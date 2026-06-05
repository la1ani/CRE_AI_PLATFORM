from __future__ import annotations

import json
import re
from typing import Any, Dict, List, Optional


TENANT_NAMES = [
    "BrewingZ",
    "Centrum Health",
    "Master Lease",
    "Royalty Smoke N Vape",
    "Royalty Smoke",
    "Café Petra",
    "Cafe Petra",
    "Sport Clips",
    "T-Mobile",
    "Meta Dental",
    "Pearland Eye Care",
    "Palace Nails",
    "Alliance Martial Arts",
    "Little Caesars Pizza",
    "Little Caesars",
    "La Monarca Michoacana",
    "La Monarca",
    "World Finance",
    "Kids Empire",
    "Neighbours Liquor",
    "Neighbors Liquor",
    "BPS Stores LLC",
    "BPS Stores",
    "Smoke & Vape",
    "Le Refresqueria",
    "Lease Pending",
    "Vacant",
]


def clean_line(line: str) -> str:
    line = line.replace("±", "")
    line = re.sub(r"\s+", " ", line)
    return line.strip()


def money_values(line: str) -> List[str]:
    return re.findall(r"\$[\d,]+(?:\.\d+)?", line)


def date_values(line: str) -> List[str]:
    return re.findall(r"\d{1,2}/\d{1,2}/\d{2,4}", line)


def percent_values(line: str) -> List[str]:
    return re.findall(r"\d+(?:\.\d+)?%", line)


def clean_number(value: Optional[str]) -> Optional[str]:
    if not value:
        return None
    return value.replace(",", "").strip()


def find_rent_roll_section(text: str) -> str:
    lower = text.lower()

    start_terms = [
        "proforma rent roll",
        "rent roll",
        "tenant rental",
        "tenant info lease terms",
    ]

    end_terms = [
        "lease abstract",
        "tenant overview",
        "financial summary",
        "market overview",
        "property photos",
        "lease expiration schedule",
        "tenant overview",
    ]

    start = -1

    for term in start_terms:
        idx = lower.find(term)
        if idx != -1:
            start = idx
            break

    if start == -1:
        return ""

    end = len(text)

    for term in end_terms:
        idx = lower.find(term, start + 100)
        if idx != -1:
            end = min(end, idx)

    return text[start:end]


def detect_format(section: str) -> str:
    lower = section.lower()

    if "monthly gross" in lower and "annual base rent" in lower:
        return "boulder"

    if "tenant info" in lower and "rent summary" in lower:
        return "clearwood"

    if "unit #" in lower and "fixed cam" in lower:
        return "las_palmas"

    if "rent psf" in lower and "monthly rent" in lower:
        return "las_palmas"

    return "generic"


def parse_boulder_row(line: str, tenant: str) -> Optional[Dict[str, Any]]:
    dates = date_values(line)
    money = money_values(line)
    percents = percent_values(line)

    sf_match = re.search(rf"{re.escape(tenant)}\s+([\d,]+)\s+\d", line, re.I)
    sf = clean_number(sf_match.group(1)) if sf_match else None

    if not sf or len(money) < 4:
        return None

    return {
        "tenant_name": tenant,
        "suite": None,
        "sf": sf,
        "percent_gla": percents[0] if percents else None,
        "lease_start": dates[0] if len(dates) >= 1 else None,
        "lease_end": dates[1] if len(dates) >= 2 else None,
        "monthly_rent": money[-3] if len(money) >= 3 else None,
        "annual_rent": money[-1],
        "rent_psf": money[0],
        "lease_type": "NNN",
        "renewal_options": None,
        "confidence": 90,
        "raw_row": line,
    }


