import json
from datetime import date, time, timedelta

from fastapi import APIRouter, Depends, HTTPException, Query, Request
from sqlalchemy.orm import Session

from app.data.pancha_pakshi_service import (
    calculate as pancha_pakshi_calculate,
    get_article as pancha_pakshi_article,
    list_articles as pancha_pakshi_articles,
    list_birth_paksha_options,
    list_nakshatras,
    supported_years as pancha_pakshi_years,
)
from app.data.palangal_content import get_article as palangal_article
from app.data.palangal_content import list_articles as palangal_articles
from app.data.palangal_content import list_categories as palangal_categories
from app.data import jyotish_service
from app.data.vastu_service import get_vastu_articles, get_vastu_days, get_vastu_years
from app.config import settings
from app.data.metal_rates_service import get_rates, has_today, list_cities as list_metal_cities, sync_retail
from app.data.status_stories_service import PUBLIC_LIMIT, list_stories as list_status_stories
from app.data import books_service
from app.data import posts_service
from app.data.indru_service import get_indru_for_date, indru_to_dict
from app.data.temples_service import get_temple_by_slug, list_temples
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
    VastuArticleOut,
    VastuDayOut,
    VastuDaysOut,
    PanchaPakshiArticleOut,
    PanchaPakshiArticleDetailOut,
    PanchaPakshiCalculateOut,
    PanchaPakshiNakshatraOut,
    PanchaPakshiPakshaOptionOut,
    PanchaPakshiSectionOut,
    PanchaPakshiSlotOut,
    JyotishNakshatraOut,
    JyotishRashiOut,
    NazhigaiConvertOut,
    ChandrashtamamOut,
    ChandrashtamamPeriodOut,
    NumerologyOut,
    MarriagePoruthamOut,
    PoruthamFactorOut,
    TarabalamOut,
    TarabalamPeriodOut,
    PalangalCategoryOut,
    PalangalArticleOut,
    PalangalArticleDetailOut,
    StatusStoryOut,
    MetalRateCityOut,
    MetalRatesOut,
    BookCategoryOut,
    LibraryBookOut,
    PostOut,
    IndruDailyOut,
    TempleOut,
)
from app.serializers import daily_to_schema, month_to_schema

router = APIRouter()


def _status_story_out(entry: dict, request: Request) -> StatusStoryOut:
    base = str(request.base_url).rstrip("/")
    image_url = f"{base}{settings.api_prefix}/status-media/{entry['filename']}"
    return StatusStoryOut(
        id=entry["id"],
        image_url=image_url,
        title=entry.get("title") or "",
        caption=entry.get("caption") or "",
        created_at=entry["created_at"],
    )


@router.get("/spiritual/status-stories", response_model=list[StatusStoryOut])
def status_stories(
    request: Request,
    limit: int = Query(default=PUBLIC_LIMIT, ge=1, le=PUBLIC_LIMIT),
):
    """Latest admin-uploaded story images for the mobile home screen (view-only)."""
    return [_status_story_out(entry, request) for entry in list_status_stories(limit=limit)]


def _post_out(entry, request: Request) -> PostOut:
    base = str(request.base_url).rstrip("/")
    image_url = f"{base}{settings.api_prefix}/post-media/{entry.image_filename}"
    return PostOut(
        id=entry.id,
        title=entry.title,
        content=entry.content or "",
        image_url=image_url,
        push_sent=bool(entry.push_sent),
        created_at=entry.created_at,
    )


@router.get("/posts", response_model=list[PostOut])
def list_posts(
    request: Request,
    db: Session = Depends(get_db),
    limit: int = Query(default=20, ge=1, le=50),
):
    return [_post_out(p, request) for p in posts_service.list_posts(db, limit=limit)]


@router.get("/posts/{post_id}", response_model=PostOut)
def get_post(post_id: str, request: Request, db: Session = Depends(get_db)):
    row = posts_service.get_post(db, post_id)
    if not row:
        raise HTTPException(404, detail="Post not found")
    return _post_out(row, request)


