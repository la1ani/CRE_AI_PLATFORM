-- CRE AI Platform document attachment manifest
-- 21 canonical properties / 20 distinct source PDFs.
-- Plazas at Midtown I and II share the same source PDF.
-- Locator convention:
--   offering-memorandums/<file>.pdf = Supabase Storage bucket object
--   gdrive:<file-id>                  = Google Drive file
--
-- This script is intentionally non-destructive. It only fills a missing
-- drive_file_id on an existing documents row and never overwrites a locator.

UPDATE documents SET drive_file_id='gdrive:1aJryfU7pKPiu5pwWkvk7syUfMMMvSJD_'
WHERE property_id=-2647658 AND drive_file_id IS NULL; -- Cypress Station Square
UPDATE documents SET drive_file_id='gdrive:1AFZS2I3a9fmitJKyfV3MSiL9FXLh0_cK'
WHERE property_id=-1916802 AND drive_file_id IS NULL; -- Point West Center
UPDATE documents SET drive_file_id='offering-memorandums/Griggs Rd Shopping Center.pdf'
WHERE property_id=-1920767 AND drive_file_id IS NULL;
UPDATE documents SET drive_file_id='offering-memorandums/South Loop Center.pdf'
WHERE property_id=-2330984 AND drive_file_id IS NULL;
UPDATE documents SET drive_file_id='offering-memorandums/Sablechase Plaza.pdf'
WHERE property_id=-2643096 AND drive_file_id IS NULL;
UPDATE documents SET drive_file_id='offering-memorandums/Kuykendahl Plaza.pdf'
WHERE property_id=-2625237 AND drive_file_id IS NULL;
UPDATE documents SET drive_file_id='offering-memorandums/821 Fm 1960 - Texas Car Title & Payday Loan.pdf'
WHERE property_id=-2315416 AND drive_file_id IS NULL;
UPDATE documents SET drive_file_id='offering-memorandums/Clearwood Crossing.pdf'
WHERE property_id=-283411823 AND drive_file_id IS NULL;
UPDATE documents SET drive_file_id='offering-memorandums/AW Plaza - Retail Center.pdf'
WHERE property_id=-1967068965 AND drive_file_id IS NULL;
UPDATE documents SET drive_file_id='offering-memorandums/Meadow III Retail.pdf'
WHERE property_id=-360294286 AND drive_file_id IS NULL;
UPDATE documents SET drive_file_id='offering-memorandums/Kuykendahl & West Rayford Plaza.pdf'
WHERE property_id=-2402677375 AND drive_file_id IS NULL;
UPDATE documents SET drive_file_id='gdrive:1xREG2PM7DBWDbRJNB1gxuTWa3sWgBiwo'
WHERE property_id=-1625618 AND drive_file_id IS NULL; -- 26333 I-45 N
UPDATE documents SET drive_file_id='gdrive:1SrW5X1gwaVTr-gtIWwvGURyUTOzqZlzH'
WHERE property_id=-2349164 AND drive_file_id IS NULL; -- Little York Plaza
UPDATE documents SET drive_file_id='gdrive:1boqPshwpavRAKWouaY1ylNSJPAo3Vr0b'
WHERE property_id=-2621733 AND drive_file_id IS NULL; -- Copper Grove Corner
UPDATE documents SET drive_file_id='gdrive:1d_XRhhOHegXv5ueE-RlRs7KZY882Itvr'
WHERE property_id=-2465894 AND drive_file_id IS NULL; -- 6410-6578 FM 1960 Rd
UPDATE documents SET drive_file_id='gdrive:1CSFP8yu8CQrgHvO1vkyJsAzyoZDJcrC0'
WHERE property_id=-1900377375 AND drive_file_id IS NULL; -- Market at Northpointe
UPDATE documents SET drive_file_id='gdrive:1QV4XnAYimW7CjBp6S9wmBSmDHDj54l92'
WHERE property_id=-3581955298 AND drive_file_id IS NULL; -- 4145 Gessner
UPDATE documents SET drive_file_id='gdrive:1nZtJ15ufToBTASmcLN4VbvOhD8zJ7zdI'
WHERE property_id=-1227442445 AND drive_file_id IS NULL; -- Plazas at Midtown I
UPDATE documents SET drive_file_id='gdrive:1nZtJ15ufToBTASmcLN4VbvOhD8zJ7zdI'
WHERE property_id=-254224862 AND drive_file_id IS NULL; -- Plazas at Midtown II
UPDATE documents SET drive_file_id='gdrive:1RjQcasteaWu4o9SleDWpUlJEw6kniYbb'
WHERE property_id=-3587931579 AND drive_file_id IS NULL; -- Burlington - 10311 I-45 N
UPDATE documents SET drive_file_id='gdrive:1l3wEN3w9t1g3n7lW9WlOt4UZ8F7yMjKX'
WHERE property_id=-4266969103 AND drive_file_id IS NULL; -- 210 Woerner Rd

-- Verification
SELECT
  count(*) AS canonical_document_rows,
  count(*) FILTER (WHERE drive_file_id IS NOT NULL AND btrim(drive_file_id) <> '') AS rows_with_attachment_locator,
  count(DISTINCT file_name) AS distinct_source_pdfs
FROM documents
WHERE property_id IN (
  -2647658,-1916802,-1920767,-2330984,-2643096,-2625237,-2315416,
  -283411823,-1967068965,-360294286,-2402677375,-1625618,-2349164,
  -2621733,-2465894,-1900377375,-3581955298,-1227442445,-254224862,
  -3587931579,-4266969103
);
