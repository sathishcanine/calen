"""Map kaalavidya / API payloads → DB field dicts."""

from __future__ import annotations

import json
from datetime import date, datetime
from typing import TYPE_CHECKING

if TYPE_CHECKING:
    from kaalavidya.models import DailyPanchanga

from app.ingestion.gowri_panchangam import (
    gowri_from_panchanga,
    gowri_nalla_neram_from_gowri,
    nalla_neram_from_gowri,
)
from app.ingestion.hora_panchangam import hora_from_panchanga

TAMIL_MONTHS = [
    "ஜனவரி",
    "பிப்ரவரி",
    "மார்ச்",
    "ஏப்ரல்",
    "மே",
    "ஜூன்",
    "ஜூலை",
    "ஆகஸ்ட்",
    "செப்டம்பர்",
    "அக்டோபர்",
    "நவம்பர்",
    "டிசம்பர்",
]

# South Indian chart: rashi index per 4×4 cell (None = center block)
_SI_GRID_RASHI = [11, 0, 1, 2, 10, None, None, 3, 9, None, None, 4, 8, 7, 6, 5]

# Traditional remedy by Disha Shoola direction (Tamil almanac convention)
_PARIHARAM_BY_DIRECTION_TA = {
    "கிழக்கு": "தயிர்",
    "மேற்கு": "வெல்லம்",
    "வடக்கு": "பால்",
    "தெற்கு": "நெய்",
}


def _fmt_time(dt: datetime | None) -> str:
    if dt is None:
        return ""
    return dt.strftime("%I.%M %p").lstrip("0").replace(" 0", " ")


def _fmt_time_range(start: datetime | None, end: datetime | None) -> str:
    if not start or not end:
        return ""
    return f"{_fmt_time(start)} - {_fmt_time(end)}"


def _fmt_time_ta(dt: datetime | None) -> str:
    """Short format like 5.52 for sunrise."""
    if dt is None:
        return ""
    h = dt.hour
    m = dt.minute
    return f"{h}.{m:02d}"


def _tithi_description(entries) -> str:
    parts = []
    for t in entries:
        end = _fmt_time_ta(t.ends_at) if t.ends_at else ""
        if end:
            parts.append(f"{t.ends_at.strftime('%H.%M') if t.ends_at else ''} வரை {t.name}")
        else:
            parts.append(t.name)
    if len(entries) == 1:
        return f"இன்று முழுவதும் {entries[0].name}" if not entries[0].ends_at else parts[0]
    return " பின்பு ".join(parts)


def _nakshatra_description(entries) -> str:
    if not entries:
        return ""
    active = [n for n in entries if n.is_active_at_sunrise] or entries[:1]
    if len(entries) == 1 and (not entries[0].ends_at or entries[0].ends_at.date() > entries[0].starts_at.date()):
        return f"இன்று முழுவதும் {entries[0].name}"
    parts = []
    for n in entries:
        if n.ends_at:
            parts.append(f"{n.ends_at.strftime('%H.%M')} வரை {n.name}")
        else:
            parts.append(n.name)
    return " பின்பு ".join(parts)


def _yoga_description(entries) -> str:
    if not entries:
        return ""
    parts = []
    for y in entries:
        if y.ends_at:
            parts.append(f"{y.ends_at.strftime('%H.%M')} வரை {y.name}")
        else:
            parts.append(y.name)
    return " பின்பு ".join(parts)


def _karana_description(entries) -> str:
    if not entries:
        return ""
    parts = []
    for k in entries:
        if k.ends_at:
            parts.append(f"{k.ends_at.strftime('%H.%M')} வரை {k.name}")
        else:
            parts.append(k.name)
    return " பின்பு ".join(parts)


def _rasi_chart_16(panchanga: DailyPanchanga) -> list[str | None]:
    chart = panchanga.sunrise_chart
    if not chart:
        return [None] * 16
    cells: list[str | None] = []
    for rashi_idx in _SI_GRID_RASHI:
        if rashi_idx is None:
            cells.append(None)
            continue
        grahas = chart.rashi_grahas.get(rashi_idx, [])
        cells.append(" ".join(grahas) if grahas else None)
    return cells


