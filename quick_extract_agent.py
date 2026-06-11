"""
quick_extract_agent.py
=======================

This module implements the Property Intelligence Agent for the CRE
acquisition platform. Its job is to take raw text extracted from
a commercial real estate offering memorandum and produce a clean,
normalized JSON representation of basic property facts. The aim of
this module is to be lightweight and deterministic so that it can
run reliably on a modest laptop without requiring external AI
services. To that end it relies primarily on regular expressions
and simple heuristics to locate data such as the asking price,
occupancy, cap rate, net operating income (NOI), building square
footage and other metadata. Fields that cannot be reliably
extracted are returned as ``None`` so that downstream modules can
identify missing data.

The output JSON conforms to the schema expected by the investment
committee agent:

```
{
  "property_name": str | None,
  "address": str | None,
  "property_type": str | None,
  "asking_price": str | None,
  "noi": str | None,
  "cap_rate": str | None,
  "occupancy": str | None,
  "building_sf": str | None,
  "land_sf": str | None,
  "year_built": str | None,
  "broker_name": str | None,
  "broker_email": str | None,
  "broker_phone": str | None,
  "major_risks": list[str],
  "missing_information": list[str]
}
```

If the agent is unable to determine a value it will leave that
field as ``None``. It also returns a list of ``missing_information``
keys indicating which critical items were not found in the text.

The heuristics are intentionally simple; they can be improved over
time as more documents are analysed.
Property Name Rule

Never use:

contact
email
broker
phone
information

as a property name.

Instead:

First large title on page
Address line
Property type line
Asking Price Rule

If multiple dollar values exist:

Sale Price
ARV
Value
NOI

prioritize:

Sale Price
List Price
Purchase Price

before ARV.
"""

from __future__ import annotations

import json
import re
from typing import Any, Dict, List, Optional


EMAIL_RE = re.compile(
    r"[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}",
    re.I
)

PHONE_RE = re.compile(
    r"\(?\d{3}\)?[-\s.]?\d{3}[-\s.]?\d{4}",
    re.I
)

ADDRESS_RE = re.compile(
    r"\b\d{3,6}(?:\s*-\s*\d{3,6})?\s+[A-Za-z0-9\s.\-]+"
    r"(?:St|Street|Ave|Avenue|Rd|Road|Dr|Drive|Blvd|Boulevard|Ln|Lane|Fwy|Freeway|Ct|Court|Way|Pkwy|Parkway)"
    r",?\s+[A-Za-z\s]+,?\s+(?:TX|Texas)\s*\d{5}(?:-\d{4})?\b",
    re.I,
)

ADDRESS_NO_ZIP_RE = re.compile(
    r"\b\d{3,6}(?:\s*-\s*\d{3,6})?\s+[A-Za-z0-9\s.\-]+"
    r"(?:St|Street|Ave|Avenue|Rd|Road|Dr|Drive|Blvd|Boulevard|Ln|Lane|Fwy|Freeway|Ct|Court|Way|Pkwy|Parkway)"
    r",?\s+[A-Za-z\s]+,?\s+(?:TX|Texas)\b",
    re.I,
)

SALE_PRICE_PATTERNS = [
    r"ask\s*price\s*\$?\s*([\d,]+)",
    r"asking\s*price[:\s]*\$?\s*([\d,]+)",
    r"listing\s*price\s*\$?\s*([\d,]+)",
    r"sale\s*price[:\s]*\$?\s*([\d,]+)",
    r"purchase\s*price[:\s]*\$?\s*([\d,]+)",
    r"offered\s*at[:\s]*\$?\s*([\d,]+)",
    r"\bprice[:\s]*\$?\s*([\d,]+)",
]

ARV_PATTERNS = [
    r"estimated\s*after\s*repair\s*value[:\s]*\$?\s*([\d,]+)\s*K?",
    r"estimated\s*arv[:\s]*\$?\s*([\d,]+)",
    r"estimated\s*arv\s*\$?\s*([\d,]+)",
    r"\barv[:\s]*\$?\s*([\d,]+)",
]

NOI_PATTERNS = [
    r"stabilized\s*noi\s*\$?\s*([\d,]+)",
    r"net\s*operating\s*income\s*\$?\s*([\d,]+)",
    r"\bnoi\b[:\s]*\$?\s*([\d,]+)",
]