def _library_book_out(entry, request: Request) -> LibraryBookOut:
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


@router.get("/library/categories", response_model=list[BookCategoryOut])
def library_categories(request: Request, db: Session = Depends(get_db)):
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


@router.get("/library/books", response_model=list[LibraryBookOut])
def library_books(
    request: Request,
    category_id: str = Query(...),
    db: Session = Depends(get_db),
):
    return [_library_book_out(b, request) for b in books_service.list_books(db, category_id)]


@router.get("/spiritual/metal-rates/cities", response_model=list[MetalRateCityOut])
def metal_rate_cities():
    return [MetalRateCityOut(**c) for c in list_metal_cities()]


def _temple_out(entry, request: Request) -> TempleOut:
    base = str(request.base_url).rstrip("/")
    image_url = ""
    if entry.image_url:
        image_url = f"{base}{settings.api_prefix}/temple-media/{entry.image_url}"
    return TempleOut(
        id=entry.id,
        slug=entry.slug,
        name_ta=entry.name_ta,
        name_en=entry.name_en,
        location_ta=entry.location_ta,
        deity_ta=entry.deity_ta,
        description_ta=entry.description_ta,
        image_url=image_url,
        source_label=entry.source_label,
        source_url=entry.source_url,
        sort_order=entry.sort_order,
        is_featured=entry.is_featured,
        updated_at=entry.updated_at,
    )


@router.get("/spiritual/temples", response_model=list[TempleOut])
def spiritual_temples(
    request: Request,
    db: Session = Depends(get_db),
    limit: int = Query(default=30, ge=1, le=100),
    offset: int = Query(default=0, ge=0),
):
    return [_temple_out(row, request) for row in list_temples(db, limit=limit, offset=offset)]


@router.get("/spiritual/temples/{slug}", response_model=TempleOut)
def spiritual_temple_detail(
    slug: str,
    request: Request,
    db: Session = Depends(get_db),
):
    row = get_temple_by_slug(db, slug)
    if row is None:
        raise HTTPException(404, detail="Temple not found")
    return _temple_out(row, request)


@router.get("/spiritual/metal-rates", response_model=MetalRatesOut)
def metal_rates(
    city_id: str = Query(default="chennai"),
    period: str = Query(default="7d", pattern="^(7d|30d|3m|6m|5y|10y)$"),
    db: Session = Depends(get_db),
):
    try:
        from app.models import MetalRateDaily

        stale_source = (
            db.query(MetalRateDaily)
            .filter(MetalRateDaily.city_id == city_id, MetalRateDaily.source != "retail")
            .first()
            is not None
        )
        if db.query(MetalRateDaily).count() == 0 or not has_today(db) or stale_source:
            sync_retail(db)
        return MetalRatesOut(**get_rates(db, city_id=city_id, period=period))
    except KeyError as exc:
        raise HTTPException(404, detail=str(exc)) from exc
    except RuntimeError as exc:
        raise HTTPException(503, detail=str(exc)) from exc


@router.get("/health")
def health():
    return {"status": "ok"}


@router.get("/indru", response_model=IndruDailyOut)
def indru_today(
    on_date: date | None = Query(default=None, alias="date"),
    db: Session = Depends(get_db),
):
    """Global இன்று content — same for all cities and all Tamil users."""
    target = on_date or date.today()
    row = get_indru_for_date(db, target)
    return IndruDailyOut(**indru_to_dict(row))


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


@router.get("/spiritual/vastu/articles", response_model=list[VastuArticleOut])
def vastu_articles():
    return [VastuArticleOut(**a) for a in get_vastu_articles()]


@router.get("/spiritual/vastu/years", response_model=list[int])
def vastu_years():
    return get_vastu_years()


