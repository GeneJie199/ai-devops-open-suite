#!/usr/bin/env python3
from pathlib import Path
import sys
from release_docs import copy_documentation

if __name__ == '__main__':
    copy_documentation(Path(__file__).resolve().parents[1], Path(sys.argv[1]).resolve())
