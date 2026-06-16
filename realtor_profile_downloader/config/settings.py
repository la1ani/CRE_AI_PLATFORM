from __future__ import annotations

import os
from dataclasses import dataclass
from pathlib import Path


BASE_DIR = Path(__file__).resolve().parents[1]


@dataclass(frozen=True)
class Settings:
    """Runtime settings loaded from environment variables.

    Required:
      GOOGLE_SHEET_ID: Spreadsheet ID from the Google Sheets URL.
      GOOGLE_SERVICE_ACCOUNT_FILE: Path to service account JSON.

    Strongly recommended for extension control:
      CHROME_USER_DATA_DIR: Chrome profile/user-data directory that already has the extension installed.
      EXTENSION_ID: Chrome extension ID, used to open chrome-extension://<id>/popup.html.
    """

    google_sheet_id: str = os.getenv("GOOGLE_SHEET_ID", "").strip()
    google_sheet_name: str = os.getenv("GOOGLE_SHEET_NAME", "Sheet1").strip()
    google_service_account_file: str = os.getenv("GOOGLE_SERVICE_ACCOUNT_FILE", "service_account.json").strip()

    chrome_user_data_dir: str = os.getenv("CHROME_USER_DATA_DIR", str(BASE_DIR / "chrome_profile")).strip()
    chrome_executable_path: str = os.getenv("CHROME_EXECUTABLE_PATH", "").strip()
    headless: bool = os.getenv("HEADLESS", "false").lower() in {"1", "true", "yes"}
    slow_mo_ms: int = int(os.getenv("SLOW_MO_MS", "0"))

    extension_id: str = os.getenv("EXTENSION_ID", "").strip()
    extension_popup_path: str = os.getenv("EXTENSION_POPUP_PATH", "popup.html").strip()
    extension_save_timeout_ms: int = int(os.getenv("EXTENSION_SAVE_TIMEOUT_MS", "60000"))

    downloads_dir: Path = BASE_DIR / "downloads"
    profiles_dir: Path = BASE_DIR / "downloads" / "profiles"
    screenshots_dir: Path = BASE_DIR / "screenshots"
    logs_dir: Path = BASE_DIR / "logs"

    profile_load_timeout_ms: int = int(os.getenv("PROFILE_LOAD_TIMEOUT_MS", "90000"))
    profile_dynamic_wait_ms: int = int(os.getenv("PROFILE_DYNAMIC_WAIT_MS", "2500"))
    download_timeout_ms: int = int(os.getenv("DOWNLOAD_TIMEOUT_MS", "90000"))
    retry_count: int = int(os.getenv("RETRY_COUNT", "3"))

    preserve_original_filename: bool = os.getenv("PRESERVE_ORIGINAL_FILENAME", "false").lower() in {"1", "true", "yes"}

    def validate(self) -> None:
        if not self.google_sheet_id:
            raise RuntimeError("Missing GOOGLE_SHEET_ID environment variable.")
        if not Path(self.google_service_account_file).exists():
            raise RuntimeError(f"Google service account file not found: {self.google_service_account_file}")
        self.downloads_dir.mkdir(parents=True, exist_ok=True)
        self.profiles_dir.mkdir(parents=True, exist_ok=True)
        self.screenshots_dir.mkdir(parents=True, exist_ok=True)
        self.logs_dir.mkdir(parents=True, exist_ok=True)


settings = Settings()
