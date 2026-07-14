"""Daily morning FCM content (random Tamil titles) and send idempotency."""

from __future__ import annotations

import random
from datetime import date, datetime, timezone

from sqlalchemy.orm import Session

from app.models import DailyMorningPush

DAILY_MORNING_TITLES_TA = (
    "🚀 இன்றைய நாள் எப்படி அமையும்?",
    "🔥 இன்று உங்களுக்கு அதிர்ஷ்ட நாள் தானா?",
    "⭐ இன்று உங்களுக்கான சிறப்பு பலன் காத்திருக்கிறது.",
    "💫 உங்கள் நாளை மாற்றும் ராசிபலன்!",
    "🙏 இன்று உங்கள் ராசி என்ன சொல்கிறது?",
    "🌞 இன்றைய நல்ல நேரம் & ராசிபலன் பார்க்கலாம்!",
    "💰 இன்று பணவரவு உண்டா? தெரிந்துகொள்ளுங்கள்!",
    "🔮 இன்றைய ராசிபலன் வந்துவிட்டது!",
    "❤️ காதல், வேலை, அதிர்ஷ்டம்... இன்று எப்படி?",
    "📿 இறைவன் அருளுடன் இன்றைய ராசிபலன்.",
    "💎 இன்று வெற்றி யாரை தேடி வருகிறது?",
    "🌞 காலை தொடங்கும் முன் ராசிபலன் பாருங்கள்.",
    "✨ இன்றைய ராசிபலன் உங்கள் நாளை வழிநடத்தும்.",
    "🌟 உங்கள் ராசியின் இன்றைய ரகசியம் தெரிந்துகொள்ளுங்கள்.",
)


def pick_random_title() -> str:
    return random.choice(DAILY_MORNING_TITLES_TA)


def already_sent_today(db: Session, on_date: date) -> bool:
    return (
        db.query(DailyMorningPush)
        .filter(DailyMorningPush.push_date == on_date)
        .first()
        is not None
    )


def mark_sent(db: Session, *, on_date: date, title: str) -> None:
    row = DailyMorningPush(
        push_date=on_date,
        title=title,
        sent_at=datetime.now(timezone.utc),
    )
    db.add(row)
    db.commit()
