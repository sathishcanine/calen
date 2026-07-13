"""Publisher-style சுப முகூர்த்த நாட்கள் for 2026.

Aligned with Samayam / OneIndia / Nithra-style monthly grids.
Do NOT treat every 'good nakshatra' sunrise as a wedding muhurtham day.
"""

from __future__ import annotations

from datetime import date

SUBA_MUHURTHAM_2026: set[date] = {
    date(2026, 1, 28),
    date(2026, 2, 6),
    date(2026, 2, 8),
    date(2026, 2, 13),
    date(2026, 2, 15),
    date(2026, 2, 16),
    date(2026, 2, 20),
    date(2026, 3, 5),
    date(2026, 3, 6),
    date(2026, 3, 8),
    date(2026, 3, 15),
    date(2026, 3, 16),
    date(2026, 3, 25),
    date(2026, 4, 6),
    date(2026, 4, 12),
    date(2026, 4, 13),
    date(2026, 4, 16),
    date(2026, 4, 20),
    date(2026, 4, 23),
    date(2026, 4, 30),
    date(2026, 5, 8),
    date(2026, 5, 13),
    date(2026, 5, 14),
    date(2026, 5, 18),
    date(2026, 5, 28),
    date(2026, 5, 29),
    date(2026, 6, 4),
    date(2026, 6, 7),
    date(2026, 6, 17),
    date(2026, 6, 18),
    date(2026, 6, 24),
    date(2026, 6, 25),
    date(2026, 7, 2),
    date(2026, 7, 5),
    date(2026, 7, 12),
    date(2026, 8, 23),
    date(2026, 8, 30),
    date(2026, 8, 31),
    date(2026, 9, 7),
    date(2026, 9, 13),
    date(2026, 9, 17),
    date(2026, 10, 25),
    date(2026, 10, 30),
    date(2026, 11, 1),
    date(2026, 11, 11),
    date(2026, 11, 13),
    date(2026, 11, 15),
    date(2026, 11, 16),
    date(2026, 11, 20),
    date(2026, 11, 29),
    date(2026, 12, 4),
    date(2026, 12, 6),
    date(2026, 12, 10),
    date(2026, 12, 13),
    date(2026, 12, 14),
}


def is_suba_muhurtham_date(on_date: date) -> bool:
    return on_date in SUBA_MUHURTHAM_2026
