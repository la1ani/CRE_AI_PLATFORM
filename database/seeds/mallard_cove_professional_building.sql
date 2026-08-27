-- Seed data for Mallard Cove Professional Building extracted from the OM PDF.
-- Run database/schema.sql first. This seed is repeatable and uses upserts.

BEGIN;

INSERT INTO properties (
    property_name, alternate_name, address, city, state, zip_code,
    property_type, asset_class, year_built, building_sf, land_acres, land_sf,
    occupancy_pct, asking_price, noi, stated_cap_rate_pct, actual_cap_rate_pct,
    price_per_sf, annual_base_rent, annual_opex_recovery, implied_total_expenses,
    implied_expenses_psf, implied_expense_ratio_pct, traffic_count_vpd,
    demographics, property_highlights, market_summary, investment_summary,
    acquisition_decision, recommended_first_offer, offer_strategy,
    source_name, source_type, source_file_name, notes
)
VALUES (
    'Mallard Cove Professional Building',
    'Mallard Cove - Office Park',
    '2643-2751 S Loop 336 W, Conroe, TX 77304',
    'Conroe',
    'TX',
    '77304',
    'Retail/Office Park',
    'Class A multi-tenant retail/office',
    2022,
    20000,
    4.167,
    181514.52,
    100.0,
    6250000,
    492575,
    8.0,
    7.88,
    312.50,
    524450,
    78125,
    110000,
    5.50,
    18.3,
    12986,
    '{"1_mile":{"total_population":4678,"total_daytime_population":3011,"average_household_income":138653},"3_miles":{"total_population":41982,"total_daytime_population":55584,"average_household_income":115347},"5_miles":{"total_population":125202,"total_daytime_population":124925,"average_household_income":122012},"source":"2026 STDB as cited in OM"}'::jsonb,
    '["Class A 20K SF multi-tenant retail/office park in Conroe, TX","Situated on 4.16+ acres with visibility and access from Loop 336 W","Near Johnson Development and Grand Central Park MPC","Within one mile of 336 Marketplace retail development","New 2022 construction with modern finishes","Walking path, back patio spaces, lake, ample signage, and ample parking","100% occupied and presented as fully stabilized"]'::jsonb,
    'Conroe is in the Greater Houston metro. The OM cites Conroe as a fastest-growing city with 7.8% annual growth and points to Grand Central Park, Woodforest, The Woodlands Hills, 18,000 planned homes, 336 Marketplace, retail expansion, and airport investment as demand drivers.',
    'Stabilized 2022 Class A small-bay professional retail/office park with 20,000 SF across eight 2,500 SF suites. Strengths are full occupancy, newer construction, Conroe growth, and a mixed tenant base. Main underwriting issues are short WALT, two gross leases, missing T12 detail, and limited lease abstract data.',
    'HOLD / REQUEST MORE INFO',
    5750000,
    '{"aggressive_buyer_offer":{"low":5450000,"high":5650000},"reasonable_first_offer":{"low":5700000,"high":5850000},"if_t12_and_leases_verify":{"low":5900000,"high":6100000},"full_ask":"Only if financing, leases, T12, tenant strength, taxes, insurance, and CAM recoveries check out"}'::jsonb,
    'Mallard Cove OM',
    'OM',
    '9d5debbf-b7dd-4943-9e8d-e66df2b91f9b.pdf',
    '{"om_pages":11,"sale_price_page":3,"rent_roll_page":4,"tenant_profile_pages":[6,7],"broker_contact_page":11,"site_plan_page":8,"survey_page":9,"market_overview_page":10}'::jsonb
)
ON CONFLICT (address) DO UPDATE SET
    property_name = EXCLUDED.property_name,
    alternate_name = EXCLUDED.alternate_name,
    city = EXCLUDED.city,
    state = EXCLUDED.state,
    zip_code = EXCLUDED.zip_code,
    property_type = EXCLUDED.property_type,
    asset_class = EXCLUDED.asset_class,
    year_built = EXCLUDED.year_built,
    building_sf = EXCLUDED.building_sf,
    land_acres = EXCLUDED.land_acres,
    land_sf = EXCLUDED.land_sf,
    occupancy_pct = EXCLUDED.occupancy_pct,
    asking_price = EXCLUDED.asking_price,
    noi = EXCLUDED.noi,
    stated_cap_rate_pct = EXCLUDED.stated_cap_rate_pct,
    actual_cap_rate_pct = EXCLUDED.actual_cap_rate_pct,
    price_per_sf = EXCLUDED.price_per_sf,
    annual_base_rent = EXCLUDED.annual_base_rent,
    annual_opex_recovery = EXCLUDED.annual_opex_recovery,
    implied_total_expenses = EXCLUDED.implied_total_expenses,
    implied_expenses_psf = EXCLUDED.implied_expenses_psf,
    implied_expense_ratio_pct = EXCLUDED.implied_expense_ratio_pct,
    traffic_count_vpd = EXCLUDED.traffic_count_vpd,
    demographics = EXCLUDED.demographics,
    property_highlights = EXCLUDED.property_highlights,
    market_summary = EXCLUDED.market_summary,
    investment_summary = EXCLUDED.investment_summary,
    acquisition_decision = EXCLUDED.acquisition_decision,
    recommended_first_offer = EXCLUDED.recommended_first_offer,
    offer_strategy = EXCLUDED.offer_strategy,
    source_name = EXCLUDED.source_name,
    source_type = EXCLUDED.source_type,
    source_file_name = EXCLUDED.source_file_name,
    notes = EXCLUDED.notes,
    updated_at = now();

