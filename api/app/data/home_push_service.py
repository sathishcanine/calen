"""Store optional images for on-demand home-screen push notifications."""

from __future__ import annotations

import uuid
from pathlib import Path

DATA_DIR = Path(__file__).resolve().parent / "home_push"
IMAGES_DIR = DATA_DIR / "images"

ALLOWED_EXTENSIONS = {".jpg", ".jpeg", ".png", ".webp"}
MAX_IMAGE_BYTES = 8 * 1024 * 1024


def _ensure_dirs() -> None:
    IMAGES_DIR.mkdir(parents=True, exist_ok=True)


def store_image(*, filename: str, image_bytes: bytes) -> str:
    """Save image and return stored filename."""
    ext = Path(filename or "image.jpg").suffix.lower()
    if ext not in ALLOWED_EXTENSIONS:
        raise ValueError(f"Unsupported image type: {ext or '(none)'}")
    if len(image_bytes) > MAX_IMAGE_BYTES:
        raise ValueError("Image exceeds 8 MB limit")
    _ensure_dirs()
    stored_name = f"{uuid.uuid4()}{ext}"
    (IMAGES_DIR / stored_name).write_bytes(image_bytes)
    return stored_name
