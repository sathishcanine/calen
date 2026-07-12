from datetime import date, timedelta
import json

from fastapi import APIRouter, Depends, File, Form, HTTPException, Query, Request, UploadFile
from sqlalchemy.orm import Session

from app.config import settings
from app.admin_auth import create_token, require_admin, verify_password
from app.data.metal_rates_service import get_admin_status, sync_retail
from app.data.status_stories_service import add_story, delete_story, list_stories as list_status_stories
from app.data import books_service
from app.data import posts_service
from app.data.post_content import resolve_blocks_for_api
from app.data import indru_push_service
from app.data import raasi_palan_service
from app.push_service import send_indru_push, send_post_push
from app.data.indru_service import (
    LOOKAHEAD_DAYS,
    _today_ist,
    get_indru_for_date,
    indru_to_dict,
    refresh_indru_range,
)
from app.database import get_db
from app.models import DailyCalendar, MonthCalendar, IndruDaily
from app.schemas import (
    DailyCalendarIn,
    DailyCalendarOut,
    MonthCalendarIn,
    MonthCalendarOut,
    StatusStoryOut,
    BookCategoryOut,
    BookCategoryIn,
    LibraryBookOut,
    PostOut,
    PostBlockOut,
    IndruPushOut,
    IndruDailyOut,
    IndruDailyIn,
    AdminLoginIn,
    AdminLoginOut,
    RaasiPalanSignIn,
    RaasiPalanSignOut,
    RaasiPalanPeriodIn,
    RaasiPalanPeriodOut,
)
from app.serializers import daily_from_schema, daily_to_schema, month_from_schema, month_to_schema

router = APIRouter(prefix="/admin", tags=["admin"])
secured = APIRouter(dependencies=[Depends(require_admin)])


@router.post("/login", response_model=AdminLoginOut)
def admin_login(body: AdminLoginIn):
    if not settings.admin_password:
        raise HTTPException(503, detail="Admin password not configured on server")
    if not verify_password(body.password):
        raise HTTPException(401, detail="Invalid password")
    token, expires_at = create_token()
    return AdminLoginOut(token=token, expires_at=expires_at)


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


@secured.get("/status-stories", response_model=list[StatusStoryOut])
def admin_list_status_stories(request: Request):
    return [_admin_status_story_out(entry, request) for entry in list_status_stories(admin=True)]


@secured.post("/status-stories", response_model=StatusStoryOut)
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


@secured.delete("/status-stories/{story_id}")
def admin_delete_status_story(story_id: str):
    if not delete_story(story_id):
        raise HTTPException(404, detail="Story not found")
    return {"ok": True}


def _book_out(entry, request: Request) -> LibraryBookOut:
    base = str(request.base_url).rstrip("/")
    pdf_url = f"{base}{settings.api_prefix}/book-media/{entry.filename}"
    preview_url = None
    if entry.preview_filename:
        preview_url = f"{base}{settings.api_prefix}/book-preview-media/{entry.preview_filename}"
    return LibraryBookOut(
        id=entry.id,
        category_id=entry.category_id,
        title=entry.title,
        author=entry.author or "",
        pdf_url=pdf_url,
        preview_url=preview_url,
        file_size=entry.file_size or 0,
        sort_order=entry.sort_order or 0,
        created_at=entry.created_at,
    )


@secured.get("/book-categories", response_model=list[BookCategoryOut])
def admin_list_book_categories(request: Request, db: Session = Depends(get_db)):
    del request
    return [
        BookCategoryOut(
            id=c.id,
            name=c.name,
            sort_order=c.sort_order,
            book_count=books_service.book_count_for_category(db, c.id),
            created_at=c.created_at,
        )
        for c in books_service.list_categories(db)
    ]


@secured.post("/book-categories", response_model=BookCategoryOut)
def admin_create_book_category(body: BookCategoryIn, db: Session = Depends(get_db)):
    name = body.name.strip()
    if not name:
        raise HTTPException(400, detail="Category name required")
    row = books_service.create_category(db, name=name)
    return BookCategoryOut(
        id=row.id,
        name=row.name,
        sort_order=row.sort_order,
        book_count=0,
        created_at=row.created_at,
    )


