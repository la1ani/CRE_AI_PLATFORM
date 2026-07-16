from __future__ import annotations

import logging
import random
import time
from dataclasses import dataclass
from pathlib import Path
from typing import Any, Callable, Iterable, Sequence, TypeVar

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

SyncRecord = tuple[ProfileExtraction, dict[str, Any], ValidationResult]
T = TypeVar("T")


@dataclass
class StorageConfig:
    google_sheet_id: str = ""
    google_service_account_file: str = ""
    supabase_url: str = ""
    supabase_service_role_key: str = ""


def _is_rate_limit_error(exc: Exception) -> bool:
    response = getattr(exc, "response", None)
    status_code = getattr(response, "status_code", None)
    text = str(exc).upper()
    return status_code == 429 or "429" in text or "RESOURCE_EXHAUSTED" in text or "QUOTA EXCEEDED" in text


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
        self._worksheets: dict[str, Any] = {}
        self._values: dict[str, list[list[str]]] = {}
        self._master_rows: dict[str, int] | None = None
        self._detail_source_hashes: dict[str, set[str]] = {}

    def _api_call(self, operation: Callable[..., T], *args: Any, **kwargs: Any) -> T:
        max_attempts = 7
        for attempt in range(max_attempts):
            try:
                return operation(*args, **kwargs)
            except gspread.exceptions.APIError as exc:
                if not _is_rate_limit_error(exc) or attempt == max_attempts - 1:
                    raise
                delay = min((2 ** attempt) + random.random(), 64)
                logger.warning(
                    "Google Sheets rate limit reached. Waiting %.1f seconds before retry %s/%s.",
                    delay,
                    attempt + 1,
                    max_attempts - 1,
                )
                time.sleep(delay)
        raise RuntimeError("Google Sheets request retry loop exited unexpectedly.")

    def _worksheet(self, title: str, headers: list[str]):
        cached = self._worksheets.get(title)
        if cached is not None:
            return cached

        try:
            sheet = self._api_call(self.book.worksheet, title)
        except gspread.WorksheetNotFound:
            sheet = self._api_call(
                self.book.add_worksheet,
                title=title,
                rows=1000,
                cols=max(20, len(headers)),
            )

        values = self._api_call(sheet.get_all_values)
        if not values:
            self._api_call(sheet.append_row, headers, value_input_option="RAW")
            values = [headers]
        elif values[0] != headers:
            self._api_call(
                sheet.update,
                values=[headers],
                range_name="A1",
                value_input_option="RAW",
            )
            values[0] = headers

        self._worksheets[title] = sheet
        self._values[title] = values
        return sheet

    def initialize(self) -> None:
        self._worksheet("Realtor Master", MASTER_HEADERS)
        for title, headers in DETAIL_HEADERS.items():
            self._worksheet(title, headers)
        logger.info("Google Sheets connection verified and worksheets initialized: %s", self.book.title)

    def _get_master_rows(self) -> dict[str, int]:
        if self._master_rows is not None:
            return self._master_rows
        self._worksheet("Realtor Master", MASTER_HEADERS)
        values = self._values.get("Realtor Master", [MASTER_HEADERS])
        key_index = MASTER_HEADERS.index("Profile Key")
        self._master_rows = {
            row[key_index].strip(): row_number
            for row_number, row in enumerate(values[1:], start=2)
            if key_index < len(row) and row[key_index].strip()
        }
        return self._master_rows

    def _get_detail_hashes(self, title: str) -> set[str]:
        if title in self._detail_source_hashes:
            return self._detail_source_hashes[title]
        headers = DETAIL_HEADERS[title]
        self._worksheet(title, headers)
        values = self._values.get(title, [headers])
        hash_index = headers.index("Source Hash")
        hashes = {
            row[hash_index].strip()
            for row in values[1:]
            if hash_index < len(row) and row[hash_index].strip()
        }
        self._detail_source_hashes[title] = hashes
        return hashes

    @staticmethod
    def _detail_rows(
        profile: ProfileExtraction,
        metadata: dict[str, Any],
        validation: ValidationResult,
    ) -> dict[str, list[dict[str, Any]]]:
        master = master_row(profile, metadata, validation.model_dump())
        common = {
            "Profile Key": master["Profile Key"],
            "Realtor Name": profile.identity.realtor_name or "",
            "Source Hash": metadata["source_hash"],
            "Scanned At": metadata["scanned_at"],
        }
        return {
            "LO Relationships": [
                common | row.model_dump() for row in profile.relationships.loan_officer_relationships
            ],
            "Loan Companies": [
                common | row.model_dump() for row in profile.relationships.loan_company_relationships
            ],
            "Visible Transactions": [
                common | row.model_dump() for row in profile.transactions.rows
            ],
            "Loan Details": [
                common | row.model_dump() for row in profile.loan_details.rows
            ],
            "Title Companies": [
                common | row.model_dump() for row in profile.extras.title_relationships
            ],
            "Listings": [
                common | row.model_dump() for row in profile.extras.recent_listings
            ],
            "Scan Review": [{
                **common,
                "Status": validation.status,
                "Score": validation.score,
                "Issues": "; ".join(f"{x.code}: {x.message}" for x in validation.issues),
                "Transactions Expected": profile.transactions.expected_entries,
                "Transactions Extracted": len(profile.transactions.rows),
                "Loan Rows Expected": profile.loan_details.expected_entries,
                "Loan Rows Extracted": len(profile.loan_details.rows),
            }],
        }

    def _append_detail_if_new(
        self,
        title: str,
        rows: list[dict[str, Any]],
        source_hash: str,
    ) -> None:
        hashes = self._get_detail_hashes(title)
        if source_hash in hashes:
            return
        if rows:
            headers = DETAIL_HEADERS[title]
            values = [
                [row.get(header, "") if row.get(header) is not None else "" for header in headers]
                for row in rows
            ]
            sheet = self._worksheet(title, headers)
            self._api_call(sheet.append_rows, values, value_input_option="RAW")
            self._values.setdefault(title, [headers]).extend(values)
        hashes.add(source_hash)

    def write(self, profile: ProfileExtraction, metadata: dict[str, Any], validation: ValidationResult) -> None:
        master = master_row(profile, metadata, validation.model_dump())
        sheet = self._worksheet("Realtor Master", MASTER_HEADERS)
        master_rows = self._get_master_rows()
        target_row = master_rows.get(master["Profile Key"])
        values = [[master.get(header, "") if master.get(header) is not None else "" for header in MASTER_HEADERS]]

        if target_row:
            self._api_call(
                sheet.update,
                values=values,
                range_name=f"A{target_row}",
                value_input_option="RAW",
            )
            cached_values = self._values.setdefault("Realtor Master", [MASTER_HEADERS])
            while len(cached_values) < target_row:
                cached_values.append([])
            cached_values[target_row - 1] = values[0]
        else:
            self._api_call(sheet.append_rows, values, value_input_option="RAW")
            cached_values = self._values.setdefault("Realtor Master", [MASTER_HEADERS])
            cached_values.extend(values)
            master_rows[master["Profile Key"]] = len(cached_values)

        source_hash = metadata["source_hash"]
        for title, rows in self._detail_rows(profile, metadata, validation).items():
            self._append_detail_if_new(title, rows, source_hash)

    def write_many(self, records: Sequence[SyncRecord]) -> None:
        """Rebuild all scanner-owned worksheet tabs using a small, fixed number of API calls."""
        latest_master: dict[str, tuple[str, dict[str, Any]]] = {}
        detail_rows: dict[str, list[dict[str, Any]]] = {title: [] for title in DETAIL_HEADERS}
        seen_detail_hashes: dict[str, set[str]] = {title: set() for title in DETAIL_HEADERS}

        for profile, metadata, validation in records:
            master = master_row(profile, metadata, validation.model_dump())
            scanned_at = str(metadata.get("scanned_at", ""))
            previous = latest_master.get(master["Profile Key"])
            if previous is None or scanned_at >= previous[0]:
                latest_master[master["Profile Key"]] = (scanned_at, master)

            source_hash = str(metadata["source_hash"])
            for title, rows in self._detail_rows(profile, metadata, validation).items():
                if source_hash in seen_detail_hashes[title]:
                    continue
                detail_rows[title].extend(rows)
                seen_detail_hashes[title].add(source_hash)

        master_values = [
            [row.get(header, "") if row.get(header) is not None else "" for header in MASTER_HEADERS]
            for _, row in sorted(latest_master.values(), key=lambda item: (
                str(item[1].get("Name", "")).lower(),
                str(item[1].get("Profile Key", "")).lower(),
            ))
        ]

        datasets: dict[str, tuple[list[str], list[list[Any]]]] = {
            "Realtor Master": (MASTER_HEADERS, master_values)
        }
        for title, headers in DETAIL_HEADERS.items():
            datasets[title] = (
                headers,
                [
                    [row.get(header, "") if row.get(header) is not None else "" for header in headers]
                    for row in detail_rows[title]
                ],
            )

        for title, (headers, rows) in datasets.items():
            sheet = self._worksheet(title, headers)
            matrix = [headers, *rows]
            self._api_call(sheet.clear)
            self._api_call(
                sheet.update,
                values=matrix,
                range_name="A1",
                value_input_option="RAW",
            )
            self._values[title] = matrix

        self._master_rows = None
        self._detail_source_hashes.clear()
        logger.info(
            "Google Sheets batch sync completed: %s report(s), %s master realtor row(s).",
            len(records),
            len(master_values),
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

    def write_many(self, records: Sequence[SyncRecord]) -> None:
        for profile, metadata, validation in records:
            self.write(profile, metadata, validation)


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
        for writer in self.writers:
            writer.write(profile, metadata, validation)

    def write_many(self, records: Sequence[SyncRecord]) -> None:
        for writer in self.writers:
            writer.write_many(records)
