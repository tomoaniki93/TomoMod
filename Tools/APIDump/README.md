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
--geometry        also audit GetLeft/GetWidth/GetPoint and friends
--json            machine-readable output
--baseline FILE   accept the findings already recorded in FILE
```

`--geometry` is off by default on purpose. Frame measurements only turn
secret once a frame is anchored to, or fed from, protected data — the
ForgeCanvas crash was exactly that. On a config widget we built
ourselves they are plain numbers every time, and auditing them by
default buries thirty real findings under five hundred harmless ones.
Read it as a worklist, not a bug list.

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

That writes `Tools/apidoc_secrets.txt`. It is sorted and carries the
build it came from, so the diff between two patches shows exactly which
API changed its secrecy contract — which is worth reading on its own.

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
