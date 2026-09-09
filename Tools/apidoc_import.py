#!/usr/bin/env python3
# =====================================================================
# Tools/apidoc_import.py -- SavedVariables dump -> apidoc_secrets.txt
#
# Tools/APIDump writes the client's secret-value metadata into
# WTF/Account/<ACCOUNT>/SavedVariables/TomoAPIDump.lua. That file is
# valid Lua but it is written by the client's serialiser, so its shape
# (indentation, key quoting, table ordering) is not ours to rely on.
#
# This script reads only what it can prove: the string literals inside
# the `records` table. Every record was built by the addon from a fixed
# template, so anything that does not match the template is a sign the
# dump is stale or truncated, and is reported rather than skipped
# quietly.
#
# Output is sorted and carries the build it came from, so the reference
# file diffs cleanly from one patch to the next and it is always obvious
# which client version the audit was run against.
#
# Usage:
#     python3 Tools/apidoc_import.py <path>/SavedVariables/TomoAPIDump.lua
#     python3 Tools/apidoc_import.py <path> --out Tools/apidoc_secrets.txt
# =====================================================================

import argparse
import re
import sys
from pathlib import Path

HERE = Path(__file__).resolve().parent
DEFAULT_OUT = HERE / "apidoc_secrets.txt"

# The serialiser writes each array entry on its own line, either bare or
# as ["1"] = "...", and tags array entries with a trailing `-- [n]`
# index comment. All three shapes are accepted; anything else is not a
# record and is left alone.
RECORD_RE = re.compile(
    r'^\s*(?:\[\s*\d+\s*\]\s*=\s*)?"((?:[^"\\]|\\.)*)"\s*,?\s*(?:--.*)?$')

VALID_KINDS = {"H", "F", "A", "X", "S"}

ESCAPES = {"\\n": "\n", "\\t": "\t", "\\r": "\r", '\\"': '"', "\\\\": "\\"}


def unescape(text):
    out, i = [], 0
    while i < len(text):
        if text[i] == "\\" and i + 1 < len(text):
            pair = text[i:i + 2]
            if pair in ESCAPES:
                out.append(ESCAPES[pair])
                i += 2
                continue
            # \ddd numeric escape
            m = re.match(r"\\(\d{1,3})", text[i:])
            if m:
                out.append(chr(int(m.group(1))))
                i += len(m.group(0))
                continue
        out.append(text[i])
        i += 1
    return "".join(out)


def extract_records(source):
    """Pull the string literals out of the `records` table."""
    start = source.find("records")
    if start == -1:
        raise ValueError("no `records` table in the dump -- did /apidump run before /reload?")

    open_brace = source.find("{", start)
    if open_brace == -1:
        raise ValueError("`records` is not a table")

    depth, i, n = 0, open_brace, len(source)
    while i < n:
        if source[i] == "{":
            depth += 1
        elif source[i] == "}":
            depth -= 1
            if depth == 0:
                break
        i += 1
    body = source[open_brace + 1:i]

    records = []
    for line in body.splitlines():
        m = RECORD_RE.match(line)
        if m:
            records.append(unescape(m.group(1)))
    return records


def validate(records):
    """Return (header, good, rejected)."""
    header, good, rejected = None, [], []
    for rec in records:
        parts = rec.split("|")
        kind = parts[0] if parts else ""
        if kind not in VALID_KINDS:
            rejected.append(rec)
            continue
        if kind == "H":
            if len(parts) < 4:
                rejected.append(rec)
                continue
            header = rec
        elif len(parts) < 2 or not parts[1]:
            rejected.append(rec)
            continue
        else:
            good.append(rec)
    return header, good, rejected


def main():
    ap = argparse.ArgumentParser(
        description="Convert a TomoAPIDump SavedVariables file into the linter reference.")
    ap.add_argument("dump", help="path to SavedVariables/TomoAPIDump.lua")
    ap.add_argument("--out", default=str(DEFAULT_OUT))
    args = ap.parse_args()

    path = Path(args.dump)
    if not path.is_file():
        sys.stderr.write("no such file: %s\n" % path)
        return 2

    raw = path.read_bytes()
    if raw.startswith(b"\xef\xbb\xbf"):
        raw = raw[3:]
    source = raw.decode("utf-8", errors="replace")

    try:
        records = extract_records(source)
    except ValueError as exc:
        sys.stderr.write("%s\n" % exc)
        return 2

    header, good, rejected = validate(records)
    if header is None:
        sys.stderr.write("dump has no H header record -- it is truncated or from an older addon version\n")
        return 2

    counts = {}
    for rec in good:
        counts[rec.split("|")[0]] = counts.get(rec.split("|")[0], 0) + 1

    build, interface, generated = header.split("|")[1:4]

    lines = [
        "# Tools/apidoc_secrets.txt -- GENERATED, do not edit by hand.",
        "#",
        "# Source: the client's own APIDocumentation, exported by",
        "# Tools/APIDump and converted by Tools/apidoc_import.py.",
        "# Regenerate after every content patch.",
        "#",
        "#   H | build | interface | generated",
        "#   F | function            | secret return aspects | structures with secret fields",
        "#   A | function            | secret argument policy | aspects added",
        "#   X | function            | forbidden aspects checked (argument)",
        "#   S | structure | field   | ConditionalSecret,NeverSecret,...",
        "#",
        "# Only F records taint a value in Tools/lint_secret_values.py.",
        "# The rest are recorded so the file stays useful as the linter grows.",
        "",
        header,
    ]
    lines.extend(sorted(good))

    out = Path(args.out)
    out.write_text("\n".join(lines) + "\n", encoding="utf-8", newline="\n")

    print("client build %s (interface %s), dumped %s" % (build, interface, generated))
    print("  F secret-returning functions : %d" % counts.get("F", 0))
    print("  A secret-argument functions  : %d" % counts.get("A", 0))
    print("  X forbidden-aspect checks    : %d" % counts.get("X", 0))
    print("  S structure fields           : %d" % counts.get("S", 0))
    if rejected:
        print("  %d malformed record(s) skipped -- first: %r" % (len(rejected), rejected[0]))
    print("written: %s" % out)
    return 0


if __name__ == "__main__":
    sys.exit(main())
