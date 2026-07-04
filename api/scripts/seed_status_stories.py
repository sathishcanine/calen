#!/usr/bin/env python3
"""Create sample status story images and register them in the uploads store."""

from __future__ import annotations

import io
import sys
from datetime import datetime, timedelta, timezone
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
API = ROOT / "api"
sys.path.insert(0, str(API))

try:
    from PIL import Image, ImageDraw, ImageFont
except ImportError as exc:
    raise SystemExit("Install Pillow first: pip install pillow") from exc

from app.data.status_stories_service import IMAGES_DIR, MANIFEST_PATH, add_story, list_stories  # noqa: E402

APP_IMAGES = ROOT / "app" / "assets" / "images"

SAMPLES = [
    {
        "title": "இன்றைய பஞ்சாங்கம்",
        "caption": "தினசரி பஞ்சாங்கம் · தமிழர் உலகம்",
        "bg": "#FFF3E0",
        "accent": "#E65100",
        "subtitle": "Panchangam",
        "asset": APP_IMAGES / "icon_panchangam.webp",
    },
    {
        "title": "திருப்பாழி",
        "caption": "ஆன்மீக நிலை · தமிழர் உலகம்",
        "bg": "#FCE4EC",
        "accent": "#AD1457",
        "subtitle": "Devotional",
        "asset": APP_IMAGES / "icon_temple.webp",
    },
    {
        "title": "நல்ல நேரம்",
        "caption": "இன்றைய நல்ல நேரம் · காலண்டர்",
        "bg": "#E8F5E9",
        "accent": "#2E7D32",
        "subtitle": "Nalla Neram",
    },
    {
        "title": "வாஸ்து நாள்",
        "caption": "வாஸ்து சிறப்பு நாட்கள்",
        "bg": "#E3F2FD",
        "accent": "#1565C0",
        "subtitle": "Vastu",
    },
    {
        "title": "பண்டிகை",
        "caption": "தமிழ் பண்டிகை · விழா நாள்",
        "bg": "#FFF8E1",
        "accent": "#F9A825",
        "subtitle": "Festival",
    },
]


def _load_font(size: int) -> ImageFont.FreeTypeFont | ImageFont.ImageFont:
    for path in (
        "/System/Library/Fonts/Supplemental/Arial Unicode.ttf",
        "/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf",
        "/usr/share/fonts/truetype/liberation/LiberationSans-Regular.ttf",
    ):
        if Path(path).exists():
            return ImageFont.truetype(path, size)
    return ImageFont.load_default()


def _render_card(sample: dict) -> bytes:
    w, h = 540, 960
    img = Image.new("RGB", (w, h), sample["bg"])
    draw = ImageDraw.Draw(img)

    accent = sample["accent"]
    draw.rounded_rectangle((36, 36, w - 36, h - 36), radius=28, outline=accent, width=6)

    title_font = _load_font(42)
    sub_font = _load_font(28)
    body_font = _load_font(24)

    draw.text((72, 120), "Daily Status", fill=accent, font=sub_font)
    draw.text((72, 180), sample["title"], fill="#1A237E", font=title_font)

    asset = sample.get("asset")
    if asset and Path(asset).exists():
        thumb = Image.open(asset).convert("RGBA")
        thumb.thumbnail((320, 320))
        tx = (w - thumb.width) // 2
        ty = 320
        img.paste(thumb, (tx, ty), thumb)
    else:
        draw.ellipse((110, 320, 430, 640), fill=accent, outline="#FFFFFF", width=4)
        draw.text((170, 470), sample["subtitle"], fill="#FFFFFF", font=body_font)

    draw.text((72, h - 160), "Tamilar World", fill="#6B5344", font=body_font)
    draw.text((72, h - 120), sample["caption"], fill="#6B5344", font=body_font)

    buf = io.BytesIO()
    img.save(buf, format="JPEG", quality=88)
    return buf.getvalue()


def main() -> None:
    existing = {s["title"] for s in list_stories(admin=True)}
    added = 0

    base_time = datetime.now(timezone.utc)
    for index, sample in enumerate(SAMPLES):
        if sample["title"] in existing:
            print(f"Skip (exists): {sample['title']}")
            continue

        content = _render_card(sample)
        entry = add_story(
            filename=f"seed_{index + 1}.jpg",
            content=content,
            title=sample["title"],
            caption=sample["caption"],
        )

        # Stagger created_at so order is stable and newest-first reads well.
        manifest_path = MANIFEST_PATH
        import json

        items = json.loads(manifest_path.read_text(encoding="utf-8"))
        for item in items:
            if item["id"] == entry["id"]:
                item["created_at"] = (base_time - timedelta(minutes=index)).isoformat()
        manifest_path.write_text(json.dumps(items, ensure_ascii=False, indent=2), encoding="utf-8")

        print(f"Added: {sample['title']} -> {IMAGES_DIR / entry['filename']}")
        added += 1

    print(f"Done. {added} new stories in {IMAGES_DIR}")


if __name__ == "__main__":
    main()
