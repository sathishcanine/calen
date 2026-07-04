from datetime import date

from fastapi import APIRouter, Depends, File, Form, HTTPException, Query, Request, UploadFile
from sqlalchemy.orm import Session

from app.config import settings
from app.data.metal_rates_service import get_admin_status, sync_retail
from app.data.status_stories_service import add_story, delete_story, list_stories as list_status_stories
from app.database import get_db
from app.models import DailyCalendar, MonthCalendar
from app.schemas import DailyCalendarIn, DailyCalendarOut, MonthCalendarIn, MonthCalendarOut, StatusStoryOut
from app.serializers import daily_from_schema, daily_to_schema, month_from_schema, month_to_schema

router = APIRouter(prefix="/admin", tags=["admin"])


def _admin_status_story_out(entry: dict, request: Request) -> StatusStoryOut:
    base = str(request.base_url).rstrip("/")
    image_url = f"{base}{settings.api_prefix}/status-media/{entry['filename']}"
    return StatusStoryOut(
        id=entry["id"],
        image_url=image_url,
        title=entry.get("title") or "",
        caption=entry.get("caption") or "",
        created_at=entry["created_at"],
    )


@router.get("/status-stories", response_model=list[StatusStoryOut])
def admin_list_status_stories(request: Request):
    return [_admin_status_story_out(entry, request) for entry in list_status_stories(admin=True)]


@router.post("/status-stories", response_model=StatusStoryOut)
async def admin_upload_status_story(
    request: Request,
    file: UploadFile = File(...),
    title: str = Form(default=""),
    caption: str = Form(default=""),
):
    content = await file.read()
    if not content:
        raise HTTPException(400, detail="Empty file")
    try:
        entry = add_story(
            filename=file.filename or "story.jpg",
            content=content,
            title=title,
            caption=caption,
        )
    except ValueError as exc:
        raise HTTPException(400, detail=str(exc)) from exc
    return _admin_status_story_out(entry, request)


@router.delete("/status-stories/{story_id}")
def admin_delete_status_story(story_id: str):
    if not delete_story(story_id):
        raise HTTPException(404, detail="Story not found")
    return {"ok": True}


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


@router.get("/metal-rates/status")
def admin_metal_rates_status(db: Session = Depends(get_db)):
    """Current stored retail rates (no scrape)."""
    return get_admin_status(db)


@router.post("/metal-rates/sync")
def admin_sync_metal_rates(db: Session = Depends(get_db)):
    """Fetch retail gold/silver rates from Goodreturns & LiveChennai."""
    live = sync_retail(db)
    status = get_admin_status(db)
    return {
        "ok": True,
        "source": "retail",
        "rate_date": live.rate_date.isoformat(),
        "gold_22k_per_gram": live.gold_22k_per_gram,
        "gold_24k_per_gram": live.gold_24k_per_gram,
        "silver_kg": live.silver_kg,
        "fetched_at": status["fetched_at"],
        "daily_history_days": status["daily_history_days"],
    }
