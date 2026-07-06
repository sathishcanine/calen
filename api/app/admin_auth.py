import hashlib
import hmac
import secrets
import time

from fastapi import Header, HTTPException, status

from app.config import settings

TOKEN_TTL_SECONDS = 24 * 60 * 60


def _token_secret() -> bytes:
    return hashlib.sha256(f"tamilar-admin:{settings.admin_password}".encode()).digest()


def verify_password(password: str) -> bool:
    if not settings.admin_password:
        return False
    return secrets.compare_digest(password, settings.admin_password)


def create_token() -> tuple[str, int]:
    expires_at = int(time.time()) + TOKEN_TTL_SECONDS
    payload = str(expires_at)
    sig = hmac.new(_token_secret(), payload.encode(), hashlib.sha256).hexdigest()
    return f"{payload}.{sig}", expires_at


def verify_token(token: str) -> bool:
    try:
        payload, sig = token.split(".", 1)
        expires_at = int(payload)
    except ValueError:
        return False
    if expires_at < time.time():
        return False
    expected = hmac.new(_token_secret(), payload.encode(), hashlib.sha256).hexdigest()
    return secrets.compare_digest(sig, expected)


async def require_admin(authorization: str | None = Header(default=None)) -> None:
    if not settings.admin_password:
        raise HTTPException(
            status.HTTP_503_SERVICE_UNAVAILABLE,
            detail="Admin password not configured on server",
        )
    if not authorization or not authorization.startswith("Bearer "):
        raise HTTPException(status.HTTP_401_UNAUTHORIZED, detail="Not authenticated")
    token = authorization[7:].strip()
    if not token or not verify_token(token):
        raise HTTPException(status.HTTP_401_UNAUTHORIZED, detail="Invalid or expired token")
