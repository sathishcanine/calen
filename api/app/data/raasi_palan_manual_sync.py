"""Background manual raasi-palan sync jobs triggered from the admin panel."""

from __future__ import annotations

import fcntl
import json
import threading
from datetime import datetime, timedelta
from pathlib import Path
from uuid import uuid4
from zoneinfo import ZoneInfo

from app.config import settings

IST = ZoneInfo("Asia/Kolkata")
STATE_PATH = (
    Path(__file__).resolve().parent / "raasi_palan" / "manual_sync_status.json"
)
LOCK_PATH = Path("/tmp/tamilar-world-raasi-palan.lock")
STALE_AFTER = timedelta(hours=2)


def _idle_job() -> dict:
    return {
        "job_id": None,
        "status": "idle",
        "started_at": None,
        "finished_at": None,
        "updated_at": None,
        "signs": [],
    }


def _read_state() -> dict:
    if not STATE_PATH.exists():
        return _idle_job()
    try:
        state = json.loads(STATE_PATH.read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError):
        return _idle_job()
    return state if isinstance(state, dict) else _idle_job()


def _write_state(state: dict) -> None:
    STATE_PATH.parent.mkdir(parents=True, exist_ok=True)
    temporary = STATE_PATH.with_suffix(".tmp")
    temporary.write_text(
        json.dumps(state, ensure_ascii=False, indent=2),
        encoding="utf-8",
    )
    temporary.replace(STATE_PATH)


def get_manual_sync_status(job_id: str | None = None) -> dict:
    state = _read_state()
    if job_id is not None and state.get("job_id") != job_id:
        raise KeyError(job_id)
    return state


def _run_job(job_id: str) -> None:
    from app.data.raasi_palan_daily_sync import (
        RAASI_SOURCES,
        sync_daily_raasi_palan,
    )

    for source in RAASI_SOURCES:
        with LOCK_PATH.open("w") as lock_file:
            fcntl.flock(lock_file, fcntl.LOCK_EX)
            try:
                state = _read_state()
                if state.get("job_id") != job_id:
                    return
                entry = state["signs"][source.sign_index]
                entry["status"] = "running"
                entry["updated_at"] = datetime.now(IST).isoformat()
                state["updated_at"] = entry["updated_at"]
                _write_state(state)

                try:
                    sync_daily_raasi_palan(source)
                    entry["status"] = "success"
                    entry["last_error"] = None
                except Exception as exc:
                    entry["status"] = "failed"
                    entry["last_error"] = str(exc)
                entry["updated_at"] = datetime.now(IST).isoformat()
                state["updated_at"] = entry["updated_at"]
                _write_state(state)
            finally:
                fcntl.flock(lock_file, fcntl.LOCK_UN)

    with LOCK_PATH.open("w") as lock_file:
        fcntl.flock(lock_file, fcntl.LOCK_EX)
        try:
            state = _read_state()
            if state.get("job_id") != job_id:
                return
            failures = [
                entry for entry in state["signs"] if entry["status"] == "failed"
            ]
            state["status"] = (
                "completed_with_errors" if failures else "completed"
            )
            state["finished_at"] = datetime.now(IST).isoformat()
            state["updated_at"] = state["finished_at"]
            _write_state(state)
        finally:
            fcntl.flock(lock_file, fcntl.LOCK_UN)


def start_manual_sync() -> dict:
    from app.data.raasi_palan_daily_sync import RAASI_SOURCES

    if not settings.openai_api_key:
        raise RuntimeError("OPENAI_API_KEY is not configured on the server")

    with LOCK_PATH.open("w") as lock_file:
        fcntl.flock(lock_file, fcntl.LOCK_EX)
        try:
            previous = _read_state()
            if previous.get("status") == "running":
                updated_value = previous.get("updated_at")
                updated_at = (
                    datetime.fromisoformat(updated_value)
                    if isinstance(updated_value, str)
                    else datetime.now(IST)
                )
                if datetime.now(IST) - updated_at <= STALE_AFTER:
                    raise FileExistsError("A raasi-palan sync is already running")

            now = datetime.now(IST).isoformat()
            state = {
                "job_id": uuid4().hex,
                "status": "running",
                "started_at": now,
                "finished_at": None,
                "updated_at": now,
                "signs": [
                    {
                        "sign_index": source.sign_index,
                        "sign_ta": source.sign_ta,
                        "status": "pending",
                        "last_error": None,
                        "updated_at": now,
                    }
                    for source in RAASI_SOURCES
                ],
            }
            _write_state(state)
        finally:
            fcntl.flock(lock_file, fcntl.LOCK_UN)

    thread = threading.Thread(
        target=_run_job,
        args=[state["job_id"]],
        name=f"raasi-sync-{state['job_id'][:8]}",
        daemon=True,
    )
    thread.start()
    return state
