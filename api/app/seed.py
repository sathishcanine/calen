"""Seed sample data matching reference screenshots (June 2026, Chennai)."""

import json
from datetime import date, timedelta

from app.database import Base, SessionLocal, engine
from app.models import City, DailyCalendar, MonthCalendar


def _june_month_days() -> list:
    """Build June 2026 grid cells (starts Sunday June 1 in 2026 — check: June 1 2026 is Monday)."""
    # June 1, 2026 is Monday
    cells = []
    # Pad May 31
    cells.append(
        {
            "gregorian_day": 31,
            "tamil_day": 17,
            "is_sunday": False,
            "is_today": False,
            "is_other_month": True,
            "icons": [],
        }
    )
    for d in range(1, 31):
        dow = (d + 0) % 7  # June 1 = Monday -> dow 1
        weekday = (d) % 7  # simplified
        is_sun = ((d + 0) % 7) == 6  # Sundays: 7,14,21,28
        if d in (7, 14, 21, 28):
            is_sun = True
        cell = {
            "gregorian_day": d,
            "tamil_day": d + 17 if d < 15 else d - 14,
            "is_sunday": d in (7, 14, 21, 28),
            "is_today": d == 3,
            "is_highlight": d in (3, 26),
            "highlight_color": "green" if d == 3 else ("red" if d == 26 else None),
            "icons": ["ganesha"] if d in (4, 18) else [],
            "moon_phase": "amavasai" if d == 14 else ("pournami" if d == 29 else None),
            "is_other_month": False,
        }
        if d == 13:
            cell["icons"] = ["murugan"]
        cells.append(cell)
    for d in (1, 2, 3, 4):
        cells.append(
            {
                "gregorian_day": d,
                "tamil_day": d + 10,
                "is_other_month": True,
                "icons": [],
            }
        )
    return cells


