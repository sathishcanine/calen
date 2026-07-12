"""Raasi Palan content — 4 periods × 12 signs, JSON-backed for admin paste."""

from __future__ import annotations

import json
from copy import deepcopy
from datetime import datetime
from pathlib import Path
from zoneinfo import ZoneInfo

IST = ZoneInfo("Asia/Kolkata")
DATA_PATH = Path(__file__).resolve().parent / "raasi_palan" / "content.json"

PERIODS = ("today", "weekly", "monthly", "yearly")

SIGN_NAMES_TA = [
    "மேஷம்",
    "ரிஷபம்",
    "மிதுனம்",
    "கடகம்",
    "சிம்மம்",
    "கன்னி",
    "துலாம்",
    "விருச்சிகம்",
    "தனுசு",
    "மகரம்",
    "கும்பம்",
    "மீனம்",
]

# Daily + Vaara/Maadha/Varudam fields in one store.
EMPTY_SIGN = {
    # shared / daily / weekly / monthly (single paste)
    "general_ta": "",
    "nakshatra_palan_ta": "",
    "balam_ta": "",
    "kavanam_ta": "",
    "ninaivu_ta": "",
    "lucky_numbers_ta": "",
    "lucky_colors_ta": "",
    "deity_ta": "",
    # vaara leftovers (unused in UI)
    "career_ta": "",
    "business_ta": "",
    "family_ta": "",
    "income_ta": "",
    "arts_ta": "",
    "investments_ta": "",
    "jyotish_view_ta": "",
    "cautions_ta": "",
    "special_ta": "",
    "lucky_days_ta": "",
    "chandrashtamam_ta": "",
    "remedy_ta": "",
    # yearly structure
    "graham_sancharam_ta": "",
}

SIGN_FIELDS = tuple(EMPTY_SIGN.keys())


def _normalize_sign(src: dict | None) -> dict:
    src = src or {}
    out = {}
    for key in SIGN_FIELDS:
        out[key] = (src.get(key) or "").strip() if isinstance(src.get(key), str) else ""
    # Migrate older shapes into general if needed
    if not out["general_ta"]:
        legacy = "\n\n".join(
            p
            for p in (
                src.get("content_ta") or "",
                src.get("love_family_ta") or "",
                src.get("health_ta") or "",
                src.get("wealth_ta") or "",
            )
            if (p or "").strip()
        )
        out["general_ta"] = legacy.strip()
    # Prefer dedicated cautions; fall back to daily kavanam
    if not out["cautions_ta"] and out["kavanam_ta"]:
        out["cautions_ta"] = out["kavanam_ta"]
    if not out["kavanam_ta"] and out["cautions_ta"]:
        out["kavanam_ta"] = out["cautions_ta"]
    return out


def _empty_period(period: str) -> dict:
    return {
        "period": period,
        "period_label": "",
        "updated_at": None,
        "signs": {str(i): deepcopy(EMPTY_SIGN) for i in range(12)},
    }


def _empty_store() -> dict:
    return {p: _empty_period(p) for p in PERIODS}


def _ensure_file() -> None:
    DATA_PATH.parent.mkdir(parents=True, exist_ok=True)
    if not DATA_PATH.exists():
        DATA_PATH.write_text(
            json.dumps(_empty_store(), ensure_ascii=False, indent=2),
            encoding="utf-8",
        )


def _load() -> dict:
    _ensure_file()
    raw = json.loads(DATA_PATH.read_text(encoding="utf-8"))
    store = _empty_store()
    for period in PERIODS:
        block = raw.get(period) or {}
        store[period]["period_label"] = block.get("period_label") or ""
        store[period]["updated_at"] = block.get("updated_at")
        signs = block.get("signs") or {}
        for i in range(12):
            key = str(i)
            src = signs.get(key) or signs.get(i) or {}
            store[period]["signs"][key] = _normalize_sign(src)
    return store


def _save(store: dict) -> None:
    _ensure_file()
    DATA_PATH.write_text(
        json.dumps(store, ensure_ascii=False, indent=2),
        encoding="utf-8",
    )


def current_period_label(period: str) -> str:
    now = datetime.now(IST)
    if period == "today":
        return now.strftime("%Y-%m-%d")
    if period == "weekly":
        iso = now.isocalendar()
        return f"{iso.year}-W{iso.week:02d}"
    if period == "monthly":
        return now.strftime("%Y-%m")
    if period == "yearly":
        return str(now.year)
    return ""


def list_period(period: str) -> dict:
    if period not in PERIODS:
        raise ValueError(f"Invalid period: {period}")
    store = _load()
    block = store[period]
    return {
        "period": period,
        "period_label": block.get("period_label") or current_period_label(period),
        "current_label": current_period_label(period),
        "updated_at": block.get("updated_at"),
        "signs": [
            {
                "sign_index": i,
                "sign_ta": SIGN_NAMES_TA[i],
                **block["signs"][str(i)],
            }
            for i in range(12)
        ],
    }


def get_sign(period: str, sign_index: int) -> dict:
    if period not in PERIODS:
        raise ValueError(f"Invalid period: {period}")
    if sign_index < 0 or sign_index > 11:
        raise ValueError("sign_index must be 0–11")
    store = _load()
    block = store[period]
    data = block["signs"][str(sign_index)]
    return {
        "period": period,
        "period_label": block.get("period_label") or current_period_label(period),
        "current_label": current_period_label(period),
        "updated_at": block.get("updated_at"),
        "sign_index": sign_index,
        "sign_ta": SIGN_NAMES_TA[sign_index],
        **data,
    }


def _fields_from_body(fields: dict) -> dict:
    return {
        key: (fields.get(key) or "").strip() if isinstance(fields.get(key), str) else ""
        for key in SIGN_FIELDS
    }


def upsert_sign(period: str, sign_index: int, fields: dict) -> dict:
    if period not in PERIODS:
        raise ValueError(f"Invalid period: {period}")
    if sign_index < 0 or sign_index > 11:
        raise ValueError("sign_index must be 0–11")
    store = _load()
    block = store[period]
    block["signs"][str(sign_index)] = _fields_from_body(fields)
    block["period_label"] = current_period_label(period)
    block["updated_at"] = datetime.now(IST).isoformat()
    store[period] = block
    _save(store)
    return get_sign(period, sign_index)


def upsert_period(period: str, signs: list[dict]) -> dict:
    """Bulk save all 12 signs for a period (admin paste workflow)."""
    if period not in PERIODS:
        raise ValueError(f"Invalid period: {period}")
    store = _load()
    block = store[period]
    for item in signs:
        idx = int(item.get("sign_index", -1))
        if idx < 0 or idx > 11:
            continue
        block["signs"][str(idx)] = _fields_from_body(item)
    block["period_label"] = current_period_label(period)
    block["updated_at"] = datetime.now(IST).isoformat()
    store[period] = block
    _save(store)
    return list_period(period)
