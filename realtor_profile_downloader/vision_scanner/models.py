from __future__ import annotations

from typing import Literal

from pydantic import BaseModel, Field


class IdentitySection(BaseModel):
    realtor_name: str | None = None
    brokerage: str | None = None
    email: str | None = None
    phone: str | None = None
    languages: list[str] = Field(default_factory=list)
    transaction_volume_raw: str | None = None
    loan_count: int | None = None
    loan_officers_used: int | None = None
    loan_count_loyalty_percent_raw: str | None = None
    loan_volume_loyalty_percent_raw: str | None = None
    connections: int | None = None
    social_platforms_visible: list[str] = Field(default_factory=list)
    confidence: int = Field(default=0, ge=0, le=100)


class PerformanceLine(BaseModel):
    sides: int | None = None
    volume_raw: str | None = None
    average_price_raw: str | None = None


class MonthlyProductionPoint(BaseModel):
    month: str
    current_period_raw: str | None = None
    prior_period_raw: str | None = None


class PerformanceSection(BaseModel):
    period: str | None = None
    buyer_side: PerformanceLine = Field(default_factory=PerformanceLine)
    seller_side: PerformanceLine = Field(default_factory=PerformanceLine)
    total: PerformanceLine = Field(default_factory=PerformanceLine)
    conventional_raw: str | None = None
    va_raw: str | None = None
    fha_raw: str | None = None
    other_raw: str | None = None
    monthly_production: list[MonthlyProductionPoint] = Field(default_factory=list)
    confidence: int = Field(default=0, ge=0, le=100)


class LoanOfficerRelationship(BaseModel):
    loan_officer_name: str | None = None
    company: str | None = None
    branch: str | None = None
    loan_count: int | None = None
    relationship_percent_raw: str | None = None


class LoanCompanyRelationship(BaseModel):
    company: str | None = None
    loan_count: int | None = None
    relationship_percent_raw: str | None = None


class RelationshipsSection(BaseModel):
    reported_total_loans: int | None = None
    reported_loan_officers_used: int | None = None
    reported_companies_used: int | None = None
    loan_officer_relationships: list[LoanOfficerRelationship] = Field(default_factory=list)
    loan_company_relationships: list[LoanCompanyRelationship] = Field(default_factory=list)
    direct_connections: int | None = None
    office_connections: int | None = None
    indirect_connections: int | None = None
    show_more_present: bool = False
    confidence: int = Field(default=0, ge=0, le=100)


class TransactionRow(BaseModel):
    address: str | None = None
    sale_date_raw: str | None = None
    buyer_agent: str | None = None
    buyer_agent_company: str | None = None
    seller_agent: str | None = None
    seller_agent_company: str | None = None
    sale_price_raw: str | None = None
    loan_amount_raw: str | None = None
    ltv_raw: str | None = None
    loan_type: str | None = None
    loan_officer: str | None = None
    loan_officer_company: str | None = None


class TransactionsSection(BaseModel):
    expected_entries: int | None = None
    visible_entries: int | None = None
    rows: list[TransactionRow] = Field(default_factory=list)
    confidence: int = Field(default=0, ge=0, le=100)


class LoanDetailRow(BaseModel):
    address: str | None = None
    sale_date_raw: str | None = None
    sale_price_raw: str | None = None
    loan_amount_raw: str | None = None
    ltv_raw: str | None = None
    loan_type: str | None = None
    loan_officer: str | None = None
    loan_officer_company: str | None = None
    lender: str | None = None


class TopLoanCompany(BaseModel):
    company: str | None = None
    loan_count: int | None = None


class LoanDetailsSection(BaseModel):
    expected_entries: int | None = None
    visible_entries: int | None = None
    retail_share_raw: str | None = None
    wholesale_share_raw: str | None = None
    top_loan_companies: list[TopLoanCompany] = Field(default_factory=list)
    rows: list[LoanDetailRow] = Field(default_factory=list)
    confidence: int = Field(default=0, ge=0, le=100)


class TitleCompanyRelationship(BaseModel):
    side: Literal["buyer", "seller"]
    company: str | None = None
    transaction_count: int | None = None
    relationship_percent_raw: str | None = None


class ListingRow(BaseModel):
    address: str | None = None
    list_date_raw: str | None = None
    list_price_raw: str | None = None
    open_house: str | None = None


class ExtrasSection(BaseModel):
    title_relationships: list[TitleCompanyRelationship] = Field(default_factory=list)
    listings_expected: int | None = None
    listings_visible: int | None = None
    recent_listings: list[ListingRow] = Field(default_factory=list)
    confidence: int = Field(default=0, ge=0, le=100)


class ProfileExtraction(BaseModel):
    identity: IdentitySection
    performance: PerformanceSection
    relationships: RelationshipsSection
    transactions: TransactionsSection
    loan_details: LoanDetailsSection
    extras: ExtrasSection


class ValidationIssue(BaseModel):
    code: str
    message: str
    severity: Literal["warning", "error"] = "warning"


class ValidationResult(BaseModel):
    status: Literal[
        "COMPLETE",
        "PARTIAL_HIDDEN_ROWS",
        "LOW_CONFIDENCE",
        "TOTAL_MISMATCH",
        "NEEDS_REVIEW",
        "FAILED",
    ]
    score: int = Field(ge=0, le=100)
    issues: list[ValidationIssue] = Field(default_factory=list)
