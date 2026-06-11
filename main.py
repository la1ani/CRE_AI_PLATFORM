"""
Entry point for the CRE_AI_PLATFORM automation.

This script instantiates the DriveWatcherAgent using configuration
values and starts monitoring the Google Drive folder. The watcher
automatically downloads new files, processes them using the various
agents and uploads results to Supabase. Adjust the poll interval in
`config/settings.py` or override via environment variables.
"""

import logging
import sys

from agents.drive_watcher_agent import DriveWatcherAgent
from config import settings

def setup_logging() -> None:
    """Configure root logger to write to stdout."""
    level = getattr(logging, settings.LOG_LEVEL.upper(), logging.INFO)
    logging.basicConfig(
        level=level,
        format="%(asctime)s [%(levelname)s] %(name)s - %(message)s",
        handlers=[logging.StreamHandler(sys.stdout)],
    )


def main() -> None:
    setup_logging()
    settings.validate()
    watcher = DriveWatcherAgent(
        folder_id=settings.GOOGLE_DRIVE_FOLDER_ID,
        processed_folder_id=settings.GOOGLE_DRIVE_PROCESSED_FOLDER_ID,
        download_dir=settings.DOWNLOAD_DIR,
        poll_interval=300,  # poll every 5 minutes by default
    )
    try:
        watcher.run_forever()
    except KeyboardInterrupt:
        logging.info("Shutting down Drive watcher.")


if __name__ == "__main__":
    main()