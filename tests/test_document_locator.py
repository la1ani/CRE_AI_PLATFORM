import unittest

from document_locator import (
    DocumentBackend,
    google_drive_view_url,
    is_supported_document_locator,
    parse_document_locator,
    supabase_storage_object_name,
)


class DocumentLocatorTests(unittest.TestCase):
    def test_google_drive_locator(self):
        raw = "gdrive:1QV4XnAYimW7CjBp6S9wmBSmDHDj54l92"
        parsed = parse_document_locator(raw)
        self.assertEqual(parsed.backend, DocumentBackend.GOOGLE_DRIVE)
        self.assertEqual(parsed.value, "1QV4XnAYimW7CjBp6S9wmBSmDHDj54l92")
        self.assertIn(parsed.value, google_drive_view_url(raw))

    def test_supabase_storage_locator(self):
        raw = "offering-memorandums/Griggs Rd Shopping Center.pdf"
        parsed = parse_document_locator(raw)
        self.assertEqual(parsed.backend, DocumentBackend.SUPABASE_STORAGE)
        self.assertEqual(
            supabase_storage_object_name(raw),
            "Griggs Rd Shopping Center.pdf",
        )

    def test_missing_locator_is_rejected(self):
        for raw in (None, "", "   "):
            with self.assertRaises(ValueError):
                parse_document_locator(raw)
            self.assertFalse(is_supported_document_locator(raw))

    def test_unknown_backend_is_rejected(self):
        raw = "somewhere:document.pdf"
        with self.assertRaises(ValueError):
            parse_document_locator(raw)
        self.assertFalse(is_supported_document_locator(raw))

    def test_malformed_drive_id_is_rejected(self):
        with self.assertRaises(ValueError):
            parse_document_locator("gdrive:bad")

    def test_storage_parent_traversal_is_rejected(self):
        with self.assertRaises(ValueError):
            parse_document_locator("offering-memorandums/../secret")


if __name__ == "__main__":
    unittest.main()
