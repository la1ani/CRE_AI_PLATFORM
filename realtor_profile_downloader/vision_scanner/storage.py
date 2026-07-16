from __future__ import annotations

import logging
from dataclasses import dataclass
from pathlib import Path
from typing import Any, Iterable

import gspread
from google.oauth2.service_account import Credentials

from .models import ProfileExtraction, ValidationResult
from .normalizer import master_row, normalize_money, profile_key

logger = logging.getLogger(__name__)

MASTER_HEADERS = [
    "Profile Key", "Name", "Brokerage", "Email", "Phone", "Languages", "Source File", "Source Hash",
    "12M Volume", "Total Sides", "Buyer Sides", "Seller Sides", "Loan Count", "LOs Used", "Companies Used",
    "Top LO", "Top LO Share", "Top Loan Company", "Top Company Share", "Listings Visible",
    "Transactions Visible", "Transactions Expected", "Loan Rows Visible", "Loan Rows Expected",
    "Extraction Status", "Validation Score", "Last Scanned",
]

COMMON_HEADERS = ["Profile Key", "Realtor Name", "Source Hash", "Scanned At"]
DETAIL_HEADERS: dict[str, list[str]] = {
    "LO Relationships": COMMON_HEADERS + [
        "loan_officer_name", "company", "branch", "loan_count", "relationship_percent_raw",
    ],
    "Loan Companies": COMMON_HEADERS + [
        "company", "loan_count", "relationship_percent_raw",
    ],
    "Visible Transactions": COMMON_HEADERS + [
        "address", "sale_date_raw", "buyer_agent", "buyer_agent_company", "seller_agent",
        "seller_agent_company", "sale_price_raw", "loan_amount_raw", "ltv_raw", "loan_type",
        "loan_officer", "loan_officer_company",
    ],
    "Loan Details": COMMON_HEADERS + [
        "address", "sale_date_raw", "sale_price_raw", "loan_amount_raw", "ltv_raw", "loan_type",
        "loan_officer", "loan_officer_company", "lender",
    ],
    "Title Companies": COMMON_HEADERS + [
        "side", "company", "transaction_count", "relationship_percent_raw",
    ],
    "Listings": COMMON_HEADERS + [
        "address", "list_date_raw", "list_price_raw", "open_house",
    ],
    "Scan Review": COMMON_HEADERS + [
        "Status", "Score", "Issues", "Transactions Expected", "Transactions Extracted",
        "Loan Rows Expected", "Loan Rows Extracted",
    ],
}


@dataclass
class StorageConfig:
    google_sheet_id: str = ""
    google_service_account_file: str = ""
    supabase_url: str = ""
    supabase_service_role_key: str = ""


