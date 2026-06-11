from datetime import date

from fastapi import APIRouter, Depends, HTTPException, Query
from sqlalchemy.orm import Session

from app.database import get_db
from app.models import DailyCalendar, MonthCalendar
from app.schemas import DailyCalendarIn, DailyCalendarOut, MonthCalendarIn, MonthCalendarOut
from app.serializers import daily_from_schema, daily_to_schema, month_from_schema, month_to_schema

router = APIRouter(prefix="/admin", tags=["admin"])


@router.get("/daily", response_model=list[DailyCalendarOut])
def admin_list_daily(
    city_id: str | None = None,
    limit: int = Query(default=50, le=200),
    db: Session = Depends(get_db),
):
    q = db.query(DailyCalendar).order_by(DailyCalendar.gregorian_date.desc())
    if city_id:
        q = q.filter(DailyCalendar.city_id == city_id)
    return [daily_to_schema(r) for r in q.limit(limit).all()]


@router.get("/daily/{city_id}/{on_date}", response_model=DailyCalendarOut)
def admin_get_daily(city_id: str, on_date: date, db: Session = Depends(get_db)):
    row = (
        db.query(DailyCalendar)
        .filter(DailyCalendar.city_id == city_id, DailyCalendar.gregorian_date == on_date)
        .first()
    )
    if not row:
        raise HTTPException(404, detail="Not found")
    return daily_to_schema(row)


@router.put("/daily/{city_id}/{on_date}", response_model=DailyCalendarOut)
def admin_upsert_daily(city_id: str, on_date: date, body: DailyCalendarIn, db: Session = Depends(get_db)):
    if body.city_id != city_id or body.gregorian_date != on_date:
        raise HTTPException(400, detail="Path and body city/date must match")
    row = (
        db.query(DailyCalendar)
        .filter(DailyCalendar.city_id == city_id, DailyCalendar.gregorian_date == on_date)
        .first()
    )
    fields = daily_from_schema(body)
    if row:
        for k, v in fields.items():
            setattr(row, k, v)
        row.data_version = (row.data_version or 1) + 1
    else:
        row = DailyCalendar(**fields)
        db.add(row)
    db.commit()
    db.refresh(row)
    return daily_to_schema(row)


@router.get("/month/{city_id}/{year}/{month}", response_model=MonthCalendarOut)
def admin_get_month(city_id: str, year: int, month: int, db: Session = Depends(get_db)):
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
        raise HTTPException(404, detail="Not found")
    return month_to_schema(row)


@router.put("/month/{city_id}/{year}/{month}", response_model=MonthCalendarOut)
def admin_upsert_month(
    city_id: str, year: int, month: int, body: MonthCalendarIn, db: Session = Depends(get_db)
):
    if body.city_id != city_id or body.year != year or body.month != month:
        raise HTTPException(400, detail="Path and body must match")
    row = (
        db.query(MonthCalendar)
        .filter(
            MonthCalendar.city_id == city_id,
            MonthCalendar.year == year,
            MonthCalendar.month == month,
        )
        .first()
    )
    fields = month_from_schema(body)
    if row:
        for k, v in fields.items():
            setattr(row, k, v)
    else:
        row = MonthCalendar(**fields)
        db.add(row)
    db.commit()
    db.refresh(row)
    return month_to_schema(row)
