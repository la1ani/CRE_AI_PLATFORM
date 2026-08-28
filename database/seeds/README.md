# Supabase seed files

These SQL files contain idempotent property inserts for the CRE AI Platform.
They target the existing production Supabase schema, whose property references
use text IDs in some tables and stable bigint IDs in others.

- `mallard_cove_existing_supabase_schema.sql`: Mallard Cove Professional Building.
- `upload_cypress_point_west_existing_schema.sql`: Cypress Station Square and Point West Center.
- `upload_next5_oms_existing_schema.sql`: 821 FM 1960, Griggs Rd Shopping Center, Kuykendahl Plaza, Sablechase Plaza, and South Loop Center.
- `upload_kuykendahl_west_rayford_existing_schema.sql`: Kuykendahl & West Rayford Plaza.
- `upload_aw_clearwood_meadow_existing_schema.sql`: AW Plaza, Clearwood Crossing, and Meadow III Retail.
- `upload_26333_little_york_copper_fm1960_northpointe_existing_schema.sql`: 26333 I-45 N, Little York Plaza, Copper Grove Corner, 6410-6578 FM 1960 Rd, and Market at Northpointe.
- `upload_6410_full_rent_roll_existing_schema.sql`: complete normalized 33-suite rent roll and tenant rows for 6410-6578 FM 1960 Rd (136,738 SF total; 47.4% occupied / 52.6% vacant).
- `upload_4145_midtown_burlington_woerner_existing_schema.sql`: 4145 Gessner, Plazas at Midtown I, Plazas at Midtown II, Burlington - 10311 I-45 N, and 210 Woerner Rd.
- `upload_4145_midtown_burlington_woerner_rent_rolls.sql`: 23 normalized rent-roll rows and 23 tenant rows for 4145 Gessner, Midtown I, Midtown II, and Burlington. 210 Woerner Rd is vacant development land and has no tenant rows.
- `attachment_manifest.md`: canonical property-to-PDF attachment mapping and backend audit.

## Canonical 21-property audit set

The production database has canonical structured records for:

1. Cypress Station Square
2. Point West Center
3. Griggs Rd Shopping Center
4. South Loop Center
5. Sablechase Plaza
6. Kuykendahl Plaza
7. 821 FM 1960 - Texas Car Title & Payday Loan
8. Clearwood Crossing
9. AW Plaza
10. Meadow III Retail
11. Kuykendahl & West Rayford Plaza
12. 26333 I-45 N
13. Little York Plaza
14. Copper Grove Corner
15. 6410-6578 FM 1960 Rd
16. Market at Northpointe
17. 4145 Gessner
18. Plazas at Midtown I
19. Plazas at Midtown II
20. Burlington - 10311 I-45 N
21. 210 Woerner Rd

At the 2026-08-28 completeness audit, these canonical records totaled 21 properties, 21 documents, 35 broker rows, 21 financial reports, 21 analysis rows, 21 committee reports, 21 acquisition decisions, 150 rent-roll rows, and 150 tenant rows. Source documents that do not contain a field are intentionally left null and identified in the due-diligence/missing-information fields rather than guessed.

## PDF attachment integrity

Every one of the 21 canonical `documents` rows has a non-null, typed attachment locator. Nine rows point to actual PDF objects in the private Supabase Storage bucket `offering-memorandums`. Twelve rows point to Google Drive with the `gdrive:<file-id>` convention; Midtown I and Midtown II intentionally share the same portfolio PDF, so the 21 relationships represent 20 distinct source PDFs.

The actual PDF binaries are kept in the document backends rather than committed to Git. GitHub stores the structured seeds, the attachment manifest, and validation logic. See `attachment_manifest.md` for the complete mapping and `document_locator.py` in the repository root for strict locator validation.

Point West Center currently uses the existing `Point_West_Center_key_pages.pdf` Drive attachment under the canonical database source name `texas-point-west-center.pdf`. It is identified as a key-pages derivative in the manifest and must not be represented as the complete original flyer unless the full original binary is supplied.

The upload scripts use stable IDs and `WHERE NOT EXISTS` checks so rerunning them does not create duplicate records. They contain no credentials and must be run only against the existing production schema described above.
