"""Build monthly calendar grid + derived lists from daily rows."""

from __future__ import annotations

import calendar
import json
from datetime import date

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
from app.ingestion.calendar_icons import (
    icons_from_daily_row,
    moon_phase_from_row,
    wedding_day_label,
)
from app.ingestion.government_holidays import holidays_for_month
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
    gov_holidays = holidays_for_month(year, month)
    gov_days = {int(h["day"]) for h in gov_holidays}

    cal = calendar.Calendar(firstweekday=6)  # Sunday first (matches reference UI)
    weeks = cal.monthdatescalendar(year, month)

    days: list[dict] = []
    for week in weeks:
        for cell_date in week:
            in_month = cell_date.month == month
            row = by_date.get(cell_date) if in_month else None
            tithi_day = _tamil_corner_day(row) if in_month else None
            is_sunday = cell_date.weekday() == 6
            moon = moon_phase_from_row(row) if in_month else None
            icons = icons_from_daily_row(row, city, cell_date) if in_month and row else []
            is_holiday = in_month and cell_date.day in gov_days
            is_today = in_month and cell_date == today

            highlight = None
            if is_today:
                highlight = "green"
            elif is_holiday:
                highlight = "red"

            days.append(
                {
                    "gregorian_day": cell_date.day,
                    "tamil_day": tithi_day,
                    "is_sunday": is_sunday and in_month,
                    "is_today": is_today,
                    "is_highlight": is_today or is_holiday,
                    "highlight_color": highlight,
                    "icons": icons,
                    "moon_phase": moon,
                    "is_other_month": not in_month,
                }
            )

    fasting = _collect_fasting_days(year, month, by_date)
    wedding = _collect_wedding_days(city, year, month, by_date)
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
        "wedding_days_json": json.dumps(wedding, ensure_ascii=False),
        "other_days_json": json.dumps(other, ensure_ascii=False),
        "hindu_festivals_json": json.dumps([], ensure_ascii=False),
        "muslim_festivals_json": json.dumps([], ensure_ascii=False),
        "christian_festivals_json": json.dumps([], ensure_ascii=False),
        "government_holidays_json": json.dumps(gov_holidays, ensure_ascii=False),
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


def _weekday_ta(d: date) -> str:
    names = ["திங்கள்", "செவ்வாய்", "புதன்", "வியாழன்", "வெள்ளி", "சனி", "ஞாயிறு"]
    return names[d.weekday()]


def _collect_wedding_days(city: City, year: int, month: int, by_date: dict) -> list[str]:
    labels: list[str] = []
    for d in sorted(by_date.keys()):
        if d.month != month:
            continue
        row = by_date[d]
        label = wedding_day_label(row, d, city)
        if label:
            labels.append(label)
    return labels


def _collect_fasting_days(year: int, month: int, by_date: dict) -> list[dict]:
    items: list[dict] = []
    amavasai: list[str] = []
    pournami: list[str] = []
    kiruthigai: list[str] = []
    ekadasi: list[str] = []
    sashti: list[str] = []
    pradosham: list[str] = []
    sivaratri: list[str] = []
    chaturthi: list[str] = []
    sankatahara: list[str] = []
    thiruvonam: list[str] = []

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

        if day_has_amavasai(tithi_text):
            amavasai.append(label)
        if day_has_pournami(tithi_text):
            pournami.append(label)
        if day_has_kiruthigai(nak_text):
            kiruthigai.append(label)
        if day_has_ekadasi(tithi_text):
            ekadasi.append(label)
        if day_has_sashti(tithi_text):
            sashti.append(label)
        if day_has_pradosham(tithi_text):
            pradosham.append(label)
        if day_has_sivaratri(tithi_text):
            sivaratri.append(label)
        if day_has_sankatahara(tithi_text):
            sankatahara.append(label)
        elif day_has_chaturthi(tithi_text):
            chaturthi.append(label)
        if day_has_thiruvonam(nak_text):
            thiruvonam.append(label)

    if amavasai:
        items.append({"icon": "amavasai", "title_ta": "அமாவாசை", "dates_ta": ", ".join(amavasai)})
    if pournami:
        items.append({"icon": "pournami", "title_ta": "பௌர்ணமி", "dates_ta": ", ".join(pournami)})
    if kiruthigai:
        items.append({"icon": "star", "title_ta": "கிருத்திகை", "dates_ta": ", ".join(kiruthigai)})
    if thiruvonam:
        items.append({"icon": "thiruvonam", "title_ta": "திருவோணம்", "dates_ta": ", ".join(thiruvonam)})
    if ekadasi:
        items.append({"icon": "perumal", "title_ta": "ஏகாதசி", "dates_ta": ", ".join(ekadasi)})
    if sashti:
        items.append({"icon": "murugan", "title_ta": "சஷ்டி", "dates_ta": ", ".join(sashti)})
    if sankatahara:
        items.append({"icon": "sankatahara", "title_ta": "சங்கடஹர சதுர்த்தி", "dates_ta": ", ".join(sankatahara)})
    if sivaratri:
        items.append({"icon": "shiva", "title_ta": "சிவராத்திரி", "dates_ta": ", ".join(sivaratri)})
    if pradosham:
        items.append({"icon": "nandi", "title_ta": "பிரதோஷம்", "dates_ta": ", ".join(pradosham)})
    if chaturthi:
        items.append({"icon": "ganesha", "title_ta": "சதுர்த்தி", "dates_ta": ", ".join(chaturthi)})
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
