"""Global இன்று content — one row per date, shared by all Tamil users."""

from __future__ import annotations

import json
from datetime import date, datetime, timedelta
from pathlib import Path
from zoneinfo import ZoneInfo

from sqlalchemy.orm import Session

from app.models import IndruDaily

IST = ZoneInfo("Asia/Kolkata")
POOLS_PATH = Path(__file__).resolve().parent / "indru" / "pools.json"
LOOKAHEAD_DAYS = 7


def _today_ist() -> date:
    return datetime.now(IST).date()


def _load_pools() -> dict:
    raw = POOLS_PATH.read_text(encoding="utf-8")
    return json.loads(raw)


def _pick_by_month_day(items: list[dict], on_date: date) -> dict | None:
    matches = [i for i in items if i.get("month") == on_date.month and i.get("day") == on_date.day]
    if not matches:
        return None
    return matches[on_date.year % len(matches)]


def _pick_rotating(items: list, on_date: date) -> dict | str | None:
    if not items:
        return None
    index = on_date.toordinal() % len(items)
    return items[index]


def _resolve_content(on_date: date) -> dict:
    pools = _load_pools()
    birthday = _pick_by_month_day(pools.get("birthdays", []), on_date)
    event = _pick_by_month_day(pools.get("events", []), on_date)
    fact = _pick_rotating(pools.get("facts", []), on_date)
    quote = _pick_rotating(pools.get("quotes", []), on_date)
    kural = _pick_rotating(pools.get("kurals", []), on_date)

    birthday_ta = ""
    birthday_detail_ta = ""
    if birthday:
        year = birthday.get("birth_year")
        name = birthday.get("name_ta", "")
        birthday_ta = f"{name} ({year})" if year else name
        birthday_detail_ta = birthday.get("detail_ta", "")

    historic_event_ta = ""
    historic_event_detail_ta = ""
    if event:
        year = event.get("year")
        title = event.get("title_ta", "")
        historic_event_ta = f"{title} ({year})" if year else title
        historic_event_detail_ta = event.get("detail_ta", "")

    fact_ta = fact if isinstance(fact, str) else ""
    quote_ta = ""
    quote_author_ta = ""
    if isinstance(quote, dict):
        quote_ta = quote.get("text_ta", "")
        quote_author_ta = quote.get("author_ta", "")

    kural_number = 1
    kural_ta = ""
    kural_meaning_ta = ""
    if isinstance(kural, dict):
        kural_number = int(kural.get("number", 1))
        kural_ta = kural.get("text_ta", "")
        kural_meaning_ta = kural.get("meaning_ta", "")

    return {
        "gregorian_date": on_date,
        "birthday_ta": birthday_ta,
        "birthday_detail_ta": birthday_detail_ta,
        "historic_event_ta": historic_event_ta,
        "historic_event_detail_ta": historic_event_detail_ta,
        "fact_ta": fact_ta,
        "quote_ta": quote_ta,
        "quote_author_ta": quote_author_ta,
        "kural_number": kural_number,
        "kural_ta": kural_ta,
        "kural_meaning_ta": kural_meaning_ta,
        "source": "cron",
    }


def refresh_indru_for_date(db: Session, on_date: date, *, force: bool = False) -> IndruDaily:
    """Resolve pool content and upsert into indru_daily. Skips locked rows unless force."""
    row = db.query(IndruDaily).filter(IndruDaily.gregorian_date == on_date).first()
    if row and row.locked and not force:
        return row

    fields = _resolve_content(on_date)
    if row:
        for key, value in fields.items():
            if key != "gregorian_date":
                setattr(row, key, value)
        if force:
            row.locked = False
    else:
        row = IndruDaily(**fields)
        db.add(row)

    row.updated_at = datetime.utcnow()
    db.commit()
    db.refresh(row)
    return row


def refresh_indru_range(
    db: Session,
    start: date,
    days: int = LOOKAHEAD_DAYS + 1,
    *,
    force: bool = False,
) -> list[IndruDaily]:
    results: list[IndruDaily] = []
    for offset in range(days):
        on_date = start + timedelta(days=offset)
        results.append(refresh_indru_for_date(db, on_date, force=force))
    return results


def get_indru_for_date(db: Session, on_date: date) -> IndruDaily:
    row = db.query(IndruDaily).filter(IndruDaily.gregorian_date == on_date).first()
    if row:
        return row
    return refresh_indru_for_date(db, on_date)


def indru_to_dict(row: IndruDaily) -> dict:
    return {
        "gregorian_date": row.gregorian_date,
        "birthday_ta": row.birthday_ta or "",
        "birthday_detail_ta": row.birthday_detail_ta or "",
        "historic_event_ta": row.historic_event_ta or "",
        "historic_event_detail_ta": row.historic_event_detail_ta or "",
        "fact_ta": row.fact_ta or "",
        "quote_ta": row.quote_ta or "",
        "quote_author_ta": row.quote_author_ta or "",
        "kural_number": row.kural_number or 1,
        "kural_ta": row.kural_ta or "",
        "kural_meaning_ta": row.kural_meaning_ta or "",
        "locked": bool(row.locked),
        "source": row.source or "cron",
        "updated_at": row.updated_at,
    }
