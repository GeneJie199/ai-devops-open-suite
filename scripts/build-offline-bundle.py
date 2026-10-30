#!/usr/bin/env python3
"""Build a platform-specific full offline Open Suite archive."""

from __future__ import annotations

import argparse
import hashlib
import json
import pathlib
import shutil
import sys
import tarfile
import tempfile
import urllib.error
import urllib.parse
import urllib.request
import zipfile

from suite_manifest import ManifestError, load_manifest, render_index, verify_file


ROOT = pathlib.Path(__file__).resolve().parent.parent
ALLOWED_DOWNLOAD_HOSTS = {
    "github.com",
    "objects.githubusercontent.com",
    "release-assets.githubusercontent.com",
}


def main() -> int:
    parser = argparse.ArgumentParser(description="Build a complete network-independent suite bundle")
    parser.add_argument("--manifest", default=str(ROOT / "suite-manifest.json"))
    parser.add_argument("--platform", required=True)
    parser.add_argument("--output", default=str(ROOT / "dist"))
    parser.add_argument("--cache", default="")
    args = parser.parse_args()
    try:
        manifest = load_manifest(pathlib.Path(args.manifest))
        platform = args.platform
        if platform not in manifest["platforms"]:
            raise ManifestError(f"unsupported platform {platform}")
        output = pathlib.Path(args.output).resolve()
        output.mkdir(parents=True, exist_ok=True)
        cache = pathlib.Path(args.cache).resolve() if args.cache else output / ".asset-cache"
        cache.mkdir(parents=True, exist_ok=True)
        archive = build(manifest, platform, output, cache)
    except (ManifestError, OSError, urllib.error.URLError) as exc:
        print(f"offline bundle failed: {exc}", file=sys.stderr)
        return 1
    print(archive)
    return 0


def build(manifest: dict, platform: str, output: pathlib.Path, cache: pathlib.Path) -> pathlib.Path:
    version = manifest["suiteVersion"]
    archive_stem = f"ai-devops-open-suite-full-offline-v{version}-{platform}"
    with tempfile.TemporaryDirectory(prefix="ai-devops-offline-") as temporary:
        stage = pathlib.Path(temporary) / "ai-devops-open-suite"
        asset_dir = stage / "assets" / platform
        protocol_dir = stage / "protocols"
        asset_dir.mkdir(parents=True)
        protocol_dir.mkdir(parents=True)
        (stage / "suite-manifest.json").write_text(json.dumps(manifest, indent=2) + "\n", encoding="utf-8")
        (stage / "install-assets.txt").write_text(render_index(manifest, platform), encoding="utf-8", newline="\n")
        for relative in (
            "README.md",
            "LICENSE",
            "SECURITY.md",
            "COMPATIBILITY.md",
            "SUPPORT_MATRIX.md",
            "RELEASE_POLICY.md",
            "docs/quickstart.md",
            "docs/offline-install.md",
            "examples/release-report.demo.json",
            "scripts/install-suite.ps1",
            "scripts/install-suite.sh",
            "scripts/suitectl.ps1",
            "scripts/suitectl.sh",
        ):
            source = ROOT / relative
            destination = stage / relative
            destination.parent.mkdir(parents=True, exist_ok=True)
            shutil.copy2(source, destination)
        for component in manifest["components"]:
            asset = component["assets"][platform]
            cached = obtain(cache, component["repository"], component["tag"], asset["name"], asset["sha256"])
            shutil.copy2(cached, asset_dir / asset["name"])
        shutil.copytree(ROOT / "LICENSES", stage / "LICENSES")
        for name in ("NOTICE", "LICENSE_METADATA.json", "third-party-inventory.json", "third-party.cdx.json", "THIRD_PARTY_NOTICES.md", "LICENSING_HISTORY.md", "LICENSE_POLICY.md", "COMMERCIAL_LICENSE.md", "COMMERCIALIZATION.md", "TRADEMARK_POLICY.md", "CONTRIBUTOR_POLICY.md"):
            shutil.copy2(ROOT / name, stage / name)
        # Components are historical independent artifacts, not relicensed by aggregation.
        licenses = {item["id"]: {"version": item["version"], "license": "Apache-2.0" if item["version"].startswith("1.") else "AGPL-3.0-only" if item["version"].startswith("2.") else "NOASSERTION"} for item in manifest["components"]}
        (stage / "component-licenses.json").write_text(json.dumps(licenses, indent=2) + "\n", encoding="utf-8")
        protocol = manifest["protocol"]
        cached_protocol = obtain(cache, protocol["repository"], protocol["tag"], protocol["asset"], protocol["sha256"])
        shutil.copy2(cached_protocol, protocol_dir / protocol["asset"])
        if not platform.startswith("windows-"):
            for name in ("install-suite.sh", "suitectl.sh"):
                (stage / "scripts" / name).chmod(0o755)
        write_bundle_manifest(stage, manifest, platform)
        if platform.startswith("windows-"):
            archive = output / f"{archive_stem}.zip"
            write_zip(stage, archive)
        else:
            archive = output / f"{archive_stem}.tar.gz"
            write_tar(stage, archive)
    return archive


