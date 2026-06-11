"""
Configuration settings for the CRE_AI_PLATFORM automation project.

This module defines constants and helper functions used throughout the
application. Values are loaded from environment variables where
appropriate so secrets such as API keys do not need to be committed
to source control. When running locally, create a `.env` file in the
project root with the required variables or export them in your
terminal session.

Available settings:

  - GOOGLE_DRIVE_FOLDER_ID: The ID of the Google Drive folder to watch
    for new documents. Obtain this by opening the folder in Google
    Drive and copying the portion of the URL after `folders/`.
  - GOOGLE_DRIVE_PROCESSED_FOLDER_ID: The ID of the folder where
    processed files should be moved. Create this folder inside your
    watched folder and share it with the same credentials.
  - DOWNLOAD_DIR: Local directory where downloaded files are stored
    temporarily before processing. Defaults to `downloads/` under
    the project root.
  - SUPABASE_URL: The base URL of your Supabase instance.
  - SUPABASE_SERVICE_ROLE_KEY: A service role key with insert
    privileges on your Supabase project. Keep this secret.
  - GEMINI_API_KEY: API key for Google's Gemini model. Optional.
  - OPENAI_API_KEY: API key for OpenAI models used for due diligence
    and memo generation. Optional.
  - DEEPSEEK_API_KEY: API key for DeepSeek extraction tasks. Optional.

You can extend this module to include other configuration options
required by your platform.
"""

import os
from pathlib import Path

from dotenv import load_dotenv

# Load variables from a .env file if present. This allows local
# development without polluting your global environment. The `.env`
# file should be placed in the project root (same directory as
# `main.py`) and contain key=value pairs.
load_dotenv()

# Google Drive configuration
GOOGLE_DRIVE_FOLDER_ID: str = os.getenv("GOOGLE_DRIVE_FOLDER_ID", "")
GOOGLE_DRIVE_PROCESSED_FOLDER_ID: str = os.getenv(
    "GOOGLE_DRIVE_PROCESSED_FOLDER_ID", ""
)

# Local download directory
DOWNLOAD_DIR: Path = Path(os.getenv("DOWNLOAD_DIR", "downloads")).resolve()
DOWNLOAD_DIR.mkdir(parents=True, exist_ok=True)

# Supabase configuration
SUPABASE_URL: str = os.getenv("SUPABASE_URL", "")
SUPABASE_SERVICE_ROLE_KEY: str = os.getenv("SUPABASE_SERVICE_ROLE_KEY", "")

# AI service keys (optional)
GEMINI_API_KEY: str = os.getenv("GEMINI_API_KEY", "")
OPENAI_API_KEY: str = os.getenv("OPENAI_API_KEY", "")
DEEPSEEK_API_KEY: str = os.getenv("DEEPSEEK_API_KEY", "")

# Logging configuration
LOG_LEVEL: str = os.getenv("LOG_LEVEL", "INFO")


def validate() -> None:
    """Validate required configuration values.

    Raises:
        RuntimeError: If any required configuration is missing.
    """
    missing = []
    if not GOOGLE_DRIVE_FOLDER_ID:
        missing.append("GOOGLE_DRIVE_FOLDER_ID")
    if not GOOGLE_DRIVE_PROCESSED_FOLDER_ID:
        missing.append("GOOGLE_DRIVE_PROCESSED_FOLDER_ID")
    if not SUPABASE_URL:
        missing.append("SUPABASE_URL")
    if not SUPABASE_SERVICE_ROLE_KEY:
        missing.append("SUPABASE_SERVICE_ROLE_KEY")
    if missing:
        raise RuntimeError(
            f"Missing required configuration values: {', '.join(missing)}"
        )


__all__ = [
    "GOOGLE_DRIVE_FOLDER_ID",
    "GOOGLE_DRIVE_PROCESSED_FOLDER_ID",
    "DOWNLOAD_DIR",
    "SUPABASE_URL",
    "SUPABASE_SERVICE_ROLE_KEY",
    "GEMINI_API_KEY",
    "OPENAI_API_KEY",
    "DEEPSEEK_API_KEY",
    "LOG_LEVEL",
    "validate",
]