@secured.delete("/book-categories/{category_id}")
def admin_delete_book_category(category_id: str, db: Session = Depends(get_db)):
    if not books_service.delete_category(db, category_id):
        raise HTTPException(404, detail="Category not found")
    return {"ok": True}


@secured.get("/books", response_model=list[LibraryBookOut])
def admin_list_books(
    request: Request,
    category_id: str | None = None,
    db: Session = Depends(get_db),
):
    return [_book_out(b, request) for b in books_service.list_books(db, category_id)]


@secured.post("/books", response_model=LibraryBookOut)
async def admin_upload_book(
    request: Request,
    file: UploadFile = File(...),
    category_id: str = Form(...),
    title: str = Form(default=""),
    author: str = Form(default=""),
    preview: UploadFile | None = File(default=None),
    db: Session = Depends(get_db),
):
    content = await file.read()
    preview_content: bytes | None = None
    preview_name: str | None = None
    if preview is not None and preview.filename:
        preview_content = await preview.read()
        preview_name = preview.filename
    try:
        entry = books_service.add_book(
            db,
            category_id=category_id,
            title=title,
            content=content,
            original_filename=file.filename or "book.pdf",
            author=author,
            preview_content=preview_content if preview_content else None,
            preview_original_filename=preview_name,
        )
    except ValueError as exc:
        raise HTTPException(400, detail=str(exc)) from exc
    return _book_out(entry, request)


@secured.delete("/books/{book_id}")
def admin_delete_book(book_id: str, db: Session = Depends(get_db)):
    if not books_service.delete_book(db, book_id):
        raise HTTPException(404, detail="Book not found")
    return {"ok": True}


@secured.get("/daily", response_model=list[DailyCalendarOut])
def admin_list_daily(
    city_id: str | None = None,
    limit: int = Query(default=50, le=200),
    db: Session = Depends(get_db),
):
    q = db.query(DailyCalendar).order_by(DailyCalendar.gregorian_date.desc())
    if city_id:
        q = q.filter(DailyCalendar.city_id == city_id)
    return [daily_to_schema(r) for r in q.limit(limit).all()]


@secured.get("/daily/{city_id}/{on_date}", response_model=DailyCalendarOut)
def admin_get_daily(city_id: str, on_date: date, db: Session = Depends(get_db)):
    row = (
        db.query(DailyCalendar)
        .filter(DailyCalendar.city_id == city_id, DailyCalendar.gregorian_date == on_date)
        .first()
    )
    if not row:
        raise HTTPException(404, detail="Not found")
    return daily_to_schema(row)


@secured.put("/daily/{city_id}/{on_date}", response_model=DailyCalendarOut)
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


@secured.get("/month/{city_id}/{year}/{month}", response_model=MonthCalendarOut)
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


@secured.put("/month/{city_id}/{year}/{month}", response_model=MonthCalendarOut)
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


@secured.get("/metal-rates/status")
def admin_metal_rates_status(db: Session = Depends(get_db)):
    """Current stored retail rates (no scrape)."""
    return get_admin_status(db)


@secured.post("/metal-rates/sync")
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


@secured.get("/indru", response_model=list[IndruDailyOut])
def admin_list_indru(
    from_date: date | None = Query(default=None, alias="from"),
    days: int = Query(default=LOOKAHEAD_DAYS + 1, ge=1, le=31),
    db: Session = Depends(get_db),
):
    start = from_date or _today_ist()
    rows = (
        db.query(IndruDaily)
        .filter(
            IndruDaily.gregorian_date >= start,
            IndruDaily.gregorian_date < start + timedelta(days=days),
        )
        .order_by(IndruDaily.gregorian_date)
        .all()
    )
    return [IndruDailyOut(**indru_to_dict(r)) for r in rows]


@secured.get("/indru/{on_date}", response_model=IndruDailyOut)
def admin_get_indru(on_date: date, db: Session = Depends(get_db)):
    row = get_indru_for_date(db, on_date)
    return IndruDailyOut(**indru_to_dict(row))


