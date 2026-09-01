from __future__ import annotations

import logging
import os
from datetime import datetime, timezone
from pathlib import Path

import gspread
from dotenv import load_dotenv
from google.auth.transport.requests import Request
from google.oauth2.credentials import Credentials
from google_auth_oauthlib.flow import InstalledAppFlow

from .drive_list_importer import (
    LISTING_HEADERS,
    LO_HEADERS,
    REALTOR_HEADERS,
    SOURCE_LOG_HEADERS,
    SOURCES,
    _api_call,
    _clean,
    _parse_final_houston,
    _parse_listing_source,
    _parse_loan_officers,
    _parse_market_realtors,
    _parse_profile_queue,
    _source_notes,
    _write_table,
)

logger = logging.getLogger(__name__)
SCOPES = ["https://www.googleapis.com/auth/spreadsheets"]


def _oauth_credentials(client_file: Path, token_file: Path) -> Credentials:
    credentials: Credentials | None = None
    if token_file.exists():
        credentials = Credentials.from_authorized_user_file(str(token_file), SCOPES)

    if credentials and credentials.expired and credentials.refresh_token:
        credentials.refresh(Request())

    if not credentials or not credentials.valid:
        if not client_file.exists():
            raise RuntimeError(
                f"Google OAuth desktop client file was not found: {client_file}. "
                "Download an OAuth Client ID for a Desktop app and save it there."
            )
        flow = InstalledAppFlow.from_client_secrets_file(str(client_file), SCOPES)
        credentials = flow.run_local_server(port=0, open_browser=True)

    token_file.parent.mkdir(parents=True, exist_ok=True)
    token_file.write_text(credentials.to_json(), encoding="utf-8")
    return credentials


def import_with_user_oauth(
    target_spreadsheet_id: str,
    client_file: Path,
    token_file: Path,
) -> dict[str, object]:
    if not target_spreadsheet_id:
        raise RuntimeError("GOOGLE_SHEET_ID is required for Drive list import.")

    credentials = _oauth_credentials(client_file, token_file)
    client = gspread.authorize(credentials)
    target_book = _api_call(client.open_by_key, target_spreadsheet_id)
    imported_at = datetime.now(timezone.utc).isoformat()

    realtors: dict[str, dict] = {}
    listings: dict[str, dict] = {}
    loan_officers: dict[str, dict] = {}
    source_log: list[dict] = []
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
                    source,
                    rows,
                    imported_at,
                    listings,
                    {
                        "agent": 1,
                        "date": 2,
                        "price": 3,
                        "open_house": 4,
                        "address": 5,
                        "property_type": 6,
                        "buyer_count": 7,
                        "buyer_volume": 8,
                        "loan_count": 9,
                        "los_used": 10,
                    },
                )
            elif source.parser == "dallas_listing":
                imported_count = _parse_listing_source(
                    source,
                    rows,
                    imported_at,
                    listings,
                    {
                        "agent": 2,
                        "date": 3,
                        "price": 4,
                        "open_house": 5,
                        "address": 6,
                        "property_type": 7,
                        "buyer_count": 8,
                        "buyer_volume": 9,
                        "loan_count": 10,
                        "los_used": 11,
                    },
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

        source_log.append(
            {
                "Source Name": source.name,
                "Market / Type": source.market,
                "Spreadsheet ID": source.spreadsheet_id,
                "Source Tab": source.worksheet,
                "Import Type": source.import_type,
                "Source URL": source.url,
                "Service Account": "USER_OAUTH",
                "Access Status": status,
                "Notes": note,
            }
        )

    realtor_rows = sorted(
        realtors.values(),
        key=lambda row: (
            _clean(row.get("Market")).lower(),
            _clean(row.get("Agent Display") or row.get("Realtor Name")).lower(),
        ),
    )
    listing_rows = sorted(
        listings.values(),
        key=lambda row: (
            _clean(row.get("Market")).lower(),
            _clean(row.get("Address")).lower(),
            _clean(row.get("List Date")),
        ),
    )
    loan_officer_rows = sorted(
        loan_officers.values(),
        key=lambda row: (
            _clean(row.get("Loan Officer Display")).lower(),
            _clean(row.get("Phone")),
        ),
    )

    _write_table(target_book, "Imported Realtors", REALTOR_HEADERS, realtor_rows)
    _write_table(target_book, "Imported Listings", LISTING_HEADERS, listing_rows)
    _write_table(target_book, "Imported Loan Officers", LO_HEADERS, loan_officer_rows)
    _write_table(target_book, "Drive Import Sources", SOURCE_LOG_HEADERS, source_log)

    return {
        "realtors": len(realtor_rows),
        "listings": len(listing_rows),
        "loan_officers": len(loan_officer_rows),
        "inaccessible": inaccessible,
    }


def main() -> None:
    load_dotenv()
    logging.basicConfig(
        level=os.getenv("LOG_LEVEL", "INFO"),
        format="%(asctime)s [%(levelname)s] %(message)s",
    )

    client_file = Path(
        os.getenv(
            "GOOGLE_OAUTH_CLIENT_FILE",
            r"C:\RealtorProfileScanner\oauth_credentials.json",
        )
    ).expanduser()
    token_file = Path(
        os.getenv(
            "GOOGLE_OAUTH_TOKEN_FILE",
            r"C:\RealtorProfileScanner\oauth_token.json",
        )
    ).expanduser()

    result = import_with_user_oauth(
        target_spreadsheet_id=os.getenv("GOOGLE_SHEET_ID", "").strip(),
        client_file=client_file,
        token_file=token_file,
    )

    print(
        "Drive OAuth import complete: "
        f"{result['realtors']} realtor(s), "
        f"{result['listings']} listing(s), "
        f"{result['loan_officers']} loan officer(s)."
    )
    if result["inaccessible"]:
        print("These files were not accessible to the Google account used in the browser login:")
        for source in result["inaccessible"]:
            print(f"- {source}")


if __name__ == "__main__":
    main()
