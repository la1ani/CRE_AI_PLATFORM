from __future__ import annotations

import hashlib
import logging
import random
import re
import time
from dataclasses import dataclass
from datetime import datetime, timezone
from pathlib import Path
from typing import Any, Callable, TypeVar

import gspread
from google.oauth2.service_account import Credentials

from .normalizer import normalize_money

logger = logging.getLogger(__name__)
T = TypeVar("T")

SERVICE_ACCOUNT_SCOPES = [
    "https://www.googleapis.com/auth/spreadsheets",
    "https://www.googleapis.com/auth/drive",
]

REALTOR_HEADERS = [
    "Import Key", "Market", "Agent Display", "Realtor Name", "Brokerage", "Email", "Phone",
    "Buyer Sides", "Buyer Volume", "Seller Sides", "Seller Volume", "Total Sides", "Total Volume",
    "Loan Count", "LOs Used", "Conventional Count", "VA Count", "FHA Count", "Profile URL",
    "Screenshot Drive Link", "Source File", "Source Tab", "Source Row", "Imported At", "Notes",
]

LISTING_HEADERS = [
    "Listing Key", "Market", "Agent Display", "Realtor Name", "Brokerage", "Email", "Phone",
    "List Date", "List Price", "Open House", "Address", "Property Type", "Buyer Count 12M",
    "Buyer Volume 12M", "Loan Count 12M", "LOs Used 12M", "Source File", "Source Tab",
    "Source Row", "Imported At",
]

LO_HEADERS = [
    "Import Key", "Phone", "Rank", "Loan Officer Display", "Metric Count 1", "Metric Volume 1",
    "Metric Count 2", "Metric Count 3", "Metric Count 4", "Total Count", "Total Volume",
    "Average Loan", "Location", "Organization Type", "Source File", "Source Tab", "Source Row",
    "Imported At", "Notes", "Reserved",
]

SOURCE_LOG_HEADERS = [
    "Source Name", "Market / Type", "Spreadsheet ID", "Source Tab", "Import Type", "Source URL",
    "Service Account", "Access Status", "Notes",
]


@dataclass(frozen=True)
class DriveListSource:
    name: str
    market: str
    spreadsheet_id: str
    worksheet: str
    parser: str
    import_type: str

    @property
    def url(self) -> str:
        return f"https://docs.google.com/spreadsheets/d/{self.spreadsheet_id}/edit"


SOURCES = (
    DriveListSource(
        "final houston listing", "Houston", "1q-_27nN-T-YBMXe8zWb4dz3mJP__qWhUNfjJ_8uVD5g",
        "Sheet1", "final_houston", "Realtors + Listings",
    ),
    DriveListSource(
        "houston lisiting", "Houston", "1gBrnnGCm8DW_Crz1Tx1KHZ_sU6e66dr5EF0JhdoB9lA",
        "Sheet3", "houston_listing", "Listings",
    ),
    DriveListSource(
        "dallas listing", "Dallas listing source", "1De0OztGNoa5nAHUU6a6P_5QTyz-WeCsnMR7QAvqnQsc",
        "Sheet1", "dallas_listing", "Listings",
    ),
    DriveListSource(
        "austin", "Austin-Round Rock-San Marcos", "1dGlkibmhImarxYQwkxj7ZMD_VQDmSOFxrKawrt3lXWE",
        "Sheet1", "market_realtors", "Realtors",
    ),
    DriveListSource(
        "san antanio", "San Antonio-New Braunfels", "1r8W3Aj3fDCalvg0bEpcP4gCJOXpNcWOp_4XDeACwFzM",
        "Sheet1", "market_realtors", "Realtors",
    ),
    DriveListSource(
        "atlanta ga", "Atlanta-Sandy Springs-Roswell", "1lTyuNtoZixeDJKVt0nUyMD63H6fmAChG2jfuewhJBiQ",
        "Sheet1", "market_realtors", "Realtors",
    ),
    DriveListSource(
        "realtor", "Dallas-Fort Worth-Arlington", "1X2Pu6H3bI8HBWXUtSqv3014-ouxaw4_pwmXBzE9zPoM",
        "Sheet1", "market_realtors", "Realtors",
    ),
    DriveListSource(
        "relatorand lo", "Profile Queue", "15Ps0ksscpjA9M5wrdh9l_vkzYVpp0Ro-iFKFOH9-eoM",
        "realtor", "profile_queue", "Realtors",
    ),
    DriveListSource(
        "relatorand lo", "Loan Officers", "15Ps0ksscpjA9M5wrdh9l_vkzYVpp0Ro-iFKFOH9-eoM",
        "loanofficer", "loan_officers", "Loan Officers",
    ),
)


