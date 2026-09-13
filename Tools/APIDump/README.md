# Secret-value audit

Midnight can hand back "secret" values from a large part of the client
API. Arithmetic, ordering comparison, concatenation and table indexing
all throw on one. The crash lands in someone else's combat log, usually
weeks after the code shipped.

The headless harnesses in `Tools/` prove the guards that were thought
of. They cannot prove the ones that were not — a runtime stub only fires
on a path the test walks. This is the other half: a static pass over the
sources that reports every value coming out of a secret-bearing API and
reaching a Lua operation with no check in between.

## The three pieces

| | |
|---|---|
| `Tools/APIDump/` | A throwaway in-game addon. Exports the client's own `APIDocumentation` secret metadata to SavedVariables. |
| `Tools/apidoc_import.py` | Turns that SavedVariables file into `Tools/apidoc_secrets.txt`. |
| `Tools/lint_secret_values.py` | Reads the sources and reports unguarded uses. |

`.pkgmeta` drops all of `Tools/` from the release zip and nothing in any
`.toc` loads it, so none of this reaches a player.

## Running the audit

The linter works with no setup at all:

```
python3 Tools/lint_secret_values.py
```

It has two ways of knowing which calls can produce a secret, and the
second needs no external data:

1. **`Tools/apidoc_secrets.txt`** — generated from the client. Authoritative.
2. **The repo's own guards.** Any call whose result is passed to
   `issecretvalue` (or `IsSecret`, `issecret`, `Helpers.HasSecretValue`,
   or any other spelling — the guard is matched by shape, not by a
   list) anywhere in the addon is treated as secret-bearing everywhere.

Source 2 is what catches the bug class that actually bites: the same
call guarded carefully in one module and trusted in the next. Source 1
catches the calls nobody has guarded yet, anywhere.

Useful flags:

```
--evidence        which calls the repo's own guards mark as secret-bearing
--inconsistent    calls guarded in some places and trusted in others
--widgets         also audit widget methods (GetText, GetFrameLevel, GetLeft, ...)
--json            machine-readable output
--baseline FILE   accept the findings already recorded in FILE
```

`--widgets` is off by default on purpose: it turns 32 findings into 634.
A widget method only returns a secret once the frame carries the
matching secret aspect, which on a config panel we built ourselves is
almost never. Read that list as a worklist, not a bug list — but do
read it, because `GetFrameLevel` alone accounts for 122 sites and the
client documents its return as secret-capable.

## What the dump actually says

Worth knowing before trusting either source too far.

The client documents secret **returns** almost exclusively on the
widget API — 82 bare methods (`GetText`, `GetValue`, `GetAlpha`,
`IsShown`, `GetFrameLevel`, `GetCooldownTimes`, ...), each keyed to a
`SecretAspect`. Not one namespaced function (`UnitHealth`, `UnitClass`,
`C_UnitAuras.*`) is marked as returning a secret. For those the
documentation speaks instead through `SecretArguments`: 3573
`AllowedWhenUntainted`, 123 `AllowedWhenTainted`, 86 `NotAllowed`.

So the two sources disagree, in both directions, and both are needed:

- The documentation lists widget methods this addon never guarded.
- The repo guards `UnitHealth`, `UnitClass`, `UnitPower` and a dozen
  others that the documentation does not flag at all — on the strength
  of crashes that actually happened.
- The documentation does **not** mark `GetLeft`, `GetWidth`, `GetPoint`
  or `GetSize` as secret-returning, yet the ForgeCanvas crash was
  `GetLeft()` handing back a secret number. Those stay in
  `WIDGET_METHODS_FALLBACK` in the linter and are unioned in, because
  dropping them because a generated file omits them would be trading
  evidence for paperwork.

Treat a clean run as "nothing obvious", never as "nothing".

## Arguments the client refuses

The 86 `NotAllowed` entries are a separate, cheap check and it is on by
default: handing one of those functions a tainted value is wrong
whatever the addon does next. `C_CVar.SetCVar`, `C_ChatInfo.SendAddonMessage`
and `AddForbiddenAspects` are in that set. The audit currently finds no
violation, which is worth keeping true.

## Regenerating the reference

Do this after every content patch. That is the whole point: a list
Blizzard maintains cannot rot the way a hand-written one does.

1. Copy `Tools/APIDump` into `Interface/AddOns/` as `TomoAPIDump`.
2. Enable it, log in, run `/apidump`.
3. `/reload` — SavedVariables are only flushed on logout or reload.
4. ```
   python3 Tools/apidoc_import.py \
       "<WoW>/WTF/Account/<ACCOUNT>/SavedVariables/TomoAPIDump.lua"
   ```

That writes `Tools/apidoc_secrets.txt` — checked in, roughly 4 000
records. It is sorted and carries the build it came from, so the diff
between two patches shows exactly which API changed its secrecy
contract, which is worth reading on its own.

## The baseline

`Tools/secret_baseline.txt` records the unguarded uses that already
existed when the linter was written. CI runs with `--baseline`, so it
fails on anything *new* and stays quiet about the backlog. Shrink the
file as entries get fixed; never grow it. A plain run with no
`--baseline` still shows everything, which is the list to work from.

Regenerating it wholesale (`--write-baseline`) accepts every current
finding at once. That is for the day the file format changes, not for
making a red build green.

## Silencing a finding

When a value is provably plain and the linter cannot see why, mark it:

```lua
local pct = cur / mx -- @secret-ok
```

The marker works on the offending line or the line above. Prefer a real
guard or a `Safe*` helper where one fits; the comment is for the cases
where neither does.

## What it is not

A heuristic, not a prover. It tracks local variables inside their block
and gives up on values that go through table fields, varargs or
cross-module returns. It reports once per variable per block and falls
silent afterwards. A clean run means nothing obvious is wrong, not that
nothing is wrong.

`Tools/test_lint_secret_values.py` covers it in both directions:
every violation shape is caught, every guard shape silences it, and
every "clean" fixture is re-run with its guard stripped to prove the
silence was load-bearing rather than accidental.

```
python3 Tools/test_lint_secret_values.py
```
