"""Gowri Panchangam — 8 day + 8 night slots from sunrise/sunset (Tamil tradition)."""

from __future__ import annotations

from datetime import datetime, timedelta
from typing import TYPE_CHECKING

from kaalavidya.surya import compute_next_sunrise

if TYPE_CHECKING:
    from kaalavidya.models import DailyPanchanga

# Cycle: உத்தி, அமிர்தம், ரோகம், லாபம், தனம், சுகம், சோரம், விஷம்
GOWRI_NAMES = ["உத்தி", "அமிர்தம்", "ரோகம்", "லாபம்", "தனம்", "சுகம்", "சோரம்", "விஷம்"]
GOWRI_AUSPICIOUS = [True, True, False, True, True, True, False, False]

# Python weekday Mon=0 … Sun=6 — starting name index at sunrise / sunset
GOWRI_DAY_START = {0: 5, 1: 6, 2: 3, 3: 0, 4: 7, 5: 1, 6: 4}
GOWRI_NIGHT_START = {0: 7, 1: 0, 2: 0, 3: 2, 4: 3, 5: 4, 6: 6}

DAY_SECTIONS = [
    ("காலை", slice(0, 4)),
    ("பிற்பகல்", slice(4, 6)),
    ("மாலை", slice(6, 8)),
]
NIGHT_SECTIONS = [
    ("இரவு", slice(0, 4)),
    ("நள்ளிரவு", slice(4, 6)),
    ("அதிகாலை", slice(6, 8)),
]


def _display_name(name: str) -> str:
    if name == "அமிர்தம்":
        return "அமிர்த"
    return name


def _fmt_slot_time(dt: datetime) -> str:
    return f"{dt.hour}.{dt.minute:02d}"


def _fmt_slot_range(start: datetime, end: datetime) -> str:
    return f"{_fmt_slot_time(start)} - {_fmt_slot_time(end)}"


def _eight_slots(start: datetime, end: datetime, name_start: int) -> list[dict]:
    slot_sec = (end - start).total_seconds() / 8
    slots: list[dict] = []
    for i in range(8):
        s = start + timedelta(seconds=i * slot_sec)
        e = start + timedelta(seconds=(i + 1) * slot_sec)
        idx = (name_start + i) % 8
        name = GOWRI_NAMES[idx]
        slots.append(
            {
                "time": _fmt_slot_range(s, e),
                "name": _display_name(name),
                "auspicious": GOWRI_AUSPICIOUS[idx],
            }
        )
    return slots


def _build_sections(slots: list[dict], section_defs: list[tuple[str, slice]]) -> list[dict]:
    sections = []
    for period, sl in section_defs:
        part = slots[sl]
        if part:
            sections.append({"period": period, "slots": part})
    return sections


def gowri_from_panchanga(
    panchanga: DailyPanchanga,
    *,
    lat: float,
    lon: float,
    timezone: str,
) -> dict:
    """Full Gowri Panchangam for one day."""
    sunrise = panchanga.sun.sunrise
    sunset = panchanga.sun.sunset
    if not sunrise or not sunset:
        return {"sections": []}

    py_weekday = panchanga.date.weekday()
    next_sunrise = compute_next_sunrise(panchanga.date, lat, lon, timezone)

    day_slots = _eight_slots(sunrise, sunset, GOWRI_DAY_START[py_weekday])
    night_slots = _eight_slots(sunset, next_sunrise, GOWRI_NIGHT_START[py_weekday])

    sections = _build_sections(day_slots, DAY_SECTIONS) + _build_sections(night_slots, NIGHT_SECTIONS)
    return {"sections": sections}
