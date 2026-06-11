from contextlib import asynccontextmanager

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from sqlalchemy import inspect, text

from app.config import settings
from app.database import Base, engine
from app.routers import admin, public
from app.seed import ensure_cities


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
    yield


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