def seed_daily_june_3(db) -> None:
    horoscope = [
        {"sign": "மேஷம்", "prediction": "பாராட்டு"},
        {"sign": "ரிஷபம்", "prediction": "பரிவு"},
        {"sign": "மிதுனம்", "prediction": "நன்மை"},
        {"sign": "கடகம்", "prediction": "செலவு"},
        {"sign": "சிம்மம்", "prediction": "இன்பம்"},
        {"sign": "கன்னி", "prediction": "பயணம்"},
        {"sign": "துலாம்", "prediction": "லாபம்"},
        {"sign": "விருச்சிகம்", "prediction": "உறவு"},
        {"sign": "தனுசு", "prediction": "ஆரோக்கியம்"},
        {"sign": "மகரம்", "prediction": "வெற்றி"},
        {"sign": "கும்பம்", "prediction": "அமைதி"},
        {"sign": "மீனம்", "prediction": "புதுமை"},
    ]
    panchangam = [
        {"label": "சூரிய உதயம்", "value": "5.52"},
        {"label": "கரணன்", "value": "06.00 - 07.30"},
        {
            "label": "திதி",
            "value": "இன்று இரவு 08.23 வரை திரிதியை பின்பு சதுர்த்தி",
        },
        {"label": "நட்சத்திரம்", "value": "இன்று முழுவதும் பூராடம்"},
        {
            "label": "நாமயோகம்",
            "value": "இன்று காலை 07.58 வரை சுபம் பின்பு சுப்பிரம",
        },
        {
            "label": "கரணம்",
            "value": "இன்று காலை 07.31 வரை வணிசை பின்பு இரவு 08.23 வரை பத்திரை பின்பு பவம்",
        },
        {
            "label": "அமிர்தாதி யோகம்",
            "value": "இன்று அதிகாலை 05.51 வரை சித்தயோகம் பின்பு அமிர்தயோகம்",
        },
        {"label": "சந்திராஷ்டமம்", "value": "இன்று முழுவதும் ரோகிணி"},
        {"label": "நேத்திரம்", "value": "இன்று முழுவதும் இரண்டு கண்"},
        {"label": "ஜீவன்", "value": "இன்று முழுவதும் முழுவாழ்க்கை"},
    ]
    rasi = [
        "சனி",
        "செவ்",
        "சூரி",
        "சுக் புத",
        None,
        None,
        None,
        None,
        "ராகு",
        None,
        None,
        "குரு",
        "கேது",
        None,
        None,
        "சந்",
    ]
    base = {
        "city_id": "chennai",
        "month_label_ta": "ஜூன் - புதன்",
        "gregorian_display": "03-06-2026",
        "subtitle_line1_ta": "ரிஷபம் மாதம் - வசந்த ருது - உத்தராயணம்",
        "subtitle_line2_ta": "பராபவ - வைகாசி - 20",
        "banner_line_ta": "வைகாசி - 20, புதன்",
        "events_ta": "கோவளம் தமீம் அன்சாரி பாஷா உருஸ், உலக மிதிவண்டி தினம்",
        "nalla_neram_json": json.dumps(
            [
                {"period": "காலை", "time": "10.30 - 11.30"},
                {"period": "மாலை", "time": "04.30 - 05.30"},
            ],
            ensure_ascii=False,
        ),
        "gowri_nalla_neram_json": json.dumps(
            [
                {"period": "காலை", "time": "01.30 - 02.30"},
                {"period": "மாலை", "time": "06.30 - 07.30"},
            ],
            ensure_ascii=False,
        ),
        "panchangam_json": json.dumps(panchangam, ensure_ascii=False),
        "inauspicious_json": json.dumps(
            [
                {"name": "இராகு", "time": "12.00 PM - 1.30 PM"},
                {"name": "குளிகை", "time": "10.30 AM - 12.00 PM"},
                {"name": "எமகண்டம்", "time": "7.30 AM - 9.00 AM"},
            ],
            ensure_ascii=False,
        ),
        "shoolam_ta": "சூலம் - வடக்கு",
        "pariharam_ta": "பரிகாரம் - பால்",
        "lagnam_ta": "ரிஷபம் லக்னம் இருப்பு 01 நாழிகை 50 விநாடி",
        "rasi_chart_json": json.dumps(rasi, ensure_ascii=False),
        "rasi_center_ta": "01 - மிது - சுக்",
        "horoscope_json": json.dumps(horoscope, ensure_ascii=False),
        "quote_ta": "வெற்றி பெறும் ஒவ்வொரு செயலும் ஒரு குறிக்கோளாக ஆகிவிடுகிறது.",
        "birthdays_ta": "1. தமிழக முன்னாள் முதல்வர் கலைஞர்",
        "note_ta": "குறிப்பு : நாட்காட்டி பகுதியில் உள்ள அனைத்து தகவல்களும் தினசரி காலண்டர் அடிப்படையில் கொடுக்கப்பட்டுள்ளது.",
    }
    start = date(2026, 6, 1)
    for i in range(30):
        d = start + timedelta(days=i)
        disp = d.strftime("%d-%m-%Y")
        weekdays = ["திங்கள்", "செவ்வாய்", "புதன்", "வியாழன்", "வெள்ளி", "சனி", "ஞாயிறு"]
        wd = weekdays[d.weekday()]
        row = DailyCalendar(
            gregorian_date=d,
            month_label_ta=f"ஜூன் - {wd}",
            gregorian_display=disp,
            banner_line_ta=f"வைகாசி - {17 + d.day}, {wd}",
            **{k: v for k, v in base.items() if k != "gregorian_display" and k != "month_label_ta" and k != "banner_line_ta"},
        )
        row.gregorian_display = disp
        row.month_label_ta = f"ஜூன் - {wd}"
        row.banner_line_ta = f"வைகாசி - {17 + d.day}, {wd}"
        existing = (
            db.query(DailyCalendar)
            .filter(DailyCalendar.city_id == "chennai", DailyCalendar.gregorian_date == d)
            .first()
        )
        if existing:
            for k in base:
                if hasattr(existing, k):
                    setattr(existing, k, getattr(row, k))
            existing.gregorian_display = disp
            existing.month_label_ta = row.month_label_ta
            existing.banner_line_ta = row.banner_line_ta
        else:
            db.add(row)


