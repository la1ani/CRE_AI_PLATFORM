from __future__ import annotations

import argparse
import json
import logging
import os
import re
from pathlib import Path
from typing import Any

import gspread
from dotenv import load_dotenv
from google.auth.transport.requests import AuthorizedSession, Request
from google.oauth2.credentials import Credentials
from google_auth_oauthlib.flow import InstalledAppFlow

from .scanner import LocalProfileScanner, ScannerConfig

logger = logging.getLogger(__name__)

SCOPES = [
    "https://www.googleapis.com/auth/spreadsheets.readonly",
    "https://www.googleapis.com/auth/drive.readonly",
]
DEFAULT_SOURCE_SHEET_ID = "15Ps0ksscpjA9M5wrdh9l_vkzYVpp0Ro-iFKFOH9-eoM"
DEFAULT_SOURCE_TAB = "realtor"
DRIVE_FILE_RE = re.compile(r"/d/([A-Za-z0-9_-]+)|[?&]id=([A-Za-z0-9_-]+)")
SUPPORTED_EXTENSIONS = {".png", ".jpg", ".jpeg", ".webp"}


def _clean(value: Any) -> str:
    return "" if value is None else str(value).strip()


def _safe_filename(name: str, fallback: str) -> str:
    candidate = Path(name).name.strip() or fallback
    candidate = re.sub(r"[<>:\"/\\|?*]+", "_", candidate)
    suffix = Path(candidate).suffix.lower()
    if suffix not in SUPPORTED_EXTENSIONS:
        candidate = f"{Path(candidate).stem or fallback}.png"
    return candidate


def _extract_file_id(url: str) -> str:
    match = DRIVE_FILE_RE.search(url)
    if not match:
        return ""
    return match.group(1) or match.group(2) or ""


def _oauth_credentials(client_file: Path, token_file: Path) -> Credentials:
    credentials: Credentials | None = None
    if token_file.exists():
        try:
            credentials = Credentials.from_authorized_user_file(str(token_file), SCOPES)
        except Exception:
            logger.warning("OAuth token was unreadable; a new login will be requested.")

    if credentials and credentials.expired and credentials.refresh_token:
        credentials.refresh(Request())

    if not credentials or not credentials.valid or not set(SCOPES).issubset(set(credentials.scopes or [])):
        if not client_file.exists():
            raise RuntimeError(
                f"Google OAuth desktop client file was not found: {client_file}. "
                "Download a Desktop app OAuth client JSON and save it there."
            )
        flow = InstalledAppFlow.from_client_secrets_file(str(client_file), SCOPES)
        credentials = flow.run_local_server(port=0, open_browser=True)

    token_file.parent.mkdir(parents=True, exist_ok=True)
    token_file.write_text(credentials.to_json(), encoding="utf-8")
    return credentials


def _load_state(path: Path) -> dict[str, dict[str, Any]]:
    if not path.exists():
        return {}
    try:
        return json.loads(path.read_text(encoding="utf-8"))
    except Exception:
        logger.warning("Drive profile state was unreadable; starting with an empty state.")
        return {}


def _save_state(path: Path, state: dict[str, dict[str, Any]]) -> None:
    temporary = path.with_suffix(".tmp")
    temporary.write_text(json.dumps(state, indent=2), encoding="utf-8")
    temporary.replace(path)


def _unique_path(path: Path) -> Path:
    if not path.exists():
        return path
    for index in range(1, 10_000):
        candidate = path.with_name(f"{path.stem}-{index}{path.suffix}")
        if not candidate.exists():
            return candidate
    raise RuntimeError(f"Could not create a unique path for {path}")


