"""Pancha Pakshi activity schedule from traditional DB + kaalavidya sun times."""

from __future__ import annotations

import csv
from datetime import date, datetime, timedelta
from functools import lru_cache
from pathlib import Path

from kaalavidya.panchanga import Panchanga

from app.data.pancha_pakshi_tables import (
    ACTIVITIES_TA,
    ACTIVITY_STRENGTH_TA,
    WEEKDAYS_TA,
    observation_paksha_to_index,
    weekday_index,
)
from app.models import City

_DB_PATH = Path(__file__).resolve().parent / "pancha_pakshi_db.csv"

_WEEKDAY_COL = 0
_PAKSHA_COL = 1
_DAYNIGHT_COL = 2
_BIRD_COL = 3
_ACTIVITY_COL = 4


@lru_cache(maxsize=1)
def _load_db_rows() -> list[tuple[int, int, int, int, int]]:
    rows: list[tuple[int, int, int, int, int]] = []
    with _DB_PATH.open(encoding="utf-8", newline="") as f:
        reader = csv.reader(f)
        next(reader, None)
        for row in reader:
            if len(row) < 5:
                continue
            try:
                rows.append(
                    (
                        int(float(row[_WEEKDAY_COL])),
                        int(float(row[_PAKSHA_COL])),
                        int(float(row[_DAYNIGHT_COL])),
                        int(float(row[_BIRD_COL])),
                        int(float(row[_ACTIVITY_COL])),
                    )
                )
            except ValueError:
                continue
    return rows


def _matching_rows(weekday: int, paksha: int, bird: int, daynight: int) -> list[int]:
    """Return ordered main-activity indices (0–4) for five yamas."""
    filtered = [
        act
        for w, p, dn, b, act in _load_db_rows()
        if w == weekday and p == paksha and b == bird and dn == daynight
    ]
    # Top-level yama activity is every 5th row (PyJHora convention).
    return [filtered[i] for i in range(0, min(len(filtered), 25), 5)]


def _panchanga(city: City, on_date: date):
    tz = "Asia/Kolkata" if city.country == "IN" else "Asia/Kolkata"
    return Panchanga(
        on_date.year,
        on_date.month,
        on_date.day,
        city.lat,
        city.lon,
        timezone=tz,
        city=city.name_en,
        lang="ta",
    ).compute()


def _fmt_time(dt: datetime) -> str:
    return dt.strftime("%H.%M")


def _fmt_range(start: datetime, end: datetime) -> str:
    return f"{_fmt_time(start)} - {_fmt_time(end)}"


def _slot_times(sunrise: datetime, sunset: datetime, is_night: bool) -> list[tuple[datetime, datetime]]:
    if is_night:
        start = sunset
        end = sunrise + timedelta(days=1)
    else:
        start = sunrise
        end = sunset
    span = (end - start) / 5
    return [(start + span * i, start + span * (i + 1)) for i in range(5)]


def _section_slots(
    *,
    weekday: int,
    paksha: int,
    bird: int,
    is_night: bool,
    sunrise: datetime,
    sunset: datetime,
) -> list[dict]:
    activities = _matching_rows(weekday, paksha, bird, 1 if is_night else 0)
    if len(activities) < 5:
        activities = (activities + [0] * 5)[:5]
    slots = []
    for (t0, t1), act_idx in zip(_slot_times(sunrise, sunset, is_night), activities):
        slots.append(
            {
                "time": _fmt_range(t0, t1),
                "activity_ta": ACTIVITIES_TA[act_idx],
                "strength_ta": ACTIVITY_STRENGTH_TA[act_idx],
                "strength_pct": [100, 80, 50, 25, 0][act_idx],
            }
        )
    return slots


def schedule_for_day(
    city: City,
    on_date: date,
    bird_index: int,
    *,
    paksha_index: int | None = None,
) -> dict:
    """Bird activity schedule for one calendar day."""
    p = _panchanga(city, on_date)
    sunrise = p.sun.sunrise
    sunset = p.sun.sunset
    if paksha_index is None:
        paksha_index = observation_paksha_to_index(p.paksha or "")
    wdi = weekday_index(on_date)

    day_slots = _section_slots(
        weekday=wdi,
        paksha=paksha_index,
        bird=bird_index,
        is_night=False,
        sunrise=sunrise,
        sunset=sunset,
    )
    night_slots = _section_slots(
        weekday=wdi,
        paksha=paksha_index,
        bird=bird_index,
        is_night=True,
        sunrise=sunrise,
        sunset=sunset,
    )
    return {
        "weekday_ta": p.vara or WEEKDAYS_TA[wdi],
        "observation_paksha_ta": p.paksha or "",
        "sections": [
            {
                "period_ta": "பகல்பொழுது (காலை 06.01 AM முதல் மாலை 06.00 PM வரை)",
                "slots": day_slots,
            },
            {
                "period_ta": "இரவுப்பொழுது (மாலை 06.01 PM முதல் காலை 06.00 AM வரை)",
                "slots": night_slots,
            },
        ],
    }


def week_grid(bird_index: int, paksha_index: int, *, is_night: bool = False) -> list[dict]:
    """7×5 activity grid for info articles (fixed slot labels like competitor)."""
    slot_labels = [
        "06.01 - 08.24",
        "08.25 - 10.48",
        "10.49 - 01.12",
        "01.13 - 03.36",
        "03.37 - 06.00",
    ]
    rows = []
    for wdi in range(7):
        activities = _matching_rows(wdi, paksha_index, bird_index, 1 if is_night else 0)
        activities = (activities + [0] * 5)[:5]
        rows.append(
            {
                "weekday_ta": WEEKDAYS_TA[wdi],
                "slots": [
                    {"time": slot_labels[i], "activity_ta": ACTIVITIES_TA[activities[i]]}
                    for i in range(5)
                ],
            }
        )
    return rows
