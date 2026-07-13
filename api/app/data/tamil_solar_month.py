"""Tamil solar month (சௌர மாதம்) starts for 2026 — Nithra / Prokerala aligned."""

from __future__ import annotations

from datetime import date

# Inclusive start dates; next row = end of previous month.
_STARTS_2026: list[tuple[date, str]] = [
    (date(2025, 12, 16), "மார்கழி"),
    (date(2026, 1, 15), "தை"),
    (date(2026, 2, 13), "மாசி"),
    (date(2026, 3, 15), "பங்குனி"),
    (date(2026, 4, 14), "சித்திரை"),
    (date(2026, 5, 15), "வைகாசி"),
    (date(2026, 6, 15), "ஆனி"),  # → Jul 16; July 13 = ஆனி 29
    (date(2026, 7, 17), "ஆடி"),
    (date(2026, 8, 17), "ஆவணி"),
    (date(2026, 9, 17), "புரட்டாசி"),
    (date(2026, 10, 18), "ஐப்பசி"),
    (date(2026, 11, 17), "கார்த்திகை"),
    (date(2026, 12, 16), "மார்கழி"),
    (date(2027, 1, 14), "தை"),
]


def tamil_solar_day_for(d: date) -> tuple[str, int] | None:
    current: tuple[date, str] | None = None
    for start, name in _STARTS_2026:
        if start > d:
            break
        current = (start, name)
    if current is None:
        return None
    start, name = current
    return name, (d - start).days + 1
