# Run the app — quick reference

How to run **Tamilar World** (Flutter) in **online** (API) or **offline** (bundled DB) mode.

---

## Offline mode (no server)

Bundled assets in `app/assets/data/`:

| File | Size | Contents |
|------|------|----------|
| `calendar.db` | ~3 MB | Chennai 2026 — 365 daily + 12 monthly rows |
| `spiritual_bundle.json` | ~69 KB | Vastu + Pancha Pakshi articles |
| `pancha_pakshi_db.csv` | ~132 KB | Pancha Pakshi calculator rules |

All **7 spiritual menus** work offline, including Pancha Pakshi calculator (on-device).

```bash
cd app
flutter run --dart-define=OFFLINE_MODE=true
```

**Notes**

- **Chennai 2026 only** — dates outside 2026 are not in the bundle.
- If today is not in 2026, the home screen uses the same month/day in **2026**.
- App title shows **(ஆஃப்லைன்)** when offline mode is on.
- APK size increases by ~**3 MB** (mostly the SQLite file).

---

## Online mode (API server)

Start the API on your machine (LAN-accessible for a physical phone):

```bash
cd api
source .venv/bin/activate
uvicorn app.main:app --reload --host 0.0.0.0 --port 4000
```

Run the app:

```bash
cd app

# Android emulator
flutter run --dart-define=API_BASE=http://10.0.2.2:4000/api/v1

# Physical device (replace with your machine's LAN IP)
flutter run --dart-define=API_BASE=http://192.168.1.3:4000/api/v1
```

Default API base if you omit `API_BASE`: `http://10.0.2.2:4000/api/v1` (emulator).

---

## Refresh offline bundle (after re-ingesting API data)

Re-ingest Chennai 2026 if needed:

```bash
cd api
source .venv/bin/activate
python -m app.ingestion.fetch_month --city chennai --year 2026 --all-months
```

Export into Flutter assets:

```bash
cd api
source .venv/bin/activate
python scripts/export_offline_bundle.py
```

This copies:

- `api/tamilar_calendar.db` → `app/assets/data/calendar.db`
- `pancha_pakshi_db.csv` → `app/assets/data/pancha_pakshi_db.csv`
- builds `app/assets/data/spiritual_bundle.json`

Then rebuild the app with `--dart-define=OFFLINE_MODE=true`.

---

## Build flags summary

| Flag | Example | Purpose |
|------|---------|---------|
| `OFFLINE_MODE` | `--dart-define=OFFLINE_MODE=true` | Use bundled SQLite + JSON; no HTTP |
| `API_BASE` | `--dart-define=API_BASE=http://192.168.1.3:4000/api/v1` | API URL (online mode only) |

Offline and online are mutually exclusive: set `OFFLINE_MODE=true` to skip the API entirely.

---

## Default city

`chennai` — configured in `app/lib/config/api_config.dart` and in the bundled database.
