-- Supabase/PostgreSQL schema for CRE_AI_PLATFORM deal storage.
-- This file defines the core tables used by the extraction, rent roll,
-- due diligence, seller weakness, valuation, and broker follow-up workflow.
-- No credentials or environment-specific values belong in this file.

CREATE EXTENSION IF NOT EXISTS pgcrypto;

CREATE TABLE IF NOT EXISTS properties (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    property_name TEXT NOT NULL,
    alternate_name TEXT,
    address TEXT UNIQUE,
    city TEXT,
    state TEXT,
    zip_code TEXT,
    property_type TEXT,
    asset_class TEXT,
    year_built INTEGER,
    building_sf NUMERIC(14, 2),
    land_acres NUMERIC(12, 4),
    land_sf NUMERIC(14, 2),
    occupancy_pct NUMERIC(6, 3),
    asking_price NUMERIC(14, 2),
    noi NUMERIC(14, 2),
    stated_cap_rate_pct NUMERIC(8, 4),
    actual_cap_rate_pct NUMERIC(8, 4),
    price_per_sf NUMERIC(12, 2),
    annual_base_rent NUMERIC(14, 2),
    annual_opex_recovery NUMERIC(14, 2),
    implied_total_expenses NUMERIC(14, 2),
    implied_expenses_psf NUMERIC(12, 2),
    implied_expense_ratio_pct NUMERIC(8, 4),
    traffic_count_vpd INTEGER,
    demographics JSONB DEFAULT '{}'::jsonb,
    property_highlights JSONB DEFAULT '[]'::jsonb,
    market_summary TEXT,
    investment_summary TEXT,
    acquisition_decision TEXT,
    recommended_first_offer NUMERIC(14, 2),
    offer_strategy JSONB DEFAULT '{}'::jsonb,
    source_name TEXT,
    source_type TEXT DEFAULT 'OM',
    source_file_name TEXT,
    notes JSONB DEFAULT '{}'::jsonb,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_properties_city_state ON properties (city, state);
CREATE INDEX IF NOT EXISTS idx_properties_property_type ON properties (property_type);
CREATE INDEX IF NOT EXISTS idx_properties_asking_price ON properties (asking_price);
CREATE INDEX IF NOT EXISTS idx_properties_cap_rate ON properties (stated_cap_rate_pct);

CREATE TABLE IF NOT EXISTS documents (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    property_id UUID REFERENCES properties(id) ON DELETE CASCADE,
    file_name TEXT,
    document_type TEXT NOT NULL,
    source_url TEXT,
    google_drive_file_id TEXT,
    local_path TEXT,
    mime_type TEXT,
    processed_status TEXT DEFAULT 'processed',
    extracted_at TIMESTAMPTZ DEFAULT now(),
    metadata JSONB DEFAULT '{}'::jsonb,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_documents_property_id ON documents (property_id);
CREATE INDEX IF NOT EXISTS idx_documents_type ON documents (document_type);

CREATE TABLE IF NOT EXISTS brokers (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    property_id UUID REFERENCES properties(id) ON DELETE CASCADE,
    broker_name TEXT NOT NULL,
    title TEXT,
    company TEXT,
    phone TEXT,
    phone_ext TEXT,
    email TEXT,
    office_address TEXT,
    website TEXT,
    role TEXT DEFAULT 'listing_broker',
    source_page INTEGER,
    notes JSONB DEFAULT '{}'::jsonb,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    UNIQUE (property_id, email)
);

CREATE INDEX IF NOT EXISTS idx_brokers_property_id ON brokers (property_id);
CREATE INDEX IF NOT EXISTS idx_brokers_email ON brokers (email);

CREATE TABLE IF NOT EXISTS tenants (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    property_id UUID REFERENCES properties(id) ON DELETE CASCADE,
    tenant_name TEXT,
    tenant TEXT,
    suite TEXT,
    building_address TEXT,
    unit_size_sf NUMERIC(12, 2),
    sf NUMERIC(12, 2),
    annual_rent_psf NUMERIC(12, 2),
    lease_type TEXT,
    monthly_rent NUMERIC(14, 2),
    annual_rent NUMERIC(14, 2),
    annual_opex_recovery NUMERIC(14, 2),
    lease_begin DATE,
    lease_start DATE,
    lease_expiration DATE,
    lease_end DATE,
    rent_bumps TEXT,
    renewal_options TEXT,
    options TEXT,
    occupancy_status TEXT DEFAULT 'occupied',
    tenant_profile TEXT,
    tenant_website TEXT,
    tenant_quality TEXT,
    risk_notes TEXT,
    source_page INTEGER,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    UNIQUE (property_id, building_address, suite)
);

CREATE INDEX IF NOT EXISTS idx_tenants_property_id ON tenants (property_id);
CREATE INDEX IF NOT EXISTS idx_tenants_lease_expiration ON tenants (lease_expiration);
CREATE INDEX IF NOT EXISTS idx_tenants_tenant_name ON tenants (tenant_name);

CREATE TABLE IF NOT EXISTS rent_roll_summaries (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    property_id UUID NOT NULL UNIQUE REFERENCES properties(id) ON DELETE CASCADE,
    total_suites INTEGER,
    total_sf NUMERIC(14, 2),
    total_monthly_rent NUMERIC(14, 2),
    total_annual_rent NUMERIC(14, 2),
    total_annual_opex_recovery NUMERIC(14, 2),
    weighted_average_remaining_lease_term_years NUMERIC(8, 3),
    rollover_by_year JSONB DEFAULT '[]'::jsonb,
    notes JSONB DEFAULT '{}'::jsonb,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS financial_reports (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    property_id UUID REFERENCES properties(id) ON DELETE CASCADE,
    rental_income NUMERIC(14, 2),
    recoveries NUMERIC(14, 2),
    other_income NUMERIC(14, 2),
    gross_income NUMERIC(14, 2),
    taxes NUMERIC(14, 2),
    insurance NUMERIC(14, 2),
    cam NUMERIC(14, 2),
    utilities NUMERIC(14, 2),
    management_fee NUMERIC(14, 2),
    total_expenses NUMERIC(14, 2),
    noi NUMERIC(14, 2),
    cap_rate_pct NUMERIC(8, 4),
    occupancy_pct NUMERIC(6, 3),
    confidence NUMERIC(6, 2),
    source_pdf TEXT,
    raw_json JSONB DEFAULT '{}'::jsonb,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_financial_reports_property_id ON financial_reports (property_id);

CREATE TABLE IF NOT EXISTS analysis (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    property_id UUID REFERENCES properties(id) ON DELETE CASCADE,
    due_diligence_score NUMERIC(6, 2),
    seller_weakness_score NUMERIC(6, 2),
    acquisition_score NUMERIC(6, 2),
    upside_score NUMERIC(6, 2),
    risk_score NUMERIC(6, 2),
    overall_score NUMERIC(6, 2),
    deal_score NUMERIC(6, 2),
    decision TEXT,
    strengths JSONB DEFAULT '[]'::jsonb,
    red_flags JSONB DEFAULT '[]'::jsonb,
    missing_items JSONB DEFAULT '[]'::jsonb,
    weaknesses JSONB DEFAULT '[]'::jsonb,
    due_diligence_notes JSONB DEFAULT '[]'::jsonb,
    seller_weakness_notes JSONB DEFAULT '[]'::jsonb,
    financing_assumptions JSONB DEFAULT '{}'::jsonb,
    broker_questions JSONB DEFAULT '[]'::jsonb,
    valuation_scenarios JSONB DEFAULT '[]'::jsonb,
    summary TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_analysis_property_id ON analysis (property_id);

CREATE TABLE IF NOT EXISTS due_diligence_items (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    property_id UUID NOT NULL REFERENCES properties(id) ON DELETE CASCADE,
    category TEXT NOT NULL,
    item TEXT NOT NULL,
    status TEXT DEFAULT 'needed',
    priority TEXT DEFAULT 'medium',
    notes TEXT,
    source_page INTEGER,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    UNIQUE (property_id, category, item)
);

CREATE INDEX IF NOT EXISTS idx_due_diligence_items_property_id ON due_diligence_items (property_id);
CREATE INDEX IF NOT EXISTS idx_due_diligence_items_status ON due_diligence_items (status);

CREATE TABLE IF NOT EXISTS seller_weakness_items (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    property_id UUID NOT NULL REFERENCES properties(id) ON DELETE CASCADE,
    weakness TEXT NOT NULL,
    leverage_reason TEXT,
    severity TEXT DEFAULT 'medium',
    score_impact NUMERIC(6, 2),
    source_page INTEGER,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    UNIQUE (property_id, weakness)
);

CREATE INDEX IF NOT EXISTS idx_seller_weakness_items_property_id ON seller_weakness_items (property_id);

CREATE TABLE IF NOT EXISTS valuation_scenarios (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    property_id UUID NOT NULL REFERENCES properties(id) ON DELETE CASCADE,
    scenario_name TEXT NOT NULL,
    cap_rate_pct NUMERIC(8, 4),
    noi NUMERIC(14, 2),
    implied_value NUMERIC(14, 2),
    notes TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    UNIQUE (property_id, scenario_name)
);

CREATE INDEX IF NOT EXISTS idx_valuation_scenarios_property_id ON valuation_scenarios (property_id);

CREATE TABLE IF NOT EXISTS broker_questions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    property_id UUID NOT NULL REFERENCES properties(id) ON DELETE CASCADE,
    question TEXT NOT NULL,
    category TEXT,
    priority TEXT DEFAULT 'medium',
    status TEXT DEFAULT 'open',
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    UNIQUE (property_id, question)
);

CREATE INDEX IF NOT EXISTS idx_broker_questions_property_id ON broker_questions (property_id);
CREATE INDEX IF NOT EXISTS idx_broker_questions_status ON broker_questions (status);

CREATE TABLE IF NOT EXISTS committee_reports (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    property_id UUID REFERENCES properties(id) ON DELETE CASCADE,
    report JSONB NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS acquisition_decisions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    property_id UUID REFERENCES properties(id) ON DELETE CASCADE,
    decision JSONB NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Backward-compatible table used by supabase_loader.py.
CREATE TABLE IF NOT EXISTS rent_rolls (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    property_id UUID REFERENCES properties(id) ON DELETE CASCADE,
    tenant_name TEXT,
    suite TEXT,
    sf NUMERIC(12, 2),
    lease_start DATE,
    lease_end DATE,
    monthly_rent NUMERIC(14, 2),
    annual_rent NUMERIC(14, 2),
    rent_psf NUMERIC(12, 2),
    lease_type TEXT,
    renewal_options TEXT,
    source_pdf TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_rent_rolls_property_id ON rent_rolls (property_id);
