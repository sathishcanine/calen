#!/usr/bin/env python3
"""Scrape, rephrase, and save today's Meenam raasi palan."""

from __future__ import annotations

import argparse
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
API = ROOT / "api"
sys.path.insert(0, str(API))

from app.config import settings  # noqa: E402
from app.data.raasi_palan.astrosage_daily import (  # noqa: E402
    ensure_current_date,
    fetch_daily_horoscope,
    format_general_ta,
    rephrase_daily_horoscope,
)
from app.data.raasi_palan_service import (  # noqa: E402
    SIGN_FIELDS,
    get_sign,
    upsert_sign,
)

MEENAM_INDEX = 11
MEENAM_TA = "மீனம்"
DEFAULT_URL = "https://www.astrosage.com/tamil/rasi-palan/meenam-rasi-palan.asp"


def _arguments() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Sync today's AstroSage Meenam horoscope into பொதுப் பலன்."
    )
    parser.add_argument("--url", default=DEFAULT_URL, help="AstroSage source URL")
    parser.add_argument(
        "--dry-run",
        action="store_true",
        help="Print generated content without changing content.json",
    )
    return parser.parse_args()


def main() -> None:
    args = _arguments()
    horoscope = fetch_daily_horoscope(args.url)
    if horoscope.sign_ta != MEENAM_TA:
        raise RuntimeError(
            f"Expected {MEENAM_TA}, but source page contains {horoscope.sign_ta}"
        )
    ensure_current_date(horoscope)

    rephrased = rephrase_daily_horoscope(
        horoscope,
        api_key=settings.openai_api_key,
        model=settings.openai_model,
    )
    general_ta = format_general_ta(horoscope, rephrased)

    if args.dry_run:
        print(general_ta)
        return

    existing = get_sign("today", MEENAM_INDEX)
    fields = {field: existing.get(field, "") for field in SIGN_FIELDS}
    fields["general_ta"] = general_ta
    saved = upsert_sign("today", MEENAM_INDEX, fields)
    print(
        f"Saved {saved['sign_ta']} பொதுப் பலன் for {saved['period_label']} "
        f"from {horoscope.source_url}"
    )


if __name__ == "__main__":
    main()