@secured.put("/indru/{on_date}", response_model=IndruDailyOut)
def admin_upsert_indru(on_date: date, body: IndruDailyIn, db: Session = Depends(get_db)):
    row = db.query(IndruDaily).filter(IndruDaily.gregorian_date == on_date).first()
    data = body.model_dump()
    data["source"] = "admin"
    if row:
        for key, value in data.items():
            setattr(row, key, value)
    else:
        row = IndruDaily(gregorian_date=on_date, **data)
        db.add(row)
    db.commit()
    db.refresh(row)
    return IndruDailyOut(**indru_to_dict(row))


@secured.post("/indru/refresh")
def admin_refresh_indru(
    on_date: date | None = Query(default=None, alias="date"),
    days: int = Query(default=LOOKAHEAD_DAYS + 1, ge=1, le=31),
    force: bool = Query(default=True),
    db: Session = Depends(get_db),
):
    start = on_date or _today_ist()
    rows = refresh_indru_range(db, start, days=days, force=force)
    return {
        "ok": True,
        "from": start.isoformat(),
        "days": days,
        "count": len(rows),
    }


def _post_out(entry, request: Request) -> PostOut:
    base = str(request.base_url).rstrip("/")
    prefix = settings.api_prefix

    def media_url(filename: str) -> str:
        return f"{base}{prefix}/post-media/{filename}"

    image_url = media_url(entry.image_filename)
    blocks_raw = resolve_blocks_for_api(entry.content or "", media_url)
    blocks = [PostBlockOut(**block) for block in blocks_raw]
    return PostOut(
        id=entry.id,
        title=entry.title,
        content=entry.content or "",
        image_url=image_url,
        push_sent=bool(entry.push_sent),
        created_at=entry.created_at,
        blocks=blocks,
    )


@secured.post("/post-media")
async def admin_upload_post_media(
    request: Request,
    file: UploadFile = File(...),
):
    """Upload an inline image for the blog-style block editor."""
    image_bytes = await file.read()
    try:
        filename = posts_service.store_image(
            filename=file.filename or "image.jpg",
            image_bytes=image_bytes,
        )
    except ValueError as exc:
        raise HTTPException(400, detail=str(exc)) from exc
    base = str(request.base_url).rstrip("/")
    image_url = f"{base}{settings.api_prefix}/post-media/{filename}"
    return {"filename": filename, "image_url": image_url}


@secured.get("/posts", response_model=list[PostOut])
def admin_list_posts(request: Request, db: Session = Depends(get_db)):
    return [_post_out(p, request) for p in posts_service.list_posts(db)]


@secured.post("/posts", response_model=PostOut)
async def admin_create_post(
    request: Request,
    db: Session = Depends(get_db),
    title: str = Form(...),
    send_push: str = Form(default="false"),
    blocks: str = Form(default=""),
    file: UploadFile | None = File(default=None),
    content: str = Form(default=""),
):
    try:
        if blocks.strip():
            parsed = json.loads(blocks)
            if not isinstance(parsed, list):
                raise ValueError("Invalid blocks format")
            cover_filename = ""
            if file is not None:
                image_bytes = await file.read()
                if image_bytes:
                    cover_filename = posts_service.store_image(
                        filename=file.filename or "cover.jpg",
                        image_bytes=image_bytes,
                    )
            row = posts_service.add_post_with_blocks(
                db,
                title=title,
                blocks=parsed,
                cover_filename=cover_filename,
            )
        else:
            if file is None:
                raise HTTPException(400, detail="Choose a cover image or add image blocks")
            image_bytes = await file.read()
            row = posts_service.add_post(
                db,
                title=title,
                content=content,
                filename=file.filename or "post.jpg",
                image_bytes=image_bytes,
            )
    except ValueError as exc:
        raise HTTPException(400, detail=str(exc)) from exc
    except json.JSONDecodeError as exc:
        raise HTTPException(400, detail="Invalid blocks JSON") from exc

    out = _post_out(row, request)
    api_base = str(request.base_url).rstrip("/")
    if send_push.strip().lower() in {"true", "1", "yes", "on"}:
        pushed = send_post_push(
            post_id=row.id,
            title=row.title,
            body=posts_service.push_notification_body(row.content),
            image_filename=row.image_filename,
            api_base=api_base,
        )
        if pushed:
            posts_service.mark_push_sent(db, row)
            out = _post_out(row, request)
    return out


