-- CRE AI Platform: canonical OM attachment integrity audit
-- Read-only. Makes no data changes.
--
-- Expected production result for the canonical 21-property set (2026-08-28):
--   canonical_document_rows = 21
--   linked_rows             = 21
--   supabase_storage_rows   = 9
--   google_drive_rows       = 12
--   invalid_rows            = 0
--
-- Note: Google Drive object existence is verified externally by the Drive API.
-- This query validates the locator shape and verifies Supabase Storage objects
-- directly against storage.objects.

WITH canonical_document_ids(id) AS (
    VALUES
        (2),(3),(4),(5),(6),(7),(8),(9),(10),(11),(12),
        (13),(14),(15),(16),(17),(18),(19),(20),(21),(22)
), canonical_docs AS (
    SELECT d.*
    FROM documents d
    JOIN canonical_document_ids c ON c.id = d.id
), checked AS (
    SELECT
        d.id,
        d.file_name,
        d.drive_file_id,
        CASE
            WHEN d.drive_file_id LIKE 'offering-memorandums/%' THEN EXISTS (
                SELECT 1
                FROM storage.objects o
                WHERE o.bucket_id = 'offering-memorandums'
                  AND o.name = substr(
                      d.drive_file_id,
                      length('offering-memorandums/') + 1
                  )
            )
            WHEN d.drive_file_id ~ '^gdrive:[A-Za-z0-9_-]{10,}$' THEN true
            ELSE false
        END AS locator_or_storage_ok
    FROM canonical_docs d
)
SELECT
    count(*) AS canonical_document_rows,
    count(*) FILTER (WHERE drive_file_id IS NOT NULL) AS linked_rows,
    count(*) FILTER (
        WHERE drive_file_id LIKE 'offering-memorandums/%'
    ) AS supabase_storage_rows,
    count(*) FILTER (
        WHERE drive_file_id LIKE 'gdrive:%'
    ) AS google_drive_rows,
    count(*) FILTER (WHERE locator_or_storage_ok) AS locator_or_storage_verified,
    count(*) FILTER (WHERE NOT locator_or_storage_ok) AS invalid_rows
FROM checked;
