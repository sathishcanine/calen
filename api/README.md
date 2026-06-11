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
# Full year
python -m app.ingestion.fetch_month --city chennai --year 2026 --all-months --no-prokerala

# One month
python -m app.ingestion.fetch_month --city chennai --year 2026 --month 6 --no-prokerala
```

DB: `tamilar_calendar.db`

## Endpoints

See [../README.md](../README.md#rest-endpoints) for the full table.
