"""Admin-managed இன்று push notifications (image optional)."""

from __future__ import annotations

import uuid
from datetime import datetime, timezone
from pathlib import Path

from sqlalchemy.orm import Session

from app.models import IndruPush

DATA_DIR = Path(__file__).resolve().parent / "indru_push"
IMAGES_DIR = DATA_DIR / "images"

ALLOWED_EXTENSIONS = {".jpg", ".jpeg", ".png", ".webp"}
MAX_IMAGE_BYTES = 8 * 1024 * 1024
MAX_STORED = 50


def _ensure_dirs() -> None:
    IMAGES_DIR.mkdir(parents=True, exist_ok=True)


def list_pushes(db: Session, *, limit: int = MAX_STORED) -> list[IndruPush]:
    return db.query(IndruPush).order_by(IndruPush.created_at.desc()).limit(limit).all()


def get_push(db: Session, push_id: str) -> IndruPush | None:
    return db.query(IndruPush).filter(IndruPush.id == push_id).first()


def add_push(
    db: Session,
    *,
    title: str,
    body: str,
    filename: str | None,
    image_bytes: bytes | None,
) -> IndruPush:
    title = title.strip()
    if not title:
        raise ValueError("Title is required")

    stored_name: str | None = None
    if image_bytes:
        ext = Path(filename or "image.jpg").suffix.lower()
        if ext not in ALLOWED_EXTENSIONS:
            raise ValueError(f"Unsupported image type: {ext or '(none)'}")
        if len(image_bytes) > MAX_IMAGE_BYTES:
            raise ValueError("Image exceeds 8 MB limit")
        _ensure_dirs()
        push_id = str(uuid.uuid4())
        stored_name = f"{push_id}{ext}"
        (IMAGES_DIR / stored_name).write_bytes(image_bytes)
    else:
        push_id = str(uuid.uuid4())

    row = IndruPush(
        id=push_id,
        title=title,
        body=body.strip(),
        image_filename=stored_name,
        push_sent=False,
        created_at=datetime.now(timezone.utc),
    )
    db.add(row)
    db.commit()
    db.refresh(row)
    return row


def mark_push_sent(db: Session, row: IndruPush) -> None:
    row.push_sent = True
    db.commit()
    db.refresh(row)


def delete_push(db: Session, push_id: str) -> bool:
    row = get_push(db, push_id)
    if not row:
        return False
    if row.image_filename:
        (IMAGES_DIR / row.image_filename).unlink(missing_ok=True)
    db.delete(row)
    db.commit()
    return True


def push_notification_body(body: str) -> str:
    text = " ".join(line.strip() for line in body.splitlines() if line.strip())
    return text if len(text) <= 120 else text[:119].rstrip() + "…"
