from __future__ import annotations

from .models import ProfileExtraction, ValidationIssue, ValidationResult


def _present(value: str | None) -> bool:
    return value is not None and str(value).strip() not in {"", "N/A", "n/a", "null", "None"}


def validate_profile(profile: ProfileExtraction) -> ValidationResult:
    issues: list[ValidationIssue] = []

    # Gemini supplies section confidence, but a section cannot remain 100% confident when
    # expected chart values were not readable. Cap the effective confidence used for scoring.
    performance_confidence = profile.performance.confidence
    monthly_points = profile.performance.monthly_production
    if monthly_points:
        readable_months = sum(
            1
            for point in monthly_points
            if _present(point.current_period_raw) or _present(point.prior_period_raw)
        )
        if readable_months == 0:
            performance_confidence = min(performance_confidence, 80)
            issues.append(
                ValidationIssue(
                    code="MONTHLY_CHART_VALUES_UNREADABLE",
                    message="Monthly labels were detected, but none of the monthly production values were readable.",
                )
            )
        elif readable_months < len(monthly_points):
            performance_confidence = min(performance_confidence, 90)
            issues.append(
                ValidationIssue(
                    code="MONTHLY_CHART_VALUES_PARTIAL",
                    message=(
                        f"Monthly production values were readable for {readable_months} of "
                        f"{len(monthly_points)} displayed months."
                    ),
                )
            )

    confidence_values = [
        profile.identity.confidence,
        performance_confidence,
        profile.relationships.confidence,
        profile.transactions.confidence,
        profile.loan_details.confidence,
        profile.extras.confidence,
    ]
    average_confidence = round(sum(confidence_values) / len(confidence_values))

    if not profile.identity.realtor_name:
        issues.append(ValidationIssue(code="MISSING_NAME", message="Realtor name was not extracted.", severity="error"))
    if not profile.identity.email:
        issues.append(ValidationIssue(code="MISSING_EMAIL", message="Email was not extracted."))

    buyer = profile.performance.buyer_side.sides
    seller = profile.performance.seller_side.sides
    total = profile.performance.total.sides
    if buyer is not None and seller is not None and total is not None and buyer + seller != total:
        issues.append(
            ValidationIssue(
                code="PERFORMANCE_TOTAL_MISMATCH",
                message=f"Buyer sides ({buyer}) + seller sides ({seller}) does not equal total ({total}).",
                severity="error",
            )
        )

    tx_rows = len(profile.transactions.rows)
    if profile.transactions.visible_entries is not None and tx_rows != profile.transactions.visible_entries:
        issues.append(
            ValidationIssue(
                code="TRANSACTION_VISIBLE_COUNT_MISMATCH",
                message=f"Extracted {tx_rows} transaction rows but footer/vision reported {profile.transactions.visible_entries} visible.",
            )
        )

    loan_rows = len(profile.loan_details.rows)
    if profile.loan_details.visible_entries is not None and loan_rows != profile.loan_details.visible_entries:
        issues.append(
            ValidationIssue(
                code="LOAN_VISIBLE_COUNT_MISMATCH",
                message=f"Extracted {loan_rows} loan rows but footer/vision reported {profile.loan_details.visible_entries} visible.",
            )
        )

    partial_data = False
    if profile.transactions.expected_entries is not None and tx_rows < profile.transactions.expected_entries:
        partial_data = True
    if profile.loan_details.expected_entries is not None and loan_rows < profile.loan_details.expected_entries:
        partial_data = True

    # Title-company relationship cards often show only a subset of the agent's transactions.
    # Compare only sides that are actually present in the title section. A shortfall is partial;
    # an extracted count greater than performance totals is a validation error.
    for side, expected_sides in (("buyer", buyer), ("seller", seller)):
        side_relationships = [row for row in profile.extras.title_relationships if row.side == side]
        if not side_relationships or expected_sides is None:
            continue
        extracted_count = sum(row.transaction_count or 0 for row in side_relationships)
        if extracted_count < expected_sides:
            partial_data = True
            issues.append(
                ValidationIssue(
                    code=f"TITLE_{side.upper()}_RELATIONSHIPS_PARTIAL",
                    message=(
                        f"Visible {side}-side title relationships account for {extracted_count} of "
                        f"{expected_sides} {side}-side transactions."
                    ),
                )
            )
        elif extracted_count > expected_sides:
            issues.append(
                ValidationIssue(
                    code=f"TITLE_{side.upper()}_TOTAL_EXCEEDS_SIDES",
                    message=(
                        f"Visible {side}-side title relationships total {extracted_count}, which exceeds "
                        f"the performance total of {expected_sides}."
                    ),
                    severity="error",
                )
            )

    error_codes = {issue.code for issue in issues if issue.severity == "error"}
    if error_codes:
        status = "TOTAL_MISMATCH" if "PERFORMANCE_TOTAL_MISMATCH" in error_codes else "NEEDS_REVIEW"
    elif average_confidence < 75:
        status = "LOW_CONFIDENCE"
    elif partial_data:
        status = "PARTIAL_HIDDEN_ROWS"
    else:
        status = "COMPLETE"

    penalty = sum(15 if issue.severity == "error" else 5 for issue in issues)
    score = max(0, min(100, average_confidence - penalty))
    return ValidationResult(status=status, score=score, issues=issues)