def _clean(value: Any) -> str:
    if value is None:
        return ""
    return str(value).replace("\u00a0", " ").strip()


def _value(row: list[Any], index: int) -> str:
    return _clean(row[index]) if index < len(row) else ""


def _intish(value: Any) -> int | None:
    text = _clean(value).replace(",", "")
    if not text:
        return None
    match = re.search(r"-?\d+(?:\.\d+)?", text)
    if not match:
        return None
    try:
        return int(float(match.group(0)))
    except ValueError:
        return None


def _money(value: Any) -> int | None:
    return normalize_money(_clean(value))


def _slug(value: str) -> str:
    return re.sub(r"[^a-z0-9]+", " ", value.lower()).strip()


def _hash_key(prefix: str, *parts: Any) -> str:
    normalized = "|".join(_slug(_clean(part)) for part in parts)
    digest = hashlib.sha256(normalized.encode("utf-8")).hexdigest()[:20]
    return f"{prefix}:{digest}"


def _completeness(record: dict[str, Any]) -> int:
    ignored = {"Import Key", "Listing Key", "Imported At", "Source Row"}
    return sum(1 for key, value in record.items() if key not in ignored and value not in (None, "", []))


def _put_best(target: dict[str, dict[str, Any]], key: str, record: dict[str, Any]) -> None:
    existing = target.get(key)
    if existing is None or _completeness(record) > _completeness(existing):
        target[key] = record


def _is_rate_limit_error(exc: Exception) -> bool:
    response = getattr(exc, "response", None)
    status_code = getattr(response, "status_code", None)
    text = str(exc).upper()
    return status_code == 429 or "429" in text or "QUOTA EXCEEDED" in text or "RESOURCE_EXHAUSTED" in text


def _api_call(operation: Callable[..., T], *args: Any, **kwargs: Any) -> T:
    max_attempts = 7
    for attempt in range(max_attempts):
        try:
            return operation(*args, **kwargs)
        except gspread.exceptions.APIError as exc:
            if not _is_rate_limit_error(exc) or attempt == max_attempts - 1:
                raise
            delay = min((2 ** attempt) + random.random(), 64)
            logger.warning("Google Sheets rate limit reached. Waiting %.1f seconds.", delay)
            time.sleep(delay)
    raise RuntimeError("Google Sheets retry loop exited unexpectedly.")


def _source_notes(source: DriveListSource, imported: int, error: str = "") -> str:
    if error:
        return error
    return f"Imported {imported} row(s) from {source.worksheet}."


def _base_realtor(source: DriveListSource, row_number: int, imported_at: str) -> dict[str, Any]:
    return {
        "Market": source.market,
        "Source File": source.name,
        "Source Tab": source.worksheet,
        "Source Row": row_number,
        "Imported At": imported_at,
    }


def _base_listing(source: DriveListSource, row_number: int, imported_at: str) -> dict[str, Any]:
    return {
        "Market": source.market,
        "Source File": source.name,
        "Source Tab": source.worksheet,
        "Source Row": row_number,
        "Imported At": imported_at,
    }


def _realtor_key(record: dict[str, Any]) -> str:
    email = _clean(record.get("Email"))
    profile_url = _clean(record.get("Profile URL"))
    if email:
        return _hash_key("realtor", email)
    if profile_url:
        return _hash_key("realtor", profile_url)
    return _hash_key("realtor", record.get("Market"), record.get("Agent Display"), record.get("Realtor Name"), record.get("Brokerage"))


