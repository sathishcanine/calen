"""Run the 12 daily raasi syncs separately at random times from 04:00–06:00 IST."""

from __future__ import annotations

import fcntl
import json
import random
from datetime import date, datetime, time, timedelta
from pathlib import Path
from zoneinfo import ZoneInfo

from apscheduler.schedulers.background import BackgroundScheduler

IST = ZoneInfo("Asia/Kolkata")
_scheduler: BackgroundScheduler | None = None
STATE_PATH = Path(__file__).resolve().parent / "data" / "raasi_palan" / "sync_schedule.json"
LOCK_PATH = Path("/tmp/tamilar-world-raasi-palan.lock")
WINDOW_START = time(4, 0)
WINDOW_END = time(6, 0)
MIN_GAP_MINUTES = 5
MAX_ATTEMPTS = 3
_RANDOM = random.SystemRandom()


def _read_state() -> dict | None:
    if not STATE_PATH.exists():
        return None
    try:
        value = json.loads(STATE_PATH.read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError):
        return None
    return value if isinstance(value, dict) else None


def _write_state(state: dict) -> None:
    STATE_PATH.parent.mkdir(parents=True, exist_ok=True)
    temporary = STATE_PATH.with_suffix(".tmp")
    temporary.write_text(
        json.dumps(state, ensure_ascii=False, indent=2),
        encoding="utf-8",
    )
    temporary.replace(STATE_PATH)


def _window_bounds(day: date) -> tuple[datetime, datetime]:
    return (
        datetime.combine(day, WINDOW_START, tzinfo=IST),
        datetime.combine(day, WINDOW_END, tzinfo=IST),
    )


def _random_minutes(count: int, start: int = 0, end: int = 120) -> list[int]:
    """Choose sorted minute offsets with a guaranteed minimum gap."""
    compressed_size = (end - start) - (MIN_GAP_MINUTES - 1) * (count - 1)
    if compressed_size < count:
        raise RuntimeError("Not enough time remains to spread the pending raasi jobs")
    raw = sorted(_RANDOM.sample(range(compressed_size), count))
    return [
        start + value + index * (MIN_GAP_MINUTES - 1)
        for index, value in enumerate(raw)
    ]


def _new_plan(day: date, *, start_minute: int = 0) -> dict:
    from app.data.raasi_palan_daily_sync import RAASI_SOURCES

    window_start, _ = _window_bounds(day)
    sources = list(RAASI_SOURCES)
    _RANDOM.shuffle(sources)
    minutes = _random_minutes(len(sources), start=start_minute)
    jobs = []
    for source, minute in zip(sources, minutes):
        jobs.append(
            {
                "sign_index": source.sign_index,
                "sign_ta": source.sign_ta,
                "run_at": (window_start + timedelta(minutes=minute)).isoformat(),
                "status": "pending",
                "attempts": 0,
                "last_error": None,
                "updated_at": datetime.now(IST).isoformat(),
            }
        )
    return {
        "date": day.isoformat(),
        "created_at": datetime.now(IST).isoformat(),
        "minimum_gap_minutes": MIN_GAP_MINUTES,
        "jobs": jobs,
    }


def _job_id(day: str, sign_index: int) -> str:
    return f"daily_raasi_{day}_{sign_index}"


def _schedule_entry(day: str, entry: dict) -> None:
    if _scheduler is None:
        return
    run_at = datetime.fromisoformat(entry["run_at"])
    _scheduler.add_job(
        _run_sign,
        "date",
        run_date=run_at,
        args=[day, int(entry["sign_index"])],
        id=_job_id(day, int(entry["sign_index"])),
        replace_existing=True,
        misfire_grace_time=120,
    )


def _retry_time(state: dict, now: datetime, sign_index: int) -> datetime | None:
    _, window_end = _window_bounds(now.date())
    earliest = now + timedelta(minutes=MIN_GAP_MINUTES)
    latest = window_end - timedelta(minutes=1)
    if earliest > latest:
        return None

    occupied = [
        datetime.fromisoformat(job["run_at"])
        for job in state["jobs"]
        if int(job["sign_index"]) != sign_index and job["status"] == "pending"
    ]
    candidates = []
    cursor = earliest.replace(second=0, microsecond=0)
    while cursor <= latest:
        if all(
            abs((cursor - planned).total_seconds()) >= MIN_GAP_MINUTES * 60
            for planned in occupied
        ):
            candidates.append(cursor)
        cursor += timedelta(minutes=1)
    return _RANDOM.choice(candidates) if candidates else None


