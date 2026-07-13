"""Derive monthly calendar cell icons from kaalavidya panchangam data."""

from __future__ import annotations

import json
from datetime import date
from typing import TYPE_CHECKING

if TYPE_CHECKING:
    from kaalavidya.models import DailyPanchanga

from app.data.fasting_observance_dates import (
    day_has_amavasai,
    day_has_chaturthi,
    day_has_ekadasi,
    day_has_kiruthigai,
    day_has_pournami,
    day_has_pradosham,
    day_has_sankatahara,
    day_has_sashti,
    day_has_sivaratri,
    day_has_thiruvonam,
)
from app.data.suba_muhurtham_dates import is_suba_muhurtham_date
from app.ingestion.other_days import _is_kari_naal
from app.models import City

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
    return "சதுர்த்தசி" in name and "தேய்பிறை" in name


def is_suba_muhurtham(panchanga: DailyPanchanga, city: City, on_date: date) -> bool:
    """True only for curated publisher muhurtham dates (Nithra-style)."""
    if _is_kari_naal(city, on_date):
        return False
    return is_suba_muhurtham_date(on_date)


def icons_from_panchanga(panchanga: DailyPanchanga, city: City, on_date: date) -> list[str]:
    """Return ordered icon ids for a calendar cell (thaali first when present)."""
    icons: list[str] = []
    tithi_text = _tithi_blob(panchanga)
    nak = _sunrise_nakshatra_name(panchanga)
    vara = panchanga.vara or ""

    if is_suba_muhurtham(panchanga, city, on_date):
        icons.append("thaali")

    if day_has_amavasai(tithi_text):
        icons.append("sarva_amavasai" if vara == "திங்கள்" else "amavasai")
    if day_has_pournami(tithi_text):
        icons.append("pournami")
    if day_has_sashti(tithi_text):
        icons.append("murugan")
    if day_has_chaturthi(tithi_text) or day_has_sankatahara(tithi_text):
        icons.append("ganesha")
    if day_has_ekadasi(tithi_text):
        icons.append("perumal")
    if day_has_pradosham(tithi_text):
        icons.append("nandi")
    if day_has_sivaratri(tithi_text):
        icons.append("shiva")
    if day_has_kiruthigai(nak):
        icons.append("star")
    if day_has_thiruvonam(nak):
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

    if day_has_amavasai(tithi_text):
        icons.append("sarva_amavasai" if weekday == "திங்கள்" else "amavasai")
    if day_has_pournami(tithi_text):
        icons.append("pournami")
    if day_has_sashti(tithi_text):
        icons.append("murugan")
    if day_has_chaturthi(tithi_text) or day_has_sankatahara(tithi_text):
        icons.append("ganesha")
    if day_has_ekadasi(tithi_text):
        icons.append("perumal")
    if day_has_pradosham(tithi_text):
        icons.append("nandi")
    if day_has_sivaratri(tithi_text):
        icons.append("shiva")
    if day_has_kiruthigai(nak_text):
        icons.append("star")
    if day_has_thiruvonam(nak_text):
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
        if day_has_amavasai(val):
            return "amavasai"
        if day_has_pournami(val):
            return "pournami"
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


def _is_suba_muhurtham_from_text(
    tithi_text: str, nak_text: str, city: City, on_date: date
) -> bool:
    if _is_kari_naal(city, on_date):
        return False
    return is_suba_muhurtham_date(on_date)


def _dedupe(items: list[str]) -> list[str]:
    seen: set[str] = set()
    out: list[str] = []
    for item in items:
        if item not in seen:
            seen.add(item)
            out.append(item)
    return out
