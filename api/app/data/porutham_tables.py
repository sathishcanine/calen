"""Tamil 10 Porutham tables — used with kaalavidya birth nakshatra."""

from __future__ import annotations

from kaalavidya.constants import NAKSHATRA, RASHI

NAKSHATRA_NAMES_TA: list[str] = list(NAKSHATRA["ta"])
RASHI_NAMES_TA: list[str] = list(RASHI["ta"])

# 0=Deva, 1=Manushya, 2=Rakshasa
NAKSHATRA_GANA = [
    1, 1, 0, 0, 1, 0, 0, 1, 1, 1, 0, 0, 1, 1, 0, 0, 1, 0, 0, 1, 1, 0, 0, 1, 1, 0, 0,
]

# Yoni animal index (0-13) — same animal = best
NAKSHATRA_YONI = [
    3, 3, 5, 5, 4, 4, 2, 2, 5, 5, 0, 0, 1, 1, 3, 3, 5, 5, 4, 4, 2, 2, 5, 5, 0, 0, 1,
]

# Rajju: 0=Paada, 1=Ooru, 2=Prushta, 3=Kanta, 4=Sirasu
NAKSHATRA_RAJJU = [
    0, 1, 2, 3, 4, 0, 1, 2, 3, 4, 0, 1, 2, 3, 4, 0, 1, 2, 3, 4, 0, 1, 2, 3, 4, 0, 1,
]

# Rashi lord pairs for Rasi Athipathi (0=Mars,1=Venus,2=Mercury,3=Moon,4=Sun,5=Mercury,6=Venus,7=Mars,8=Jupiter,9=Saturn,10=Saturn,11=Jupiter)
RASHI_LORD = [0, 1, 2, 3, 4, 2, 1, 0, 5, 6, 6, 5]

# Nakshatra → rashi (0-based)
NAKSHATRA_RASHI = [
    0, 0, 0, 1, 1, 1, 2, 2, 2, 3, 3, 3, 4, 4, 4, 5, 5, 5, 6, 6, 6, 7, 7, 7, 8, 8, 8,
]

PORUTHAM_NAMES_TA = [
    "தின பொருத்தம்",
    "கண பொருத்தம்",
    "மகேந்திர பொருத்தம்",
    "ஸ்திரீ தீர்க்கம்",
    "யோனி பொருத்தம்",
    "ராசி பொருத்தம்",
    "ராசி அதிபதி",
    "வசியம்",
    "ரஜ்ஜு பொருத்தம்",
    "வேதை",
]

GANA_NAMES_TA = ["தேவ", "மனுஷ்ய", "ராட்சச"]


def nakshatra_count(from_idx: int, to_idx: int) -> int:
    """Count nakshatras from `from_idx` to `to_idx` inclusive."""
    if to_idx >= from_idx:
        return to_idx - from_idx + 1
    return 27 - from_idx + to_idx + 1


def check_dina(boy: int, girl: int) -> tuple[bool, str]:
    rem = nakshatra_count(boy, girl) % 9
    ok = rem in (0, 1, 3, 5, 7)
    return ok, f"நட்சத்திர எண்ணிக்கை மீதி: {rem}"


def check_gana(boy: int, girl: int) -> tuple[bool, str]:
    bg, gg = NAKSHATRA_GANA[boy], NAKSHATRA_GANA[girl]
    if bg == gg:
        return True, f"இருவரும் {GANA_NAMES_TA[bg]} கணம்"
    if {bg, gg} == {0, 1}:
        return True, f"{GANA_NAMES_TA[bg]} + {GANA_NAMES_TA[gg]}"
    if bg == 2 and gg == 2:
        return False, "இருவரும் ராட்சச கணம்"
    return bg != 2 and gg != 2, f"{GANA_NAMES_TA[bg]} + {GANA_NAMES_TA[gg]}"


def check_mahendra(boy: int, girl: int) -> tuple[bool, str]:
    c = nakshatra_count(boy, girl)
    ok = c in (4, 7, 10, 13, 16, 19, 22, 25)
    return ok, f"எண்ணிக்கை: {c}"


def check_stree_deergha(boy: int, girl: int) -> tuple[bool, str]:
    c = nakshatra_count(boy, girl)
    return c >= 13, f"எண்ணிக்கை: {c} (13+ தேவை)"


def check_yoni(boy: int, girl: int) -> tuple[bool, str]:
    by, gy = NAKSHATRA_YONI[boy], NAKSHATRA_YONI[girl]
    return by == gy, f"யோனி குறியீடு: {by} & {gy}"


