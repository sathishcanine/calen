#!/usr/bin/env python3
"""Export SQLite + spiritual static JSON into Flutter app assets for offline mode."""

from __future__ import annotations

import json
import shutil
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
API = ROOT / "api"
APP_ASSETS = ROOT / "app" / "assets" / "data"

sys.path.insert(0, str(API))

from app.database import SessionLocal  # noqa: E402
from app.data.pancha_pakshi_service import (  # noqa: E402
    get_article,
    list_articles,
    list_birth_paksha_options,
    list_nakshatras,
    supported_years,
)
from app.data.vastu_service import get_vastu_articles, get_vastu_days, get_vastu_years  # noqa: E402
from app.data.palangal_content import PALANGAL_ARTICLES, list_categories  # noqa: E402
from app.data import jyotish_service  # noqa: E402


def main() -> None:
    db_src = API / "tamilar_calendar.db"
    if not db_src.exists():
        raise SystemExit(f"Missing database: {db_src}\nRun ingestion for Chennai 2026 first.")

    APP_ASSETS.mkdir(parents=True, exist_ok=True)

    db_dst = APP_ASSETS / "calendar.db"
    shutil.copy2(db_src, db_dst)
    print(f"Copied {db_src} -> {db_dst} ({db_dst.stat().st_size / 1024 / 1024:.2f} MB)")

    csv_src = API / "app" / "data" / "pancha_pakshi_db.csv"
    csv_dst = APP_ASSETS / "pancha_pakshi_db.csv"
    shutil.copy2(csv_src, csv_dst)
    print(f"Copied {csv_src.name} ({csv_dst.stat().st_size / 1024:.1f} KB)")

    db = SessionLocal()
    try:
        vastu_days_by_year = {
            str(year): get_vastu_days(db, "chennai", year) for year in get_vastu_years()
        }
        article_details = {
            str(a["id"]): get_article(db, "chennai", a["id"]) for a in list_articles()
        }
        palangal_articles_by_category = {
            cat["id"]: [
                {"id": a["id"], "category_id": cat["id"], "title_ta": a["title_ta"]}
                for a in PALANGAL_ARTICLES.get(cat["id"], [])
            ]
            for cat in list_categories()
        }
        palangal_article_details = {
            f"{cat_id}-{a['id']}": {"category_id": cat_id, **a}
            for cat_id, articles in PALANGAL_ARTICLES.items()
            for a in articles
        }
        bundle = {
            "vastu_articles": get_vastu_articles(),
            "vastu_years": get_vastu_years(),
            "vastu_days_by_year": vastu_days_by_year,
            "pancha_pakshi_articles": list_articles(),
            "pancha_pakshi_nakshatras": list_nakshatras(),
            "pancha_pakshi_paksha_options": list_birth_paksha_options(),
            "pancha_pakshi_years": list(supported_years()),
            "pancha_pakshi_article_details": article_details,
            "palangal_categories": list_categories(),
            "palangal_articles_by_category": palangal_articles_by_category,
            "palangal_article_details": palangal_article_details,
            "jyotish_nakshatras": jyotish_service.list_nakshatras(),
            "jyotish_rashis": jyotish_service.list_rashis(),
        }
    finally:
        db.close()

    bundle_path = APP_ASSETS / "spiritual_bundle.json"
    bundle_path.write_text(json.dumps(bundle, ensure_ascii=False, default=str), encoding="utf-8")
    print(f"Wrote {bundle_path} ({bundle_path.stat().st_size / 1024:.1f} KB)")
    print("Done. Rebuild the Flutter app — Chennai 2026 is bundled by default.")


if __name__ == "__main__":
    main()