@secured.post("/posts/{post_id}/push", response_model=PostOut)
def admin_push_post(post_id: str, request: Request, db: Session = Depends(get_db)):
    row = posts_service.get_post(db, post_id)
    if not row:
        raise HTTPException(404, detail="Post not found")
    out = _post_out(row, request)
    api_base = str(request.base_url).rstrip("/")
    pushed = send_post_push(
        post_id=row.id,
        title=row.title,
        body=posts_service.push_notification_body(row.content),
        image_filename=row.image_filename,
        api_base=api_base,
    )
    if not pushed:
        raise HTTPException(503, detail="Push notification unavailable (check FIREBASE_CREDENTIALS_PATH)")
    posts_service.mark_push_sent(db, row)
    return _post_out(row, request)


@secured.delete("/posts/{post_id}")
def admin_delete_post(post_id: str, db: Session = Depends(get_db)):
    if not posts_service.delete_post(db, post_id):
        raise HTTPException(404, detail="Post not found")
    return {"ok": True}


def _indru_push_out(entry, request: Request) -> IndruPushOut:
    image_url = None
    if entry.image_filename:
        base = str(request.base_url).rstrip("/")
        image_url = f"{base}{settings.api_prefix}/indru-push-media/{entry.image_filename}"
    return IndruPushOut(
        id=entry.id,
        title=entry.title,
        body=entry.body or "",
        image_url=image_url,
        push_sent=bool(entry.push_sent),
        created_at=entry.created_at,
    )


@secured.get("/indru/pushes", response_model=list[IndruPushOut])
def admin_list_indru_pushes(request: Request, db: Session = Depends(get_db)):
    return [_indru_push_out(p, request) for p in indru_push_service.list_pushes(db)]


@secured.post("/indru/pushes", response_model=IndruPushOut)
async def admin_create_indru_push(
    request: Request,
    db: Session = Depends(get_db),
    title: str = Form(...),
    body: str = Form(default=""),
    send_push: str = Form(default="false"),
    file: UploadFile | None = File(default=None),
):
    image_bytes: bytes | None = None
    filename: str | None = None
    if file is not None and file.filename:
        image_bytes = await file.read()
        filename = file.filename
    try:
        row = indru_push_service.add_push(
            db,
            title=title,
            body=body,
            filename=filename,
            image_bytes=image_bytes if image_bytes else None,
        )
    except ValueError as exc:
        raise HTTPException(400, detail=str(exc)) from exc

    out = _indru_push_out(row, request)
    api_base = str(request.base_url).rstrip("/")
    if send_push.strip().lower() in {"true", "1", "yes", "on"}:
        pushed = send_indru_push(
            push_id=row.id,
            title=row.title,
            body=indru_push_service.push_notification_body(row.body),
            image_filename=row.image_filename,
            api_base=api_base,
        )
        if pushed:
            indru_push_service.mark_push_sent(db, row)
            out = _indru_push_out(row, request)
    return out


@secured.post("/indru/pushes/{push_id}/send", response_model=IndruPushOut)
def admin_send_indru_push(push_id: str, request: Request, db: Session = Depends(get_db)):
    row = indru_push_service.get_push(db, push_id)
    if not row:
        raise HTTPException(404, detail="Indru push not found")
    api_base = str(request.base_url).rstrip("/")
    pushed = send_indru_push(
        push_id=row.id,
        title=row.title,
        body=indru_push_service.push_notification_body(row.body),
        image_filename=row.image_filename,
        api_base=api_base,
    )
    if not pushed:
        raise HTTPException(503, detail="Push notification unavailable (check FIREBASE_CREDENTIALS_PATH)")
    indru_push_service.mark_push_sent(db, row)
    return _indru_push_out(row, request)


