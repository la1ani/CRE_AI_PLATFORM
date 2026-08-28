"""Document attachment locator helpers for the CRE AI Platform.

`documents.drive_file_id` is retained for backwards compatibility but is treated
as a typed locator rather than assuming every value is a Google Drive ID.

Supported forms:
    gdrive:<google-drive-file-id>
    offering-memorandums/<supabase-storage-object-name>

Unknown, blank, or malformed locator values raise ValueError so missing PDFs do
not silently appear as successfully attached documents.
"""

from __future__ import annotations

from dataclasses import dataclass
from enum import Enum
import re
from urllib.parse import quote


class DocumentBackend(str, Enum):
    GOOGLE_DRIVE = "google_drive"
    SUPABASE_STORAGE = "supabase_storage"


@dataclass(frozen=True)
class DocumentLocator:
    backend: DocumentBackend
    value: str


_GOOGLE_DRIVE_PREFIX = "gdrive:"
_STORAGE_PREFIX = "offering-memorandums/"
_GOOGLE_DRIVE_ID_RE = re.compile(r"^[A-Za-z0-9_-]{10,}$")


def parse_document_locator(raw: str | None) -> DocumentLocator:
    """Parse and validate a persisted document locator.

    Raises:
        ValueError: if the locator is missing, malformed, or from an unsupported
        backend.
    """
    if raw is None or not str(raw).strip():
        raise ValueError("Document locator is missing")

    locator = str(raw).strip()

    if locator.startswith(_GOOGLE_DRIVE_PREFIX):
        file_id = locator[len(_GOOGLE_DRIVE_PREFIX) :].strip()
        if not _GOOGLE_DRIVE_ID_RE.fullmatch(file_id):
            raise ValueError("Malformed Google Drive document locator")
        return DocumentLocator(DocumentBackend.GOOGLE_DRIVE, file_id)

    if locator.startswith(_STORAGE_PREFIX):
        object_name = locator[len(_STORAGE_PREFIX) :].strip()
        if not object_name or object_name.startswith("/") or ".." in object_name.split("/"):
            raise ValueError("Malformed Supabase Storage document locator")
        return DocumentLocator(DocumentBackend.SUPABASE_STORAGE, object_name)

    raise ValueError(f"Unsupported document locator: {locator!r}")


def google_drive_view_url(locator: str | DocumentLocator) -> str:
    """Return a Drive view URL, rejecting non-Drive locators."""
    parsed = parse_document_locator(locator) if isinstance(locator, str) else locator
    if parsed.backend is not DocumentBackend.GOOGLE_DRIVE:
        raise ValueError("Document is not stored in Google Drive")
    return f"https://drive.google.com/file/d/{quote(parsed.value, safe='')}/view"


def supabase_storage_object_name(locator: str | DocumentLocator) -> str:
    """Return the object name inside the `offering-memorandums` bucket."""
    parsed = parse_document_locator(locator) if isinstance(locator, str) else locator
    if parsed.backend is not DocumentBackend.SUPABASE_STORAGE:
        raise ValueError("Document is not stored in Supabase Storage")
    return parsed.value


def is_supported_document_locator(raw: str | None) -> bool:
    """Return True only for a locator the application can safely resolve."""
    try:
        parse_document_locator(raw)
    except ValueError:
        return False
    return True


__all__ = [
    "DocumentBackend",
    "DocumentLocator",
    "parse_document_locator",
    "google_drive_view_url",
    "supabase_storage_object_name",
    "is_supported_document_locator",
]
