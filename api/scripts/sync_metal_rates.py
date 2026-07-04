#!/usr/bin/env python3
"""Sync retail gold/silver rates (Goodreturns / LiveChennai) into SQLite."""

from __future__ import annotations

import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
API = ROOT / "api"
sys.path.insert(0, str(API))

from app.database import SessionLocal  # noqa: E402
from app.data.metal_rates_service import sync_retail  # noqa: E402


def main() -> None:
    db = SessionLocal()
    try:
        live = sync_retail(db)
        print(
            f"Retail {live.rate_date}: 22K ₹{live.gold_22k_per_gram}/g · "
            f"24K ₹{live.gold_24k_per_gram}/g · Silver ₹{live.silver_kg}/kg"
        )
    finally:
        db.close()


if __name__ == "__main__":
    main()