class GoogleSheetsWriter:
    name = "Google Sheets"

    def __init__(self, spreadsheet_id: str, service_account_file: str) -> None:
        credentials_path = Path(service_account_file).expanduser()
        if not credentials_path.exists():
            raise RuntimeError(f"Google service-account file was not found: {credentials_path}")
        credentials = Credentials.from_service_account_file(
            str(credentials_path),
            scopes=["https://www.googleapis.com/auth/spreadsheets", "https://www.googleapis.com/auth/drive"],
        )
        self.book = gspread.authorize(credentials).open_by_key(spreadsheet_id)

    def _worksheet(self, title: str, headers: list[str]):
        try:
            sheet = self.book.worksheet(title)
        except gspread.WorksheetNotFound:
            sheet = self.book.add_worksheet(title=title, rows=1000, cols=max(20, len(headers)))
        values = sheet.get_all_values()
        if not values:
            sheet.append_row(headers, value_input_option="RAW")
        elif values[0] != headers:
            sheet.update("A1", [headers], value_input_option="RAW")
        return sheet

    def initialize(self) -> None:
        self._worksheet("Realtor Master", MASTER_HEADERS)
        for title, headers in DETAIL_HEADERS.items():
            self._worksheet(title, headers)
        logger.info("Google Sheets connection verified and worksheets initialized: %s", self.book.title)

    def _replace_dicts(self, title: str, rows: list[dict[str, Any]], source_hash: str) -> None:
        headers = DETAIL_HEADERS[title]
        sheet = self._worksheet(title, headers)

        # Re-syncing an existing JSON report should not duplicate detail records. Remove rows from
        # the same source scan first, then append the current extraction.
        existing = sheet.get_all_values()
        if existing and "Source Hash" in headers:
            source_index = headers.index("Source Hash")
            matching_rows = [
                row_number
                for row_number, row in enumerate(existing[1:], start=2)
                if source_index < len(row) and row[source_index].strip() == source_hash
            ]
            for row_number in reversed(matching_rows):
                sheet.delete_rows(row_number)

        if not rows:
            return
        values = [
            [row.get(header, "") if row.get(header) is not None else "" for header in headers]
            for row in rows
        ]
        sheet.append_rows(values, value_input_option="RAW")

    def write(self, profile: ProfileExtraction, metadata: dict[str, Any], validation: ValidationResult) -> None:
        master = master_row(profile, metadata, validation.model_dump())
        sheet = self._worksheet("Realtor Master", MASTER_HEADERS)
        records = sheet.get_all_records(expected_headers=MASTER_HEADERS)
        target_row = next(
            (
                index
                for index, record in enumerate(records, start=2)
                if str(record.get("Profile Key", "")).strip() == master["Profile Key"]
            ),
            None,
        )
        values = [[master.get(header, "") if master.get(header) is not None else "" for header in MASTER_HEADERS]]
        if target_row:
            sheet.update(f"A{target_row}", values, value_input_option="RAW")
        else:
            sheet.append_rows(values, value_input_option="RAW")

        common = {
            "Profile Key": master["Profile Key"],
            "Realtor Name": profile.identity.realtor_name or "",
            "Source Hash": metadata["source_hash"],
            "Scanned At": metadata["scanned_at"],
        }
        source_hash = metadata["source_hash"]
        self._replace_dicts(
            "LO Relationships",
            [common | row.model_dump() for row in profile.relationships.loan_officer_relationships],
            source_hash,
        )
        self._replace_dicts(
            "Loan Companies",
            [common | row.model_dump() for row in profile.relationships.loan_company_relationships],
            source_hash,
        )
        self._replace_dicts(
            "Visible Transactions",
            [common | row.model_dump() for row in profile.transactions.rows],
            source_hash,
        )
        self._replace_dicts(
            "Loan Details",
            [common | row.model_dump() for row in profile.loan_details.rows],
            source_hash,
        )
        self._replace_dicts(
            "Title Companies",
            [common | row.model_dump() for row in profile.extras.title_relationships],
            source_hash,
        )
        self._replace_dicts(
            "Listings",
            [common | row.model_dump() for row in profile.extras.recent_listings],
            source_hash,
        )
        self._replace_dicts(
            "Scan Review",
            [{
                **common,
                "Status": validation.status,
                "Score": validation.score,
                "Issues": "; ".join(f"{x.code}: {x.message}" for x in validation.issues),
                "Transactions Expected": profile.transactions.expected_entries,
                "Transactions Extracted": len(profile.transactions.rows),
                "Loan Rows Expected": profile.loan_details.expected_entries,
                "Loan Rows Extracted": len(profile.loan_details.rows),
            }],
            source_hash,
        )


