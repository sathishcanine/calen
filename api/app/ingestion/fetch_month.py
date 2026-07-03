"""
Fetch and persist daily + monthly calendar data for a given month or full year.

Default source: kaalavidya (free, no API key, Tamil panchang).
Optional overlay: Prokerala when PROKERALA_CLIENT_ID / PROKERALA_CLIENT_SECRET are set.

Usage:
  python -m app.ingestion.fetch_month --city chennai --year 2026 --month 6
  python -m app.ingestion.fetch_month --city chennai --year 2026 --all-months
  python -m app.ingestion.fetch_month --year 2026 --all-months --all-cities
  python -m app.ingestion.fetch_month --year 2026 --all-months --all-cities --country IN
"""

from __future__ import annotations

import argparse
import logging
import time
from datetime import date

from sqlalchemy.orm import Session

from app.database import Base, SessionLocal, engine
from app.ingestion.kaalavidya_provider import fetch_month_dailies
from app.ingestion.month_builder import build_month_record
from app.ingestion.prokerala_client import ProkeralaClient, merge_prokerala_into_daily
from app.ingestion.seed_cities import ensure_world_cities
from app.models import City, DailyCalendar, MonthCalendar

logging.basicConfig(level=logging.INFO, format="%(levelname)s %(message)s")
logger = logging.getLogger(__name__)


def upsert_daily(db: Session, fields: dict) -> None:
    row = (
        db.query(DailyCalendar)
        .filter(
            DailyCalendar.city_id == fields["city_id"],
            DailyCalendar.gregorian_date == fields["gregorian_date"],
        )
        .first()
    )
    if row:
        for k, v in fields.items():
            setattr(row, k, v)
        row.data_version = (row.data_version or 1) + 1
    else:
        db.add(DailyCalendar(**fields))


def upsert_month(db: Session, fields: dict) -> None:
    row = (
        db.query(MonthCalendar)
        .filter(
            MonthCalendar.city_id == fields["city_id"],
            MonthCalendar.year == fields["year"],
            MonthCalendar.month == fields["month"],
        )
        .first()
    )
    if row:
        for k, v in fields.items():
            setattr(row, k, v)
    else:
        db.add(MonthCalendar(**fields))


def fetch_and_store_month(
    db: Session,
    city: City,
    year: int,
    month: int,
    *,
    prokerala: ProkeralaClient | None = None,
) -> int:
    """Fetch one month; return number of daily rows saved."""
    logger.info("Fetching %s %04d-%02d via kaalavidya for %s...", city.name_en, year, month, city.id)
    daily_rows = fetch_month_dailies(city, year, month)

    if prokerala:
        logger.info("  Prokerala overlay (%d days)...", len(daily_rows))
        for i, row in enumerate(daily_rows):
            d = row["gregorian_date"]
            try:
                pdata = prokerala.fetch_panchang(city.lat, city.lon, d)
                gdata = prokerala.fetch_gowri(city.lat, city.lon, d)
                daily_rows[i] = merge_prokerala_into_daily(row, pdata, gdata)
            except Exception as e:
                logger.warning("  Prokerala skip %s: %s", d, e)

    for fields in daily_rows:
        upsert_daily(db, fields)

    month_fields = build_month_record(city, year, month, daily_rows)
    upsert_month(db, month_fields)
    logger.info("  Saved %d daily + 1 monthly row for %04d-%02d.", len(daily_rows), year, month)
    return len(daily_rows)


def fetch_and_store(
    city_id: str,
    year: int,
    month: int,
    *,
    use_prokerala: bool = True,
) -> None:
    Base.metadata.create_all(bind=engine)
    ensure_world_cities()

    db = SessionLocal()
    prokerala = ProkeralaClient.from_settings() if use_prokerala else None
    if use_prokerala and prokerala is None:
        logger.info("Prokerala credentials not set — using kaalavidya only (free, local).")

    try:
        city = db.query(City).filter(City.id == city_id).first()
        if not city:
            raise SystemExit(f"City not found: {city_id}")

        fetch_and_store_month(db, city, year, month, prokerala=prokerala)
        db.commit()
    finally:
        if prokerala:
            prokerala.close()
        db.close()


def fetch_and_store_year_for_city(
    db: Session,
    city: City,
    year: int,
    *,
    prokerala: ProkeralaClient | None = None,
    from_month: int = 1,
    to_month: int = 12,
) -> int:
    """Fetch all months for one city; return total daily rows saved."""
    total_days = 0
    for month in range(from_month, to_month + 1):
        total_days += fetch_and_store_month(db, city, year, month, prokerala=prokerala)
        db.commit()
    return total_days