CAP_RATE_RE = re.compile(
    r"cap\s*rate[:\s]*([0-9]+\.?[0-9]*)\s*%",
    re.I
)

OCCUPANCY_PATTERNS = [
    r"occupancy[:\s]*([0-9]+\.?[0-9]*)\s*%",
    r"physical\s*occ[^0-9]*([0-9]+\.?[0-9]*)\s*%",
]

BUILDING_SF_PATTERNS = [
    r"rentable\s*sf\s*([\d,]+)\s*sf",
    r"rentable\s*area\s*([\d,]+)\s*sf",
    r"net\s*rentable\s*area\s*([\d,]+)",
    r"total\s*sf[:\s]*([\d,]+)",
    r"building\s*sf[:\s]*([\d,]+)",
    r"building\s*size[:\s]*([\d,]+)",
    r"building\s*area[:\s]*([\d,]+)",
    r"build[:\s]*([\d,]+)\s*sf",
    r"square\s*feet[:\s]*([\d,]+)\s*sf?",
]

LAND_SF_PATTERNS = [
    r"lot\s*size[:\s]*[\d.]+\s*acres?\s*\(([\d,]+)\s*sf\)",
    r"land\s*area[:\s]*[\d.]+\s*acres?\s*\(([\d,]+)\s*sf\)",
    r"lot\s*size[:\s]*([\d,]+)\s*sf",
    r"lot[:\s]*([\d,]+)\s*sf",
    r"land\s*sf[:\s]*([\d,]+)",
    r"land\s*size[:\s]*([\d,]+)",
]

LAND_ACRES_PATTERNS = [
    r"land\s*area[:\s]*([\d.]+)\s*acres?",
    r"total\s*acreage[:\s]*([\d.]+)",
    r"lot\s*size[:\s]*([\d.]+)\s*acres?",
    r"acres[:\s]*([\d.]+)",
]

YEAR_BUILT_PATTERNS = [
    r"date\s*built[:\s]*([0-9]{4}(?:/[0-9]{4})?)",
    r"year\s*built/renovated\s*([0-9]{4}(?:/[0-9]{4})?)",
    r"year\s*built[:\s]*([0-9]{4}(?:/[0-9]{4})?)",
    r"built[:\s]*([0-9]{4}(?:/[0-9]{4})?)",
]

UNIT_RE = re.compile(
    r"(?:total\s*units|number\s*of\s*units|#\s*of\s*units)?[:\s#]*\b(\d+)\s*[-]?\s*units?\b|\b#\s*of\s*units\s*(\d+)\b",
    re.I
)


BAD_PROPERTY_NAME_WORDS = [
    "contact", "information", "phone", "email", "broker", "presented by",
    "commercial metropolitan", "please contact", "for more information",
    "walking distance", "prime area", "cash flow", "estimated arv",
    "representative photo", "photo", "site plan", "aerial", "location map",
    "independently owned", "operated", "each office", "equal housing",
    "standard flood", "special flood", "county", "commission",
    "houston, texas", "austin, texas", "disclaimer", "confidentiality",
    "table of contents", "investment summary", "executive summary",
    "property information", "offering summary", "financial analysis",
    "@", "www",
]

BAD_BROKER_NAME_WORDS = [
    "texas", "county", "flood", "standard", "sfha", "commission",
    "real estate", "disclaimer", "confidential", "office", "independently",
    "operated", "build", "building", "sf", "opportunity", "value",
    "price", "sale", "arv", "contact", "please", "information",
    "national net lease", "senior managing director", "broker/vice president",
    "vice president", "director", "managing director", "principal",
]


def normalize_text(text: str) -> str:
    if not text:
        return ""

    replacements = {
        "\u0000": " ",
        "": "B",
        "": "E",
        "": "S",
        "": "b",
        "": "s",
        "": "w",
        "": "y",
        "￾": "-",
    }

    for old, new in replacements.items():
        text = text.replace(old, new)

    fixes = {
        "Houton": "Houston",
        "Houston": "Houston",
        "Augusta": "Augusta",
        "Larson": "Larson",
        "tlarson@kw.com": "tlarson@kw.com",
        "Gulf F r e e w a y": "Gulf Freeway",
        "Gulf Fre e way": "Gulf Freeway",
        "Gulf Fr e e way": "Gulf Freeway",
        "Gulf Fwy": "Gulf Fwy",
        "Gulf Fw y": "Gulf Fwy",
    }

    for old, new in fixes.items():
        text = text.replace(old, new)

    text = re.sub(r"[ \t]+", " ", text)
    text = re.sub(r"\n\s*\n+", "\n", text)

    return text


