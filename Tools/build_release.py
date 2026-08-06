#!/usr/bin/env python3
# =====================================================================
# Tools/build_release.py -- reproducible CurseForge zip builder
#
# Does by script what used to be done by hand: copy the repo, drop the
# development-only files listed under `ignore:` in .pkgmeta, relocate the
# sub-addons listed under `move-folders:` so they land as sibling addon
# folders, and zip the result.
#
# The relocation step is the one that matters. TomoMod_CDStudio lives
# inside the repo for convenience, but WoW only scans the top level of
# Interface/AddOns -- a zip that ships it nested is a zip where nobody can
# even see the Studio in their addon list. This script makes forgetting
# that step impossible, and refuses to write a zip if it happened anyway.
#
# Pure standard library: no pip install, no native modules.
#
# Usage:
#     python3 Tools/build_release.py              # build .release/TomoMod-<ver>.zip
#     python3 Tools/build_release.py --check      # validate only, write nothing
#     python3 Tools/build_release.py --out DIR    # choose the output directory
# =====================================================================

import argparse
import fnmatch
import os
import re
import shutil
import sys
import tempfile
import zipfile
from pathlib import Path

REPO = Path(__file__).resolve().parent.parent


# ---------------------------------------------------------------------
# .pkgmeta -- only the subset this repo actually uses
# ---------------------------------------------------------------------
def read_pkgmeta(path):
    """Parse `package-as`, `ignore:` and `move-folders:` out of .pkgmeta.

    Deliberately not a YAML parser: supporting exactly the three keys the
    repo uses keeps this dependency-free and keeps failures obvious.
    """
    meta = {"package-as": None, "ignore": [], "move-folders": {}}
    section = None

    for raw in path.read_text(encoding="utf-8").splitlines():
        line = raw.split("#", 1)[0].rstrip() if not raw.strip().startswith("#") else ""
        if not line.strip():
            continue

        if not line[0].isspace() and not line.lstrip().startswith("-"):
            key, _, value = line.partition(":")
            key, value = key.strip(), value.strip()
            if key == "package-as":
                meta["package-as"] = _unquote(value)
                section = None
            elif key in ("ignore", "move-folders"):
                section = key
            else:
                section = None
            continue

        stripped = line.strip()
        if section == "ignore" and stripped.startswith("-"):
            meta["ignore"].append(_unquote(stripped[1:].strip()))
        elif section == "move-folders":
            src, _, dst = stripped.partition(":")
            if dst.strip():
                meta["move-folders"][_unquote(src.strip())] = _unquote(dst.strip())

    if not meta["package-as"]:
        sys.exit("ERROR: .pkgmeta has no `package-as:` entry.")
    return meta


def _unquote(value):
    if len(value) >= 2 and value[0] == value[-1] and value[0] in "\"'":
        return value[1:-1]
    return value


# ---------------------------------------------------------------------
# Ignore matching
# ---------------------------------------------------------------------
def is_ignored(relpath, patterns):
    """True when `relpath` (POSIX, relative to the repo root) is excluded.

    A pattern matches when it equals the path, is a parent directory of it,
    or globs it. `**/x` also matches a top-level `x`, which plain fnmatch
    would miss.
    """
    rel = relpath.replace(os.sep, "/")
    for pat in patterns:
        pat = pat.replace(os.sep, "/").rstrip("/")
        if not pat:
            continue
        if rel == pat or rel.startswith(pat + "/"):
            return True
        if fnmatch.fnmatchcase(rel, pat):
            return True
        if pat.startswith("**/") and fnmatch.fnmatchcase(rel, pat[3:]):
            return True
    return False


# ---------------------------------------------------------------------
# Version
# ---------------------------------------------------------------------
def read_version(toc_path):
    text = toc_path.read_text(encoding="utf-8-sig")
    match = re.search(r"^##\s*Version:\s*(.+?)\s*$", text, re.MULTILINE)
    if not match:
        sys.exit("ERROR: no `## Version:` line in %s" % toc_path.name)
    return match.group(1)


# ---------------------------------------------------------------------
# Staging
# ---------------------------------------------------------------------
def stage(meta, staging, always_ignore):
    """Copy the repo into `staging/<package-as>/`, minus ignored paths."""
    patterns = list(meta["ignore"]) + always_ignore
    root = staging / meta["package-as"]
    copied = 0

    for dirpath, dirnames, filenames in os.walk(REPO):
        reldir = Path(dirpath).relative_to(REPO).as_posix()
        reldir = "" if reldir == "." else reldir

        # Prune ignored directories so we never descend into .git at all.
        dirnames[:] = [
            d for d in sorted(dirnames)
            if not is_ignored(("%s/%s" % (reldir, d)).lstrip("/"), patterns)
        ]

        for name in sorted(filenames):
            rel = ("%s/%s" % (reldir, name)).lstrip("/")
            if is_ignored(rel, patterns):
                continue
            dest = root / rel
            dest.parent.mkdir(parents=True, exist_ok=True)
            shutil.copy2(Path(dirpath) / name, dest)
            copied += 1

    return root, copied


