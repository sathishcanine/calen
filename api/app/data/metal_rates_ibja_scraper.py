"""Scrape official IBJA benchmark rates from ibjarates.com (India gold/silver)."""

from __future__ import annotations

import html as html_module
import json
import re
from dataclasses import dataclass
from datetime import date, datetime, timezone

import httpx

IBJA_URL = "https://ibjarates.com/"
TIMEOUT = httpx.Timeout(25.0)


@dataclass
class IbjaDayRate:
    rate_date: date
    gold_24k_per_gram: float
    gold_22k_per_gram: float
    silver_gram: float
    silver_kg: float


@dataclass
class IbjaSnapshot:
    live: IbjaDayRate
    history: list[IbjaDayRate]
    scraped_at: datetime


def _parse_ddmmyyyy(value: str) -> date:
    day, month, year = value.strip().split("/")
    return date(int(year), int(month), int(day))


def _fetch_html() -> str:
    with httpx.Client(timeout=TIMEOUT, follow_redirects=True) as client:
        res = client.get(
            IBJA_URL,
            headers={"User-Agent": "TamilarWorldCalendar/1.0 (IBJA benchmark sync)"},
        )
    res.raise_for_status()
    return res.text


def _parse_hidden_series(page: str) -> tuple[dict, dict]:
    gold_match = re.search(r'id="HdnGold"\s+value="([^"]+)"', page)
    silver_match = re.search(r'id="HdnSilver"\s+value="([^"]+)"', page)
    if not gold_match or not silver_match:
        raise RuntimeError("IBJA chart data not found on ibjarates.com")
    gold = json.loads(html_module.unescape(gold_match.group(1)))
    silver = json.loads(html_module.unescape(silver_match.group(1)))
    return gold, silver


def _parse_live_spans(page: str) -> tuple[float, float] | None:
    """Today's per-gram compare cards (most accurate for current rate)."""
    g24 = re.search(r'id="GoldRatesCompare999"[^>]*>([\d,]+)', page)
    g22 = re.search(r'id="GoldRatesCompare916"[^>]*>([\d,]+)', page)
    if not g24 or not g22:
        return None
    return float(g24.group(1).replace(",", "")), float(g22.group(1).replace(",", ""))


def _build_history(gold: dict, silver: dict) -> list[IbjaDayRate]:
    labels = gold.get("labels") or []
    g999 = gold.get("purity999") or []
    g916 = gold.get("purity916") or []
    s_labels = silver.get("labels") or []
    s_rates = silver.get("silverRate") or []

    silver_by_label = {
        lbl: rate for lbl, rate in zip(s_labels, s_rates, strict=False)
    }

    rows: list[IbjaDayRate] = []
    for i, label in enumerate(labels):
        if i >= len(g999) or i >= len(g916):
            break
        # Chart values are rupees per 10g (gold) and per 1kg (silver).
        g24 = round(float(g999[i]) / 10, 2)
        g22 = round(float(g916[i]) / 10, 2)
        silver_kg = float(silver_by_label.get(label, s_rates[i] if i < len(s_rates) else 0))
        silver_g = round(silver_kg / 1000, 2)
        rows.append(
            IbjaDayRate(
                rate_date=_parse_ddmmyyyy(label),
                gold_24k_per_gram=g24,
                gold_22k_per_gram=g22,
                silver_gram=silver_g,
                silver_kg=round(silver_kg, 2),
            )
        )
    rows.sort(key=lambda r: r.rate_date)
    return rows


def fetch_ibja_snapshot() -> IbjaSnapshot:
    page = _fetch_html()
    gold, silver = _parse_hidden_series(page)
    history = _build_history(gold, silver)
    if not history:
        raise RuntimeError("IBJA returned no historical rates")

    live_spans = _parse_live_spans(page)
    latest = history[-1]
    if live_spans:
        g24, g22 = live_spans
        live = IbjaDayRate(
            rate_date=latest.rate_date,
            gold_24k_per_gram=g24,
            gold_22k_per_gram=g22,
            silver_gram=latest.silver_gram,
            silver_kg=latest.silver_kg,
        )
    else:
        live = latest

    return IbjaSnapshot(
        live=live,
        history=history,
        scraped_at=datetime.now(timezone.utc),
    )
