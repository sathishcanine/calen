"""Send one morning home-screen push daily at 06:30 IST."""

from __future__ import annotations

from datetime import date
from zoneinfo import ZoneInfo

from apscheduler.schedulers.background import BackgroundScheduler

from app.data.daily_morning_push_service import (
    already_sent_today,
    mark_sent,
    pick_random_title,
)
from app.database import SessionLocal
from app.push_service import send_daily_morning_push

IST = ZoneInfo("Asia/Kolkata")
_scheduler: BackgroundScheduler | None = None


def _today_ist() -> date:
    from datetime import datetime

    return datetime.now(IST).date()


def _run_daily_morning_push() -> None:
    db = SessionLocal()
    try:
        today = _today_ist()
        if already_sent_today(db, today):
            print(f"[daily-morning-push cron] Already sent for {today}")
            return

        title = pick_random_title()
        pushed = send_daily_morning_push(title=title)
        if pushed:
            mark_sent(db, on_date=today, title=title)
            print(f"[daily-morning-push cron] Sent for {today}: {title}")
        else:
            print("[daily-morning-push cron] Push failed")
    except Exception as exc:
        print(f"[daily-morning-push cron] failed: {exc}")
    finally:
        db.close()


def start_daily_morning_push_scheduler() -> BackgroundScheduler:
    global _scheduler
    if _scheduler is not None:
        return _scheduler

    scheduler = BackgroundScheduler(timezone=IST)
    scheduler.add_job(
        _run_daily_morning_push,
        "cron",
        hour=6,
        minute=30,
        id="daily_morning_push",
    )
    scheduler.start()
    _scheduler = scheduler
    print("Daily morning push cron: scheduled at 06:30 IST")
    return scheduler


def stop_daily_morning_push_scheduler() -> None:
    global _scheduler
    if _scheduler is not None:
        _scheduler.shutdown(wait=False)
        _scheduler = None
