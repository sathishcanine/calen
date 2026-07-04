#!/usr/bin/env python3
"""Deprecated — use sync_metal_rates.py instead."""

import subprocess
import sys
from pathlib import Path

if __name__ == "__main__":
    script = Path(__file__).resolve().parent / "sync_metal_rates.py"
    subprocess.run([sys.executable, str(script), *sys.argv[1:]], check=True)
