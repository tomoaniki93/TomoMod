#!/usr/bin/env python3
# =====================================================================
# Tools/lint_secret_values.py -- static audit of secret-value handling
#
# Midnight made a large part of the client API able to return "secret"
# values. Any Lua operation on one of those -- arithmetic, ordering
# comparison, concatenation, table indexing -- throws at runtime. The
# error surfaces in the field, on someone else's machine, usually inside
# a raid.
#
# The headless test harnesses in this folder prove the guards that were
# thought of. They cannot prove the ones that were not: a runtime stub
# only fires on a path the test walks. This linter is the other half --
# it reads the sources and reports every place a value that came out of
# a secret-bearing API reaches a Lua operation without a guard first.
#
# It is a heuristic, not a prover. It is deliberately tuned to be quiet:
# a guard anywhere earlier in the same block silences the rest of the
# block, and any value that passed through a sanitiser is considered
# clean. The point is a signal-to-noise ratio good enough to actually
# read, not a proof of absence.
#
# Two sources decide which API can hand back a secret:
#
#   1. Tools/apidoc_secrets.txt, generated from the client's own
#      APIDocumentation by Tools/APIDump + Tools/apidoc_import.py.
#      Authoritative, and regenerated per patch instead of rotting.
#
#   2. The repo itself. Any call whose result is guarded with
#      issecretvalue() somewhere is treated as secret-bearing
#      everywhere. This needs no external data and it is what catches
#      the real bug class: the same call guarded in one module and
#      trusted in the next.
#
# Pure standard library: no pip install, no native modules.
#
# Usage:
#     python3 Tools/lint_secret_values.py                 # audit the repo
#     python3 Tools/lint_secret_values.py --evidence      # what feeds (2)
#     python3 Tools/lint_secret_values.py --inconsistent  # guarded here, not there
#     python3 Tools/lint_secret_values.py --json
#     python3 Tools/lint_secret_values.py --baseline Tools/secret_baseline.txt
#     python3 Tools/lint_secret_values.py --write-baseline Tools/secret_baseline.txt
#
# Exit codes: 0 clean (or fully baselined), 1 findings, 2 bad invocation.
# =====================================================================

import argparse
import json
import os
import re
import sys
from pathlib import Path

REPO = Path(__file__).resolve().parent.parent
REFERENCE = Path(__file__).resolve().parent / "apidoc_secrets.txt"

# =====================================================================
# CONFIG -- edit this block, not the code below it.
# =====================================================================

# Folders scanned. Libs/ is third-party and not ours to fix.
SCAN_ROOTS = [
    "Core", "Modules", "Locales",
    "TomoMod_AstralForge", "TomoMod_CDStudio", "TomoMod_GroupStudio",
    "TomoMod_MythicPlus", "TomoMod_Options", "TomoMod_ResourceCastStudio",
]

SKIP_DIR_NAMES = {".git", "Libs", "Tools", ".github", ".release"}

# Functions that answer "is this value secret?". Seeing one of these
# applied to a variable marks that variable guarded for the rest of the
# block. Bare names and dotted names both work; only the last segment is
# matched, so `U.IsSecret` and a file-local `IsSecret` both land here.
GUARD_FUNCTIONS = {
    "issecretvalue",
}

# The repo spells the same idea seven ways -- issecretvalue, IsSecret,
# issecret, _issecret, isSecret, IsSecretValue, HasSecretValue -- and a
# fixed list would silently stop recognising the eighth. Matching the
# shape instead means a new helper is honoured the day it is written.
GUARD_PATTERN = re.compile(r"^_?(is|has|any)_?secret\w*$", re.IGNORECASE)

# Functions that take a possibly-secret value and hand back something
# provably plain (or nil). Their *result* is clean, and passing a tainted
# value *into* one is correct usage rather than a finding.
SANITISER_FUNCTIONS = {
    "Plain",
    "PlainNumber",
    "SafeStr",
    "SafeNum",
    "SafeNumber",
    "SafeNumberOrNil",
    "SafeToNumber",
    "SafeValue",
    "SafeGroupRole",
    "SafeCall",
}

# Any function whose name matches this is treated as a sanitiser too, so
# new `U.SafeWhatever` helpers do not need a config edit to be honoured.
SANITISER_PATTERN = re.compile(
    r"^(Safe[A-Z]\w*|Plain[A-Z]?\w*|Decode\w*Secret\w*)$")

