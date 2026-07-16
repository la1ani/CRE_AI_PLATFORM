from realtor_profile_downloader.vision_scanner.models import (
    ExtrasSection,
    IdentitySection,
    LoanDetailRow,
    LoanDetailsSection,
    MonthlyProductionPoint,
    PerformanceLine,
    PerformanceSection,
    ProfileExtraction,
    RelationshipsSection,
    TitleCompanyRelationship,
    TransactionRow,
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


def test_unread_monthly_chart_and_partial_title_totals_reduce_score():
    profile = ProfileExtraction(
        identity=IdentitySection(realtor_name="A Stephanie Mcgrew", email="agent@example.com", confidence=100),
        performance=PerformanceSection(
            buyer_side=PerformanceLine(sides=2),
            seller_side=PerformanceLine(sides=6),
            total=PerformanceLine(sides=8),
            monthly_production=[
                MonthlyProductionPoint(month="Jun"),
                MonthlyProductionPoint(month="Jul"),
                MonthlyProductionPoint(month="Aug"),
            ],
            confidence=100,
        ),
        relationships=RelationshipsSection(confidence=100),
        transactions=TransactionsSection(
            expected_entries=2,
            visible_entries=2,
            rows=[TransactionRow(address="1 Main St"), TransactionRow(address="2 Main St")],
            confidence=100,
        ),
        loan_details=LoanDetailsSection(
            expected_entries=1,
            visible_entries=1,
            rows=[LoanDetailRow(address="1 Main St")],
            confidence=100,
        ),
        extras=ExtrasSection(
            title_relationships=[
                TitleCompanyRelationship(side="buyer", company="Wfg Title", transaction_count=1),
                TitleCompanyRelationship(side="seller", company="Capital Title", transaction_count=2),
                TitleCompanyRelationship(side="seller", company="Select Title", transaction_count=1),
                TitleCompanyRelationship(side="seller", company="Old Republic Title", transaction_count=1),
            ],
            confidence=100,
        ),
    )

    result = validate_profile(profile)
    issue_codes = {issue.code for issue in result.issues}

    assert result.status == "PARTIAL_HIDDEN_ROWS"
    assert result.score == 82
    assert "MONTHLY_CHART_VALUES_UNREADABLE" in issue_codes
    assert "TITLE_BUYER_RELATIONSHIPS_PARTIAL" in issue_codes
    assert "TITLE_SELLER_RELATIONSHIPS_PARTIAL" in issue_codes
    assert "TRANSACTION_VISIBLE_COUNT_MISMATCH" not in issue_codes
    assert "LOAN_VISIBLE_COUNT_MISMATCH" not in issue_codes


def test_complete_title_totals_do_not_create_partial_issue():
    profile = ProfileExtraction(
        identity=IdentitySection(realtor_name="Complete Agent", email="agent@example.com", confidence=95),
        performance=PerformanceSection(
            buyer_side=PerformanceLine(sides=1),
            seller_side=PerformanceLine(sides=2),
            total=PerformanceLine(sides=3),
            confidence=95,
        ),
        relationships=RelationshipsSection(confidence=95),
        transactions=TransactionsSection(confidence=95),
        loan_details=LoanDetailsSection(confidence=95),
        extras=ExtrasSection(
            title_relationships=[
                TitleCompanyRelationship(side="buyer", company="Buyer Title", transaction_count=1),
                TitleCompanyRelationship(side="seller", company="Seller Title", transaction_count=2),
            ],
            confidence=95,
        ),
    )

    result = validate_profile(profile)
    assert result.status == "COMPLETE"
    assert not any(issue.code.startswith("TITLE_") for issue in result.issues)
