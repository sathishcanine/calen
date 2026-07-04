from contextlib import asynccontextmanager

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from fastapi.staticfiles import StaticFiles
from sqlalchemy import inspect, text

from app.config import settings
from app.data.status_stories_service import IMAGES_DIR
from app.database import Base, SessionLocal, engine
from app.metal_rates_scheduler import start_metal_rates_scheduler, stop_metal_rates_scheduler
from app.routers import admin, public
from app.seed import ensure_cities

def _bootstrap_metal_rates() -> None:
    """Load retail benchmark rates into DB on first start."""
    from app.data.metal_rates_service import sync_retail
    from app.models import MetalRateDaily

    db = SessionLocal()
    try:
        stale = (
            db.query(MetalRateDaily)
            .filter(MetalRateDaily.source != "retail")
            .first()
            is not None
        )
        if db.query(MetalRateDaily).count() == 0 or stale:
            print("Metal rates: syncing retail rates from Goodreturns / LiveChennai ...")
            live = sync_retail(db)
            print(f"Retail synced for {live.rate_date}: 22K ₹{live.gold_22k_per_gram}/g")
    except Exception as exc:
        print(f"Metal rates bootstrap skipped: {exc}")
    finally:
        db.close()


def _ensure_sqlite_columns() -> None:
    if not settings.database_url.startswith("sqlite"):
        return
    insp = inspect(engine)
    if "daily_calendars" not in insp.get_table_names():
        return
    cols = {c["name"] for c in insp.get_columns("daily_calendars")}
    migrations = {
        "gowri_panchangam_json": "ALTER TABLE daily_calendars ADD COLUMN gowri_panchangam_json TEXT DEFAULT '[]'",
        "hora_json": "ALTER TABLE daily_calendars ADD COLUMN hora_json TEXT DEFAULT '[]'",
    }
    for col, sql in migrations.items():
        if col not in cols:
            with engine.begin() as conn:
                conn.execute(text(sql))


@asynccontextmanager
async def lifespan(_app: FastAPI):
    Base.metadata.create_all(bind=engine)
    _ensure_sqlite_columns()
    ensure_cities()
    _bootstrap_metal_rates()
    start_metal_rates_scheduler()
    yield
    stop_metal_rates_scheduler()


app = FastAPI(
    title="Tamilar World Calendar API",
    version="0.1.0",
    lifespan=lifespan,
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=settings.cors_origins.split(","),
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

prefix = settings.api_prefix
app.include_router(public.router, prefix=prefix, tags=["public"])
app.include_router(admin.router, prefix=prefix, tags=["admin"])

IMAGES_DIR.mkdir(parents=True, exist_ok=True)
app.mount(f"{prefix}/status-media", StaticFiles(directory=str(IMAGES_DIR)), name="status-media")


@app.get("/")
def root():
    return {
        "app": "Tamilar World Calendar API",
        "docs": "/docs",
        "health": "/api/v1/health",
    }


@app.get("/health")
def health_shortcut():
    """Convenience route (full path is /api/v1/health)."""
    return {"status": "ok"}
