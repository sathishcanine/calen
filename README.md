# Tamilar World — Tamil Calendar

> **Handbook for developers and AI assistants.** This README captures project structure, architecture decisions, commands, and troubleshooting from initial build-through. Use it as context when continuing work on this repo.

## Project goal

Android-first Tamil calendar app (similar in scope to apps like Nithra Calendar): daily panchangam, monthly grid, festivals, horoscope, etc. Monetization plan: **ads only** (no subscription). Audience: **Tamils worldwide** (diaspora needs city/timezone-aware data).

**Brand:** Tamilar World (தமிழர் உலகம் காலண்டர்)

---

## Monorepo layout

| Folder | Stack | Purpose |
|--------|-------|---------|
| `app/` | Flutter (`tamilar_calendar`) | Android mobile app |
| `api/` | Python FastAPI + SQLAlchemy | REST API + SQLite DB |
| `admin/` | React + Vite + TypeScript | Admin panel to edit calendar rows |

**Org / package:** `com.tamilarworld` (Flutter)

---

## UI screens (reference from competitor screenshots)

| ID | Screen | Implementation |
|----|--------|----------------|
| **SS1** | Home — green date banner, `நாள் காட்டி` + `மாத காட்டி` tiles | `app/lib/screens/home_screen.dart` |
| **SS2–SS4** | Daily — header, events, நல்ல நேரம், கௌரி நல்ல நேரம், பஞ்சாங்கம், Rahu/Gulika/Yamagandam, rasi chart, ராசிபலன், quote, birthday | `app/lib/screens/daily_calendar_screen.dart` |
| **SS5–SS7** | Monthly — grid, விரத தினங்கள், சுபமுகூர்த்த, festival lists by religion | `app/lib/screens/monthly_calendar_screen.dart` |

**Not fully implemented yet:** festival editorial content (Hindu/Muslim/Christian lists often empty after ingestion), wedding days from publishers, AdMob, user accounts, push notifications, full SS3 spiritual grid (Pancha Pakshi, etc.).

---

## Architecture (current)

```
┌─────────────────────────────────────────────────────────────────┐
│  INGESTION (server-side only, batch jobs)                        │
│  kaalavidya (default, free, local)  │  Prokerala API (optional) │
└──────────────────────────┬──────────────────────────────────────┘
                           ▼
                   SQLite: api/tamilar_calendar.db
                   • daily_calendars  (1 row / city / date)
                   • month_calendars  (1 row / city / year / month)
                   • cities
                           ▼
                   FastAPI REST  (/api/v1/...)
                           ▼
              ┌────────────┴────────────┐
              ▼                         ▼
        Flutter app (app/)      Admin panel (admin/)
        API on every screen      Edit daily fields
```

### Important decisions (do not undo without discussion)

| Topic | Decision |
|-------|----------|
| **Flutter data** | **API-only for now** — every screen fetch hits the backend. **No local SQLite/cache** in the app yet (planned when stable). |
| **User → upstream APIs** | **Never** call Prokerala/others from the phone. Only batch jobs on the server fill the DB. |
| **App prefetch** | `GET /sync/daily-bundle` exists on API for **future** 30-day cache; Flutter does **not** use it currently. |
| **API startup** | `ensure_cities()` only — does **not** overwrite ingested data with demo seed. |
| **Demo seed** | `python -m app.seed` — manual sample UI copy; prefer ingestion for real data. |
| **Default city** | `chennai` (`app/lib/config/api_config.dart`, API query default) |

---

## Database (SQLite)

**File:** `api/tamilar_calendar.db`

| Table | Key | Contents |
|-------|-----|----------|
| `cities` | `id` (e.g. `chennai`, `singapore`) | `lat`, `lon`, `tz_offset`, `name_ta`, `name_en` |
| `daily_calendars` | `(city_id, gregorian_date)` | Banner, panchangam JSON, nalla neram, horoscope JSON, rasi chart, etc. |
| `month_calendars` | `(city_id, year, month)` | Grid `days_json`, `fasting_days_json`, festival JSON columns |

**Current data (as of setup):** Chennai **2026** — **365** daily rows + **12** monthly rows (full year ingested via kaalavidya).

---

## Data sources and provenance

