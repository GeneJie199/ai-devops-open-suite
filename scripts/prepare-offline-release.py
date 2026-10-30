#!/usr/bin/env python3
"""Add this exact Suite commit's source without a self-referential source hash."""
import hashlib
import json
from pathlib import Path
import subprocess
import sys

root = Path(__file__).resolve().parents[1]
manifest = json.loads((root / 'suite-manifest.json').read_text(encoding='utf-8'))
tag = 'v' + manifest['suiteVersion']
revision = subprocess.check_output(['git', 'rev-parse', 'HEAD'], cwd=root, text=True).strip()
name = f'ai-devops-open-suite-{tag}-source.tar.gz'
asset = root / 'dist' / name
subprocess.run([sys.executable, str(root / 'scripts/package-corresponding-source.py'), '--output', str(asset)], cwd=root, check=True)
digest = hashlib.sha256(asset.read_bytes()).hexdigest()
cache = root / 'dist/.asset-cache/ai-devops-open-suite' / tag / name
cache.parent.mkdir(parents=True, exist_ok=True)
cache.write_bytes(asset.read_bytes())
manifest.setdefault('sources', []).append(dict(repository='ai-devops-open-suite', tag=tag, revision=revision, asset=name, sha256=digest))
manifest['suiteRevision'] = revision
out = root / '.qa/release/suite-manifest.json'
out.parent.mkdir(parents=True, exist_ok=True)
out.write_text(json.dumps(manifest, indent=2) + '\n', encoding='utf-8')
print(out)
