"""Derive monthly calendar cell icons from kaalavidya panchangam data."""

from __future__ import annotations

import json
from datetime import date
from typing import TYPE_CHECKING

if TYPE_CHECKING:
    from kaalavidya.models import DailyPanchanga

from app.ingestion.other_days import _is_kari_naal
from app.models import City

# Nakshatras traditionally used for suba muhurtham (Tamil almanac convention).
_SUBA_MUHURTHAM_NAK = {
    "ரோகிணி",
    "மிருகசீரிடம்",
    "திருவாதிரை",
    "புனர்பூசம்",
    "உத்திரம்",
    "ஹஸ்தம்",
    "சுவாதி",
    "அனுஷம்",
    "மகம்",
    "மூலம்",
    "உத்திராடம்",
    "உத்திரட்டாதி",
    "ரேவதி",
    "சித்திரை",
    "அவிட்டம்",
    "பூசம்",
}

_BAD_SUNRISE_TITHI = ("அமாவாசை", "அஷ்டமி", "நவமி")


def _sunrise_tithi_name(panchanga: DailyPanchanga) -> str:
    for entry in panchanga.tithi:
        if entry.is_active_at_sunrise:
            return entry.name
    return panchanga.tithi[0].name if panchanga.tithi else ""


def _sunrise_nakshatra_name(panchanga: DailyPanchanga) -> str:
    for entry in panchanga.nakshatra:
        if entry.is_active_at_sunrise:
            return entry.name
    return panchanga.nakshatra[0].name if panchanga.nakshatra else ""


def _tithi_blob(panchanga: DailyPanchanga) -> str:
    return " ".join(t.name for t in panchanga.tithi)


def _is_bad_sunrise_tithi(name: str) -> bool:
    if any(token in name for token in _BAD_SUNRISE_TITHI):
        return True
    # Krishna paksha chaturdashi (Sivaratri eve) — not a wedding day.
    return "சதுர்த்தசி" in name and "தேய்பிறை" in name


def is_suba_muhurtham(panchanga: DailyPanchanga, city: City, on_date: date) -> bool:
    if _is_kari_naal(city, on_date):
        return False
    sunrise_tithi = _sunrise_tithi_name(panchanga)
    if _is_bad_sunrise_tithi(sunrise_tithi):
        return False
    return _sunrise_nakshatra_name(panchanga) in _SUBA_MUHURTHAM_NAK


def icons_from_panchanga(panchanga: DailyPanchanga, city: City, on_date: date) -> list[str]:
    """Return ordered icon ids for a calendar cell (thaali first when present)."""
    icons: list[str] = []
    tithi_text = _tithi_blob(panchanga)
    nak = _sunrise_nakshatra_name(panchanga)
    vara = panchanga.vara or ""

    if is_suba_muhurtham(panchanga, city, on_date):
        icons.append("thaali")

    if "அமாவாசை" in tithi_text:
        if vara == "திங்கள்":
            icons.append("sarva_amavasai")
        else:
            icons.append("amavasai")
    if "பௌர்ணமி" in tithi_text:
        icons.append("pournami")
    if "சஷ்டி" in tithi_text:
        icons.append("murugan")
    if "சதுர்த்தி" in tithi_text:
        icons.append("ganesha")
    if "ஏகாதசி" in tithi_text:
        icons.append("perumal")
    if "திரயோதசி" in tithi_text:
        icons.append("nandi")
    if "சதுர்த்தசி" in tithi_text and "தேய்பிறை" in tithi_text:
        icons.append("shiva")
    if nak == "கிருத்திகை":
        icons.append("star")
    if nak == "உத்திரம்":
        icons.append("thiruvonam")

    return _dedupe(icons)


