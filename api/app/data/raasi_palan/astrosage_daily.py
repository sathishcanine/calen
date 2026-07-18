"""Fetch and rephrase a Tamil daily horoscope from AstroSage."""

from __future__ import annotations

import json
import re
from dataclasses import dataclass
from datetime import date, datetime
from typing import TYPE_CHECKING
from zoneinfo import ZoneInfo

import httpx
from bs4 import BeautifulSoup, Tag

if TYPE_CHECKING:
    from openai import OpenAI

IST = ZoneInfo("Asia/Kolkata")
TIMEOUT = httpx.Timeout(25.0)
HEADERS = {"User-Agent": "Mozilla/5.0 (compatible; TamilarWorldCalendar/1.0)"}

RATING_LABELS = {
    "உடல்நலம்": "❤️ #உடல்நலம்:#",
    "செல்வம்": "💰 #செல்வம்:#",
    "குடும்பம்": "👨‍👩‍👧 #குடும்பம்:#",
    "காதல் விவகாரங்கள்": "💕 #காதல் வாழ்க்கை:#",
    "வேலை": "💼 #வேலை:#",
    "மண வாழ்க்கை": "💍 #மண வாழ்க்கை:#",
}

SIGN_SYMBOLS = {
    "மேஷம்": "♈",
    "ரிஷபம்": "♉",
    "மிதுனம்": "♊",
    "கடகம்": "♋",
    "சிம்மம்": "♌",
    "கன்னி": "♍",
    "துலாம்": "♎",
    "விருச்சிகம்": "♏",
    "தனுசு": "♐",
    "மகரம்": "♑",
    "கும்பம்": "♒",
    "மீனம்": "♓",
}


@dataclass(frozen=True)
class DailyHoroscope:
    sign_ta: str
    horoscope_date: date
    narrative_ta: str
    lucky_number_ta: str
    lucky_color_ta: str
    remedy_ta: str
    ratings: dict[str, int]
    source_url: str


@dataclass(frozen=True)
class RephrasedHoroscope:
    paragraphs_ta: list[str]
    remedy_ta: str


def _clean_text(node: Tag) -> str:
    return re.sub(r"\s+", " ", node.get_text(" ", strip=True)).strip()


def _value_after_label(card: Tag, label_pattern: str) -> str:
    label = card.find("b", string=re.compile(label_pattern))
    if not isinstance(label, Tag) or not isinstance(label.parent, Tag):
        raise RuntimeError(f"AstroSage field not found: {label_pattern}")
    text = _clean_text(label.parent)
    return re.sub(r"^.*?:\s*-\s*", "", text, count=1).strip()


def parse_daily_horoscope(html: str, source_url: str) -> DailyHoroscope:
    """Parse the daily horoscope card and its source ratings."""
    soup = BeautifulSoup(html, "html.parser")
    heading = soup.find(
        "h2",
        string=lambda value: bool(value and "ராசிபலன் (" in value),
    )
    if not isinstance(heading, Tag) or not isinstance(heading.parent, Tag):
        raise RuntimeError("AstroSage daily horoscope heading was not found")

    card = heading.parent
    heading_text = _clean_text(heading)
    match = re.fullmatch(r"(.+?)\s+ராசிபலன்\s+\((.+)\)", heading_text)
    if not match:
        raise RuntimeError(f"Unexpected AstroSage heading: {heading_text}")
    sign_ta, date_text = match.groups()
    try:
        horoscope_date = datetime.strptime(date_text, "%A, %B %d, %Y").date()
    except ValueError as exc:
        raise RuntimeError(f"Unexpected AstroSage date: {date_text}") from exc

    narrative = heading.find_next_sibling(
        "div", class_=lambda value: value and "text-justify" in value
    )
    if not isinstance(narrative, Tag):
        raise RuntimeError("AstroSage daily prediction was not found")

    rating_heading = card.find("h2", string=re.compile(r"இன்றைய ரேட்டிங்"))
    ratings: dict[str, int] = {}
    if isinstance(rating_heading, Tag):
        grid = rating_heading.find_next_sibling("div", class_="show-grid")
        if isinstance(grid, Tag):
            for item in grid.find_all("div", recursive=False):
                label_node = item.find("b")
                if not isinstance(label_node, Tag):
                    continue
                label = _clean_text(label_node).rstrip(":")
                filled = sum(
                    1
                    for image in item.find_all("img")
                    if str(image.get("src", "")).endswith("/star2.gif")
                )
                if label in RATING_LABELS:
                    ratings[label] = filled

    return DailyHoroscope(
        sign_ta=sign_ta.strip(),
        horoscope_date=horoscope_date,
        narrative_ta=_clean_text(narrative),
        lucky_number_ta=_value_after_label(card, r"அதிர்ஷ்ட எண்"),
        lucky_color_ta=_value_after_label(card, r"அதிர்ஷ்ட (?:நிறம்|நீரம்)"),
        remedy_ta=_value_after_label(card, r"பரிகாரம்"),
        ratings=ratings,
        source_url=source_url,
    )


