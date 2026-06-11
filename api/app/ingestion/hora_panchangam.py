"""Planetary Hora (கிரக ஓரை) — 12 day + 12 night slots from kaalavidya hora_table."""

from __future__ import annotations

from datetime import datetime
from typing import TYPE_CHECKING

if TYPE_CHECKING:
    from kaalavidya.models import DailyPanchanga

INAUSPICIOUS_PLANETS = {"சூரியன்", "செவ்வாய்", "சனி"}

DAY_SECTIONS = [
    ("காலை", slice(0, 6)),
    ("பிற்பகல்", slice(6, 9)),
    ("மாலை", slice(9, 12)),
]
NIGHT_SECTIONS = [
    ("இரவு", slice(0, 6)),
    ("நள்ளிரவு", slice(6, 9)),
    ("அதிகாலை", slice(9, 12)),
]


def _fmt_slot_time(dt: datetime) -> str:
    return f"{dt.hour}.{dt.minute:02d}"


def _fmt_slot_range(start: datetime, end: datetime) -> str:
    return f"{_fmt_slot_time(start)} - {_fmt_slot_time(end)}"


def _is_auspicious(planet: str, paksha: str) -> bool:
    if planet in INAUSPICIOUS_PLANETS:
        return False
    if planet == "சந்திரன்":
        return "வளர்பிறை" in paksha
    return True


def _slots_from_horas(horas: list, paksha: str) -> list[dict]:
    return [
        {
            "time": _fmt_slot_range(h.starts_at, h.ends_at),
            "planet": h.planet,
            "auspicious": _is_auspicious(h.planet, paksha),
        }
        for h in horas
    ]


def _build_sections(slots: list[dict], section_defs: list[tuple[str, slice]]) -> list[dict]:
    sections = []
    for period, sl in section_defs:
        part = slots[sl]
        if part:
            sections.append({"period": period, "slots": part})
    return sections


def hora_from_panchanga(panchanga: DailyPanchanga) -> dict:
    horas = panchanga.hora_table or []
    if not horas:
        return {"sections": []}

    paksha = panchanga.paksha or ""
    day_horas = [h for h in horas if h.is_day_hora]
    night_horas = [h for h in horas if not h.is_day_hora]

    day_slots = _slots_from_horas(day_horas, paksha)
    night_slots = _slots_from_horas(night_horas, paksha)

    sections = _build_sections(day_slots, DAY_SECTIONS) + _build_sections(night_slots, NIGHT_SECTIONS)
    return {"sections": sections}
