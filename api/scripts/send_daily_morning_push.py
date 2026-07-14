"""Send today's daily morning home push immediately (manual test)."""

from app.data.daily_morning_push_service import (
    already_sent_today,
    mark_sent,
    pick_random_title,
)
from app.database import SessionLocal
from app.daily_morning_push_scheduler import _today_ist
from app.push_service import send_daily_morning_push


def main() -> None:
    db = SessionLocal()
    try:
        today = _today_ist()
        title = pick_random_title()
        pushed = send_daily_morning_push(title=title)
        if not pushed:
            print("Push failed (check FIREBASE_CREDENTIALS_PATH).")
            return

        if not already_sent_today(db, today):
            mark_sent(db, on_date=today, title=title)
        print(f"Daily morning push sent for {today}: {title}")
    finally:
        db.close()


if __name__ == "__main__":
    main()