# Frame/widget methods that hand back geometry. `GetLeft()` returning a
# secret is the exact shape of the ForgeCanvas crash the harness was
# written for -- but that only happens once a frame is anchored to, or
# fed from, protected data. On a config widget we built ourselves these
# are plain numbers every time, so auditing them by default buries the
# real findings under hundreds of harmless ones. They live behind
# --geometry, to be read as a worklist rather than a bug list.
GEOMETRY_METHODS = {
    "GetLeft", "GetRight", "GetTop", "GetBottom",
    "GetPoint", "GetRect", "GetCenter", "GetSize",
    "GetWidth", "GetHeight",
    "GetValue", "GetMinMaxValues",
    "GetEffectiveScale", "GetScale",
    "GetText",
}

# Wrappers that call something else on the caller's behalf. The guard in
# `local ok, hp = pcall(UnitHealth, unit)` is evidence about UnitHealth,
# not about pcall -- without this the harvest reports pcall as the most
# secret-bearing call in the addon and says nothing useful.
PASSTHROUGH_CALLS = {"pcall", "xpcall", "securecall", "securecallfunction"}

# Never worth harvesting as an origin: too generic to mean anything.
EVIDENCE_BLACKLIST = {"select", "type", "rawget", "tostring", "tonumber", "next"}

# Lua operations that throw on a secret operand.
ARITH_OPS = {"+", "-", "*", "/", "%", "^"}
ORDER_OPS = {"<", ">", "<=", ">="}
CONCAT_OP = ".."
# `==` and `~=` are deliberately absent: equality on a secret is allowed,
# it leaks no ordering. Flagging it would bury the real findings.

# Library calls that operate on the value in Lua and therefore throw.
UNSAFE_CONSUMERS = {
    "tonumber", "tostring", "format", "strformat", "strjoin", "strsplit",
    "abs", "floor", "ceil", "min", "max", "sqrt", "modf", "fmod",
    "ipairs", "pairs", "unpack", "sort", "concat", "date", "rep", "sub",
}

# Suppression marker: put it on the offending line or the line above.
SUPPRESS = "@secret-ok"

# =====================================================================
# Lua lexer
#
# Comments and strings are dropped, which is the whole point: a `--` in
# a string and a `]]` in a comment are exactly what a regex-only pass
# gets wrong, and getting block nesting wrong poisons every scope after
# it.
# =====================================================================

KEYWORDS = {
    "and", "break", "do", "else", "elseif", "end", "false", "for",
    "function", "goto", "if", "in", "local", "nil", "not", "or",
    "repeat", "return", "then", "true", "until", "while",
}

# Longest-first so `<=` is never read as `<` then `=`.
OPERATORS = [
    "...", "..", "==", "~=", "<=", ">=", "::",
    "+", "-", "*", "/", "%", "^", "#", "<", ">", "=",
    "(", ")", "{", "}", "[", "]", ";", ":", ",", ".",
]

NAME_RE = re.compile(r"[A-Za-z_]\w*")
NUM_RE = re.compile(r"0[xX][0-9a-fA-F]+|(?:\d+\.?\d*|\.\d+)(?:[eE][+-]?\d+)?")


class Token:
    __slots__ = ("kind", "value", "line")

    def __init__(self, kind, value, line):
        self.kind = kind      # NAME | KEYWORD | NUM | STR | OP
        self.value = value
        self.line = line

    def __repr__(self):
        return "%s(%r)@%d" % (self.kind, self.value, self.line)


class LuaLexError(Exception):
    pass


def _long_bracket(src, i):
    """If src[i:] opens a long bracket, return (level, body_start). Else None."""
    if src[i] != "[":
        return None
    j = i + 1
    level = 0
    while j < len(src) and src[j] == "=":
        level += 1
        j += 1
    if j < len(src) and src[j] == "[":
        return level, j + 1
    return None


def _skip_long(src, level, start, line):
    close = "]" + "=" * level + "]"
    end = src.find(close, start)
    if end == -1:
        raise LuaLexError("unterminated long bracket opened at line %d" % line)
    return end + len(close), line + src.count("\n", start, end)


