"""Copy the maintained user documentation without touching platform binaries."""
from pathlib import Path
import shutil


def copy_documentation(root: Path, destination: Path) -> None:
    destination.mkdir(parents=True, exist_ok=True)
    for source in root.glob('*.md'):
        shutil.copy2(source, destination / source.name)
    shutil.copytree(root / 'docs', destination / 'docs', dirs_exist_ok=True)
    assets = destination / 'assets'
    assets.mkdir(exist_ok=True)
    for source in (root / 'assets').glob('*.png'):
        shutil.copy2(source, assets / source.name)
