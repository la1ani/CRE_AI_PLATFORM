from __future__ import annotations

import re
from datetime import datetime
from decimal import Decimal, InvalidOperation
from typing import Any

from .models import ProfileExtraction

MONEY_MULTIPLIERS = {"K": 1_000, "M": 1_000_000, "B": 1_000_000_000}


def normalize_money(value: str | None) -> int | None:
    if not value:
        return None
    cleaned = value.upper().replace("$", "").replace(",", "").strip()
    match = re.search(r"(-?\d+(?:\.\d+)?)\s*([KMB])?", cleaned)
    if not match:
        return None
    try:
        number = Decimal(match.group(1))
    except InvalidOperation:
        return None
    return int(number * MONEY_MULTIPLIERS.get(match.group(2) or "", 1))


def normalize_percent(value: str | None) -> float | None:
    if not value:
        return None
    match = re.search(r"-?\d+(?:\.\d+)?", value.replace(",", ""))
    return float(match.group(0)) if match else None


def normalize_date(value: str | None) -> str | None:
    if not value:
        return None
    for fmt in ("%m/%d/%Y", "%m/%d/%y", "%Y-%m-%d"):
        try:
            return datetime.strptime(value.strip(), fmt).date().isoformat()
        except ValueError:
            continue
    return None


def profile_key(extraction: ProfileExtraction) -> str:
    identity = extraction.identity
    if identity.email:
        return identity.email.strip().lower()
    name = re.sub(r"[^a-z0-9]+", "-", (identity.realtor_name or "unknown").lower()).strip("-")
    company = re.sub(r"[^a-z0-9]+", "-", (identity.brokerage or "unknown").lower()).strip("-")
    return f"{name}:{company}"


def master_row(extraction: ProfileExtraction, metadata: dict[str, Any], validation: dict[str, Any]) -> dict[str, Any]:
    identity = extraction.identity
    performance = extraction.performance
    relationships = extraction.relationships
    top_lo = relationships.loan_officer_relationships[0] if relationships.loan_officer_relationships else None
    top_company = relationships.loan_company_relationships[0] if relationships.loan_company_relationships else None
    return {
        "Profile Key": profile_key(extraction),
        "Name": identity.realtor_name or "",
        "Brokerage": identity.brokerage or "",
        "Email": identity.email or "",
        "Phone": identity.phone or "",
        "Languages": ", ".join(identity.languages),
        "Source File": metadata["source_file"],
        "Source Hash": metadata["source_hash"],
        "12M Volume": normalize_money(performance.total.volume_raw) or normalize_money(identity.transaction_volume_raw),
        "Total Sides": performance.total.sides,
        "Buyer Sides": performance.buyer_side.sides,
        "Seller Sides": performance.seller_side.sides,
        "Loan Count": identity.loan_count or relationships.reported_total_loans,
        "LOs Used": identity.loan_officers_used or relationships.reported_loan_officers_used,
        "Companies Used": relationships.reported_companies_used,
        "Top LO": top_lo.loan_officer_name if top_lo else "",
        "Top LO Share": normalize_percent(top_lo.relationship_percent_raw) if top_lo else None,
        "Top Loan Company": top_company.company if top_company else "",
        "Top Company Share": normalize_percent(top_company.relationship_percent_raw) if top_company else None,
        "Listings Visible": len(extraction.extras.recent_listings),
        "Transactions Visible": len(extraction.transactions.rows),
        "Transactions Expected": extraction.transactions.expected_entries,
        "Loan Rows Visible": len(extraction.loan_details.rows),
        "Loan Rows Expected": extraction.loan_details.expected_entries,
        "Extraction Status": validation["status"],
        "Validation Score": validation["score"],
        "Last Scanned": metadata["scanned_at"],
    }
