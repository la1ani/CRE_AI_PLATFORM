"""
main.py
=======

This script orchestrates the entire CRE acquisition pipeline. It reads
offering memorandum (OM) PDFs from the ``downloads`` directory, extracts
raw text, parses key property facts, runs the investment committee
analysis, and finally invokes the acquisition director to produce a BUY,
HOLD or REJECT decision. All intermediate and final outputs are saved
as JSON files in the ``outputs`` directory. If Supabase credentials are
configured via environment variables, the script will also persist
property facts, committee reports and director decisions to the
corresponding tables.

The script limits processing to five PDFs at a time to accommodate
resource constraints on modest hardware. Errors encountered while
processing individual documents are logged, but do not stop the batch.
"""

from __future__ import annotations

import json
from pathlib import Path
from typing import List

from supabase_loader import SupabaseLoader
from om_reader import extract_pdf_text
from quick_extract_agent import extract_key_facts
from financial_extractor import extract_financial_package
from investment_committee_agent import run_investment_committee
from acquisition_director import run_acquisition_director


def safe_json_loads(json_text: str, label: str) -> dict:
    try:
        return json.loads(json_text)
    except Exception as exc:
        print(f"Error parsing {label}: {exc}")
        return {}


def process_pdf(
    pdf_path: Path,
    loader: SupabaseLoader,
    outputs_dir: Path
) -> None:

    print(f"\nProcessing {pdf_path.name}...")

    property_id = pdf_path.stem

    # Step 1: Extract text from PDF
    text = extract_pdf_text(str(pdf_path))
    debug_file = outputs_dir / f"{pdf_path.stem}_RAW_TEXT.txt"

    with open(debug_file, "w", encoding="utf-8") as f:
        f.write(text)

    print(f"RAW TEXT saved: {debug_file.name}")

    if not text:
        print(f"No text extracted from {pdf_path.name}; skipping.")
        return

    # Step 2: Extract property facts
    facts_json = extract_key_facts(text)

    facts_file = outputs_dir / f"{pdf_path.stem}_facts.json"
    with facts_file.open("w", encoding="utf-8") as f:
        f.write(facts_json)

    property_data = safe_json_loads(
        facts_json,
        f"facts JSON for {pdf_path.name}"
    )

    property_data["property_id"] = property_id
    property_data["source_pdf"] = pdf_path.name

    # Remove fields not stored in properties table
    property_data.pop("major_risks", None)
    property_data.pop("missing_information", None)

    loader.save_property(property_data)

    # Step 3: Extract financial summary and rent roll
    financial_json = extract_financial_package(text)

    financial_file = outputs_dir / f"{pdf_path.stem}_financials.json"
    with financial_file.open("w", encoding="utf-8") as f:
        f.write(financial_json)

    financial_data = safe_json_loads(
        financial_json,
        f"financial JSON for {pdf_path.name}"
    )

    loader.save_financial_report(
        property_id,
        financial_data,
        pdf_path.name
    )
    # Handle rent roll if present
    rent_roll = financial_data.get("rent_roll", [])
    if not rent_roll:
        print(f"No rent roll found for {pdf_path.name}")
    else:
        print(f"Saving {len(rent_roll)} rent roll rows")
        loader.save_rent_roll(
            property_id,
            rent_roll,
            pdf_path.name
        )

        # Debug output for rent roll
        print("\n========== RENT ROLL DEBUG ==========")
        print(f"Property: {property_id}")
        print(f"Rent Roll Rows Found: {len(rent_roll)}")
        for row in rent_roll[:5]:
            print(row)
        print("=====================================\n")

    # Step 4: Run investment committee
    committee_json = run_investment_committee(facts_json)

    committee_file = outputs_dir / f"{pdf_path.stem}_committee.json"
    with committee_file.open("w", encoding="utf-8") as f:
        f.write(committee_json)

    committee_data = safe_json_loads(
        committee_json,
        f"committee JSON for {pdf_path.name}"
    )

    loader.save_committee_report(
        property_id,
        committee_data
    )

    # Step 5: Run acquisition director
    director_json = run_acquisition_director(
        facts_json,
        committee_json
    )

    director_file = outputs_dir / f"{pdf_path.stem}_director.json"
    with director_file.open("w", encoding="utf-8") as f:
        f.write(director_json)

    director_data = safe_json_loads(
        director_json,
        f"director JSON for {pdf_path.name}"
    )

    loader.save_acquisition_decision(
        property_id,
        director_data
    )

    print(
        f"Completed processing {pdf_path.name}. "
        f"Decision: {director_data.get('decision')}. "
        f"Confidence: {director_data.get('confidence_score')}%"
    )


def main() -> None:

    base_dir = Path(__file__).resolve().parent
    downloads_dir = base_dir / "downloads"
    outputs_dir = base_dir / "outputs"

    outputs_dir.mkdir(
        parents=True,
        exist_ok=True
    )

    loader = SupabaseLoader()

    pdf_paths: List[Path] = sorted(
        downloads_dir.glob("*.pdf")
    )[:5]

    if not pdf_paths:
        print("No PDF files found in downloads directory.")
        return

    print(f"Found {len(pdf_paths)} PDF(s) to process.")

    for pdf_path in pdf_paths:
        try:
            process_pdf(
                pdf_path,
                loader,
                outputs_dir
            )
        except Exception as exc:
            print(
                f"Unexpected error processing {pdf_path.name}: {exc}"
            )
            continue

    print("\nAll documents processed.")


if __name__ == "__main__":
    main()