#!/usr/bin/env python3
"""Generate all 12 daily raasi palans, optionally without saving."""

from __future__ import annotations

import argparse
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
API = ROOT / "api"
sys.path.insert(0, str(API))

from app.data.raasi_palan_daily_sync import (  # noqa: E402
    generate_all_daily_raasi_palan,
    save_all_daily_raasi_palan,
)


def main() -> None:
    parser = argparse.ArgumentParser(
        description="Sync all 12 daily raasi palans into பொதுப் பலன்."
    )
    parser.add_argument(
        "--dry-run",
        action="store_true",
        help="Generate and print all signs without saving",
    )
    args = parser.parse_args()

    generated = generate_all_daily_raasi_palan()
    if args.dry_run:
        for item in generated:
            print(f"\n{'=' * 20} {item.source.sign_ta} {'=' * 20}\n")
            print(item.general_ta)
        return

    save_all_daily_raasi_palan(generated)
    print(f"Saved all {len(generated)} daily raasis to பொதுப் பலன்")


if __name__ == "__main__":
    main()
