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
  - tenants: tenant data extracted from rent rolls.

Ensure your Supabase service role key has permissions to insert into
these tables. To keep the service role key secret, it should be set
via an environment variable (see config/settings.py).
"""

from __future__ import annotations

import logging
from typing import Any, Dict, List, Optional

from supabase import create_client

from config import settings

logger = logging.getLogger(__name__)


class SupabaseClient:
    """Simple wrapper around the Supabase Python client."""

    def __init__(self) -> None:
        settings.validate()
        self._client = create_client(
            settings.SUPABASE_URL, settings.SUPABASE_SERVICE_ROLE_KEY
        )

    def insert_property(self, data: Dict[str, Any]) -> None:
        """Insert a single property record into the properties table.

        Args:
            data: A dictionary containing columns that match the
                `properties` table schema.
        """
        logger.info("Inserting property %s", data.get("property_name"))
        self._client.table("properties").insert(data).execute()

    def insert_broker(self, data: Dict[str, Any]) -> None:
        logger.info("Inserting broker %s", data.get("broker_email"))
        self._client.table("brokers").insert(data).execute()

    def insert_document(self, data: Dict[str, Any]) -> None:
        logger.info("Inserting document %s", data.get("file_name"))
        self._client.table("documents").insert(data).execute()

    def insert_tenants(self, data: List[Dict[str, Any]]) -> None:
        logger.info("Inserting %d tenant records", len(data))
        if data:
            self._client.table("tenants").insert(data).execute()

    def insert_analysis(self, data: Dict[str, Any]) -> None:
        logger.info("Inserting analysis for property_id %s", data.get("property_id"))
        self._client.table("analysis").insert(data).execute()


__all__ = ["SupabaseClient"]