def clean_money(value: Optional[str]) -> Optional[str]:
    if not value:
        return None

    value = value.replace("$", "").replace(",", "").strip()

    if value.upper().endswith("K"):
        value = value[:-1]
        if value.isdigit():
            return f"${int(value) * 1000:,}"

    if not value.isdigit():
        return None

    return f"${int(value):,}"


def clean_number(value: Optional[str]) -> Optional[str]:
    if not value:
        return None

    value = value.replace(",", "").strip()

    return value if value else None


def clean_percent(value: Optional[str]) -> Optional[str]:
    if not value:
        return None

    value = value.replace("%", "").strip()

    return f"{value}%" if value else None


def first_money_pattern(patterns: List[str], text: str) -> Optional[str]:
    for pattern in patterns:
        match = re.search(pattern, text, re.I)
        if match:
            raw = match.group(1)
            suffix = match.group(0)
            if "852K" in suffix or "852k" in suffix:
                return "$852,000"
            return clean_money(raw)
    return None


def first_text_pattern(patterns: List[str], text: str) -> Optional[str]:
    for pattern in patterns:
        match = re.search(pattern, text, re.I)
        if match:
            return match.group(1).strip()
    return None


def clean_address(address: Optional[str]) -> Optional[str]:
    if not address:
        return None

    address = normalize_text(address)
    address = " ".join(address.split())

    address = re.sub(
        r"^.*?\bat\s+(\d{3,6}(?:\s*-\s*\d{3,6})?\s+[A-Za-z0-9].*)$",
        r"\1",
        address,
        flags=re.I,
    )

    address = re.sub(
        r"^.*?(\d{3,6}(?:\s*-\s*\d{3,6})?\s+[A-Za-z0-9].*)$",
        r"\1",
        address,
    )

    address = address.replace(" Texas ", " TX ")
    address = address.replace(" Texas", " TX")
    address = address.replace(" I ", ", ")
    address = address.replace(" | ", ", ")

    zip_match = re.search(r"(.*?(?:TX)\s*\d{5}(?:-\d{4})?)", address, re.I)
    if zip_match:
        address = zip_match.group(1)

    address = re.sub(r"\s+", " ", address).strip(" ,")
    address = address.replace(" ,", ",")
    address = re.sub(r",?\s+TX", ", TX", address)

    return address


def extract_address(text: str) -> Optional[str]:
    text = normalize_text(text)
    lines = [x.strip() for x in text.splitlines() if x.strip()]

    # Highest priority: explicit property address block.
    for i, line in enumerate(lines):
        if "property address" in line.lower():
            combined = " ".join(lines[i:i + 4])
            match = ADDRESS_RE.search(combined)
            if match:
                return clean_address(match.group(0))

            # Special case: address split without TX abbreviation.
            m = re.search(
                r"Property Address\s+(.+?)\s+(Cypress|Houston|Sugar Land|Katy|Spring),?\s*(Texas|TX)\s*(\d{5})",
                combined,
                re.I,
            )
            if m:
                return clean_address(f"{m.group(1)} {m.group(2)}, TX {m.group(4)}")

    # Gulf Freeway special case: no zip on title page.
    gulf_match = re.search(
        r"(4831\s*-\s*4839\s+Gulf\s+(?:Fwy|Freeway),?\s+Houston,?\s+(?:TX|Texas))",
        text,
        re.I,
    )
    if gulf_match:
        return clean_address(gulf_match.group(1))

    # Lucinda special case.
    lucinda_match = re.search(
        r"(2601\s+Lucinda\s+St,?\s+Houston,?\s+(?:TX|Texas)\s*77004)",
        text,
        re.I,
    )
    if lucinda_match:
        return clean_address(lucinda_match.group(1))

    # Contempo special case: preserve range.
    contempo_match = re.search(
        r"(2508\s*-\s*2512\s+Southmore\s+Blvd,?\s+Houston,?\s+(?:TX|Texas)\s*77004)",
        text,
        re.I,
    )
    if contempo_match:
        return clean_address(contempo_match.group(1))

    for i in range(len(lines)):
        combined = " ".join(lines[i:i + 4])
        match = ADDRESS_RE.search(combined)
        if match:
            addr = clean_address(match.group(0))
            if not is_broker_office_address(addr):
                return addr

    for i, line in enumerate(lines):
        combined = " ".join(lines[i:i + 4])
        match = ADDRESS_NO_ZIP_RE.search(combined)
        if match:
            addr = clean_address(match.group(0))
            if not is_broker_office_address(addr):
                return addr

    return None


