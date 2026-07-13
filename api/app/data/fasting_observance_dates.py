"""Timing-correct viratham dates for 2026 (Nithra-style)."""

from __future__ import annotations

import re
from datetime import date


AMAVASAI_2026: set[date] = {
    date(2026, 1, 17),
    date(2026, 2, 16),
    date(2026, 2, 17),
    date(2026, 3, 18),
    date(2026, 4, 16),
    date(2026, 4, 17),
    date(2026, 5, 15),
    date(2026, 6, 14),
    date(2026, 7, 13),
    date(2026, 7, 14),
    date(2026, 8, 11),
    date(2026, 8, 12),
    date(2026, 9, 10),
    date(2026, 10, 9),
    date(2026, 10, 10),
    date(2026, 11, 8),
    date(2026, 11, 9),
    date(2026, 12, 7),
    date(2026, 12, 8),
}

POURNAMI_2026: set[date] = {
    date(2026, 1, 2),
    date(2026, 1, 3),
    date(2026, 1, 31),
    date(2026, 3, 2),
    date(2026, 3, 3),
    date(2026, 4, 1),
    date(2026, 4, 30),
    date(2026, 5, 1),
    date(2026, 5, 30),
    date(2026, 5, 31),
    date(2026, 6, 28),
    date(2026, 7, 28),
    date(2026, 7, 29),
    date(2026, 8, 27),
    date(2026, 9, 25),
    date(2026, 9, 26),
    date(2026, 10, 25),
    date(2026, 11, 23),
    date(2026, 11, 24),
    date(2026, 12, 23),
}

EKADASI_2026: set[date] = {
    date(2026, 1, 14),
    date(2026, 1, 29),
    date(2026, 2, 13),
    date(2026, 2, 27),
    date(2026, 3, 15),
    date(2026, 3, 29),
    date(2026, 4, 12),
    date(2026, 4, 27),
    date(2026, 5, 13),
    date(2026, 5, 27),
    date(2026, 6, 11),
    date(2026, 6, 25),
    date(2026, 7, 10),
    date(2026, 7, 25),
    date(2026, 8, 9),
    date(2026, 8, 22),
    date(2026, 9, 7),
    date(2026, 9, 22),
    date(2026, 10, 5),
    date(2026, 10, 22),
    date(2026, 11, 5),
    date(2026, 11, 21),
    date(2026, 12, 4),
    date(2026, 12, 20),
}

SASHTI_2026: set[date] = {
    date(2026, 1, 9),
    date(2026, 1, 23),
    date(2026, 2, 6),
    date(2026, 2, 23),
    date(2026, 3, 9),
    date(2026, 3, 24),
    date(2026, 4, 8),
    date(2026, 4, 22),
    date(2026, 5, 8),
    date(2026, 5, 22),
    date(2026, 6, 5),
    date(2026, 6, 20),
    date(2026, 7, 6),
    date(2026, 7, 18),
    date(2026, 8, 4),
    date(2026, 8, 18),
    date(2026, 9, 2),
    date(2026, 9, 17),
    date(2026, 10, 2),
    date(2026, 10, 15),
    date(2026, 10, 31),
    date(2026, 11, 14),
    date(2026, 11, 28),
    date(2026, 12, 15),
    date(2026, 12, 29),
}

PRADOSHAM_2026: set[date] = {
    date(2026, 1, 1),
    date(2026, 1, 16),
    date(2026, 1, 31),
    date(2026, 2, 15),
    date(2026, 3, 1),
    date(2026, 3, 17),
    date(2026, 3, 31),
    date(2026, 4, 15),
    date(2026, 4, 29),
    date(2026, 5, 15),
    date(2026, 5, 29),
    date(2026, 6, 13),
    date(2026, 6, 26),
    date(2026, 7, 12),
    date(2026, 7, 27),
    date(2026, 8, 10),
    date(2026, 8, 26),
    date(2026, 9, 9),
    date(2026, 9, 24),
    date(2026, 10, 8),
    date(2026, 10, 24),
    date(2026, 11, 7),
    date(2026, 11, 21),
    date(2026, 12, 5),
    date(2026, 12, 22),
}

SIVARATRI_2026: set[date] = {
    date(2026, 1, 16),
    date(2026, 2, 15),
    date(2026, 3, 17),
    date(2026, 4, 15),
    date(2026, 5, 15),
    date(2026, 6, 13),
    date(2026, 7, 12),
    date(2026, 8, 10),
    date(2026, 9, 9),
    date(2026, 10, 8),
    date(2026, 11, 7),
    date(2026, 12, 6),
}

