# Tamilar World Calendar API

Python FastAPI backend. **Full project handbook:** [../README.md](../README.md) (architecture, Flutter, troubleshooting, ingestion, **data sources**, AI context).

## Quick start

```bash
cd api
python3 -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt
uvicorn app.main:app --reload --host 0.0.0.0 --port 4000
```

Health: `http://<LAN_IP>:4000/api/v1/health` → `{"status":"ok"}`

## Ingest data

```bash
# 1. Seed ~180 world cities (TN, India, diaspora, global hubs)
python -m app.ingestion.seed_cities

# 2. One city, full year
python -m app.ingestion.fetch_month --city coimbatore --year 2026 --all-months --no-prokerala

# 3. All seeded cities, full year (batch — may take several hours)
python -m app.ingestion.fetch_month --year 2026 --all-months --all-cities --no-prokerala

# 4. India only, skip cities already ingested
python -m app.ingestion.fetch_month --year 2026 --all-months --all-cities --country IN --skip-existing --no-prokerala

# One month only
python -m app.ingestion.fetch_month --city chennai --year 2026 --month 6 --no-prokerala
```

DB: `tamilar_calendar.db` (~4 MB per city per year)

**Note:** Literal “every city on Earth” is not practical (millions of places). Extend `app/data/world_cities.py` or pass `--json cities_extra.json` to `seed_cities`.

## Endpoints

See [../README.md](../README.md#rest-endpoints) for the full table.
