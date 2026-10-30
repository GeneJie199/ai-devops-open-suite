#!/usr/bin/env python3
"""Verify an offline bundle without extracting it."""

from __future__ import annotations

import argparse
import hashlib
import io
import json
import pathlib
import sys
import tarfile
import zipfile

from suite_manifest import ManifestError, render_index, validate_manifest


ROOT = "ai-devops-open-suite/"


def main() -> int:
    parser = argparse.ArgumentParser(description="Verify full offline bundle integrity and layout")
    parser.add_argument("archives", nargs="+")
    args = parser.parse_args()
    try:
        for value in args.archives:
            verify_archive(pathlib.Path(value))
    except (ManifestError, OSError, ValueError, json.JSONDecodeError, tarfile.TarError, zipfile.BadZipFile) as exc:
        print(f"offline bundle verification failed: {exc}", file=sys.stderr)
        return 1
    return 0


def verify_archive(path: pathlib.Path) -> None:
    files, executable = read_archive(path)
    bundle_manifest = decode_json(files, "bundle-manifest.json")
    if bundle_manifest.get("schemaVersion") != "ai-devops.offline-bundle/v1" or bundle_manifest.get("networkRequired") is not False:
        raise ManifestError(f"{path.name}: invalid offline bundle metadata")
    manifest = decode_json(files, "suite-manifest.json")
    if "LICENSE_METADATA.json" in files:
        for required in ("NOTICE", "LICENSES/AGPL-3.0-only.txt", "LICENSES/Apache-2.0.txt", "third-party-inventory.json", "third-party.cdx.json", "component-licenses.json"):
            if required not in files:
                raise ManifestError(f"{path.name}: missing bundled license evidence {required}")
    validate_manifest(manifest)
    platform = bundle_manifest.get("platform")
    if platform not in manifest["platforms"] or bundle_manifest.get("suiteVersion") != manifest["suiteVersion"]:
        raise ManifestError(f"{path.name}: suite version or platform mismatch")
    declared = bundle_manifest.get("files")
    if not isinstance(declared, list):
        raise ManifestError(f"{path.name}: bundle files must be an array")
    expected_paths = set()
    for item in declared:
        if not isinstance(item, dict) or set(item) != {"path", "size", "sha256"}:
            raise ManifestError(f"{path.name}: invalid file record")
        name = item["path"]
        if name in expected_paths or name not in files:
            raise ManifestError(f"{path.name}: missing or duplicate declared file {name}")
        expected_paths.add(name)
        content = files[name]
        if len(content) != item["size"] or hashlib.sha256(content).hexdigest() != item["sha256"]:
            raise ManifestError(f"{path.name}: file digest mismatch for {name}")
    actual_paths = set(files) - {"bundle-manifest.json"}
    if actual_paths != expected_paths:
        raise ManifestError(f"{path.name}: undeclared or missing files: {sorted(actual_paths ^ expected_paths)}")
    if files.get("install-assets.txt", b"").decode("utf-8") != render_index(manifest, platform):
        raise ManifestError(f"{path.name}: install index does not match suite manifest")
    for component in manifest["components"]:
        asset = component["assets"][platform]
        name = f"assets/{platform}/{asset['name']}"
        content = files.get(name)
        if content is None or hashlib.sha256(content).hexdigest() != asset["sha256"]:
            raise ManifestError(f"{path.name}: component asset mismatch for {name}")
    protocol = manifest["protocol"]
    protocol_name = f"protocols/{protocol['asset']}"
    content = files.get(protocol_name)
    if content is None or hashlib.sha256(content).hexdigest() != protocol["sha256"]:
        raise ManifestError(f"{path.name}: protocol asset mismatch")
    if not platform.startswith("windows-"):
        for script in ("scripts/install-suite.sh", "scripts/suitectl.sh"):
            if not executable.get(script, False):
                raise ManifestError(f"{path.name}: {script} is not executable")
    print(f"Offline bundle is valid: {path.name} ({platform}, {len(declared)} files)")


def read_archive(path: pathlib.Path) -> tuple[dict[str, bytes], dict[str, bool]]:
    files: dict[str, bytes] = {}
    executable: dict[str, bool] = {}
    if path.suffix == ".zip":
        with zipfile.ZipFile(path) as archive:
            for info in archive.infolist():
                relative = safe_relative(info.filename)
                if info.is_dir():
                    continue
                files[relative] = archive.read(info)
                executable[relative] = bool((info.external_attr >> 16) & 0o111)
    elif path.name.endswith(".tar.gz"):
        with tarfile.open(path, "r:gz") as archive:
            for info in archive.getmembers():
                relative = safe_relative(info.name)
                if info.issym() or info.islnk():
                    raise ManifestError(f"{path.name}: links are not allowed: {info.name}")
                if not info.isfile():
                    continue
                extracted = archive.extractfile(info)
                if extracted is None:
                    raise ManifestError(f"{path.name}: cannot read {info.name}")
                files[relative] = extracted.read()
                executable[relative] = bool(info.mode & 0o111)
    else:
        raise ManifestError(f"unsupported archive extension: {path}")
    return files, executable


def safe_relative(name: str) -> str:
    normalized = pathlib.PurePosixPath(name)
    if name.rstrip("/") == ROOT.rstrip("/"):
        return ""
    if normalized.is_absolute() or ".." in normalized.parts or not name.startswith(ROOT):
        raise ManifestError(f"unsafe archive path: {name}")
    relative = name[len(ROOT):].rstrip("/")
    if not relative:
        raise ManifestError(f"invalid archive path: {name}")
    return relative


def decode_json(files: dict[str, bytes], name: str) -> dict:
    if name not in files:
        raise ManifestError(f"bundle is missing {name}")
    value = json.load(io.BytesIO(files[name]))
    if not isinstance(value, dict):
        raise ManifestError(f"{name} must contain an object")
    return value


if __name__ == "__main__":
    raise SystemExit(main())
