"""
Rent Roll Extraction Agent.

This agent parses tenant information from rent roll spreadsheets. It
supports Excel (XLSX) and CSV formats and returns a list of tenant
records ready for insertion into the `tenants` table in Supabase.

The extraction assumes that the first row of the sheet contains
headers. Column names are matched loosely and case‑insensitively to
standard rent roll fields. If your rent roll uses different column
names, update the `COLUMN_MAP` accordingly.
"""

from __future__ import annotations

import logging
from typing import Dict, List

import pandas as pd

logger = logging.getLogger(__name__)


# Mapping from expected column names (lowercase) to our canonical keys
COLUMN_MAP = {
    "tenant": "tenant",
    "tenant name": "tenant",
    "suite": "suite",
    "unit": "suite",
    "monthly rent": "monthly_rent",
    "monthly_rental_rate": "monthly_rent",
    "annual rent": "annual_rent",
    "lease start": "lease_start",
    "lease commencement": "lease_start",
    "lease end": "lease_end",
    "lease expiration": "lease_end",
    "options": "options",
    "occupancy status": "occupancy_status",
}


def extract_tenants(path: str) -> List[Dict[str, str]]:
    """Extract tenant data from a rent roll spreadsheet.

    Args:
        path: Path to the rent roll file (XLSX or CSV).

    Returns:
        A list of dictionaries representing tenant records.
    """
    logger.info("Extracting tenants from %s", path)
    # Read spreadsheet into pandas DataFrame
    if path.lower().endswith(".csv"):
        df = pd.read_csv(path)
    else:
        df = pd.read_excel(path)

    # Normalize column names
    normalized_columns = {
        col: COLUMN_MAP.get(col.strip().lower(), None) for col in df.columns
    }
    tenants: List[Dict[str, str]] = []
    for _, row in df.iterrows():
        tenant_record: Dict[str, str] = {}
        for col, canonical_key in normalized_columns.items():
            if canonical_key:
                value = row[col]
                # Convert pandas NaN/NaT to empty string
                if pd.isna(value):
                    value = ""
                tenant_record[canonical_key] = str(value).strip()
        if tenant_record:
            tenants.append(tenant_record)
    return tenants


__all__ = ["extract_tenants"]