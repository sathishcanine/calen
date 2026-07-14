import json
from datetime import date, datetime

from sqlalchemy import Date, DateTime, ForeignKey, Integer, String, Text, UniqueConstraint
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.database import Base


def _city_display_name(name_en: str, name_ta: str) -> str:
    from app.data.world_cities import format_display_name

    return format_display_name(name_en, name_ta)


class City(Base):
    __tablename__ = "cities"

    id: Mapped[str] = mapped_column(String(64), primary_key=True)
    name_en: Mapped[str] = mapped_column(String(128))
    name_ta: Mapped[str] = mapped_column(String(128))
    lat: Mapped[float] = mapped_column()
    lon: Mapped[float] = mapped_column()
    tz_offset: Mapped[float] = mapped_column(default=5.5)
    country: Mapped[str] = mapped_column(String(8), default="IN")
    timezone: Mapped[str | None] = mapped_column(String(64), nullable=True)
    is_default: Mapped[bool] = mapped_column(default=False)

    @property
    def display_name(self) -> str:
        return _city_display_name(self.name_en, self.name_ta)


class DailyCalendar(Base):
    """One row per city per Gregorian date — daily view (SS2–4)."""

    __tablename__ = "daily_calendars"
    __table_args__ = (UniqueConstraint("city_id", "gregorian_date", name="uq_city_date"),)

    id: Mapped[int] = mapped_column(Integer, primary_key=True, autoincrement=True)
    city_id: Mapped[str] = mapped_column(String(64), ForeignKey("cities.id"))
    gregorian_date: Mapped[date] = mapped_column(Date, index=True)

    # Header
    month_label_ta: Mapped[str] = mapped_column(String(64))  # ஜூன் - புதன்
    gregorian_display: Mapped[str] = mapped_column(String(16))  # 03-06-2026
    subtitle_line1_ta: Mapped[str] = mapped_column(Text, default="")
    subtitle_line2_ta: Mapped[str] = mapped_column(Text, default="")
    banner_line_ta: Mapped[str] = mapped_column(String(128), default="")  # வைகாசி - 20, புதன்

    # Events row under header
    events_ta: Mapped[str] = mapped_column(Text, default="")

    # Nalla neram / Gowri — JSON: [{"period":"காலை","time":"10.30 - 11.30"}, ...]
    nalla_neram_json: Mapped[str] = mapped_column(Text, default="[]")
    gowri_nalla_neram_json: Mapped[str] = mapped_column(Text, default="[]")
    # Full Gowri Panchangam — JSON {sections: [{period, slots: [{time, name, auspicious}]}]}
    gowri_panchangam_json: Mapped[str] = mapped_column(Text, default="[]")
    # Planetary hora — JSON {sections: [{period, slots: [{time, planet, auspicious}]}]}
    hora_json: Mapped[str] = mapped_column(Text, default="[]")

    # Panchangam grid — JSON list of {label, value}
    panchangam_json: Mapped[str] = mapped_column(Text, default="[]")

    # Rahu / Gulika / Yamagandam — JSON
    inauspicious_json: Mapped[str] = mapped_column(Text, default="[]")

    shoolam_ta: Mapped[str] = mapped_column(String(128), default="")
    pariharam_ta: Mapped[str] = mapped_column(String(128), default="")
    lagnam_ta: Mapped[str] = mapped_column(Text, default="")

    # Rasi chart 4x4 — JSON 16 cells (null = empty)
    rasi_chart_json: Mapped[str] = mapped_column(Text, default="[]")
    rasi_center_ta: Mapped[str] = mapped_column(Text, default="")

    # Horoscope — JSON [{sign, prediction}, ...]
    horoscope_json: Mapped[str] = mapped_column(Text, default="[]")

    quote_ta: Mapped[str] = mapped_column(Text, default="")
    birthdays_ta: Mapped[str] = mapped_column(Text, default="")

    note_ta: Mapped[str] = mapped_column(Text, default="")
    data_version: Mapped[int] = mapped_column(Integer, default=1)
    updated_at: Mapped[datetime] = mapped_column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)

    city: Mapped["City"] = relationship("City")

    def get_nalla_neram(self) -> list:
        return json.loads(self.nalla_neram_json or "[]")

    def set_nalla_neram(self, value: list) -> None:
        self.nalla_neram_json = json.dumps(value, ensure_ascii=False)


