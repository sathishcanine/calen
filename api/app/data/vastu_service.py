"""Build vastu day labels from ingested daily calendar rows."""

from __future__ import annotations

from datetime import date

from sqlalchemy.orm import Session

from app.data.vastu_content import GREGORIAN_MONTH_TA, VASTU_ARTICLES, VASTU_DAYS_BY_YEAR, available_vastu_years
from app.models import DailyCalendar


def _label_from_daily(on_date: date, row: DailyCalendar | None) -> str:
    month_ta = GREGORIAN_MONTH_TA[on_date.month - 1]
    day = on_date.day

    weekday_ta = ""
    tamil_part = ""
    if row:
        parts = (row.month_label_ta or "").split(" - ")
        if len(parts) >= 2:
            weekday_ta = parts[-1].strip()
        sub2 = row.subtitle_line2_ta or ""
        if " - " in sub2:
            tamil_part = sub2.split(" - ", 1)[-1].strip()
        elif sub2:
            tamil_part = sub2.strip()

    if weekday_ta and tamil_part:
        return f"{month_ta} {day} - {weekday_ta} - {tamil_part}"
    if weekday_ta:
        return f"{month_ta} {day} - {weekday_ta}"
    return f"{month_ta} {day}"


def get_vastu_articles() -> list[dict]:
    return list(VASTU_ARTICLES)


def get_vastu_days(db: Session, city_id: str, year: int) -> list[dict]:
    entries = VASTU_DAYS_BY_YEAR.get(year, [])
    days: list[dict] = []
    for entry in entries:
        on_date = entry["gregorian_date"]
        row = (
            db.query(DailyCalendar)
            .filter(DailyCalendar.city_id == city_id, DailyCalendar.gregorian_date == on_date)
            .first()
        )
        days.append(
            {
                "gregorian_date": on_date,
                "label_line1_ta": _label_from_daily(on_date, row),
                "time_line_ta": entry["time_ta"],
            }
        )
    return days


def get_vastu_years() -> list[int]:
    return available_vastu_years()
