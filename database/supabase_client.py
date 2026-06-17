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

    PROPERTY_COLUMNS = {
        "property_name",
        "address",
        "property_type",
        "asking_price",
        "noi",
        "cap_rate",
        "occupancy",
        "building_sf",
        "land_sf",
        "year_built",
        "broker_name",
        "broker_email",
        "broker_phone",
        "unit_count",
        "estimated_arv",
        "opportunity_zone",
        "value_add",
        "extraction_confidence",
        "missing_information",
        "major_risks",
    }

    def __init__(self) -> None:
        settings.validate_supabase()
        self._client = create_client(
            settings.SUPABASE_URL,
            settings.SUPABASE_SERVICE_ROLE_KEY
        )

    def insert_property(self, data: Dict[str, Any]) -> Optional[Dict[str, Any]]:

        if "price" in data and "asking_price" not in data:
            data["asking_price"] = data.pop("price")

        payload = {
            k: v for k, v in data.items()
            if v not in (None, "") and k in self.PROPERTY_COLUMNS
        }

        if isinstance(payload.get("missing_information"), list):
            payload["missing_information"] = ", ".join(
                str(item) for item in payload["missing_information"]
            )

        logger.info(
            "Inserting property %s",
            payload.get("property_name")
        )

        result = self._client.table(
            "properties"
        ).insert(payload).execute()

        if getattr(result, "error", None):
            logger.error("Supabase insert_property error: %s", result.error)

        if getattr(result, "data", None):
            if isinstance(result.data, list) and result.data:
                return result.data[0]
            if isinstance(result.data, dict):
                return result.data
        return None

    def _collect_result_data(self, result: Any) -> Optional[Dict[str, Any]]:
        if getattr(result, "error", None):
            logger.error("Supabase error: %s", result.error)
        if getattr(result, "data", None):
            if isinstance(result.data, list) and result.data:
                return result.data[0]
            if isinstance(result.data, dict):
                return result.data
        return None

    def insert_broker(self, data: Dict[str, Any]) -> Optional[Dict[str, Any]]:

        payload = {k: v for k, v in data.items() if v not in (None, "")}
        logger.info(
            "Inserting broker %s",
            payload.get("broker_email")
        )

        result = self._client.table(
            "brokers"
        ).insert(payload).execute()

        return self._collect_result_data(result)

    def insert_document(self, data: Dict[str, Any]) -> Optional[Dict[str, Any]]:

        payload = {k: v for k, v in data.items() if v not in (None, "")}
        logger.info(
            "Inserting document %s",
            payload.get("file_name")
        )

        result = self._client.table(
            "documents"
        ).insert(payload).execute()

        return self._collect_result_data(result)

    def insert_tenants(
        self,
        data: List[Dict[str, Any]]
    ) -> Optional[Dict[str, Any]]:

        logger.info(
            "Inserting %d tenant records",
            len(data)
        )

        if not data:
            return None

        result = self._client.table(
            "tenants"
        ).insert(data).execute()

        if getattr(result, "error", None):
            logger.error("Supabase insert_tenants error: %s", result.error)
            return None

        return result.data

    def insert_analysis(
        self,
        data: Dict[str, Any]
    ) -> Optional[Dict[str, Any]]:

        payload = {k: v for k, v in data.items() if v not in (None, "")}
        logger.info(
            "Inserting analysis for property_id %s",
            payload.get("property_id")
        )

        result = self._client.table(
            "analysis"
        ).insert(payload).execute()

        return self._collect_result_data(result)

    def fetch_properties(
        self,
        property_type: str | None = None,
        limit: int = 500,
    ) -> list[Dict[str, Any]]:
        query = self._client.table("properties").select("*")
        if property_type:
            query = query.eq("property_type", property_type)
        if limit:
            query = query.limit(limit)

        result = query.execute()
        if getattr(result, "error", None):
            logger.error("Supabase fetch_properties error: %s", result.error)
            return []

        return result.data if isinstance(result.data, list) else []

    def fetch_analysis(self, property_id: Any) -> dict[str, Any]:
        result = (
            self._client.table("analysis")
            .select("*")
            .eq("property_id", property_id)
            .order("id", desc=True)
            .limit(1)
            .execute()
        )
        if getattr(result, "error", None):
            logger.error("Supabase fetch_analysis error: %s", result.error)
            return {}

        if getattr(result, "data", None) and isinstance(result.data, list) and result.data:
            return result.data[0]
        return {}


__all__ = ["SupabaseClient"]