# Batch 2 — Property Extractions (76 new unique properties)

This folder documents the second batch of commercial real-estate offering memoranda (OM) / listing flyers
processed for the CRE AI Platform.

## Source

- Source folder: `C:\Users\hp\Downloads\wetransfer_om_2026-08-31_2319\Om shopping center(rest78)`
- The folder held 79 files: 77 `.pdf` files plus 2 extension-less files (`17960 FM 529 RD HOUSTON TX 77095-1000`
  and `Bella Katy Drive OM`) that are identical PDF duplicates of two of the `.pdf` files. Only the 77 distinct
  `.pdf` documents were processed.
- Original files in `Downloads` were only read — none were moved, modified, or deleted. Copies live in
  `documents/batch2/`.

## Dedupe against batch 1

Batch 1 already extracted 21 canonical properties (see `database/seeds/attachment_manifest.md` and the seed
SQL under `database/seeds/`). Deduplication was done by **real property address/name**, not filename, against
those 21 addresses. One source PDF matched an already-extracted property and was skipped:

- `920 E Little York.pdf` → **Little York Plaza** (920 E Little York Rd, Houston, TX 77076), already extracted in batch 1.

Result: **76 new unique properties** were extracted.

## Outputs

- **Consolidated machine-readable JSON**: `data/batch2_extracted_properties.json`
  - A JSON array with one object per new property. Every object uses the same keys for all 12 fields plus the
    source PDF filename (`source_pdf`):
    `property_name, address, asking_price, cap_rate, noi, occupancy, building_size, land_size, year_built,
    tenant_mix, broker, offering_terms, source_pdf` (plus a `notes` field for caveats/uncertainty).
- **Per-property summary files**: `data/batch2_summaries/<slug>.json` (one per property).
- **Source PDF copies**: `documents/batch2/<original filename>.pdf` (originals remain in Downloads).

## Field notes

Values are taken only from the source document; missing values are set to `"Not provided"` (never invented).
Many listings are undeveloped land / pad / build-to-suit sites or single-page sales flyers that legitimately do
not disclose NOI, cap rate, or occupancy, so those fields are `"Not provided"` for those records.

## Known naming/corrections flagged during extraction

- `NWC Fm-1464 & Beechnut Rd.pdf` is actually the **4402 Airline Drive** flyer (NEC Airline Dr & Crosstimbers St,
  Houston, TX 77022); the `NWC FM-1464 & Beechnut Rd, Richmond TX 77407` line on the flyer appears to be a
  location-field error. The record uses the corrected 4402 Airline Drive address.
- `6713 FM 521 Rd FOR SALE.pdf` (property shown as "Grand Plaza Arcola") has an address discrepancy between
  Houston 77030 and Rosharon 77583; noted in the record.
- `SBA Eligible Pet Grooming Salon In Kroger Shopping Center.pdf` is a **business** sale (not a stabilized real
  estate asset); the displayed Crexi address is a broker-office proxy and flagged as confidential.