class MonthCalendar(Base):
    """Month metadata + fasting summary (SS5–7)."""

    __tablename__ = "month_calendars"
    __table_args__ = (UniqueConstraint("city_id", "year", "month", name="uq_city_month"),)

    id: Mapped[int] = mapped_column(Integer, primary_key=True, autoincrement=True)
    city_id: Mapped[str] = mapped_column(String(64), ForeignKey("cities.id"))
    year: Mapped[int] = mapped_column(Integer)
    month: Mapped[int] = mapped_column(Integer)

    month_label_ta: Mapped[str] = mapped_column(String(64))  # ஜூன் - 2026
    tamil_months_ta: Mapped[str] = mapped_column(String(128))  # வைகாசி - ஆனி

    # Each day in grid: JSON array of day objects
    days_json: Mapped[str] = mapped_column(Text, default="[]")

    # Lists below grid
    fasting_days_json: Mapped[str] = mapped_column(Text, default="[]")
    wedding_days_json: Mapped[str] = mapped_column(Text, default="[]")
    other_days_json: Mapped[str] = mapped_column(Text, default="[]")
    hindu_festivals_json: Mapped[str] = mapped_column(Text, default="[]")
    muslim_festivals_json: Mapped[str] = mapped_column(Text, default="[]")
    christian_festivals_json: Mapped[str] = mapped_column(Text, default="[]")
    government_holidays_json: Mapped[str] = mapped_column(Text, default="[]")

    updated_at: Mapped[datetime] = mapped_column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)


class MetalRateDaily(Base):
    """Daily gold/silver rates per city (synced from free market APIs)."""

    __tablename__ = "metal_rate_daily"
    __table_args__ = (UniqueConstraint("city_id", "rate_date", name="uq_metal_city_date"),)

    id: Mapped[int] = mapped_column(Integer, primary_key=True, autoincrement=True)
    city_id: Mapped[str] = mapped_column(String(64), ForeignKey("cities.id"), index=True)
    rate_date: Mapped[date] = mapped_column(Date, index=True)
    gold_22k: Mapped[float] = mapped_column()
    gold_24k: Mapped[float] = mapped_column()
    silver_gram: Mapped[float] = mapped_column()
    silver_kg: Mapped[float] = mapped_column()
    source: Mapped[str] = mapped_column(String(32), default="api")
    fetched_at: Mapped[datetime] = mapped_column(DateTime, default=datetime.utcnow)


class MetalRateMonthly(Base):
    """Month-end gold/silver snapshot for long-range charts (5y / 10y)."""

    __tablename__ = "metal_rate_monthly"
    __table_args__ = (UniqueConstraint("city_id", "rate_month", name="uq_metal_city_month"),)

    id: Mapped[int] = mapped_column(Integer, primary_key=True, autoincrement=True)
    city_id: Mapped[str] = mapped_column(String(64), ForeignKey("cities.id"), index=True)
    rate_month: Mapped[date] = mapped_column(Date, index=True)
    gold_22k: Mapped[float] = mapped_column()
    gold_24k: Mapped[float] = mapped_column()
    silver_gram: Mapped[float] = mapped_column()
    silver_kg: Mapped[float] = mapped_column()
    source: Mapped[str] = mapped_column(String(32), default="api")
    fetched_at: Mapped[datetime] = mapped_column(DateTime, default=datetime.utcnow)


class BookCategory(Base):
    """PDF library category (admin-managed)."""

    __tablename__ = "book_categories"

    id: Mapped[str] = mapped_column(String(64), primary_key=True)
    name: Mapped[str] = mapped_column(String(128))
    sort_order: Mapped[int] = mapped_column(Integer, default=0)
    created_at: Mapped[datetime] = mapped_column(DateTime, default=datetime.utcnow)

    books: Mapped[list["LibraryBook"]] = relationship(
        "LibraryBook", back_populates="category", cascade="all, delete-orphan"
    )


class LibraryBook(Base):
    """PDF book entry under a category."""

    __tablename__ = "library_books"

    id: Mapped[str] = mapped_column(String(64), primary_key=True)
    category_id: Mapped[str] = mapped_column(String(64), ForeignKey("book_categories.id"), index=True)
    title: Mapped[str] = mapped_column(String(256))
    filename: Mapped[str] = mapped_column(String(256))
    preview_filename: Mapped[str | None] = mapped_column(String(256), nullable=True)
    author: Mapped[str] = mapped_column(String(128), default="")
    file_size: Mapped[int] = mapped_column(Integer, default=0)
    sort_order: Mapped[int] = mapped_column(Integer, default=0)
    created_at: Mapped[datetime] = mapped_column(DateTime, default=datetime.utcnow)

    category: Mapped["BookCategory"] = relationship("BookCategory", back_populates="books")