def tokenize(src):
    """Return (tokens, suppressed_lines).

    suppressed_lines holds every line whose comment carried the
    suppression marker, so the reporter can honour it after the comment
    text itself has been thrown away.
    """
    tokens = []
    suppressed = set()
    i, line, n = 0, 1, len(src)

    while i < n:
        c = src[i]

        if c == "\n":
            line += 1
            i += 1
            continue
        if c in " \t\r":
            i += 1
            continue

        # -- comment, long or short
        if src.startswith("--", i):
            lb = _long_bracket(src, i + 2)
            if lb:
                level, body = lb
                body_end = src.find("]" + "=" * level + "]", body)
                text = src[body:body_end] if body_end != -1 else src[body:]
                if SUPPRESS in text:
                    for k in range(text.count("\n") + 1):
                        suppressed.add(line + k)
                i, line = _skip_long(src, level, body, line)
            else:
                eol = src.find("\n", i)
                if eol == -1:
                    eol = n
                if SUPPRESS in src[i:eol]:
                    suppressed.add(line)
                i = eol
            continue

        # long string
        lb = _long_bracket(src, i)
        if lb:
            level, body = lb
            start_line = line
            i, line = _skip_long(src, level, body, line)
            tokens.append(Token("STR", "", start_line))
            continue

        # quoted string
        if c in "\"'":
            quote, j = c, i + 1
            while j < n:
                if src[j] == "\\":
                    j += 2
                    continue
                if src[j] == quote:
                    break
                if src[j] == "\n":
                    raise LuaLexError("unterminated string at line %d" % line)
                j += 1
            if j >= n:
                raise LuaLexError("unterminated string at line %d" % line)
            tokens.append(Token("STR", src[i + 1:j], line))
            i = j + 1
            continue

        # number
        m = NUM_RE.match(src, i)
        if m and (c.isdigit() or (c == "." and i + 1 < n and src[i + 1].isdigit())):
            tokens.append(Token("NUM", m.group(0), line))
            i = m.end()
            continue

        # name / keyword
        m = NAME_RE.match(src, i)
        if m:
            word = m.group(0)
            tokens.append(Token("KEYWORD" if word in KEYWORDS else "NAME", word, line))
            i = m.end()
            continue

        # operator
        for op in OPERATORS:
            if src.startswith(op, i):
                tokens.append(Token("OP", op, line))
                i += len(op)
                break
        else:
            # Unknown byte (stray BOM, encoding debris). Skip it rather
            # than abort: one odd byte should not blind the whole file.
            i += 1

    return tokens, suppressed


# =====================================================================
# Call-shape reading
#
# Both passes need the same question answered: "at token k, does a call
# start, and what is it called?" Sharing one reader keeps evidence
# harvesting and violation detection from disagreeing about what counts
# as a call.
# =====================================================================

def read_callee(tokens, k):
    """Read a call starting at k.

    Returns (qualified_name, last_segment, open_paren_index) or None.
    Handles `Fn(`, `A.B.C(`, `obj:Method(`, and the argument-less string
    and table call forms `Fn"x"` / `Fn{...}`.
    """
    if k >= len(tokens) or tokens[k].kind != "NAME":
        return None

    parts = [tokens[k].value]
    j = k + 1
    method = None

    while j + 1 < len(tokens) and tokens[j].kind == "OP" and tokens[j].value == "." \
            and tokens[j + 1].kind == "NAME":
        parts.append(tokens[j + 1].value)
        j += 2

    if j + 1 < len(tokens) and tokens[j].kind == "OP" and tokens[j].value == ":" \
            and tokens[j + 1].kind == "NAME":
        method = tokens[j + 1].value
        parts.append(method)
        j += 2

    if j >= len(tokens):
        return None
    t = tokens[j]
    if t.kind == "OP" and t.value in ("(", "{"):
        return ".".join(parts), parts[-1], j
    if t.kind == "STR":
        return ".".join(parts), parts[-1], j
    return None


def matching_close(tokens, open_idx):
    """Index of the bracket closing the one at open_idx, or len(tokens)."""
    opens = {"(": ")", "{": "}", "[": "]"}
    if tokens[open_idx].kind != "OP" or tokens[open_idx].value not in opens:
        return open_idx
    want = opens[tokens[open_idx].value]
    depth = 0
    for j in range(open_idx, len(tokens)):
        if tokens[j].kind != "OP":
            continue
        if tokens[j].value in opens:
            depth += 1
        elif tokens[j].value in (")", "}", "]"):
            depth -= 1
            if depth == 0:
                return j if tokens[j].value == want else j
    return len(tokens)