def daily_from_panchanga(
    city_id: str,
    panchanga: DailyPanchanga,
    *,
    lat: float,
    lon: float,
    timezone: str,
) -> dict:
    d = panchanga.date
    weekday = panchanga.vara
    gregorian_display = d.strftime("%d-%m-%Y")
    tamil_month = TAMIL_MONTHS[d.month - 1]
    masa = panchanga.masa.name if panchanga.masa else ""
    tithi_main = panchanga.tithi[0] if panchanga.tithi else None
    tithi_day = (tithi_main.index % 15) + 1 if tithi_main else 0

    samvatsara = panchanga.samvatsara
    subtitle1 = ""
    if panchanga.sun_rashi and panchanga.moon_rashi:
        subtitle1 = f"{panchanga.sun_rashi.name} மாதம் - {panchanga.ritu_solar} - {panchanga.ayana}"
    subtitle2 = f"{samvatsara} - {masa} - {tithi_day}" if masa else samvatsara

    panchangam = []
    if panchanga.sun and panchanga.sun.sunrise:
        panchangam.append({"label": "சூரிய உதயம்", "value": _fmt_time_ta(panchanga.sun.sunrise)})
    if panchanga.karana:
        k0 = panchanga.karana[0]
        panchangam.append(
            {
                "label": "கரணன்",
                "value": _fmt_time_range(k0.starts_at, k0.ends_at) if k0.starts_at else k0.name,
            }
        )
    if panchanga.tithi:
        panchangam.append({"label": "திதி", "value": _tithi_description(panchanga.tithi)})
    if panchanga.nakshatra:
        panchangam.append({"label": "நட்சத்திரம்", "value": _nakshatra_description(panchanga.nakshatra)})
    if panchanga.yoga:
        panchangam.append({"label": "நாமயோகம்", "value": _yoga_description(panchanga.yoga)})
    if len(panchanga.karana) > 1:
        panchangam.append({"label": "கரணம்", "value": _karana_description(panchanga.karana)})
    for y in panchanga.yoga[:1]:
        panchangam.append({"label": "அமிர்தாதி யோகம்", "value": y.name})
    if panchanga.moon_rashi:
        panchangam.append(
            {
                "label": "சந்திராஷ்டமம்",
                "value": f"இன்று முழுவதும் {panchanga.moon_rashi.name}",
            }
        )

    inauspicious = []
    if panchanga.rahu_kala:
        inauspicious.append(
            {"name": "இராகு", "time": _fmt_time_range(panchanga.rahu_kala.starts_at, panchanga.rahu_kala.ends_at)}
        )
    if panchanga.gulika_kala:
        inauspicious.append(
            {
                "name": "குளிகை",
                "time": _fmt_time_range(panchanga.gulika_kala.starts_at, panchanga.gulika_kala.ends_at),
            }
        )
    if panchanga.yamagandam:
        inauspicious.append(
            {
                "name": "எமகண்டம்",
                "time": _fmt_time_range(panchanga.yamagandam.starts_at, panchanga.yamagandam.ends_at),
            }
        )

    shoolam = ""
    pariharam = ""
    if panchanga.disha_shoola:
        direction = panchanga.disha_shoola.get("direction", "")
        shoolam = f"சூலம் - {direction}"
        remedy = _PARIHARAM_BY_DIRECTION_TA.get(direction, "")
        if remedy:
            pariharam = f"பரிகாரம் - {remedy}"

    lagnam = ""
    if panchanga.lagna_table:
        lg = panchanga.lagna_table[0]
        lagnam = f"{lg.name} லக்னம்"

    chart = panchanga.sunrise_chart
    center = ""
    if chart:
        center = f"{d.day} - {chart.lagna_name}"

    horoscope = _generic_horoscope(d)
    gowri_panchangam = gowri_from_panchanga(panchanga, lat=lat, lon=lon, timezone=timezone)
    hora_panchangam = hora_from_panchanga(panchanga)

    return {
        "city_id": city_id,
        "gregorian_date": d,
        "month_label_ta": f"{tamil_month} - {weekday}",
        "gregorian_display": gregorian_display,
        "subtitle_line1_ta": subtitle1,
        "subtitle_line2_ta": subtitle2,
        "banner_line_ta": f"{masa} - {tithi_day}, {weekday}" if masa else f"{tamil_month} - {weekday}",
        "events_ta": "",
        "nalla_neram_json": json.dumps(
            nalla_neram_from_gowri(gowri_panchangam["day_slots"], gowri_panchangam["night_slots"]),
            ensure_ascii=False,
        ),
        "gowri_nalla_neram_json": json.dumps(
            gowri_nalla_neram_from_gowri(gowri_panchangam["day_slots"], gowri_panchangam["night_slots"]),
            ensure_ascii=False,
        ),
        "gowri_panchangam_json": json.dumps(
            {"sections": gowri_panchangam["sections"]},
            ensure_ascii=False,
        ),
        "hora_json": json.dumps(hora_panchangam, ensure_ascii=False),
        "panchangam_json": json.dumps(panchangam, ensure_ascii=False),
        "inauspicious_json": json.dumps(inauspicious, ensure_ascii=False),
        "shoolam_ta": shoolam,
        "pariharam_ta": pariharam,
        "lagnam_ta": lagnam,
        "rasi_chart_json": json.dumps(_rasi_chart_16(panchanga), ensure_ascii=False),
        "rasi_center_ta": center,
        "horoscope_json": json.dumps(horoscope, ensure_ascii=False),
        "quote_ta": "",
        "birthdays_ta": "",
        "note_ta": "குறிப்பு : நாட்காட்டி பகுதியில் உள்ள அனைத்து தகவல்களும் தினசரி காலண்டர் அடிப்படையில் கொடுக்கப்பட்டுள்ளது.",
    }


def _generic_horoscope(d: date) -> list[dict]:
    signs = [
        "மேஷம்",
        "ரிஷபம்",
        "மிதுனம்",
        "கடகம்",
        "சிம்மம்",
        "கன்னி",
        "துலாம்",
        "விருச்சிகம்",
        "தனுசு",
        "மகரம்",
        "கும்பம்",
        "மீனம்",
    ]
    words = ["நன்மை", "பாராட்டு", "பயணம்", "செலவு", "இன்பம்", "லாபம்", "அமைதி", "வெற்றி"]
    offset = d.toordinal() % len(words)
    return [{"sign": s, "prediction": words[(offset + i) % len(words)]} for i, s in enumerate(signs)]
