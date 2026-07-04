"""Scrape retail gold/silver rates (Goodreturns + LiveChennai) — matches consumer websites."""

from __future__ import annotations

import re
from dataclasses import dataclass
from datetime import date, datetime, timezone
from zoneinfo import ZoneInfo

import httpx

from app.data.metal_rates_ibja_scraper import fetch_ibja_snapshot

TIMEOUT = httpx.Timeout(25.0)
HEADERS = {"User-Agent": "Mozilla/5.0 (compatible; TamilarWorldCalendar/1.0)"}
IST = ZoneInfo("Asia/Kolkata")

MONTHS = {
    "Jan": 1,
    "Feb": 2,
    "Mar": 3,
    "Apr": 4,
    "May": 5,
    "Jun": 6,
    "Jul": 7,
    "Aug": 8,
    "Sep": 9,
    "Oct": 10,
    "Nov": 11,
    "Dec": 12,
}


@dataclass
class RetailDayRate:
    rate_date: date
    gold_24k_per_gram: float
    gold_22k_per_gram: float
    silver_gram: float
    silver_kg: float


@dataclass
class RetailSnapshot:
    live: RetailDayRate
    history: list[RetailDayRate]
    scraped_at: datetime


def _parse_lc_date(value: str) -> date:
    day, mon, year = value.strip().split("/")
    month = MONTHS.get(mon)
    if month is None:
        raise ValueError(f"Unknown month in LiveChennai date: {value}")
    return date(int(year), month, int(day))


def _parse_inr(value: str) -> float:
    return float(value.replace(",", "").strip())


def _fetch(url: str) -> str:
    with httpx.Client(timeout=TIMEOUT, follow_redirects=True, headers=HEADERS) as client:
        res = client.get(url)
    res.raise_for_status()
    return res.text


def fetch_goodreturns_gold(city: str = "chennai") -> tuple[float, float]:
    page = _fetch(f"https://www.goodreturns.in/gold-rates/{city}.html")
    block = re.search(r"currentMetalPrices\s*=\s*\{([^}]+)\}", page)
    if not block:
        raise RuntimeError(f"Goodreturns gold prices not found for {city}")
    inner = block.group(1)
    g24 = re.search(r"['\"]24['\"]\s*:\s*([\d.]+)", inner)
    g22 = re.search(r"['\"]22['\"]\s*:\s*([\d.]+)", inner)
    if not g24 or not g22:
        raise RuntimeError(f"Goodreturns 22K/24K parse failed for {city}")
    return float(g22.group(1)), float(g24.group(1))


def fetch_goodreturns_silver(city: str = "chennai") -> float:
    page = _fetch(f"https://www.goodreturns.in/silver-rates/{city}.html")
    m = re.search(r"currentSilverPrice\s*=\s*([\d.]+)", page)
    if not m:
        raise RuntimeError(f"Goodreturns silver price not found for {city}")
    return float(m.group(1))


def fetch_livechennai_history() -> list[RetailDayRate]:
    page = _fetch("https://www.livechennai.com/gold_silverrate.asp")

    gold_rows = re.findall(
        r'<td class="date-col">(\d{2}/\w{3}/\d{4})</td>\s*'
        r'<td[^>]*>\s*(?:<i[^>]*></i>\s*)?([\d,]+)\s*</td>\s*'
        r'<td[^>]*>\s*(?:<i[^>]*></i>\s*)?([\d,]+)\s*</td>\s*'
        r'<td[^>]*>\s*(?:<i[^>]*></i>\s*)?([\d,]+)\s*</td>\s*'
        r'<td[^>]*>\s*(?:<i[^>]*></i>\s*)?([\d,]+)\s*</td>',
        page,
        flags=re.I,
    )

    silver_part = page.split("Chennai Silver Rate", 1)[-1]
    silver_rows = re.findall(
        r'<td class="date-col">(\d{2}/\w{3}/\d{4})</td>\s*'
        r'<td[^>]*>\s*(?:<i[^>]*></i>\s*)?([\d,.]+)\s*</td>\s*'
        r'<td[^>]*>\s*(?:<i[^>]*></i>\s*)?([\d,.]+)\s*</td>',
        silver_part,
        flags=re.I,
    )
    silver_by_date = {
        _parse_lc_date(d): (_parse_inr(g), _parse_inr(kg)) for d, g, kg in silver_rows
    }

    rows: list[RetailDayRate] = []
    for d_str, g24, _g24_8, g22, _g22_8 in gold_rows:
        rate_date = _parse_lc_date(d_str)
        silver_g, silver_kg = silver_by_date.get(rate_date, (0.0, 0.0))
        rows.append(
            RetailDayRate(
                rate_date=rate_date,
                gold_24k_per_gram=_parse_inr(g24),
                gold_22k_per_gram=_parse_inr(g22),
                silver_gram=silver_g,
                silver_kg=silver_kg,
            )
        )
    rows.sort(key=lambda r: r.rate_date)
    return rows