WITH property AS (
    SELECT id FROM properties WHERE address = '2643-2751 S Loop 336 W, Conroe, TX 77304'
)
INSERT INTO documents (property_id, file_name, document_type, mime_type, processed_status, extracted_at, metadata)
SELECT id, '9d5debbf-b7dd-4943-9e8d-e66df2b91f9b.pdf', 'offering_memorandum', 'application/pdf', 'processed', now(),
       '{"pages":11,"contains_rent_roll":true,"contains_tenant_profiles":true,"contains_site_plan":true,"contains_property_survey":true,"contains_market_overview":true}'::jsonb
FROM property
ON CONFLICT (property_id, file_name, document_type) DO UPDATE SET
    mime_type = EXCLUDED.mime_type,
    processed_status = EXCLUDED.processed_status,
    extracted_at = EXCLUDED.extracted_at,
    metadata = EXCLUDED.metadata;

WITH property AS (
    SELECT id FROM properties WHERE address = '2643-2751 S Loop 336 W, Conroe, TX 77304'
)
INSERT INTO brokers (property_id, broker_name, title, company, phone, phone_ext, email, office_address, website, source_page)
SELECT p.id, b.broker_name, b.title, b.company, b.phone, b.phone_ext, b.email, b.office_address, b.website, 11
FROM property p
CROSS JOIN (VALUES
    ('Linda Crumley', 'Advisor', 'SVN | J. Beard Real Estate', '281-367-2220', '119', 'linda.crumley@svn.com', '9320 Lakeside Blvd, Ste 250, The Woodlands, TX 77381', 'jbeardcompany.com'),
    ('Brigham Hedges', 'Associate Advisor', 'SVN | J. Beard Real Estate', '281-367-2220', '143', 'brigham.hedges@svn.com', '9320 Lakeside Blvd, Ste 250, The Woodlands, TX 77381', 'jbeardcompany.com')
) AS b(broker_name, title, company, phone, phone_ext, email, office_address, website)
ON CONFLICT (property_id, email) DO UPDATE SET
    broker_name = EXCLUDED.broker_name,
    title = EXCLUDED.title,
    company = EXCLUDED.company,
    phone = EXCLUDED.phone,
    phone_ext = EXCLUDED.phone_ext,
    office_address = EXCLUDED.office_address,
    website = EXCLUDED.website,
    source_page = EXCLUDED.source_page;

WITH property AS (
    SELECT id FROM properties WHERE address = '2643-2751 S Loop 336 W, Conroe, TX 77304'
)
INSERT INTO tenants (
    property_id, tenant_name, tenant, suite, building_address, unit_size_sf, sf,
    annual_rent_psf, lease_type, monthly_rent, annual_rent, annual_opex_recovery,
    lease_begin, lease_start, lease_expiration, lease_end, rent_bumps,
    renewal_options, options, occupancy_status, tenant_profile, tenant_website,
    tenant_quality, risk_notes, source_page
)
SELECT p.id, t.tenant_name, t.tenant_name, t.suite, t.building_address, t.unit_size_sf, t.unit_size_sf,
       t.annual_rent_psf, t.lease_type, t.monthly_rent, t.annual_rent, t.annual_opex_recovery,
       t.lease_begin, t.lease_begin, t.lease_expiration, t.lease_expiration, t.rent_bumps,
       t.renewal_options, t.renewal_options, 'occupied', t.tenant_profile, t.tenant_website,
       t.tenant_quality, t.risk_notes, 4
