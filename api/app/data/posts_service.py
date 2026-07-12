"""Admin-managed posts with image + text (mobile detail view + optional push)."""

from __future__ import annotations

import uuid
from datetime import datetime, timezone
from pathlib import Path

from sqlalchemy.orm import Session

from app.data.post_content import (
    blocks_to_json,
    collect_image_filenames,
    first_image_filename,
    parse_blocks,
    text_preview,
)
from app.models import Post

DATA_DIR = Path(__file__).resolve().parent / "posts"
IMAGES_DIR = DATA_DIR / "images"

ALLOWED_EXTENSIONS = {".jpg", ".jpeg", ".png", ".webp"}
MAX_IMAGE_BYTES = 8 * 1024 * 1024  # 8 MB
MAX_STORED = 100


def _ensure_dirs() -> None:
    IMAGES_DIR.mkdir(parents=True, exist_ok=True)


def _validate_image(filename: str, image_bytes: bytes) -> str:
    ext = Path(filename).suffix.lower()
    if ext not in ALLOWED_EXTENSIONS:
        raise ValueError(f"Unsupported image type: {ext or '(none)'}")
    if not image_bytes:
        raise ValueError("Image file is empty")
    if len(image_bytes) > MAX_IMAGE_BYTES:
        raise ValueError("Image exceeds 8 MB limit")
    return ext


def store_image(*, filename: str, image_bytes: bytes) -> str:
    """Save an image and return stored filename."""
    ext = _validate_image(filename, image_bytes)
    _ensure_dirs()
    stored_name = f"{uuid.uuid4()}{ext}"
    (IMAGES_DIR / stored_name).write_bytes(image_bytes)
    return stored_name


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
    """Legacy create — single cover image + plain text content."""
    title = title.strip()
    if not title:
        raise ValueError("Title is required")

    ext = _validate_image(filename, image_bytes)
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


def add_post_with_blocks(
    db: Session,
    *,
    title: str,
    blocks: list[dict],
    cover_filename: str = "",
) -> Post:
    """Blog-style create — mixed text/image blocks in content JSON."""
    title = title.strip()
    if not title:
        raise ValueError("Title is required")
    if not blocks:
        raise ValueError("Add at least one text or image block")

    normalized: list[dict] = []
    for block in blocks:
        block_type = block.get("type")
        if block_type == "text":
            value = str(block.get("value") or "")
            if value.strip():
                normalized.append({"type": "text", "value": value})
        elif block_type == "image":
            filename = str(block.get("filename") or "").strip()
            if not filename:
                continue
            path = IMAGES_DIR / filename
            if not path.is_file():
                raise ValueError(f"Image not found: {filename}")
            normalized.append({"type": "image", "filename": filename})

    if not normalized:
        raise ValueError("Add at least one text or image block")

    cover = cover_filename.strip() or first_image_filename(blocks_to_json(normalized))
    if not cover:
        raise ValueError("Add at least one image (used as cover thumbnail)")

    cover_path = IMAGES_DIR / cover
    if not cover_path.is_file():
        raise ValueError("Cover image not found")

    post_id = str(uuid.uuid4())
    row = Post(
        id=post_id,
        title=title,
        content=blocks_to_json(normalized),
        image_filename=cover,
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

    for name in collect_image_filenames(row.content or "", row.image_filename):
        (IMAGES_DIR / name).unlink(missing_ok=True)
    db.delete(row)
    db.commit()
    return True


def push_body_preview(content: str, *, max_len: int = 120) -> str:
    return text_preview(content, max_len=max_len)


def push_notification_body(content: str) -> str:
    """Notification body text — never duplicates the title when content is empty."""
    return push_body_preview(content)