def download_saved_profiles(
    config: ScannerConfig,
    credentials: Credentials,
    source_sheet_id: str,
    source_tab: str,
    limit: int,
) -> tuple[int, int, int]:
    folders = config.prepare()
    state_path = config.root / ".drive_profile_state.json"
    state = _load_state(state_path)

    client = gspread.authorize(credentials)
    book = client.open_by_key(source_sheet_id)
    worksheet = book.worksheet(source_tab)
    rows = worksheet.get_all_values()
    if not rows:
        return 0, 0, 0

    headers = [header.strip() for header in rows[0]]
    required = ["Status", "Screenshot File Name", "Google Drive Link"]
    missing = [name for name in required if name not in headers]
    if missing:
        raise RuntimeError(f"Source tab is missing required column(s): {', '.join(missing)}")

    indexes = {name: headers.index(name) for name in required}
    profile_url_index = headers.index("Profile URL") if "Profile URL" in headers else None
    session = AuthorizedSession(credentials)

    downloaded = 0
    skipped = 0
    failed = 0

    for row_number, row in enumerate(rows[1:], start=2):
        def cell(column: str) -> str:
            index = indexes[column]
            return _clean(row[index]) if index < len(row) else ""

        status = cell("Status").lower()
        drive_url = cell("Google Drive Link")
        if status != "completed" or not drive_url:
            continue

        file_id = _extract_file_id(drive_url)
        if not file_id:
            failed += 1
            logger.warning("Row %s has an unreadable Drive link: %s", row_number, drive_url)
            continue
        if file_id in state:
            skipped += 1
            continue
        if limit > 0 and downloaded >= limit:
            break

        filename = _safe_filename(cell("Screenshot File Name"), f"profile-{file_id}.png")
        target = _unique_path(folders["incoming"] / filename)
        url = f"https://www.googleapis.com/drive/v3/files/{file_id}?alt=media&supportsAllDrives=true"

        try:
            response = session.get(url, timeout=120)
            response.raise_for_status()
            target.write_bytes(response.content)
            profile_url = ""
            if profile_url_index is not None and profile_url_index < len(row):
                profile_url = _clean(row[profile_url_index])
            state[file_id] = {
                "source_sheet_id": source_sheet_id,
                "source_tab": source_tab,
                "source_row": row_number,
                "profile_url": profile_url,
                "drive_url": drive_url,
                "downloaded_file": str(target),
            }
            _save_state(state_path, state)
            downloaded += 1
            logger.info("Downloaded %s", filename)
        except Exception as exc:
            failed += 1
            logger.warning("Failed to download row %s (%s): %s", row_number, filename, exc)

    return downloaded, skipped, failed


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(
        description="Download saved realtor profile screenshots from Google Drive and run the local vision scanner."
    )
    parser.add_argument("--download-limit", type=int, default=100, help="Maximum new Drive images to download; 0 means unlimited.")
    parser.add_argument("--download-only", action="store_true", help="Download images but do not call Gemini.")
    return parser


def main() -> None:
    load_dotenv()
    args = build_parser().parse_args()
    logging.basicConfig(level=os.getenv("LOG_LEVEL", "INFO"), format="%(asctime)s [%(levelname)s] %(message)s")

    config = ScannerConfig.from_env()
    client_file = Path(
        os.getenv("GOOGLE_PROFILE_OAUTH_CLIENT_FILE", r"C:\RealtorProfileScanner\oauth_credentials.json")
    ).expanduser()
    token_file = Path(
        os.getenv("GOOGLE_PROFILE_OAUTH_TOKEN_FILE", r"C:\RealtorProfileScanner\profile_drive_oauth_token.json")
    ).expanduser()
    source_sheet_id = os.getenv("PROFILE_SOURCE_SHEET_ID", DEFAULT_SOURCE_SHEET_ID).strip()
    source_tab = os.getenv("PROFILE_SOURCE_TAB", DEFAULT_SOURCE_TAB).strip()

    credentials = _oauth_credentials(client_file, token_file)
    downloaded, skipped, failed = download_saved_profiles(
        config=config,
        credentials=credentials,
        source_sheet_id=source_sheet_id,
        source_tab=source_tab,
        limit=max(0, args.download_limit),
    )
    print(f"Drive download complete: {downloaded} new, {skipped} already imported, {failed} failed.")

    if args.download_only:
        return

    scanner = LocalProfileScanner(config)
    processed = scanner.scan_once()
    print(f"Vision scan complete: {processed} profile screenshot(s) processed.")


if __name__ == "__main__":
    main()