FROM property p
CROSS JOIN (VALUES
    ('Compassionate Care Hospice of Southeastern Texas, LLC', 'Suite A', '2685 S Loop 336 W', 2500, 30.36, 'Gross', 6325, 75900, NULL::numeric, '2022-05-01'::date, '2027-04-30'::date, 'None', 'Two 3-year terms at lesser of market rates or current lease rate', 'Hospice care administrative office in Conroe. OM describes tenant as part of a national hospice care company headquartered in Baton Rouge, LA.', 'amedisys.com', 'stronger', 'Near-term 2027 expiration, highest annual rent in roll, gross lease expense exposure, renewal language may cap upside.'),
    ('PowerPath International', 'Suite B', '2685 S Loop 336 W', 2500, 26.50, 'NNN', 5521, 66250, 13750, '2026-07-01'::date, '2029-06-30'::date, '3% Annual', 'None', 'Global supplier of power generation equipment and energy solutions.', 'powerpathie.com', 'local/specialty', 'Lease begins July 2026; verify commencement, guarantee, and payment history.'),
    ('Experience Network, LLC', 'Suite A', '2671 S Loop 336 W', 2500, 25.50, 'NNN', 5313, 63750, 13125, '2024-12-01'::date, '2029-11-30'::date, '$0.50 Annual', 'One 5-year option at market rate', 'Also known as Grand Terra Realty, an independent brokerage with 75 agents serving Montgomery and surrounding counties.', 'grandterrarealty.com', 'local', 'Local tenant profile; verify tenant financials and renewal probability.'),
    ('Quatro Tax, LLC', 'Suite B', '2671 S Loop 336 W', 2500, 25.50, 'NNN', 5313, 63750, 13125, '2025-10-01'::date, '2028-09-30'::date, '$0.50 Annual', 'No Option', 'Property tax consulting firm with offices in Conroe, Houston, and Dallas Fort Worth. OM says it manages ad valorem taxes for over $12.4B in real estate and business personal property.', 'quatrotax.com', 'stronger', 'No renewal option; OM text has typo in September expiration.'),
    ('Ryan Nelson Chiropractor', 'Suite A', '2657 S Loop 336 W', 2500, 25.20, 'Gross', 5250, 63000, NULL::numeric, '2023-02-01'::date, '2028-02-29'::date, '5% Annual', 'None', 'Chiropractic and rehabilitation practice focused on physiotherapy, stretching, strengthening exercises, spinal manipulation, exercise, and nutrition.', 'conroespine.com', 'local', 'Gross lease expense exposure; verify reimbursement obligations and tenant credit.'),
    ('Investar', 'Suite B', '2657 S Loop 336 W', 2500, 24.97, 'NNN', 5202, 62425, 12500, '2024-04-01'::date, '2029-03-31'::date, '2% Annual', 'One 5-year renewal at market rates', 'Investar Bank is a full-service community bank headquartered in Baton Rouge. OM cites $2.8B in assets and 29+ locations after purchase of First National Bank as of 2026-01-02.', 'investarbank.com', 'stronger', 'Good tenant profile; verify lease entity and guaranty.'),
    ('Manuel Builders', 'Suite A', '2643 S Loop 336 W', 2500, 25.75, 'NNN', 5365, 64375, 12500, '2024-04-01'::date, '2030-01-31'::date, '3% Annual', 'One 5-year renewal at market rates', 'Family-owned home builder with over 65 years of experience in residential homes and commercial construction, with regional locations including the Greater Houston area.', 'manuelbuilders.com', 'stronger', 'Good renewal option; verify tenant financial strength and assignment language.'),
    ('Core Movement Therapy LLC', 'Suite B', '2643 S Loop 336 W', 2500, 26.00, 'NNN', 5417, 65000, 13125, '2026-07-07'::date, '2030-06-06'::date, '2.5% Annual', 'None', 'The CORE Movement Studio offers in-home small group Pilates classes and private training sessions.', 'coremovementstudio.com', 'local', 'No renewal option; small wellness tenant profile; verify lease start and deposits.')
) AS t(tenant_name, suite, building_address, unit_size_sf, annual_rent_psf, lease_type, monthly_rent, annual_rent, annual_opex_recovery, lease_begin, lease_expiration, rent_bumps, renewal_options, tenant_profile, tenant_website, tenant_quality, risk_notes)
ON CONFLICT (property_id, building_address, suite) DO UPDATE SET
    tenant_name = EXCLUDED.tenant_name,
    tenant = EXCLUDED.tenant,
    unit_size_sf = EXCLUDED.unit_size_sf,
    sf = EXCLUDED.sf,
    annual_rent_psf = EXCLUDED.annual_rent_psf,
    lease_type = EXCLUDED.lease_type,
    monthly_rent = EXCLUDED.monthly_rent,
    annual_rent = EXCLUDED.annual_rent,
    annual_opex_recovery = EXCLUDED.annual_opex_recovery,
    lease_begin = EXCLUDED.lease_begin,
    lease_start = EXCLUDED.lease_start,
    lease_expiration = EXCLUDED.lease_expiration,
    lease_end = EXCLUDED.lease_end,
    rent_bumps = EXCLUDED.rent_bumps,
    renewal_options = EXCLUDED.renewal_options,
    options = EXCLUDED.options,
    occupancy_status = EXCLUDED.occupancy_status,
    tenant_profile = EXCLUDED.tenant_profile,
    tenant_website = EXCLUDED.tenant_website,
    tenant_quality = EXCLUDED.tenant_quality,
    risk_notes = EXCLUDED.risk_notes,
    source_page = EXCLUDED.source_page;