@router.get("/spiritual/vastu/days", response_model=VastuDaysOut)
def vastu_days(
    city_id: str = Query(default="chennai"),
    year: int = Query(default=2026),
    db: Session = Depends(get_db),
):
    city = db.query(City).filter(City.id == city_id).first()
    if not city:
        raise HTTPException(404, detail="City not found")
    days = [VastuDayOut(**d) for d in get_vastu_days(db, city_id, year)]
    return VastuDaysOut(city_id=city_id, year=year, days=days)


@router.get("/spiritual/pancha-pakshi/articles", response_model=list[PanchaPakshiArticleOut])
def pancha_pakshi_article_list():
    return [PanchaPakshiArticleOut(**a) for a in pancha_pakshi_articles()]


@router.get("/spiritual/pancha-pakshi/articles/{article_id}", response_model=PanchaPakshiArticleDetailOut)
def pancha_pakshi_article_detail(
    article_id: int,
    city_id: str = Query(default="chennai"),
    db: Session = Depends(get_db),
):
    return PanchaPakshiArticleDetailOut(**pancha_pakshi_article(db, city_id, article_id))


@router.get("/spiritual/pancha-pakshi/nakshatras", response_model=list[PanchaPakshiNakshatraOut])
def pancha_pakshi_nakshatra_list():
    return [PanchaPakshiNakshatraOut(**n) for n in list_nakshatras()]


@router.get("/spiritual/pancha-pakshi/paksha-options", response_model=list[PanchaPakshiPakshaOptionOut])
def pancha_pakshi_paksha_options():
    return [PanchaPakshiPakshaOptionOut(**p) for p in list_birth_paksha_options()]


@router.get("/spiritual/pancha-pakshi/years", response_model=list[int])
def pancha_pakshi_supported_years():
    return pancha_pakshi_years()


@router.get("/spiritual/pancha-pakshi/calculate", response_model=PanchaPakshiCalculateOut)
def pancha_pakshi_calculate_endpoint(
    city_id: str = Query(default="chennai"),
    nakshatra_index: int = Query(..., ge=0, le=26),
    birth_paksha_id: str = Query(...),
    on_date: date = Query(..., alias="date"),
    db: Session = Depends(get_db),
):
    """பஞ்ச பட்சி கணக்கீடு — birth bird + day/night activities (kaalavidya sun times)."""
    result = pancha_pakshi_calculate(
        db,
        city_id,
        nakshatra_index=nakshatra_index,
        birth_paksha_id=birth_paksha_id,
        on_date=on_date,
    )
    sections = [
        PanchaPakshiSectionOut(
            period_ta=s["period_ta"],
            slots=[PanchaPakshiSlotOut(**slot) for slot in s["slots"]],
        )
        for s in result["sections"]
    ]
    return PanchaPakshiCalculateOut(**{**result, "sections": sections})


def _city_or_404(db: Session, city_id: str) -> City:
    city = db.query(City).filter(City.id == city_id).first()
    if not city:
        raise HTTPException(404, detail="City not found")
    return city


@router.get("/spiritual/jyotish/nakshatras", response_model=list[JyotishNakshatraOut])
def jyotish_nakshatras():
    return [JyotishNakshatraOut(**n) for n in jyotish_service.list_nakshatras()]


@router.get("/spiritual/jyotish/rashis", response_model=list[JyotishRashiOut])
def jyotish_rashis():
    return [JyotishRashiOut(**r) for r in jyotish_service.list_rashis()]


@router.get("/spiritual/jyotish/nazhigai-convert", response_model=NazhigaiConvertOut)
def nazhigai_convert(
    city_id: str = Query(default="chennai"),
    on_date: date = Query(..., alias="date"),
    hour: int = Query(default=0, ge=0, le=23),
    minute: int = Query(default=0, ge=0, le=59),
    to_nazhigai: bool = Query(default=True),
    nazhigai: int = Query(default=1, ge=1, le=60),
    vinadi: int = Query(default=0, ge=0, le=59),
    db: Session = Depends(get_db),
):
    city = _city_or_404(db, city_id)
    result = jyotish_service.convert_nazhigai(
        city, on_date, hour, minute, to_nazhigai=to_nazhigai, nazhigai=nazhigai, vinadi=vinadi
    )
    return NazhigaiConvertOut(**result)


