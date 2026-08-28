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

## Canonical 16-property audit set

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

At the 2026-08-28 completeness audit, these canonical records totaled 16 properties, 16 documents, 16 financial reports, 16 analysis rows, 16 committee reports, 16 acquisition decisions, 127 rent-roll rows, and 127 tenant rows. Source documents that do not contain a field are intentionally left null and identified in the due-diligence/missing-information fields rather than guessed.

The upload scripts use stable IDs and `WHERE NOT EXISTS` checks so rerunning
them does not create duplicate records. They contain no credentials and must be
run only against the existing production schema described above.