WITH property AS (
    SELECT id FROM properties WHERE address = '2643-2751 S Loop 336 W, Conroe, TX 77304'
)
INSERT INTO rent_roll_summaries (
    property_id, total_suites, total_sf, total_monthly_rent, total_annual_rent,
    total_annual_opex_recovery, weighted_average_remaining_lease_term_years,
    rollover_by_year, notes
)
SELECT id, 8, 20000, 43704, 524450, 78125, 2.5,
       '[{"year":2027,"sf_expiring":2500,"building_pct":12.5,"annual_rent_expiring":75900},{"year":2028,"sf_expiring":5000,"building_pct":25.0,"annual_rent_expiring":126750},{"year":2029,"sf_expiring":7500,"building_pct":37.5,"annual_rent_expiring":192425},{"year":2030,"sf_expiring":5000,"building_pct":25.0,"annual_rent_expiring":129375}]'::jsonb,
       '{"rollover_comment":"37.5% of building rolls by end of 2028; 75% rolls by end of 2029."}'::jsonb
FROM property
ON CONFLICT (property_id) DO UPDATE SET
    total_suites = EXCLUDED.total_suites,
    total_sf = EXCLUDED.total_sf,
    total_monthly_rent = EXCLUDED.total_monthly_rent,
    total_annual_rent = EXCLUDED.total_annual_rent,
    total_annual_opex_recovery = EXCLUDED.total_annual_opex_recovery,
    weighted_average_remaining_lease_term_years = EXCLUDED.weighted_average_remaining_lease_term_years,
    rollover_by_year = EXCLUDED.rollover_by_year,
    notes = EXCLUDED.notes;

WITH property AS (
    SELECT id FROM properties WHERE address = '2643-2751 S Loop 336 W, Conroe, TX 77304'
)
INSERT INTO financial_reports (
    property_id, rental_income, recoveries, gross_income, total_expenses,
    noi, cap_rate_pct, occupancy_pct, confidence, source_pdf, raw_json
)
SELECT id, 524450, 78125, 602575, 110000, 492575, 8.0, 100.0, 70,
       '9d5debbf-b7dd-4943-9e8d-e66df2b91f9b.pdf',
       '{"actual_cap_rate_pct":7.88,"price_per_sf":312.50,"implied_expenses_psf":5.50,"implied_expense_ratio_pct":18.3,"note":"OM gives NOI but does not provide a full T12 income and expense statement."}'::jsonb
