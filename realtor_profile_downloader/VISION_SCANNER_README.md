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

## Install on Windows

Use the actual cloned project path. For example:

```powershell
cd C:\Users\HP\CRE_AI_PLATFORM
git switch agent/realtor-profile-ai-vision
git pull origin agent/realtor-profile-ai-vision

py -m venv .venv
.\.venv\Scripts\python.exe -m pip install --upgrade pip
.\.venv\Scripts\python.exe -m pip install -r realtor_profile_downloader\requirements-vision.txt
```

Calling `.venv\Scripts\python.exe` directly avoids PowerShell activation-policy problems.

Copy the example configuration when `.env` does not already exist:

```powershell
Copy-Item realtor_profile_downloader\.env.vision.example .env
notepad .env
```

Set at least:

```env
GEMINI_API_KEY=your_key
GEMINI_MODEL=gemini-2.5-flash-lite
GEMINI_FALLBACK_MODELS=gemini-2.5-flash
REALTOR_PROFILE_ROOT=C:\RealtorProfileScanner
```

Also configure either Google Sheets credentials, Supabase credentials, or both.

For Google Sheets, share the spreadsheet with the service-account email in the JSON credentials file.

For Supabase, run `sql/realtor_profile_vision_schema.sql` once in the Supabase SQL editor.

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

## Gemini quota behavior

Gemini quotas are applied per Google Cloud project and can differ by model. When the primary model is unavailable or its model-specific quota is exhausted, the scanner tries the configured fallback model. If every configured model is out of quota, processing stops and the current screenshot is returned to `incoming`; it is not moved to `failed` and is not lost.

Check current limits in Google AI Studio. Daily quotas reset according to Google's quota schedule.

## Output status

- `COMPLETE`: all visible sections were extracted and counts align
- `PARTIAL_HIDDEN_ROWS`: summary is usable, but the screenshot contains hidden table rows
- `LOW_CONFIDENCE`: average section confidence is below 75
- `TOTAL_MISMATCH`: buyer + seller does not equal total
- `NEEDS_REVIEW`: a critical identity field or validation rule failed

A complete JSON audit report is written to the `reports` folder for every processed profile.