def resolve_call(tokens, k):
    """read_callee, plus one step through pcall-style wrappers.

    Returns (qualified_name, last_segment, open_idx, close_idx) or None.
    For `pcall(UnitHealth, unit)` the name reported is UnitHealth, which
    is the call the guard downstream is actually about.
    """
    call = read_callee(tokens, k)
    if not call:
        return None
    qname, last, open_idx = call
    close = matching_close(tokens, open_idx)

    if last in PASSTHROUGH_CALLS and tokens[open_idx].value == "(":
        j = open_idx + 1
        if j < len(tokens) and tokens[j].kind == "NAME":
            parts = [tokens[j].value]
            j += 1
            while j + 1 < len(tokens) and tokens[j].kind == "OP" \
                    and tokens[j].value in (".", ":") and tokens[j + 1].kind == "NAME":
                parts.append(tokens[j + 1].value)
                j += 2
            # Only a bare reference counts; `pcall(function() ... end)`
            # and `pcall(f(x))` say nothing about which API is involved.
            if j < len(tokens) and tokens[j].kind == "OP" and tokens[j].value in (",", ")"):
                return ".".join(parts), parts[-1], open_idx, close
        return None

    return qname, last, open_idx, close


def is_guard(last_segment):
    return last_segment in GUARD_FUNCTIONS or bool(GUARD_PATTERN.match(last_segment))


def is_sanitiser(last_segment):
    return last_segment in SANITISER_FUNCTIONS or bool(SANITISER_PATTERN.match(last_segment))


def worth_harvesting(qname, last):
    if last in EVIDENCE_BLACKLIST or last in PASSTHROUGH_CALLS:
        return False
    if is_guard(last) or is_sanitiser(last):
        return False
    return True


# =====================================================================
# Block scoping
#
# `for x do ... end` and `while c do ... end` carry a `do` that belongs
# to the loop rather than opening a block of its own. Counting it twice
# leaves every scope after it off by one, so the loop keywords arm a
# flag that eats the next `do`.
# =====================================================================

class ScopeStack:
    def __init__(self):
        self.frames = [{}]
        self._eat_do = False

    def feed(self, tok):
        """Advance block nesting. Returns nothing; call before use checks."""
        if tok.kind != "KEYWORD":
            return
        w = tok.value
        if w in ("for", "while"):
            self.frames.append({})
            self._eat_do = True
        elif w == "do":
            if self._eat_do:
                self._eat_do = False
            else:
                self.frames.append({})
        elif w in ("function", "if", "repeat"):
            self.frames.append({})
        elif w in ("end", "until"):
            if len(self.frames) > 1:
                self.frames.pop()

    def declare(self, name, state):
        self.frames[-1][name] = state

    def set_anywhere(self, name, state):
        """Update the innermost frame that knows the name, else declare here."""
        for frame in reversed(self.frames):
            if name in frame:
                frame[name] = state
                return
        self.frames[-1][name] = state

    def get(self, name):
        for frame in reversed(self.frames):
            if name in frame:
                return frame[name]
        return None


TAINTED = "tainted"
GUARDED = "guarded"


# =====================================================================
# Pass 1 -- evidence
#
# Harvest, from the repo itself, which calls hand back values the code
# already treats as secret. A guard is an admission: whoever wrote it
# had a reason.
# =====================================================================

def harvest_evidence(files):
    """Return {qualified_call: [(file, line), ...]} for guarded results."""
    evidence = {}

    for path, tokens, _ in files:
        origin = {}   # variable name -> qualified call that produced it
        k = 0
        while k < len(tokens):
            call = resolve_call(tokens, k)
            if call:
                qname, last, open_idx, close = call
                if is_guard(last):
                    for j in range(open_idx + 1, min(close, len(tokens))):
                        if tokens[j].kind == "NAME":
                            src = origin.get(tokens[j].value)
                            if src:
                                evidence.setdefault(src, []).append((path, tokens[j].line))
                    k = close + 1
                    continue

            names, rhs = read_assignment(tokens, k)
            if names is not None and rhs is not None:
                rcall = resolve_call(tokens, rhs)
                src = None
                if rcall and worth_harvesting(rcall[0], rcall[1]):
                    src = rcall[0]
                for nm in names:
                    if src:
                        origin[nm] = src
                    else:
                        origin.pop(nm, None)
                k = rhs
                continue
            k += 1

    return evidence


