"""Send today's temple-of-the-day push immediately (manual test)."""

from app.database import SessionLocal
from app.data.temple_push_service import (
    already_sent_today,
    ensure_temples_synced,
    mark_sent,
    push_body_preview,
    temple_for_date,
)
from app.config import settings
from app.push_service import send_temple_push
from app.temple_push_scheduler import _today_ist


def main() -> None:
    db = SessionLocal()
    try:
        today = _today_ist()
        ensure_temples_synced(db)
        temple = temple_for_date(db, today)
        if temple is None or not temple.image_url:
            print("No temple with image available.")
            return

        api_base = settings.public_base_url.strip().rstrip("/") or "http://127.0.0.1:4000"
        pushed = send_temple_push(
            temple_slug=temple.slug,
            title=temple.name_ta,
            body=push_body_preview(temple),
            image_filename=temple.image_url,
            api_base=api_base,
        )
        if not pushed:
            print("Push failed (check FIREBASE_CREDENTIALS_PATH).")
            return

        if not already_sent_today(db, today):
            mark_sent(db, on_date=today, temple_slug=temple.slug)
        print(f"Temple push sent: {temple.name_ta} ({temple.slug})")
    finally:
        db.close()


if __name__ == "__main__":
    main()
