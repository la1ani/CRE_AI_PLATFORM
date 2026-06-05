"""
acquisition_director.py
=======================

This module implements the Acquisition Director for the CRE acquisition
platform. The director is responsible for taking the outputs of the
Property Intelligence Agent (property facts) and the Investment Committee
Agent (committee report) and making a final acquisition recommendation.
The recommendation consists of a simple decision (BUY, HOLD or REJECT),
a confidence score, summary metrics from the committee report, and a
list of high‑level reasons supporting the decision.

The logic here is intentionally transparent and heuristic. It uses
scores produced by the investment committee—such as due diligence,
seller leverage, opportunity and risk—to evaluate the strength of the
deal. If key data are missing or the risk is high, the director will
recommend HOLD or REJECT. If due diligence is strong and risk is low,
it may recommend BUY. Confidence scores are derived from the same
signals. This module can be refined further with more sophisticated
analysis, but provides a reasonable baseline for testing.
"""

from __future__ import annotations

import json
from typing import Any, Dict


def _compute_confidence(dd_score: float, risk: float, leverage: float, opportunity: float) -> float:
    """Compute a confidence score based on component scores.

    The confidence score is scaled between 0 and 100 and increases with
    higher due diligence and opportunity scores, and decreases with higher
    risk and leverage. This is a simple weighted combination that can be
    tuned for more nuanced behaviour.
    """
    # Weights: due diligence (40%), opportunity (20%), leverage (20%), risk (20%)
    confidence = (
        dd_score * 0.4
        + opportunity * 0.2
        + (100 - leverage) * 0.2
        + (100 - risk) * 0.2
    )
    return max(0.0, min(100.0, round(confidence, 2)))


def run_acquisition_director(facts_json: str, committee_json: str) -> str:
    """Produce a final acquisition decision.

    Args:
        facts_json: A JSON string representing the property facts.
        committee_json: A JSON string produced by the Investment Committee.

    Returns:
        A JSON string containing the decision, confidence score, summary
        metrics and reasons. If the input JSON strings cannot be parsed,
        the function returns a rejection decision with a low confidence.
    """
    # Default decision in case of parsing errors
    default_decision = {
        "decision": "REJECT",
        "confidence_score": 10.0,
        "summary": {},
        "top_reasons": [
            "Unable to parse committee or property data."
        ],
    }
    try:
        property_data: Dict[str, Any] = json.loads(facts_json)
        committee_data: Dict[str, Any] = json.loads(committee_json)
    except Exception as exc:
        # Return default rejection if JSON cannot be parsed
        default_decision["top_reasons"].append(f"JSON parsing error: {exc}")
        return json.dumps(default_decision, indent=2)

    # Extract scores and grade from committee report
    scores: Dict[str, Any] = committee_data.get("scores", {})
    dd_score: float = scores.get("due_diligence_score", 0.0)
    leverage_score: float = scores.get("seller_leverage_score", 0.0)
    opportunity_score: float = scores.get("opportunity_score", 0.0)
    risk_score: float = scores.get("risk_score", 0.0)
    deal_score: float = scores.get("deal_score", 0.0)
    underwriting: Dict[str, Any] = committee_data.get("underwriting", {})
    grade: str = underwriting.get("grade", "C")

    # Determine decision
    decision: str
    reasons: list[str] = []
    # Reject if due diligence is very low or risk extremely high
    if dd_score < 40 or risk_score > 80:
        decision = "REJECT"
        reasons.append("Insufficient due diligence or extremely high risk.")
    else:
        # Evaluate based on grade and scores
        if dd_score >= 75 and grade in ("A+", "A", "B") and risk_score <= 50:
            decision = "BUY"
            reasons.append("Strong due diligence, acceptable risk and solid underwriting grade.")
        elif deal_score < 50 or grade in ("C", "Trash"):
            decision = "HOLD"
            reasons.append("Moderate deal score or weak underwriting grade.")
        else:
            decision = "HOLD"
            reasons.append("Further analysis required; incomplete data or moderate risk.")

    # Evaluate missing information from property facts
    missing_fields = property_data.get("missing_information", [])
    if missing_fields:
        reasons.append(f"Missing critical information: {', '.join(missing_fields)}.")
        # Reduce confidence if missing many items
        if len(missing_fields) > 3:
            dd_score = max(0.0, dd_score - 10.0)
            risk_score = min(100.0, risk_score + 10.0)

    # Compute confidence
    confidence = _compute_confidence(dd_score, risk_score, leverage_score, opportunity_score)

    # Summary metrics for reporting
    summary = {
        "due_diligence_score": dd_score,
        "seller_leverage_score": leverage_score,
        "opportunity_score": opportunity_score,
        "risk_score": risk_score,
        "deal_score": deal_score,
        "underwriting_grade": grade,
    }

    # Limit reasons to top 5 to keep output concise
    top_reasons = reasons[:10]

    result = {
        "decision": decision,
        "confidence_score": confidence,
        "summary": summary,
        "top_reasons": top_reasons,
    }
    return json.dumps(result, indent=2)