def read_assignment(tokens, k):
    """If an assignment starts at k, return (lhs_names, rhs_index).

    Recognises `local a, b = ...` and `a.b, c = ...`. Only plain names
    land in lhs_names -- a field assignment taints nothing trackable.
    Returns (None, None) when k does not begin an assignment.
    """
    i = k
    if tokens[i].kind == "KEYWORD" and tokens[i].value == "local":
        i += 1
        if i < len(tokens) and tokens[i].kind == "KEYWORD" and tokens[i].value == "function":
            return None, None
    elif tokens[i].kind != "NAME":
        return None, None

    names = []
    while i < len(tokens):
        if tokens[i].kind != "NAME":
            return None, None
        name = tokens[i].value
        i += 1
        # Skip field/index suffixes; those are not trackable locals.
        plain = True
        while i < len(tokens) and tokens[i].kind == "OP" and tokens[i].value in (".", "[", ":"):
            plain = False
            if tokens[i].value == "[":
                i = matching_close(tokens, i) + 1
            else:
                i += 2
        if plain:
            names.append(name)
        if i < len(tokens) and tokens[i].kind == "OP" and tokens[i].value == ",":
            i += 1
            continue
        break

    if i < len(tokens) and tokens[i].kind == "OP" and tokens[i].value == "=":
        return names, i + 1
    return None, None


# =====================================================================
# Pass 2 -- violations
# =====================================================================

class Finding:
    __slots__ = ("path", "line", "var", "op", "source", "kind")

    def __init__(self, path, line, var, op, source, kind):
        self.path, self.line, self.var = path, line, var
        self.op, self.source, self.kind = op, source, kind

    def key(self):
        return "%s:%d:%s:%s" % (self.path, self.line, self.var, self.op)

    def text(self):
        return "%s:%d: %s on `%s` (from %s) without a secret check -- %s" % (
            self.path, self.line, self.kind, self.var, self.source, self.op)


def prev_significant(tokens, k):
    j = k - 1
    return tokens[j] if j >= 0 else None


def classify_use(tokens, k, name_idx):
    """Describe the Lua operation touching the name at name_idx, or None."""
    before = prev_significant(tokens, name_idx)
    after = tokens[name_idx + 1] if name_idx + 1 < len(tokens) else None

    def op_of(tok):
        return tok.value if tok is not None and tok.kind == "OP" else None

    b, a = op_of(before), op_of(after)

    if b == CONCAT_OP or a == CONCAT_OP:
        return "concatenation", CONCAT_OP
    if b in ORDER_OPS or a in ORDER_OPS:
        return "ordering comparison", b if b in ORDER_OPS else a
    if a in ARITH_OPS:
        return "arithmetic", a
    if b in ARITH_OPS:
        # A leading `-` may be unary on a fresh operand; that still
        # throws on a secret, so it is reported either way.
        return "arithmetic", b
    if b == "[":
        return "table index", "[]"
    if b == "#":
        return "length operator", "#"
    return None


