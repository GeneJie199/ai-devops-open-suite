#!/usr/bin/env python3
"""Verify every locally downloaded release asset against its published checksum."""
import hashlib
from pathlib import Path
import sys

root = Path(sys.argv[1]).resolve()
sums = {}
for line in (root / 'checksums.txt').read_text(encoding='utf-8').splitlines():
    digest, name = line.split(maxsplit=1)
    name = name.lstrip('*')
    if Path(name).name != name or len(digest) != 64:
        raise SystemExit('Invalid checksum entry')
    sums[name] = digest.lower()
count = 0
for asset in root.iterdir():
    if not asset.is_file() or asset.name == 'checksums.txt':
        continue
    if asset.name not in sums:
        raise SystemExit('Unchecksummed asset: ' + asset.name)
    if hashlib.sha256(asset.read_bytes()).hexdigest() != sums[asset.name]:
        raise SystemExit('Hash mismatch: ' + asset.name)
    count += 1
if not count:
    raise SystemExit('No assets verified')
print(f'Verified {count} downloaded release assets')