@router.get("/spiritual/jyotish/chandrashtamam", response_model=ChandrashtamamOut)
def chandrashtamam(
    city_id: str = Query(default="chennai"),
    birth_rashi_index: int = Query(..., ge=0, le=11),
    on_date: date = Query(..., alias="date"),
    db: Session = Depends(get_db),
):
    city = _city_or_404(db, city_id)
    result = jyotish_service.calculate_chandrashtamam(city, birth_rashi_index, on_date)
    periods = [ChandrashtamamPeriodOut(**p) for p in result.pop("periods")]
    return ChandrashtamamOut(**result, periods=periods)


@router.get("/spiritual/jyotish/numerology", response_model=NumerologyOut)
def numerology(
    city_id: str = Query(default="chennai"),
    name: str = Query(..., min_length=1),
    on_date: date = Query(..., alias="date"),
    db: Session = Depends(get_db),
):
    city = _city_or_404(db, city_id)
    return NumerologyOut(**jyotish_service.calculate_numerology(city, name, on_date))


@router.get("/spiritual/jyotish/marriage-porutham", response_model=MarriagePoruthamOut)
def marriage_porutham(
    city_id: str = Query(default="chennai"),
    person1_date: date = Query(...),
    person1_hour: int = Query(default=6, ge=0, le=23),
    person1_minute: int = Query(default=0, ge=0, le=59),
    person1_nakshatra: int | None = Query(default=None, ge=0, le=26),
    person2_date: date = Query(...),
    person2_hour: int = Query(default=6, ge=0, le=23),
    person2_minute: int = Query(default=0, ge=0, le=59),
    person2_nakshatra: int | None = Query(default=None, ge=0, le=26),
    db: Session = Depends(get_db),
):
    city = _city_or_404(db, city_id)
    result = jyotish_service.calculate_marriage_porutham(
        city,
        person1_date,
        time(person1_hour, person1_minute),
        person1_nakshatra,
        person2_date,
        time(person2_hour, person2_minute),
        person2_nakshatra,
    )
    factors = [PoruthamFactorOut(**f) for f in result.pop("factors")]
    return MarriagePoruthamOut(**result, factors=factors)


@router.get("/spiritual/jyotish/tarabalam", response_model=TarabalamOut)
def tarabalam(
    city_id: str = Query(default="chennai"),
    birth_nakshatra_index: int = Query(..., ge=0, le=26),
    on_date: date = Query(..., alias="date"),
    db: Session = Depends(get_db),
):
    city = _city_or_404(db, city_id)
    result = jyotish_service.calculate_tarabalam(city, birth_nakshatra_index, on_date)
    favorable = [TarabalamPeriodOut(**p) for p in result.pop("favorable_periods")]
    unfavorable = [TarabalamPeriodOut(**p) for p in result.pop("unfavorable_periods")]
    return TarabalamOut(**result, favorable_periods=favorable, unfavorable_periods=unfavorable)


@router.get("/spiritual/palangal/categories", response_model=list[PalangalCategoryOut])
def palangal_category_list():
    return [PalangalCategoryOut(**c) for c in palangal_categories()]


@router.get("/spiritual/palangal/categories/{category_id}/articles", response_model=list[PalangalArticleOut])
def palangal_article_list(category_id: str):
    return [PalangalArticleOut(**a) for a in palangal_articles(category_id)]


@router.get("/spiritual/palangal/categories/{category_id}/articles/{article_id}", response_model=PalangalArticleDetailOut)
def palangal_article_detail(category_id: str, article_id: int):
    article = palangal_article(category_id, article_id)
    if not article:
        raise HTTPException(404, detail="Article not found")
    return PalangalArticleDetailOut(**article)


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