class Post(Base):
    """Admin-published post with image and text content."""

    __tablename__ = "posts"

    id: Mapped[str] = mapped_column(String(64), primary_key=True)
    title: Mapped[str] = mapped_column(String(256))
    content: Mapped[str] = mapped_column(Text, default="")
    image_filename: Mapped[str] = mapped_column(String(256))
    push_sent: Mapped[bool] = mapped_column(default=False)
    created_at: Mapped[datetime] = mapped_column(DateTime, default=datetime.utcnow)


class IndruPush(Base):
    """Admin-sent இன்று tab push notification (optional image)."""

    __tablename__ = "indru_pushes"

    id: Mapped[str] = mapped_column(String(64), primary_key=True)
    title: Mapped[str] = mapped_column(String(256))
    body: Mapped[str] = mapped_column(Text, default="")
    image_filename: Mapped[str | None] = mapped_column(String(256), nullable=True)
    push_sent: Mapped[bool] = mapped_column(default=False)
    created_at: Mapped[datetime] = mapped_column(DateTime, default=datetime.utcnow)


class IndruDaily(Base):
    """Global இன்று content — one row per Gregorian date, shared by all users (no city)."""

    __tablename__ = "indru_daily"

    gregorian_date: Mapped[date] = mapped_column(Date, primary_key=True)
    birthday_ta: Mapped[str] = mapped_column(Text, default="")
    birthday_detail_ta: Mapped[str] = mapped_column(Text, default="")
    historic_event_ta: Mapped[str] = mapped_column(Text, default="")
    historic_event_detail_ta: Mapped[str] = mapped_column(Text, default="")
    fact_ta: Mapped[str] = mapped_column(Text, default="")
    quote_ta: Mapped[str] = mapped_column(Text, default="")
    quote_author_ta: Mapped[str] = mapped_column(Text, default="")
    kural_number: Mapped[int] = mapped_column(Integer, default=1)
    kural_ta: Mapped[str] = mapped_column(Text, default="")
    kural_meaning_ta: Mapped[str] = mapped_column(Text, default="")
    locked: Mapped[bool] = mapped_column(default=False)
    source: Mapped[str] = mapped_column(String(16), default="cron")
    updated_at: Mapped[datetime] = mapped_column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)


class TempleDailyPush(Base):
    """Tracks one temple push per calendar day (IST)."""

    __tablename__ = "temple_daily_pushes"

    push_date: Mapped[date] = mapped_column(Date, primary_key=True)
    temple_slug: Mapped[str] = mapped_column(String(96))
    sent_at: Mapped[datetime] = mapped_column(DateTime, default=datetime.utcnow)


class DailyMorningPush(Base):
    """Tracks one morning home-screen push per calendar day (IST)."""

    __tablename__ = "daily_morning_pushes"

    push_date: Mapped[date] = mapped_column(Date, primary_key=True)
    title: Mapped[str] = mapped_column(String(256))
    sent_at: Mapped[datetime] = mapped_column(DateTime, default=datetime.utcnow)


class Temple(Base):
    """Famous temple directory content for spiritual discovery screens."""

    __tablename__ = "temples"

    id: Mapped[int] = mapped_column(Integer, primary_key=True, autoincrement=True)
    slug: Mapped[str] = mapped_column(String(96), unique=True, index=True)
    name_ta: Mapped[str] = mapped_column(String(256))
    name_en: Mapped[str] = mapped_column(String(256))
    location_ta: Mapped[str] = mapped_column(String(256), default="")
    deity_ta: Mapped[str] = mapped_column(String(256), default="")
    description_ta: Mapped[str] = mapped_column(Text, default="")
    image_url: Mapped[str] = mapped_column(Text, default="")
    source_label: Mapped[str] = mapped_column(String(64), default="Wikipedia")
    source_url: Mapped[str] = mapped_column(Text, default="")
    sort_order: Mapped[int] = mapped_column(Integer, default=0)
    is_featured: Mapped[bool] = mapped_column(default=False)
    updated_at: Mapped[datetime] = mapped_column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)