def seed_month_june(db) -> None:
    month = MonthCalendar(
        city_id="chennai",
        year=2026,
        month=6,
        month_label_ta="ஜூன் - 2026",
        tamil_months_ta="வைகாசி - ஆனி",
        days_json=json.dumps(_june_month_days(), ensure_ascii=False),
        fasting_days_json=json.dumps(
            [
                {"icon": "amavasai", "title_ta": "அமாவாசை", "dates_ta": "14 ஞாயிறு"},
                {"icon": "pournami", "title_ta": "பௌர்ணமி", "dates_ta": "29 திங்கள்"},
                {"icon": "star", "title_ta": "கிருத்திகை", "dates_ta": "13 சனி"},
                {"icon": "vishnu", "title_ta": "திருவோணம்", "dates_ta": "5 வெள்ளி"},
                {"icon": "ekadasi", "title_ta": "ஏகாதசி", "dates_ta": "11 வியாழன், 25 வியாழன்"},
                {"icon": "sashti", "title_ta": "சஷ்டி", "dates_ta": "6 சனி, 20 சனி"},
                {"icon": "ganesha", "title_ta": "சங்கடஹர சதுர்த்தி", "dates_ta": "4 வியாழன்"},
                {"icon": "shiva", "title_ta": "சிவராத்திரி", "dates_ta": "13 சனி"},
                {"icon": "nandi", "title_ta": "பிரதோஷம்", "dates_ta": "12 வெள்ளி, 27 சனி"},
                {"icon": "ganesha", "title_ta": "சதுர்த்தி", "dates_ta": "18 வியாழன்"},
            ],
            ensure_ascii=False,
        ),
        wedding_days_json=json.dumps(
            [
                "ஜூன் 4 - வைகாசி 21 - வியாழன்",
                "ஜூன் 7 - வைகாசி 24 - ஞாயிறு",
                "ஜூன் 17 - ஆனி 3 - புதன் *",
                "ஜூன் 18 - ஆனி 4 - வியாழன் *",
                "ஜூன் 24 - ஆனி 10 - புதன் *",
            ],
            ensure_ascii=False,
        ),
        other_days_json=json.dumps(
            [
                {"title": "அஷ்டமி", "dates": "8 திங்கள், 22 திங்கள்"},
                {"title": "நவமி", "dates": "9 செவ்வாய், 23 செவ்வாய்"},
                {"title": "தசமி", "dates": "10 புதன், 24 புதன்"},
                {"title": "கரி நாட்கள்", "dates": "15 திங்கள், 20 சனி"},
            ],
            ensure_ascii=False,
        ),
        hindu_festivals_json=json.dumps(
            [
                {"day": "20", "title": "ஸ்ரீ மாணிக்கவாசகர் குரு பூஜை"},
                {"day": "22", "title": "ஆனி உத்திர தரிசனம்"},
            ],
            ensure_ascii=False,
        ),
        muslim_festivals_json=json.dumps(
            [
                {"day": "3", "title": "கோவளம் தமீம் அன்சாரி பாஷா உருஸ்"},
                {"day": "17", "title": "ஹிஜ்ரி புத்தாண்டு"},
                {"day": "26", "title": "முஹர்ரம் பண்டிகை"},
            ],
            ensure_ascii=False,
        ),
        christian_festivals_json=json.dumps(
            [
                {"day": "4", "title": "கார்ப்பஸ் கிறிஸ்தி"},
                {"day": "29", "title": "ஆர்ச் பீட்டர் அன்பல்"},
            ],
            ensure_ascii=False,
        ),
        government_holidays_json=json.dumps(
            [{"day": "26", "title": "முஹர்ரம் பண்டிகை"}],
            ensure_ascii=False,
        ),
    )
    existing = (
        db.query(MonthCalendar)
        .filter(MonthCalendar.city_id == "chennai", MonthCalendar.year == 2026, MonthCalendar.month == 6)
        .first()
    )
    if existing:
        for col in [
            "month_label_ta",
            "tamil_months_ta",
            "days_json",
            "fasting_days_json",
            "wedding_days_json",
            "other_days_json",
            "hindu_festivals_json",
            "muslim_festivals_json",
            "christian_festivals_json",
            "government_holidays_json",
        ]:
            setattr(existing, col, getattr(month, col))
    else:
        db.add(month)


def ensure_cities() -> None:
    from app.ingestion.seed_cities import ensure_world_cities

    ensure_world_cities()


def run_seed() -> None:
    """Demo/sample UI data (manual). Prefer ingestion fetch_month for real panchang."""
    Base.metadata.create_all(bind=engine)
    db = SessionLocal()
    try:
        ensure_cities()
        seed_daily_june_3(db)
        seed_month_june(db)
        db.commit()
        print("Seed completed.")
    finally:
        db.close()


if __name__ == "__main__":
    run_seed()
