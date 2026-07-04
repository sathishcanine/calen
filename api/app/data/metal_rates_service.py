"""Fetch and store retail gold/silver rates (Goodreturns / LiveChennai)."""

from __future__ import annotations

from datetime import date, datetime, timedelta, timezone

from sqlalchemy import func
from sqlalchemy.orm import Session

from app.data.metal_rates_retail_scraper import RetailDayRate, fetch_retail_snapshot
from app.models import MetalRateDaily, MetalRateMonthly

PERIOD_DAYS = {
    "7d": 7,
    "30d": 30,
    "3m": 90,
    "6m": 180,
    "5y": 365 * 5,
    "10y": 365 * 10,
}

DEFAULT_CITY = "chennai"
SOURCE = "retail"

# Goodreturns / LiveChennai publish the same national retail rate for TN cities.
METAL_CITIES: dict[str, dict] = {
    "chennai": {"name_en": "Chennai", "name_ta": "சென்னை"},
    "coimbatore": {"name_en": "Coimbatore", "name_ta": "கோயம்புத்தூர்"},
    "madurai": {"name_en": "Madurai", "name_ta": "மதுரை"},
    "trichy": {"name_en": "Trichy", "name_ta": "திருச்சி"},
    "salem": {"name_en": "Salem", "name_ta": "சேலம்"},
}


def list_cities() -> list[dict]:
    return [
        {"id": cid, "name_ta": info["name_ta"], "name_en": info["name_en"]}
        for cid, info in METAL_CITIES.items()
    ]


def upsert_daily(
    db: Session,
    *,
    city_id: str,
    rate_date: date,
    gold_22k: float,
    gold_24k: float,
    silver_gram: float,
    silver_kg: float,
    source: str,
    fetched_at: datetime,
) -> None:
    row = (
        db.query(MetalRateDaily)
        .filter(MetalRateDaily.city_id == city_id, MetalRateDaily.rate_date == rate_date)
        .first()
    )
    if row:
        row.gold_22k = gold_22k
        row.gold_24k = gold_24k
        row.silver_gram = silver_gram
        row.silver_kg = silver_kg
        row.source = source
        row.fetched_at = fetched_at
    else:
        db.add(
            MetalRateDaily(
                city_id=city_id,
                rate_date=rate_date,
                gold_22k=gold_22k,
                gold_24k=gold_24k,
                silver_gram=silver_gram,
                silver_kg=silver_kg,
                source=source,
                fetched_at=fetched_at,
            )
        )


def rebuild_monthly(db: Session, city_id: str) -> None:
    rows = (
        db.query(MetalRateDaily)
        .filter(MetalRateDaily.city_id == city_id)
        .order_by(MetalRateDaily.rate_date)
        .all()
    )
    by_month: dict[tuple[int, int], MetalRateDaily] = {}
    for row in rows:
        key = (row.rate_date.year, row.rate_date.month)
        by_month[key] = row

    for daily in by_month.values():
        month_start = date(daily.rate_date.year, daily.rate_date.month, 1)
        existing = (
            db.query(MetalRateMonthly)
            .filter(MetalRateMonthly.city_id == city_id, MetalRateMonthly.rate_month == month_start)
            .first()
        )
        payload = {
            "gold_22k": daily.gold_22k,
            "gold_24k": daily.gold_24k,
            "silver_gram": daily.silver_gram,
            "silver_kg": daily.silver_kg,
            "source": daily.source,
            "fetched_at": daily.fetched_at,
        }
        if existing:
            for k, v in payload.items():
                setattr(existing, k, v)
        else:
            db.add(MetalRateMonthly(city_id=city_id, rate_month=month_start, **payload))


def _persist_day(db: Session, day: RetailDayRate, *, fetched_at: datetime) -> None:
    for city_id in METAL_CITIES:
        upsert_daily(
            db,
            city_id=city_id,
            rate_date=day.rate_date,
            gold_22k=day.gold_22k_per_gram,
            gold_24k=day.gold_24k_per_gram,
            silver_gram=day.silver_gram,
            silver_kg=day.silver_kg,
            source=SOURCE,
            fetched_at=fetched_at,
        )


def sync_retail(db: Session, city: str = DEFAULT_CITY) -> RetailDayRate:
    snapshot = fetch_retail_snapshot(city)
    db.query(MetalRateDaily).filter(MetalRateDaily.source != SOURCE).delete(synchronize_session=False)
    db.query(MetalRateMonthly).filter(MetalRateMonthly.source != SOURCE).delete(synchronize_session=False)

    by_date = {day.rate_date: day for day in snapshot.history}
    by_date[snapshot.live.rate_date] = snapshot.live
    for day in sorted(by_date.values(), key=lambda r: r.rate_date):
        _persist_day(db, day, fetched_at=snapshot.scraped_at)
    for city_id in METAL_CITIES:
        rebuild_monthly(db, city_id)
    db.commit()
    return snapshot.live


def has_today(db: Session) -> bool:
    today = date.today()
    row = (
        db.query(MetalRateDaily)
        .filter(MetalRateDaily.city_id == DEFAULT_CITY, MetalRateDaily.rate_date == today)
        .first()
    )
    return row is not None and row.source == SOURCE


def _daily_rows(db: Session, city_id: str) -> list[dict]:
    rows = (
        db.query(MetalRateDaily)
        .filter(MetalRateDaily.city_id == city_id)
        .order_by(MetalRateDaily.rate_date)
        .all()
    )
    return [
        {
            "date": r.rate_date.isoformat(),
            "gold_22k": r.gold_22k,
            "gold_24k": r.gold_24k,
            "silver_gram": r.silver_gram,
            "silver_kg": r.silver_kg,
        }
        for r in rows
    ]


