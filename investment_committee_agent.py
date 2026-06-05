"""
investment_committee_agent.py
=============================

This module implements the Investment Committee Agent for the CRE acquisition
platform. Given a set of extracted property facts (as JSON), it scores the
deal, identifies major risks and opportunities, generates broker questions,
recommends financing, proposes a negotiation strategy, and produces offer
guidance. The output is a JSON string structured for downstream consumption.

The design focuses on simplicity and transparency. Scores are computed via
`deal_scoring.compute_scores` and offers via `offer_generator.generate_offer`.
The missing information is inferred by checking the presence of key fields in
the property data; typical broker questions are generated accordingly.
"""

from __future__ import annotations

import json
from typing import Any, Dict, List

# Import compute_scores and generate_offer from top-level modules. Relative
# imports (e.g. ".deal_scoring") require this module to be part of a package,
# which is not the case in this standalone script. Using absolute imports
# ensures the functions are found when running main.py.
from deal_scoring import compute_scores
from offer_generator import generate_offer


def _infer_missing_items(property_data: Dict[str, Any]) -> List[str]:
    """Return a list of critical missing items based on property facts."""
    missing = []
    required_fields = {
        "NOI": property_data.get("noi"),
        "Cap Rate": property_data.get("cap_rate"),
        "Asking Price": property_data.get("asking_price"),
        "Occupancy": property_data.get("occupancy"),
        "Building SF": property_data.get("building_sf"),
        "Land SF": property_data.get("land_sf"),
        "Year Built": property_data.get("year_built"),
        "Broker Contact": property_data.get("broker_name"),
    }
    for name, value in required_fields.items():
        if not value:
            missing.append(name)
    return missing


def _generate_broker_questions(missing_items: List[str]) -> List[str]:
    """Generate broker questions from missing data keys."""
    questions = []
    for item in missing_items:
        key = item.lower()
        if "noi" in key:
            questions.append("Please provide the current net operating income (NOI) and a T12 statement.")
        elif "cap rate" in key:
            questions.append("What cap rate are you marketing this property at? Please share supporting data.")
        elif "asking price" in key:
            questions.append("What is the seller's asking price and are they open to offers?")
        elif "occupancy" in key:
            questions.append("What is the current occupancy level and tenant roster?")
        elif "building sf" in key:
            questions.append("What is the verified building square footage?")
        elif "land sf" in key:
            questions.append("What is the total land area of the property?")
        elif "year built" in key:
            questions.append("What year was the property built, and what capital improvements have been made?")
        elif "broker contact" in key:
            questions.append("Who is the listing broker and what is the best way to contact them?")
        else:
            questions.append(f"Please provide additional details for: {item}.")
    # Ensure a minimum of 10 questions by adding generic ones
    generic_questions = [
        "Please provide the current rent roll.",
        "Please provide operating expenses and T12 financials.",
        "Please provide any Phase I/II ESA reports.",
        "Please provide roof and HVAC age and service history.",
        "Please provide utility bills and service contracts.",
        "Please provide insurance loss history.",
    ]
    while len(questions) < 10 and generic_questions:
        questions.append(generic_questions.pop(0))
    return questions[:20]


def _grade_underwriting(deal_score: float) -> str:
    """Convert a numeric deal score into a letter grade."""
    if deal_score >= 90:
        return "A+"
    if deal_score >= 80:
        return "A"
    if deal_score >= 70:
        return "B"
    if deal_score >= 60:
        return "C"
    return "Trash"


def _recommend_financing(risk_score: float, dd_score: float) -> str:
    """Return a simple financing recommendation based on risk and due diligence."""
    # If risk is low and due diligence is high, recommend conventional
    if risk_score < 40 and dd_score > 70:
        return "Conventional"
    # If risk moderate, recommend SBA/DSCR or Bridge for short term
    if risk_score < 60:
        return "SBA or DSCR"
    # High risk: Bridge or Private Money
    return "Bridge or Private Money"


def _select_negotiation_strategy(leverage_score: float) -> str:
    """Select negotiation strategy based on seller leverage score."""
    if leverage_score > 70:
        return "Aggressive"
    if leverage_score > 40:
        return "Moderate"
    return "Conservative"