def fetch_daily_horoscope(url: str) -> DailyHoroscope:
    """Download and parse one AstroSage Tamil daily horoscope page."""
    with httpx.Client(
        timeout=TIMEOUT, follow_redirects=True, headers=HEADERS
    ) as client:
        response = client.get(url)
    response.raise_for_status()
    return parse_daily_horoscope(response.text, str(response.url))


def _json_from_response(value: str) -> dict:
    value = value.strip()
    if value.startswith("```"):
        value = re.sub(r"^```(?:json)?\s*", "", value)
        value = re.sub(r"\s*```$", "", value)
    try:
        parsed = json.loads(value)
    except json.JSONDecodeError as exc:
        raise RuntimeError("OpenAI returned invalid JSON") from exc
    if not isinstance(parsed, dict):
        raise RuntimeError("OpenAI response must be a JSON object")
    return parsed


def rephrase_daily_horoscope(
    horoscope: DailyHoroscope,
    *,
    api_key: str,
    model: str,
    client: OpenAI | None = None,
) -> RephrasedHoroscope:
    """Use OpenAI to substantially rephrase source prose without adding facts."""
    if not api_key and client is None:
        raise RuntimeError("OPENAI_API_KEY is required")
    if client is None:
        from openai import OpenAI

        client = OpenAI(api_key=api_key)

    prompt = f"""
கீழே உள்ள {horoscope.sign_ta} தினசரி ராசிபலனை இயல்பான, தெளிவான தமிழில்
முற்றிலும் புதிய சொற்றொடர்களுடன் மறுஎழுது. மூலத்தின் கருத்துகளை மட்டும் காப்பாற்று.
புதிய பலன், எண், நிறம், மதிப்பீடு, பெயர் அல்லது பரிகாரத்தை உருவாக்காதே.
பொதுப்பலனை 2 அல்லது 3 சுருக்கமான பத்திகளாகப் பிரி. விளம்பர மொழி வேண்டாம்.
பரிகாரத்தின் பொருளை மாற்றாமல் தனியாக மறுஎழுது.

JSON மட்டும் இந்த வடிவில் கொடு:
{{"paragraphs_ta":["பத்தி 1","பத்தி 2"],"remedy_ta":"பரிகாரம்"}}

மூல பொதுப்பலன்:
{horoscope.narrative_ta}

மூல பரிகாரம்:
{horoscope.remedy_ta}
""".strip()

    response = client.responses.create(
        model=model,
        instructions=(
            "நீங்கள் தமிழ் ஜோதிட உள்ளடக்கத்தைத் துல்லியமாக மறுஎழுதும் ஆசிரியர். "
            "கேட்கப்பட்ட JSON தவிர வேறு எதையும் வெளியிட வேண்டாம்."
        ),
        input=prompt,
    )
    parsed = _json_from_response(response.output_text)
    paragraphs = parsed.get("paragraphs_ta")
    remedy = parsed.get("remedy_ta")
    if (
        not isinstance(paragraphs, list)
        or not 2 <= len(paragraphs) <= 3
        or not all(isinstance(item, str) and item.strip() for item in paragraphs)
        or not isinstance(remedy, str)
        or not remedy.strip()
    ):
        raise RuntimeError("OpenAI response does not match the expected horoscope shape")
    return RephrasedHoroscope(
        paragraphs_ta=[item.strip() for item in paragraphs],
        remedy_ta=remedy.strip(),
    )


def format_general_ta(
    horoscope: DailyHoroscope, rephrased: RephrasedHoroscope
) -> str:
    """Format rephrased data for the app's `general_ta` rich-text syntax."""
    date_ta = horoscope.horoscope_date.strftime("%d.%m.%Y")
    symbol = SIGN_SYMBOLS.get(horoscope.sign_ta, "🔮")
    first, *remaining = rephrased.paragraphs_ta
    sections = [
        f"#{symbol} {horoscope.sign_ta} - இன்றைய ராசிபலன் ({date_ta})#",
        f"#{horoscope.sign_ta} ராசி அன்பர்களே!# {first}",
        *remaining,
        f"#🔢 அதிர்ஷ்ட எண்#\n\n{horoscope.lucky_number_ta}",
        f"#🎨 அதிர்ஷ்ட நிறம்#\n\n{horoscope.lucky_color_ta}",
        f"#🪔 பரிகாரம்#\n\n{rephrased.remedy_ta}",
    ]

    if horoscope.ratings:
        rating_lines = []
        for source_label, display_label in RATING_LABELS.items():
            if source_label not in horoscope.ratings:
                continue
            score = horoscope.ratings[source_label]
            rating_lines.append(f"{display_label} {'★' * score}{'☆' * (5 - score)}")
        sections.append("#🌈 இன்றைய பலன் சுருக்கம்#\n\n" + "\n".join(rating_lines))

    return "\n\n".join(sections).strip()


def ensure_current_date(horoscope: DailyHoroscope) -> None:
    """Prevent an old/cached source page from overwriting today's content."""
    today = datetime.now(IST).date()
    if horoscope.horoscope_date != today:
        raise RuntimeError(
            f"AstroSage page is for {horoscope.horoscope_date}, but today is {today}"
        )
