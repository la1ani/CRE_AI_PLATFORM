"""
om_reader.py
=============

This module provides a lightweight wrapper around PyMuPDF (fitz) to extract
plain text from PDF files. The function defined here reads every page of a
PDF and concatenates their text content into a single string. It is used by
the property intelligence agent to obtain raw offering memorandum (OM) text
without relying on external services or heavyweight PDF parsers.  The code
gracefully handles missing or inaccessible files and logs errors instead of
raising them, ensuring that a single bad document does not halt the entire
processing pipeline.

The module intentionally avoids any dependencies beyond PyMuPDF and the
standard library so that it can run on modest hardware. If PyMuPDF is not
available, the extraction will fail with a clear error message.
"""

from __future__ import annotations

try:
    import pdfplumber
except ImportError:  # pragma: no cover
    pdfplumber = None

import sys
from pathlib import Path
from typing import Optional

def extract_tables(pdf_path):

    if pdfplumber is None:
        return []

    rows = []

    with pdfplumber.open(pdf_path) as pdf:

        for page in pdf.pages:

            tables = page.extract_tables()

            for table in tables:

                if not table:
                    continue

                rows.extend(table)

    return rows

def extract_pdf_text(pdf_path: str) -> str:
    """Extract all text from a PDF file.

    Args:
        pdf_path: Path to the PDF file to extract text from.

    Returns:
        A string containing the concatenated text of all pages. If the file
        cannot be read, returns an empty string.

    This function uses PyMuPDF (fitz) under the hood. If `fitz` cannot be
    imported, an error message is printed to stderr and an empty string is
    returned. Any exceptions during PDF reading are caught and logged.
    """
    try:
        import fitz  # type: ignore
    except Exception as exc:  # pragma: no cover - library import errors
        print(f"om_reader: PyMuPDF (fitz) is not installed: {exc}", file=sys.stderr)
        return ""

    path = Path(pdf_path)
    if not path.is_file():
        print(f"om_reader: PDF file not found: {pdf_path}", file=sys.stderr)
        return ""
    try:
        doc = fitz.open(pdf_path)
    except Exception as exc:
        print(f"om_reader: Failed to open PDF {pdf_path}: {exc}", file=sys.stderr)
        return ""
    text_parts: list[str] = []
    for page_number in range(len(doc)):
        try:
            page = doc.load_page(page_number)
            text_parts.append(page.get_text())
        except Exception as exc:
            # Log error but continue reading remaining pages
            print(
                f"om_reader: Failed to read page {page_number} of {pdf_path}: {exc}",
                file=sys.stderr,
            )
            continue
    doc.close()
    return "\n".join(text_parts)