"""Daily temple-of-the-day selection and push idempotency."""

from __future__ import annotations

from datetime import date, datetime, timezone

from sqlalchemy.orm import Session

from app.models import Temple, TempleDailyPush


def ensure_temples_synced(db: Session) -> int:
    """Sync curated temples when the directory is empty (first deploy)."""
    count = db.query(Temple).count()
    if count > 0:
        return count
    from app.data.temples_service import sync_temples

    return sync_temples(db)


def temples_with_images(db: Session) -> list[Temple]:
    return (
        db.query(Temple)
        .filter(Temple.image_url != "")
        .order_by(Temple.sort_order.asc(), Temple.id.asc())
        .all()
    )


def temple_for_date(db: Session, on_date: date) -> Temple | None:
    temples = temples_with_images(db)
    if not temples:
        return None
    idx = on_date.toordinal() % len(temples)
    return temples[idx]


def already_sent_today(db: Session, on_date: date) -> bool:
    return (
        db.query(TempleDailyPush)
        .filter(TempleDailyPush.push_date == on_date)
        .first()
        is not None
    )


def mark_sent(db: Session, *, on_date: date, temple_slug: str) -> None:
    row = TempleDailyPush(
        push_date=on_date,
        temple_slug=temple_slug,
        sent_at=datetime.now(timezone.utc),
    )
    db.add(row)
    db.commit()


def push_body_preview(temple: Temple, *, max_len: int = 120) -> str:
    text = " • ".join(
        part.strip()
        for part in (temple.location_ta, temple.deity_ta)
        if part and part.strip()
    )
    if not text:
        text = temple.name_ta.strip()
    if len(text) <= max_len:
        return text
    return text[: max_len - 1].rstrip() + "…"
