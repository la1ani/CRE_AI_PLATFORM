# Realtor Profile AI Vision Scanner

This scanner reads long PNG/JPG realtor profile screenshots saved on a Windows computer, divides each image into overlapping sections, sends each section to Gemini Vision with a strict Pydantic schema, validates totals, and writes the results to Google Sheets, Supabase, or both.

## What it extracts

- Realtor identity, brokerage, email, phone, languages and summary metrics
- Buyer/seller performance summary
- Loan officer and loan company relationships
- Visible transaction-table rows and footer totals
- Retail/wholesale loan details and visible loan-table rows
- Title-company relationships and recent listings when present

The scanner never invents rows hidden inside an internally scrollable table. A screenshot that says `Showing 1 to 6 of 26 entries` is stored as six visible rows and 26 expected rows, with status `PARTIAL_HIDDEN_ROWS`.

## Install

```powershell
cd C:\path\to\CRE_AI_PLATFORM
py -3.11 -m venv .venv
.\.venv\Scripts\Activate.ps1
python -m pip install -r realtor_profile_downloader\requirements-vision.txt
```

Copy the example configuration:

```powershell
Copy-Item realtor_profile_downloader\.env.vision.example .env
```

Set at least:

- `GEMINI_API_KEY`
- either Google Sheets credentials, Supabase credentials, or both

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
python -m realtor_profile_downloader.vision_scanner.scanner --once
```

## Continuously watch the folder

```powershell
python -m realtor_profile_downloader.vision_scanner.scanner --watch
```

## Output status

- `COMPLETE`: all visible sections were extracted and counts align
- `PARTIAL_HIDDEN_ROWS`: summary is usable, but the screenshot contains hidden table rows
- `LOW_CONFIDENCE`: average section confidence is below 75
- `TOTAL_MISMATCH`: buyer + seller does not equal total
- `NEEDS_REVIEW`: a critical identity field or validation rule failed

A complete JSON audit report is written to the `reports` folder for every processed profile.
