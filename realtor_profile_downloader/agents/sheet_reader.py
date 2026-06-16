from __future__ import annotations

from dataclasses import dataclass
from datetime import datetime
from typing import Any

import gspread
from google.oauth2.service_account import Credentials


REQUIRED_COLUMNS = [
    "ID",
    "Profile URL",
    "Status",
    "File Name",
    "File Path",
    "Date Saved",
    "Error Message",
]


@dataclass
class ProfileRow:
    row_number: int
    data: dict[str, Any]

    @property
    def profile_id(self) -> str:
        return str(self.data.get("ID", "")).strip()

    @property
    def url(self) -> str:
        return str(self.data.get("Profile URL", "")).strip()

    @property
    def status(self) -> str:
        return str(self.data.get("Status", "")).strip()


class GoogleSheetReader:
    def __init__(self, spreadsheet_id: str, worksheet_name: str, service_account_file: str) -> None:
        scopes = [
            "https://www.googleapis.com/auth/spreadsheets",
            "https://www.googleapis.com/auth/drive",
        ]
        credentials = Credentials.from_service_account_file(service_account_file, scopes=scopes)
        client = gspread.authorize(credentials)
        spreadsheet = client.open_by_key(spreadsheet_id)
        self.worksheet = spreadsheet.worksheet(worksheet_name)
        self.headers = self.ensure_required_columns()

    def ensure_required_columns(self) -> list[str]:
        values = self.worksheet.get_all_values()
        if not values:
            self.worksheet.append_row(REQUIRED_COLUMNS)
            return REQUIRED_COLUMNS.copy()

        headers = [h.strip() for h in values[0]]
        changed = False
        for col in REQUIRED_COLUMNS:
            if col not in headers:
                headers.append(col)
                changed = True

        if changed:
            self.worksheet.update("1:1", [headers])
        return headers

    def _column_number(self, column_name: str) -> int:
        if column_name not in self.headers:
            self.headers = self.ensure_required_columns()
        return self.headers.index(column_name) + 1

    def get_pending_rows(self) -> list[ProfileRow]:
        records = self.worksheet.get_all_records(expected_headers=self.headers)
        rows: list[ProfileRow] = []
        for idx, record in enumerate(records, start=2):
            status = str(record.get("Status", "")).strip().lower()
            url = str(record.get("Profile URL", "")).strip()
            if status == "pending" and url:
                rows.append(ProfileRow(row_number=idx, data=record))
        return rows

    def get_first_pending_row(self) -> ProfileRow | None:
        rows = self.get_pending_rows()
        return rows[0] if rows else None

    def update_row_values(self, row_number: int, values: dict[str, Any]) -> None:
        updates = []
        for key, value in values.items():
            col = self._column_number(key)
            updates.append({"range": gspread.utils.rowcol_to_a1(row_number, col), "values": [[value]]})
        if updates:
            self.worksheet.batch_update(updates)

    def mark_processing(self, row_number: int) -> None:
        self.update_row_values(row_number, {"Status": "Processing", "Error Message": ""})

    def mark_complete(self, row_number: int, file_name: str, file_path: str) -> None:
        self.update_row_values(
            row_number,
            {
                "Status": "Complete",
                "File Name": file_name,
                "File Path": file_path,
                "Date Saved": datetime.now().strftime("%Y-%m-%d %H:%M:%S"),
                "Error Message": "",
            },
        )

    def mark_failed(self, row_number: int, error_message: str) -> None:
        self.update_row_values(
            row_number,
            {
                "Status": "Failed",
                "Error Message": error_message[:5000],
            },
        )