FROM property
ON CONFLICT (property_id, source_pdf) DO UPDATE SET
    rental_income = EXCLUDED.rental_income,
    recoveries = EXCLUDED.recoveries,
    gross_income = EXCLUDED.gross_income,
    total_expenses = EXCLUDED.total_expenses,
    noi = EXCLUDED.noi,
    cap_rate_pct = EXCLUDED.cap_rate_pct,
    occupancy_pct = EXCLUDED.occupancy_pct,
    confidence = EXCLUDED.confidence,
    raw_json = EXCLUDED.raw_json;

WITH property AS (
    SELECT id FROM properties WHERE address = '2643-2751 S Loop 336 W, Conroe, TX 77304'
)
INSERT INTO analysis (
    property_id, due_diligence_score, seller_weakness_score, decision,
    strengths, red_flags, missing_items, weaknesses, due_diligence_notes,
    seller_weakness_notes, financing_assumptions, broker_questions,
    valuation_scenarios, summary
)
SELECT id, 35, 38, 'HOLD / REQUEST MORE INFO',
       '["100% occupied","New 2022 construction","20,000 SF across eight 2,500 SF suites","Tenant mix includes healthcare, bank, tax, homebuilder, energy, realty, chiropractor, and wellness users","Conroe growth story and nearby retail/master-planned development"]'::jsonb,
       '["Short WALT around 2.5 years","Two gross leases create owner expense exposure","Compassionate Care expires 2027 and pays the highest annual rent","Renewal option language may cap rent growth for Compassionate Care","No full T12 shown in OM","No lease abstracts or executed lease copies provided in OM"]'::jsonb,
       '["T12 operating statement","Current rent roll in Excel","Executed leases and amendments","Tax bills","Insurance quote or policy","CAM reconciliation history","Tenant payment ledger","Roof/HVAC/parking responsibility detail","Environmental, drainage, detention pond, and easement detail"]'::jsonb,
       '["Short WALT","Missing T12","Gross lease expense exposure","2027 lease expiration risk","No full lease copies","Small/local tenant profile mixed with stronger tenants"]'::jsonb,
       '["NOI is not fully proven from the OM alone because no T12 expense breakdown is included.","Verify actual 2025 and YTD 2026 taxes and insurance.","Confirm CAM and operating expense recoveries are reconciled annually.","Verify roof, HVAC, parking lot, landscaping, lake, walking path, and exterior maintenance obligations.","Review lease guarantees, default clauses, deposits, and payment history."]'::jsonb,
       '["No direct seller distress disclosed in the OM.","Negotiation leverage comes from short WALT, missing T12, two gross leases, near-term renewal risk, lack of full lease copies, and small/local tenant credit exposure."]'::jsonb,
       '{"ltv_pct":70,"loan_amount":4375000,"dscr_at_7_5_pct_25_year_amortization":1.27,"dscr_at_8_0_pct_25_year_amortization":1.22,"note":"Financing may be tight if lender requires about 1.25x DSCR and rates are near 8%."}'::jsonb,
       '["Please send the T12 operating statement.","Please send current rent roll in Excel.","Please send all executed leases and amendments.","Are all tenants current on rent?","Any late payments in the last 24 months?","Are any tenants requesting concessions or planning not to renew?","Has Compassionate Care indicated renewal intent?","Who is responsible for roof, HVAC, parking lot, landscaping, and exterior repairs?","What are actual 2025 and 2026 property taxes?","What is the current insurance premium?","Are CAM / opex recoveries reconciled annually?","Are the gross lease tenants paying any reimbursements at all?","Is there any debt on the property?","Why is the seller selling a newly built, fully occupied asset?","Any environmental, drainage, detention pond, or easement issues?","Are there tenant guarantees or personal guarantees?","Has the property ever had flooding or water intrusion?","Are any roofs, HVAC units, or parking areas under warranty?","Is the lake / walking path maintained by owner, HOA, or another party?","Can seller provide 2024, 2025, and YTD 2026 P&L?"]'::jsonb,
       '[{"cap_rate_pct":7.88,"value":6250000,"label":"asking price"},{"cap_rate_pct":8.0,"value":6157188},{"cap_rate_pct":8.5,"value":5795000},{"cap_rate_pct":9.0,"value":5473056},{"cap_rate_pct":9.5,"value":5185000}]'::jsonb,
       'Good-looking stabilized new-build asset, but not a buy-now decision from the OM alone. Request T12, lease copies, rent roll Excel, tax bill, insurance bill, CAM reconciliation, and payment ledger before serious LOI.'
