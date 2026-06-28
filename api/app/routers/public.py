import json
from datetime import date, time, timedelta

from fastapi import APIRouter, Depends, HTTPException, Query
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
