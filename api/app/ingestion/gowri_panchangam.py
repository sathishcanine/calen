"""Gowri Panchangam — 8 day + 8 night slots from sunrise/sunset (Tamil tradition)."""

from __future__ import annotations

from datetime import datetime, timedelta
from typing import TYPE_CHECKING

from kaalavidya.surya import compute_next_sunrise

if TYPE_CHECKING:
    from kaalavidya.models import DailyPanchanga

# Athiban / epanchang / Nithra-style per-weekday sequences (NOT a simple rotation).
GOWRI_DAY_SEQUENCE: dict[int, list[str]] = {
    6: ["உத்தி", "அமிர்தம்", "ரோகம்", "லாபம்", "தனம்", "சுகம்", "சோரம்", "விஷம்"],  # Sunday
    0: ["அமிர்தம்", "விஷம்", "ரோகம்", "லாபம்", "தனம்", "சுகம்", "சோரம்", "உத்தி"],  # Monday
    1: ["ரோகம்", "லாபம்", "தனம்", "சுகம்", "சோரம்", "உத்தி", "விஷம்", "அமிர்தம்"],  # Tuesday
    2: ["லாபம்", "தனம்", "சுகம்", "சோரம்", "விஷம்", "உத்தி", "அமிர்தம்", "ரோகம்"],  # Wednesday
    3: ["தனம்", "சுகம்", "சோரம்", "உத்தி", "அமிர்தம்", "விஷம்", "ரோகம்", "லாபம்"],  # Thursday
    4: ["சுகம்", "சோரம்", "உத்தி", "விஷம்", "அமிர்தம்", "ரோகம்", "லாபம்", "தனம்"],  # Friday
    5: ["சோரம்", "உத்தி", "விஷம்", "அமிர்தம்", "ரோகம்", "லாபம்", "தனம்", "சுகம்"],  # Saturday
}

GOWRI_NIGHT_SEQUENCE: dict[int, list[str]] = {
    6: ["தனம்", "சுகம்", "சோரம்", "விஷம்", "உத்தி", "அமிர்தம்", "ரோகம்", "லாபம்"],
    0: ["சுகம்", "சோரம்", "உத்தி", "அமிர்தம்", "விஷம்", "ரோகம்", "லாபம்", "தனம்"],
    1: ["சோரம்", "உத்தி", "விஷம்", "அமிர்தம்", "ரோகம்", "லாபம்", "தனம்", "சுகம்"],
    2: ["உத்தி", "அமிர்தம்", "ரோகம்", "லாபம்", "தனம்", "சுகம்", "சோரம்", "விஷம்"],
    3: ["அமிர்தம்", "விஷம்", "ரோகம்", "லாபம்", "தனம்", "சுகம்", "சோரம்", "உத்தி"],
    4: ["ரோகம்", "லாபம்", "தனம்", "சுகம்", "சோரம்", "உத்தி", "விஷம்", "அமிர்தம்"],
    5: ["லாபம்", "தனம்", "சுகம்", "சோரம்", "உத்தி", "விஷம்", "அமிர்தம்", "ரோகம்"],
}

INAUSPICIOUS = frozenset({"ரோகம்", "சோரம்", "விஷம்"})

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


def _is_auspicious(name: str) -> bool:
    return name not in INAUSPICIOUS


def _display_name(name: str) -> str:
    if name == "அமிர்தம்":
        return "அமிர்த"
    return name


def _fmt_slot_time(dt: datetime) -> str:
    return f"{dt.hour}.{dt.minute:02d}"


def _fmt_slot_range(start: datetime, end: datetime) -> str:
    return f"{_fmt_slot_time(start)} - {_fmt_slot_time(end)}"