def run_investment_committee(facts_json: str) -> str:
    """Run the investment committee analysis.

    Args:
        facts_json: A JSON string representing property facts extracted by
            the Property Intelligence Agent.

    Returns:
        A JSON string with the committee report.
    """
    try:
        property_data = json.loads(facts_json)
        if not isinstance(property_data, dict):
            raise ValueError("facts_json is not a dictionary")
    except Exception as exc:
        # Return a minimal report indicating failure
        failure = {
            "error": f"Invalid property facts: {exc}",
            "due_diligence": {"score": 0, "recommendation": "High Risk", "critical_missing_items": []},
            "seller_weakness": {"negotiation_leverage_score": 0, "reasons": ["Invalid input"]},
            "opportunities": {"opportunity_score": 0, "value_creation": []},
            "underwriting": {"grade": "Trash", "reason": "Invalid input"},
            "financing": {"recommended_structure": "Unknown", "estimated_ltv": None, "cash_needed": None},
            "broker_questions": [],
            "negotiation_strategy": {"strategy": "Conservative", "reason": "Invalid input"},
            "offer_analysis": {},
        }
        return json.dumps(failure, indent=2)

    # Compute scores
    scores = compute_scores(property_data)
    dd_score = scores.get("due_diligence_score", 0.0)
    leverage_score = scores.get("seller_leverage_score", 0.0)
    opportunity_score = scores.get("opportunity_score", 0.0)
    risk_score = scores.get("risk_score", 0.0)
    deal_score = scores.get("deal_score", 0.0)

    # Determine critical missing items
    missing_items = _infer_missing_items(property_data)

    # Due diligence recommendation
    if dd_score >= 75:
        dd_recommendation = "Ready For Offer"
    elif dd_score >= 50:
        dd_recommendation = "Need More Information"
    else:
        dd_recommendation = "High Risk"

    # Seller weakness reasons
    leverage_reasons = []
    if leverage_score > 80:
        leverage_reasons.append("High vacancy or missing financials increases seller pressure.")
    elif leverage_score > 50:
        leverage_reasons.append("Some vacancy or uncertainty gives negotiation leverage.")
    else:
        leverage_reasons.append("Low leverage; seller may be firm on pricing.")

    # Opportunities descriptions
    opportunity_descriptions = []
    if opportunity_score > 70:
        opportunity_descriptions.append("Significant upside through lease‑up and rent increases.")
    elif opportunity_score > 40:
        opportunity_descriptions.append("Moderate upside if vacancy can be addressed.")
    else:
        opportunity_descriptions.append("Limited upside potential.")

    # Underwriting grade and reason
    grade = _grade_underwriting(deal_score)
    underwriting_reason = "Strong deal fundamentals." if grade in ("A+", "A", "B") else "Deal has material risks or unknowns."

    # Financing recommendation
    financing_structure = _recommend_financing(risk_score, dd_score)
    # For simplicity, LTV and cash needed are not computed; they could be derived from offer.
    financing = {
        "recommended_structure": financing_structure,
        "estimated_ltv": None,
        "cash_needed": None,
    }

    # Generate broker questions
    questions = _generate_broker_questions(missing_items)

    # Negotiation strategy
    strategy = _select_negotiation_strategy(leverage_score)
    negotiation = {
        "strategy": strategy,
        "reason": (
            "High seller leverage; push for maximum discount." if strategy == "Aggressive" else
            "Moderate leverage; balance firmness with flexibility." if strategy == "Moderate" else
            "Low leverage; adopt conservative negotiation approach."
        )
    }

    # Offer analysis
    offer = generate_offer(property_data, scores)
    offer_analysis = {
        "asking_price": property_data.get("asking_price"),
        "recommended_offer": offer.get("recommended_offer"),
        "settlement_range": offer.get("settlement_range"),
        "walk_away_price": offer.get("walk_away_price"),
        "discount_rate": offer.get("discount_rate"),
    }

    committee_report = {
        "scores": scores,
        "due_diligence": {
            "score": dd_score,
            "recommendation": dd_recommendation,
            "critical_missing_items": missing_items,
        },
        "seller_weakness": {
            "negotiation_leverage_score": leverage_score,
            "reasons": leverage_reasons,
        },
        "opportunities": {
            "opportunity_score": opportunity_score,
            "value_creation": opportunity_descriptions,
        },
        "underwriting": {
            "grade": grade,
            "reason": underwriting_reason,
        },
        "financing": financing,
        "broker_questions": questions,
        "negotiation_strategy": negotiation,
        "offer_analysis": offer_analysis,
    }

    return json.dumps(committee_report, indent=2)