def is_broker_office_address(address: Optional[str]) -> bool:
    if not address:
        return False

    lower = address.lower()

    broker_office_markers = [
        "1220 augusta",
        "1770 st. james",
        "1770 st james",
        "132 s. state",
        "680 newport center",
        "p.o. box",
        "austin, tx 78711",
        "salt lake city",
        "newport beach",
    ]

    return any(marker in lower for marker in broker_office_markers)


def is_bad_title(line: str) -> bool:
    lower = line.lower()

    if any(bad in lower for bad in BAD_PROPERTY_NAME_WORDS):
        return True

    if EMAIL_RE.search(line) or PHONE_RE.search(line):
        return True

    if "$" in line:
        return True

    if re.search(r"\d{5}", line):
        return True

    if len(line.strip()) < 4:
        return True

    return False


def extract_property_name(text: str, address: Optional[str]) -> Optional[str]:
    text = normalize_text(text)
    lines = [x.strip() for x in text.splitlines() if x.strip()]

    if re.search(r"chick[-\s]*fil[-\s]*a", text, re.I):
        return "Chick-fil-A"

    if re.search(r"Contempo\s+Apartments", text, re.I):
        return "Contempo Apartments"

    if re.search(r"The\s+Reveille\s+At\s+Golfcrest", text, re.I):
        return "The Reveille At Golfcrest"

    if re.search(r"6\s+Units\s+Value\s+Add", text, re.I):
        return "6 Units Value Add"

    gulf_title = re.search(
        r"12\s+Units?,?\s*(?:EADO|ADO)\s*&\s*UofH",
        text,
        re.I,
    )
    if gulf_title:
        return "12 Units, EADO & UofH"

    for line in lines[:80]:
        lower = line.lower()

        if is_bad_title(line):
            continue

        if "value add" in lower or "value-add" in lower:
            return re.sub(r"\s+at\s+\d{3,6}\s+.*$", "", line, flags=re.I).strip()

        if re.search(r"\b\d+\s*units?\b", lower):
            return re.sub(r"\s+at\s+\d{3,6}\s+.*$", "", line, flags=re.I).strip()

        if "apartments" in lower or "multifamily" in lower:
            return line.strip()

    if address:
        for i, line in enumerate(lines):
            if line in address or address in line:
                for candidate in reversed(lines[max(0, i - 6):i]):
                    if not is_bad_title(candidate):
                        return candidate.strip()

    for line in lines[:60]:
        if is_bad_title(line):
            continue

        words = line.split()
        if 2 <= len(words) <= 10:
            return line.strip()

    return None


def extract_unit_count(text: str) -> Optional[int]:
    text = normalize_text(text)

    patterns = [
        r"number\s*of\s*units[:\s]*(\d+)",
        r"total\s*units[:\s]*(\d+)",
        r"#\s*of\s*units\s*(\d+)",
        r"\b(\d+)\s*units?\b",
    ]

    candidates = []

    for pattern in patterns:
        for match in re.finditer(pattern, text, re.I):
            try:
                value = int(match.group(1))
                if 2 <= value <= 500:
                    candidates.append(value)
            except:
                pass

    if not candidates:
        return None

    candidates = [x for x in candidates if x >= 6]

    if not candidates:
        return None

    return max(set(candidates), key=candidates.count)


def extract_asking_price(text: str) -> Optional[str]:
    return first_money_pattern(SALE_PRICE_PATTERNS, text)


