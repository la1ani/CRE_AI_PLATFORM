from __future__ import annotations

from .models import ProfileExtraction, ValidationIssue, ValidationResult


def validate_profile(profile: ProfileExtraction) -> ValidationResult:
    issues: list[ValidationIssue] = []
    confidence_values = [
        profile.identity.confidence,
        profile.performance.confidence,
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

    hidden_rows = False
    if profile.transactions.expected_entries is not None and tx_rows < profile.transactions.expected_entries:
        hidden_rows = True
    if profile.loan_details.expected_entries is not None and loan_rows < profile.loan_details.expected_entries:
        hidden_rows = True

    error_codes = {issue.code for issue in issues if issue.severity == "error"}
    if error_codes:
        status = "TOTAL_MISMATCH" if "PERFORMANCE_TOTAL_MISMATCH" in error_codes else "NEEDS_REVIEW"
    elif average_confidence < 75:
        status = "LOW_CONFIDENCE"
    elif hidden_rows:
        status = "PARTIAL_HIDDEN_ROWS"
    else:
        status = "COMPLETE"

    penalty = sum(15 if issue.severity == "error" else 5 for issue in issues)
    score = max(0, min(100, average_confidence - penalty))
    return ValidationResult(status=status, score=score, issues=issues)
