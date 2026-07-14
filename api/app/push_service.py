"""Firebase Cloud Messaging — metal rates push after retail sync."""

from __future__ import annotations

import logging
from pathlib import Path

from app.config import settings
from app.data.metal_rates_service import (
    METAL_RATES_PUSH_TITLE_TA,
    build_metal_rates_push_body,
)
from app.database import SessionLocal

logger = logging.getLogger(__name__)

METAL_RATES_TOPIC = "metal_rates_updates"

_api_root = Path(__file__).resolve().parents[1]
_firebase_ready = False


def _resolve_credentials_path() -> Path | None:
    raw = settings.firebase_credentials_path.strip()
    if not raw:
        return None
    path = Path(raw).expanduser()
    if not path.is_absolute():
        path = (_api_root / path).resolve()
    return path


def _ensure_firebase() -> bool:
    global _firebase_ready
    if _firebase_ready:
        return True

    path = _resolve_credentials_path()
    if path is None:
        logger.info("FIREBASE_CREDENTIALS_PATH not set — push notifications disabled")
        return False
    if not path.is_file():
        logger.warning(
            "Firebase credentials file not found at %s — push notifications disabled",
            path,
        )
        return False

    try:
        import firebase_admin
        from firebase_admin import credentials

        if not firebase_admin._apps:
            cred = credentials.Certificate(str(path))
            firebase_admin.initialize_app(cred)
        _firebase_ready = True
        return True
    except Exception as exc:
        logger.warning("Firebase init failed — push notifications disabled: %s", exc)
        return False


def send_metal_rates_push() -> None:
    """Broadcast today's gold/silver rates notification to subscribed devices."""
    if not _ensure_firebase():
        return

    from firebase_admin import messaging

    db = SessionLocal()
    try:
        body = build_metal_rates_push_body(db)
    finally:
        db.close()

    message = messaging.Message(
        data={
            "route": "metal_rates",
            "title": METAL_RATES_PUSH_TITLE_TA,
            "body": body,
        },
        topic=METAL_RATES_TOPIC,
        android=messaging.AndroidConfig(priority="high"),
        apns=messaging.APNSConfig(
            payload=messaging.APNSPayload(
                aps=messaging.Aps(content_available=True),
            ),
        ),
    )

    try:
        response = messaging.send(message)
        logger.info("[push] Metal rates notification sent (%s): %s", body, response)
    except Exception as exc:
        logger.warning("[push] Metal rates notification failed: %s", exc)


POSTS_TOPIC = "posts_updates"


def _post_push_image_url(image_filename: str, api_base: str) -> str:
    """Image URL reachable from phones (PUBLIC_BASE_URL overrides admin localhost)."""
    base = settings.public_base_url.strip().rstrip("/") or api_base.rstrip("/")
    return f"{base}{settings.api_prefix}/post-media/{image_filename}"


def send_post_push(
    *,
    post_id: str,
    title: str,
    body: str,
    image_filename: str,
    api_base: str,
) -> bool:
    """Broadcast a post as a data message; the app shows title/body/image locally."""
    if not _ensure_firebase():
        return False

    from firebase_admin import messaging

    image_url = _post_push_image_url(image_filename, api_base)
    data: dict[str, str] = {
        "route": "post",
        "post_id": post_id,
        "title": title,
        "image_url": image_url,
    }
    if body:
        data["body"] = body

    message = messaging.Message(
        data=data,
        topic=POSTS_TOPIC,
        android=messaging.AndroidConfig(priority="high"),
        apns=messaging.APNSConfig(
            payload=messaging.APNSPayload(
                aps=messaging.Aps(content_available=True),
            ),
        ),
    )

    try:
        response = messaging.send(message)
        logger.info("[push] Post notification sent (%s): %s", post_id, response)
        return True
    except Exception as exc:
        logger.warning("[push] Post notification failed: %s", exc)
        return False