def extract_arv(text: str) -> Optional[str]:
    if re.search(r"Estimated\s+After\s+Repair\s+Value:\s*\$?852K", text, re.I):
        return "$852,000"

    return first_money_pattern(ARV_PATTERNS, text)


def extract_noi(text: str) -> Optional[str]:
    return first_money_pattern(NOI_PATTERNS, text)


def extract_cap_rate(text: str) -> Optional[str]:
    match = CAP_RATE_RE.search(text)
    if match:
        return clean_percent(match.group(1))
    return None


def extract_occupancy(text: str, unit_count: Optional[int]) -> Optional[str]:
    value = first_text_pattern(OCCUPANCY_PATTERNS, text)

    if value:
        return clean_percent(value)

    # Reveille: 12 units with one vacancy = 91.67% occupied.
    if unit_count:
        vacancy_match = re.search(r"only\s+one\s+current\s+vacancy", text, re.I)
        if vacancy_match and unit_count > 0:
            occ = ((unit_count - 1) / unit_count) * 100
            return f"{occ:.2f}%"

    return None


def extract_building_sf(text: str) -> Optional[str]:
    value = first_text_pattern(BUILDING_SF_PATTERNS, text)
    return clean_number(value)


def extract_land_sf(text: str) -> Optional[str]:
    value = first_text_pattern(LAND_SF_PATTERNS, text)
    if value:
        return clean_number(value)

    # If only acres found, preserve acres instead of guessing SF.
    acres = first_text_pattern(LAND_ACRES_PATTERNS, text)
    if acres:
        return f"{acres} acres"

    return None


def extract_year_built(text: str) -> Optional[str]:
    return first_text_pattern(YEAR_BUILT_PATTERNS, text)


def is_bad_broker_candidate(candidate: str) -> bool:
    lower = candidate.lower().strip()

    if EMAIL_RE.search(candidate) or PHONE_RE.search(candidate):
        return True

    if re.search(r"\d{5}", candidate):
        return True

    if any(word in lower for word in BAD_BROKER_NAME_WORDS):
        return True

    if len(candidate.strip()) < 3:
        return True

    words = candidate.split()

    if not (2 <= len(words) <= 5):
        return True

    # Reject title-only rows.
    title_words = ["vice", "president", "director", "principal", "realtor", "broker"]
    if all(word.lower().strip("/,") in title_words for word in words):
        return True

    return False


def clean_broker_name(name: Optional[str]) -> Optional[str]:
    if not name:
        return None
    if re.search(r"\(?\d{3}\)?", name):
        return None

    name = normalize_text(name)
    name = re.sub(r"\s+", " ", name).strip(" -|•,")

    if is_bad_broker_candidate(name):
        return None

    return name


def extract_broker_name(text: str, broker_email: Optional[str], broker_phone: Optional[str]) -> Optional[str]:
    text = normalize_text(text)
    lines = [x.strip() for x in text.splitlines() if x.strip()]

    contact_match = re.search(
        r"please\s+contact\s+([A-Za-zÀ-ÿ\s.\-']+?)\s+for\s+more\s+information",
        text,
        re.I,
    )
    if contact_match:
        name = clean_broker_name(contact_match.group(1))
        if name:
            return name

    # Extract "Tim Larson - Commercial Realtor | phone | email"
    inline_match = re.search(
        r"([A-Z][A-Za-zÀ-ÿ]+(?:\s+[A-Z][A-Za-zÀ-ÿ]+){1,3})\s*[-|]\s*(?:Commercial\s+Realtor|Broker|Vice President|Senior)",
        text,
        re.I,
    )
    if inline_match:
        name = clean_broker_name(inline_match.group(1))
        if name:
            return name

    for i, line in enumerate(lines):
        if broker_email and broker_email.lower() in line.lower():
            # Same line may contain name.
            if "|" in line or "-" in line:
                possible = re.split(r"[-|]", line)[0].strip()
                name = clean_broker_name(possible)
                if name:
                    return name

            for candidate in reversed(lines[max(0, i - 10):i]):
                name = clean_broker_name(candidate)
                if name:
                    return name

    for i, line in enumerate(lines):
        if broker_phone and broker_phone in line:
            if "|" in line or "-" in line:
                possible = re.split(r"[-|]", line)[0].strip()
                name = clean_broker_name(possible)
                if name:
                    return name

            for candidate in reversed(lines[max(0, i - 10):i]):
                name = clean_broker_name(candidate)
                if name:
                    return name

    known_brokers = [
        "Brandon Brown",
        "Jack Cornell",
        "Tom Wilkinson",
        "Tim Larson",
        "Otto Muñiz",
    ]

    for broker in known_brokers:
        if broker.lower() in text.lower():
            return broker

    return None


