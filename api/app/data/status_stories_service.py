"""Admin-managed status story images (read-only in mobile app)."""

from __future__ import annotations

import json
import uuid
from datetime import datetime, timezone
from pathlib import Path

DATA_DIR = Path(__file__).resolve().parent / "status_stories"
IMAGES_DIR = DATA_DIR / "images"
MANIFEST_PATH = DATA_DIR / "manifest.json"
PUBLIC_LIMIT = 10
MAX_STORED = 50

ALLOWED_EXTENSIONS = {".jpg", ".jpeg", ".png", ".webp"}


def _ensure_dirs() -> None:
    IMAGES_DIR.mkdir(parents=True, exist_ok=True)
    if not MANIFEST_PATH.exists():
        MANIFEST_PATH.write_text("[]", encoding="utf-8")


def _load_manifest() -> list[dict]:
    _ensure_dirs()
    raw = MANIFEST_PATH.read_text(encoding="utf-8").strip()
    if not raw:
        return []
    return json.loads(raw)


def _save_manifest(items: list[dict]) -> None:
    _ensure_dirs()
    MANIFEST_PATH.write_text(json.dumps(items, ensure_ascii=False, indent=2), encoding="utf-8")


def _sorted(items: list[dict]) -> list[dict]:
    return sorted(items, key=lambda x: x.get("created_at", ""), reverse=True)


def list_stories(*, limit: int = PUBLIC_LIMIT, admin: bool = False) -> list[dict]:
    items = _sorted(_load_manifest())
    cap = MAX_STORED if admin else min(limit, PUBLIC_LIMIT)
    return items[:cap]


def add_story(
    *,
    filename: str,
    content: bytes,
    title: str = "",
    caption: str = "",
) -> dict:
    ext = Path(filename).suffix.lower()
    if ext not in ALLOWED_EXTENSIONS:
        raise ValueError(f"Unsupported image type: {ext or '(none)'}")

    _ensure_dirs()
    story_id = str(uuid.uuid4())
    stored_name = f"{story_id}{ext}"
    (IMAGES_DIR / stored_name).write_bytes(content)

    entry = {
        "id": story_id,
        "filename": stored_name,
        "title": title.strip(),
        "caption": caption.strip(),
        "created_at": datetime.now(timezone.utc).isoformat(),
    }

    items = _load_manifest()
    items.insert(0, entry)
    items = _sorted(items)[:MAX_STORED]

    # Drop overflow image files from disk.
    kept_names = {i["filename"] for i in items}
    for path in IMAGES_DIR.iterdir():
        if path.is_file() and path.name not in kept_names:
            path.unlink(missing_ok=True)

    _save_manifest(items)
    return entry


def delete_story(story_id: str) -> bool:
    items = _load_manifest()
    target = next((i for i in items if i["id"] == story_id), None)
    if not target:
        return False

    image_path = IMAGES_DIR / target["filename"]
    image_path.unlink(missing_ok=True)
    _save_manifest([i for i in items if i["id"] != story_id])
    return True


def image_path(filename: str) -> Path:
    return IMAGES_DIR / filename