def _scale_ibja_history(
    retail_rows: dict[date, RetailDayRate],
    ibja_history: list,
) -> None:
    """Back-fill older chart days by scaling IBJA trend to retail levels."""
    ibja_by_date = {r.rate_date: r for r in ibja_history}
    overlap_dates = [d for d in retail_rows if d in ibja_by_date]

    if overlap_dates:
        scale_22 = sum(
            retail_rows[d].gold_22k_per_gram / ibja_by_date[d].gold_22k_per_gram
            for d in overlap_dates
        ) / len(overlap_dates)
        scale_24 = sum(
            retail_rows[d].gold_24k_per_gram / ibja_by_date[d].gold_24k_per_gram
            for d in overlap_dates
        ) / len(overlap_dates)
        silver_ratios = [
            retail_rows[d].silver_gram / ibja_by_date[d].silver_gram
            for d in overlap_dates
            if ibja_by_date[d].silver_gram > 0 and retail_rows[d].silver_gram > 0
        ]
        scale_s = sum(silver_ratios) / len(silver_ratios) if silver_ratios else scale_22
    else:
        latest_ibja = ibja_history[-1]
        latest_retail = max(retail_rows.values(), key=lambda r: r.rate_date)
        scale_22 = latest_retail.gold_22k_per_gram / latest_ibja.gold_22k_per_gram
        scale_24 = latest_retail.gold_24k_per_gram / latest_ibja.gold_24k_per_gram
        scale_s = (
            latest_retail.silver_gram / latest_ibja.silver_gram
            if latest_ibja.silver_gram > 0
            else scale_22
        )

    for ibja in ibja_history:
        if ibja.rate_date in retail_rows:
            continue
        retail_rows[ibja.rate_date] = RetailDayRate(
            rate_date=ibja.rate_date,
            gold_22k_per_gram=round(ibja.gold_22k_per_gram * scale_22, 2),
            gold_24k_per_gram=round(ibja.gold_24k_per_gram * scale_24, 2),
            silver_gram=round(ibja.silver_gram * scale_s, 2),
            silver_kg=round(ibja.silver_kg * scale_s, 2),
        )


def fetch_retail_snapshot(city: str = "chennai") -> RetailSnapshot:
    g22, g24 = fetch_goodreturns_gold(city)
    silver_g = fetch_goodreturns_silver(city)
    silver_kg = round(silver_g * 1000, 2)
    today = datetime.now(IST).date()

    live = RetailDayRate(
        rate_date=today,
        gold_22k_per_gram=g22,
        gold_24k_per_gram=g24,
        silver_gram=silver_g,
        silver_kg=silver_kg,
    )

    by_date: dict[date, RetailDayRate] = {}
    for row in fetch_livechennai_history():
        by_date[row.rate_date] = row

    ibja = fetch_ibja_snapshot()
    _scale_ibja_history(by_date, ibja.history)

    by_date[today] = live
    history = sorted(by_date.values(), key=lambda r: r.rate_date)
    return RetailSnapshot(
        live=live,
        history=history,
        scraped_at=datetime.now(timezone.utc),
    )
