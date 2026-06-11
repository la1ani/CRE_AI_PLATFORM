"""
offer_generator.py
===================

This module provides a simple, heuristic approach to generating offer guidance
for commercial real estate acquisitions. It takes into account the extracted
property facts and computed deal scores to estimate a recommended offer,
negotiation range, and walk‑away price.

The calculation is intentionally simplistic and should be refined for real
world use. The heuristics used here are:
  - If asking price is known, use it as the baseline; otherwise derive a
    pseudo price from NOI and cap rate if both are available.
  - Higher risk and higher seller leverage warrant a larger discount from the
    asking price.
  - Opportunity score can slightly increase the acceptable price due to
    potential upside.
  - A walk‑away price is set above the recommended offer to give room for
    negotiation.

All monetary values returned are floats. They should be formatted by callers
for display or further processing.
"""

from typing import Dict, Any, Tuple, Optional


def _parse_price(value: Any) -> Optional[float]:
    """Attempt to parse a price string like "$3,500,000" or "3500000".

    Returns a float or None if parsing fails.
    """
    if value is None:
        return None
    try:
        if isinstance(value, (int, float)):
            return float(value)
        # Remove currency symbols and commas
        stripped = (
            str(value)
            .replace("$", "")
            .replace(",", "")
            .strip()
        )
        return float(stripped)
    except Exception:
        return None


def generate_offer(property_data: Dict[str, Any], scores: Dict[str, float]) -> Dict[str, Any]:
    """Generate offer guidance based on property data and deal scores.

    Args:
        property_data: The extracted property facts (should include asking_price,
            noi and cap_rate where available).
        scores: A dictionary of deal scores from `deal_scoring.compute_scores`.

    Returns:
        A dictionary with keys: `recommended_offer`, `settlement_range`,
        `walk_away_price`, `discount_rate`.
    """
    asking_price = _parse_price(property_data.get("asking_price"))
    noi = _parse_price(property_data.get("noi"))
    cap_rate = property_data.get("cap_rate")
    try:
        cap_rate_val = float(str(cap_rate).strip("% ")) / 100.0 if cap_rate else None
    except Exception:
        cap_rate_val = None

    # Derive a pseudo price from NOI and cap rate if asking price is missing
    derived_price: Optional[float] = None
    if asking_price is None and noi is not None and cap_rate_val:
        # Value estimate = NOI / Cap Rate
        try:
            derived_price = noi / cap_rate_val
        except Exception:
            derived_price = None

    baseline_price = asking_price if asking_price is not None else derived_price
    if baseline_price is None:
        # No reasonable price info; return None values
        return {
            "recommended_offer": None,
            "settlement_range": None,
            "walk_away_price": None,
            "discount_rate": None,
        }

    # Determine discount based on risk and leverage
    risk = scores.get("risk_score", 50.0)
    leverage = scores.get("seller_leverage_score", 50.0)
    opportunity = scores.get("opportunity_score", 50.0)

    # Baseline discount between 5% and 30%
    discount_rate = 0.05 + (risk * 0.002) + (leverage * 0.001)
    # Adjust discount for opportunity (reduce discount slightly if high upside)
    discount_rate -= opportunity * 0.0005
    # Clamp between 0.05 and 0.35
    discount_rate = max(0.05, min(0.35, discount_rate))

    recommended_offer = baseline_price * (1.0 - discount_rate)
    # Settlement range ±5%
    low = recommended_offer * 0.95
    high = recommended_offer * 1.05
    settlement_range: Tuple[float, float] = (round(low, 2), round(high, 2))
    walk_away_price = recommended_offer * 1.10

    return {
        "recommended_offer": round(recommended_offer, 2),
        "settlement_range": settlement_range,
        "walk_away_price": round(walk_away_price, 2),
        "discount_rate": round(discount_rate, 4),
    }
