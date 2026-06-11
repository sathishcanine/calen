"""Optional Prokerala API overlay (free tier: https://api.prokerala.com)."""

from __future__ import annotations

import logging
import time
from datetime import date, datetime
from typing import Any

import httpx

from app.config import settings

logger = logging.getLogger(__name__)

TOKEN_URL = "https://api.prokerala.com/token"
PANCHANG_URL = "https://api.prokerala.com/v2/astrology/panchang"
HOROSCOPE_URL = "https://api.prokerala.com/v2/horoscope/daily"
GOWRI_URL = "https://api.prokerala.com/v2/astrology/gowri-nalla-neram"


class ProkeralaClient:
    def __init__(self, client_id: str, client_secret: str):
        self.client_id = client_id
        self.client_secret = client_secret
        self._token: str | None = None
        self._token_expires = 0.0
        self._http = httpx.Client(timeout=30.0)

    @classmethod
    def from_settings(cls) -> ProkeralaClient | None:
        cid = settings.prokerala_client_id
        secret = settings.prokerala_client_secret
        if not cid or not secret:
            return None
        return cls(cid, secret)

    def _get_token(self) -> str:
        if self._token and time.time() < self._token_expires:
            return self._token
        resp = self._http.post(
            TOKEN_URL,
            data={
                "grant_type": "client_credentials",
                "client_id": self.client_id,
                "client_secret": self.client_secret,
            },
            headers={"Content-Type": "application/x-www-form-urlencoded"},
        )
        resp.raise_for_status()
        data = resp.json()
        self._token = data["access_token"]
        self._token_expires = time.time() + int(data.get("expires_in", 3600)) - 60
        return self._token

    def _get(self, url: str, params: dict) -> dict[str, Any]:
        token = self._get_token()
        time.sleep(0.25)  # respect ~5 req/min on free tier
        resp = self._http.get(url, params=params, headers={"Authorization": f"Bearer {token}"})
        resp.raise_for_status()
        return resp.json()

    def fetch_panchang(self, lat: float, lon: float, on_date: date) -> dict[str, Any]:
        dt = datetime(on_date.year, on_date.month, on_date.day, 6, 0, 0)
        params = {
            "ayanamsa": 1,
            "coordinates": f"{lat},{lon}",
            "datetime": dt.isoformat(),
            "la": "ta",
        }
        return self._get(PANCHANG_URL, params)

    def fetch_gowri(self, lat: float, lon: float, on_date: date) -> dict[str, Any]:
        dt = datetime(on_date.year, on_date.month, on_date.day, 6, 0, 0)
        params = {
            "ayanamsa": 1,
            "coordinates": f"{lat},{lon}",
            "datetime": dt.isoformat(),
            "la": "ta",
        }
        try:
            return self._get(GOWRI_URL, params)
        except httpx.HTTPError as e:
            logger.warning("Gowri fetch failed: %s", e)
            return {}

    def close(self) -> None:
        self._http.close()


def merge_prokerala_into_daily(row: dict, api_data: dict, gowri_data: dict) -> dict:
    """Overlay Prokerala fields when present (best-effort parsing)."""
    import json

    data = api_data.get("data") or api_data
    if gowri_data:
        gdata = gowri_data.get("data") or gowri_data
        periods = gdata.get("nalla_neram") or gdata.get("periods") or []
        if periods:
            slots = []
            for p in periods[:2]:
                slots.append(
                    {
                        "period": p.get("name", p.get("period", "நேரம்")),
                        "time": p.get("time", p.get("range", "")),
                    }
                )
            row["gowri_nalla_neram_json"] = json.dumps(slots, ensure_ascii=False)
    return row