def _monthly_rows(db: Session, city_id: str) -> list[dict]:
    rows = (
        db.query(MetalRateMonthly)
        .filter(MetalRateMonthly.city_id == city_id)
        .order_by(MetalRateMonthly.rate_month)
        .all()
    )
    return [
        {
            "date": r.rate_month.isoformat(),
            "gold_22k": r.gold_22k,
            "gold_24k": r.gold_24k,
            "silver_gram": r.silver_gram,
            "silver_kg": r.silver_kg,
        }
        for r in rows
    ]


def _last_updated(db: Session) -> datetime | None:
    ts = db.query(func.max(MetalRateDaily.fetched_at)).scalar()
    if ts is None:
        return None
    if ts.tzinfo is None:
        return ts.replace(tzinfo=timezone.utc)
    return ts


def get_admin_status(db: Session) -> dict:
    """Latest stored retail rates for admin dashboard."""
    row = (
        db.query(MetalRateDaily)
        .filter(MetalRateDaily.city_id == DEFAULT_CITY)
        .order_by(MetalRateDaily.rate_date.desc())
        .first()
    )
    last = _last_updated(db)
    daily_count = db.query(MetalRateDaily).filter(MetalRateDaily.city_id == DEFAULT_CITY).count()
    return {
        "source": row.source if row else None,
        "rate_date": row.rate_date.isoformat() if row else None,
        "gold_22k_per_gram": row.gold_22k if row else None,
        "gold_24k_per_gram": row.gold_24k if row else None,
        "silver_kg": row.silver_kg if row else None,
        "fetched_at": last.isoformat().replace("+00:00", "Z") if last else None,
        "daily_history_days": daily_count,
        "cron_schedule_ist": ["10:00", "12:35", "18:35"],
        "rate_source_note": (
            "Retail rates from Goodreturns & LiveChennai — same as consumer gold websites. "
            "Updated daily by ~9:30–10 AM IST."
        ),
    }


def get_rates(db: Session, city_id: str = DEFAULT_CITY, period: str = "7d") -> dict:
    if city_id not in METAL_CITIES:
        raise KeyError(city_id)

    city = METAL_CITIES[city_id]
    daily = _daily_rows(db, city_id)
    monthly = _monthly_rows(db, city_id)
    if not daily:
        raise KeyError(f"No metal rate data for {city_id}")

    today_row = daily[-1]
    yesterday_row = daily[-2] if len(daily) >= 2 else today_row

    days = PERIOD_DAYS.get(period, 7)
    if period in ("5y", "10y"):
        history = monthly[-min(len(monthly), max(days // 30, 12)) :]
    else:
        cutoff = (date.today() - timedelta(days=days)).isoformat()
        history = [r for r in daily if r["date"] >= cutoff]

    def _grams_table(per_gram: float, yesterday_per_gram: float) -> list[dict]:
        rows = []
        for grams in (1, 8, 10):
            today_total = round(per_gram * grams, 2)
            yesterday_total = round(yesterday_per_gram * grams, 2)
            rows.append(
                {
                    "grams": grams,
                    "today": today_total,
                    "yesterday": yesterday_total,
                    "change": round(today_total - yesterday_total, 2),
                }
            )
        return rows

    g22 = today_row["gold_22k"]
    g24 = today_row["gold_24k"]
    y22 = yesterday_row["gold_22k"]
    y24 = yesterday_row["gold_24k"]

    recent = daily[-10:]
    recent_payload = []
    for i, r in enumerate(recent):
        prev = recent[i - 1] if i > 0 else None
        g22_8 = round(r["gold_22k"] * 8, 2)
        g24_8 = round(r["gold_24k"] * 8, 2)
        recent_payload.append(
            {
                "date": r["date"],
                "gold_22k_8g": g22_8,
                "gold_24k_8g": g24_8,
                "change_22k_8g": round(g22_8 - round(prev["gold_22k"] * 8, 2), 2) if prev else 0.0,
                "change_24k_8g": round(g24_8 - round(prev["gold_24k"] * 8, 2), 2) if prev else 0.0,
            }
        )
    recent_payload.reverse()

    silver_hist = list(reversed(daily[-10:]))
    updated = _last_updated(db)

    return {
        "city_id": city_id,
        "city_name_ta": city["name_ta"],
        "city_name_en": city["name_en"],
        "last_updated": updated.isoformat().replace("+00:00", "Z") if updated else None,
        "source": SOURCE,
        "period": period,
        "gold_22k": {
            "per_gram_today": g22,
            "per_gram_yesterday": y22,
            "change_per_gram": round(g22 - y22, 2),
            "table": _grams_table(g22, y22),
        },
        "gold_24k": {
            "per_gram_today": g24,
            "per_gram_yesterday": y24,
            "change_per_gram": round(g24 - y24, 2),
            "table": _grams_table(g24, y24),
        },
        "silver": {
            "per_gram_today": today_row["silver_gram"],
            "per_kg_today": today_row["silver_kg"],
            "history": [
                {"date": r["date"], "per_gram": r["silver_gram"], "per_kg": r["silver_kg"]}
                for r in silver_hist
            ],
        },
        "gold_history": [
            {"date": r["date"], "gold_22k": r["gold_22k"], "gold_24k": r["gold_24k"]}
            for r in history
        ],
        "recent_daily": recent_payload,
    }


# Backwards-compatible aliases used by routers/scripts.
sync_ibja = sync_retail
sync_live = sync_retail
backfill_from_history = sync_retail
