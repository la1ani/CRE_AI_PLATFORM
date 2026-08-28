"""
Supabase client wrapper for CRE_AI_PLATFORM.

This module encapsulates basic interactions with Supabase. It uses the
supabase-py library under the hood. Only the operations required for
inserting extracted data are implemented here, but you can extend it
to support queries or other operations as your platform evolves.

Tables expected to exist in your Supabase project:

  - properties: stores core property information extracted from OMs.
  - documents: tracks uploaded documents and their metadata.
  - brokers: broker contact details parsed from OMs.
  - analysis: aggregated scores from due diligence, seller weakness and
    deal ranking agents.
  - tenants and rent_rolls: tenant and lease data extracted from rent rolls.
  - financial_reports: income, expense, NOI, and valuation inputs.
  - due_diligence_items, seller_weakness_items, valuation_scenarios, and
    broker_questions: structured acquisition-review details.
  - committee_reports and acquisition_decisions: final review outputs.

Ensure your Supabase service role key has permissions to insert into
these tables. To keep the service role key secret, it should be set
via an environment variable (see config/settings.py).
"""

from __future__ import annotations

import logging
from typing import Any, Dict, List

from supabase import create_client
from config import settings
from document_locator import parse_document_locator

logger = logging.getLogger(__name__)


class SupabaseClient:
    """Simple wrapper around the Supabase Python client."""

    def __init__(self) -> None:
        settings.validate()
        self._client = create_client(
            settings.SUPABASE_URL,
            settings.SUPABASE_SERVICE_ROLE_KEY
        )

    def insert_property(self, data: Dict[str, Any]) -> None:

        if "price" in data:
            data["asking_price"] = data.pop("price")

        logger.info(
            "Inserting property %s",
            data.get("property_name")
        )

        self._client.table(
            "properties"
        ).insert(data).execute()

    def insert_broker(self, data: Dict[str, Any]) -> None:

        logger.info(
            "Inserting broker %s",
            data.get("broker_email")
        )

        self._client.table(
            "brokers"
        ).insert(data).execute()

    def insert_document(self, data: Dict[str, Any]) -> None:
        """Insert a document only when it has a valid, resolvable locator.

        This prevents a metadata-only row from being recorded as a successfully
        attached OM. Supported locator formats are validated by
        :func:`document_locator.parse_document_locator`.
        """
        locator = data.get("drive_file_id")
        parse_document_locator(locator)

        logger.info(
            "Inserting document %s",
            data.get("file_name")
        )

        self._client.table(
            "documents"
        ).insert(data).execute()

    def insert_tenants(
        self,
        data: List[Dict[str, Any]]
    ) -> None:

        logger.info(
            "Inserting %d tenant records",
            len(data)
        )

        if data:
            self._client.table(
                "tenants"
            ).insert(data).execute()

    def insert_analysis(
        self,
        data: Dict[str, Any]
    ) -> None:

        logger.info(
            "Inserting analysis for property_id %s",
            data.get("property_id")
        )

        self._client.table(
            "analysis"
        ).insert(data).execute()

    def _insert_one(self, table: str, data: Dict[str, Any]) -> None:
        logger.info("Inserting record into %s", table)
        self._client.table(table).insert(data).execute()

    def _insert_many(self, table: str, data: List[Dict[str, Any]]) -> None:
        logger.info("Inserting %d records into %s", len(data), table)
        if data:
            self._client.table(table).insert(data).execute()

    def insert_financial_report(self, data: Dict[str, Any]) -> None:
        self._insert_one("financial_reports", data)

    def insert_rent_rolls(self, data: List[Dict[str, Any]]) -> None:
        self._insert_many("rent_rolls", data)

    def insert_due_diligence_items(self, data: List[Dict[str, Any]]) -> None:
        self._insert_many("due_diligence_items", data)

    def insert_seller_weakness_items(self, data: List[Dict[str, Any]]) -> None:
        self._insert_many("seller_weakness_items", data)

    def insert_valuation_scenarios(self, data: List[Dict[str, Any]]) -> None:
        self._insert_many("valuation_scenarios", data)

    def insert_broker_questions(self, data: List[Dict[str, Any]]) -> None:
        self._insert_many("broker_questions", data)

    def insert_committee_report(self, data: Dict[str, Any]) -> None:
        self._insert_one("committee_reports", data)

    def insert_acquisition_decision(self, data: Dict[str, Any]) -> None:
        self._insert_one("acquisition_decisions", data)


__all__ = ["SupabaseClient"]