class SupabaseWriter:
    name = "Supabase"

    def __init__(self, url: str, service_role_key: str) -> None:
        try:
            from supabase import create_client
        except ImportError as exc:
            raise RuntimeError("Install the supabase package to enable Supabase storage.") from exc
        self.client = create_client(url, service_role_key)

    def initialize(self) -> None:
        try:
            self.client.table("realtors").select("id").limit(1).execute()
        except Exception as exc:
            raise RuntimeError(
                "Supabase connection failed. Confirm the URL/key and run sql/realtor_profile_vision_schema.sql."
            ) from exc
        logger.info("Supabase connection and realtor schema verified.")

    def write(self, profile: ProfileExtraction, metadata: dict[str, Any], validation: ValidationResult) -> None:
        key = profile_key(profile)
        realtor_payload = {
            "profile_key": key,
            "name": profile.identity.realtor_name,
            "brokerage": profile.identity.brokerage,
            "email": profile.identity.email,
            "phone": profile.identity.phone,
            "languages": profile.identity.languages,
            "transaction_volume": normalize_money(profile.performance.total.volume_raw)
            or normalize_money(profile.identity.transaction_volume_raw),
            "loan_count": profile.identity.loan_count or profile.relationships.reported_total_loans,
            "loan_officers_used": profile.identity.loan_officers_used or profile.relationships.reported_loan_officers_used,
            "loan_companies_used": profile.relationships.reported_companies_used,
            "updated_at": metadata["scanned_at"],
        }
        realtor = self.client.table("realtors").upsert(realtor_payload, on_conflict="profile_key").execute().data[0]
        scan_payload = {
            "realtor_id": realtor["id"],
            "source_file": metadata["source_file"],
            "source_hash": metadata["source_hash"],
            "status": validation.status,
            "validation_score": validation.score,
            "issues": [x.model_dump() for x in validation.issues],
            "raw_json": profile.model_dump(),
            "scanned_at": metadata["scanned_at"],
        }
        scan = self.client.table("realtor_profile_scans").upsert(scan_payload, on_conflict="source_hash").execute().data[0]
        scan_id = scan["id"]

        # The scan row is upserted, so remove old child rows before inserting the corrected extraction.
        child_tables = (
            "realtor_lo_relationships",
            "realtor_company_relationships",
            "realtor_transactions",
            "realtor_loan_details",
            "realtor_title_relationships",
            "realtor_listings",
        )
        for table in child_tables:
            self.client.table(table).delete().eq("scan_id", scan_id).execute()

        def insert_rows(table: str, rows: Iterable[dict[str, Any]]) -> None:
            payload = [{"scan_id": scan_id, "realtor_id": realtor["id"], **row} for row in rows]
            if payload:
                self.client.table(table).insert(payload).execute()

        insert_rows("realtor_lo_relationships", [row.model_dump() for row in profile.relationships.loan_officer_relationships])
        insert_rows("realtor_company_relationships", [row.model_dump() for row in profile.relationships.loan_company_relationships])
        insert_rows("realtor_transactions", [row.model_dump() for row in profile.transactions.rows])
        insert_rows("realtor_loan_details", [row.model_dump() for row in profile.loan_details.rows])
        insert_rows("realtor_title_relationships", [row.model_dump() for row in profile.extras.title_relationships])
        insert_rows("realtor_listings", [row.model_dump() for row in profile.extras.recent_listings])


class StorageRouter:
    def __init__(self, config: StorageConfig) -> None:
        self.writers: list[Any] = []
        if config.google_sheet_id and config.google_service_account_file:
            self.writers.append(GoogleSheetsWriter(config.google_sheet_id, config.google_service_account_file))
        if config.supabase_url and config.supabase_service_role_key:
            self.writers.append(SupabaseWriter(config.supabase_url, config.supabase_service_role_key))
        if not self.writers:
            logger.warning(
                "No Google Sheets or Supabase storage is configured. Extraction will continue in local report-only mode."
            )

    @property
    def configured_names(self) -> list[str]:
        return [writer.name for writer in self.writers]

    def initialize(self) -> None:
        if not self.writers:
            raise RuntimeError("No storage configured. Add Google Sheets, Supabase, or both to .env.")
        for writer in self.writers:
            writer.initialize()

    def write(self, profile: ProfileExtraction, metadata: dict[str, Any], validation: ValidationResult) -> None:
        # scanner.py always writes a complete JSON audit report after this call. External
        # storage is intentionally optional so the user can verify extraction before setup.
        for writer in self.writers:
            writer.write(profile, metadata, validation)
