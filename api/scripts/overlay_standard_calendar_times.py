#!/usr/bin/env python3
"""Overlay physical Tamil calendar Nalla Neram/Gowri Nalla Neram into SQLite.

The astronomy library gives location-derived Gowri bands. Daily Tamil calendars
publish a separate standard Nalla Neram summary, and that is what users compare
against physical calendars. This script imports those standard daily summaries
from Golden Chennai monthly calendar pages and updates generated calendar DBs.
"""

from __future__ import annotations

import argparse
import json
import re
import sqlite3
from dataclasses import dataclass
from datetime import date
from html.parser import HTMLParser
from pathlib import Path
from urllib.request import Request, urlopen


ROOT = Path(__file__).resolve().parents[2]
DEFAULT_DBS = [
    ROOT / "api" / "tamilar_calendar.db",
    ROOT / "app" / "assets" / "data" / "calendar.db",
]

MONTH_SLUGS = [
    "january",
    "february",
    "march",
    "april",
    "may",
    "june",
    "july",
    "august",
    "september",
    "october",
    "november",
    "december",
]

DATE_RE = re.compile(r"^(\d{2})-([A-Z]{3})-(\d{4})$")
TIME_RE = re.compile(
    r"(?P<sh>\d{1,2}):(?P<sm>\d{2})\s*(?:AM|PM)?\s*-\s*"
    r"(?P<eh>\d{1,2}):(?P<em>\d{2})\s*(?:AM|PM)?",
    re.IGNORECASE,
)


class TextExtractor(HTMLParser):
    def __init__(self) -> None:
        super().__init__()
        self.lines: list[str] = []

    def handle_data(self, data: str) -> None:
        text = " ".join(data.split())
        if text:
            self.lines.append(text)


@dataclass(frozen=True)
class CalendarTimes:
    gregorian_date: date
    nalla_neram: list[dict[str, str]]
    gowri_nalla_neram: list[dict[str, str]]


def _fetch_month_lines(year: int, month: int) -> list[str]:
    slug = MONTH_SLUGS[month - 1]
    url = f"https://calendar.goldenchennai.com/tamil-monthly-calendar/{slug}-{year}/"
    req = Request(url, headers={"User-Agent": "Mozilla/5.0"})
    with urlopen(req, timeout=30) as response:
        html = response.read().decode("utf-8", errors="replace")

    parser = TextExtractor()
    parser.feed(html)
    return parser.lines


def _normalize_time(value: str) -> str:
    match = TIME_RE.search(value)
    if not match:
        raise ValueError(f"Could not parse time range: {value!r}")
    return (
        f"{int(match.group('sh'))}.{match.group('sm')} - "
        f"{int(match.group('eh'))}.{match.group('em')}"
    )


def _section_values(block: list[str], title: str) -> list[str]:
    try:
        start = block.index(title) + 1
    except ValueError:
        return []

    values: list[str] = []
    for line in block[start:]:
        if line in {
            "Gowri Nalla Neram",
            "Rahu Kalam",
            "Yamagandam",
            "Kuligai Neram",
            "Tithi",
            "Pirai",
        }:
            break
        if line == "-":
            values.append(line)
        elif TIME_RE.search(line):
            values.append(_normalize_time(line))
    return values


def _slots(values: list[str], periods: list[str]) -> list[dict[str, str]]:
    result = []
    for period, value in zip(periods, values):
        if value == "-":
            continue
        result.append({"period": period, "time": value})
    return result


def _parse_month(year: int, month: int, lines: list[str]) -> list[CalendarTimes]:
    records: list[CalendarTimes] = []
    indices = [i for i, line in enumerate(lines) if DATE_RE.match(line)]

    for pos, start in enumerate(indices):
        end = indices[pos + 1] if pos + 1 < len(indices) else len(lines)
        date_line = lines[start]
        match = DATE_RE.match(date_line)
        if not match:
            continue

        day = int(match.group(1))
        record_date = date(year, month, day)
        block = lines[start:end]
        nalla = _slots(_section_values(block, "Nalla Neram"), ["காலை", "மாலை"])
        gowri = _slots(_section_values(block, "Gowri Nalla Neram"), ["காலை", "மாலை"])
        if nalla or gowri:
            records.append(CalendarTimes(record_date, nalla, gowri))

    return records


def fetch_year(year: int) -> list[CalendarTimes]:
    rows: list[CalendarTimes] = []
    for month in range(1, 13):
        rows.extend(_parse_month(year, month, _fetch_month_lines(year, month)))
    return rows


def update_db(db_path: Path, city_id: str, rows: list[CalendarTimes]) -> int:
    conn = sqlite3.connect(db_path)
    try:
        updated = 0
        for row in rows:
            cursor = conn.execute(
                """
                UPDATE daily_calendars
                SET nalla_neram_json = ?, gowri_nalla_neram_json = ?
                WHERE city_id = ? AND gregorian_date = ?
                """,
                (
                    json.dumps(row.nalla_neram, ensure_ascii=False),
                    json.dumps(row.gowri_nalla_neram, ensure_ascii=False),
                    city_id,
                    row.gregorian_date.isoformat(),
                ),
            )
            updated += cursor.rowcount
        conn.commit()
        return updated
    finally:
        conn.close()


def main() -> None:
    parser = argparse.ArgumentParser(
        description="Overlay standard Tamil calendar Nalla Neram into SQLite DBs."
    )
    parser.add_argument("--year", type=int, required=True)
    parser.add_argument("--city-id", default="chennai")
    parser.add_argument(
        "--db",
        action="append",
        type=Path,
        default=None,
        help="SQLite DB to update. May be passed multiple times.",
    )
    args = parser.parse_args()

    rows = fetch_year(args.year)
    if not rows:
        raise SystemExit(f"No calendar rows fetched for {args.year}")

    dbs = args.db if args.db else DEFAULT_DBS
    for db_path in dbs:
        if not db_path.exists():
            raise SystemExit(f"Missing DB: {db_path}")
        updated = update_db(db_path, args.city_id, rows)
        print(f"{db_path}: updated {updated} rows")


if __name__ == "__main__":
    main()
