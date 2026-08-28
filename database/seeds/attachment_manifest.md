# Canonical OM attachment manifest

Audited 2026-08-28 for the production `cre-ai-project` Supabase database.

Every canonical property has a `documents` row with a non-null attachment locator. Actual OM/flyer binaries are kept outside the Git repository: older files are in the private Supabase Storage bucket `offering-memorandums`; newer files are in Google Drive. The `documents.drive_file_id` field is treated as a document locator:

- `offering-memorandums/<filename>` = private Supabase Storage object.
- `gdrive:<file_id>` = Google Drive file.

| # | Property | Source PDF | Locator |
|---:|---|---|---|
| 1 | Cypress Station Square | texas-cypress-station-square.pdf | `gdrive:1aJryfU7pKPiu5pwWkvk7syUfMMMvSJD_` |
| 2 | Point West Center | texas-point-west-center.pdf | `gdrive:1AFZS2I3a9fmitJKyfV3MSiL9FXLh0_cK` |
| 3 | Griggs Rd Shopping Center | Griggs Rd Shopping Center.pdf | `offering-memorandums/Griggs Rd Shopping Center.pdf` |
| 4 | South Loop Center | South Loop Center.pdf | `offering-memorandums/South Loop Center.pdf` |
| 5 | Sablechase Plaza | Sablechase Plaza.pdf | `offering-memorandums/Sablechase Plaza.pdf` |
| 6 | Kuykendahl Plaza | Kuykendahl Plaza.pdf | `offering-memorandums/Kuykendahl Plaza.pdf` |
| 7 | 821 FM 1960 - Texas Car Title & Payday Loan | 821 Fm 1960 - Texas Car Title & Payday Loan.pdf | `offering-memorandums/821 Fm 1960 - Texas Car Title & Payday Loan.pdf` |
| 8 | Clearwood Crossing | Clearwood Crossing.pdf | `offering-memorandums/Clearwood Crossing.pdf` |
| 9 | AW Plaza | AW Plaza - Retail Center.pdf | `offering-memorandums/AW Plaza - Retail Center.pdf` |
| 10 | Meadow III Retail | Meadow III Retail.pdf | `offering-memorandums/Meadow III Retail.pdf` |
| 11 | Kuykendahl & West Rayford Plaza | Kuykendahl & West Rayford Plaza.pdf | `offering-memorandums/Kuykendahl & West Rayford Plaza.pdf` |
| 12 | 26333 I-45 N | 26333 I-45 N.pdf | `gdrive:1xREG2PM7DBWDbRJNB1gxuTWa3sWgBiwo` |
| 13 | Little York Plaza | Little York Plaza.pdf | `gdrive:1SrW5X1gwaVTr-gtIWwvGURyUTOzqZlzH` |
| 14 | Copper Grove Corner | Copper Grove Corner.pdf | `gdrive:1boqPshwpavRAKWouaY1ylNSJPAo3Vr0b` |
| 15 | 6410-6578 FM 1960 Rd | 6410-6578 FM 1960 Rd.pdf | `gdrive:1d_XRhhOHegXv5ueE-RlRs7KZY882Itvr` |
| 16 | Market at Northpointe | Market at Northpointe.pdf | `gdrive:1CSFP8yu8CQrgHvO1vkyJsAzyoZDJcrC0` |
| 17 | 4145 Gessner | 100% Leased 6-Tenant Trophy Retail Center.pdf | `gdrive:1QV4XnAYimW7CjBp6S9wmBSmDHDj54l92` |
| 18 | Plazas at Midtown I | Plazas at Midtown I & II.pdf | `gdrive:1nZtJ15ufToBTASmcLN4VbvOhD8zJ7zdI` |
| 19 | Plazas at Midtown II | Plazas at Midtown I & II.pdf | `gdrive:1nZtJ15ufToBTASmcLN4VbvOhD8zJ7zdI` |
| 20 | Burlington - 10311 I-45 N | Burlington Houston TX.pdf | `gdrive:1RjQcasteaWu4o9SleDWpUlJEw6kniYbb` |
| 21 | 210 Woerner Rd | Prime Hard Corner Location.pdf | `gdrive:1l3wEN3w9t1g3n7lW9WlOt4UZ8F7yMjKX` |

## Integrity notes

- There are 21 property/document relationships but 20 distinct source PDFs because Midtown I and Midtown II intentionally share one portfolio OM.
- All nine `offering-memorandums/...` locators were verified against actual rows in `storage.objects`.
- All newly uploaded `gdrive:` locators were created/verified as real Google Drive PDF files during the attachment audit.
- Point West Center currently links to the existing `Point_West_Center_key_pages.pdf` Drive copy under the canonical database source name `texas-point-west-center.pdf`. It contains the key property source pages. Replace this locator if/when the complete original flyer binary is supplied; do not silently claim the derivative is the original full file.
- PDF binaries are intentionally not committed to Git. Git stores reproducible structured seed data and this locator manifest; the file backends store the actual PDFs.
- No passwords, API keys, service-role keys, or other secrets belong in this manifest.