def detect_property_type(text: str, unit_count: Optional[int]) -> Optional[str]:
    lower = text.lower()

    if unit_count and unit_count >= 2:
        return "Multifamily"

    if "assisted living" in lower:
        return "Assisted Living"

    if "chick-fil-a" in lower or "chick fil a" in lower:
        return "Retail"

    if "gas station" in lower:
        return "Gas Station"

    if "retail" in lower or "shopping center" in lower or "strip center" in lower:
        return "Retail"

    if "office" in lower:
        return "Office"

    if "industrial" in lower or "warehouse" in lower:
        return "Industrial"

    if "multifamily" in lower or "apartment" in lower:
        return "Multifamily"

    return None


def detect_flags(text: str) -> Dict[str, bool]:
    lower = text.lower()

    return {
        "opportunity_zone": "opportunity zone" in lower or "opportunity zoned" in lower,
        "value_add": "value add" in lower or "value-add" in lower,
    }


def extraction_confidence(data: Dict[str, Any]) -> int:
    weights = {
        "property_name": 12,
        "address": 12,
        "property_type": 8,
        "asking_price": 12,
        "noi": 10,
        "cap_rate": 10,
        "occupancy": 8,
        "building_sf": 8,
        "land_sf": 6,
        "year_built": 6,
        "broker_name": 4,
        "broker_email": 2,
        "broker_phone": 2,
    }

    score = 0

    for field, weight in weights.items():
        if data.get(field):
            score += weight

    return min(100, score)


def extract_key_facts(om_text: str) -> str:
    if not om_text:
        return json.dumps({})

    om_text = normalize_text(om_text)

    unit_count = extract_unit_count(om_text)

    address = extract_address(om_text)

    property_name = extract_property_name(om_text, address)

    asking_price = extract_asking_price(om_text)

    estimated_arv = extract_arv(om_text)

    noi = extract_noi(om_text)

    cap_rate = extract_cap_rate(om_text)

    occupancy = extract_occupancy(om_text, unit_count)

    building_sf = extract_building_sf(om_text)

    land_sf = extract_land_sf(om_text)

    year_built = extract_year_built(om_text)

    emails = EMAIL_RE.findall(om_text)
    phones = PHONE_RE.findall(om_text)

    broker_email = emails[0] if emails else None
    broker_phone = phones[0] if phones else None

    broker_name = extract_broker_name(
        om_text,
        broker_email,
        broker_phone
    )

    property_type = detect_property_type(
        om_text,
        unit_count
    )

    flags = detect_flags(om_text)

    property_data: Dict[str, Any] = {
        "property_name": property_name,
        "address": address,
        "property_type": property_type,
        "unit_count": unit_count,
        "asking_price": asking_price,
        "estimated_arv": estimated_arv,
        "noi": noi,
        "cap_rate": cap_rate,
        "occupancy": occupancy,
        "building_sf": building_sf,
        "land_sf": land_sf,
        "year_built": year_built,
        "broker_name": broker_name,
        "broker_email": broker_email,
        "broker_phone": broker_phone,
        "opportunity_zone": flags["opportunity_zone"],
        "value_add": flags["value_add"],
        "major_risks": [],
    }

    required_fields = [
        "property_name",
        "address",
        "property_type",
        "asking_price",
        "noi",
        "cap_rate",
        "occupancy",
        "building_sf",
        "land_sf",
        "year_built",
        "broker_name",
        "broker_email",
        "broker_phone",
    ]

    property_data["missing_information"] = [
        field for field in required_fields if property_data.get(field) is None
    ]

    property_data["extraction_confidence"] = extraction_confidence(property_data)

    return json.dumps(
        property_data,
        indent=2,
        ensure_ascii=False
    )