def icons_from_daily_row(row: dict, city: City, on_date: date) -> list[str]:
    """Derive icons from a persisted daily_calendars row."""
    panchangam = json.loads(row.get("panchangam_json") or "[]")
    tithi_text = ""
    nak_text = ""
    for item in panchangam:
        label = item.get("label", "")
        value = item.get("value", "")
        if label == "திதி":
            tithi_text = value
        elif label == "நட்சத்திரம்":
            nak_text = value

    weekday = ""
    banner = row.get("banner_line_ta", "")
    if "," in banner:
        weekday = banner.split(",")[-1].strip()

    icons: list[str] = []

    if _is_suba_muhurtham_from_text(tithi_text, nak_text, city, on_date):
        icons.append("thaali")

    if "அமாவாசை" in tithi_text:
        icons.append("sarva_amavasai" if weekday == "திங்கள்" else "amavasai")
    if "பௌர்ணமி" in tithi_text:
        icons.append("pournami")
    if "சஷ்டி" in tithi_text:
        icons.append("murugan")
    if "சதுர்த்தி" in tithi_text:
        icons.append("ganesha")
    if "ஏகாதசி" in tithi_text:
        icons.append("perumal")
    if "திரயோதசி" in tithi_text:
        icons.append("nandi")
    if "சதுர்த்தசி" in tithi_text and "தேய்பிறை" in tithi_text:
        icons.append("shiva")
    if "கிருத்திகை" in nak_text:
        icons.append("star")
    if "உத்திரம்" in nak_text and "உத்திராட" not in nak_text:
        icons.append("thiruvonam")

    return _dedupe(icons)


def moon_phase_from_row(row: dict | None) -> str | None:
    if not row:
        return None
    panchangam = json.loads(row.get("panchangam_json") or "[]")
    for item in panchangam:
        if item.get("label") != "திதி":
            continue
        val = item.get("value", "")
        if "அமாவாசை" in val:
            return "amavasai"
        if "பௌர்ணமி" in val:
            return "pournami"
    sub = row.get("subtitle_line2_ta", "")
    if "அமாவாசை" in sub:
        return "amavasai"
    return None


def wedding_day_label(row: dict, on_date: date, city: City) -> str | None:
    """Human-readable wedding/suba muhurtham line for monthly list."""
    panchangam = json.loads(row.get("panchangam_json") or "[]")
    tithi_text = ""
    nak_text = ""
    for item in panchangam:
        if item.get("label") == "திதி":
            tithi_text = item.get("value", "")
        elif item.get("label") == "நட்சத்திரம்":
            nak_text = item.get("value", "")

    if not _is_suba_muhurtham_from_text(tithi_text, nak_text, city, on_date):
        return None

    weekday = ""
    banner = row.get("banner_line_ta", "")
    masa_day = ""
    if " - " in banner:
        left = banner.split(",")[0]
        if " - " in left:
            masa_day = left.strip()
        if "," in banner:
            weekday = banner.split(",")[-1].strip()

    month = row.get("month_label_ta", "").split(" - ")[0].strip()
    parts = [month, str(on_date.day)]
    if masa_day:
        parts.append(masa_day)
    if weekday:
        parts.append(weekday)
    return " - ".join(parts)


def _is_suba_muhurtham_from_text(tithi_text: str, nak_text: str, city: City, on_date: date) -> bool:
    if _is_kari_naal(city, on_date):
        return False
    if any(token in tithi_text for token in _BAD_SUNRISE_TITHI):
        return False
    if "சதுர்த்தசி" in tithi_text and "தேய்பிறை" in tithi_text:
        return False
    first_nak = nak_text.split(" பின்பு ")[0].split(" வரை ")[-1].strip()
    for token in first_nak.split():
        if token in _SUBA_MUHURTHAM_NAK:
            return True
    return any(nak in nak_text for nak in _SUBA_MUHURTHAM_NAK)


def _dedupe(items: list[str]) -> list[str]:
    seen: set[str] = set()
    out: list[str] = []
    for item in items:
        if item not in seen:
            seen.add(item)
            out.append(item)
    return out
