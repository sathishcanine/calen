"""Pancha Pakshi API service — kaalavidya times + traditional activity tables."""

from __future__ import annotations

from datetime import date

from fastapi import HTTPException
from sqlalchemy.orm import Session

from app.data.pancha_pakshi_content import PANCHA_PAKSHI_ARTICLES, get_article_content
from app.data.pancha_pakshi_engine import schedule_for_day, week_grid
from app.data.pancha_pakshi_tables import (
    BIRDS_TA,
    BIRTH_PAKSHA_OPTIONS,
    NAKSHATRA_NAMES_TA,
    SUPPORTED_YEARS,
    birth_bird_index,
)
from app.models import City


def list_articles() -> list[dict]:
    return [
        {"id": a["id"], "title_ta": a["title_ta"], "kind": a["kind"]}
        for a in PANCHA_PAKSHI_ARTICLES
    ]


def list_nakshatras() -> list[dict]:
    return [{"index": i, "name_ta": name} for i, name in enumerate(NAKSHATRA_NAMES_TA)]


def list_birth_paksha_options() -> list[dict]:
    return list(BIRTH_PAKSHA_OPTIONS)


def supported_years() -> list[int]:
    return list(SUPPORTED_YEARS)


def get_article(db: Session, city_id: str, article_id: int) -> dict:
    article = next((a for a in PANCHA_PAKSHI_ARTICLES if a["id"] == article_id), None)
    if not article:
        raise HTTPException(404, detail="Article not found")

    payload: dict = {
        "id": article["id"],
        "title_ta": article["title_ta"],
        "kind": article["kind"],
        "content": get_article_content(article),
    }

    if article["kind"] == "bird_grid":
        bird = article["bird"]
        paksha = article["paksha"]
        paksha_ta = "வளர்பிறை" if paksha == 0 else "தேய்பிறை"
        payload["content"]["subtitle_ta"] = f"{paksha_ta} - {BIRDS_TA[bird]}"
        payload["content"]["day_rows"] = week_grid(bird, paksha, is_night=False)
        payload["content"]["night_rows"] = week_grid(bird, paksha, is_night=True)

    return payload


def calculate(
    db: Session,
    city_id: str,
    *,
    nakshatra_index: int,
    birth_paksha_id: str,
    on_date: date,
) -> dict:
    if on_date.year not in SUPPORTED_YEARS:
        raise HTTPException(
            400,
            detail=f"பட்சி பார்க்க {SUPPORTED_YEARS[0]}–{SUPPORTED_YEARS[-1]} ஆண்டுகளுக்கு மட்டுமே சாத்தியம்",
        )

    city = db.query(City).filter(City.id == city_id).first()
    if not city:
        raise HTTPException(404, detail="City not found")

    if not 0 <= nakshatra_index < 27:
        raise HTTPException(400, detail="Invalid nakshatra_index")

    valid_paksha = {p["id"] for p in BIRTH_PAKSHA_OPTIONS}
    if birth_paksha_id not in valid_paksha:
        raise HTTPException(400, detail="Invalid birth_paksha_id")

    bird_index = birth_bird_index(nakshatra_index, birth_paksha_id)
    birth_paksha_ta = next(p["label_ta"] for p in BIRTH_PAKSHA_OPTIONS if p["id"] == birth_paksha_id)
    schedule = schedule_for_day(city, on_date, bird_index)

    return {
        "nakshatra_ta": NAKSHATRA_NAMES_TA[nakshatra_index],
        "birth_paksha_ta": birth_paksha_ta,
        "bird_ta": BIRDS_TA[bird_index],
        "gregorian_date": on_date,
        "weekday_ta": schedule["weekday_ta"],
        "observation_paksha_ta": schedule["observation_paksha_ta"],
        "sections": schedule["sections"],
    }