def parse_clearwood_row(line: str, tenant: str) -> Optional[Dict[str, Any]]:
    dates = date_values(line)
    money = money_values(line)
    percents = percent_values(line)

    # Example:
    # Little Caesars Pizza 100 1,618 10.26% 03/29/17 03/31/32 $4,530 $54,365 $33.60
    after = re.sub(re.escape(tenant), "", line, count=1, flags=re.I).strip()
    nums = re.findall(r"\b[\d,]{1,7}\b", after)

    suite = nums[0] if len(nums) >= 1 else None
    sf = clean_number(nums[1]) if len(nums) >= 2 else None

    if not sf or len(money) < 2:
        return None

    return {
        "tenant_name": tenant,
        "suite": suite,
        "sf": sf,
        "percent_gla": percents[0] if percents else None,
        "lease_start": dates[0] if len(dates) >= 1 else None,
        "lease_end": dates[1] if len(dates) >= 2 else None,
        "monthly_rent": money[0] if len(money) >= 1 else None,
        "annual_rent": money[1] if len(money) >= 2 else None,
        "rent_psf": money[2] if len(money) >= 3 else None,
        "lease_type": None,
        "renewal_options": None,
        "confidence": 90,
        "raw_row": line,
    }


def parse_las_palmas_row(line: str, tenant: str) -> Optional[Dict[str, Any]]:
    dates = date_values(line)
    money = money_values(line)
    percents = percent_values(line)

    suite_match = re.search(r"^(\d{2,5})\s+", line)
    suite = suite_match.group(1) if suite_match else None

    sf_match = re.search(rf"{re.escape(tenant)}\s+([\d,]+)", line, re.I)
    sf = clean_number(sf_match.group(1)) if sf_match else None

    if not suite or not sf:
        return None

    return {
        "tenant_name": tenant,
        "suite": suite,
        "sf": sf,
        "percent_gla": percents[0] if percents else None,
        "lease_start": dates[0] if len(dates) >= 1 else None,
        "lease_end": dates[1] if len(dates) >= 2 else None,
        "monthly_rent": money[-1] if len(money) >= 1 else None,
        "annual_rent": money[0] if len(money) >= 1 else None,
        "rent_psf": money[1] if len(money) >= 2 else None,
        "lease_type": "Fixed CAM" if "fixed cam" in line.lower() else None,
        "renewal_options": None,
        "confidence": 90,
        "raw_row": line,
    }


def is_real_rent_roll_line(line: str) -> bool:
    lower = line.lower()

    bad_words = [
        "table of contents",
        "executive summary",
        "financial summary",
        "lease abstract",
        "market overview",
        "property overview",
        "property photos",
        "confidential",
        "offering memorandum",
        "broker",
        "disclaimer",
        "demographics",
        "population",
        "income exceeds",
        "traffic",
        "aerial",
        "site plan",
    ]

    if any(bad in lower for bad in bad_words):
        return False

    has_tenant = any(t.lower() in lower for t in TENANT_NAMES)
    has_money = bool(money_values(line))
    has_date = bool(date_values(line))
    has_sf_like_number = bool(re.search(r"\b[\d,]{3,7}\b", line))

    return has_tenant and (has_money or has_date or has_sf_like_number)


def extract_rent_roll(text: str) -> List[Dict[str, Any]]:
    section = find_rent_roll_section(text)

    if not section:
        return []

    fmt = detect_format(section)

    lines = [
        clean_line(x)
        for x in section.splitlines()
        if clean_line(x)
    ]

    rows: List[Dict[str, Any]] = []
    seen = set()

    for line in lines:
        if not is_real_rent_roll_line(line):
            continue

        for tenant in TENANT_NAMES:
            if tenant.lower() not in line.lower():
                continue

            if fmt == "boulder":
                row = parse_boulder_row(line, tenant)
            elif fmt == "clearwood":
                row = parse_clearwood_row(line, tenant)
            elif fmt == "las_palmas":
                row = parse_las_palmas_row(line, tenant)
            else:
                row = parse_clearwood_row(line, tenant)

            if not row:
                continue

            # Hard filter: do not save rows with no economic data.
            if not row.get("sf") and not row.get("annual_rent"):
                continue

            key = (
                row.get("tenant_name", "").lower(),
                row.get("suite"),
                row.get("sf"),
                row.get("lease_end"),
                row.get("annual_rent"),
            )

            if key in seen:
                continue

            seen.add(key)
            rows.append(row)
            break

    return rows


def extract_rent_roll_json(text: str) -> str:
    rows = extract_rent_roll(text)

    return json.dumps(
        {
            "rent_roll": rows,
            "tenant_count": len(rows),
        },
        indent=2,
        ensure_ascii=False,
    )