def obtain(cache: pathlib.Path, repository: str, tag: str, name: str, digest: str) -> pathlib.Path:
    path = cache / repository / tag / name
    if path.is_file():
        try:
            verify_file(path, digest)
            return path
        except ManifestError:
            path.unlink()
    path.parent.mkdir(parents=True, exist_ok=True)
    temporary = path.with_suffix(path.suffix + ".part")
    url = f"https://github.com/GeneJie199/{repository}/releases/download/{tag}/{name}"
    request = urllib.request.Request(url, headers={"User-Agent": "ai-devops-offline-builder/1"})
    try:
        with urllib.request.urlopen(request, timeout=60) as response, temporary.open("wb") as target:
            final_host = urllib.parse.urlparse(response.url).hostname
            if final_host not in ALLOWED_DOWNLOAD_HOSTS:
                raise ManifestError(f"download redirected to an untrusted host: {final_host}")
            shutil.copyfileobj(response, target)
        verify_file(temporary, digest)
        temporary.replace(path)
    finally:
        temporary.unlink(missing_ok=True)
    return path


def write_bundle_manifest(stage: pathlib.Path, manifest: dict, platform: str) -> None:
    files = []
    for path in sorted(item for item in stage.rglob("*") if item.is_file()):
        files.append({
            "path": path.relative_to(stage).as_posix(),
            "size": path.stat().st_size,
            "sha256": hashlib.sha256(path.read_bytes()).hexdigest(),
        })
    value = {
        "schemaVersion": "ai-devops.offline-bundle/v1",
        "suiteVersion": manifest["suiteVersion"],
        "platform": platform,
        "networkRequired": False,
        "files": files,
    }
    (stage / "bundle-manifest.json").write_text(json.dumps(value, indent=2) + "\n", encoding="utf-8", newline="\n")


def write_zip(stage: pathlib.Path, archive: pathlib.Path) -> None:
    archive.unlink(missing_ok=True)
    with zipfile.ZipFile(archive, "w", compression=zipfile.ZIP_DEFLATED, compresslevel=9) as target:
        for path in sorted(item for item in stage.rglob("*") if item.is_file()):
            relative = pathlib.Path(stage.name) / path.relative_to(stage)
            info = zipfile.ZipInfo(relative.as_posix(), date_time=(2026, 1, 1, 0, 0, 0))
            info.compress_type = zipfile.ZIP_DEFLATED
            info.external_attr = (0o755 if path.stat().st_mode & 0o111 else 0o644) << 16
            target.writestr(info, path.read_bytes(), compresslevel=9)


def write_tar(stage: pathlib.Path, archive: pathlib.Path) -> None:
    archive.unlink(missing_ok=True)
    with tarfile.open(archive, "w:gz", compresslevel=9) as target:
        for path in [stage, *sorted(stage.rglob("*"))]:
            relative = pathlib.Path(stage.name) / path.relative_to(stage)
            info = target.gettarinfo(str(path), arcname=relative.as_posix())
            info.uid = info.gid = 0
            info.uname = info.gname = "root"
            info.mtime = 0
            if path.is_dir() or relative.as_posix().endswith(("/install-suite.sh", "/suitectl.sh")):
                info.mode = 0o755
            else:
                info.mode = 0o644
            if path.is_file():
                with path.open("rb") as source:
                    target.addfile(info, source)
            else:
                target.addfile(info)


if __name__ == "__main__":
    raise SystemExit(main())