FROM property
ON CONFLICT (property_id) DO UPDATE SET
    due_diligence_score = EXCLUDED.due_diligence_score,
    seller_weakness_score = EXCLUDED.seller_weakness_score,
    decision = EXCLUDED.decision,
    strengths = EXCLUDED.strengths,
    red_flags = EXCLUDED.red_flags,
    missing_items = EXCLUDED.missing_items,
    weaknesses = EXCLUDED.weaknesses,
    due_diligence_notes = EXCLUDED.due_diligence_notes,
    seller_weakness_notes = EXCLUDED.seller_weakness_notes,
    financing_assumptions = EXCLUDED.financing_assumptions,
    broker_questions = EXCLUDED.broker_questions,
    valuation_scenarios = EXCLUDED.valuation_scenarios,
    summary = EXCLUDED.summary;

WITH property AS (
    SELECT id FROM properties WHERE address = '2643-2751 S Loop 336 W, Conroe, TX 77304'
)
INSERT INTO due_diligence_items (property_id, category, item, status, priority, notes)
SELECT p.id, d.category, d.item, 'needed', d.priority, d.notes
FROM property p
CROSS JOIN (VALUES
    ('financials', 'T12 operating statement', 'high', 'Required to verify NOI and expense assumptions.'),
    ('financials', '2024, 2025, and YTD 2026 P&L', 'high', 'Needed to understand income and expense trend.'),
    ('rent_roll', 'Current rent roll in Excel', 'high', 'Needed to verify the OM rent roll and tenant fields.'),
    ('leases', 'All executed leases and amendments', 'high', 'Needed to verify lease obligations, options, defaults, guarantees, and expense responsibility.'),
    ('tenants', 'Tenant payment history / ledger', 'high', 'Needed to verify current rent, delinquencies, and late payments.'),
    ('tenants', 'Tenant renewal intent', 'medium', 'Especially important for Compassionate Care expiring 2027.'),
    ('expenses', 'Actual 2025 and 2026 property taxes', 'high', 'Needed to validate operating expenses.'),
    ('expenses', 'Current insurance premium', 'high', 'Needed to validate operating expenses.'),
    ('expenses', 'CAM reconciliation history', 'high', 'Needed to determine recovery quality and gross lease exposure.'),
    ('physical', 'Roof, HVAC, parking, landscaping, exterior repair responsibility', 'high', 'Needed to confirm owner expense exposure.'),
    ('physical', 'Warranty status for roof, HVAC units, and parking areas', 'medium', 'Newer construction may have warranty protections.'),
    ('site', 'Environmental, drainage, detention pond, and easement issues', 'medium', 'Needed to confirm site risk.'),
    ('site', 'Flooding or water intrusion history', 'medium', 'Needed to understand physical and insurance risk.'),
    ('operations', 'Lake and walking path maintenance responsibility', 'medium', 'Needed to determine owner/HOA/third-party obligations.'),
    ('seller', 'Reason for sale and debt status', 'medium', 'Needed to evaluate seller motivation.')
) AS d(category, item, priority, notes)
ON CONFLICT (property_id, category, item) DO UPDATE SET
    status = EXCLUDED.status,
    priority = EXCLUDED.priority,
    notes = EXCLUDED.notes;

WITH property AS (
    SELECT id FROM properties WHERE address = '2643-2751 S Loop 336 W, Conroe, TX 77304'
)
INSERT INTO seller_weakness_items (property_id, weakness, leverage_reason, severity, score_impact)
SELECT p.id, s.weakness, s.leverage_reason, s.severity, s.score_impact
FROM property p
CROSS JOIN (VALUES
    ('Short WALT', 'Buyer can argue rollover risk reduces value because most leases roll between 2027 and 2030.', 'high', 10),
    ('Missing T12', 'Buyer can argue the stated NOI is not proven until full operating statements are received.', 'high', 8),
    ('Two gross leases', 'Owner may carry more expense risk than under pure NNN leases.', 'medium', 6),
    ('2027 Compassionate Care expiration', 'Near-term expiration on the highest annual rent tenant creates renewal risk.', 'high', 8),
    ('Renewal option may cap upside', 'Compassionate Care option at lesser of market or current rent may limit rent growth.', 'medium', 4),
    ('No lease abstracts or full lease copies', 'Buyer cannot verify obligations, default clauses, guarantees, or maintenance responsibilities.', 'high', 7),
    ('Local tenant exposure', 'Several tenants appear local/small-business rather than national-credit tenants.', 'medium', 5)
) AS s(weakness, leverage_reason, severity, score_impact)
ON CONFLICT (property_id, weakness) DO UPDATE SET
    leverage_reason = EXCLUDED.leverage_reason,
    severity = EXCLUDED.severity,
    score_impact = EXCLUDED.score_impact;

