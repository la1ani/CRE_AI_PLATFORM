"""
deal_scoring.py
================

This module defines a simple scoring engine for commercial real estate deals.
The goal is to convert extracted property facts into numeric scores that reflect
deal quality, data completeness and potential negotiation leverage.

The following scores are produced:

  - due_diligence_score: Measures data completeness and reliability. Missing
    key financials (NOI, cap rate, rent roll, T12) and building information
    (roof age, HVAC age, ESA) reduce this score.
  - seller_leverage_score: Estimates how motivated the seller may be to
    negotiate based on occupancy, vacancy and missing information. Lower
    occupancy and more missing data increase this score.
  - opportunity_score: Approximates upside potential based on current
    occupancy (vacant space) and rent/price metrics. More vacancy implies
    potential lease‑up; missing price/cap rate reduces the score.
  - risk_score: Aggregates the inverse of due diligence and seller leverage to
    reflect deal uncertainty. High risk reduces overall deal attractiveness.
  - deal_score: Weighted blend of the above. Higher is better; lower indicates
    caution or rejection.

The scores produced here are intentionally simple and transparent. They can be
refined later with more sophisticated underwriting assumptions.
"""

from typing import Any, Dict


def _missing_penalty(property_data: Dict[str, Any], keys: list[str], weight: float) -> float:
    """Return penalty points for missing or falsy fields.

    Args:
        property_data: The extracted property data.
        keys: A list of keys to check for presence and truthiness.
        weight: The penalty per missing item.

    Returns:
        The total penalty points for missing keys.
    """
    penalty = 0.0
    for key in keys:
        value = property_data.get(key)
        if not value:
            penalty += weight
    return penalty


def compute_scores(property_data: Dict[str, Any]) -> Dict[str, float]:
    """Compute scoring metrics from property facts.

    The input dictionary is expected to include common fields such as
    `noi`, `cap_rate`, `occupancy`, `building_sf` and `price`. Missing or
    falsy values are treated as absent.

    Returns a dictionary with the following keys:
      - due_diligence_score
      - seller_leverage_score
      - opportunity_score
      - risk_score
      - deal_score
    """
    # Base scores start at 100 and are reduced by penalties
    dd_score = 100.0
    leverage_score = 0.0
    opportunity_score = 50.0

    # Penalty for missing financial data
    financial_keys = ["noi", "cap_rate", "asking_price"]
    dd_score -= _missing_penalty(property_data, financial_keys, weight=10.0)

    # Penalty for missing building details
    building_keys = ["building_sf", "land_sf", "year_built"]
    dd_score -= _missing_penalty(property_data, building_keys, weight=5.0)

    # If occupancy is available, adjust seller leverage and opportunity
    occupancy = property_data.get("occupancy")
    try:
        occ_val = float(str(occupancy).strip("% "))  # convert from string percentage
    except Exception:
        occ_val = None

    if occ_val is not None:
        # Lower occupancy implies higher seller leverage (more vacancy pressure)
        leverage_score += max(0.0, (100.0 - occ_val) * 0.5)
        # More vacancy can mean opportunity to lease up
        opportunity_score += max(0.0, (100.0 - occ_val) * 0.3)
    else:
        # Unknown occupancy reduces due diligence score
        dd_score -= 5.0

    # Ensure scores fall within 0..100 range
    dd_score = max(0.0, min(100.0, dd_score))
    leverage_score = max(0.0, min(100.0, leverage_score))
    opportunity_score = max(0.0, min(100.0, opportunity_score))

    # Risk is higher if due diligence is low or leverage is high
    risk_score = max(0.0, min(100.0, 100.0 - dd_score + leverage_score * 0.5))

    # Deal score is a weighted average of the key components
    deal_score = (
        dd_score * 0.4
        + (100.0 - risk_score) * 0.3
        + (100.0 - leverage_score) * 0.2
        + opportunity_score * 0.1
    )
    deal_score = max(0.0, min(100.0, deal_score))

    return {
        "due_diligence_score": round(dd_score, 2),
        "seller_leverage_score": round(leverage_score, 2),
        "opportunity_score": round(opportunity_score, 2),
        "risk_score": round(risk_score, 2),
        "deal_score": round(deal_score, 2),
    }
