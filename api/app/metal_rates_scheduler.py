"""Scheduled retail gold/silver sync — morning + midday + evening (IST)."""

from __future__ import annotations

from datetime import datetime, timedelta
from zoneinfo import ZoneInfo

from apscheduler.schedulers.background import BackgroundScheduler

from app.database import SessionLocal

IST = ZoneInfo("Asia/Kolkata")
_scheduler: BackgroundScheduler | None = None
_PUSH_JOB_ID = "metal_rates_push"
_PUSH_DELAY_MINUTES = 5


def _schedule_metal_rates_push() -> None:
    """Notify subscribed devices 5 minutes after a successful retail sync."""
    if _scheduler is None:
        return

    from app.push_service import send_metal_rates_push

    run_at = datetime.now(IST) + timedelta(minutes=_PUSH_DELAY_MINUTES)
    _scheduler.add_job(
        send_metal_rates_push,
        "date",
        run_date=run_at,
        id=_PUSH_JOB_ID,
        replace_existing=True,
    )
    print(f"[metal-rates cron] Push notification scheduled for {run_at:%H:%M} IST")


def _run_sync() -> None:
    from app.data.metal_rates_service import sync_retail

    db = SessionLocal()
    try:
        live = sync_retail(db)
        print(
            f"[metal-rates cron] Retail synced {live.rate_date}: "
            f"22K ₹{live.gold_22k_per_gram}/g, 24K ₹{live.gold_24k_per_gram}/g"
        )
        _schedule_metal_rates_push()
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