INDRU_TOPIC = "indru_updates"


def _indru_push_image_url(image_filename: str, api_base: str) -> str:
    base = settings.public_base_url.strip().rstrip("/") or api_base.rstrip("/")
    return f"{base}{settings.api_prefix}/indru-push-media/{image_filename}"


def send_indru_push(
    *,
    push_id: str,
    title: str,
    body: str,
    image_filename: str | None,
    api_base: str,
) -> bool:
    """Broadcast an இன்று notification; tapping opens the இன்று tab in the app."""
    if not _ensure_firebase():
        return False

    from firebase_admin import messaging

    data: dict[str, str] = {
        "route": "indru",
        "push_id": push_id,
        "title": title,
    }
    if body:
        data["body"] = body
    if image_filename:
        data["image_url"] = _indru_push_image_url(image_filename, api_base)

    message = messaging.Message(
        data=data,
        topic=INDRU_TOPIC,
        android=messaging.AndroidConfig(priority="high"),
        apns=messaging.APNSConfig(
            payload=messaging.APNSPayload(
                aps=messaging.Aps(content_available=True),
            ),
        ),
    )

    try:
        response = messaging.send(message)
        logger.info("[push] Indru notification sent (%s): %s", push_id, response)
        return True
    except Exception as exc:
        logger.warning("[push] Indru notification failed: %s", exc)
        return False


TEMPLES_TOPIC = "temples_updates"
DAILY_MORNING_TOPIC = "daily_morning_updates"


def _temple_push_image_url(image_filename: str, api_base: str) -> str:
    base = settings.public_base_url.strip().rstrip("/") or api_base.rstrip("/")
    return f"{base}{settings.api_prefix}/temple-media/{image_filename}"


def send_temple_push(
    *,
    temple_slug: str,
    title: str,
    body: str,
    image_filename: str,
    api_base: str,
) -> bool:
    """Broadcast today's temple; tapping opens the kovil detail screen."""
    if not _ensure_firebase():
        return False

    from firebase_admin import messaging

    data: dict[str, str] = {
        "route": "temple",
        "temple_slug": temple_slug,
        "title": title,
        "image_url": _temple_push_image_url(image_filename, api_base),
    }
    if body:
        data["body"] = body

    message = messaging.Message(
        data=data,
        topic=TEMPLES_TOPIC,
        android=messaging.AndroidConfig(priority="high"),
        apns=messaging.APNSConfig(
            payload=messaging.APNSPayload(
                aps=messaging.Aps(content_available=True),
            ),
        ),
    )

    try:
        response = messaging.send(message)
        logger.info("[push] Temple notification sent (%s): %s", temple_slug, response)
        return True
    except Exception as exc:
        logger.warning("[push] Temple notification failed: %s", exc)
        return False


def send_daily_morning_push(
    *,
    title: str,
    body: str = "",
    image_filename: str | None = None,
    api_base: str = "",
) -> bool:
    """Broadcast home-screen FCM; tapping opens the app home screen."""
    if not _ensure_firebase():
        return False

    from firebase_admin import messaging

    data: dict[str, str] = {
        "route": "home",
        "title": title,
    }
    if body:
        data["body"] = body
    if image_filename:
        base = settings.public_base_url.strip().rstrip("/") or api_base.rstrip("/")
        data["image_url"] = f"{base}{settings.api_prefix}/home-push-media/{image_filename}"

    message = messaging.Message(
        data=data,
        topic=DAILY_MORNING_TOPIC,
        android=messaging.AndroidConfig(priority="high"),
        apns=messaging.APNSConfig(
            payload=messaging.APNSPayload(
                aps=messaging.Aps(content_available=True),
            ),
        ),
    )

    try:
        response = messaging.send(message)
        logger.info("[push] Home notification sent (%s): %s", title, response)
        return True
    except Exception as exc:
        logger.warning("[push] Home notification failed: %s", exc)
        return False
