from __future__ import annotations

from dataclasses import dataclass
from typing import Any, Iterable

import gspread
from google.oauth2.service_account import Credentials

from .models import ProfileExtraction, ValidationResult
from .normalizer import master_row, normalize_money, profile_key

MASTER_HEADERS = [
    "Profile Key", "Name", "Brokerage", "Email", "Phone", "Languages", "Source File", "Source Hash",
    "12M Volume", "Total Sides", "Buyer Sides", "Seller Sides", "Loan Count", "LOs Used", "Companies Used",
    "Top LO", "Top LO Share", "Top Loan Company", "Top Company Share", "Listings Visible",
    "Transactions Visible", "Transactions Expected", "Loan Rows Visible", "Loan Rows Expected",
    "Extraction Status", "Validation Score", "Last Scanned",
]


@dataclass
class StorageConfig:
    google_sheet_id: str = ""
    google_service_account_file: str = ""
    supabase_url: str = ""
    supabase_service_role_key: str = ""


class GoogleSheetsWriter:
    def __init__(self, spreadsheet_id: str, service_account_file: str) -> None:
        credentials = Credentials.from_service_account_file(
            service_account_file,
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
            sheet.update("1:1", [headers])
        return sheet

    def _append_dicts(self, title: str, rows: list[dict[str, Any]]) -> None:
        if not rows:
            return
        headers = list(rows[0].keys())
        sheet = self._worksheet(title, headers)
        values = [[row.get(header, "") if row.get(header) is not None else "" for header in headers] for row in rows]
        sheet.append_rows(values, value_input_option="RAW")

    def write(self, profile: ProfileExtraction, metadata: dict[str, Any], validation: ValidationResult) -> None:
        master = master_row(profile, metadata, validation.model_dump())
        sheet = self._worksheet("Realtor Master", MASTER_HEADERS)
        records = sheet.get_all_records(expected_headers=MASTER_HEADERS)
        target_row = next(
            (index for index, record in enumerate(records, start=2)
             if str(record.get("Profile Key", "")).strip() == master["Profile Key"]),
            None,
        )
        values = [[master.get(header, "") if master.get(header) is not None else "" for header in MASTER_HEADERS]]
        if target_row:
            sheet.update(f"A{target_row}", values)
        else:
            sheet.append_rows(values, value_input_option="RAW")

        common = {
            "Profile Key": master["Profile Key"],
            "Realtor Name": profile.identity.realtor_name or "",
            "Source Hash": metadata["source_hash"],
            "Scanned At": metadata["scanned_at"],
        }
        self._append_dicts("LO Relationships", [common | row.model_dump() for row in profile.relationships.loan_officer_relationships])
        self._append_dicts("Loan Companies", [common | row.model_dump() for row in profile.relationships.loan_company_relationships])
        self._append_dicts("Visible Transactions", [common | row.model_dump() for row in profile.transactions.rows])
        self._append_dicts("Loan Details", [common | row.model_dump() for row in profile.loan_details.rows])
        self._append_dicts("Title Companies", [common | row.model_dump() for row in profile.extras.title_relationships])
        self._append_dicts("Listings", [common | row.model_dump() for row in profile.extras.recent_listings])
        self._append_dicts("Scan Review", [{
            **common,
            "Status": validation.status,
            "Score": validation.score,
            "Issues": "; ".join(f"{x.code}: {x.message}" for x in validation.issues),
            "Transactions Expected": profile.transactions.expected_entries,
            "Transactions Extracted": len(profile.transactions.rows),
            "Loan Rows Expected": profile.loan_details.expected_entries,
            "Loan Rows Extracted": len(profile.loan_details.rows),
        }])


class SupabaseWriter:
    def __init__(self, url: str, service_role_key: str) -> None:
        try:
            from supabase import create_client
        except ImportError as exc:
            raise RuntimeError("Install the supabase package to enable Supabase storage.") from exc
        self.client = create_client(url, service_role_key)

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

    def write(self, profile: ProfileExtraction, metadata: dict[str, Any], validation: ValidationResult) -> None:
        if not self.writers:
            raise RuntimeError("No storage configured. Configure Google Sheets, Supabase, or both.")
        for writer in self.writers:
            writer.write(profile, metadata, validation)
