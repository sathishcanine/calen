"""Send one temple push notification daily at 17:30 IST."""

from __future__ import annotations

from datetime import date
from zoneinfo import ZoneInfo

from apscheduler.schedulers.background import BackgroundScheduler

from app.config import settings
from app.data.temple_push_service import (
    already_sent_today,
    ensure_temples_synced,
    mark_sent,
    push_body_preview,
    temple_for_date,
)
from app.database import SessionLocal
from app.push_service import send_temple_push

IST = ZoneInfo("Asia/Kolkata")
_scheduler: BackgroundScheduler | None = None


def _today_ist() -> date:
    from datetime import datetime

    return datetime.now(IST).date()


def _run_daily_temple_push() -> None:
    db = SessionLocal()
    try:
        today = _today_ist()
        if already_sent_today(db, today):
            print(f"[temple-push cron] Already sent for {today}")
            return

        ensure_temples_synced(db)
        temple = temple_for_date(db, today)
        if temple is None or not temple.image_url:
            print(f"[temple-push cron] No temple with image for {today}")
            return

        api_base = settings.public_base_url.strip().rstrip("/") or "http://127.0.0.1:4000"
        pushed = send_temple_push(
            temple_slug=temple.slug,
            title=temple.name_ta,
            body=push_body_preview(temple),
            image_filename=temple.image_url,
            api_base=api_base,
        )
        if pushed:
            mark_sent(db, on_date=today, temple_slug=temple.slug)
            print(f"[temple-push cron] Sent {temple.slug} for {today}")
        else:
            print(f"[temple-push cron] Push failed for {temple.slug}")
    except Exception as exc:
        print(f"[temple-push cron] failed: {exc}")
    finally:
        db.close()


def start_temple_push_scheduler() -> BackgroundScheduler:
    global _scheduler
    if _scheduler is not None:
        return _scheduler

    scheduler = BackgroundScheduler(timezone=IST)
    scheduler.add_job(
        _run_daily_temple_push,
        "cron",
        hour=17,
        minute=30,
        id="temple_daily_push",
    )
    scheduler.start()
    _scheduler = scheduler
    print("Temple push cron: scheduled at 17:30 IST (one kovil per day)")
    return scheduler


def stop_temple_push_scheduler() -> None:
    global _scheduler
    if _scheduler is not None:
        _scheduler.shutdown(wait=False)
        _scheduler = None