def _listing_key(record: dict[str, Any]) -> str:
    return _hash_key(
        "listing",
        record.get("Address"),
        record.get("List Date"),
        record.get("Agent Display") or record.get("Realtor Name"),
    )


def _parse_final_houston(
    source: DriveListSource,
    rows: list[list[Any]],
    imported_at: str,
    realtors: dict[str, dict[str, Any]],
    listings: dict[str, dict[str, Any]],
) -> int:
    imported = 0
    for row_number, row in enumerate(rows[2:], start=3):
        agent_display = _value(row, 1)
        realtor_name = _value(row, 12)
        brokerage = _value(row, 13)
        email = _value(row, 14)
        phone = _value(row, 15)
        address = _value(row, 5)
        if not any((agent_display, realtor_name, email, address)):
            continue

        if any((realtor_name, email, brokerage, agent_display)):
            realtor = _base_realtor(source, row_number, imported_at) | {
                "Agent Display": agent_display,
                "Realtor Name": realtor_name,
                "Brokerage": brokerage,
                "Email": email,
                "Phone": phone,
                "Buyer Sides": _intish(_value(row, 22)),
                "Buyer Volume": _money(_value(row, 23)),
                "Seller Sides": _intish(_value(row, 25)),
                "Seller Volume": _money(_value(row, 26)),
                "Total Sides": _intish(_value(row, 28)),
                "Total Volume": _money(_value(row, 29)) or _money(_value(row, 16)),
                "Loan Count": _intish(_value(row, 17)),
                "LOs Used": _intish(_value(row, 18)),
                "Conventional Count": None,
                "VA Count": None,
                "FHA Count": None,
                "Profile URL": "",
                "Screenshot Drive Link": "",
                "Notes": "; ".join(
                    item for item in (
                        f"Loyalty Score={_value(row, 19)}" if _value(row, 19) else "",
                        f"Loyalty YoY={_value(row, 20)}" if _value(row, 20) else "",
                        f"Connections={_value(row, 21)}" if _value(row, 21) else "",
                    ) if item
                ),
            }
            key = _realtor_key(realtor)
            realtor["Import Key"] = key
            _put_best(realtors, key, realtor)

        if address:
            listing = _base_listing(source, row_number, imported_at) | {
                "Agent Display": agent_display,
                "Realtor Name": realtor_name,
                "Brokerage": brokerage,
                "Email": email,
                "Phone": phone,
                "List Date": _value(row, 2),
                "List Price": _money(_value(row, 3)),
                "Open House": _value(row, 4),
                "Address": address,
                "Property Type": _value(row, 6),
                "Buyer Count 12M": _intish(_value(row, 22)),
                "Buyer Volume 12M": _money(_value(row, 23)),
                "Loan Count 12M": _intish(_value(row, 17)),
                "LOs Used 12M": _intish(_value(row, 18)),
            }
            key = _listing_key(listing)
            listing["Listing Key"] = key
            _put_best(listings, key, listing)
        imported += 1
    return imported


def _parse_listing_source(
    source: DriveListSource,
    rows: list[list[Any]],
    imported_at: str,
    listings: dict[str, dict[str, Any]],
    indexes: dict[str, int],
) -> int:
    imported = 0
    for row_number, row in enumerate(rows[2:], start=3):
        agent = _value(row, indexes["agent"])
        address = _value(row, indexes["address"])
        if not any((agent, address)):
            continue
        listing = _base_listing(source, row_number, imported_at) | {
            "Agent Display": agent,
            "Realtor Name": "",
            "Brokerage": "",
            "Email": "",
            "Phone": "",
            "List Date": _value(row, indexes["date"]),
            "List Price": _money(_value(row, indexes["price"])),
            "Open House": _value(row, indexes["open_house"]),
            "Address": address,
            "Property Type": _value(row, indexes["property_type"]),
            "Buyer Count 12M": _intish(_value(row, indexes["buyer_count"])),
            "Buyer Volume 12M": _money(_value(row, indexes["buyer_volume"])),
            "Loan Count 12M": _intish(_value(row, indexes["loan_count"])),
            "LOs Used 12M": _intish(_value(row, indexes["los_used"])),
        }
        key = _listing_key(listing)
        listing["Listing Key"] = key
        _put_best(listings, key, listing)
        imported += 1
    return imported


