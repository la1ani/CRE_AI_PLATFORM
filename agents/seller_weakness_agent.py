"""
Seller Weakness Agent.

This module identifies potential seller motivations to accept a lower
offer by analysing property attributes. It returns a score from
0–100 and a list of identified weaknesses. The higher the score, the
more motivated the seller may be.
"""

from __future__ import annotations

import logging
from typing import Dict, List, Tuple

logger = logging.getLogger(__name__)


def _parse_percentage(value: str) -> float:
    try:
        return float(value.strip("%"))
    except Exception:
        return 0.0


def evaluate(property_data: Dict[str, str]) -> Tuple[int, List[str]]:
    """Compute seller weakness score and list of weaknesses.

    Args:
        property_data: Dictionary of property attributes extracted from the OM.

    Returns:
        (score, weaknesses): A tuple containing the seller weakness score
        (0–100) and a list of descriptive weaknesses.
    """
    weaknesses: List[str] = []
    score_components: List[int] = []

    # Vacancy risk: occupancy below 90% is considered a weakness
    occupancy_str = property_data.get("occupancy", "")
    occupancy = _parse_percentage(occupancy_str)
    if occupancy and occupancy < 90:
        weaknesses.append(f"Low occupancy ({occupancy_str})")
        score_components.append(20)

    # Lease rollover risk: if many leases expire in next year
    # This is a placeholder; add logic based on rent roll analysis
    lease_rollover = property_data.get("lease_rollover_risk")
    if lease_rollover:
        weaknesses.append("High lease rollover risk")
        score_components.append(20)

    # Debt pressure: maturity within a year
    debt_maturity = property_data.get("debt_maturity_year")
    if debt_maturity:
        try:
            debt_maturity_year = int(debt_maturity)
            current_year = 2026  # update according to timezone; here static for example
            if debt_maturity_year <= current_year:
                weaknesses.append("Debt maturity pressure")
                score_components.append(20)
        except ValueError:
            pass

    # Deferred maintenance or CapEx risk
    if property_data.get("deferred_maintenance"):
        weaknesses.append("Deferred maintenance or CapEx needs")
        score_components.append(20)

    # Occupancy decline (placeholder)
    if property_data.get("occupancy_decline"):
        weaknesses.append("Occupancy trending downward")
        score_components.append(20)

    # Cap the score at 100
    score = min(sum(score_components), 100)
    logger.info("Seller weakness evaluation: %s, score %s", weaknesses, score)
    return score, weaknesses


__all__ = ["evaluate"]