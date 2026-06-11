import json
from datetime import date

from app.models import DailyCalendar, MonthCalendar
from app.schemas import (
    DailyCalendarOut,
    HoroscopeItem,
    InauspiciousSlot,
    MonthCalendarOut,
    MonthDayCell,
    MonthListItem,
    PanchangamItem,
    TimeSlot,
)


def daily_to_schema(row: DailyCalendar) -> DailyCalendarOut:
    return DailyCalendarOut(
        city_id=row.city_id,
        gregorian_date=row.gregorian_date,
        month_label_ta=row.month_label_ta,
        gregorian_display=row.gregorian_display,
        subtitle_line1_ta=row.subtitle_line1_ta,
        subtitle_line2_ta=row.subtitle_line2_ta,
        banner_line_ta=row.banner_line_ta,
        events_ta=row.events_ta,
        nalla_neram=[TimeSlot(**x) for x in json.loads(row.nalla_neram_json or "[]")],
        gowri_nalla_neram=[TimeSlot(**x) for x in json.loads(row.gowri_nalla_neram_json or "[]")],
        panchangam=[PanchangamItem(**x) for x in json.loads(row.panchangam_json or "[]")],
        inauspicious=[InauspiciousSlot(**x) for x in json.loads(row.inauspicious_json or "[]")],
        shoolam_ta=row.shoolam_ta,
        pariharam_ta=row.pariharam_ta,
        lagnam_ta=row.lagnam_ta,
        rasi_chart=json.loads(row.rasi_chart_json or "[]"),
        rasi_center_ta=row.rasi_center_ta,
        horoscope=[HoroscopeItem(**x) for x in json.loads(row.horoscope_json or "[]")],
        quote_ta=row.quote_ta,
        birthdays_ta=row.birthdays_ta,
        note_ta=row.note_ta,
        data_version=row.data_version,
        updated_at=row.updated_at,
    )


def daily_from_schema(data) -> dict:
    payload = data.model_dump() if hasattr(data, "model_dump") else data
    gdate = payload["gregorian_date"]
    if isinstance(gdate, str):
        gdate = date.fromisoformat(gdate)
    return {
        "city_id": payload["city_id"],
        "gregorian_date": gdate,
        "month_label_ta": payload.get("month_label_ta", ""),
        "gregorian_display": payload.get("gregorian_display", gdate.strftime("%d-%m-%Y")),
        "subtitle_line1_ta": payload.get("subtitle_line1_ta", ""),
        "subtitle_line2_ta": payload.get("subtitle_line2_ta", ""),
        "banner_line_ta": payload.get("banner_line_ta", ""),
        "events_ta": payload.get("events_ta", ""),
        "nalla_neram_json": json.dumps(
            [x if isinstance(x, dict) else x.model_dump() for x in payload.get("nalla_neram", [])],
            ensure_ascii=False,
        ),
        "gowri_nalla_neram_json": json.dumps(
            [x if isinstance(x, dict) else x.model_dump() for x in payload.get("gowri_nalla_neram", [])],
            ensure_ascii=False,
        ),
        "panchangam_json": json.dumps(
            [x if isinstance(x, dict) else x.model_dump() for x in payload.get("panchangam", [])],
            ensure_ascii=False,
        ),
        "inauspicious_json": json.dumps(
            [x if isinstance(x, dict) else x.model_dump() for x in payload.get("inauspicious", [])],
            ensure_ascii=False,
        ),
        "shoolam_ta": payload.get("shoolam_ta", ""),
        "pariharam_ta": payload.get("pariharam_ta", ""),
        "lagnam_ta": payload.get("lagnam_ta", ""),
        "rasi_chart_json": json.dumps(payload.get("rasi_chart", []), ensure_ascii=False),
        "rasi_center_ta": payload.get("rasi_center_ta", ""),
        "horoscope_json": json.dumps(
            [x if isinstance(x, dict) else x.model_dump() for x in payload.get("horoscope", [])],
            ensure_ascii=False,
        ),
        "quote_ta": payload.get("quote_ta", ""),
        "birthdays_ta": payload.get("birthdays_ta", ""),
        "note_ta": payload.get("note_ta", ""),
    }


def month_to_schema(row: MonthCalendar) -> MonthCalendarOut:
    return MonthCalendarOut(
        city_id=row.city_id,
        year=row.year,
        month=row.month,
        month_label_ta=row.month_label_ta,
        tamil_months_ta=row.tamil_months_ta,
        days=[MonthDayCell(**x) for x in json.loads(row.days_json or "[]")],
        fasting_days=[MonthListItem(**x) for x in json.loads(row.fasting_days_json or "[]")],
        wedding_days=json.loads(row.wedding_days_json or "[]"),
        other_days=json.loads(row.other_days_json or "[]"),
        hindu_festivals=json.loads(row.hindu_festivals_json or "[]"),
        muslim_festivals=json.loads(row.muslim_festivals_json or "[]"),
        christian_festivals=json.loads(row.christian_festivals_json or "[]"),
        government_holidays=json.loads(row.government_holidays_json or "[]"),
    )


def month_from_schema(data) -> dict:
    payload = data.model_dump() if hasattr(data, "model_dump") else data
    return {
        "city_id": payload["city_id"],
        "year": payload["year"],
        "month": payload["month"],
        "month_label_ta": payload.get("month_label_ta", ""),
        "tamil_months_ta": payload.get("tamil_months_ta", ""),
        "days_json": json.dumps(
            [x if isinstance(x, dict) else x.model_dump() for x in payload.get("days", [])],
            ensure_ascii=False,
        ),
        "fasting_days_json": json.dumps(
            [x if isinstance(x, dict) else x.model_dump() for x in payload.get("fasting_days", [])],
            ensure_ascii=False,
        ),
        "wedding_days_json": json.dumps(payload.get("wedding_days", []), ensure_ascii=False),
        "other_days_json": json.dumps(payload.get("other_days", []), ensure_ascii=False),
        "hindu_festivals_json": json.dumps(payload.get("hindu_festivals", []), ensure_ascii=False),
        "muslim_festivals_json": json.dumps(payload.get("muslim_festivals", []), ensure_ascii=False),
        "christian_festivals_json": json.dumps(payload.get("christian_festivals", []), ensure_ascii=False),
        "government_holidays_json": json.dumps(payload.get("government_holidays", []), ensure_ascii=False),
    }
