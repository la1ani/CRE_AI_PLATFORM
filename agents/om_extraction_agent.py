"""
OM Extraction Agent.

This agent extracts structured data from Offering Memorandum (OM) PDFs.
It uses PyMuPDF to read the document text and applies simple
regular-expression heuristics to extract common fields such as price,
NOI, cap rate, occupancy and property characteristics. For complex
memorandums or documents with inconsistent formatting, consider
augmenting this module with AI extraction using Gemini, DeepSeek or
OpenAI APIs (see config/settings.py for API keys).

Functions return two dictionaries: one for property attributes and
another for broker contact information.
"""

from __future__ import annotations

import logging
import re
from typing import Dict, Tuple

import fitz  # PyMuPDF

logger = logging.getLogger(__name__)


FIELD_PATTERNS = {
    "price": r"(?i)price\s*[:\-]?\s*\$?([\d,]+)",
    "noi": r"(?i)noi\s*[:\-]?\s*\$?([\d,]+)",
    "cap_rate": r"(?i)cap\s*rate\s*[:\-]?\s*(\d+\.\d+%?)",
    "occupancy": r"(?i)occupancy\s*[:\-]?\s*(\d+%?)",
    "building_sf": r"(?i)building\s+sf\s*[:\-]?\s*([\d,]+)",
    "land_sf": r"(?i)land\s+sf\s*[:\-]?\s*([\d,]+)",
    "year_built": r"(?i)year\s+built\s*[:\-]?\s*(\d{4})",
}


def extract_text_from_pdf(path: str) -> str:
    """Read text from a PDF file using PyMuPDF.

    Args:
        path: Filesystem path to the PDF.

    Returns:
        All text from the document concatenated.
    """
    text = []
    with fitz.open(path) as doc:
        for page in doc:
            text.append(page.get_text())
    return "\n".join(text)


def extract_property_info(path: str) -> Tuple[Dict[str, str], Dict[str, str]]:
    """Extract property and broker data from an OM PDF.

    Args:
        path: Filesystem path to the OM PDF.

    Returns:
        (property_data, broker_data): Two dictionaries containing
        extracted fields. Missing values are set to empty strings.
    """
    logger.info("Extracting property information from %s", path)
    text = extract_text_from_pdf(path)
    property_data: Dict[str, str] = {}
    broker_data: Dict[str, str] = {}

    # Extract property-level fields using regex patterns
    for field, pattern in FIELD_PATTERNS.items():
        match = re.search(pattern, text)
        property_data[field] = match.group(1).replace(",", "") if match else ""

    # Attempt to extract property name as the first capitalized phrase
    property_name_match = re.search(r"(?m)^([A-Z][\w\s]+)$", text)
    property_data["property_name"] = (
        property_name_match.group(1).strip() if property_name_match else ""
    )

    # Attempt to find broker contact details (name, company, email, phone)
    # These patterns are simplistic; adjust as needed for your OMs.
    broker_name_match = re.search(r"(?i)broker\s*[:\-]?\s*([A-Za-z ,]+)", text)
    broker_company_match = re.search(r"(?i)company\s*[:\-]?\s*([A-Za-z ,]+)", text)
    broker_email_match = re.search(r"[\w.+-]+@\w+\.\w+", text)
    broker_phone_match = re.search(r"(?:(?:\+?\d{1,2}\s*)?(?:\(\d{3}\)|\d{3})[\s.-]?\d{3}[\s.-]?\d{4})", text)

    broker_data["broker_name"] = (
        broker_name_match.group(1).strip() if broker_name_match else ""
    )
    broker_data["broker_company"] = (
        broker_company_match.group(1).strip() if broker_company_match else ""
    )
    broker_data["broker_email"] = (
        broker_email_match.group(0).strip() if broker_email_match else ""
    )
    broker_data["broker_phone"] = (
        broker_phone_match.group(0).strip() if broker_phone_match else ""
    )

    # Additional fields could be extracted with AI services here
    return property_data, broker_data


__all__ = ["extract_property_info"]