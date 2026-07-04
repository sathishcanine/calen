#!/usr/bin/env python3
"""Build Chennai-only tamilar_calendar.db from the multi-city archive."""

from __future__ import annotations

import sqlite3
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
API = ROOT / "api"
ARCHIVE = API / "calender-all-citiest-to-use-later.db"
OUT = API / "tamilar_calendar.db"
CITY = "chennai"


def main() -> None:
    if not ARCHIVE.exists():
        raise SystemExit(f"Missing archive: {ARCHIVE}")

    if OUT.exists():
        OUT.unlink()

    arch = sqlite3.connect(ARCHIVE)
    try:
        tables = arch.execute(
            """
            SELECT name, sql FROM sqlite_master
            WHERE type = 'table' AND name NOT LIKE 'sqlite_%'
            ORDER BY name
            """
        ).fetchall()
    finally:
        arch.close()

    out = sqlite3.connect(OUT)
    try:
        for _, sql in tables:
            if sql:
                out.execute(sql)

        out.execute("ATTACH DATABASE ? AS src", (str(ARCHIVE),))
        out.execute("INSERT INTO cities SELECT * FROM src.cities WHERE id = ?", (CITY,))
        out.execute(
            "INSERT INTO daily_calendars SELECT * FROM src.daily_calendars WHERE city_id = ?",
            (CITY,),
        )
        out.execute(
            "INSERT INTO month_calendars SELECT * FROM src.month_calendars WHERE city_id = ?",
            (CITY,),
        )
        out.commit()
        out.execute("DETACH DATABASE src")
        out.execute("VACUUM")
    finally:
        out.close()

    mb = OUT.stat().st_size / 1024 / 1024
    daily = sqlite3.connect(OUT).execute("SELECT COUNT(*) FROM daily_calendars").fetchone()[0]
    monthly = sqlite3.connect(OUT).execute("SELECT COUNT(*) FROM month_calendars").fetchone()[0]
    print(f"Wrote {OUT} ({mb:.2f} MB) — {daily} daily, {monthly} monthly rows for {CITY}.")


if __name__ == "__main__":
    main()
