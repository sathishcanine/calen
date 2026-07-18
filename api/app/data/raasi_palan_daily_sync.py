"""Daily AstroSage-to-OpenAI synchronization for all 12 raasis."""

from __future__ import annotations

from dataclasses import dataclass

from openai import OpenAI

from app.config import settings
from app.data.raasi_palan.astrosage_daily import (
    ensure_current_date,
    fetch_daily_horoscope,
    format_general_ta,
    rephrase_daily_horoscope,
)
from app.data.raasi_palan_service import (
    SIGN_FIELDS,
    get_sign,
    upsert_period,
    upsert_sign,
)

ASTROSAGE_BASE_URL = "https://www.astrosage.com/tamil/rasi-palan"


@dataclass(frozen=True)
class RaasiSource:
    sign_index: int
    sign_ta: str
    slug: str

    @property
    def url(self) -> str:
        return f"{ASTROSAGE_BASE_URL}/{self.slug}-rasi-palan.asp"


RAASI_SOURCES = (
    RaasiSource(0, "மேஷம்", "mesham"),
    RaasiSource(1, "ரிஷபம்", "rishabam"),
    RaasiSource(2, "மிதுனம்", "midhunam"),
    RaasiSource(3, "கடகம்", "kadagam"),
    RaasiSource(4, "சிம்மம்", "simmam"),
    RaasiSource(5, "கன்னி", "kanni"),
    RaasiSource(6, "துலாம்", "thulaam"),
    RaasiSource(7, "விருச்சிகம்", "viruchigam"),
    RaasiSource(8, "தனுசு", "dhanusu"),
    RaasiSource(9, "மகரம்", "magaram"),
    RaasiSource(10, "கும்பம்", "kumbam"),
    RaasiSource(11, "மீனம்", "meenam"),
)


@dataclass(frozen=True)
class GeneratedRaasiPalan:
    source: RaasiSource
    general_ta: str


def generate_daily_raasi_palan(
    source: RaasiSource, *, client: OpenAI | None = None
) -> GeneratedRaasiPalan:
    """Fetch and generate one sign without saving it."""
    if not settings.openai_api_key:
        raise RuntimeError("OPENAI_API_KEY is required for daily raasi-palan sync")

    client = client or OpenAI(api_key=settings.openai_api_key)
    horoscope = fetch_daily_horoscope(source.url)
    if horoscope.sign_ta != source.sign_ta:
        raise RuntimeError(
            f"Expected {source.sign_ta}, but {source.url} contains "
            f"{horoscope.sign_ta}"
        )
    ensure_current_date(horoscope)
    rephrased = rephrase_daily_horoscope(
        horoscope,
        api_key=settings.openai_api_key,
        model=settings.openai_model,
        client=client,
    )
    return GeneratedRaasiPalan(
        source=source,
        general_ta=format_general_ta(horoscope, rephrased),
    )


def save_daily_raasi_palan(generated: GeneratedRaasiPalan) -> None:
    """Update only one sign's `general_ta`, preserving all other fields."""
    existing = get_sign("today", generated.source.sign_index)
    fields = {field: existing.get(field, "") for field in SIGN_FIELDS}
    fields["general_ta"] = generated.general_ta
    upsert_sign("today", generated.source.sign_index, fields)


def sync_daily_raasi_palan(source: RaasiSource) -> GeneratedRaasiPalan:
    """Generate and save one daily horoscope."""
    generated = generate_daily_raasi_palan(source)
    save_daily_raasi_palan(generated)
    return generated


def generate_all_daily_raasi_palan() -> list[GeneratedRaasiPalan]:
    """Generate all signs first so a failed sign cannot cause a partial save."""
    if not settings.openai_api_key:
        raise RuntimeError("OPENAI_API_KEY is required for daily raasi-palan sync")

    client = OpenAI(api_key=settings.openai_api_key)
    generated: list[GeneratedRaasiPalan] = []
    for source in RAASI_SOURCES:
        generated.append(generate_daily_raasi_palan(source, client=client))
        print(f"[raasi-palan sync] Generated {source.sign_ta}")
    return generated


def save_all_daily_raasi_palan(generated: list[GeneratedRaasiPalan]) -> None:
    """Atomically update only `general_ta`, preserving every other sign field."""
    if len(generated) != len(RAASI_SOURCES):
        raise RuntimeError(
            f"Expected {len(RAASI_SOURCES)} generated signs, got {len(generated)}"
        )

    items = []
    for item in generated:
        existing = get_sign("today", item.source.sign_index)
        fields = {field: existing.get(field, "") for field in SIGN_FIELDS}
        fields["sign_index"] = item.source.sign_index
        fields["general_ta"] = item.general_ta
        items.append(fields)
    upsert_period("today", items)


def sync_all_daily_raasi_palan() -> list[GeneratedRaasiPalan]:
    """Generate and save all 12 daily horoscopes."""
    generated = generate_all_daily_raasi_palan()
    save_all_daily_raasi_palan(generated)
    return generated
