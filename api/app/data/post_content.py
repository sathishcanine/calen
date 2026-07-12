"""Parse and serialize blog-style post content blocks (text + images)."""

from __future__ import annotations

import json
import re
from typing import Any


def is_blocks_content(content: str) -> bool:
    text = (content or "").strip()
    return text.startswith("[") and text.endswith("]")


def parse_blocks(content: str) -> list[dict[str, Any]]:
    """Return content blocks; plain text becomes a single text block."""
    raw = (content or "").strip()
    if not raw:
        return []
    if is_blocks_content(raw):
        try:
            data = json.loads(raw)
        except json.JSONDecodeError:
            return [{"type": "text", "value": content}]
        if not isinstance(data, list):
            return [{"type": "text", "value": content}]
        blocks: list[dict[str, Any]] = []
        for item in data:
            if not isinstance(item, dict):
                continue
            block_type = item.get("type")
            if block_type == "text":
                value = str(item.get("value") or "")
                if value.strip():
                    blocks.append({"type": "text", "value": value})
            elif block_type == "image":
                filename = str(item.get("filename") or "").strip()
                if filename:
                    blocks.append({"type": "image", "filename": filename})
        return blocks
    return [{"type": "text", "value": content}]


def blocks_to_json(blocks: list[dict[str, Any]]) -> str:
    return json.dumps(blocks, ensure_ascii=False)


def first_image_filename(content: str, *, fallback: str = "") -> str:
    for block in parse_blocks(content):
        if block.get("type") == "image" and block.get("filename"):
            return str(block["filename"])
    return fallback


def collect_image_filenames(content: str, cover_filename: str = "") -> set[str]:
    names: set[str] = set()
    if cover_filename:
        names.add(cover_filename)
    for block in parse_blocks(content):
        if block.get("type") == "image" and block.get("filename"):
            names.add(str(block["filename"]))
    return names


def text_preview(content: str, *, max_len: int = 120) -> str:
    parts: list[str] = []
    for block in parse_blocks(content):
        if block.get("type") != "text":
            continue
        value = str(block.get("value") or "").strip()
        if value:
            parts.append(value)
    text = " ".join(" ".join(line.strip() for line in part.splitlines() if line.strip()) for part in parts)
    text = re.sub(r"\s+", " ", text).strip()
    if not text:
        return ""
    if len(text) <= max_len:
        return text
    return text[: max_len - 1].rstrip() + "…"


def resolve_blocks_for_api(content: str, media_url_for_filename) -> list[dict[str, str]]:
    """Build API blocks with image URLs resolved."""
    resolved: list[dict[str, str]] = []
    for block in parse_blocks(content):
        if block.get("type") == "text":
            resolved.append({"type": "text", "value": str(block.get("value") or "")})
        elif block.get("type") == "image":
            filename = str(block.get("filename") or "")
            if filename:
                resolved.append({"type": "image", "url": media_url_for_filename(filename)})
    return resolved
