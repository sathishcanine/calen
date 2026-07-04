"""Refresh global இன்று content daily at midnight IST."""

from datetime import timedelta
from zoneinfo import ZoneInfo

from apscheduler.schedulers.background import BackgroundScheduler

from app.database import SessionLocal
from app.data.indru_service import LOOKAHEAD_DAYS, _today_ist, refresh_indru_range

IST = ZoneInfo("Asia/Kolkata")
_scheduler: BackgroundScheduler | None = None


def _run_refresh() -> None:
    from app.data.indru_service import refresh_indru_for_date

    db = SessionLocal()
    try:
        today = _today_ist()
        refresh_indru_for_date(db, today, force=True)
        refresh_indru_range(db, today + timedelta(days=1), days=LOOKAHEAD_DAYS)
        print(f"[indru cron] Refreshed இன்று content for {today} + {LOOKAHEAD_DAYS} days ahead")
    except Exception as exc:
        print(f"[indru cron] refresh failed: {exc}")
    finally:
        db.close()


def bootstrap_indru() -> None:
    """Populate today + lookahead on API startup."""
    db = SessionLocal()
    try:
        today = _today_ist()
        refresh_indru_range(db, today, days=LOOKAHEAD_DAYS + 1)
        print(f"[indru] Bootstrapped content for {today} (+{LOOKAHEAD_DAYS} days)")
    except Exception as exc:
        print(f"[indru] bootstrap skipped: {exc}")
    finally:
        db.close()


def start_indru_scheduler() -> BackgroundScheduler:
    global _scheduler
    if _scheduler is not None:
        return _scheduler

    scheduler = BackgroundScheduler(timezone=IST)
    scheduler.add_job(_run_refresh, "cron", hour=0, minute=0, id="indru_midnight")
    scheduler.start()
    _scheduler = scheduler
    print("Indru cron: scheduled at 00:00 IST (global daily refresh)")
    return scheduler


def stop_indru_scheduler() -> None:
    global _scheduler
    if _scheduler is not None:
        _scheduler.shutdown(wait=False)
        _scheduler = None