@secured.delete("/indru/pushes/{push_id}")
def admin_delete_indru_push(push_id: str, db: Session = Depends(get_db)):
    if not indru_push_service.delete_push(db, push_id):
        raise HTTPException(404, detail="Indru push not found")
    return {"ok": True}


def _raasi_sign_out(data: dict) -> RaasiPalanSignOut:
    return RaasiPalanSignOut(
        period=data.get("period") or "",
        period_label=data.get("period_label") or "",
        current_label=data.get("current_label") or "",
        updated_at=data.get("updated_at"),
        sign_index=int(data["sign_index"]),
        sign_ta=data.get("sign_ta") or "",
        general_ta=data.get("general_ta") or "",
        nakshatra_palan_ta=data.get("nakshatra_palan_ta") or "",
        balam_ta=data.get("balam_ta") or "",
        kavanam_ta=data.get("kavanam_ta") or "",
        ninaivu_ta=data.get("ninaivu_ta") or "",
        lucky_numbers_ta=data.get("lucky_numbers_ta") or "",
        lucky_colors_ta=data.get("lucky_colors_ta") or "",
        deity_ta=data.get("deity_ta") or "",
        career_ta=data.get("career_ta") or "",
        business_ta=data.get("business_ta") or "",
        family_ta=data.get("family_ta") or "",
        income_ta=data.get("income_ta") or "",
        arts_ta=data.get("arts_ta") or "",
        investments_ta=data.get("investments_ta") or "",
        jyotish_view_ta=data.get("jyotish_view_ta") or "",
        cautions_ta=data.get("cautions_ta") or "",
        special_ta=data.get("special_ta") or "",
        lucky_days_ta=data.get("lucky_days_ta") or "",
        chandrashtamam_ta=data.get("chandrashtamam_ta") or "",
        remedy_ta=data.get("remedy_ta") or "",
        graham_sancharam_ta=data.get("graham_sancharam_ta") or "",
    )


def _raasi_period_out(data: dict) -> RaasiPalanPeriodOut:
    return RaasiPalanPeriodOut(
        period=data["period"],
        period_label=data.get("period_label") or "",
        current_label=data.get("current_label") or "",
        updated_at=data.get("updated_at"),
        signs=[
            _raasi_sign_out({
                **s,
                "period": data["period"],
                "period_label": data.get("period_label") or "",
                "current_label": data.get("current_label") or "",
                "updated_at": data.get("updated_at"),
            })
            for s in data["signs"]
        ],
    )


@secured.get("/raasi-palan/{period}", response_model=RaasiPalanPeriodOut)
def admin_list_raasi_palan(period: str):
    try:
        return _raasi_period_out(raasi_palan_service.list_period(period))
    except ValueError as exc:
        raise HTTPException(400, detail=str(exc)) from exc


@secured.get("/raasi-palan/{period}/{sign_index}", response_model=RaasiPalanSignOut)
def admin_get_raasi_palan(period: str, sign_index: int):
    try:
        return _raasi_sign_out(raasi_palan_service.get_sign(period, sign_index))
    except ValueError as exc:
        raise HTTPException(400, detail=str(exc)) from exc


@secured.put("/raasi-palan/{period}/{sign_index}", response_model=RaasiPalanSignOut)
def admin_upsert_raasi_palan(period: str, sign_index: int, body: RaasiPalanSignIn):
    try:
        return _raasi_sign_out(
            raasi_palan_service.upsert_sign(period, sign_index, body.model_dump())
        )
    except ValueError as exc:
        raise HTTPException(400, detail=str(exc)) from exc


@secured.put("/raasi-palan/{period}", response_model=RaasiPalanPeriodOut)
def admin_upsert_raasi_palan_period(period: str, body: RaasiPalanPeriodIn):
    try:
        return _raasi_period_out(
            raasi_palan_service.upsert_period(
                period,
                [s.model_dump() for s in body.signs],
            )
        )
    except ValueError as exc:
        raise HTTPException(400, detail=str(exc)) from exc


router.include_router(secured)
