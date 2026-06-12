
import importlib
import os
from pathlib import Path
from dotenv import load_dotenv

try:
    _supabase = importlib.import_module("supabase")
    create_client = _supabase.create_client
except Exception:  # pragma: no cover - graceful fallback for environments without supabase package
    def create_client(url, key):
        raise ImportError(
            "supabase package is not installed. Install with `pip install supabase` to use SupabaseLoader.`"
        )

BASE_DIR = Path(__file__).resolve().parent
load_dotenv(BASE_DIR / ".env")


class SupabaseLoader:

    def __init__(self):
        self.url = os.getenv("SUPABASE_URL")
        self.key = os.getenv("SUPABASE_SERVICE_ROLE_KEY") or os.getenv("SUPABASE_KEY")

        print("URL:", self.url)
        print("KEY FOUND:", bool(self.key))

        self.client = create_client(
            self.url,
            self.key
        )

    def save_property(self, property_data):
        try:
            self.client.table(
                "properties"
            ).insert(
                property_data
            ).execute()

            print("Property saved")

        except Exception as e:
            print("Property save error:", e)

    def save_committee_report(
        self,
        property_id,
        committee_data
    ):
        try:

            self.client.table(
                "committee_reports"
            ).insert(
                {
                    "property_id": property_id,
                    "report": committee_data
                }
            ).execute()

            print("Committee saved")

        except Exception as e:
            print("Committee save error:", e)

    def save_acquisition_decision(
        self,
        property_id,
        decision_data
    ):
        try:

            self.client.table(
                "acquisition_decisions"
            ).insert(
                {
                    "property_id": property_id,
                    "decision": decision_data
                }
            ).execute()

            print("Decision saved")

        except Exception as e:
            print("Decision save error:", e)

    def save_financial_report(self, property_id, financial_data, source_pdf=None):
        try:
            summary = financial_data.get("financial_summary", {})

            record = {
                "property_id": property_id,
                "rental_income": summary.get("rental_income"),
                "recoveries": summary.get("recoveries"),
                "other_income": summary.get("other_income"),
                "gross_income": summary.get("gross_income"),
                "taxes": summary.get("taxes"),
                "insurance": summary.get("insurance"),
                "cam": summary.get("cam"),
                "utilities": summary.get("utilities"),
                "management_fee": summary.get("management_fee"),
                "total_expenses": summary.get("total_expenses"),
                "noi": summary.get("noi"),
                "cap_rate": summary.get("cap_rate"),
                "occupancy": summary.get("occupancy"),
                "confidence": summary.get("confidence"),
                "source_pdf": source_pdf,
                "raw_json": financial_data,
            }

            self.client.table("financial_reports").insert(record).execute()
            print("Financial report saved")

        except Exception as e:
            print("Financial save error:", e)


    def save_rent_roll(self, property_id, rent_roll, source_pdf=None):
        try:
            for tenant in rent_roll:
                record = {
                    "property_id": property_id,
                    "tenant_name": tenant.get("tenant_name"),
                    "suite": tenant.get("suite"),
                    "sf": tenant.get("sf"),
                    "lease_start": tenant.get("lease_start"),
                    "lease_end": tenant.get("lease_end"),
                    "monthly_rent": tenant.get("monthly_rent"),
                    "annual_rent": tenant.get("annual_rent"),
                    "rent_psf": tenant.get("rent_psf"),
                    "lease_type": tenant.get("lease_type"),
                    "renewal_options": tenant.get("renewal_options"),
                    "source_pdf": source_pdf,
                }

                self.client.table("rent_rolls").insert(record).execute()

            print("Rent roll saved")

        except Exception as e:
            print("Rent roll save error:", e)

