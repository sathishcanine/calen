"""Scheduled retail gold/silver sync — morning + midday + evening (IST)."""

from __future__ import annotations

from zoneinfo import ZoneInfo

from apscheduler.schedulers.background import BackgroundScheduler

from app.database import SessionLocal

IST = ZoneInfo("Asia/Kolkata")
_scheduler: BackgroundScheduler | None = None


def _run_sync() -> None:
    from app.data.metal_rates_service import sync_retail

    db = SessionLocal()
    try:
        live = sync_retail(db)
        print(
            f"[metal-rates cron] Retail synced {live.rate_date}: "
            f"22K ₹{live.gold_22k_per_gram}/g, 24K ₹{live.gold_24k_per_gram}/g"
        )
    except Exception as exc:
        print(f"[metal-rates cron] sync failed: {exc}")
    finally:
        db.close()


def start_metal_rates_scheduler() -> BackgroundScheduler:
    global _scheduler
    if _scheduler is not None:
        return _scheduler

    scheduler = BackgroundScheduler(timezone=IST)
    # Consumer sites update ~9:30–10 AM; also refresh after midday/evening sessions.
    scheduler.add_job(_run_sync, "cron", hour=10, minute=0, id="retail_morning")
    scheduler.add_job(_run_sync, "cron", hour=12, minute=35, id="retail_noon")
    scheduler.add_job(_run_sync, "cron", hour=18, minute=35, id="retail_evening")
    scheduler.start()
    _scheduler = scheduler
    print("Metal rates cron: scheduled at 10:00, 12:35 & 18:35 IST (retail)")
    return scheduler


def stop_metal_rates_scheduler() -> None:
    global _scheduler
    if _scheduler is not None:
        _scheduler.shutdown(wait=False)
        _scheduler = None