def _parse_market_realtors(
    source: DriveListSource,
    rows: list[list[Any]],
    imported_at: str,
    realtors: dict[str, dict[str, Any]],
) -> int:
    imported = 0
    for row_number, row in enumerate(rows[4:], start=5):
        agent = _value(row, 2)
        if not agent:
            continue
        buyer_sides = _intish(_value(row, 3))
        buyer_volume = _money(_value(row, 4))
        seller_sides = _intish(_value(row, 5))
        seller_volume = _money(_value(row, 6))
        realtor = _base_realtor(source, row_number, imported_at) | {
            "Agent Display": agent,
            "Realtor Name": "",
            "Brokerage": "",
            "Email": "",
            "Phone": "",
            "Buyer Sides": buyer_sides,
            "Buyer Volume": buyer_volume,
            "Seller Sides": seller_sides,
            "Seller Volume": seller_volume,
            "Total Sides": (buyer_sides or 0) + (seller_sides or 0) if buyer_sides is not None or seller_sides is not None else None,
            "Total Volume": (buyer_volume or 0) + (seller_volume or 0) if buyer_volume is not None or seller_volume is not None else None,
            "Loan Count": _intish(_value(row, 7)),
            "LOs Used": _intish(_value(row, 8)),
            "Conventional Count": _intish(_value(row, 9)),
            "VA Count": _intish(_value(row, 10)),
            "FHA Count": _intish(_value(row, 11)),
            "Profile URL": "",
            "Screenshot Drive Link": "",
            "Notes": "; ".join(
                item for item in (
                    f"Sales Anywhere Buyer Count={_value(row, 12)}" if _value(row, 12) else "",
                    f"Sales Anywhere Buyer Volume={_value(row, 13)}" if _value(row, 13) else "",
                    f"Wholesale Count={_value(row, 14)}" if _value(row, 14) else "",
                ) if item
            ),
        }
        key = _realtor_key(realtor)
        realtor["Import Key"] = key
        _put_best(realtors, key, realtor)
        imported += 1
    return imported


def _parse_profile_queue(
    source: DriveListSource,
    rows: list[list[Any]],
    imported_at: str,
    realtors: dict[str, dict[str, Any]],
) -> int:
    imported = 0
    for row_number, row in enumerate(rows[2:], start=3):
        agent = _value(row, 2)
        profile_url = _value(row, 15)
        if not any((agent, profile_url)):
            continue
        buyer_sides = _intish(_value(row, 3))
        buyer_volume = _money(_value(row, 4))
        seller_sides = _intish(_value(row, 5))
        seller_volume = _money(_value(row, 6))
        realtor = _base_realtor(source, row_number, imported_at) | {
            "Agent Display": agent,
            "Realtor Name": "",
            "Brokerage": "",
            "Email": "",
            "Phone": "",
            "Buyer Sides": buyer_sides,
            "Buyer Volume": buyer_volume,
            "Seller Sides": seller_sides,
            "Seller Volume": seller_volume,
            "Total Sides": (buyer_sides or 0) + (seller_sides or 0) if buyer_sides is not None or seller_sides is not None else None,
            "Total Volume": (buyer_volume or 0) + (seller_volume or 0) if buyer_volume is not None or seller_volume is not None else None,
            "Loan Count": _intish(_value(row, 7)),
            "LOs Used": _intish(_value(row, 8)),
            "Conventional Count": _intish(_value(row, 9)),
            "VA Count": _intish(_value(row, 10)),
            "FHA Count": _intish(_value(row, 11)),
            "Profile URL": profile_url,
            "Screenshot Drive Link": _value(row, 18),
            "Notes": "; ".join(
                item for item in (
                    f"Status={_value(row, 16)}" if _value(row, 16) else "",
                    f"Screenshot={_value(row, 17)}" if _value(row, 17) else "",
                    f"Completed={_value(row, 19)}" if _value(row, 19) else "",
                    f"Error={_value(row, 20)}" if _value(row, 20) else "",
                    f"Retry Count={_value(row, 21)}" if _value(row, 21) else "",
                ) if item
            ),
        }
        key = _realtor_key(realtor)
        realtor["Import Key"] = key
        _put_best(realtors, key, realtor)
        imported += 1
    return imported


