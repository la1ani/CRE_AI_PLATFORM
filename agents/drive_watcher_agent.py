"""
Drive Watcher Agent.

This agent monitors a Google Drive folder for new files, downloads
them locally for processing and then moves the processed files into
a separate "Processed" folder. It supports PDFs, spreadsheets and
other document formats commonly used in commercial real estate deal
packages. After downloading, it invokes the appropriate extraction
agent based on file type.

The watcher can be executed in a loop or scheduled via an external
cron/job scheduler. For long‑running deployments, consider running
this as a background process or service.
"""

from __future__ import annotations

import io
import logging
import mimetypes
import sys
import time
from pathlib import Path
from typing import List

# Ensure the project root is on the import path so sibling packages like
# config and database can be imported when this module is executed directly.
_root_path = Path(__file__).resolve().parents[1]
if str(_root_path) not in sys.path:
    sys.path.insert(0, str(_root_path))

from googleapiclient.discovery import build
from googleapiclient.http import MediaIoBaseDownload
import google.auth.transport.requests
from google.auth import default as google_auth_default
from google_auth_oauthlib.flow import InstalledAppFlow
from google.oauth2.credentials import Credentials

from config import settings
from . import (
    om_extraction_agent,
    rent_roll_agent,
    due_diligence_agent,
    seller_weakness_agent,
    deal_ranking_agent,
)
from database.supabase_client import SupabaseClient

logger = logging.getLogger(__name__)

SCOPES = ["https://www.googleapis.com/auth/drive"]


def _authenticate() -> Credentials:
    """
    Load stored credentials or run the OAuth flow to obtain new credentials.

    Returns:
        Credentials: OAuth credentials authorized for the Drive API.
    """
    creds = None
    token_file = Path("token.pickle")
    if token_file.exists():
        # Load existing token
        import pickle  # imported here to avoid global dependency if not used

        with token_file.open("rb") as f:
            creds = pickle.load(f)
    # If there are no (valid) credentials available, let the user log in.
    if not creds or not creds.valid:
        if creds and creds.expired and creds.refresh_token:
            creds.refresh(google.auth.transport.requests.Request())
        else:
            # Use the OAuth client credentials specified in settings. The client
            # secrets file should be placed in config/credentials.json.
            flow = InstalledAppFlow.from_client_secrets_file(
                str(Path("config") / "credentials.json"), SCOPES
            )
            creds = flow.run_local_server(port=0)
        # Save the credentials for the next run
        with token_file.open("wb") as f:
            import pickle

            pickle.dump(creds, f)
    return creds


