"""Free local panchang computation via kaalavidya (MIT, no API key)."""

from __future__ import annotations

import calendar
from datetime import date

from kaalavidya.panchanga import Panchanga

from app.ingestion.mappers import TAMIL_MONTHS, daily_from_panchanga
from app.models import City


def fetch_daily(city: City, on_date: date) -> dict:
    tz = _timezone_for_city(city)
    p = Panchanga(
        on_date.year,
        on_date.month,
        on_date.day,
        city.lat,
        city.lon,
        timezone=tz,
        city=city.name_en,
        lang="ta",
    )
    return daily_from_panchanga(
        city.id,
        p.compute(),
        lat=city.lat,
        lon=city.lon,
        timezone=tz,
    )


def fetch_month_dailies(city: City, year: int, month: int) -> list[dict]:
    last = calendar.monthrange(year, month)[1]
    rows = []
    for day in range(1, last + 1):
        rows.append(fetch_daily(city, date(year, month, day)))
    return rows


def _timezone_for_city(city: City) -> str:
    if city.country == "IN":
        return "Asia/Kolkata"
    if city.country == "SG":
        return "Asia/Singapore"
    if city.country == "LK":
        return "Asia/Colombo"
    if city.country == "MY":
        return "Asia/Kuala_Lumpur"
    # Fallback from offset (approximate)
    offsets = {5.5: "Asia/Kolkata", 8.0: "Asia/Singapore"}
    return offsets.get(city.tz_offset, "Asia/Kolkata")


def month_label(year: int, month: int) -> str:
    return f"{TAMIL_MONTHS[month - 1]} - {year}"