def _parse_loan_officers(
    source: DriveListSource,
    rows: list[list[Any]],
    imported_at: str,
    loan_officers: dict[str, dict[str, Any]],
) -> int:
    imported = 0
    for row_number, row in enumerate(rows[2:], start=3):
        phone = _value(row, 0)
        display = _value(row, 2)
        if not any((phone, display)):
            continue
        record = {
            "Phone": phone,
            "Rank": _intish(_value(row, 1)),
            "Loan Officer Display": display,
            "Metric Count 1": _intish(_value(row, 3)),
            "Metric Volume 1": _money(_value(row, 4)),
            "Metric Count 2": _intish(_value(row, 5)),
            "Metric Count 3": _intish(_value(row, 6)),
            "Metric Count 4": _intish(_value(row, 7)),
            "Total Count": _intish(_value(row, 8)),
            "Total Volume": _money(_value(row, 9)),
            "Average Loan": _money(_value(row, 10)),
            "Location": _value(row, 11),
            "Organization Type": _value(row, 12),
            "Source File": source.name,
            "Source Tab": source.worksheet,
            "Source Row": row_number,
            "Imported At": imported_at,
            "Notes": "Source did not include column headers; metric labels are preserved generically without inference.",
            "Reserved": "",
        }
        key = _hash_key("loan-officer", phone or display, display)
        record["Import Key"] = key
        _put_best(loan_officers, key, record)
        imported += 1
    return imported


def _worksheet(book: gspread.Spreadsheet, title: str, rows: int, cols: int) -> gspread.Worksheet:
    try:
        sheet = _api_call(book.worksheet, title)
    except gspread.WorksheetNotFound:
        sheet = _api_call(book.add_worksheet, title=title, rows=rows, cols=cols)
    return sheet


def _write_table(book: gspread.Spreadsheet, title: str, headers: list[str], records: list[dict[str, Any]]) -> None:
    sheet = _worksheet(book, title, max(1000, len(records) + 10), len(headers))
    required_rows = max(1000, len(records) + 10)
    required_cols = len(headers)
    if sheet.row_count < required_rows or sheet.col_count < required_cols:
        _api_call(sheet.resize, rows=max(sheet.row_count, required_rows), cols=max(sheet.col_count, required_cols))
    _api_call(sheet.clear)
    _api_call(sheet.update, values=[headers], range_name="A1", value_input_option="RAW")

    chunk_size = 750
    for offset in range(0, len(records), chunk_size):
        chunk = records[offset: offset + chunk_size]
        values = [
            [record.get(header, "") if record.get(header) is not None else "" for header in headers]
            for record in chunk
        ]
        start_row = offset + 2
        _api_call(sheet.update, values=values, range_name=f"A{start_row}", value_input_option="RAW")
        time.sleep(0.15)
    try:
        _api_call(sheet.freeze, rows=1)
    except Exception:
        logger.debug("Could not freeze header row for %s", title, exc_info=True)


