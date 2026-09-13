#!/usr/bin/env python3
"""Run every headless Lua harness with Lua 5.1, then Python unit tests.

Usage: python3 Tools/run_tests.py [--lua /path/to/lua5.1]
Each harness runs in a separate process; a failure or timeout fails the suite.
"""
import argparse
import shutil
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--lua", default=shutil.which("lua5.1") or shutil.which("luajit"))
    args = parser.parse_args()
    if not args.lua:
        parser.error("Lua 5.1 or LuaJIT is required; pass --lua PATH")
    version = subprocess.run([args.lua, "-e", "assert(_VERSION == 'Lua 5.1', _VERSION)"], cwd=ROOT)
    if version.returncode:
        return version.returncode
    failed = []
    tests = sorted((ROOT / "Tools").glob("test_*.lua"))
    commands = [(p.name, [args.lua, "Tools/run_test.lua", str(p)]) for p in tests]
    commands += [("Python unit tests", [sys.executable, "-m", "unittest", "discover",
                                         "-s", "Tools", "-p", "test_*.py"])]
    for name, command in commands:
        try:
            run = subprocess.run(command, cwd=ROOT, stdout=subprocess.PIPE,
                                 stderr=subprocess.STDOUT, text=True, timeout=120)
            good = run.returncode == 0
            print(("PASS " if good else "FAIL ") + name, flush=True)
            if not good:
                print(run.stdout)
                failed.append(name)
        except subprocess.TimeoutExpired:
            print("FAIL " + name + " (120s timeout)", flush=True)
            failed.append(name)
    print(f"\n{len(commands) - len(failed)}/{len(commands)} test processes passed.")
    return bool(failed)


if __name__ == "__main__":
    sys.exit(main())
