# Supabase seed files

These SQL files contain idempotent property inserts for the CRE AI Platform.
They target the existing production Supabase schema, whose property references
use text IDs in some tables and stable bigint IDs in others.

- `mallard_cove_existing_supabase_schema.sql`: Mallard Cove Professional Building.
- `upload_cypress_point_west_existing_schema.sql`: Cypress Station Square and Point West Center.
- `upload_next5_oms_existing_schema.sql`: 821 FM 1960, Griggs Rd Shopping Center, Kuykendahl Plaza, Sablechase Plaza, and South Loop Center.
- `upload_kuykendahl_west_rayford_existing_schema.sql`: Kuykendahl & West Rayford Plaza.
- `upload_aw_clearwood_meadow_existing_schema.sql`: AW Plaza, Clearwood Crossing, and Meadow III Retail.

The upload scripts use stable IDs and `WHERE NOT EXISTS` checks so rerunning
them does not create duplicate records. They contain no credentials and must be
run only against the existing production schema described above.
