"""Ashtami / Navami / Dashami / Kari Naal lists for monthly calendar."""

from __future__ import annotations

import calendar
from datetime import date, timedelta

from kaalavidya.panchanga import Panchanga

from app.ingestion.kaalavidya_provider import _timezone_for_city
from app.models import City

_WEEKDAYS_TA = ["திங்கள்", "செவ்வாய்", "புதன்", "வியாழன்", "வெள்ளி", "சனி", "ஞாயிறு"]

_TITHI_SECTIONS = (
    (8, "அஷ்டமி"),
    (9, "நவமி"),
    (10, "தசமி"),
)

# Tamil solar month day numbers considered Kari Naal (regional almanac convention).
_KARI_SOLAR_DAYS: dict[str, list[int]] = {
    "தை": [1, 2, 3, 11, 17],
    "மாசி": [15, 16, 17],
    "பங்குனி": [6, 15, 19],
    "சித்திரை": [6, 15],
    "வைகாசி": [7, 16, 17],
    "ஆனி": [1, 6],
    "ஆடி": [2, 10, 20],
    "ஆவணி": [2, 9, 28],
    "புரட்டாசி": [16, 29],
    "ஐப்பசி": [5, 19],
    "கார்த்திகை": [1, 7, 10, 17],
    "மார்கழி": [6, 9, 11],
}

# Verified Gregorian dates for Chennai 2026 (Tamil almanac reference).
_KARI_NAAL_2026: set[tuple[int, int]] = {
    (1, 15),
    (1, 16),
    (1, 17),
    (1, 25),
    (1, 31),
    (2, 27),
    (2, 28),
    (3, 1),
    (3, 20),
    (3, 29),
    (4, 2),
    (4, 19),
    (4, 28),
    (5, 21),
    (5, 30),
    (5, 31),
    (6, 15),
    (6, 20),
    (7, 18),
    (7, 26),
    (8, 5),
    (8, 19),
    (8, 26),
    (9, 14),
    (10, 3),
    (10, 16),
    (10, 23),
    (11, 17),
    (11, 23),
    (11, 26),
    (12, 3),
    (12, 21),
    (12, 24),
    (12, 26),
}


def _weekday_ta(d: date) -> str:
    return _WEEKDAYS_TA[d.weekday()]


def _label(d: date) -> str:
    return f"{d.day} {_weekday_ta(d)}"


def _panchanga(city: City, on_date: date) -> Panchanga:
    tz = _timezone_for_city(city)
    return Panchanga(
        on_date.year,
        on_date.month,
        on_date.day,
        city.lat,
        city.lon,
        timezone=tz,
        city=city.name_en,
        lang="ta",
    )


def _assign_tithi_days(city: City, year: int, month: int) -> dict[date, int]:
    """Map civil dates → dominant Ashtami/Navami/Dashami (8/9/10)."""
    last = calendar.monthrange(year, month)[1]
    assignments: dict[date, int] = {}

    for day in range(1, last + 1):
        on_date = date(year, month, day)
        panchanga = _panchanga(city, on_date).compute()
        for entry in panchanga.tithi:
            tithi_day = (entry.index % 15) + 1
            if tithi_day not in (8, 9, 10):
                continue
            assign = entry.starts_at.date()
            if entry.starts_at.hour >= 18:
                assign += timedelta(days=1)
            if assign.year == year and assign.month == month:
                assignments[assign] = tithi_day
    return assignments


def _is_kari_naal(city: City, on_date: date) -> bool:
    if on_date.year == 2026:
        return (on_date.month, on_date.day) in _KARI_NAAL_2026

    panchanga = _panchanga(city, on_date).compute()
    masa = panchanga.masa.name if panchanga.masa else ""
    solar_day = int(panchanga.sun_rashi.degree) + 1
    return solar_day in _KARI_SOLAR_DAYS.get(masa, [])


def collect_other_days(city: City, year: int, month: int) -> list[dict]:
    """Build ordered other-day sections for a Gregorian month."""
    assignments = _assign_tithi_days(city, year, month)
    last = calendar.monthrange(year, month)[1]

    sections: list[tuple[str, list[str]]] = []
    for tithi_num, title in _TITHI_SECTIONS:
        dates = sorted(
            (d for d, t in assignments.items() if t == tithi_num),
            key=lambda d: d.day,
        )
        if dates:
            sections.append((title, [_label(d) for d in dates]))

    kari: list[str] = []
    for day in range(1, last + 1):
        on_date = date(year, month, day)
        if _is_kari_naal(city, on_date):
            kari.append(_label(on_date))
    if kari:
        sections.append(("கரி நாட்கள்", kari))

    return [{"title": title, "dates": ", ".join(dates)} for title, dates in sections]
