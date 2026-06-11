"""Build monthly calendar grid + derived lists from daily rows."""

from __future__ import annotations

import calendar
import json
from datetime import date

from app.ingestion.mappers import TAMIL_MONTHS
from app.ingestion.kaalavidya_provider import month_label
from app.ingestion.other_days import collect_other_days
from app.models import City


def build_month_record(
    city: City,
    year: int,
    month: int,
    daily_rows: list[dict],
    *,
    tamil_months_ta: str = "",
) -> dict:
    """Assemble MonthCalendar fields from daily dicts (DB-ready)."""
    by_date = {r["gregorian_date"]: r for r in daily_rows}
    today = date.today()

    cal = calendar.Calendar(firstweekday=6)  # Sunday first (matches reference UI)
    weeks = cal.monthdatescalendar(year, month)

    days: list[dict] = []
    for week in weeks:
        for cell_date in week:
            in_month = cell_date.month == month
            row = by_date.get(cell_date) if in_month else None
            tithi_day = _tamil_corner_day(row) if in_month else None
            is_sunday = cell_date.weekday() == 6
            moon = _moon_phase(row) if in_month else None
            days.append(
                {
                    "gregorian_day": cell_date.day,
                    "tamil_day": tithi_day,
                    "is_sunday": is_sunday and in_month,
                    "is_today": in_month and cell_date == today,
                    "is_highlight": in_month and cell_date == today,
                    "highlight_color": "green" if in_month and cell_date == today else None,
                    "icons": [],
                    "moon_phase": moon,
                    "is_other_month": not in_month,
                }
            )

    fasting = _collect_fasting_days(year, month, by_date)
    other = collect_other_days(city, year, month)
    tamil_range = _tamil_month_range(daily_rows)

    return {
        "city_id": city.id,
        "year": year,
        "month": month,
        "month_label_ta": month_label(year, month),
        "tamil_months_ta": tamil_months_ta or tamil_range,
        "days_json": json.dumps(days, ensure_ascii=False),
        "fasting_days_json": json.dumps(fasting, ensure_ascii=False),
        "wedding_days_json": json.dumps([], ensure_ascii=False),
        "other_days_json": json.dumps(other, ensure_ascii=False),
        "hindu_festivals_json": json.dumps([], ensure_ascii=False),
        "muslim_festivals_json": json.dumps([], ensure_ascii=False),
        "christian_festivals_json": json.dumps([], ensure_ascii=False),
        "government_holidays_json": json.dumps([], ensure_ascii=False),
    }


def _tamil_corner_day(row: dict | None) -> int | None:
    if not row:
        return None
    banner = row.get("banner_line_ta", "")
    # e.g. "ஆனி - 3, புதன்"
    left = banner.split(",")[0] if "," in banner else banner
    if " - " in left:
        try:
            return int(left.split(" - ")[-1].strip())
        except ValueError:
            pass
    return None


def _moon_phase(row: dict | None) -> str | None:
    if not row:
        return None
    panchangam = json.loads(row.get("panchangam_json") or "[]")
    for item in panchangam:
        if item.get("label") != "திதி":
            continue
        val = item.get("value", "")
        if "அமாவாசை" in val:
            return "amavasai"
        if "பௌர்ணமி" in val or "சதுர்த்தி" in val and "வளர்பிறை" in val:
            # full moon tithi names in Tamil almanacs
            if "பௌர்ணமி" in val or "15" in val:
                return "pournami"
        if "பிரதமை" in val and "வளர்பிறை" in val:
            pass
        # Krishna prathama after amavasai — detect new moon day via தேய்பிறை last tithi
        if "திருதியை" in val and "தேய்பிறை" in val:
            return None
    # Check banner/subtitle for krishna/shukla end
    sub = row.get("subtitle_line2_ta", "")
    if "அமாவாசை" in sub:
        return "amavasai"
    return None


def _weekday_ta(d: date) -> str:
    names = ["திங்கள்", "செவ்வாய்", "புதன்", "வியாழன்", "வெள்ளி", "சனி", "ஞாயிறு"]
    return names[d.weekday()]


def _collect_fasting_days(year: int, month: int, by_date: dict) -> list[dict]:
    items: list[dict] = []
    amavasai: list[str] = []
    pournami: list[str] = []
    kiruthigai: list[str] = []
    ekadasi: list[str] = []
    sashti: list[str] = []

    for d, row in sorted(by_date.items()):
        if d.month != month:
            continue
        wd = _weekday_ta(d)
        label = f"{d.day} {wd}"
        panchangam = json.loads(row.get("panchangam_json") or "[]")
        tithi_text = ""
        nak_text = ""
        for p in panchangam:
            if p.get("label") == "திதி":
                tithi_text = p.get("value", "")
            if p.get("label") == "நட்சத்திரம்":
                nak_text = p.get("value", "")

        if "அமாவாசை" in tithi_text or "தேய்பிறை" in tithi_text and "30" in tithi_text:
            amavasai.append(label)
        if "பௌர்ணமி" in tithi_text or ("வளர்பிறை" in tithi_text and "15" in tithi_text):
            pournami.append(label)
        if "கிருத்திகை" in nak_text or "கிருத்திகை" in tithi_text:
            kiruthigai.append(label)
        if "ஏகாதசி" in tithi_text or "பதினொன்று" in tithi_text:
            ekadasi.append(label)
        if "சஷ்டி" in tithi_text:
            sashti.append(label)

    if amavasai:
        items.append({"icon": "amavasai", "title_ta": "அமாவாசை", "dates_ta": ", ".join(amavasai)})
    if pournami:
        items.append({"icon": "pournami", "title_ta": "பௌர்ணமி", "dates_ta": ", ".join(pournami)})
    if kiruthigai:
        items.append({"icon": "star", "title_ta": "கிருத்திகை", "dates_ta": ", ".join(kiruthigai)})
    if ekadasi:
        items.append({"icon": "ekadasi", "title_ta": "ஏகாதசி", "dates_ta": ", ".join(ekadasi)})
    if sashti:
        items.append({"icon": "sashti", "title_ta": "சஷ்டி", "dates_ta": ", ".join(sashti)})
    return items


def _tamil_month_range(daily_rows: list[dict]) -> str:
    names = []
    for row in daily_rows:
        banner = row.get("banner_line_ta", "")
        masa = banner.split(" - ")[0].split(",")[0].strip()
        if masa and masa not in names:
            names.append(masa)
    if not names:
        return ""
    if len(names) == 1:
        return names[0]
    return f"{names[0]} - {names[-1]}"
