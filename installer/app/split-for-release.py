#!/usr/bin/env python3
"""Split a file for a GitHub release (2 GiB asset cap) the way the image releases are split.

usage: split-for-release.py FILE [CHUNK_MIB] [--with EXTRA ...]

Writes FILE.part0, FILE.part1, ... (CHUNK_MIB MiB each, default 1900, the
last one shorter) and appends `<sha256>  <name>` lines for every part and for
FILE itself to SHA256SUMS beside FILE, the format `shasum -a 256 -c` reads
(run it to check the parts on disk). A file no larger than one chunk is not
split; only its line is written. FILE is left in place. Each `--with EXTRA`
(an image release's installer_data.json) gets its own line too: the app
workflow checks every name it downloads against SHA256SUMS, and release 10's
first app run failed on a SHA256SUMS without the installer_data.json line.
"""
import hashlib
from pathlib import Path
import sys

BLOCK = 8 * 1024 * 1024


def main() -> None:
    args = sys.argv[1:]
    extras = []
    while "--with" in args:
        i = args.index("--with")
        if i + 1 >= len(args):
            raise SystemExit(__doc__.strip().splitlines()[2])
        extras.append(Path(args[i + 1]))
        del args[i:i + 2]
    if len(args) not in (1, 2):
        raise SystemExit(__doc__.strip().splitlines()[2])
    path = Path(args[0])
    chunk = int(args[1] if len(args) == 2 else 1900) * 1024 * 1024
    for extra in extras:
        if extra.is_symlink() or not extra.is_file():
            raise SystemExit(f"split-for-release: --with needs a regular file: {extra}")
    if path.is_symlink() or not path.is_file() or chunk <= 0:
        raise SystemExit("split-for-release: need a regular file and a positive chunk size")
    size = path.stat().st_size
    whole = hashlib.sha256()
    lines = []
    if size > chunk:
        index = 0
        with path.open("rb") as source:
            while True:
                part = path.with_name(f"{path.name}.part{index}")
                if part.exists():
                    raise SystemExit(f"split-for-release: {part} exists")
                digest = hashlib.sha256()
                written = 0
                with part.open("xb") as target:
                    while written < chunk and (block := source.read(min(BLOCK, chunk - written))):
                        target.write(block)
                        digest.update(block)
                        whole.update(block)
                        written += len(block)
                if written == 0:
                    part.unlink()
                    break
                lines.append(f"{digest.hexdigest()}  {part.name}")
                print(part)
                index += 1
    else:
        with path.open("rb") as source:
            while block := source.read(BLOCK):
                whole.update(block)
    lines.append(f"{whole.hexdigest()}  {path.name}")
    for extra in extras:
        digest = hashlib.sha256()
        with extra.open("rb") as source:
            while block := source.read(BLOCK):
                digest.update(block)
        lines.append(f"{digest.hexdigest()}  {extra.name}")
    with path.with_name("SHA256SUMS").open("a") as sums:
        sums.write("\n".join(lines) + "\n")


if __name__ == "__main__":
    main()
