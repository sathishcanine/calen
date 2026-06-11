import json
from datetime import date, timedelta

from fastapi import APIRouter, Depends, HTTPException, Query
from sqlalchemy.orm import Session

from app.database import get_db
from app.ingestion.spiritual_data import get_daily_fields
from app.models import City, DailyCalendar, MonthCalendar
from app.schemas import (
    CityOut,
    DailyBundleOut,
    DailyCalendarOut,
    GowriSectionOut,
    GowriSlotOut,
    GowriWeekDayOut,
    GowriWeekOut,
    HoraSectionOut,
    HoraSlotOut,
    HoraWeekDayOut,
    HoraWeekOut,
    HomeSummaryOut,
    InauspiciousWeekDayOut,
    InauspiciousWeekOut,
    MonthCalendarOut,
)
from app.serializers import daily_to_schema, month_to_schema

router = APIRouter()


@router.get("/health")
def health():
    return {"status": "ok"}


@router.get("/cities", response_model=list[CityOut])
def list_cities(db: Session = Depends(get_db)):
    return db.query(City).order_by(City.name_en).all()


@router.get("/home", response_model=HomeSummaryOut)
def home_summary(
    city_id: str = Query(default="chennai"),
    on_date: date | None = Query(default=None, alias="date"),
    db: Session = Depends(get_db),
):
    target = on_date or date.today()
    row = (
        db.query(DailyCalendar)
        .filter(DailyCalendar.city_id == city_id, DailyCalendar.gregorian_date == target)
        .first()
    )
    if not row:
        raise HTTPException(404, detail="Daily data not found for this date")
    return HomeSummaryOut(
        banner_line_ta=row.banner_line_ta,
        gregorian_display=row.gregorian_display,
        gregorian_date=row.gregorian_date,
    )


@router.get("/calendar/day", response_model=DailyCalendarOut)
def get_day(
    city_id: str = Query(default="chennai"),
    on_date: date = Query(..., alias="date"),
    db: Session = Depends(get_db),
):
    row = (
        db.query(DailyCalendar)
        .filter(DailyCalendar.city_id == city_id, DailyCalendar.gregorian_date == on_date)
        .first()
    )
    if not row:
        raise HTTPException(404, detail="Daily calendar not found")
    return daily_to_schema(row)


@router.get("/sync/daily-bundle", response_model=DailyBundleOut)
def daily_bundle(
    city_id: str = Query(default="chennai"),
    from_date: date = Query(..., alias="from"),
    days: int = Query(default=30, ge=1, le=60),
    db: Session = Depends(get_db),
):
    end = from_date + timedelta(days=days - 1)
    rows = (
        db.query(DailyCalendar)
        .filter(
            DailyCalendar.city_id == city_id,
            DailyCalendar.gregorian_date >= from_date,
            DailyCalendar.gregorian_date <= end,
        )
        .order_by(DailyCalendar.gregorian_date)
        .all()
    )
    items = [daily_to_schema(r) for r in rows]
    version = max((r.data_version for r in rows), default=1)
    return DailyBundleOut(
        city_id=city_id,
        from_date=from_date,
        days=days,
        data_version=version,
        items=items,
    )


def _week_sunday(target: date) -> date:
    return target - timedelta(days=(target.weekday() + 1) % 7)


@router.get("/spiritual/inauspicious-week", response_model=InauspiciousWeekOut)
def inauspicious_week(
    city_id: str = Query(default="chennai"),
    on_date: date | None = Query(default=None, alias="date"),
    db: Session = Depends(get_db),
):
    """Rahu / Gulikai / Yamagandam for Sun–Sat of the week containing `date`."""
    target = on_date or date.today()
    city = db.query(City).filter(City.id == city_id).first()
    if not city:
        raise HTTPException(404, detail="City not found")

    sunday = _week_sunday(target)
    days: list[InauspiciousWeekDayOut] = []

    for offset in range(7):
        d = sunday + timedelta(days=offset)
        row = get_daily_fields(db, city, d)
        inauspicious = json.loads(row.get("inauspicious_json") or "[]")

        def _slot(name: str) -> str:
            for slot in inauspicious:
                if slot.get("name") == name:
                    return slot.get("time", "")
            return ""

        shoolam_full = row.get("shoolam_ta") or ""
        shoolam = shoolam_full.replace("சூலம் - ", "").strip()

        pariharam_full = row.get("pariharam_ta") or ""
        pariharam = pariharam_full.replace("பரிகாரம் - ", "").strip()

        label = row.get("month_label_ta") or ""
        weekday_ta = label.split(" - ")[-1].strip() if " - " in label else ""

        days.append(
            InauspiciousWeekDayOut(
                weekday_ta=weekday_ta,
                gregorian_date=d,
                rahu_kalam=_slot("இராகு"),
                gulikai_kalam=_slot("குளிகை"),
                yamagandam=_slot("எமகண்டம்"),
                shoolam=shoolam,
                pariharam=pariharam,
            )
        )

    return InauspiciousWeekOut(city_id=city_id, week_start=sunday, days=days)