WITH property AS (
    SELECT id FROM properties WHERE address = '2643-2751 S Loop 336 W, Conroe, TX 77304'
)
INSERT INTO valuation_scenarios (property_id, scenario_name, cap_rate_pct, noi, implied_value, notes)
SELECT p.id, v.scenario_name, v.cap_rate_pct, 492575, v.implied_value, v.notes
FROM property p
CROSS JOIN (VALUES
    ('Asking price / actual cap from OM numbers', 7.88, 6250000, 'Actual cap rate from stated NOI divided by asking price.'),
    ('8.00% cap', 8.00, 6157188, 'Value using stated NOI at 8.00% cap.'),
    ('8.50% cap', 8.50, 5795000, 'Value using stated NOI at 8.50% cap.'),
    ('9.00% cap', 9.00, 5473056, 'Value using stated NOI at 9.00% cap.'),
    ('9.50% cap', 9.50, 5185000, 'Value using stated NOI at 9.50% cap.')
) AS v(scenario_name, cap_rate_pct, implied_value, notes)
ON CONFLICT (property_id, scenario_name) DO UPDATE SET
    cap_rate_pct = EXCLUDED.cap_rate_pct,
    noi = EXCLUDED.noi,
    implied_value = EXCLUDED.implied_value,
    notes = EXCLUDED.notes;

WITH property AS (
    SELECT id FROM properties WHERE address = '2643-2751 S Loop 336 W, Conroe, TX 77304'
)
INSERT INTO broker_questions (property_id, question, category, priority)
SELECT p.id, q.question, q.category, q.priority
FROM property p
CROSS JOIN (VALUES
    ('Please send the T12 operating statement.', 'financials', 'high'),
    ('Please send current rent roll in Excel.', 'rent_roll', 'high'),
    ('Please send all executed leases and amendments.', 'leases', 'high'),
    ('Are all tenants current on rent?', 'tenants', 'high'),
    ('Any late payments in the last 24 months?', 'tenants', 'high'),
    ('Are any tenants requesting concessions or planning not to renew?', 'tenants', 'high'),
    ('Has Compassionate Care indicated renewal intent?', 'tenants', 'high'),
    ('Who is responsible for roof, HVAC, parking lot, landscaping, and exterior repairs?', 'physical', 'high'),
    ('What are actual 2025 and 2026 property taxes?', 'expenses', 'high'),
    ('What is the current insurance premium?', 'expenses', 'high'),
    ('Are CAM / opex recoveries reconciled annually?', 'expenses', 'high'),
    ('Are the gross lease tenants paying any reimbursements at all?', 'leases', 'medium'),
    ('Is there any debt on the property?', 'seller', 'medium'),
    ('Why is the seller selling a newly built, fully occupied asset?', 'seller', 'medium'),
    ('Any environmental, drainage, detention pond, or easement issues?', 'site', 'medium'),
    ('Are there tenant guarantees or personal guarantees?', 'leases', 'high'),
    ('Has the property ever had flooding or water intrusion?', 'site', 'medium'),
    ('Are any roofs, HVAC units, or parking areas under warranty?', 'physical', 'medium'),
    ('Is the lake / walking path maintained by owner, HOA, or another party?', 'operations', 'medium'),
    ('Can seller provide 2024, 2025, and YTD 2026 P&L?', 'financials', 'high')
) AS q(question, category, priority)
ON CONFLICT (property_id, question) DO UPDATE SET
    category = EXCLUDED.category,
    priority = EXCLUDED.priority;

COMMIT;
