#!/usr/bin/env python3
"""Fail when a local Markdown link or image points to a missing file."""

from pathlib import Path
from urllib.parse import unquote
import re
import sys


ROOT = Path(__file__).resolve().parents[1]
LINK = re.compile(r"!?\[[^\]]*\]\(([^)]+)\)")
SKIP_PREFIXES = ("http://", "https://", "mailto:", "#", "data:")


def local_target(markdown: Path, raw: str) -> Path | None:
    raw = raw.strip().split(maxsplit=1)[0].strip("<>")
    if not raw or raw.startswith(SKIP_PREFIXES):
        return None
    path = unquote(raw.split("#", 1)[0].split("?", 1)[0])
    return (markdown.parent / path).resolve()


def main() -> int:
    failures: list[str] = []
    for markdown in sorted(ROOT.rglob("*.md")):
        if ".git" in markdown.parts or ".qa" in markdown.parts:
            continue
        text = markdown.read_text(encoding="utf-8")
        for match in LINK.finditer(text):
            target = local_target(markdown, match.group(1))
            if target is None:
                continue
            try:
                target.relative_to(ROOT)
            except ValueError:
                failures.append(f"{markdown.relative_to(ROOT)}: link escapes repository: {match.group(1)}")
                continue
            if not target.exists():
                failures.append(f"{markdown.relative_to(ROOT)}: missing {match.group(1)}")
    if failures:
        print("\n".join(failures), file=sys.stderr)
        return 1
    print("Documentation links and images are valid")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
