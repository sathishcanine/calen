"""ஜோதிட கணக்கீடு — kaalavidya-backed calculators."""

from __future__ import annotations

import re
from datetime import date, datetime, time
from zoneinfo import ZoneInfo

from kaalavidya.constants import NAKSHATRA, RASHI, name
from kaalavidya.panchanga import Panchanga

from app.data.porutham_tables import (
    NAKSHATRA_NAMES_TA,
    RASHI_NAMES_TA,
    compute_porutham,
)
from app.ingestion.kaalavidya_provider import _timezone_for_city
from app.models import City

CHALDEAN_MAP = {
    "A": 1, "B": 2, "C": 3, "D": 4, "E": 5, "F": 8, "G": 3, "H": 5, "I": 1,
    "J": 1, "K": 2, "L": 3, "M": 4, "N": 5, "O": 7, "P": 8, "Q": 1, "R": 2,
    "S": 3, "T": 4, "U": 6, "V": 6, "W": 6, "X": 5, "Y": 1, "Z": 7,
}

NUMEROLOGY_MEANINGS_TA = {
    1: "தலைமைத்துவம், சுயமாக முன்னேற்றம், புதிய தொடக்கம்",
    2: "இணக்கம், கூட்டுறவு, உணர்வுபூர்வமான பிணைப்பு",
    3: "படைப்பாற்றல், தொடர்பு திறன், சமூக வளர்ச்சி",
    4: "உழைப்பு, நிலைத்தன்மை, கடின உழைப்பின் பலன்",
    5: "சுதந்திரம், பயணம், மாற்றம் மற்றும் சாதனை",
    6: "குடும்பம், பொறுப்பு, அன்பு மற்றும் சேவை",
    7: "ஆன்மீகம், ஆராய்ச்சி, உள்ளார்ந்த ஞானம்",
    8: "பொருளாதாரம், அதிகாரம், வணிக வெற்றி",
    9: "மனிதநேயம், தாராளம், உலகளாவிய பார்வை",
}


def _panchanga(city: City, on_date: date, hour: int = 6, minute: int = 0) -> Panchanga:
    tz = _timezone_for_city(city)
    return Panchanga(
        on_date.year,
        on_date.month,
        on_date.day,
        city.lat,
        city.lon,
        timezone=tz,
        city=city.name_en,
        lang="ta",
    )


def _birth_nakshatra_index(city: City, on_date: date, birth_time: time) -> int:
    tz = ZoneInfo(_timezone_for_city(city))
    p = Panchanga(
        on_date.year,
        on_date.month,
        on_date.day,
        city.lat,
        city.lon,
        timezone=str(tz),
        city=city.name_en,
        lang="ta",
    )
    result = p.compute()
    # Use nakshatra active at birth time
    for seg in result.nakshatra:
        start = seg.starts_at if hasattr(seg, "starts_at") else None
        if start is None:
            continue
        end = seg.ends_at
        bt = datetime.combine(on_date, birth_time, tzinfo=tz)
        if start <= bt < end:
            return seg.index
    return result.nakshatra[0].index


def _birth_moon_rashi_index(city: City, on_date: date, birth_time: time) -> int:
    tz = ZoneInfo(_timezone_for_city(city))
    p = Panchanga(
        on_date.year,
        on_date.month,
        on_date.day,
        city.lat,
        city.lon,
        timezone=str(tz),
        city=city.name_en,
        lang="ta",
    )
    result = p.compute()
    for seg in result.chandrabalam:
        start = datetime.fromisoformat(seg["starts_at"])
        end = datetime.fromisoformat(seg["ends_at"])
        bt = datetime.combine(on_date, birth_time, tzinfo=tz)
        if start <= bt < end:
            return seg["transit_index"]
    return result.moon_rashi.index if hasattr(result.moon_rashi, "index") else 0


def _format_time(dt: datetime) -> str:
    return dt.strftime("%H:%M")


def _parse_duration_seconds(text: str) -> int:
    """Parse kaalavidya dinamana like '12 Hours 50 Mins 52 Secs'."""
    hours = mins = secs = 0
    if m := re.search(r"(\d+)\s*Hours?", text):
        hours = int(m.group(1))
    if m := re.search(r"(\d+)\s*Mins?", text):
        mins = int(m.group(1))
    if m := re.search(r"(\d+)\s*Secs?", text):
        secs = int(m.group(1))
    return hours * 3600 + mins * 60 + secs


