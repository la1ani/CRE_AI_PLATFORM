"""
OM Extraction Agent.

This agent extracts structured data from Offering Memorandum (OM) PDFs.
It uses PyMuPDF to read PDF text and applies enhanced heuristics for key
commercial real estate fields including asking price, NOI, cap rate,
occupancy, building area, land area and broker details.
"""

from __future__ import annotations

import logging
import re
from pathlib import Path
from typing import Dict, Tuple

logger = logging.getLogger(__name__)

FIELD_PATTERNS = {
    "asking_price": r"(?i)(?:asking|list|sale|purchase|offered at|price)\s*(?:price)?\s*[:\-]?\s*\$?([\d,]+(?:\.\d+)?)",
    "noi": r"(?i)(?:net operating income|stabilized noi|noi)\s*[:\-]?\s*\$?([\d,]+(?:\.\d+)?)",
    "cap_rate": r"(?i)cap\s*rate\s*[:\-]?\s*([0-9]+(?:\.[0-9]+)?)\s*%",
    "occupancy": r"(?i)occupancy\s*[:\-]?\s*([0-9]+(?:\.[0-9]+)?)\s*%",
    "building_sf": r"(?i)(?:building|rentable|total)\s*(?:sf|square feet|square footage)\s*[:\-]?\s*([\d,]+)",
    "land_sf": r"(?i)(?:land|lot)\s*(?:sf|square feet|acreage|size)\s*[:\-]?\s*([\d,]+)",
    "year_built": r"(?i)(?:year built|built)\s*[:\-]?\s*([0-9]{4})",
}

PROPERTY_NAME_BLACKLIST = [
    "confidential",
    "broker",
    "contact",
    "property address",
    "offering memorandum",
    "investment summary",
    "financial summary",
    "table of contents",
    "please contact",
    "www.",
    "@",
    "email",
]

BROKER_NAME_PATTERN = re.compile(r"(?i)(?:broker|listing agent|contact)\s*[:\-]?\s*([A-Za-z .,'-]+)")
COMPANY_NAME_PATTERN = re.compile(r"(?i)(?:company|firm)\s*[:\-]?\s*([A-Za-z .,'-]+)")
EMAIL_PATTERN = re.compile(r"[\w.+-]+@[\w.-]+\.[A-Za-z]{2,}")
PHONE_PATTERN = re.compile(
    r"(?:(?:\+?\d{1,2}\s*)?(?:\(\d{3}\)|\d{3})[\s.-]?\d{3}[\s.-]?\d{4})"
)


def _clean_currency(raw: str) -> str:
    if not raw:
        return ""
    normalized = raw.replace(",", "").replace("$", "").strip()
    try:
        return f"${int(float(normalized)):,}"
    except ValueError:
        return raw.strip()


def _clean_percent(raw: str) -> str:
    if not raw:
        return ""
    normalized = raw.replace("%", "").strip()
    try:
        value = float(normalized)
        if value.is_integer():
            return f"{int(value)}%"
        return f"{value:.2f}%"
    except ValueError:
        return raw.strip()


def _extract_text(path: str) -> str:
    try:
        import fitz
    except ImportError as exc:
        logger.error("PyMuPDF is required for OM extraction: %s", exc)
        return ""

    file_path = Path(path)
    if not file_path.exists():
        logger.warning("OM file not found: %s", path)
        return ""

    try:
        with fitz.open(str(file_path)) as doc:
            return "\n".join(page.get_text() for page in doc)
    except Exception as exc:
        logger.warning("Failed to read OM PDF %s: %s", path, exc)
        return ""


def _extract_property_name(text: str) -> str:
    if not text:
        return ""

    lines = [line.strip() for line in text.splitlines() if line.strip()]
    for line in lines[:60]:
        lower = line.lower()
        if any(term in lower for term in PROPERTY_NAME_BLACKLIST):
            continue
        if EMAIL_PATTERN.search(line) or PHONE_PATTERN.search(line):
            continue
        if "$" in line or re.search(r"\d{5}", line):
            continue
        if len(line) < 8 or len(line) > 80:
            continue
        if re.search(r"(apartments|multifamily|retail|office|industrial|shopping center|hotel|medical)", lower):
            return line.strip()
        if line.isupper() and len(line.split()) <= 8:
            return line.title().strip()
    return lines[0].title().strip() if lines else ""


def extract_property_info(path: str) -> Tuple[Dict[str, str], Dict[str, str]]:
    logger.info("Extracting property information from %s", path)
    text = _extract_text(path)
    property_data: Dict[str, str] = {}
    broker_data: Dict[str, str] = {}

    for field, pattern in FIELD_PATTERNS.items():
        match = re.search(pattern, text)
        raw_value = match.group(1) if match else ""
        if field in {"asking_price", "noi"}:
            property_data[field] = _clean_currency(raw_value)
        elif field in {"cap_rate", "occupancy"}:
            property_data[field] = _clean_percent(raw_value)
        else:
            property_data[field] = raw_value.replace(",", "").strip()

    property_data["property_name"] = _extract_property_name(text)
    property_data["price"] = property_data.get("asking_price", "")

    broker_name_match = BROKER_NAME_PATTERN.search(text)
    broker_company_match = COMPANY_NAME_PATTERN.search(text)
    broker_email_match = EMAIL_PATTERN.search(text)
    broker_phone_match = PHONE_PATTERN.search(text)

    broker_data["broker_name"] = broker_name_match.group(1).strip() if broker_name_match else ""
    broker_data["broker_company"] = broker_company_match.group(1).strip() if broker_company_match else ""
    broker_data["broker_email"] = broker_email_match.group(0).strip() if broker_email_match else ""
    broker_data["broker_phone"] = broker_phone_match.group(0).strip() if broker_phone_match else ""

    return property_data, broker_data


__all__ = ["extract_property_info"]
