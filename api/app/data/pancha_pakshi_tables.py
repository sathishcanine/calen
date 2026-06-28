"""Pancha Pakshi constants — birds, activities, birth-star mapping (Agathiyar tradition)."""

from __future__ import annotations

from kaalavidya.constants import NAKSHATRA

# 27 Tamil nakshatra names (kaalavidya)
NAKSHATRA_NAMES_TA: list[str] = list(NAKSHATRA["ta"])

BIRDS_TA = ["வல்லூறு", "ஆந்தை", "காகம்", "கோழி", "மயில்"]

ACTIVITIES_TA = ["அரசு", "ஊண்", "நடை", "துயில்", "சாவு"]

ACTIVITY_STRENGTH_TA = [
    "100% பலம் கொண்டது",
    "80% பலம் கொண்டது",
    "50% பலம் கொண்டது",
    "25% பலம் கொண்டது",
    "0% பலம் கொண்டது",
]

WEEKDAYS_TA = ["ஞாயிறு", "திங்கள்", "செவ்வாய்", "புதன்", "வியாழன்", "வெள்ளி", "சனி"]

BIRTH_PAKSHA_OPTIONS = [
    {"id": "valarpirai", "label_ta": "வளர்பிறை"},
    {"id": "theypirai", "label_ta": "தேய்பிறை"},
    {"id": "amavasai", "label_ta": "அமாவாசை"},
    {"id": "pournami", "label_ta": "பௌர்ணமி"},
]

# (shukla_bird_index, krishna_bird_index) — 0-based bird indices
BIRTH_BIRD_BY_NAKSHATRA: list[tuple[int, int]] = [
    (0, 4),
    (0, 4),
    (0, 4),
    (0, 4),
    (0, 4),
    (1, 3),
    (1, 3),
    (1, 3),
    (1, 3),
    (1, 3),
    (1, 3),
    (2, 2),
    (2, 2),
    (2, 2),
    (2, 2),
    (2, 2),
    (3, 1),
    (3, 1),
    (3, 1),
    (3, 1),
    (3, 1),
    (4, 0),
    (4, 0),
    (4, 0),
    (4, 0),
    (4, 0),
    (4, 0),
]

SUPPORTED_YEARS = (2025, 2026, 2027)


def birth_paksha_to_index(paksha_id: str) -> int:
    """Map birth paksha selection to shukla(0) / krishna(1) index."""
    if paksha_id in ("valarpirai", "pournami"):
        return 0
    return 1


def observation_paksha_to_index(paksha_ta: str) -> int:
    if "வளர்பிறை" in paksha_ta:
        return 0
    return 1


def birth_bird_index(nakshatra_index: int, birth_paksha_id: str) -> int:
    if not 0 <= nakshatra_index < 27:
        raise ValueError("nakshatra_index must be 0–26")
    shukla, krishna = BIRTH_BIRD_BY_NAKSHATRA[nakshatra_index]
    return shukla if birth_paksha_to_index(birth_paksha_id) == 0 else krishna


def weekday_index(on_date) -> int:
    """Sunday=0 … Saturday=6 (PyJHora convention)."""
    return (on_date.weekday() + 1) % 7