def analyse(path, tokens, suppressed, secret_calls, geometry):
    """Report Lua operations reaching a value that came out of a secret
    API without a check in between.

    `geometry` switches on the frame-measurement methods. They are a
    different question -- a worklist of places that *could* go secret
    once a frame touches protected data -- and mixing the two makes
    neither readable.
    """
    findings = []
    scopes = ScopeStack()
    source_of = {}

    def suppressed_at(line):
        return line in suppressed or (line - 1) in suppressed

    def is_secret_call(qname, last):
        if qname in secret_calls:
            return True
        if geometry and last in GEOMETRY_METHODS:
            return True
        return False

    k = 0
    while k < len(tokens):
        tok = tokens[k]
        scopes.feed(tok)

        call = resolve_call(tokens, k)
        if call:
            qname, last, open_idx, close = call
            close = min(close, len(tokens) - 1)

            if is_guard(last) or is_sanitiser(last):
                for j in range(open_idx + 1, close):
                    if tokens[j].kind == "NAME":
                        scopes.set_anywhere(tokens[j].value, GUARDED)
                k = close + 1
                continue

            if last in UNSAFE_CONSUMERS:
                for j in range(open_idx + 1, close):
                    t = tokens[j]
                    if t.kind == "NAME" and scopes.get(t.value) == TAINTED:
                        if not suppressed_at(t.line):
                            findings.append(Finding(
                                path, t.line, t.value, qname + "()",
                                source_of.get(t.value, "?"), "unsafe consumer"))
                        scopes.set_anywhere(t.value, GUARDED)

            if is_secret_call(qname, last):
                # An inline call feeding an operator directly, with no
                # variable in between: `if UnitHealth(u) > 0 then`.
                use = classify_use(tokens, k, close)
                if use and not suppressed_at(tok.line):
                    kind, op = use
                    findings.append(Finding(path, tok.line, qname + "()", op, qname, kind))
                # Consume the whole call so the method name is not read a
                # second time as a call of its own.
                k = close + 1
                continue

        names, rhs = read_assignment(tokens, k)
        if names is not None and rhs is not None:
            rcall = resolve_call(tokens, rhs)
            state, src = None, None
            if rcall:
                qname, last, _, _ = rcall
                if is_guard(last) or is_sanitiser(last):
                    state, src = GUARDED, qname
                elif is_secret_call(qname, last):
                    state, src = TAINTED, qname
            for nm in names:
                scopes.declare(nm, state)
                if state:
                    source_of[nm] = src
            k = rhs
            continue

        if tok.kind == "NAME" and scopes.get(tok.value) == TAINTED:
            use = classify_use(tokens, k, k)
            if use:
                kind, op = use
                if not suppressed_at(tok.line):
                    findings.append(Finding(
                        path, tok.line, tok.value, op,
                        source_of.get(tok.value, "?"), kind))
                # One report per variable per block; after that the
                # reader has the information and repetition only hides
                # the next distinct problem.
                scopes.set_anywhere(tok.value, GUARDED)

        k += 1

    return findings


# =====================================================================
# Reference file
# =====================================================================

def load_reference(path):
    """Read Tools/apidoc_secrets.txt. Missing file is not an error."""
    calls, meta = set(), {}
    if not path.is_file():
        return calls, meta
    for raw in path.read_text(encoding="utf-8").splitlines():
        line = raw.strip()
        if not line or line.startswith("#"):
            continue
        parts = line.split("|")
        if parts[0] == "H" and len(parts) >= 4:
            meta = {"build": parts[1], "interface": parts[2], "generated": parts[3]}
        elif parts[0] == "F" and len(parts) >= 2 and parts[1]:
            calls.add(parts[1])
    return calls, meta


# =====================================================================
# Driver
# =====================================================================

def collect_files(repo, roots):
    out = []
    for root in roots:
        base = repo / root
        if not base.is_dir():
            continue
        for dirpath, dirnames, filenames in os.walk(base):
            dirnames[:] = [d for d in dirnames if d not in SKIP_DIR_NAMES]
            for fn in sorted(filenames):
                if fn.endswith(".lua"):
                    out.append(Path(dirpath) / fn)
    return sorted(out)


def lex_all(paths, repo):
    files, errors = [], []
    for p in paths:
        raw = p.read_bytes()
        if raw.startswith(b"\xef\xbb\xbf"):
            raw = raw[3:]
        src = raw.decode("utf-8", errors="replace")
        rel = str(p.relative_to(repo))
        try:
            tokens, suppressed = tokenize(src)
        except LuaLexError as exc:
            errors.append("%s: %s" % (rel, exc))
            continue
        files.append((rel, tokens, suppressed))
    return files, errors


