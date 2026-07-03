# Run the app — quick reference

How to run **Tamilar World** (Flutter). **Chennai 2026 is always bundled** — no server needed for default use.

---

## Normal run (recommended)

```bash
cd app
flutter run
```

- **Default city:** Chennai (saved on first launch)
- **Data source:** bundled `calendar.db` — 365 daily + 12 monthly rows for 2026
- **Works offline** for calendar, panchangam, spiritual menus
- **No `OFFLINE_MODE` flag required**

Other cities (Madurai, Dubai, etc.) need the API when selected via the location button.

---

## Bundled assets (included in every APK)

| File | Size | Contents |
|------|------|----------|
| `calendar.db` | ~4.6 MB | Chennai 2026 — 365 daily + 12 monthly rows |
| `spiritual_bundle.json` | ~69 KB | Vastu + Pancha Pakshi + Palangal |
| `pancha_pakshi_db.csv` | ~132 KB | Pancha Pakshi calculator rules |

On first launch, `calendar.db` is copied from assets to app storage automatically.

---

## Optional: strict offline mode

Disables API entirely — only Chennai available in city picker:

```bash
flutter run --dart-define=OFFLINE_MODE=true
```

App title shows **(ஆஃப்லைன்)**. Use for builds that must never call the network.

---

## Online mode — other cities

Start the API when users pick cities other than Chennai:

```bash
cd api
source .venv/bin/activate
uvicorn app.main:app --reload --host 0.0.0.0 --port 4000
```

```bash
cd app
# Android emulator
flutter run --dart-define=API_BASE=http://10.0.2.2:4000/api/v1

# Physical device (replace with your LAN IP)
flutter run --dart-define=API_BASE=http://192.168.1.3:4000/api/v1
```

Chennai still uses bundled DB even with API running.

---

## Refresh bundled Chennai data (after re-ingesting API)

```bash
cd api
source .venv/bin/activate
python -m app.ingestion.fetch_month --city chennai --year 2026 --all-months
python scripts/export_offline_bundle.py
```

Then rebuild the app.

---

## Build flags summary

| Flag | Example | Purpose |
|------|---------|---------|
| *(none)* | `flutter run` | Chennai from bundled DB; API optional for other cities |
| `OFFLINE_MODE` | `--dart-define=OFFLINE_MODE=true` | No API at all; Chennai only |
| `API_BASE` | `--dart-define=API_BASE=http://192.168.1.3:4000/api/v1` | Server URL for non-Chennai cities |

---

## Default city

`chennai` — bundled in `assets/data/calendar.db`, default on fresh install.
