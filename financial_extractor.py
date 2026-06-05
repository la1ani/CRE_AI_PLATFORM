from __future__ import annotations

import json
import re
from typing import Dict, Optional

# NEW
from rent_roll_agent import extract_rent_roll


def money(pattern: str, text: str) -> Optional[str]:

    m = re.search(pattern, text, re.I)

    if not m:
        return None

    val = (
        m.group(1)
        .replace(",", "")
        .replace("$", "")
        .strip()
    )

    try:
        return f"${int(float(val)):,}"
    except:
        return None


def percent(pattern: str, text: str) -> Optional[str]:

    m = re.search(pattern, text, re.I)

    if not m:
        return None

    return f"{m.group(1)}%"


def extract_financial_summary(text: str) -> Dict:

    data = {
        "rental_income":
            money(
                r"rental income\s*\$?\s*([\d,]+)",
                text
            ),

        "recoveries":
            money(
                r"recoveries\s*\$?\s*([\d,]+)",
                text
            ),

        "other_income":
            money(
                r"other income\s*\$?\s*([\d,]+)",
                text
            ),

        "gross_income":
            money(
                r"(?:effective gross income|gross income|effective gross revenue|total income)\s*\$?\s*([\d,]+)",
                text
            ),

        "taxes":
            money(
                r"(?:real estate taxes|property taxes|taxes)\s*\$?\s*([\d,]+)",
                text
            ),

        "insurance":
            money(
                r"insurance\s*\$?\s*([\d,]+)",
                text
            ),

        "cam":
            money(
                r"\bcam\b\s*\$?\s*([\d,]+)",
                text
            ),

        "utilities":
            money(
                r"(?:utilities|water|electric)\s*\$?\s*([\d,]+)",
                text
            ),

        "management_fee":
            money(
                r"(?:management fee|property management fee)\s*\$?\s*([\d,]+)",
                text
            ),

        "total_expenses":
            money(
                r"(?:total operating expenses|total operating expense|total expenses)\s*\$?\s*([\d,]+)",
                text
            ),

        "noi":
            money(
                r"(?:net operating income|stabilized noi|noi)\s*\$?\s*([\d,]+)",
                text
            ),

        "cap_rate":
            percent(
                r"cap rate\s*([0-9]+\.?[0-9]*)\s*%",
                text
            ),

        "occupancy":
            percent(
                r"occupancy\s*([0-9]+\.?[0-9]*)\s*%",
                text
            ),
    }

    score = 0

    important_fields = [
        "gross_income",
        "total_expenses",
        "noi",
        "cap_rate",
        "rental_income",
        "taxes",
        "insurance",
    ]

    for field in important_fields:

        if data.get(field):
            score += 14

    data["confidence"] = min(score, 100)

    return data


def extract_financial_package(text: str) -> str:

    financial_summary = extract_financial_summary(text)

    # NEW RENT ROLL AGENT
    rent_roll = extract_rent_roll(text)

    package = {
        "financial_summary": financial_summary,
        "rent_roll": rent_roll,
        "tenant_count": len(rent_roll)
    }

    return json.dumps(
        package,
        indent=2,
        ensure_ascii=False
    )