def import_drive_lists(spreadsheet_id: str, service_account_file: str) -> dict[str, Any]:
    if not spreadsheet_id:
        raise RuntimeError("GOOGLE_SHEET_ID is required for Drive list import.")
    credentials_path = Path(service_account_file).expanduser()
    if not credentials_path.exists():
        raise RuntimeError(f"Google service-account file was not found: {credentials_path}")

    credentials = Credentials.from_service_account_file(str(credentials_path), scopes=SERVICE_ACCOUNT_SCOPES)
    client = gspread.authorize(credentials)
    target_book = _api_call(client.open_by_key, spreadsheet_id)
    service_email = _clean(getattr(credentials, "service_account_email", ""))
    imported_at = datetime.now(timezone.utc).isoformat()

    realtors: dict[str, dict[str, Any]] = {}
    listings: dict[str, dict[str, Any]] = {}
    loan_officers: dict[str, dict[str, Any]] = {}
    source_log: list[dict[str, Any]] = []
    inaccessible: list[str] = []

    for source in SOURCES:
        status = "IMPORTED"
        imported_count = 0
        note = ""
        try:
            source_book = _api_call(client.open_by_key, source.spreadsheet_id)
            source_sheet = _api_call(source_book.worksheet, source.worksheet)
            rows = _api_call(source_sheet.get_all_values)

            if source.parser == "final_houston":
                imported_count = _parse_final_houston(source, rows, imported_at, realtors, listings)
            elif source.parser == "houston_listing":
                imported_count = _parse_listing_source(
                    source, rows, imported_at, listings,
                    {"agent": 1, "date": 2, "price": 3, "open_house": 4, "address": 5,
                     "property_type": 6, "buyer_count": 7, "buyer_volume": 8, "loan_count": 9, "los_used": 10},
                )
            elif source.parser == "dallas_listing":
                imported_count = _parse_listing_source(
                    source, rows, imported_at, listings,
                    {"agent": 2, "date": 3, "price": 4, "open_house": 5, "address": 6,
                     "property_type": 7, "buyer_count": 8, "buyer_volume": 9, "loan_count": 10, "los_used": 11},
                )
            elif source.parser == "market_realtors":
                imported_count = _parse_market_realtors(source, rows, imported_at, realtors)
            elif source.parser == "profile_queue":
                imported_count = _parse_profile_queue(source, rows, imported_at, realtors)
            elif source.parser == "loan_officers":
                imported_count = _parse_loan_officers(source, rows, imported_at, loan_officers)
            else:
                raise RuntimeError(f"Unknown Drive list parser: {source.parser}")
            note = _source_notes(source, imported_count)
            logger.info("Imported %s row(s) from %s / %s", imported_count, source.name, source.worksheet)
        except Exception as exc:
            status = "NO_ACCESS_OR_ERROR"
            note = f"{type(exc).__name__}: {exc}"
            inaccessible.append(f"{source.name} / {source.worksheet}")
            logger.warning("Could not import %s / %s: %s", source.name, source.worksheet, exc)

        source_log.append({
            "Source Name": source.name,
            "Market / Type": source.market,
            "Spreadsheet ID": source.spreadsheet_id,
            "Source Tab": source.worksheet,
            "Import Type": source.import_type,
            "Source URL": source.url,
            "Service Account": service_email,
            "Access Status": status,
            "Notes": note,
        })

    realtor_rows = sorted(realtors.values(), key=lambda row: (_clean(row.get("Market")).lower(), _clean(row.get("Agent Display") or row.get("Realtor Name")).lower()))
    listing_rows = sorted(listings.values(), key=lambda row: (_clean(row.get("Market")).lower(), _clean(row.get("Address")).lower(), _clean(row.get("List Date"))))
    loan_officer_rows = sorted(loan_officers.values(), key=lambda row: (_clean(row.get("Loan Officer Display")).lower(), _clean(row.get("Phone"))))

    _write_table(target_book, "Imported Realtors", REALTOR_HEADERS, realtor_rows)
    _write_table(target_book, "Imported Listings", LISTING_HEADERS, listing_rows)
    _write_table(target_book, "Imported Loan Officers", LO_HEADERS, loan_officer_rows)
    _write_table(target_book, "Drive Import Sources", SOURCE_LOG_HEADERS, source_log)

    result = {
        "realtors": len(realtor_rows),
        "listings": len(listing_rows),
        "loan_officers": len(loan_officer_rows),
        "sources": len(SOURCES),
        "inaccessible": inaccessible,
        "service_account_email": service_email,
    }
    logger.info(
        "Drive list import finished: %s realtor(s), %s listing(s), %s loan officer(s).",
        result["realtors"], result["listings"], result["loan_officers"],
    )
    return result