class DriveWatcherAgent:
    """Watches a Google Drive folder for new files and processes them."""

    def __init__(
        self,
        folder_id: str,
        processed_folder_id: str,
        download_dir: Path,
        poll_interval: int = 300,
    ) -> None:
        """
        Args:
            folder_id: ID of the folder to monitor for incoming documents.
            processed_folder_id: ID of the folder where processed
                documents are moved.
            download_dir: Local directory where files are saved prior to
                processing.
            poll_interval: Number of seconds to wait between checks for
                new files. Defaults to 5 minutes (300 seconds).
        """
        settings.validate()
        self.folder_id = folder_id
        self.processed_folder_id = processed_folder_id
        self.download_dir = download_dir
        self.poll_interval = poll_interval
        self.supabase = SupabaseClient()
        self.creds = _authenticate()
        self.service = build("drive", "v3", credentials=self.creds)

    def _walk_folder(self, folder_id: str) -> List[dict]:
        """Recursively list all files inside a Drive folder."""
        files = []
        page_token = None

        query = f"'{folder_id}' in parents and trashed=false"
        while True:
            response = (
                self.service.files()
                .list(
                    q=query,
                    fields="nextPageToken, files(id,name,mimeType)",
                    pageToken=page_token,
                    includeItemsFromAllDrives=True,
                    supportsAllDrives=True,
                )
                .execute()
            )
            items = response.get("files", [])
            for item in items:
                if item.get("mimeType") == "application/vnd.google-apps.folder":
                    files.extend(self._walk_folder(item["id"]))
                else:
                    files.append(item)
            page_token = response.get("nextPageToken")
            if not page_token:
                break
        return files

    def list_new_files(self) -> List[dict]:
        root_files = []

        logger.info("Scanning Google Drive folder recursively: %s", self.folder_id)
        root_files = self._walk_folder(self.folder_id)

        logger.info("Found %s files total", len(root_files))
        return root_files

    def download_file(self, file_id: str, filename: str) -> Path:
        """Download a file from Google Drive to the local download directory.

        Args:
            file_id: The ID of the file to download.
            filename: The name to save the file as locally.

        Returns:
            Path to the downloaded file.
        """
        request = self.service.files().get_media(fileId=file_id)
        local_path = self.download_dir / filename
        fh = io.FileIO(str(local_path), "wb")
        downloader = MediaIoBaseDownload(fh, request)
        done = False
        while not done:
            status, done = downloader.next_chunk()
            if status:
                logger.debug("Download %s %% complete", int(status.progress() * 100))
        logger.info("Downloaded %s to %s", filename, local_path)
        return local_path

    def move_file_to_processed(self, file_id: str) -> None:
        """Move a file to the processed folder.

        Args:
            file_id: The ID of the file to move.
        """
        # Retrieve the existing parents to remove
        file_metadata = self.service.files().get(fileId=file_id, fields="parents").execute()
        previous_parents = ",".join(file_metadata.get("parents", []))
        # Move the file
        self.service.files().update(
            fileId=file_id,
            addParents=self.processed_folder_id,
            removeParents=previous_parents,
            fields="id, parents",
        ).execute()
        logger.info("Moved file %s to processed folder", file_id)

    def process_file(self, path: Path, mime_type: str) -> None:
        """Invoke extraction agents based on MIME type and store results.

        Args:
            path: Local filesystem path of the downloaded file.
            mime_type: Reported MIME type from Google Drive. Used to
                dispatch to the correct extraction agent.
        """
        # Process Offering Memorandum PDF
        if mime_type == "application/pdf" or path.suffix.lower() == ".pdf":
            property_data, broker_data = om_extraction_agent.extract_property_info(str(path))
            inserted_property = self.supabase.insert_property(property_data)
            self.supabase.insert_broker(broker_data)

            property_id = None
            if inserted_property and isinstance(inserted_property, dict):
                property_id = inserted_property.get("id") or inserted_property.get("property_id")
            if not property_id:
                property_id = property_data.get("id")

            # Run due diligence and seller weakness analysis
            dd_score, missing_items = due_diligence_agent.evaluate(property_data)
            sw_score, weaknesses = seller_weakness_agent.evaluate(property_data)
            # Rank deal
            ranking = deal_ranking_agent.rank(
                acquisition_score=property_data.get("acquisition_score", 0),
                risk_score=dd_score,
                seller_weakness_score=sw_score,
                upside_score=property_data.get("upside_score", 0),
            )
            # Insert analysis results
            analysis_record = {
                "property_id": property_id,
                "due_diligence_score": dd_score,
                "seller_weakness_score": sw_score,
                "overall_score": ranking.get("overall_score"),
                "missing_items": missing_items,
                "weaknesses": weaknesses,
            }
            self.supabase.insert_analysis(analysis_record)
        # Process rent roll spreadsheets
        elif mime_type in (
            "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet",
            "application/vnd.ms-excel",
            "text/csv",
        ):
            tenants = rent_roll_agent.extract_tenants(str(path))
            self.supabase.insert_tenants(tenants)
        else:
            logger.warning("Unsupported file type %s for file %s", mime_type, path)

    def run_once(self) -> None:
        """Check for new files once and process any found."""
        new_files = self.list_new_files()
        if not new_files:
            logger.info("No new files found in Google Drive folder")
            return
        logger.info("Found %d new files to process", len(new_files))
        for file_metadata in new_files:
            file_id = file_metadata["id"]
            filename = file_metadata["name"]
            mime_type = file_metadata.get("mimeType", mimetypes.guess_type(filename)[0] or "")
            local_file = self.download_file(file_id, filename)
            try:
                self.process_file(local_file, mime_type)
            except Exception as exc:
                logger.exception("Error processing file %s: %s", filename, exc)
            finally:
                # Move file to processed folder regardless of success
                try:
                    self.move_file_to_processed(file_id)
                except Exception:
                    logger.exception("Failed to move file %s to processed folder", filename)

    def run_forever(self) -> None:
        """Continuously monitor for new files at the configured interval."""
        logger.info(
            "Starting DriveWatcherAgent polling every %s seconds", self.poll_interval
        )
        while True:
            self.run_once()
            time.sleep(self.poll_interval)


__all__ = ["DriveWatcherAgent"]