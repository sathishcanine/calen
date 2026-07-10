"""Gowri Panchangam — 8 day + 8 night slots from sunrise/sunset (Tamil tradition)."""

from __future__ import annotations

from datetime import datetime, timedelta
from typing import TYPE_CHECKING, Iterable

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


def _fmt_summary_time(dt: datetime) -> str:
    """12-hour Tamil almanac style for summary rows (13:15 → 1.15)."""
    hour = dt.hour % 12 or 12
    return f"{hour}.{dt.minute:02d}"


def _fmt_slot_range(start: datetime, end: datetime) -> str:
    return f"{_fmt_slot_time(start)} - {_fmt_slot_time(end)}"


def _floor_quarter_hour(dt: datetime) -> datetime:
    base = dt.replace(second=0, microsecond=0)
    return base - timedelta(minutes=dt.minute % 15)


def _ceil_quarter_hour(dt: datetime) -> datetime:
    base = dt.replace(second=0, microsecond=0)
    if dt.minute % 15 == 0 and dt.second == 0:
        return base
    return base + timedelta(minutes=15 - (dt.minute % 15))


def _round_nalla_range(start: datetime, end: datetime) -> str:
    """30-min window inside a Gowri slot (centred on the astronomical band)."""

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


def _summary_slot_time(slot: dict, *, style: str, start_offset_minutes: int = 0) -> str:
    """Location-specific summary window inside a Gowri slot."""
    start = datetime.fromisoformat(slot["starts_at"])
    end = datetime.fromisoformat(slot["ends_at"])
    if style == "centered_half":
        raw = _round_nalla_range(start, end)
        return _translate_summary_range(raw)
    if style == "start_hour":
        window_start = _ceil_quarter_hour(start + timedelta(minutes=start_offset_minutes))
        window_end = window_start + timedelta(minutes=60)
        if window_end > end:
            window_end = _ceil_quarter_hour(end)
            window_start = window_end - timedelta(minutes=60)
        return f"{_fmt_summary_time(window_start)} - {_fmt_summary_time(window_end)}"
    if style == "end_hour":
        window_end = _floor_quarter_hour(end)
        window_start = window_end - timedelta(minutes=60)
        return f"{_fmt_summary_time(window_start)} - {_fmt_summary_time(window_end)}"
    raise ValueError(f"unknown summary style: {style}")


def _translate_summary_range(raw: str) -> str:
    start_s, end_s = raw.split(" - ", 1)
    sh, sm = start_s.split(".", 1)
    eh, em = end_s.split(".", 1)
    start = datetime(2000, 1, 1, int(sh), int(sm))
    end = datetime(2000, 1, 1, int(eh), int(em))
    return f"{_fmt_summary_time(start)} - {_fmt_summary_time(end)}"


def _first_auspicious(slots: list[dict], indices: Iterable[int]) -> int | None:
    return next((i for i in indices if slots[i]["auspicious"]), None)


def _last_auspicious(slots: list[dict], indices: Iterable[int]) -> int | None:
    ordered = list(indices)
    return next((i for i in reversed(ordered) if slots[i]["auspicious"]), None)


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
    நல்ல நேரம் — last auspicious காலை Gowri + predawn அதிகாலை Gowri before next sunrise.
    Times are derived from local sunrise/sunset (not fixed clock bands).
    """
    out: list[dict] = []
    morning_idx = _last_auspicious(day_slots, range(0, 4))
    if morning_idx is not None:
        out.append(
            {
                "period": "காலை",
                "time": _summary_slot_time(day_slots[morning_idx], style="centered_half"),
            }
        )

    evening_idx = _last_auspicious(night_slots, range(6, 8))
    evening_slot_list = night_slots
    if evening_idx is None:
        evening_idx = _last_auspicious(night_slots, range(4, 8))
    if evening_idx is None:
        evening_idx = _last_auspicious(day_slots, range(4, 8))
        evening_slot_list = day_slots
    if evening_idx is not None:
        out.append(
            {
                "period": "மாலை",
                "time": _summary_slot_time(
                    evening_slot_list[evening_idx],
                    style="end_hour" if evening_slot_list is night_slots and evening_idx >= 6 else "centered_half",
                ),
            }
        )

    return out


def gowri_nalla_neram_from_gowri(day_slots: list[dict], night_slots: list[dict]) -> list[dict]:
    """
    கௌரி நல்ல நேரம் — first auspicious பிற்பகல் Gowri + first auspicious காலை Gowri.
    """
    out: list[dict] = []
    morning_idx = _first_auspicious(day_slots, range(4, 6))
    if morning_idx is not None:
        out.append(
            {
                "period": "காலை",
                "time": _summary_slot_time(day_slots[morning_idx], style="start_hour"),
            }
        )

    evening_idx = _first_auspicious(day_slots, range(0, 4))
    if evening_idx is not None:
        out.append(
            {
                "period": "மாலை",
                "time": _summary_slot_time(
                    day_slots[evening_idx],
                    style="start_hour",
                    start_offset_minutes=30,
                ),
            }
        )

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