@router.get("/spiritual/gowri-week", response_model=GowriWeekOut)
def gowri_week(
    city_id: str = Query(default="chennai"),
    on_date: date | None = Query(default=None, alias="date"),
    db: Session = Depends(get_db),
):
    """Gowri Panchangam for Sun–Sat of the week containing `date`."""
    target = on_date or date.today()
    city = db.query(City).filter(City.id == city_id).first()
    if not city:
        raise HTTPException(404, detail="City not found")

    sunday = _week_sunday(target)
    days: list[GowriWeekDayOut] = []

    for offset in range(7):
        d = sunday + timedelta(days=offset)
        row = get_daily_fields(db, city, d)
        gowri = json.loads(row.get("gowri_panchangam_json") or "{}")
        sections_raw = gowri.get("sections") or []

        label = row.get("month_label_ta") or ""
        weekday_ta = label.split(" - ")[-1].strip() if " - " in label else ""

        sections = [
            GowriSectionOut(
                period=s.get("period", ""),
                slots=[GowriSlotOut(**slot) for slot in s.get("slots") or []],
            )
            for s in sections_raw
        ]

        days.append(
            GowriWeekDayOut(
                weekday_ta=weekday_ta,
                gregorian_date=d,
                sections=sections,
            )
        )

    return GowriWeekOut(city_id=city_id, week_start=sunday, days=days)


@router.get("/spiritual/hora-week", response_model=HoraWeekOut)
def hora_week(
    city_id: str = Query(default="chennai"),
    on_date: date | None = Query(default=None, alias="date"),
    db: Session = Depends(get_db),
):
    """Planetary Hora (கிரக ஓரை) for Sun–Sat of the week containing `date`."""
    target = on_date or date.today()
    city = db.query(City).filter(City.id == city_id).first()
    if not city:
        raise HTTPException(404, detail="City not found")

    sunday = _week_sunday(target)
    days: list[HoraWeekDayOut] = []

    for offset in range(7):
        d = sunday + timedelta(days=offset)
        row = get_daily_fields(db, city, d)
        hora = json.loads(row.get("hora_json") or "{}")
        sections_raw = hora.get("sections") or []

        label = row.get("month_label_ta") or ""
        weekday_ta = label.split(" - ")[-1].strip() if " - " in label else ""

        sections = [
            HoraSectionOut(
                period=s.get("period", ""),
                slots=[HoraSlotOut(**slot) for slot in s.get("slots") or []],
            )
            for s in sections_raw
        ]

        days.append(
            HoraWeekDayOut(
                weekday_ta=weekday_ta,
                gregorian_date=d,
                sections=sections,
            )
        )

    return HoraWeekOut(city_id=city_id, week_start=sunday, days=days)


@router.get("/calendar/month", response_model=MonthCalendarOut)
def get_month(
    city_id: str = Query(default="chennai"),
    year: int = Query(...),
    month: int = Query(..., ge=1, le=12),
    db: Session = Depends(get_db),
):
    row = (
        db.query(MonthCalendar)
        .filter(
            MonthCalendar.city_id == city_id,
            MonthCalendar.year == year,
            MonthCalendar.month == month,
        )
        .first()
    )
    if not row:
        raise HTTPException(404, detail="Month calendar not found")
    return month_to_schema(row)
