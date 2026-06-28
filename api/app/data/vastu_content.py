"""Editorial வாஸ்து நாட்கள் / தகவல்கள் — static content (not from kaalavidya)."""

from __future__ import annotations

from datetime import date

VASTU_ARTICLES: list[dict] = [
    {"id": 1, "title_ta": "அடிக்கடி வேலை மாற்றத்திற்கும்... வாஸ்துவிற்கு தொடர்பு உண்டா?"},
    {"id": 2, "title_ta": "அடுக்குமாடி வீடுகள் வாழ்வில் அடுத்த கட்டத்திற்கு அழைத்து செல்லுமா?"},
    {"id": 3, "title_ta": "கடனுக்கு மேல் கடன் ஏற்பட காரணம்..!!"},
    {"id": 4, "title_ta": "சதுரமும், செவ்வகமும் வீட்டிற்கும், அதன் அறைகளுக்கும் பொருந்தும் விதி..!!"},
    {"id": 5, "title_ta": "பணம் வந்த வேகத்தில் விரயமாகிறதா? இதற்கு இதுதான் காரணமா?"},
    {"id": 6, "title_ta": "வீடு கட்ட... மனையை தேர்வு செய்வதில்... இவ்வளவு நுணுக்கங்கள் இருக்கா?"},
    {"id": 7, "title_ta": "வீட்டை நமது வசதிக்காக மாற்றி அமைக்கும்போது கவனிக்க வேண்டிய முக்கிய விஷயங்கள்..!!"},
    {"id": 8, "title_ta": "கடண் சுமையை ஏற்படுத்தும் வாஸ்து அமைப்புகள்..!!"},
    {"id": 9, "title_ta": "வீட்டின் எந்த பகுதியில் சமையலறை அமைக்கலாம்?"},
    {"id": 10, "title_ta": "வீட்டின் அழகை மட்டும் கூட்டினால் என்னென்ன விளைவுகளை எதிர்கொள்ள நேரிடும்?"},
]

# Morning muhurta window per vastu day (competitor reference, year 2026 Chennai).
VASTU_DAYS_BY_YEAR: dict[int, list[dict]] = {
    2026: [
        {"gregorian_date": date(2026, 1, 26), "time_ta": "காலை 10.41 - 11.17"},
        {"gregorian_date": date(2026, 3, 6), "time_ta": "காலை 10.32 - 11.08"},
        {"gregorian_date": date(2026, 4, 23), "time_ta": "காலை 08.54 - 09.30"},
        {"gregorian_date": date(2026, 6, 4), "time_ta": "காலை 9.58 - 10.34"},
        {"gregorian_date": date(2026, 7, 27), "time_ta": "காலை 07.44 - 08.20"},
        {"gregorian_date": date(2026, 8, 23), "time_ta": "காலை 07.23 - 07.59"},
        {"gregorian_date": date(2026, 10, 28), "time_ta": "காலை 07.44 - 08.20"},
        {"gregorian_date": date(2026, 11, 24), "time_ta": "காலை 11.29 - 12.05"},
    ],
}

GREGORIAN_MONTH_TA = [
    "ஜனவரி",
    "பிப்ரவரி",
    "மார்ச்",
    "ஏப்ரல்",
    "மே",
    "ஜூன்",
    "ஜூலை",
    "ஆகஸ்ட்",
    "செப்டம்பர்",
    "அக்டோபர்",
    "நவம்பர்",
    "டிசம்பர்",
]


def available_vastu_years() -> list[int]:
    return sorted(VASTU_DAYS_BY_YEAR.keys(), reverse=True)
