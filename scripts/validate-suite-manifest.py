#!/usr/bin/env python3

from __future__ import annotations

import argparse
import pathlib
import sys

from suite_manifest import PLATFORMS, ManifestError, load_manifest, render_index


def main() -> int:
    parser = argparse.ArgumentParser(description="Validate an AI DevOps Open Suite manifest")
    parser.add_argument("manifest", nargs="?", default="suite-manifest.json")
    parser.add_argument("--indexes", default="manifests", help="directory containing generated platform indexes")
    parser.add_argument("--write-indexes", action="store_true")
    args = parser.parse_args()
    root = pathlib.Path(args.manifest).resolve().parent
    try:
        manifest = load_manifest(pathlib.Path(args.manifest))
        index_dir = root / args.indexes
        if args.write_indexes:
            index_dir.mkdir(parents=True, exist_ok=True)
        for platform in PLATFORMS:
            expected = render_index(manifest, platform)
            path = index_dir / f"install-{platform}.txt"
            if args.write_indexes:
                path.write_text(expected, encoding="utf-8", newline="\n")
            elif not path.is_file() or path.read_text(encoding="utf-8") != expected:
                raise ManifestError(f"generated index is missing or stale: {path}")
    except ManifestError as exc:
        print(f"manifest validation failed: {exc}", file=sys.stderr)
        return 1
    print(f"Suite manifest is valid: {manifest['suiteVersion']} ({len(manifest['components'])} components, {len(PLATFORMS)} platforms)")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