def apply_moves(meta, staging):
    """Relocate sub-addon folders to the zip root, as the packager would."""
    moves = []
    for src_rel, dst_rel in sorted(meta["move-folders"].items()):
        src, dst = staging / src_rel, staging / dst_rel
        if not src.is_dir():
            sys.exit("ERROR: move-folders source not found after staging: %s\n"
                     "       Check the path in .pkgmeta." % src_rel)
        dst.parent.mkdir(parents=True, exist_ok=True)
        shutil.move(str(src), str(dst))
        moves.append((src_rel, dst_rel))
    return moves


# ---------------------------------------------------------------------
# Validation -- the hard gate
# ---------------------------------------------------------------------
def validate(staging):
    """Every top-level folder must be a real addon, and contain no nested one.

    This is what catches the failure this script exists to prevent: an addon
    folder buried inside another addon folder is invisible to the client.
    """
    problems = []
    tops = sorted(p for p in staging.iterdir() if p.is_dir())

    if not tops:
        problems.append("staging tree is empty")

    for top in tops:
        if not (top / (top.name + ".toc")).is_file():
            problems.append("%s/ has no %s.toc -- not a loadable addon folder"
                            % (top.name, top.name))
        for sub in sorted(top.rglob("*")):
            if sub.is_dir() and (sub / (sub.name + ".toc")).is_file():
                rel = sub.relative_to(staging).as_posix()
                # Bundled libraries legitimately carry their own .toc.
                if rel.split("/")[1:2] == ["Libs"]:
                    continue
                problems.append("nested addon folder %s -- WoW will not see it; "
                                "add a move-folders entry in .pkgmeta" % rel)
    return tops, problems


def write_zip(staging, out_dir, package, version):
    out_dir.mkdir(parents=True, exist_ok=True)
    zip_path = out_dir / ("%s-%s.zip" % (package, version))
    if zip_path.exists():
        zip_path.unlink()

    with zipfile.ZipFile(zip_path, "w", zipfile.ZIP_DEFLATED, compresslevel=9) as zf:
        for path in sorted(staging.rglob("*")):
            if path.is_file():
                zf.write(path, path.relative_to(staging).as_posix())
    return zip_path


# ---------------------------------------------------------------------
def main():
    parser = argparse.ArgumentParser(description="Build the TomoMod release zip.")
    parser.add_argument("--check", action="store_true",
                        help="validate the staged layout, write no zip")
    parser.add_argument("--out", default=".release",
                        help="output directory (default: .release)")
    args = parser.parse_args()

    meta = read_pkgmeta(REPO / ".pkgmeta")
    package = meta["package-as"]
    version = read_version(REPO / ("%s.toc" % package))

    # Never ship the builder's own output or VCS state, whatever .pkgmeta says.
    always_ignore = [".git", ".release", "**/*.zip", "**/__pycache__"]

    tmp = Path(tempfile.mkdtemp(prefix="tomomod-release-"))
    try:
        staging = tmp / "stage"
        staging.mkdir()

        _, copied = stage(meta, staging, always_ignore)
        moves = apply_moves(meta, staging)
        tops, problems = validate(staging)

        print("%s %s" % (package, version))
        print("  %d files staged" % copied)
        for src, dst in moves:
            print("  moved  %s  ->  %s" % (src, dst))
        for top in tops:
            count = sum(1 for p in top.rglob("*") if p.is_file())
            print("  folder %-22s %5d files" % (top.name + "/", count))

        if problems:
            print("\nLAYOUT ERRORS:")
            for problem in problems:
                print("  - %s" % problem)
            return 1

        if args.check:
            print("\nOK: layout valid (--check, nothing written).")
            return 0

        out_dir = Path(args.out)
        if not out_dir.is_absolute():
            out_dir = REPO / out_dir
        zip_path = write_zip(staging, out_dir, package, version)
        size_mb = zip_path.stat().st_size / (1024 * 1024)
        print("\nOK: %s (%.2f MB)" % (zip_path.relative_to(REPO), size_mb))
        return 0
    finally:
        shutil.rmtree(tmp, ignore_errors=True)


if __name__ == "__main__":
    sys.exit(main())
