"""Admin-managed posts with image + text (mobile detail view + optional push)."""

from __future__ import annotations

import uuid
from datetime import datetime, timezone
from pathlib import Path

from sqlalchemy.orm import Session

from app.models import Post

DATA_DIR = Path(__file__).resolve().parent / "posts"
IMAGES_DIR = DATA_DIR / "images"

ALLOWED_EXTENSIONS = {".jpg", ".jpeg", ".png", ".webp"}
MAX_IMAGE_BYTES = 8 * 1024 * 1024  # 8 MB
MAX_STORED = 100


def _ensure_dirs() -> None:
    IMAGES_DIR.mkdir(parents=True, exist_ok=True)


def list_posts(db: Session, *, limit: int = MAX_STORED) -> list[Post]:
    return db.query(Post).order_by(Post.created_at.desc()).limit(limit).all()


def get_post(db: Session, post_id: str) -> Post | None:
    return db.query(Post).filter(Post.id == post_id).first()


def add_post(
    db: Session,
    *,
    title: str,
    content: str,
    filename: str,
    image_bytes: bytes,
) -> Post:
    title = title.strip()
    if not title:
        raise ValueError("Title is required")

    ext = Path(filename).suffix.lower()
    if ext not in ALLOWED_EXTENSIONS:
        raise ValueError(f"Unsupported image type: {ext or '(none)'}")
    if not image_bytes:
        raise ValueError("Image file is empty")
    if len(image_bytes) > MAX_IMAGE_BYTES:
        raise ValueError("Image exceeds 8 MB limit")

    _ensure_dirs()
    post_id = str(uuid.uuid4())
    stored_name = f"{post_id}{ext}"
    (IMAGES_DIR / stored_name).write_bytes(image_bytes)

    row = Post(
        id=post_id,
        title=title,
        content=content,
        image_filename=stored_name,
        push_sent=False,
        created_at=datetime.now(timezone.utc),
    )
    db.add(row)
    db.commit()
    db.refresh(row)
    return row


def mark_push_sent(db: Session, post: Post) -> None:
    post.push_sent = True
    db.commit()
    db.refresh(post)


def delete_post(db: Session, post_id: str) -> bool:
    row = get_post(db, post_id)
    if not row:
        return False

    image_path = IMAGES_DIR / row.image_filename
    image_path.unlink(missing_ok=True)
    db.delete(row)
    db.commit()
    return True


def push_body_preview(content: str, *, max_len: int = 120) -> str:
    text = " ".join(line.strip() for line in content.splitlines() if line.strip())
    if not text:
        return ""
    if len(text) <= max_len:
        return text
    return text[: max_len - 1].rstrip() + "…"


def push_notification_body(content: str) -> str:
    """Notification body text — never duplicates the title when content is empty."""
    return push_body_preview(content)
