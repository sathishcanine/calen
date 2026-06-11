"""Load daily spiritual fields from DB or compute via kaalavidya."""

from __future__ import annotations

import json
from datetime import date

from sqlalchemy.orm import Session

from app.ingestion.kaalavidya_provider import fetch_daily
from app.models import City, DailyCalendar


def get_daily_fields(db: Session, city: City, on_date: date) -> dict:
    """Prefer ingested SQLite row; fall back to live kaalavidya."""
    row = (
        db.query(DailyCalendar)
        .filter(DailyCalendar.city_id == city.id, DailyCalendar.gregorian_date == on_date)
        .first()
    )
    if row:
        return {
            "city_id": row.city_id,
            "gregorian_date": row.gregorian_date,
            "month_label_ta": row.month_label_ta,
            "inauspicious_json": row.inauspicious_json or "[]",
            "shoolam_ta": row.shoolam_ta or "",
            "pariharam_ta": row.pariharam_ta or "",
            "gowri_panchangam_json": row.gowri_panchangam_json or "[]",
            "hora_json": row.hora_json or "[]",
        }
    return fetch_daily(city, on_date)
