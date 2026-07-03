"""Government holiday lists for monthly calendar highlighting."""

from __future__ import annotations

from datetime import date

# Tamil Nadu + national holidays for 2026 (G.O. / RBI convention).
_TN_2026: dict[tuple[int, int], str] = {
    (1, 1): "புத்தாண்டு",
    (1, 15): "தைப்பொங்கல்",
    (1, 16): "திருவள்ளுவர் நாள்",
    (1, 26): "குடியரசு தினம்",
    (2, 1): "ஆண்டு கணக்கு முடிவு (வங்கி)",
    (3, 19): "தெலுங்கு புத்தாண்டு",
    (4, 1): "ஆண்டு கணக்கு முடிவு",
    (4, 3): "புனித வெள்ளி",
    (4, 14): "தமிழ் புத்தாண்டு",
    (5, 1): "May Day",
    (5, 28): "பக்ரீத்",
    (6, 26): "முஹர்ரம்",
    (8, 15): "சுதந்திர தினம்",
    (8, 26): "கிருஷ்ண ஜயந்தி",
    (9, 14): "விநாயகர் சதுர்த்தி",
    (10, 2): "காந்தி ஜெயந்தி",
    (10, 20): "தீபாவளி",
    (11, 8): "தீபாவளி",
    (12, 25): "கிறிஸ்தumas நாள்",
}


def holidays_for_month(year: int, month: int) -> list[dict[str, str]]:
    """Return [{day, title}, ...] for a Gregorian month."""
    if year != 2026:
        return []
    out: list[dict[str, str]] = []
    for (m, d), title in sorted(_TN_2026.items()):
        if m == month:
            out.append({"day": str(d), "title": title})
    return out


def is_government_holiday(year: int, month: int, day: int) -> bool:
    return year == 2026 and (month, day) in _TN_2026


def holiday_title(year: int, on_date: date) -> str | None:
    if year != 2026:
        return None
    return _TN_2026.get((on_date.month, on_date.day))
