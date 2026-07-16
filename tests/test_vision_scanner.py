from realtor_profile_downloader.vision_scanner.models import (
    ExtrasSection,
    IdentitySection,
    LoanDetailsSection,
    PerformanceLine,
    PerformanceSection,
    ProfileExtraction,
    RelationshipsSection,
    TransactionsSection,
)
from realtor_profile_downloader.vision_scanner.normalizer import normalize_money, normalize_percent
from realtor_profile_downloader.vision_scanner.validator import validate_profile


def test_money_and_percent_normalization():
    assert normalize_money("$17M") == 17_000_000
    assert normalize_money("$456K") == 456_000
    assert normalize_money("$1,805,000") == 1_805_000
    assert normalize_percent("98.9%") == 98.9


def test_hidden_rows_are_marked_partial():
    profile = ProfileExtraction(
        identity=IdentitySection(realtor_name="Test Agent", email="agent@example.com", confidence=95),
        performance=PerformanceSection(
            buyer_side=PerformanceLine(sides=26),
            seller_side=PerformanceLine(sides=6),
            total=PerformanceLine(sides=32),
            confidence=95,
        ),
        relationships=RelationshipsSection(confidence=90),
        transactions=TransactionsSection(expected_entries=26, visible_entries=6, rows=[], confidence=90),
        loan_details=LoanDetailsSection(expected_entries=19, visible_entries=9, rows=[], confidence=90),
        extras=ExtrasSection(confidence=90),
    )
    result = validate_profile(profile)
    assert result.status == "PARTIAL_HIDDEN_ROWS"


def test_total_mismatch_requires_review():
    profile = ProfileExtraction(
        identity=IdentitySection(realtor_name="Test Agent", email="agent@example.com", confidence=95),
        performance=PerformanceSection(
            buyer_side=PerformanceLine(sides=10),
            seller_side=PerformanceLine(sides=5),
            total=PerformanceLine(sides=20),
            confidence=95,
        ),
        relationships=RelationshipsSection(confidence=90),
        transactions=TransactionsSection(confidence=90),
        loan_details=LoanDetailsSection(confidence=90),
        extras=ExtrasSection(confidence=90),
    )
    result = validate_profile(profile)
    assert result.status == "TOTAL_MISMATCH"
