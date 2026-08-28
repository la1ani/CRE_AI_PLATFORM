-- CRE AI Platform document attachment manifest
-- 21 canonical properties / 20 distinct source PDFs.
-- Plazas at Midtown I and II share the same source PDF.
-- Locator convention:
--   offering-memorandums/<file>.pdf = Supabase Storage bucket object
--   gdrive:<file-id>                  = Google Drive file
--
-- The standard rows only fill missing attachment locators. Point West Center is
-- an intentional canonical correction from the old key-pages derivative to the
-- complete 6-page PDF supplied on 2026-08-28.

UPDATE documents SET drive_file_id='gdrive:1aJryfU7pKPiu5pwWkvk7syUfMMMvSJD_'
WHERE property_id=-2647658 AND drive_file_id IS NULL; -- Cypress Station Square

UPDATE documents SET file_name='Point West Center.pdf', drive_file_id='gdrive:1yuehoBLowKFc4haaqQSGxTtaoHsp0Cjo'
WHERE property_id=-1916802; -- Point West Center: verified full 6-page PDF

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
WHERE property_id=-1625618 AND drive_file_id IS NULL;
UPDATE documents SET drive_file_id='gdrive:1SrW5X1gwaVTr-gtIWwvGURyUTOzqZlzH'
WHERE property_id=-2349164 AND drive_file_id IS NULL;
UPDATE documents SET drive_file_id='gdrive:1boqPshwpavRAKWouaY1ylNSJPAo3Vr0b'
WHERE property_id=-2621733 AND drive_file_id IS NULL;
UPDATE documents SET drive_file_id='gdrive:1d_XRhhOHegXv5ueE-RlRs7KZY882Itvr'
WHERE property_id=-2465894 AND drive_file_id IS NULL;
UPDATE documents SET drive_file_id='gdrive:1CSFP8yu8CQrgHvO1vkyJsAzyoZDJcrC0'
WHERE property_id=-1900377375 AND drive_file_id IS NULL;
UPDATE documents SET drive_file_id='gdrive:1QV4XnAYimW7CjBp6S9wmBSmDHDj54l92'
WHERE property_id=-3581955298 AND drive_file_id IS NULL;
UPDATE documents SET drive_file_id='gdrive:1nZtJ15ufToBTASmcLN4VbvOhD8zJ7zdI'
WHERE property_id=-1227442445 AND drive_file_id IS NULL;
UPDATE documents SET drive_file_id='gdrive:1nZtJ15ufToBTASmcLN4VbvOhD8zJ7zdI'
WHERE property_id=-254224862 AND drive_file_id IS NULL;
UPDATE documents SET drive_file_id='gdrive:1RjQcasteaWu4o9SleDWpUlJEw6kniYbb'
WHERE property_id=-3587931579 AND drive_file_id IS NULL;
UPDATE documents SET drive_file_id='gdrive:1l3wEN3w9t1g3n7lW9WlOt4UZ8F7yMjKX'
WHERE property_id=-4266969103 AND drive_file_id IS NULL;