def convert_nazhigai(
    city: City,
    on_date: date,
    hour: int,
    minute: int,
    to_nazhigai: bool = True,
    nazhigai: int = 0,
    vinadi: int = 0,
) -> dict:
    """Convert clock time ↔ nazhigai (ghati) using kaalavidya sunrise/sunset."""
    p = _panchanga(city, on_date)
    result = p.compute()
    sunrise = result.sun.sunrise
    sunset = result.sun.sunset
    tz = sunrise.tzinfo
    day_secs = _parse_duration_seconds(result.dinamana)
    night_secs = _parse_duration_seconds(result.ratrimana)

    if to_nazhigai:
        clock = datetime.combine(on_date, time(hour, minute), tzinfo=tz)
        if clock < sunrise:
            # Previous night segment
            prev_day = on_date.toordinal() - 1
            prev_date = date.fromordinal(prev_day)
            prev = _panchanga(city, prev_date).compute()
            prev_sunset = prev.sun.sunset
            elapsed = (clock - prev_sunset).total_seconds()
            segment = "இரவு"
            total_ghatis = 60
            duration = _parse_duration_seconds(prev.ratrimana)
            offset = elapsed
        elif clock < sunset:
            elapsed = (clock - sunrise).total_seconds()
            segment = "பகல்"
            total_ghatis = 60
            duration = day_secs
            offset = elapsed
        else:
            elapsed = (clock - sunset).total_seconds()
            segment = "இரவு"
            total_ghatis = 60
            duration = night_secs
            offset = elapsed

        ghati_float = (offset / duration) * total_ghatis if duration else 0
        g = int(ghati_float)
        v = int((ghati_float - g) * 60)
        vi = int(((ghati_float - g) * 60 - v) * 60)
        return {
            "mode": "time_to_nazhigai",
            "gregorian_date": on_date,
            "input_time": f"{hour:02d}:{minute:02d}",
            "segment_ta": segment,
            "sunrise": _format_time(sunrise),
            "sunset": _format_time(sunset),
            "day_duration_ta": result.dinamana,
            "night_duration_ta": result.ratrimana,
            "nazhigai": g + 1,
            "vinadi": v,
            "vighadiya": vi,
            "display_ta": f"{g + 1} நாழிகை {v} விநாடி {vi} விகலை",
        }

    # nazhigai → clock time
    ghati_float = (nazhigai - 1) + vinadi / 60.0
    if nazhigai <= 30 or nazhigai > 60:
        segment = "பகல்" if nazhigai <= 30 else "இரவு"
        if nazhigai <= 30:
            base = sunrise
            duration = day_secs
            g = ghati_float
        else:
            base = sunset
            duration = night_secs
            g = ghati_float - 30 if nazhigai > 30 else ghati_float
    else:
        segment = "பகல்"
        base = sunrise
        duration = day_secs
        g = ghati_float

    if nazhigai > 30:
        base = sunset
        duration = night_secs
        segment = "இரவு"
        g = nazhigai - 30 - 1 + vinadi / 60.0
    elif nazhigai > 0:
        base = sunrise
        duration = day_secs
        segment = "பகல்"
        g = nazhigai - 1 + vinadi / 60.0

    offset_secs = (g / 60.0) * duration
    out_time = base.timestamp() + offset_secs
    out_dt = datetime.fromtimestamp(out_time, tz=tz)
    return {
        "mode": "nazhigai_to_time",
        "gregorian_date": on_date,
        "input_nazhigai": nazhigai,
        "input_vinadi": vinadi,
        "segment_ta": segment,
        "sunrise": _format_time(sunrise),
        "sunset": _format_time(sunset),
        "day_duration_ta": result.dinamana,
        "night_duration_ta": result.ratrimana,
        "equivalent_time": _format_time(out_dt),
        "display_ta": f"{_format_time(out_dt)} ({segment})",
    }


def calculate_chandrashtamam(city: City, birth_rashi_index: int, on_date: date) -> dict:
    """சந்திராஷ்டமம் — Moon in 8th rashi from birth moon (kaalavidya chandrabalam)."""
    chandra_rashi = (birth_rashi_index + 7) % 12
    p = _panchanga(city, on_date)
    result = p.compute()
    periods = []
    is_active = False
    now = datetime.now(ZoneInfo(_timezone_for_city(city)))

    for seg in result.chandrabalam:
        transit_idx = seg["transit_index"]
        start = datetime.fromisoformat(seg["starts_at"])
        end = datetime.fromisoformat(seg["ends_at"])
        active = transit_idx == chandra_rashi
        if active and start <= now < end:
            is_active = True
        periods.append({
            "rashi_ta": seg["transit_rashi"],
            "time_range": f"{start.strftime('%H:%M')} - {end.strftime('%H:%M')}",
            "is_chandrashtamam": active,
        })

    return {
        "gregorian_date": on_date,
        "birth_rashi_ta": RASHI_NAMES_TA[birth_rashi_index],
        "chandrashtamam_rashi_ta": RASHI_NAMES_TA[chandra_rashi],
        "is_active_now": is_active,
        "periods": periods,
        "note_ta": (
            f"பிறந்த சந்திர ராசி {RASHI_NAMES_TA[birth_rashi_index]}க்கு "
            f"8-ம் இடத்தில் சந்திரன் ({RASHI_NAMES_TA[chandra_rashi]}) வரும் போது சந்திராஷ்டமம்."
        ),
    }


