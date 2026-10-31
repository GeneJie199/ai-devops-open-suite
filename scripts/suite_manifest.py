#!/usr/bin/env python3
"""Validate and resolve the Open Suite release manifest using the standard library."""

from __future__ import annotations

import hashlib
import json
import pathlib
import re
from typing import Any


SCHEMA = "ai-devops.suite-manifest/v1"
SHA256 = re.compile(r"^[0-9a-f]{64}$")
TOKEN = re.compile(r"^[a-z0-9][a-z0-9._-]*$")
PLATFORMS = (
    "windows-amd64",
    "linux-amd64",
    "linux-arm64",
    "darwin-amd64",
    "darwin-arm64",
)


class ManifestError(ValueError):
    pass


def load_manifest(path: pathlib.Path) -> dict[str, Any]:
    try:
        value = json.loads(path.read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as exc:
        raise ManifestError(f"cannot read manifest {path}: {exc}") from exc
    validate_manifest(value)
    return value


def validate_manifest(value: Any) -> None:
    if not isinstance(value, dict) or value.get("schemaVersion") != SCHEMA:
        raise ManifestError(f"schemaVersion must be {SCHEMA}")
    _token(value.get("suiteVersion"), "suiteVersion")
    if value.get("channel") not in {"development", "prerelease", "stable"}:
        raise ManifestError("channel must be development, prerelease, or stable")
    platforms = value.get("platforms")
    if not isinstance(platforms, dict) or tuple(platforms) != PLATFORMS:
        raise ManifestError(f"platforms must be ordered as {', '.join(PLATFORMS)}")
    components = value.get("components")
    if not isinstance(components, list) or not components:
        raise ManifestError("components must be a non-empty array")
    ids: set[str] = set()
    targets: set[str] = set()
    for component in components:
        if not isinstance(component, dict):
            raise ManifestError("each component must be an object")
        component_id = _token(component.get("id"), "component.id")
        target = _token(component.get("target"), f"{component_id}.target")
        if component_id in ids or target in targets:
            raise ManifestError(f"duplicate component id or target: {component_id}")
        ids.add(component_id)
        targets.add(target)
        _token(component.get("repository"), f"{component_id}.repository")
        _token(component.get("version"), f"{component_id}.version")
        _tag(component.get("tag"), f"{component_id}.tag")
        assets = component.get("assets")
        if not isinstance(assets, dict) or tuple(assets) != PLATFORMS:
            raise ManifestError(f"{component_id}.assets must cover every platform in order")
        for platform, asset in assets.items():
            _asset(asset, f"{component_id}.assets.{platform}")
    protocol = value.get("protocol")
    if not isinstance(protocol, dict):
        raise ManifestError("protocol must be an object")
    _token(protocol.get("repository"), "protocol.repository")
    _token(protocol.get("version"), "protocol.version")
    _tag(protocol.get("tag"), "protocol.tag")
    _filename(protocol.get("asset"), "protocol.asset")
    _digest(protocol.get("sha256"), "protocol.sha256")
    sources = value.get("sources", [])
    if not isinstance(sources, list):
        raise ManifestError("sources must be an array")
    seen_sources = set()
    for source in sources:
        if not isinstance(source, dict):
            raise ManifestError("each source artifact must be an object")
        _token(source.get("repository"), "source.repository")
        _tag(source.get("tag"), "source.tag")
        _filename(source.get("asset"), "source.asset")
        _digest(source.get("sha256"), "source.sha256")
        if not re.fullmatch(r"[0-9a-f]{40}", source.get("revision", "")) or source["asset"] in seen_sources:
            raise ManifestError("invalid source revision or duplicate source asset")
        seen_sources.add(source["asset"])


def resolved_rows(manifest: dict[str, Any], platform: str) -> list[tuple[str, ...]]:
    if platform not in manifest["platforms"]:
        raise ManifestError(f"unsupported platform {platform}")
    rows = [("suite", manifest["schemaVersion"], manifest["suiteVersion"], platform)]
    for component in manifest["components"]:
        asset = component["assets"][platform]
        target = component["target"] + (".exe" if platform.startswith("windows-") else "")
        rows.append((
            "component",
            component["id"],
            component["repository"],
            component["tag"],
            component["version"],
            asset["name"],
            target,
            asset["sha256"],
        ))
    protocol = manifest["protocol"]
    rows.append((
        "protocol",
        protocol["repository"],
        protocol["tag"],
        protocol["version"],
        protocol["asset"],
        protocol["sha256"],
    ))
    return rows


def render_index(manifest: dict[str, Any], platform: str) -> str:
    return "\n".join("|".join(row) for row in resolved_rows(manifest, platform)) + "\n"


def verify_file(path: pathlib.Path, digest: str) -> None:
    actual = hashlib.sha256(path.read_bytes()).hexdigest()
    if actual != digest:
        raise ManifestError(f"SHA-256 mismatch for {path.name}: expected {digest}, got {actual}")


def _token(value: Any, field: str) -> str:
    if not isinstance(value, str) or not TOKEN.fullmatch(value):
        raise ManifestError(f"{field} contains an unsafe or empty token")
    return value


def _tag(value: Any, field: str) -> str:
    value = _token(value, field)
    if not value.startswith("v"):
        raise ManifestError(f"{field} must start with v")
    return value


def _filename(value: Any, field: str) -> str:
    if not isinstance(value, str) or not value or pathlib.PurePath(value).name != value:
        raise ManifestError(f"{field} must be a basename")
    if not re.fullmatch(r"[A-Za-z0-9][A-Za-z0-9._-]*", value):
        raise ManifestError(f"{field} contains unsafe characters")
    return value


def _digest(value: Any, field: str) -> str:
    if not isinstance(value, str) or not SHA256.fullmatch(value):
        raise ManifestError(f"{field} must be a lowercase SHA-256 digest")
    return value


def _asset(value: Any, field: str) -> None:
    if not isinstance(value, dict) or set(value) != {"name", "sha256"}:
        raise ManifestError(f"{field} must contain only name and sha256")
    _filename(value["name"], f"{field}.name")
    _digest(value["sha256"], f"{field}.sha256")
