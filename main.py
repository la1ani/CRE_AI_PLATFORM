import logging
import sys

from agents.drive_watcher_agent import DriveWatcherAgent
from config import settings


def setup_logging() -> None:
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
        poll_interval=300,
    )

    try:
        watcher.run_forever()
    except KeyboardInterrupt:
        logging.info("Shutting down Drive watcher.")


if __name__ == "__main__":
    main()