Where information in this project comes from — for transparency, legal clarity, and AI/human handoff.

### 1. This repository (code and docs)

| Item | Source |
|------|--------|
| `api/`, `app/`, `admin/` | Built in this project (FastAPI, Flutter, React) |
| `api/tamilar_calendar.db` | Filled by ingestion scripts (see below) |
| UI layout (SS1–SS7) | Inspired by **user-provided competitor screenshots** (e.g. Nithra-style flows) — **design reference only** |
| Product choices | User decisions: Android-first, ads-only, API-only app, default city Chennai, year 2026, etc. |
| This README | Commands, architecture, and fixes from **development sessions** (runbooks, debugging notes) |

### 2. Calendar and panchang data in the database

| Source | Role | How it enters the DB |
|--------|------|----------------------|
| **[kaalavidya](https://pypi.org/project/kaalavidya/)** | **Default / current** | `python -m app.ingestion.fetch_month ...` runs local astronomical + panchang math; results mapped in `api/app/ingestion/mappers.py` → SQLite |
| **[Prokerala API](https://api.prokerala.com)** | **Optional overlay** | `api/app/ingestion/prokerala_client.py` — only if `PROKERALA_CLIENT_ID` / `SECRET` in `api/.env`. Re-run ingestion **without** `--no-prokerala`. **Not used** if you always pass `--no-prokerala` |
| **`api/app/seed.py`** | **Demo / static sample** | Manual `python -m app.seed` — placeholder Tamil copy for UI demos; **not** real panchang. API startup does **not** run this automatically |

**What kaalavidya provides (examples):** tithi, nakshatra, yoga, karana, sunrise/sunset, Rahu / Gulika / Yamagandam, approximate nalla neram (from abhijit/amrit), planet positions for rasi chart, Tamil labels for weekday and lunar month.

**What is generated in our code (not from an external publisher):** generic daily horoscope one-liners (rotating words per sign in `mappers.py`), empty or derived festival lists until you add editorial data.

### 3. Competitor / market reference (Nithra and similar)

| Used for | Not used for |
|----------|----------------|
| Screen list, UX patterns, feature scope | Database rows, API responses, copyrighted text or icons |
| Business context (ads, install scale) in README | Copying their panchang values or festival wording |

### 4. What we do **not** pull from

- Nithra (or any competitor) app backend, API, or database  
- Scraping of calendar websites  
- A single “Tamil calendar API” that includes full festival + horoscope editorial content  
- Government / religious holiday datasets (unless you add them via admin or future ingestion)

### 5. README troubleshooting notes (environment-specific)

Examples like `192.168.1.9`, `localhost:4000` returning `{"detail":"Not Found"}`, or port conflicts came from **debugging this dev machine** (`ipconfig getifaddr en0`, `curl`, `lsof -i :4000`). **Your LAN IP may differ** — always re-check with `ipconfig getifaddr en0`.

### 6. Accuracy disclaimer

Panchang values depend on **location** (lat/lon), **ayanamsa**, and tradition. kaalavidya uses standard Vedic/drik calculation; they may **differ slightly** from printed regional almanacs (e.g. specific Tamil solar month day numbers vs lunar `masa` naming). For production, plan expert review or comparison with a trusted regional calendar before marketing “official” muhurtham.

---

## Backend API

### One-time setup

```bash
cd api
python3 -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt
cp .env.example .env   # optional, for Prokerala keys
```

### Start server (required before app/admin)

```bash
cd api
source .venv/bin/activate
uvicorn app.main:app --reload --host 0.0.0.0 --port 4000
```

- **`--host 0.0.0.0`** — required so a **physical phone** on the same Wi‑Fi can connect.
- Stop: `Ctrl + C`
- Entry: `api/app/main.py`
- Config: `api/app/config.py` (`.env` supported)

### Verify API (use LAN IP, not always localhost)

```bash
ipconfig getifaddr en0    # Mac Wi‑Fi IP, e.g. 192.168.1.9
```

| Check | URL | Expected |
|-------|-----|----------|
| Swagger | `http://<LAN_IP>:4000/docs` | API docs UI |
| Health | `http://<LAN_IP>:4000/api/v1/health` | `{"status":"ok"}` |
| Health shortcut | `http://<LAN_IP>:4000/health` | `{"status":"ok"}` |
| Home | `http://<LAN_IP>:4000/api/v1/home?city_id=chennai&date=2026-06-03` | JSON banner |
| Daily | `http://<LAN_IP>:4000/api/v1/calendar/day?city_id=chennai&date=2026-06-03` | Full day JSON |
| Month | `http://<LAN_IP>:4000/api/v1/calendar/month?city_id=chennai&year=2026&month=6` | Month JSON |

### REST endpoints

| Method | Path | Used by |
|--------|------|---------|
| GET | `/api/v1/health` | Health check |
| GET | `/api/v1/home?city_id=&date=` | Flutter home (SS1) |
| GET | `/api/v1/calendar/day?city_id=&date=` | Flutter daily (SS2–4) |
| GET | `/api/v1/calendar/month?city_id=&year=&month=` | Flutter monthly (SS5–7) |
| GET | `/api/v1/cities` | City list |
| GET | `/api/v1/sync/daily-bundle?city_id=&from=&days=` | Future app cache (unused in app now) |
| PUT | `/api/v1/admin/daily/{city_id}/{date}` | Admin panel |
| PUT | `/api/v1/admin/month/{city_id}/{year}/{month}` | Admin (not in UI yet) |
| GET | `/` | `{"app": "...", "docs": "/docs"}` |

---

## Data ingestion (fill / refresh DB)

> See also: [Data sources and provenance](#data-sources-and-provenance).

**Script:** `api/app/ingestion/fetch_month.py`

**Default source:** [kaalavidya](https://pypi.org/project/kaalavidya/) — free, MIT, Tamil panchang computed locally (no API key). Maps to our DB via `api/app/ingestion/mappers.py`.

**Optional source:** [Prokerala API](https://api.prokerala.com) — set in `api/.env`:

```env
PROKERALA_CLIENT_ID=
PROKERALA_CLIENT_SECRET=
```

Remove `--no-prokerala` to overlay (costs API credits; ~5 req/min on free tier).

### Commands

```bash
cd api
source .venv/bin/activate

# Full year (12 months, ~365 daily + 12 monthly rows)
python -m app.ingestion.fetch_month --city chennai --year 2026 --all-months --no-prokerala

# Single month
python -m app.ingestion.fetch_month --city chennai --year 2026 --month 6 --no-prokerala

# Partial year
python -m app.ingestion.fetch_month --city chennai --year 2026 --all-months --from-month 1 --to-month 6 --no-prokerala

# Other city (must exist in cities table)
python -m app.ingestion.fetch_month --city singapore --year 2026 --all-months --no-prokerala
```

**Manual demo seed** (static copy, not astronomical):

```bash
python -m app.seed
```

### What ingestion fills vs does not

| Filled by kaalavidya | Not filled (needs editorial / other APIs) |
|----------------------|-------------------------------------------|
| Tithi, nakshatra, yoga, karana, sunrise | Government holidays |
| Rahu, Gulika, Yamagandam | Named Hindu/Muslim/Christian festival titles |
| Nalla neram (from abhijit/amrit), Gowri-ish slots from muhurtas | Wedding muhurtham lists |
| Rasi chart (planet positions) | Horoscope prose quality (generic rotation used) |
| Tamil weekday, lunar month names | “Today in history”, articles |

---

## Flutter app (`app/`)

### Run

```bash
cd app
flutter pub get
flutter run
```

### API base URL (`app/lib/config/api_config.dart`)

| Device | `API_BASE` |
|--------|------------|
| **Android emulator** | `http://10.0.2.2:4000/api/v1` (default) |
| **Physical phone** | `http://<YOUR_MAC_LAN_IP>:4000/api/v1` |

**Physical device — full restart required** (hot reload does not apply `--dart-define`):

```bash
flutter run --dart-define=API_BASE=http://192.168.1.9:4000/api/v1
```

Replace `192.168.1.9` with **your** IP from `ipconfig getifaddr en0`.

### API calls per screen (current behavior)

| Screen | Endpoint | When |
|--------|----------|------|
| Home | `GET /home` | Open, pull-to-refresh |
| Daily | `GET /calendar/day` | Open, each prev/next day |
| Monthly | `GET /calendar/month` | Open, each month change |

**Repository:** `app/lib/services/calendar_repository.dart` — thin wrapper over `api_service.dart`.

### Android notes

- Cleartext HTTP enabled: `app/android/app/src/main/AndroidManifest.xml` (`usesCleartextTraffic`, `INTERNET`)
- App label: தமிழர் உலகம் காலண்டர்

### Planned later (not implemented)

- Local Room/SQLite cache + `daily-bundle` sync
- City picker, diaspora cities
- AdMob

---

## Admin panel (`admin/`)

```bash
cd admin
cp .env.example .env    # VITE_API_BASE=http://localhost:4000/api/v1
npm install
npm run dev
```

- URL: http://localhost:5173
- Lists daily rows, edit Tamil fields → `PUT /api/v1/admin/daily/...`
- API must be running

---

## Troubleshooting

### `No route to host` / connection error on phone

1. API running with `--host 0.0.0.0 --port 4000`
2. Phone and Mac on **same Wi‑Fi**
3. Use **correct LAN IP** in `--dart-define` (e.g. `192.168.1.9`, **not** `192.168.1.10` unless that is your current IP)
4. Test in phone browser: `http://<LAN_IP>:4000/api/v1/health` → `{"status":"ok"}`
5. Full **restart** Flutter app after changing `API_BASE`

### `{"detail":"Not Found"}` on health URL

| Cause | Fix |
|-------|-----|
| Wrong path | Use `/api/v1/health` or `/health` (not `/api/health`) |
| Wrong server on **localhost** | Another project may own the port. Run `lsof -i :4000` and stop the conflicting process, or pick a different `--port` |
| API not started | Start uvicorn from `api/` folder |

### `Address already in use` (port 4000)

```bash
lsof -i :4000
# kill conflicting PID or use another port:
uvicorn app.main:app --reload --host 0.0.0.0 --port 8080
# then point Flutter: --dart-define=API_BASE=http://<IP>:8080/api/v1
```

### API returns 404 for `/home` or `/calendar/day`

DB empty for that date — run ingestion for that year/month (see above).

### Terminal: commands pasted on one line

Run as **separate lines**:

```bash
cd api
source .venv/bin/activate
uvicorn app.main:app --reload --host 0.0.0.0 --port 4000
```

---

## Key file map (for AI / navigation)

```
api/
  app/main.py                 # FastAPI app, CORS, routes
  app/models.py               # SQLAlchemy models
  app/schemas.py              # Pydantic request/response
  app/routers/public.py       # Mobile API
  app/routers/admin.py        # Admin API
  app/ingestion/
    fetch_month.py            # CLI: month or full year
    kaalavidya_provider.py    # Free panchang source
    prokerala_client.py       # Optional API overlay
    mappers.py                # Panchanga → DB fields
    month_builder.py          # Daily rows → month grid
  app/seed.py                 # Demo data + ensure_cities()
  tamilar_calendar.db         # SQLite database

app/lib/
  config/api_config.dart
  services/api_service.dart
  services/calendar_repository.dart
  screens/home_screen.dart
  screens/daily_calendar_screen.dart
  screens/monthly_calendar_screen.dart
  models/daily_calendar.dart
  models/month_calendar.dart

admin/src/
  api.ts
  pages/DailyList.tsx
  pages/DailyEdit.tsx
```

---

## Business context (for future features)

- **Revenue:** ads only; no subscription planned initially
- **Distribution:** existing website ~20k visits/mo can link to Play Store
- **Install goal:** 1L+ installs is ambitious organically; needs ASO + marketing
- **Competitor reference:** Nithra Tamil Calendar (large feature set, ~58MB, ads)

---

## Command cheat sheet

```bash
# API
cd api && source .venv/bin/activate
uvicorn app.main:app --reload --host 0.0.0.0 --port 4000

# Ingest full year
python -m app.ingestion.fetch_month --city chennai --year 2026 --all-months --no-prokerala

# Flutter emulator
cd app && flutter run

# Flutter physical device
cd app && flutter run --dart-define=API_BASE=http://$(ipconfig getifaddr en0):4000/api/v1

# Admin
cd admin && npm run dev
```

---

## Related docs

- [api/README.md](api/README.md) — API-focused quick reference