def check_rasi(boy: int, girl: int) -> tuple[bool, str]:
    br, gr = NAKSHATRA_RASHI[boy], NAKSHATRA_RASHI[girl]
    diff = (gr - br) % 12
    ok = diff in (0, 1, 3, 4, 5, 7, 9, 10, 11)
    return ok, f"{RASHI_NAMES_TA[br]} → {RASHI_NAMES_TA[gr]}"


def check_rasi_adhipathi(boy: int, girl: int) -> tuple[bool, str]:
    bl = RASHI_LORD[NAKSHATRA_RASHI[boy]]
    gl = RASHI_LORD[NAKSHATRA_RASHI[girl]]
    friends = {
        0: {0, 3, 6},
        1: {1, 2, 5},
        2: {1, 2, 5},
        3: {0, 3, 6},
        4: {4, 7, 8},
        5: {4, 7, 8},
        6: {4, 7, 8},
    }
    ok = gl in friends.get(bl, {bl}) or bl == gl
    return ok, f"அதிபதி குறியீடு {bl} & {gl}"


def check_vasiya(boy: int, girl: int) -> tuple[bool, str]:
    br, gr = NAKSHATRA_RASHI[boy], NAKSHATRA_RASHI[girl]
    pairs = {(0, 1), (1, 0), (2, 5), (5, 2), (3, 4), (4, 3), (6, 7), (7, 6), (8, 9), (9, 8), (10, 11), (11, 10)}
    ok = (br, gr) in pairs or br == gr
    return ok, f"{RASHI_NAMES_TA[br]} & {RASHI_NAMES_TA[gr]}"


def check_rajju(boy: int, girl: int) -> tuple[bool, str]:
    br, gr = NAKSHATRA_RAJJU[boy], NAKSHATRA_RAJJU[girl]
    return br != gr, f"ரஜ்ஜு: {br} & {gr} (வேறுபட வேண்டும்)"


def check_vedha(boy: int, girl: int) -> tuple[bool, str]:
    bad = {
        (0, 17), (17, 0), (1, 16), (16, 1), (2, 15), (15, 2),
        (3, 14), (14, 3), (4, 13), (13, 4), (5, 12), (12, 5),
        (6, 11), (11, 6), (7, 10), (10, 7), (8, 9), (9, 8),
        (18, 26), (26, 18), (19, 25), (25, 19), (20, 24), (24, 20),
        (21, 23), (23, 21),
    }
    ok = (boy, girl) not in bad
    return ok, "வேதை இணை இல்லை" if ok else "வேதை இணை உள்ளது"


def compute_porutham(boy_nakshatra: int, girl_nakshatra: int) -> dict:
    checks = [
        check_dina,
        check_gana,
        check_mahendra,
        check_stree_deergha,
        check_yoni,
        check_rasi,
        check_rasi_adhipathi,
        check_vasiya,
        check_rajju,
        check_vedha,
    ]
    factors = []
    score = 0
    for i, fn in enumerate(checks):
        matched, note = fn(boy_nakshatra, girl_nakshatra)
        factors.append({
            "name_ta": PORUTHAM_NAMES_TA[i],
            "matched": matched,
            "note_ta": note,
        })
        if matched:
            score += 1
    max_score = len(checks)
    if score >= 8:
        verdict = "மிக நல்ல பொருத்தம் — திருமணத்திற்கு ஏற்றது"
    elif score >= 6:
        verdict = "நல்ல பொருத்தம் — பொதுவாக ஏற்றது"
    elif score >= 4:
        verdict = "சராசரி பொருத்தம் — ஜோதிடர் ஆலோசனை நல்லது"
    else:
        verdict = "பொருத்தம் குறைவு — விரிவான ஆலோசனை தேவை"
    return {
        "person1_nakshatra_ta": NAKSHATRA_NAMES_TA[boy_nakshatra],
        "person2_nakshatra_ta": NAKSHATRA_NAMES_TA[girl_nakshatra],
        "person1_rashi_ta": RASHI_NAMES_TA[NAKSHATRA_RASHI[boy_nakshatra]],
        "person2_rashi_ta": RASHI_NAMES_TA[NAKSHATRA_RASHI[girl_nakshatra]],
        "total_score": score,
        "max_score": max_score,
        "verdict_ta": verdict,
        "factors": factors,
    }
