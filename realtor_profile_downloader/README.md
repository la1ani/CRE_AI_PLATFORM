# Realtor Profile Downloader

This package reads realtor profile URLs from Google Sheets, opens each profile in Chrome with Playwright, expands the page when possible, saves the completed profile, and updates the sheet.

## Required environment variables

```bash
GOOGLE_SHEET_ID=your_google_sheet_id
GOOGLE_SHEET_NAME=Sheet1
GOOGLE_SERVICE_ACCOUNT_FILE=service_account.json
CHROME_USER_DATA_DIR=C:/path/to/chrome/profile
HEADLESS=false
```

Optional:

```bash
CHROME_EXECUTABLE_PATH=C:/Program Files/Google/Chrome/Application/chrome.exe
PROFILE_LOAD_TIMEOUT_MS=90000
PROFILE_DYNAMIC_WAIT_MS=2500
RETRY_COUNT=3
```

## Sheet columns

Required input columns:

- ID
- Profile URL
- Status

The program adds these if missing:

- File Name
- File Path
- Date Saved
- Error Message

## Run

```bash
cd CRE_AI_PLATFORM
pip install -r realtor_profile_downloader/requirements.txt
python -m realtor_profile_downloader.main
```

## Notes

Use a real Chrome user data directory that already has any required login session and extension installed. The browser launches once, processes pending rows, and closes at the end.