def fetch_and_store_all_cities(
    year: int,
    *,
    use_prokerala: bool = True,
    from_month: int = 1,
    to_month: int = 12,
    country: str | None = None,
    skip_existing: bool = False,
) -> None:
    """Precompute calendar data for every seeded city (or filter by country)."""
    Base.metadata.create_all(bind=engine)
    ensure_world_cities()

    if not 1 <= from_month <= 12 or not 1 <= to_month <= 12 or from_month > to_month:
        raise SystemExit("Invalid month range: use 1–12 with from_month <= to_month")

    db = SessionLocal()
    prokerala = ProkeralaClient.from_settings() if use_prokerala else None
    if use_prokerala and prokerala is None:
        logger.info("Prokerala credentials not set — using kaalavidya only (free, local).")

    try:
        query = db.query(City).order_by(City.name_en)
        if country:
            query = query.filter(City.country == country.upper())
        cities = query.all()
        if not cities:
            raise SystemExit("No cities found — run: python -m app.ingestion.seed_cities")

        logger.info(
            "Batch precompute: %d cities, year %d, months %d–%d",
            len(cities),
            year,
            from_month,
            to_month,
        )
        batch_start = time.perf_counter()
        ok = 0
        skipped = 0
        failed: list[str] = []

        for i, city in enumerate(cities, start=1):
            if skip_existing:
                existing = (
                    db.query(DailyCalendar)
                    .filter(
                        DailyCalendar.city_id == city.id,
                        DailyCalendar.gregorian_date >= date(year, from_month, 1),
                    )
                    .first()
                )
                if existing:
                    logger.info("[%d/%d] Skip %s (already has data)", i, len(cities), city.id)
                    skipped += 1
                    continue

            logger.info("[%d/%d] Starting %s (%s)...", i, len(cities), city.id, city.name_en)
            city_start = time.perf_counter()
            try:
                days = fetch_and_store_year_for_city(
                    db,
                    city,
                    year,
                    prokerala=prokerala,
                    from_month=from_month,
                    to_month=to_month,
                )
                ok += 1
                elapsed = time.perf_counter() - city_start
                logger.info(
                    "[%d/%d] Done %s — %d days in %.1fs",
                    i,
                    len(cities),
                    city.id,
                    days,
                    elapsed,
                )
            except Exception as e:
                failed.append(city.id)
                logger.error("[%d/%d] Failed %s: %s", i, len(cities), city.id, e)
                db.rollback()

        total_elapsed = time.perf_counter() - batch_start
        logger.info(
            "Batch complete in %.1f min — ok=%d skipped=%d failed=%d",
            total_elapsed / 60,
            ok,
            skipped,
            len(failed),
        )
        if failed:
            logger.error("Failed cities: %s", ", ".join(failed))
    finally:
        if prokerala:
            prokerala.close()
        db.close()


def fetch_and_store_year(
    city_id: str,
    year: int,
    *,
    use_prokerala: bool = True,
    from_month: int = 1,
    to_month: int = 12,
) -> None:
    """Fetch all months in range (default Jan–Dec) for one city."""
    Base.metadata.create_all(bind=engine)
    ensure_world_cities()

    if not 1 <= from_month <= 12 or not 1 <= to_month <= 12 or from_month > to_month:
        raise SystemExit("Invalid month range: use 1–12 with from_month <= to_month")

    db = SessionLocal()
    prokerala = ProkeralaClient.from_settings() if use_prokerala else None
    if use_prokerala and prokerala is None:
        logger.info("Prokerala credentials not set — using kaalavidya only (free, local).")

    total_days = 0
    try:
        city = db.query(City).filter(City.id == city_id).first()
        if not city:
            raise SystemExit(f"City not found: {city_id}")

        logger.info(
            "Starting full-year fetch: %s %d (months %d–%d)",
            city_id,
            year,
            from_month,
            to_month,
        )

        total_days = fetch_and_store_year_for_city(
            db,
            city,
            year,
            prokerala=prokerala,
            from_month=from_month,
            to_month=to_month,
        )

        months_count = to_month - from_month + 1
        logger.info(
            "Done: %s %d — %d daily rows, %d monthly rows.",
            city_id,
            year,
            total_days,
            months_count,
        )
    finally:
        if prokerala:
            prokerala.close()
        db.close()


def main() -> None:
    parser = argparse.ArgumentParser(description="Fetch calendar data into DB")
    parser.add_argument("--city", default="chennai", help="City id (ignored with --all-cities)")
    parser.add_argument("--year", type=int, default=2026)
    parser.add_argument("--month", type=int, default=None, help="Single month (1–12)")
    parser.add_argument(
        "--all-months",
        action="store_true",
        help="Fetch entire year (all 12 months, or range via --from-month/--to-month)",
    )
    parser.add_argument("--from-month", type=int, default=1, help="First month when using --all-months")
    parser.add_argument("--to-month", type=int, default=12, help="Last month when using --all-months")
    parser.add_argument(
        "--all-cities",
        action="store_true",
        help="Fetch for every seeded city (use with --all-months)",
    )
    parser.add_argument(
        "--country",
        default=None,
        help="With --all-cities, limit to country code e.g. IN, US, LK",
    )
    parser.add_argument(
        "--skip-existing",
        action="store_true",
        help="With --all-cities, skip cities that already have data for the year",
    )
    parser.add_argument("--no-prokerala", action="store_true", help="Skip Prokerala even if configured")
    args = parser.parse_args()

    use_prokerala = not args.no_prokerala

    if args.all_cities:
        if not args.all_months:
            parser.error("--all-cities requires --all-months")
        fetch_and_store_all_cities(
            args.year,
            use_prokerala=use_prokerala,
            from_month=args.from_month,
            to_month=args.to_month,
            country=args.country,
            skip_existing=args.skip_existing,
        )
    elif args.all_months:
        fetch_and_store_year(
            args.city,
            args.year,
            use_prokerala=use_prokerala,
            from_month=args.from_month,
            to_month=args.to_month,
        )
    elif args.month is not None:
        fetch_and_store(args.city, args.year, args.month, use_prokerala=use_prokerala)
    else:
        parser.error("Specify --month N, --all-months, or --all-cities --all-months")


if __name__ == "__main__":
    main()