# Canonical Tamil almanac labels per 8-slot index (Athiban columns).
# Nithra / mPanchang show the first hour of each band for summary rows.
CANONICAL_NALLA_LABELS: list[tuple[str, str]] = [
    ("6.00", "7.30"),
    ("7.30", "8.30"),
    ("9.00", "10.30"),
    ("10.30", "11.30"),
    ("12.00", "1.30"),
    ("1.30", "2.30"),
    ("3.00", "4.30"),
    ("4.30", "5.30"),
]


def _canonical_nalla_time(slot_index: int) -> str:
    start, end = CANONICAL_NALLA_LABELS[slot_index]
    return f"{start} - {end}"


def _round_nalla_range(start: datetime, end: datetime) -> str:
    """Fallback astronomical 30-min window inside a Gowri slot."""

    def ceil_half_hour(dt: datetime) -> datetime:
        base = dt.replace(second=0, microsecond=0)
        if dt.minute % 30 == 0 and dt.second == 0:
            return base
        add = 30 - (dt.minute % 30)
        return base + timedelta(minutes=add)

    def floor_half_hour(dt: datetime) -> datetime:
        base = dt.replace(second=0, microsecond=0)
        return base - timedelta(minutes=dt.minute % 30)

    rs = ceil_half_hour(start)
    re = floor_half_hour(end)
    if re <= rs:
        re = rs + timedelta(minutes=30)
    return f"{_fmt_slot_time(rs)} - {_fmt_slot_time(re)}"


def _eight_slots(start: datetime, end: datetime, names: list[str]) -> list[dict]:
    slot_sec = (end - start).total_seconds() / 8
    slots: list[dict] = []
    for i in range(8):
        s = start + timedelta(seconds=i * slot_sec)
        e = start + timedelta(seconds=(i + 1) * slot_sec)
        name = names[i]
        slots.append(
            {
                "time": _fmt_slot_range(s, e),
                "name": _display_name(name),
                "auspicious": _is_auspicious(name),
                "starts_at": s.isoformat(),
                "ends_at": e.isoformat(),
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


def nalla_neram_from_gowri(day_slots: list[dict], night_slots: list[dict]) -> list[dict]:
    """
    நல்ல நேரம் — first auspicious morning half + last auspicious afternoon half (Tamil almanac).
    """
    out: list[dict] = []
    morning_idx = next((i for i in range(0, 4) if day_slots[i]["auspicious"]), None)
    if morning_idx is not None:
        out.append({"period": "காலை", "time": _canonical_nalla_time(morning_idx)})

    afternoon_idx = next((i for i in range(7, 3, -1) if day_slots[i]["auspicious"]), None)
    if afternoon_idx is not None:
        out.append({"period": "மாலை", "time": _canonical_nalla_time(afternoon_idx)})

    return out


def gowri_nalla_neram_from_gowri(day_slots: list[dict], night_slots: list[dict]) -> list[dict]:
    """
    கௌரி நல்ல நேரம் — last auspicious morning Gowri + first auspicious early night Gowri.
    """
    out: list[dict] = []
    morning_idx = next((i for i in range(3, -1, -1) if day_slots[i]["auspicious"]), None)
    if morning_idx is not None:
        out.append({"period": "காலை", "time": _canonical_nalla_time(morning_idx)})

    evening_idx = next((i for i in range(0, 4) if night_slots[i]["auspicious"]), None)
    if evening_idx is not None:
        out.append({"period": "மாலை", "time": _canonical_nalla_time(evening_idx)})

    return out


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
        return {"sections": [], "day_slots": [], "night_slots": []}

    py_weekday = panchanga.date.weekday()
    next_sunrise = compute_next_sunrise(panchanga.date, lat, lon, timezone)

    day_slots = _eight_slots(sunrise, sunset, GOWRI_DAY_SEQUENCE[py_weekday])
    night_slots = _eight_slots(sunset, next_sunrise, GOWRI_NIGHT_SEQUENCE[py_weekday])

    sections = _build_sections(day_slots, DAY_SECTIONS) + _build_sections(night_slots, NIGHT_SECTIONS)
    return {"sections": sections, "day_slots": day_slots, "night_slots": night_slots}
