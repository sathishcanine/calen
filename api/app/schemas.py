from datetime import date, datetime
from typing import Any

from pydantic import BaseModel, Field


class CityOut(BaseModel):
    id: str
    name_en: str
    name_ta: str
    lat: float
    lon: float
    tz_offset: float
    country: str
    is_default: bool

    model_config = {"from_attributes": True}


class TimeSlot(BaseModel):
    period: str
    time: str


class PanchangamItem(BaseModel):
    label: str
    value: str


class InauspiciousSlot(BaseModel):
    name: str
    time: str


class HoroscopeItem(BaseModel):
    sign: str
    prediction: str


class DailyCalendarOut(BaseModel):
    city_id: str
    gregorian_date: date
    month_label_ta: str
    gregorian_display: str
    subtitle_line1_ta: str
    subtitle_line2_ta: str
    banner_line_ta: str
    events_ta: str
    nalla_neram: list[TimeSlot]
    gowri_nalla_neram: list[TimeSlot]
    panchangam: list[PanchangamItem]
    inauspicious: list[InauspiciousSlot]
    shoolam_ta: str
    pariharam_ta: str
    lagnam_ta: str
    rasi_chart: list[str | None]
    rasi_center_ta: str
    horoscope: list[HoroscopeItem]
    quote_ta: str
    birthdays_ta: str
    note_ta: str
    data_version: int
    updated_at: datetime | None = None


class DailyCalendarIn(BaseModel):
    city_id: str
    gregorian_date: date
    month_label_ta: str = ""
    gregorian_display: str = ""
    subtitle_line1_ta: str = ""
    subtitle_line2_ta: str = ""
    banner_line_ta: str = ""
    events_ta: str = ""
    nalla_neram: list[TimeSlot] = Field(default_factory=list)
    gowri_nalla_neram: list[TimeSlot] = Field(default_factory=list)
    panchangam: list[PanchangamItem] = Field(default_factory=list)
    inauspicious: list[InauspiciousSlot] = Field(default_factory=list)
    shoolam_ta: str = ""
    pariharam_ta: str = ""
    lagnam_ta: str = ""
    rasi_chart: list[str | None] = Field(default_factory=list)
    rasi_center_ta: str = ""
    horoscope: list[HoroscopeItem] = Field(default_factory=list)
    quote_ta: str = ""
    birthdays_ta: str = ""
    note_ta: str = ""


class DailyBundleOut(BaseModel):
    city_id: str
    from_date: date
    days: int
    data_version: int
    items: list[DailyCalendarOut]


class MonthDayCell(BaseModel):
    gregorian_day: int | None
    tamil_day: int | None = None
    is_sunday: bool = False
    is_today: bool = False
    is_highlight: bool = False
    highlight_color: str | None = None  # green, red
    icons: list[str] = Field(default_factory=list)
    moon_phase: str | None = None  # amavasai, pournami
    is_other_month: bool = False


class MonthListItem(BaseModel):
    icon: str | None = None
    title_ta: str
    dates_ta: str


class MonthCalendarOut(BaseModel):
    city_id: str
    year: int
    month: int
    month_label_ta: str
    tamil_months_ta: str
    days: list[MonthDayCell]
    fasting_days: list[MonthListItem]
    wedding_days: list[str]
    other_days: list[dict[str, Any]]
    hindu_festivals: list[dict[str, str]]
    muslim_festivals: list[dict[str, str]]
    christian_festivals: list[dict[str, str]]
    government_holidays: list[dict[str, str]]


class MonthCalendarIn(BaseModel):
    city_id: str
    year: int
    month: int
    month_label_ta: str = ""
    tamil_months_ta: str = ""
    days: list[MonthDayCell] = Field(default_factory=list)
    fasting_days: list[MonthListItem] = Field(default_factory=list)
    wedding_days: list[str] = Field(default_factory=list)
    other_days: list[dict[str, Any]] = Field(default_factory=list)
    hindu_festivals: list[dict[str, str]] = Field(default_factory=list)
    muslim_festivals: list[dict[str, str]] = Field(default_factory=list)
    christian_festivals: list[dict[str, str]] = Field(default_factory=list)
    government_holidays: list[dict[str, str]] = Field(default_factory=list)


class HomeSummaryOut(BaseModel):
    banner_line_ta: str
    gregorian_display: str
    gregorian_date: date


class InauspiciousWeekDayOut(BaseModel):
    weekday_ta: str
    gregorian_date: date
    rahu_kalam: str
    gulikai_kalam: str
    yamagandam: str
    shoolam: str
    pariharam: str


class InauspiciousWeekOut(BaseModel):
    city_id: str
    week_start: date
    days: list[InauspiciousWeekDayOut]


class GowriSlotOut(BaseModel):
    time: str
    name: str
    auspicious: bool


class GowriSectionOut(BaseModel):
    period: str
    slots: list[GowriSlotOut]


class GowriWeekDayOut(BaseModel):
    weekday_ta: str
    gregorian_date: date
    sections: list[GowriSectionOut]


class GowriWeekOut(BaseModel):
    city_id: str
    week_start: date
    days: list[GowriWeekDayOut]


class HoraSlotOut(BaseModel):
    time: str
    planet: str
    auspicious: bool


class HoraSectionOut(BaseModel):
    period: str
    slots: list[HoraSlotOut]


class HoraWeekDayOut(BaseModel):
    weekday_ta: str
    gregorian_date: date
    sections: list[HoraSectionOut]


class HoraWeekOut(BaseModel):
    city_id: str
    week_start: date
    days: list[HoraWeekDayOut]
