import hashlib
from datetime import datetime
from bs4 import BeautifulSoup


def clean_html(raw_html: str) -> str:
    """
    Parses raw HTML using BeautifulSoup, removes script, style, nav, footer,
    and header elements, collapses whitespace, and returns plain text.
    """
    soup = BeautifulSoup(raw_html, "html.parser")

    # Remove script, style, and nav elements
    for element in soup(["script", "style", "nav", "footer", "header"]):
        element.decompose()

    # Get plain text and collapse whitespace
    text = soup.get_text(separator=" ")
    return " ".join(text.split())


def generate_id_from_url(url: str) -> int:
    """
    Helper to generate a deterministic integer ID from a URL.

    Args:
        url (str): The URL string to generate the ID for.

    Returns:
        int: A deterministic integer representation of the URL generated using SHA-256.
    """
    return int(hashlib.sha256(url.encode("utf-8")).hexdigest()[:8], 16)


def parse_timestamp(ts_str: str) -> datetime:
    """
    Helper to parse an ISO timestamp string, substituting 'Z' with UTC timezone offset.

    Args:
        ts_str (str): The ISO timestamp string.

    Returns:
        datetime: The parsed datetime object.
    """
    return datetime.fromisoformat(ts_str.replace("Z", "+00:00"))