def _run_sign(plan_date: str, sign_index: int) -> None:
    from app.data.raasi_palan_daily_sync import RAASI_SOURCES, sync_daily_raasi_palan

    retry_entry = None
    with LOCK_PATH.open("w") as lock_file:
        fcntl.flock(lock_file, fcntl.LOCK_EX)
        try:
            state = _read_state()
            if not state or state.get("date") != plan_date:
                return
            entry = next(
                (
                    job
                    for job in state.get("jobs", [])
                    if int(job.get("sign_index", -1)) == sign_index
                ),
                None,
            )
            if not entry or entry.get("status") == "success":
                return

            source = next(item for item in RAASI_SOURCES if item.sign_index == sign_index)
            entry["status"] = "running"
            entry["attempts"] = int(entry.get("attempts", 0)) + 1
            entry["updated_at"] = datetime.now(IST).isoformat()
            _write_state(state)

            try:
                sync_daily_raasi_palan(source)
                entry["status"] = "success"
                entry["last_error"] = None
                print(f"[raasi-palan cron] Saved {source.sign_ta} பொதுப் பலன்")
            except Exception as exc:
                entry["status"] = "failed"
                entry["last_error"] = str(exc)
                retry_at = None
                if entry["attempts"] < MAX_ATTEMPTS:
                    retry_at = _retry_time(state, datetime.now(IST), sign_index)
                if retry_at is not None:
                    entry["status"] = "pending"
                    entry["run_at"] = retry_at.isoformat()
                    retry_entry = dict(entry)
                    print(
                        f"[raasi-palan cron] {source.sign_ta} failed; "
                        f"retrying at {retry_at:%H:%M} IST"
                    )
                else:
                    print(f"[raasi-palan cron] {source.sign_ta} failed: {exc}")
            entry["updated_at"] = datetime.now(IST).isoformat()
            _write_state(state)
        finally:
            fcntl.flock(lock_file, fcntl.LOCK_UN)

    if retry_entry is not None:
        _schedule_entry(plan_date, retry_entry)


def _prepare_daily_plan() -> None:
    now = datetime.now(IST)
    window_start, window_end = _window_bounds(now.date())
    if now >= window_end:
        return

    entries_to_schedule: list[dict] = []
    with LOCK_PATH.open("w") as lock_file:
        fcntl.flock(lock_file, fcntl.LOCK_EX)
        try:
            state = _read_state()
            if not state or state.get("date") != now.date().isoformat():
                if now >= window_start:
                    elapsed = int((now - window_start).total_seconds() // 60) + 2
                    try:
                        state = _new_plan(now.date(), start_minute=max(0, elapsed))
                    except RuntimeError:
                        print(
                            "[raasi-palan cron] Too late to safely spread all "
                            "12 signs before 06:00 IST"
                        )
                        return
                else:
                    state = _new_plan(now.date())
                _write_state(state)

            state_changed = False
            for entry in state.get("jobs", []):
                if entry.get("status") == "running":
                    updated_at = datetime.fromisoformat(entry["updated_at"])
                    if now - updated_at > timedelta(minutes=20):
                        entry["status"] = "pending"
                        state_changed = True

            for entry in state.get("jobs", []):
                if entry.get("status") != "pending":
                    continue
                run_at = datetime.fromisoformat(entry["run_at"])
                if run_at <= now:
                    replacement = _retry_time(
                        state, now, int(entry["sign_index"])
                    )
                    if replacement is None:
                        entry["status"] = "missed"
                        entry["last_error"] = (
                            "No safe retry slot remained before 06:00 IST"
                        )
                    else:
                        entry["run_at"] = replacement.isoformat()
                    entry["updated_at"] = now.isoformat()
                    state_changed = True

            if state_changed:
                _write_state(state)

            for entry in state.get("jobs", []):
                if entry.get("status") != "pending":
                    continue
                run_at = datetime.fromisoformat(entry["run_at"])
                if run_at > now:
                    entries_to_schedule.append(dict(entry))
        finally:
            fcntl.flock(lock_file, fcntl.LOCK_UN)

    for entry in entries_to_schedule:
        _schedule_entry(now.date().isoformat(), entry)
    if entries_to_schedule:
        schedule = ", ".join(
            f"{entry['sign_ta']} {datetime.fromisoformat(entry['run_at']):%H:%M}"
            for entry in entries_to_schedule
        )
        print(f"[raasi-palan cron] Today's random plan: {schedule}")


def start_raasi_palan_scheduler() -> BackgroundScheduler:
    global _scheduler
    if _scheduler is not None:
        return _scheduler

    scheduler = BackgroundScheduler(timezone=IST)
    scheduler.add_job(
        _prepare_daily_plan,
        "cron",
        hour=3,
        minute=55,
        id="prepare_daily_raasi_palan",
        coalesce=True,
        max_instances=1,
        misfire_grace_time=3600,
    )
    scheduler.add_job(
        _prepare_daily_plan,
        "cron",
        hour="4-5",
        minute="*/10",
        id="recover_daily_raasi_palan",
        coalesce=True,
        max_instances=1,
    )
    scheduler.start()
    _scheduler = scheduler
    _prepare_daily_plan()
    print("Raasi palan cron: 12 separate random jobs between 04:00–06:00 IST")
    return scheduler


def stop_raasi_palan_scheduler() -> None:
    global _scheduler
    if _scheduler is not None:
        _scheduler.shutdown(wait=False)
        _scheduler = None
