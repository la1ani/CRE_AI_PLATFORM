"""
Due Diligence Agent.

This module evaluates the completeness of a property package by
identifying missing documents or critical pieces of information. It
returns a score from 0–100 reflecting how complete the due diligence
package is and lists any missing items for further action.
"""

from __future__ import annotations

import logging
from typing import Dict, List, Tuple

logger = logging.getLogger(__name__)

# List of keys expected in the property data to consider the due diligence
# package complete. These keys should be provided by the OM extraction
# agent or manually added when performing due diligence.
REQUIRED_ITEMS = [
    "roof_age",
    "hvac_age",
    "environmental_reports",
    "utility_bills",
    "service_contracts",
    "estoppels",
    "financial_statements",
]


def evaluate(property_data: Dict[str, str]) -> Tuple[int, List[str]]:
    """Evaluate due diligence completeness for a property.

    Args:
        property_data: Dictionary of property attributes extracted from the OM.

    Returns:
        Tuple of (score, missing_items). Score is an integer from 0–100.
    """
    missing: List[str] = []
    for item in REQUIRED_ITEMS:
        value = property_data.get(item)
        if not value:
            missing.append(item)
    # Simple scoring: subtract equal weight for each missing item
    total_items = len(REQUIRED_ITEMS)
    missing_count = len(missing)
    score = max(0, int(100 * (total_items - missing_count) / total_items))
    logger.info(
        "Due diligence evaluation complete: %s%% complete, missing %s",
        score,
        missing,
    )
    return score, missing


__all__ = ["evaluate"]