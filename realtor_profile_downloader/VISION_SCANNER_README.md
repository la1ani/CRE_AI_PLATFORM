# Realtor Profile AI Vision Scanner

This scanner reads long PNG/JPG realtor profile screenshots saved on a Windows computer, divides each image into overlapping sections, sends all labeled sections to Gemini Vision in one structured request, validates totals, and writes the results to Google Sheets, Supabase, or both.

Using one request for all crops reduces API usage from six requests per realtor to one request per realtor.

## What it extracts

- Realtor identity, brokerage, email, phone, languages and summary metrics
- Buyer/seller performance summary
- Loan officer and loan company relationships
- Visible transaction-table rows and footer totals
- Retail/wholesale loan details and visible loan-table rows
- Title-company relationships and recent listings when present

The scanner never invents rows hidden inside an internally scrollable table. A screenshot that says `Showing 1 to 6 of 26 entries` is stored as six visible rows and 26 expected rows, with status `PARTIAL_HIDDEN_ROWS`.

Validation also reduces the score when monthly chart labels are detected but chart values are unreadable. When visible title-company relationship counts do not cover all buyer/seller sides, the profile is marked `PARTIAL_HIDDEN_ROWS` rather than incorrectly marked complete.

## Install on Windows

Use the actual cloned project path:

```powershell
cd C:\Users\HP\CRE_AI_PLATFORM
git switch agent/realtor-profile-ai-vision
git pull origin agent/realtor-profile-ai-vision

if (-not (Test-Path ".venv\Scripts\python.exe")) {
    py -m venv .venv
}
.\.venv\Scripts\python.exe -m pip install --upgrade pip
.\.venv\Scripts\python.exe -m pip install -r realtor_profile_downloader\requirements-vision.txt
```

Calling `.venv\Scripts\python.exe` directly avoids PowerShell activation-policy problems.

Copy the example configuration when `.env` does not already exist:

```powershell
Copy-Item realtor_profile_downloader\.env.vision.example .env
notepad .env
```

Set Gemini and the local folder:

```env
GEMINI_API_KEY=your_key
GEMINI_MODEL=gemini-3.1-flash-lite
GEMINI_FALLBACK_MODELS=gemini-3.5-flash,gemini-2.5-flash
REALTOR_PROFILE_ROOT=C:\RealtorProfileScanner
```

## Google Sheets setup

1. Create a blank Google spreadsheet.
2. Copy the spreadsheet ID from its URL. It is the text between `/d/` and `/edit`.
3. In Google Cloud, enable the Google Sheets API and Google Drive API.
4. Create a service account and download its JSON key.
5. Save the key locally, for example:

```text
C:\RealtorProfileScanner\service_account.json
```

6. Open the JSON file and copy the `client_email` value.
7. Share the Google spreadsheet with that email as **Editor**.
8. Add these values to `.env`:

```env
GOOGLE_SHEET_ID=your_spreadsheet_id
GOOGLE_SERVICE_ACCOUNT_FILE=C:\RealtorProfileScanner\service_account.json
```

Verify the connection and automatically create all worksheet tabs:

```powershell
.\.venv\Scripts\python.exe -m realtor_profile_downloader.vision_scanner.scanner --setup-storage
```

The command creates/verifies:

- Realtor Master
- LO Relationships
- Loan Companies
- Visible Transactions
- Loan Details
- Title Companies
- Listings
- Scan Review

## Sync reports that were already scanned

Profiles scanned before Google Sheets was configured do not need another Gemini request. Upload every existing JSON report with:

```powershell
.\.venv\Scripts\python.exe -m realtor_profile_downloader.vision_scanner.scanner --sync-reports
```

This command recalculates validation using the latest rules, updates each local report, and writes it to Google Sheets/Supabase. Repeating the command replaces records from the same source hash instead of duplicating them.

## Supabase setup

Add the project URL and service-role key to `.env`, then run `sql/realtor_profile_vision_schema.sql` once in the Supabase SQL editor:

```env
SUPABASE_URL=your_project_url
SUPABASE_SERVICE_ROLE_KEY=your_service_role_key
```

Run `--setup-storage` to test the schema and credentials.

## Folder structure

The first run creates:

```text
C:\RealtorProfileScanner\
  incoming\
  processing\
  processed\
  review\
  failed\
  crops\
  reports\
```

Put saved PNG/JPG profiles into `incoming`.

## Run once

```powershell
.\.venv\Scripts\python.exe -m realtor_profile_downloader.vision_scanner.scanner --once
```

## Continuously watch the folder

```powershell
.\.venv\Scripts\python.exe -m realtor_profile_downloader.vision_scanner.scanner --watch
```

## List models available to the Gemini key

```powershell
.\.venv\Scripts\python.exe -m realtor_profile_downloader.vision_scanner.scanner --list-models
```

## Gemini quota behavior

Gemini quotas are applied per Google Cloud project and can differ by model. When the primary model is unavailable or its model-specific quota is exhausted, the scanner tries the configured fallback model. If every configured model is out of quota, processing stops and the current screenshot is returned to `incoming`; it is not moved to `failed` and is not lost.

## Output status

- `COMPLETE`: visible data is complete and validation totals align
- `PARTIAL_HIDDEN_ROWS`: usable summary, but hidden table rows or partial title relationships exist
- `LOW_CONFIDENCE`: effective average section confidence is below 75
- `TOTAL_MISMATCH`: buyer + seller does not equal total
- `NEEDS_REVIEW`: a critical identity or count validation rule failed

A complete JSON audit report is written to the `reports` folder for every processed profile.