def main():
    ap = argparse.ArgumentParser(description="Static secret-value audit for TomoMod.")
    ap.add_argument("--repo", default=str(REPO))
    ap.add_argument("--reference", default=str(REFERENCE))
    ap.add_argument("--evidence", action="store_true",
                    help="list the calls the repo's own guards mark as secret-bearing")
    ap.add_argument("--inconsistent", action="store_true",
                    help="list calls guarded in some places and trusted in others")
    ap.add_argument("--geometry", action="store_true",
                    help="also audit frame measurement methods (GetLeft, GetWidth, ...)")
    ap.add_argument("--json", action="store_true")
    ap.add_argument("--baseline", help="accept the findings listed in this file")
    ap.add_argument("--write-baseline", help="record current findings and exit 0")
    args = ap.parse_args()

    repo = Path(args.repo).resolve()
    if not (repo / "TomoMod.toc").is_file():
        sys.stderr.write("not a TomoMod checkout: %s\n" % repo)
        return 2

    paths = collect_files(repo, SCAN_ROOTS)
    files, lex_errors = lex_all(paths, repo)

    ref_calls, ref_meta = load_reference(Path(args.reference))
    evidence = harvest_evidence(files)
    secret_calls = set(ref_calls) | set(evidence)

    if args.evidence:
        for name in sorted(evidence):
            sites = evidence[name]
            print("%-52s %d guard%s  e.g. %s:%d"
                  % (name, len(sites), "" if len(sites) == 1 else "s",
                     sites[0][0], sites[0][1]))
        print("\n%d call%s marked secret-bearing by the repo's own guards."
              % (len(evidence), "" if len(evidence) == 1 else "s"))
        return 0

    findings = []
    for rel, tokens, suppressed in files:
        findings.extend(analyse(rel, tokens, suppressed, secret_calls, args.geometry))

    if args.inconsistent:
        guarded = {name: len(sites) for name, sites in evidence.items()}
        by_call = {}
        for f in findings:
            by_call.setdefault(f.source, []).append(f)
        rows = [(name, guarded.get(name, 0), by_call.get(name, []))
                for name in sorted(set(guarded) | set(by_call))
                if guarded.get(name, 0) and by_call.get(name)]
        for name, nguard, unguarded in rows:
            print("%s\n    guarded %d time%s, unguarded %d time%s:"
                  % (name, nguard, "" if nguard == 1 else "s",
                     len(unguarded), "" if len(unguarded) == 1 else "s"))
            for f in unguarded:
                print("        %s:%d  %s on `%s`" % (f.path, f.line, f.kind, f.var))
        print("\n%d call%s treated inconsistently." % (len(rows), "" if len(rows) == 1 else "s"))
        return 1 if rows else 0

    if args.write_baseline:
        Path(args.write_baseline).write_text(
            "".join(sorted(f.key() + "\n" for f in findings)), encoding="utf-8")
        print("baseline written: %d finding%s" % (len(findings), "" if len(findings) == 1 else "s"))
        return 0

    accepted = set()
    if args.baseline and Path(args.baseline).is_file():
        accepted = {l.strip() for l in Path(args.baseline).read_text(encoding="utf-8").splitlines() if l.strip()}
    new = [f for f in findings if f.key() not in accepted]

    if args.json:
        print(json.dumps({
            "reference": ref_meta or None,
            "secret_calls": len(secret_calls),
            "from_evidence": len(evidence),
            "lex_errors": lex_errors,
            "findings": [{"file": f.path, "line": f.line, "variable": f.var,
                          "operation": f.op, "kind": f.kind, "source": f.source}
                         for f in new],
        }, indent=2))
        return 1 if new else 0

    for err in lex_errors:
        print("lex error: %s" % err)

    for f in sorted(new, key=lambda x: (x.path, x.line)):
        print(f.text())

    print()
    if ref_meta:
        print("reference: build %s, interface %s, generated %s"
              % (ref_meta.get("build"), ref_meta.get("interface"), ref_meta.get("generated")))
    else:
        print("reference: Tools/apidoc_secrets.txt absent -- running on repo evidence only.")
        print("           see Tools/APIDump/README.md to generate it.")
    print("%d file%s scanned, %d secret-bearing call%s known (%d from repo evidence)."
          % (len(files), "" if len(files) == 1 else "s",
             len(secret_calls), "" if len(secret_calls) == 1 else "s", len(evidence)))
    if accepted:
        print("%d finding%s accepted by baseline." % (len(accepted), "" if len(accepted) == 1 else "s"))
    print("%d finding%s." % (len(new), "" if len(new) == 1 else "s"))
    return 1 if new else 0


if __name__ == "__main__":
    sys.exit(main())