CHATURTHI_2026: set[date] = {
    date(2026, 1, 21),
    date(2026, 2, 21),
    date(2026, 3, 22),
    date(2026, 4, 20),
    date(2026, 5, 20),
    date(2026, 6, 18),
    date(2026, 7, 17),
    date(2026, 8, 16),
    date(2026, 9, 15),
    date(2026, 10, 13),
    date(2026, 11, 13),
    date(2026, 12, 13),
}

SANKATAHARA_2026: set[date] = {
    date(2026, 1, 7),
    date(2026, 2, 4),
    date(2026, 3, 7),
    date(2026, 4, 6),
    date(2026, 5, 6),
    date(2026, 6, 4),
    date(2026, 7, 4),
    date(2026, 8, 2),
    date(2026, 9, 1),
    date(2026, 9, 30),
    date(2026, 10, 29),
    date(2026, 11, 28),
    date(2026, 12, 27),
}

KIRUTHIGAI_2026: set[date] = {
    date(2026, 1, 28),
    date(2026, 2, 24),
    date(2026, 3, 23),
    date(2026, 5, 17),
    date(2026, 6, 13),
    date(2026, 7, 11),
    date(2026, 8, 7),
    date(2026, 9, 3),
    date(2026, 10, 1),
    date(2026, 10, 28),
    date(2026, 11, 24),
    date(2026, 12, 22),
}

THIRUVONAM_2026: set[date] = {
    date(2026, 1, 20),
    date(2026, 2, 16),
    date(2026, 3, 15),
    date(2026, 4, 12),
    date(2026, 5, 9),
    date(2026, 6, 5),
    date(2026, 6, 6),
    date(2026, 7, 3),
    date(2026, 7, 30),
    date(2026, 8, 26),
    date(2026, 9, 23),
    date(2026, 10, 20),
    date(2026, 11, 16),
    date(2026, 12, 13),
    date(2026, 12, 14),
}


_CHATOORTHI_RE = re.compile(r"சதுர்த்தி(?!சி)")


def sunrise_tithi_text(tithi_text: str) -> str:
    if "பின்பு" in tithi_text:
        return tithi_text.split("பின்பு", 1)[0].strip()
    return tithi_text.strip()


def after_pinbu_text(tithi_text: str) -> str:
    if "பின்பு" in tithi_text:
        return tithi_text.split("பின்பு", 1)[1].strip()
    return ""


def day_has_amavasai(tithi_text: str) -> bool:
    return "அமாவாசை" in tithi_text


def day_has_pournami(tithi_text: str) -> bool:
    return "பௌர்ணமி" in tithi_text or "பவுர்ணமி" in tithi_text


def day_has_ekadasi(tithi_text: str) -> bool:
    return "ஏகாதசி" in tithi_text


def day_has_sashti(tithi_text: str) -> bool:
    return "சஷ்டி" in tithi_text


def day_has_pradosham(tithi_text: str) -> bool:
    return "திரயோதசி" in tithi_text


def day_has_sivaratri(tithi_text: str) -> bool:
    aft = after_pinbu_text(tithi_text)
    if aft:
        return "சதுர்த்தசி" in aft and "தேய்பிறை" in aft
    return "சதுர்த்தசி" in tithi_text and "தேய்பிறை" in tithi_text


def day_has_chaturthi(tithi_text: str) -> bool:
    for part in tithi_text.split("பின்பு"):
        if _CHATOORTHI_RE.search(part) and "வளர்பிறை" in part:
            return True
    return False


def day_has_sankatahara(tithi_text: str) -> bool:
    for part in tithi_text.split("பின்பு"):
        if _CHATOORTHI_RE.search(part) and "தேய்பிறை" in part:
            return True
    return False


def day_has_kiruthigai(nak_text: str) -> bool:
    return "கிருத்திகை" in nak_text


def day_has_thiruvonam(nak_text: str) -> bool:
    return "திருவோணம்" in nak_text


def is_amavasai_date(on_date: date) -> bool:
    return on_date in AMAVASAI_2026


def is_pournami_date(on_date: date) -> bool:
    return on_date in POURNAMI_2026


def is_sivaratri_date(on_date: date) -> bool:
    return on_date in SIVARATRI_2026


def sunrise_has_amavasai(tithi_text: str) -> bool:
    return day_has_amavasai(tithi_text)


def sunrise_has_pournami(tithi_text: str) -> bool:
    return day_has_pournami(tithi_text)
