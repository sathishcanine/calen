"""Seed / upsert world cities into the database."""

from __future__ import annotations

import json
import logging
from pathlib import Path

from sqlalchemy import inspect, text
from sqlalchemy.orm import Session

from app.data.world_cities import WORLD_CITIES, CitySeed
from app.database import Base, SessionLocal, engine
from app.models import City

logger = logging.getLogger(__name__)


def _ensure_timezone_column() -> None:
    """Add cities.timezone on existing SQLite DBs (create_all does not alter)."""
    insp = inspect(engine)
    if not insp.has_table("cities"):
        return
    columns = {col["name"] for col in insp.get_columns("cities")}
    if "timezone" in columns:
        return
    with engine.begin() as conn:
        conn.execute(text("ALTER TABLE cities ADD COLUMN timezone VARCHAR(64)"))
    logger.info("Added cities.timezone column")


def _upsert_city(db: Session, seed: CitySeed) -> None:
    row = db.query(City).filter(City.id == seed.id).first()
    fields = {
        "name_en": seed.name_en,
        "name_ta": seed.name_ta,
        "lat": seed.lat,
        "lon": seed.lon,
        "tz_offset": seed.tz_offset,
        "country": seed.country,
        "timezone": seed.timezone,
        "is_default": seed.is_default,
    }
    if row:
        for key, value in fields.items():
            setattr(row, key, value)
    else:
        db.add(City(id=seed.id, **fields))


def seed_all_cities(db: Session, cities: list[CitySeed] | None = None) -> int:
    """Upsert all cities; return count processed."""
    source = cities if cities is not None else WORLD_CITIES
    for seed in source:
        _upsert_city(db, seed)
    return len(source)


def load_cities_from_json(path: Path) -> list[CitySeed]:
    """Load extra cities from JSON array [{id, name_en, name_ta, lat, lon, country, timezone, ...}]."""
    raw = json.loads(path.read_text(encoding="utf-8"))
    cities: list[CitySeed] = []
    for item in raw:
        cities.append(
            CitySeed(
                id=item["id"],
                name_en=item["name_en"],
                name_ta=item.get("name_ta", item["name_en"]),
                lat=float(item["lat"]),
                lon=float(item["lon"]),
                country=item.get("country", "IN"),
                timezone=item["timezone"],
                tz_offset=float(item.get("tz_offset", 5.5)),
                is_default=bool(item.get("is_default", False)),
            )
        )
    return cities


def ensure_world_cities(*, json_path: Path | None = None) -> int:
    """Create tables, migrate schema, upsert built-in (+ optional JSON) cities."""
    Base.metadata.create_all(bind=engine)
    _ensure_timezone_column()

    db = SessionLocal()
    try:
        cities = list(WORLD_CITIES)
        if json_path and json_path.exists():
            cities.extend(load_cities_from_json(json_path))
        count = seed_all_cities(db, cities)
        db.commit()
        logger.info("Seeded %d cities", count)
        return count
    finally:
        db.close()


def main() -> None:
    import argparse

    logging.basicConfig(level=logging.INFO, format="%(levelname)s %(message)s")
    parser = argparse.ArgumentParser(description="Seed world cities into DB")
    parser.add_argument(
        "--json",
        type=Path,
        default=None,
        help="Optional JSON file with additional cities",
    )
    args = parser.parse_args()
    count = ensure_world_cities(json_path=args.json)
    print(f"Done — {count} cities in database.")


if __name__ == "__main__":
    main()
