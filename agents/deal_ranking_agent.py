"""
Deal Ranking Agent.

This agent aggregates various scores into a single overall investment
score. You can tweak the weights applied to each component to reflect
your investment philosophy. Higher scores indicate more attractive
deals.
"""

from __future__ import annotations

from typing import Dict


def rank(
    acquisition_score: float,
    risk_score: float,
    seller_weakness_score: float,
    upside_score: float,
    weights: Dict[str, float] | None = None,
) -> Dict[str, float]:
    """Compute a weighted overall score for a deal.

    Args:
        acquisition_score: Score representing how well the deal
            matches acquisition criteria (0–100).
        risk_score: Due diligence score (0–100); lower is worse.
        seller_weakness_score: Seller motivation score (0–100);
            higher indicates more seller pressure.
        upside_score: Potential upside score (0–100).
        weights: Optional dictionary of weights for each component.
            Default weights are used if not provided.

    Returns:
        Dictionary with each component and the final overall_score.
    """
    default_weights = {
        "acquisition": 0.4,
        "risk": 0.3,
        "seller_weakness": 0.2,
        "upside": 0.1,
    }
    if weights:
        default_weights.update(weights)

    # Normalize inputs to 0–100
    acquisition_score = max(0.0, min(100.0, float(acquisition_score)))
    risk_score = max(0.0, min(100.0, float(risk_score)))
    seller_weakness_score = max(0.0, min(100.0, float(seller_weakness_score)))
    upside_score = max(0.0, min(100.0, float(upside_score)))

    # For risk and seller weakness, lower numbers are better for risk,
    # but higher numbers indicate more seller pressure. We invert risk to
    # reward deals with fewer missing items.
    risk_component = 100.0 - risk_score
    seller_component = seller_weakness_score

    overall_score = (
        default_weights["acquisition"] * acquisition_score
        + default_weights["risk"] * risk_component
        + default_weights["seller_weakness"] * seller_component
        + default_weights["upside"] * upside_score
    )
    return {
        "acquisition_score": acquisition_score,
        "risk_component": risk_component,
        "seller_weakness_component": seller_component,
        "upside_score": upside_score,
        "overall_score": overall_score,
    }


__all__ = ["rank"]