def calculate_numerology(city: City, full_name: str, dob: date) -> dict:
    """Chaldean numerology + kaalavidya birth nakshatra/rashi."""
    clean = re.sub(r"[^A-Za-z]", "", full_name.upper())
    if not clean:
        raise ValueError("பெயரில் எழுத்துகள் இல்லை")

    name_total = sum(CHALDEAN_MAP.get(c, 0) for c in clean)
    while name_total > 9 and name_total not in (11, 22):
        name_total = sum(int(d) for d in str(name_total))

    dob_str = dob.strftime("%d%m%Y")
    destiny = sum(int(d) for d in dob_str)
    while destiny > 9 and destiny not in (11, 22):
        destiny = sum(int(d) for d in str(destiny))

    p = _panchanga(city, dob).compute()
    nak_idx = p.nakshatra[0].index
    nak_name = name(NAKSHATRA, nak_idx, "ta")
    rashi_idx = p.moon_rashi.index if hasattr(p.moon_rashi, "index") else 0
    rashi_name = name(RASHI, rashi_idx, "ta")

    meaning = NUMEROLOGY_MEANINGS_TA.get(
        name_total if name_total <= 9 else name_total % 9 or 9,
        NUMEROLOGY_MEANINGS_TA[1],
    )

    return {
        "full_name": full_name.strip(),
        "gregorian_date": dob,
        "name_number": name_total,
        "destiny_number": destiny,
        "birth_nakshatra_ta": nak_name,
        "birth_rashi_ta": rashi_name,
        "interpretation_ta": meaning,
        "summary_ta": (
            f"பெயர் எண்: {name_total}, விதி எண்: {destiny}. "
            f"பிறப்பு நட்சத்திரம்: {nak_name}, ராசி: {rashi_name}. {meaning}"
        ),
    }


def calculate_marriage_porutham(
    city: City,
    person1_dob: date,
    person1_time: time,
    person1_nakshatra_index: int | None,
    person2_dob: date,
    person2_time: time,
    person2_nakshatra_index: int | None,
) -> dict:
    boy_idx = person1_nakshatra_index
    girl_idx = person2_nakshatra_index
    if boy_idx is None:
        boy_idx = _birth_nakshatra_index(city, person1_dob, person1_time)
    if girl_idx is None:
        girl_idx = _birth_nakshatra_index(city, person2_dob, person2_time)
    return compute_porutham(boy_idx, girl_idx)


def calculate_tarabalam(city: City, birth_nakshatra_index: int, on_date: date) -> dict:
    """தாரா பலன் — favorable moon transit windows for birth star."""
    p = _panchanga(city, on_date)
    result = p.compute()
    favorable_periods = []
    unfavorable_periods = []

    for seg in result.tarabalam:
        transit = seg["transit_nakshatra"]
        start = datetime.fromisoformat(seg["starts_at"]).strftime("%H:%M")
        end = datetime.fromisoformat(seg["ends_at"]).strftime("%H:%M")
        fav_indices = {f["index"] for f in seg.get("favorable", [])}
        if birth_nakshatra_index in fav_indices:
            tara = next(
                (f["tara_name"] for f in seg["favorable"] if f["index"] == birth_nakshatra_index),
                "",
            )
            favorable_periods.append({
                "transit_nakshatra_ta": transit,
                "time_range": f"{start} - {end}",
                "tara_name_ta": tara,
            })
        else:
            unfavorable_periods.append({
                "transit_nakshatra_ta": transit,
                "time_range": f"{start} - {end}",
            })

    return {
        "gregorian_date": on_date,
        "birth_nakshatra_ta": NAKSHATRA_NAMES_TA[birth_nakshatra_index],
        "favorable_periods": favorable_periods,
        "unfavorable_periods": unfavorable_periods,
        "note_ta": "இன்றைய சந்திர நட்சத்திர பயணத்தில் உங்கள் நட்சத்திரத்திற்கு ஏற்ற தாரா காலங்கள்.",
    }


def list_nakshatras() -> list[dict]:
    return [{"index": i, "name_ta": NAKSHATRA_NAMES_TA[i]} for i in range(27)]


def list_rashis() -> list[dict]:
    return [{"index": i, "name_ta": RASHI_NAMES_TA[i]} for i in range(12)]
