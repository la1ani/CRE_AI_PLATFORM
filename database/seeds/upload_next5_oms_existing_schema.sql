-- Insert-only Supabase seed for five uploaded Crexi OM/flyer PDFs.
-- Built for the current live schema shared from Supabase Schema Visualizer.
-- This file does not delete or update existing rows.
--
-- Text property ids:
--   texas_car_title_payday_loan_houston_tx_2026
--   griggs_rd_shopping_center_houston_tx_2026
--   kuykendahl_plaza_spring_tx_2026
--   sablechase_plaza_houston_tx_2026
--   south_loop_center_houston_tx_2026
--
-- Numeric property ids used by bigint property_id tables:
--   821 FM 1960 - Texas Car Title & Payday Loan: -2315416
--   Griggs Rd Shopping Center: -1920767
--   Kuykendahl Plaza: -2625237
--   Sablechase Plaza: -2643096
--   South Loop Center: -2330984

BEGIN;

-- ---------------------------------------------------------------------------
-- 821 FM 1960 - Texas Car Title & Payday Loan
-- ---------------------------------------------------------------------------

INSERT INTO public.properties (
    property_id, property_name, address, property_type, asking_price, noi,
    cap_rate, occupancy, building_sf, land_sf, year_built, broker_name,
    broker_email, broker_phone, source_pdf, major_risks, missing_information,
    unit_count, opportunity_zone, value_add, extraction_confidence
)
SELECT
    $$texas_car_title_payday_loan_houston_tx_2026$$,
    $$821 FM 1960 - Texas Car Title & Payday Loan$$,
    $$821 FM 1960 W, Houston, TX 77090$$,
    $$Retail / Single-tenant net lease$$,
    $$$1,150,000$$,
    $$$85,877$$,
    $$7.47%$$,
    $$100%$$,
    $$4,700 SF$$,
    $$0.31 acres / approx. 13,504 SF$$,
    $$1978 / renovated 2015$$,
    $$John Baddour$$,
    NULL,
    $$281-303-6670$$,
    $$821 Fm 1960 - Texas Car Title & Payday Loan.pdf$$,
    $json$["Single-tenant exposure","Lease expires 01/31/2028 with only about 1.4 years remaining as of flyer date","1978 building; renovated 2015","Landlord responsible for roof and structure per marketing notes","Broker email not shown in readable flyer pages","Need to verify tenant credit, remaining options, and current lease status"]$json$::jsonb,
    $json$["Executed lease and all amendments","Current tenant estoppel","T12 operating statement","Roof/structure inspection and capital expenditure history","Insurance quote","Property tax bill","Environmental report","Tenant sales or payment history if available","Clarification of NN vs NNN language"]$json$::jsonb,
    1,
    NULL,
    false,
    80
WHERE NOT EXISTS (
    SELECT 1 FROM public.properties
    WHERE property_id = $$texas_car_title_payday_loan_houston_tx_2026$$
       OR address = $$821 FM 1960 W, Houston, TX 77090$$
);

INSERT INTO public.documents (property_id, file_name, file_type, drive_file_id, processed_at, status)
SELECT -2315416, $$821 Fm 1960 - Texas Car Title & Payday Loan.pdf$$, $$crexi_flyer_pdf$$, NULL, now(), $$processed$$
WHERE NOT EXISTS (
    SELECT 1 FROM public.documents
    WHERE property_id = -2315416 AND file_name = $$821 Fm 1960 - Texas Car Title & Payday Loan.pdf$$
);

INSERT INTO public.brokers (property_id, broker_name, broker_company, broker_email, broker_phone)
SELECT * FROM (VALUES
    (-2315416::bigint, $$John Baddour$$::text, $$ProspectCRE$$::text, NULL::text, $$281-303-6670$$::text)
) AS data(property_id, broker_name, broker_company, broker_email, broker_phone)
WHERE NOT EXISTS (
    SELECT 1 FROM public.brokers b
    WHERE b.property_id = data.property_id AND b.broker_name = data.broker_name
);

INSERT INTO public.financial_reports (
    property_id, rental_income, recoveries, gross_income, total_expenses,
    noi, cap_rate, occupancy, source_pdf, confidence, raw_json
)
SELECT
    $$texas_car_title_payday_loan_houston_tx_2026$$,
    $$Not separately provided; flyer provides NOI only$$,
    $$Not provided$$,
    $$Not provided$$,
    $$Not provided$$,
    $$$85,877$$,
    $$7.47%$$,
    $$100%$$,
    $$821 Fm 1960 - Texas Car Title & Payday Loan.pdf$$,
    78,
    $json${
      "asking_price": 1150000,
      "noi": 85877,
      "cap_rate_pct": 7.47,
      "price_per_sf": 244.68,
      "building_sf": 4700,
      "land_acres": 0.31,
      "occupancy_pct": 100,
      "lease_start": "2015-01-16",
      "lease_expiration": "2028-01-31",
      "remaining_term_years": 1.4,
      "lease_type": "NN",
      "investment_subtype": "NN",
      "tenant_credit": "Corporate Guarantee",
      "rent_bumps": "3% annually",
      "lease_options": 2,
      "parking_spaces": 10,
      "broker_coop": true,
      "ground_lease": false
    }$json$::jsonb
WHERE NOT EXISTS (
    SELECT 1 FROM public.financial_reports
    WHERE property_id = $$texas_car_title_payday_loan_houston_tx_2026$$
      AND source_pdf = $$821 Fm 1960 - Texas Car Title & Payday Loan.pdf$$
);

INSERT INTO public.rent_rolls (
    property_id, tenant_name, suite, sf, lease_start, lease_end,
    monthly_rent, annual_rent, rent_psf, lease_type, renewal_options, source_pdf
)
SELECT * FROM (VALUES
    ($$texas_car_title_payday_loan_houston_tx_2026$$, $$Texas Car Title & Payday Loans, Inc.$$::text, $$Single tenant$$::text, $$4,700$$::text, $$2015-01-16$$::text, $$2028-01-31$$::text, $$$7,156.42 implied from NOI$$::text, $$$85,877 NOI$$::text, $$$18.27 implied NOI/SF$$::text, $$NN; marketing notes also say NNN with landlord responsible for roof and structure$$::text, $$2 lease options; 3% annual rent bumps$$::text, $$821 Fm 1960 - Texas Car Title & Payday Loan.pdf$$::text)
) AS data(property_id, tenant_name, suite, sf, lease_start, lease_end, monthly_rent, annual_rent, rent_psf, lease_type, renewal_options, source_pdf)
WHERE NOT EXISTS (
    SELECT 1 FROM public.rent_rolls r
    WHERE r.property_id = data.property_id AND r.tenant_name = data.tenant_name AND r.suite = data.suite
);

INSERT INTO public.tenants (
    property_id, tenant, suite, monthly_rent, annual_rent,
    lease_start, lease_end, options, occupancy_status
)
SELECT * FROM (VALUES
    (-2315416::bigint, $$Texas Car Title & Payday Loans, Inc.$$::text, $$Single tenant$$::text, 7156.42::numeric, 85877::numeric, DATE $$2015-01-16$$, DATE $$2028-01-31$$, $$2 lease options; 3% annual rent bumps$$::text, $$Occupied$$::text)
) AS data(property_id, tenant, suite, monthly_rent, annual_rent, lease_start, lease_end, options, occupancy_status)
WHERE NOT EXISTS (
    SELECT 1 FROM public.tenants t
    WHERE t.property_id = data.property_id AND t.tenant = data.tenant AND t.suite = data.suite
);

INSERT INTO public.analysis (
    property_id, due_diligence_score, seller_weakness_score, acquisition_score,
    risk_score, upside_score, overall_score, recommendation, missing_items, weaknesses
)
SELECT
    -2315416, 72, 58, 70, 62, 54, 68,
    $$Pursue selectively after lease and roof/structure diligence.$$,
    $$Executed lease/amendments; estoppel; T12; roof and structure reports; tax bill; insurance quote; environmental report; tenant payment history.$$,
    $$Single-tenant risk, short remaining lease term to January 2028, older 1978 building, landlord roof/structure responsibility, no broker email in flyer.$$
WHERE NOT EXISTS (SELECT 1 FROM public.analysis WHERE property_id = -2315416);

INSERT INTO public.committee_reports (property_id, report)
SELECT
    $$texas_car_title_payday_loan_houston_tx_2026$$,
    $json${
      "property": "821 FM 1960 - Texas Car Title & Payday Loan",
      "summary": "Single-tenant retail net-lease flyer for a 4,700 SF building occupied by Texas Car Title & Payday Loans at 821 FM 1960 W, Houston, TX 77090.",
      "valuation": {"asking_price": "$1,150,000", "noi": "$85,877", "cap_rate": "7.47%", "price_per_sf": "$244.68"},
      "tenant_data": [{"tenant": "Texas Car Title & Payday Loans, Inc.", "sf": 4700, "lease_start": "2015-01-16", "lease_end": "2028-01-31", "lease_type": "NN", "rent_bumps": "3% annually", "options": "2"}],
      "due_diligence_notes": ["Confirm executed lease and remaining option terms.", "Verify NN vs NNN responsibility because flyer says landlord responsible for roof and structure.", "Review roof, structural, insurance, tax, and environmental backup."],
      "seller_weakness_items": ["Lease maturity in January 2028.", "Single tenant concentration.", "Older building with landlord retained structural obligations."],
      "broker_questions": ["Can you send the executed lease, amendments, and option language?", "Has the tenant delivered an estoppel?", "What is the roof age and condition?", "What are 2025/2026 taxes and insurance?", "Has tenant ever paid late or requested concessions?", "Is the lease NN or NNN for all expenses except roof and structure?"]
    }$json$::jsonb
WHERE NOT EXISTS (
    SELECT 1 FROM public.committee_reports
    WHERE property_id = $$texas_car_title_payday_loan_houston_tx_2026$$
);

INSERT INTO public.acquisition_decisions (property_id, decision)
SELECT
    $$texas_car_title_payday_loan_houston_tx_2026$$,
    $json${
      "recommendation": "Pursue selectively",
      "reason": "Attractive small-ticket cap rate, but short lease term and single-tenant exposure require lease, roof, and tenant-credit diligence.",
      "suggested_next_step": "Request lease package, estoppel, T12, tax bill, insurance quote, and roof/structure reports before LOI."
    }$json$::jsonb
WHERE NOT EXISTS (
    SELECT 1 FROM public.acquisition_decisions
    WHERE property_id = $$texas_car_title_payday_loan_houston_tx_2026$$
);

-- ---------------------------------------------------------------------------
-- Griggs Rd Shopping Center
-- ---------------------------------------------------------------------------

INSERT INTO public.properties (
    property_id, property_name, address, property_type, asking_price, noi,
    cap_rate, occupancy, building_sf, land_sf, year_built, broker_name,
    broker_email, broker_phone, source_pdf, major_risks, missing_information,
    unit_count, opportunity_zone, value_add, extraction_confidence
)
SELECT
    $$griggs_rd_shopping_center_houston_tx_2026$$,
    $$Griggs Rd Shopping Center$$,
    $$4429 Griggs Rd, Houston, TX 77021$$,
    $$Multi-tenant shopping center$$,
    $$$9,482,000$$,
    $$$687,479$$,
    $$7.25%$$,
    $$100%$$,
    $$52,976 SF$$,
    $$190,793 SF$$,
    $$1952 / remodeled 2002$$,
    $$Anita Amin$$,
    $$aa@theblueoxgroup.com$$,
    $$713-324-8954$$,
    $$Griggs Rd Shopping Center.pdf$$,
    $json$["Pro forma rent roll includes seller credit for difference between NOI at closing and pro forma NOI","Several 2026 lease expirations including Rent-A-Center, Family Dollar, and Eshallence Hair Design","Older 1952 property remodeled in 2002","Anchor concentration in Family Dollar, Rent-A-Center, Citi Trends, and Dedicated Senior Medical Center","Need lease abstracts, current rent roll, T12, CAM reconciliation, tax and insurance backup"]$json$::jsonb,
    $json$["Executed leases and amendments","Current actual rent roll vs pro forma rent roll","Tenant estoppels","T12 operating statement","CAM reconciliation","Property tax bill","Insurance quote and loss runs","Roof and parking lot condition","Environmental report","Seller credit mechanics at closing","Tenant sales/traffic support for anchors"]$json$::jsonb,
    10,
    NULL,
    true,
    94
WHERE NOT EXISTS (
    SELECT 1 FROM public.properties
    WHERE property_id = $$griggs_rd_shopping_center_houston_tx_2026$$
       OR address = $$4429 Griggs Rd, Houston, TX 77021$$
);

INSERT INTO public.documents (property_id, file_name, file_type, drive_file_id, processed_at, status)
SELECT -1920767, $$Griggs Rd Shopping Center.pdf$$, $$offering_memorandum_pdf$$, NULL, now(), $$processed$$
WHERE NOT EXISTS (
    SELECT 1 FROM public.documents
    WHERE property_id = -1920767 AND file_name = $$Griggs Rd Shopping Center.pdf$$
);

INSERT INTO public.brokers (property_id, broker_name, broker_company, broker_email, broker_phone)
SELECT * FROM (VALUES
    (-1920767::bigint, $$Anita Amin$$::text, $$Blue Ox Brokerage, LLC$$::text, $$aa@theblueoxgroup.com$$::text, $$713-324-8954$$::text)
) AS data(property_id, broker_name, broker_company, broker_email, broker_phone)
WHERE NOT EXISTS (
    SELECT 1 FROM public.brokers b
    WHERE b.property_id = data.property_id AND b.broker_email = data.broker_email
);

INSERT INTO public.financial_reports (
    property_id, rental_income, recoveries, other_income, gross_income,
    cam, insurance, taxes, management_fee, total_expenses, noi,
    cap_rate, occupancy, source_pdf, confidence, raw_json
)
SELECT
    $$griggs_rd_shopping_center_houston_tx_2026$$,
    $$$776,168$$,
    $$$370,936$$,
    $$$6,600$$,
    $$$1,153,704$$,
    $$$149,516$$,
    $$$66,717$$,
    $$$204,301$$,
    $$$45,691$$,
    $$$466,225$$,
    $$$687,479$$,
    $$7.25%$$,
    $$100%$$,
    $$Griggs Rd Shopping Center.pdf$$,
    92,
    $json${
      "asking_price": 9482000,
      "valuation_price": 9482472,
      "noi": 687479,
      "cap_rate_pct": 7.25,
      "price_per_sf": 179,
      "building_sf": 52976,
      "land_sf": 190793,
      "rental_income": 776168,
      "recoveries": 370936,
      "other_income": 6600,
      "total_income": 1153704,
      "cam": 149516,
      "insurance": 66717,
      "real_estate_taxes": 204301,
      "management_fee": 45691,
      "total_operating_expenses": 466225,
      "assumptions": ["Operating statement based on 2024 actual plus 3% inflation", "Management fee equals 4.00% of EGR", "Taxes per HCAD 2024 values at 2024 rates"]
    }$json$::jsonb
WHERE NOT EXISTS (
    SELECT 1 FROM public.financial_reports
    WHERE property_id = $$griggs_rd_shopping_center_houston_tx_2026$$
      AND source_pdf = $$Griggs Rd Shopping Center.pdf$$
);

INSERT INTO public.rent_rolls (
    property_id, tenant_name, suite, sf, lease_start, lease_end,
    monthly_rent, annual_rent, rent_psf, lease_type, renewal_options, source_pdf
)
SELECT * FROM (VALUES
    ($$griggs_rd_shopping_center_houston_tx_2026$$, $$US Vets$$::text, $$N/A$$::text, $$3,062$$::text, $$2023-12-01$$::text, $$2028-11-30$$::text, $$$10,656 gross$$::text, $$$127,871 gross$$::text, $$$32.96 base / $8.80 NNN PSF$$::text, $$NNN$$::text, $$No renewal option; rent increases to $33.95 PSF on 12/1/2025, $34.97 on 12/1/2026, and $36.02 on 12/1/2027; termination right if VA grant renewal is denied or reduced by more than 20%$$::text, $$Griggs Rd Shopping Center.pdf$$::text),
    ($$griggs_rd_shopping_center_houston_tx_2026$$, $$Rent-A-Center$$::text, $$N/A$$::text, $$4,975$$::text, $$2016-06-30$$::text, $$2026-06-30$$::text, $$$10,605 gross$$::text, $$$127,264 gross$$::text, $$$16.78 base / $8.80 NNN PSF$$::text, $$NNN$$::text, $$No renewal options remaining$$::text, $$Griggs Rd Shopping Center.pdf$$::text),
    ($$griggs_rd_shopping_center_houston_tx_2026$$, $$Dedicated Senior Medical Center$$::text, $$N/A$$::text, $$11,412$$::text, $$2021-11-15$$::text, $$2031-11-30$$::text, $$$20,752 gross$$::text, $$$249,029 gross$$::text, $$$13.02 base / $8.80 NNN PSF$$::text, $$NNN$$::text, $$Two 5-year options at market; annual 2% increases after 12/1/2025$$::text, $$Griggs Rd Shopping Center.pdf$$::text),
    ($$griggs_rd_shopping_center_houston_tx_2026$$, $$Family Dollar$$::text, $$N/A$$::text, $$9,415$$::text, $$2001-08-13$$::text, $$2026-12-31$$::text, $$$7,321 gross$$::text, $$$87,846 gross$$::text, $$$9.33 base / $0.00 NNN PSF$$::text, $$NNN with base-year reimbursement limits$$::text, $$No renewal options remaining$$::text, $$Griggs Rd Shopping Center.pdf$$::text),
    ($$griggs_rd_shopping_center_houston_tx_2026$$, $$Sirius Dental$$::text, $$N/A$$::text, $$2,480$$::text, $$2021-11-16$$::text, $$2031-11-30$$::text, $$$6,779 gross$$::text, $$$81,346 gross$$::text, $$$24.00 base / $8.80 NNN PSF$$::text, $$NNN$$::text, $$One 5-year at $29.04 PSF and one 5-year at $31.94 PSF; 12/1/2026 rent increases to $26.40 PSF$$::text, $$Griggs Rd Shopping Center.pdf$$::text),
    ($$griggs_rd_shopping_center_houston_tx_2026$$, $$Eshallence Hair Design$$::text, $$N/A$$::text, $$1,400$$::text, $$2010-08-02$$::text, $$2026-02-28$$::text, $$$3,138 gross$$::text, $$$37,660 gross$$::text, $$$18.21 base / $8.69 NNN PSF$$::text, $$NNN$$::text, $$No renewal options shown$$::text, $$Griggs Rd Shopping Center.pdf$$::text),
    ($$griggs_rd_shopping_center_houston_tx_2026$$, $$Citi Trends$$::text, $$N/A$$::text, $$14,226$$::text, $$2003-04-18$$::text, $$2030-03-31$$::text, $$$22,522 gross$$::text, $$$270,269 gross$$::text, $$$11.06 base / $7.94 NNN PSF$$::text, $$NNN$$::text, $$One 5-year at $12.17 PSF and one 5-year at $13.39 PSF$$::text, $$Griggs Rd Shopping Center.pdf$$::text),
    ($$griggs_rd_shopping_center_houston_tx_2026$$, $$Total Wireless$$::text, $$N/A$$::text, $$1,143$$::text, $$2025-10-01$$::text, $$2030-09-30$$::text, $$$2,743 gross$$::text, $$$32,919 gross$$::text, $$$20.00 base / $8.80 NNN PSF$$::text, $$NNN$$::text, $$Two 5-year options at market; 10/1/2026 rent increases to $20.50 PSF, then 2.5% annually$$::text, $$Griggs Rd Shopping Center.pdf$$::text),
    ($$griggs_rd_shopping_center_houston_tx_2026$$, $$H&R Block$$::text, $$N/A$$::text, $$1,650$$::text, $$2003-08-01$$::text, $$2028-04-30$$::text, $$$4,540 gross$$::text, $$$54,484 gross$$::text, $$$24.22 base / $8.80 NNN PSF$$::text, $$NNN$$::text, $$One 5-year option at $18.28 PSF plus 2% annual increases; rent abated 5/1/2027-5/31/2027$$::text, $$Griggs Rd Shopping Center.pdf$$::text),
    ($$griggs_rd_shopping_center_houston_tx_2026$$, $$SpinXpress$$::text, $$N/A$$::text, $$3,213$$::text, $$2023-05-17$$::text, $$2033-05-31$$::text, $$$6,535 gross$$::text, $$$78,419 gross$$::text, $$$15.61 base / $8.80 NNN PSF$$::text, $$NNN$$::text, $$One 5-year option at market; 6/1/2026 rent increases to $15.92 PSF then 2% annually$$::text, $$Griggs Rd Shopping Center.pdf$$::text)
) AS data(property_id, tenant_name, suite, sf, lease_start, lease_end, monthly_rent, annual_rent, rent_psf, lease_type, renewal_options, source_pdf)
WHERE NOT EXISTS (
    SELECT 1 FROM public.rent_rolls r
    WHERE r.property_id = data.property_id AND r.tenant_name = data.tenant_name AND r.source_pdf = data.source_pdf
);

INSERT INTO public.tenants (
    property_id, tenant, suite, monthly_rent, annual_rent,
    lease_start, lease_end, options, occupancy_status
)
SELECT * FROM (VALUES
    (-1920767::bigint, $$US Vets$$::text, $$N/A$$::text, 10656::numeric, 127871::numeric, DATE $$2023-12-01$$, DATE $$2028-11-30$$, $$No renewal option; termination right tied to VA grant denial/reduction$$::text, $$Occupied$$::text),
    (-1920767::bigint, $$Rent-A-Center$$::text, $$N/A$$::text, 10605::numeric, 127264::numeric, DATE $$2016-06-30$$, DATE $$2026-06-30$$, $$No renewal options remaining$$::text, $$Occupied$$::text),
    (-1920767::bigint, $$Dedicated Senior Medical Center$$::text, $$N/A$$::text, 20752::numeric, 249029::numeric, DATE $$2021-11-15$$, DATE $$2031-11-30$$, $$Two 5-year renewal options at market$$::text, $$Occupied$$::text),
    (-1920767::bigint, $$Family Dollar$$::text, $$N/A$$::text, 7321::numeric, 87846::numeric, DATE $$2001-08-13$$, DATE $$2026-12-31$$, $$No renewal options remaining$$::text, $$Occupied$$::text),
    (-1920767::bigint, $$Sirius Dental$$::text, $$N/A$$::text, 6779::numeric, 81346::numeric, DATE $$2021-11-16$$, DATE $$2031-11-30$$, $$Two 5-year renewal options at fixed rents$$::text, $$Occupied$$::text),
    (-1920767::bigint, $$Eshallence Hair Design$$::text, $$N/A$$::text, 3138::numeric, 37660::numeric, DATE $$2010-08-02$$, DATE $$2026-02-28$$, $$No renewal options shown$$::text, $$Occupied$$::text),
    (-1920767::bigint, $$Citi Trends$$::text, $$N/A$$::text, 22522::numeric, 270269::numeric, DATE $$2003-04-18$$, DATE $$2030-03-31$$, $$Two 5-year renewal options at fixed rents$$::text, $$Occupied$$::text),
    (-1920767::bigint, $$Total Wireless$$::text, $$N/A$$::text, 2743::numeric, 32919::numeric, DATE $$2025-10-01$$, DATE $$2030-09-30$$, $$Two 5-year renewal options at market$$::text, $$Occupied$$::text),
    (-1920767::bigint, $$H&R Block$$::text, $$N/A$$::text, 4540::numeric, 54484::numeric, DATE $$2003-08-01$$, DATE $$2028-04-30$$, $$One 5-year renewal option$$::text, $$Occupied$$::text),
    (-1920767::bigint, $$SpinXpress$$::text, $$N/A$$::text, 6535::numeric, 78419::numeric, DATE $$2023-05-17$$, DATE $$2033-05-31$$, $$One 5-year renewal option at market$$::text, $$Occupied$$::text)
) AS data(property_id, tenant, suite, monthly_rent, annual_rent, lease_start, lease_end, options, occupancy_status)
WHERE NOT EXISTS (
    SELECT 1 FROM public.tenants t
    WHERE t.property_id = data.property_id AND t.tenant = data.tenant
);

INSERT INTO public.analysis (
    property_id, due_diligence_score, seller_weakness_score, acquisition_score,
    risk_score, upside_score, overall_score, recommendation, missing_items, weaknesses
)
SELECT
    -1920767, 78, 63, 82, 58, 70, 78,
    $$Pursue after validating pro forma assumptions and 2026 rollover exposure.$$,
    $$Executed leases; current actual rent roll; T12; tenant estoppels; CAM reconciliation; tax/insurance backup; seller credit documentation; roof/parking reports.$$,
    $$Older construction, several 2026 expirations, pro forma credit dependency, anchor concentration, and need to verify 2024 actuals plus 3% inflation assumptions.$$
WHERE NOT EXISTS (SELECT 1 FROM public.analysis WHERE property_id = -1920767);

INSERT INTO public.committee_reports (property_id, report)
SELECT
    $$griggs_rd_shopping_center_houston_tx_2026$$,
    $json${
      "property": "Griggs Rd Shopping Center",
      "summary": "100% occupied 52,976 SF Houston shopping center anchored by Family Dollar, Rent-A-Center, Citi Trends, Dedicated Senior Medical Center, and SpinXpress.",
      "valuation": {"asking_price": "$9,482,000", "noi": "$687,479", "cap_rate": "7.25%", "price_per_sf": "$179"},
      "financials": {"rental_income": "$776,168", "recoveries": "$370,936", "other_income": "$6,600", "gross_income": "$1,153,704", "expenses": "$466,225"},
      "tenant_data": ["US Vets", "Rent-A-Center", "Dedicated Senior Medical Center", "Family Dollar", "Sirius Dental", "Eshallence Hair Design", "Citi Trends", "Total Wireless", "H&R Block", "SpinXpress"],
      "due_diligence_notes": ["Validate current actual rent roll against pro forma rent roll.", "Confirm seller credit for difference between NOI at closing and pro forma NOI.", "Review 2026 expirations and renewal probability.", "Confirm roof, parking lot, tax, insurance, and CAM obligations."],
      "seller_weakness_items": ["Rent-A-Center, Family Dollar, and Eshallence expirations in 2026.", "Older 1952 construction despite 2002 remodel.", "NOI relies on pro forma/seller credit mechanics."],
      "broker_questions": ["What is the actual in-place NOI at closing before seller credit?", "Can you send Excel rent roll, T12, and CAM reconciliation?", "Are any 2026 expiring tenants negotiating renewals?", "What capex has been completed since the 2002 remodel?", "Are there tenant sales reports or payment histories for anchors?", "How exactly will the seller credit be calculated and documented?"]
    }$json$::jsonb
WHERE NOT EXISTS (
    SELECT 1 FROM public.committee_reports
    WHERE property_id = $$griggs_rd_shopping_center_houston_tx_2026$$
);

INSERT INTO public.acquisition_decisions (property_id, decision)
SELECT
    $$griggs_rd_shopping_center_houston_tx_2026$$,
    $json${
      "recommendation": "Pursue",
      "reason": "Large, fully occupied neighborhood center with internet-resistant tenants and strong traffic, but rollover and pro forma/seller-credit assumptions need verification.",
      "suggested_next_step": "Request diligence package and underwrite downside case for 2026 tenant rollover before LOI."
    }$json$::jsonb
WHERE NOT EXISTS (
    SELECT 1 FROM public.acquisition_decisions
    WHERE property_id = $$griggs_rd_shopping_center_houston_tx_2026$$
);

-- ---------------------------------------------------------------------------
-- Kuykendahl Plaza
-- ---------------------------------------------------------------------------

INSERT INTO public.properties (
    property_id, property_name, address, property_type, asking_price, noi,
    cap_rate, occupancy, building_sf, land_sf, year_built, broker_name,
    broker_email, broker_phone, source_pdf, major_risks, missing_information,
    unit_count, opportunity_zone, value_add, extraction_confidence
)
SELECT
    $$kuykendahl_plaza_spring_tx_2026$$,
    $$Kuykendahl Plaza$$,
    $$17611 Kuykendahl Rd, Spring, TX 77379$$,
    $$Shopping center / multi-tenant retail$$,
    $$$2,545,000$$,
    $$$189,496$$,
    $$7.45%$$,
    $$100%$$,
    $$13,350 SF$$,
    $$1.106 acres / approx. 48,177 SF$$,
    $$1983$$,
    $$STRIVE team / Jennifer Pierson$$,
    $$JPierson@StriveRE.com$$,
    $$214-354-6820 / 469-844-8880$$,
    $$Kuykendahl Plaza.pdf$$,
    $json$["Small local tenant mix; tenant credit likely limited","Older 1983 construction","Several leases roll in 2026-2028","Some gross leases limit reimbursement capture","Need leases, T12, estoppels, CAM backup, and capex history"]$json$::jsonb,
    $json$["Executed leases and amendments","Current rent roll in Excel","T12 operating statement","Tenant payment history","CAM reconciliation","Roof/HVAC/parking condition reports","Tax bill and insurance quote","Environmental report","Tenant sales or business financials if available"]$json$::jsonb,
    6,
    NULL,
    true,
    92
WHERE NOT EXISTS (
    SELECT 1 FROM public.properties
    WHERE property_id = $$kuykendahl_plaza_spring_tx_2026$$
       OR address = $$17611 Kuykendahl Rd, Spring, TX 77379$$
);

INSERT INTO public.documents (property_id, file_name, file_type, drive_file_id, processed_at, status)
SELECT -2625237, $$Kuykendahl Plaza.pdf$$, $$offering_memorandum_pdf$$, NULL, now(), $$processed$$
WHERE NOT EXISTS (
    SELECT 1 FROM public.documents
    WHERE property_id = -2625237 AND file_name = $$Kuykendahl Plaza.pdf$$
);

INSERT INTO public.brokers (property_id, broker_name, broker_company, broker_email, broker_phone)
SELECT * FROM (VALUES
    (-2625237::bigint, $$Jennifer Pierson$$::text, $$STRIVE$$::text, $$JPierson@StriveRE.com$$::text, $$214-354-6820$$::text)
) AS data(property_id, broker_name, broker_company, broker_email, broker_phone)
WHERE NOT EXISTS (
    SELECT 1 FROM public.brokers b
    WHERE b.property_id = data.property_id AND b.broker_email = data.broker_email
);

INSERT INTO public.financial_reports (
    property_id, rental_income, recoveries, gross_income,
    cam, insurance, taxes, management_fee, total_expenses, noi,
    cap_rate, occupancy, source_pdf, confidence, raw_json
)
SELECT
    $$kuykendahl_plaza_spring_tx_2026$$,
    $$$203,088$$,
    $$$51,635$$,
    $$$254,723$$,
    $$$13,100$$,
    $$$18,129$$,
    $$$23,838$$,
    $$$10,160$$,
    $$$65,227$$,
    $$$189,496$$,
    $$7.45%$$,
    $$100%$$,
    $$Kuykendahl Plaza.pdf$$,
    91,
    $json${
      "asking_price": 2545000,
      "noi": 189496,
      "cap_rate_pct": 7.45,
      "price_per_sf": 191,
      "building_sf": 13350,
      "land_acres": 1.106,
      "base_rent_occupied_space": 203088,
      "gross_potential_rent": 203088,
      "expense_reimbursements": 51635,
      "gross_potential_income": 254723,
      "effective_gross_revenue": 254723,
      "taxes": 23838,
      "insurance": 18129,
      "cam": 13100,
      "management_fee": 10160,
      "total_expenses": 65227,
      "analysis_start_date": "2026-09-01"
    }$json$::jsonb
WHERE NOT EXISTS (
    SELECT 1 FROM public.financial_reports
    WHERE property_id = $$kuykendahl_plaza_spring_tx_2026$$
      AND source_pdf = $$Kuykendahl Plaza.pdf$$
);

INSERT INTO public.rent_rolls (
    property_id, tenant_name, suite, sf, lease_start, lease_end,
    monthly_rent, annual_rent, rent_psf, lease_type, renewal_options, source_pdf
)
SELECT * FROM (VALUES
    ($$kuykendahl_plaza_spring_tx_2026$$, $$Mr. G Tire Shop$$::text, $$A$$::text, $$3,300$$::text, $$2017-02-01$$::text, $$2028-12-31$$::text, $$$3,597.00$$::text, $$$43,164$$::text, $$$13.08$$::text, $$NNN$$::text, $$No options shown$$::text, $$Kuykendahl Plaza.pdf$$::text),
    ($$kuykendahl_plaza_spring_tx_2026$$, $$Harris Academic Club Tutoring$$::text, $$B/C/D$$::text, $$3,200$$::text, $$2025-06-01$$::text, $$2030-12-31$$::text, $$$4,308.00$$::text, $$$51,696$$::text, $$$16.16$$::text, $$NNN$$::text, $$1/1/2029 escalation to $52,800 / $16.50 PSF$$::text, $$Kuykendahl Plaza.pdf$$::text),
    ($$kuykendahl_plaza_spring_tx_2026$$, $$Djamila Braiding$$::text, $$E$$::text, $$1,200$$::text, $$2022-05-01$$::text, $$2026-12-31$$::text, $$$1,500.00$$::text, $$$18,000$$::text, $$$15.00$$::text, $$NNN$$::text, $$No options shown$$::text, $$Kuykendahl Plaza.pdf$$::text),
    ($$kuykendahl_plaza_spring_tx_2026$$, $$DA Taxes & Multiservices$$::text, $$F$$::text, $$950$$::text, $$2023-06-01$$::text, $$2028-12-31$$::text, $$$1,570.00$$::text, $$$18,840$$::text, $$$19.83$$::text, $$Gross$$::text, $$1 x 5-year option; 1/1/2027 escalation to $19,440 / $20.46 PSF$$::text, $$Kuykendahl Plaza.pdf$$::text),
    ($$kuykendahl_plaza_spring_tx_2026$$, $$C Print$$::text, $$G$$::text, $$1,100$$::text, $$2019-07-01$$::text, $$2028-06-30$$::text, $$$1,784.00$$::text, $$$21,408$$::text, $$$19.46$$::text, $$Gross$$::text, $$7/1/2027 escalation to $22,068 / $20.06 PSF$$::text, $$Kuykendahl Plaza.pdf$$::text),
    ($$kuykendahl_plaza_spring_tx_2026$$, $$City Balloons$$::text, $$H/I$$::text, $$3,600$$::text, $$2019-07-01$$::text, $$2028-06-30$$::text, $$$4,104.00$$::text, $$$49,248$$::text, $$$13.68$$::text, $$NNN$$::text, $$7/1/2027 escalation to $50,580 / $14.05 PSF$$::text, $$Kuykendahl Plaza.pdf$$::text)
) AS data(property_id, tenant_name, suite, sf, lease_start, lease_end, monthly_rent, annual_rent, rent_psf, lease_type, renewal_options, source_pdf)
WHERE NOT EXISTS (
    SELECT 1 FROM public.rent_rolls r
    WHERE r.property_id = data.property_id AND r.tenant_name = data.tenant_name AND r.suite = data.suite
);

INSERT INTO public.tenants (
    property_id, tenant, suite, monthly_rent, annual_rent,
    lease_start, lease_end, options, occupancy_status
)
SELECT * FROM (VALUES
    (-2625237::bigint, $$Mr. G Tire Shop$$::text, $$A$$::text, 3597::numeric, 43164::numeric, DATE $$2017-02-01$$, DATE $$2028-12-31$$, $$No options shown$$::text, $$Occupied$$::text),
    (-2625237::bigint, $$Harris Academic Club Tutoring$$::text, $$B/C/D$$::text, 4308::numeric, 51696::numeric, DATE $$2025-06-01$$, DATE $$2030-12-31$$, $$Escalation 1/1/2029$$::text, $$Occupied$$::text),
    (-2625237::bigint, $$Djamila Braiding$$::text, $$E$$::text, 1500::numeric, 18000::numeric, DATE $$2022-05-01$$, DATE $$2026-12-31$$, $$No options shown$$::text, $$Occupied$$::text),
    (-2625237::bigint, $$DA Taxes & Multiservices$$::text, $$F$$::text, 1570::numeric, 18840::numeric, DATE $$2023-06-01$$, DATE $$2028-12-31$$, $$1 x 5-year option$$::text, $$Occupied$$::text),
    (-2625237::bigint, $$C Print$$::text, $$G$$::text, 1784::numeric, 21408::numeric, DATE $$2019-07-01$$, DATE $$2028-06-30$$, $$Escalation 7/1/2027$$::text, $$Occupied$$::text),
    (-2625237::bigint, $$City Balloons$$::text, $$H/I$$::text, 4104::numeric, 49248::numeric, DATE $$2019-07-01$$, DATE $$2028-06-30$$, $$Escalation 7/1/2027$$::text, $$Occupied$$::text)
) AS data(property_id, tenant, suite, monthly_rent, annual_rent, lease_start, lease_end, options, occupancy_status)
WHERE NOT EXISTS (
    SELECT 1 FROM public.tenants t
    WHERE t.property_id = data.property_id AND t.tenant = data.tenant AND t.suite = data.suite
);

INSERT INTO public.analysis (
    property_id, due_diligence_score, seller_weakness_score, acquisition_score,
    risk_score, upside_score, overall_score, recommendation, missing_items, weaknesses
)
SELECT
    -2625237, 80, 55, 80, 50, 62, 79,
    $$Pursue after tenant-credit and physical-condition diligence.$$,
    $$Executed leases; T12; CAM reconciliation; estoppels; tenant payment history; roof/HVAC/parking reports; tax and insurance backup.$$,
    $$Small local tenants, older 1983 building, near-term 2026-2028 rollover, gross lease reimbursement leakage.$$
WHERE NOT EXISTS (SELECT 1 FROM public.analysis WHERE property_id = -2625237);

INSERT INTO public.committee_reports (property_id, report)
SELECT
    $$kuykendahl_plaza_spring_tx_2026$$,
    $json${
      "property": "Kuykendahl Plaza",
      "summary": "100% occupied 13,350 SF shopping center at 17611 Kuykendahl Rd in Spring, TX, offered at a 7.45% cap rate.",
      "valuation": {"asking_price": "$2,545,000", "noi": "$189,496", "cap_rate": "7.45%", "price_per_sf": "$191"},
      "financials": {"base_rent": "$203,088", "recoveries": "$51,635", "effective_gross_revenue": "$254,723", "expenses": "$65,227"},
      "tenant_data": ["Mr. G Tire Shop", "Harris Academic Club Tutoring", "Djamila Braiding", "DA Taxes & Multiservices", "C Print", "City Balloons"],
      "due_diligence_notes": ["Verify local tenant payment history and financial strength.", "Confirm gross lease reimbursement exposure.", "Review 2026-2028 lease rollover and renewal probabilities."],
      "seller_weakness_items": ["Older 1983 construction.", "Local tenant mix.", "Several leases roll within roughly two years of analysis date."],
      "broker_questions": ["Can you send lease files and amendments?", "Are taxes and insurance fully reimbursed by all NNN tenants?", "What capex has been completed recently?", "Do any tenants have late payment history?", "Are listed escalations already executed in signed leases?", "Can you provide T12 and CAM reconciliation?"]
    }$json$::jsonb
WHERE NOT EXISTS (
    SELECT 1 FROM public.committee_reports
    WHERE property_id = $$kuykendahl_plaza_spring_tx_2026$$
);

INSERT INTO public.acquisition_decisions (property_id, decision)
SELECT
    $$kuykendahl_plaza_spring_tx_2026$$,
    $json${
      "recommendation": "Pursue",
      "reason": "Fully occupied small-center profile with sustainable average rents, but tenant credit and older property condition need careful diligence.",
      "suggested_next_step": "Request leases, T12, CAM backup, estoppels, and recent capex/roof/HVAC reports."
    }$json$::jsonb
WHERE NOT EXISTS (
    SELECT 1 FROM public.acquisition_decisions
    WHERE property_id = $$kuykendahl_plaza_spring_tx_2026$$
);

-- ---------------------------------------------------------------------------
-- Sablechase Plaza
-- ---------------------------------------------------------------------------

INSERT INTO public.properties (
    property_id, property_name, address, property_type, asking_price, noi,
    cap_rate, occupancy, building_sf, land_sf, year_built, broker_name,
    broker_email, broker_phone, source_pdf, major_risks, missing_information,
    unit_count, opportunity_zone, value_add, extraction_confidence
)
SELECT
    $$sablechase_plaza_houston_tx_2026$$,
    $$Sablechase Plaza$$,
    $$13712 Walters Road, Houston, TX 77014$$,
    $$Multi-tenant retail center$$,
    $$$1,899,000$$,
    $$$142,887$$,
    $$7.52%$$,
    $$100%$$,
    $$12,980 SF$$,
    $$1.17 acres / approx. 50,965 SF$$,
    $$1984$$,
    $$Gus N. Lagos; Alex Wolansky$$,
    $$gus.lagos@marcusmillichap.com; alex.wolansky@marcusmillichap.com$$,
    $$713-452-4257; 713-452-4292$$,
    $$Sablechase Plaza.pdf$$,
    $json$["Underwriting includes rent increases that have not yet come into effect","Seller credit required for difference between advertised rent and current rent","Suite size discrepancy between landlord rent roll, actual measurements, and HCAD","Small tenant mix with local service tenants","Need executed leases, T12, CAM reconciliation, estoppels, and size verification"]$json$::jsonb,
    $json$["Executed leases and amendments","Current rent roll in Excel","T12 operating statement","CAM reconciliation","Tenant estoppels","Seller credit agreement","Survey or verified suite measurements","HCAD building size support","Tax bill","Insurance quote","Roof/HVAC/parking reports","Environmental report"]$json$::jsonb,
    6,
    NULL,
    true,
    94
WHERE NOT EXISTS (
    SELECT 1 FROM public.properties
    WHERE property_id = $$sablechase_plaza_houston_tx_2026$$
       OR address = $$13712 Walters Road, Houston, TX 77014$$
);

INSERT INTO public.documents (property_id, file_name, file_type, drive_file_id, processed_at, status)
SELECT -2643096, $$Sablechase Plaza.pdf$$, $$offering_memorandum_pdf$$, NULL, now(), $$processed$$
WHERE NOT EXISTS (
    SELECT 1 FROM public.documents
    WHERE property_id = -2643096 AND file_name = $$Sablechase Plaza.pdf$$
);

INSERT INTO public.brokers (property_id, broker_name, broker_company, broker_email, broker_phone)
SELECT * FROM (VALUES
    (-2643096::bigint, $$Gus N. Lagos$$::text, $$Marcus & Millichap$$::text, $$gus.lagos@marcusmillichap.com$$::text, $$713-452-4257$$::text),
    (-2643096::bigint, $$Alex Wolansky, CCIM$$::text, $$Marcus & Millichap$$::text, $$alex.wolansky@marcusmillichap.com$$::text, $$713-452-4292$$::text),
    (-2643096::bigint, $$Jamie Safier$$::text, $$Marcus & Millichap Capital Corporation$$::text, $$jamie.safier@marcusmillichap.com$$::text, $$713-239-0501$$::text),
    (-2643096::bigint, $$Thomas Monge$$::text, $$Marcus & Millichap Capital Corporation$$::text, $$thomas.monge@marcusmillichap.com$$::text, $$713-239-0515$$::text)
) AS data(property_id, broker_name, broker_company, broker_email, broker_phone)
WHERE NOT EXISTS (
    SELECT 1 FROM public.brokers b
    WHERE b.property_id = data.property_id AND b.broker_email = data.broker_email
);

INSERT INTO public.financial_reports (
    property_id, rental_income, recoveries, gross_income,
    taxes, insurance, cam, management_fee, total_expenses, noi,
    cap_rate, occupancy, source_pdf, confidence, raw_json
)
SELECT
    $$sablechase_plaza_houston_tx_2026$$,
    $$$142,887 scheduled base rental income$$,
    $$$72,967 total reimbursement income$$,
    $$$215,855 effective gross revenue$$,
    $$$36,927.77$$,
    $$$12,980.00$$,
    $$$14,425.51 other CAM/service line items$$,
    $$$8,634.20$$,
    $$$72,967.48$$,
    $$$142,887$$,
    $$7.52%$$,
    $$100%$$,
    $$Sablechase Plaza.pdf$$,
    92,
    $json${
      "asking_price": 1899000,
      "noi": 142887,
      "cap_rate_pct": 7.52,
      "price_per_sf": 146.30,
      "building_gla_sf": 12980,
      "land_acres": 1.17,
      "scheduled_base_rental_income": 142887,
      "total_reimbursement_income": 72967,
      "effective_gross_revenue": 215855,
      "taxes": 36927.77,
      "management_fee": 8634.20,
      "landscaping": 1496.40,
      "electrical_maintenance": 300,
      "waste_removal": 8134.09,
      "portering_service": 1983.10,
      "signage": 135.31,
      "water_and_sewer": 1938.38,
      "electricity_use": 438.23,
      "insurance": 12980,
      "total_expenses": 72967.48,
      "loan_terms": {"loan_amount": 1234350, "down_payment": 664650, "annual_debt_service": 102339, "ltv_pct": 65, "interest_rate_pct": 6.75, "term_years": 5, "amortization_years": 25},
      "returns": {"net_cash_flow_after_debt_service": 40548, "cash_on_cash_pct": 6.10, "total_return_pct": 9.05}
    }$json$::jsonb
WHERE NOT EXISTS (
    SELECT 1 FROM public.financial_reports
    WHERE property_id = $$sablechase_plaza_houston_tx_2026$$
      AND source_pdf = $$Sablechase Plaza.pdf$$
);

INSERT INTO public.rent_rolls (
    property_id, tenant_name, suite, sf, lease_start, lease_end,
    monthly_rent, annual_rent, rent_psf, lease_type, renewal_options, source_pdf
)
SELECT * FROM (VALUES
    ($$sablechase_plaza_houston_tx_2026$$, $$Daycare$$::text, $$110$$::text, $$5,986 landlord / 5,986 actual$$::text, $$2025-01-01$$::text, $$2031-05-31$$::text, $$$4,075.67 current$$::text, $$$48,908.04 current$$::text, NULL::text, $$NNN$$::text, $$Rent increases to $54,908.04 on 6/1/2026, $60,908.04 on 6/1/2028, and $66,908.04 on 6/1/2030; seller credit for advertised/current rent difference$$::text, $$Sablechase Plaza.pdf$$::text),
    ($$sablechase_plaza_houston_tx_2026$$, $$Hair Salon$$::text, $$120$$::text, $$938 landlord / 980 actual$$::text, $$2026-04-01$$::text, $$2029-06-30$$::text, $$Abated until 6/30/2026; $1,120.11 from 7/1/2026$$::text, $$$13,441.32 from 7/1/2026$$::text, NULL::text, $$NNN$$::text, $$Initial abatement through 6/30/2026$$::text, $$Sablechase Plaza.pdf$$::text),
    ($$sablechase_plaza_houston_tx_2026$$, $$Lone Star Sausage$$::text, $$130 & 140$$::text, $$2,938 landlord / 2,170 actual$$::text, $$2019-08-01$$::text, $$2028-08-31$$::text, $$$2,310.00 current$$::text, $$$27,720.00 current$$::text, NULL::text, $$NNN$$::text, $$Rent increases to $31,320 on 9/1/2026 and $34,920 on 9/1/2027$$::text, $$Sablechase Plaza.pdf$$::text),
    ($$sablechase_plaza_houston_tx_2026$$, $$Smoke Shop$$::text, $$150$$::text, $$1,400 landlord / 1,400 actual$$::text, $$2026-07-01$$::text, $$2029-09-30$$::text, $$Abated until 9/30/2026; $1,260.84 from 10/1/2026$$::text, $$$15,130.08 from 10/1/2026$$::text, NULL::text, $$NNN$$::text, $$Initial abatement through 9/30/2026$$::text, $$Sablechase Plaza.pdf$$::text),
    ($$sablechase_plaza_houston_tx_2026$$, $$Orozco Tire Service$$::text, $$160$$::text, $$2,444 landlord / 2,444 actual$$::text, $$2023-05-01$$::text, $$2028-07-31$$::text, $$$1,874.00$$::text, $$$22,488.00$$::text, NULL::text, $$NNN$$::text, $$No options shown$$::text, $$Sablechase Plaza.pdf$$::text),
    ($$sablechase_plaza_houston_tx_2026$$, $$HW Fireworks$$::text, $$PAD$$::text, $$Pad tenant$$::text, $$2024-12-18$$::text, $$2029-01-04$$::text, $$$466.67$$::text, $$$5,600.00$$::text, NULL::text, $$Gross$$::text, $$Tenant pays $2,800 bi-annually$$::text, $$Sablechase Plaza.pdf$$::text)
) AS data(property_id, tenant_name, suite, sf, lease_start, lease_end, monthly_rent, annual_rent, rent_psf, lease_type, renewal_options, source_pdf)
WHERE NOT EXISTS (
    SELECT 1 FROM public.rent_rolls r
    WHERE r.property_id = data.property_id AND r.tenant_name = data.tenant_name AND r.suite = data.suite
);

INSERT INTO public.tenants (
    property_id, tenant, suite, monthly_rent, annual_rent,
    lease_start, lease_end, options, occupancy_status
)
SELECT * FROM (VALUES
    (-2643096::bigint, $$Daycare$$::text, $$110$$::text, 4075.67::numeric, 48908.04::numeric, DATE $$2025-01-01$$, DATE $$2031-05-31$$, $$Rent increases through 2031$$::text, $$Occupied$$::text),
    (-2643096::bigint, $$Hair Salon$$::text, $$120$$::text, 1120.11::numeric, 13441.32::numeric, DATE $$2026-04-01$$, DATE $$2029-06-30$$, $$Rent abated until 6/30/2026$$::text, $$Occupied / rent abatement$$::text),
    (-2643096::bigint, $$Lone Star Sausage$$::text, $$130 & 140$$::text, 2310::numeric, 27720::numeric, DATE $$2019-08-01$$, DATE $$2028-08-31$$, $$Rent increases in 2026 and 2027$$::text, $$Occupied$$::text),
    (-2643096::bigint, $$Smoke Shop$$::text, $$150$$::text, 1260.84::numeric, 15130.08::numeric, DATE $$2026-07-01$$, DATE $$2029-09-30$$, $$Rent abated until 9/30/2026$$::text, $$Occupied / rent abatement$$::text),
    (-2643096::bigint, $$Orozco Tire Service$$::text, $$160$$::text, 1874::numeric, 22488::numeric, DATE $$2023-05-01$$, DATE $$2028-07-31$$, $$No options shown$$::text, $$Occupied$$::text),
    (-2643096::bigint, $$HW Fireworks$$::text, $$PAD$$::text, 466.67::numeric, 5600::numeric, DATE $$2024-12-18$$, DATE $$2029-01-04$$, $$Pays $2,800 bi-annually$$::text, $$Occupied$$::text)
) AS data(property_id, tenant, suite, monthly_rent, annual_rent, lease_start, lease_end, options, occupancy_status)
WHERE NOT EXISTS (
    SELECT 1 FROM public.tenants t
    WHERE t.property_id = data.property_id AND t.tenant = data.tenant AND t.suite = data.suite
);

INSERT INTO public.analysis (
    property_id, due_diligence_score, seller_weakness_score, acquisition_score,
    risk_score, upside_score, overall_score, recommendation, missing_items, weaknesses
)
SELECT
    -2643096, 76, 66, 78, 60, 68, 76,
    $$Pursue after confirming rent-credit, rent-abatement, and suite-size issues.$$,
    $$Executed leases; current rent roll; T12; CAM reconciliation; estoppels; seller credit agreement; size verification; HCAD support; tax/insurance backup; roof/HVAC reports.$$,
    $$Underwritten rent increases not yet effective, rent abatements, seller credit dependency, suite-size discrepancy, small local tenant mix.$$
WHERE NOT EXISTS (SELECT 1 FROM public.analysis WHERE property_id = -2643096);

INSERT INTO public.committee_reports (property_id, report)
SELECT
    $$sablechase_plaza_houston_tx_2026$$,
    $json${
      "property": "Sablechase Plaza",
      "summary": "100% occupied 12,980 SF service-based retail center at a signalized corner in Houston, offered at $1.899M and 7.52% cap.",
      "valuation": {"asking_price": "$1,899,000", "noi": "$142,887", "cap_rate": "7.52%", "price_per_sf": "$146.30"},
      "financials": {"scheduled_base_rent": "$142,887", "reimbursement_income": "$72,967", "effective_gross_revenue": "$215,855", "expenses": "$72,967.48"},
      "tenant_data": ["Daycare", "Hair Salon", "Lone Star Sausage", "Smoke Shop", "Orozco Tire Service", "HW Fireworks"],
      "due_diligence_notes": ["Underwriting uses future rent increases and seller credit at closing.", "Two tenants show initial abatements.", "Suite size notes require verification because rent roll, actual size, and HCAD differ."],
      "seller_weakness_items": ["Advertised NOI may exceed current rent due to future increases.", "Seller credit required.", "Potential square footage discrepancy."],
      "broker_questions": ["How much seller credit is required at closing?", "Which rent figures are actually in-place today?", "Can you provide lease files, amendments, and estoppels?", "Can you provide survey/measurement backup for suite sizes?", "Are abatements fully documented?", "Can you provide T12, CAM reconciliation, tax bill, and insurance quote?"]
    }$json$::jsonb
WHERE NOT EXISTS (
    SELECT 1 FROM public.committee_reports
    WHERE property_id = $$sablechase_plaza_houston_tx_2026$$
);

INSERT INTO public.acquisition_decisions (property_id, decision)
SELECT
    $$sablechase_plaza_houston_tx_2026$$,
    $json${
      "recommendation": "Pursue with conditions",
      "reason": "The price and cap rate are attractive, but advertised NOI depends on future rent increases/seller credit and there are suite-size discrepancies.",
      "suggested_next_step": "Request current actual rent roll, seller-credit calculation, leases, estoppels, and size-verification documents before LOI."
    }$json$::jsonb
WHERE NOT EXISTS (
    SELECT 1 FROM public.acquisition_decisions
    WHERE property_id = $$sablechase_plaza_houston_tx_2026$$
);

-- ---------------------------------------------------------------------------
-- South Loop Center
-- ---------------------------------------------------------------------------

INSERT INTO public.properties (
    property_id, property_name, address, property_type, asking_price, noi,
    cap_rate, occupancy, building_sf, land_sf, year_built, broker_name,
    broker_email, broker_phone, source_pdf, major_risks, missing_information,
    unit_count, opportunity_zone, value_add, extraction_confidence
)
SELECT
    $$south_loop_center_houston_tx_2026$$,
    $$South Loop Center$$,
    $$3260 S. Loop W., Houston, TX 77025$$,
    $$Retail center$$,
    $$$11,000,000$$,
    $$$781,369.56$$,
    $$7.10%$$,
    $$89%$$,
    $$34,141 SF$$,
    $$106,966 SF$$,
    $$Renovated 2024; original year not provided$$,
    $$Todd Carlson$$,
    $$todd@hpiproperties.com$$,
    $$713-623-6944$$,
    $$South Loop Center.pdf$$,
    $json$["Only flyer-level financial data provided; no rent roll in extracted flyer","89% occupancy leaves vacancy/lease-up risk","Asking price is high relative to flyer data without tenant schedule","Need T12, rent roll, lease abstracts, CAM reconciliation, and capex backup","Recent 2024 renovation and 20-year TPO roof should be verified"]$json$::jsonb,
    $json$["Rent roll","Executed leases and amendments","T12 operating statement","Tenant payment history","CAM reconciliation","Vacancy details and lease-up assumptions","Roof warranty for 2024 TPO roof","Renovation invoices and permits","Property tax bill","Insurance quote","Environmental report","Survey/site plan"]$json$::jsonb,
    NULL,
    NULL,
    true,
    85
WHERE NOT EXISTS (
    SELECT 1 FROM public.properties
    WHERE property_id = $$south_loop_center_houston_tx_2026$$
       OR address = $$3260 S. Loop W., Houston, TX 77025$$
);

INSERT INTO public.documents (property_id, file_name, file_type, drive_file_id, processed_at, status)
SELECT -2330984, $$South Loop Center.pdf$$, $$crexi_flyer_pdf$$, NULL, now(), $$processed$$
WHERE NOT EXISTS (
    SELECT 1 FROM public.documents
    WHERE property_id = -2330984 AND file_name = $$South Loop Center.pdf$$
);

INSERT INTO public.brokers (property_id, broker_name, broker_company, broker_email, broker_phone)
SELECT * FROM (VALUES
    (-2330984::bigint, $$Todd Carlson$$::text, $$Hunington Properties, Inc.$$::text, $$todd@hpiproperties.com$$::text, $$713-623-6944$$::text)
) AS data(property_id, broker_name, broker_company, broker_email, broker_phone)
WHERE NOT EXISTS (
    SELECT 1 FROM public.brokers b
    WHERE b.property_id = data.property_id AND b.broker_email = data.broker_email
);

INSERT INTO public.financial_reports (
    property_id, rental_income, recoveries, gross_income, total_expenses,
    noi, cap_rate, occupancy, source_pdf, confidence, raw_json
)
SELECT
    $$south_loop_center_houston_tx_2026$$,
    $$Not provided in flyer$$,
    $$Not provided in flyer$$,
    $$Not provided in flyer$$,
    $$Not provided in flyer$$,
    $$$781,369.56$$,
    $$7.10%$$,
    $$89%$$,
    $$South Loop Center.pdf$$,
    82,
    $json${
      "asking_price": 11000000,
      "noi": 781369.56,
      "cap_rate_pct": 7.10,
      "building_sf": 34141,
      "lot_sf": 106966,
      "occupancy_pct": 89,
      "year_renovated": 2024,
      "property_highlights": ["Newly renovated exterior", "New 20-year TPO roof installed in 2024", "Freeway signalized intersection", "Proximity to Reliant Park"],
      "traffic_counts": {"south_main_vpd": 53238, "south_loop_vpd": 192701},
      "demographics": {"population_2_mile": 60867, "population_3_mile": 128751, "population_5_mile": 449443, "avg_household_income_2_mile": 104873, "avg_household_income_3_mile": 130490, "avg_household_income_5_mile": 102889}
    }$json$::jsonb
WHERE NOT EXISTS (
    SELECT 1 FROM public.financial_reports
    WHERE property_id = $$south_loop_center_houston_tx_2026$$
      AND source_pdf = $$South Loop Center.pdf$$
);

INSERT INTO public.analysis (
    property_id, due_diligence_score, seller_weakness_score, acquisition_score,
    risk_score, upside_score, overall_score, recommendation, missing_items, weaknesses
)
SELECT
    -2330984, 65, 72, 73, 66, 75, 72,
    $$Request full diligence before pursuing; flyer has too little tenant-level detail.$$,
    $$Rent roll; leases; T12; CAM reconciliation; vacancy schedule; lease-up plan; roof warranty; renovation invoices; tax bill; insurance quote; environmental report.$$,
    $$89% occupancy, no rent roll in flyer, no detailed income/expense breakdown, dependence on verifying recent renovation and roof work.$$
WHERE NOT EXISTS (SELECT 1 FROM public.analysis WHERE property_id = -2330984);

INSERT INTO public.committee_reports (property_id, report)
SELECT
    $$south_loop_center_houston_tx_2026$$,
    $json${
      "property": "South Loop Center",
      "summary": "34,141 SF Houston retail center at 3260 S. Loop W. offered at $11.0M with 89% occupancy and 7.10% cap rate per flyer.",
      "valuation": {"asking_price": "$11,000,000", "noi": "$781,369.56", "cap_rate": "7.10%", "building_size": "34,141 SF"},
      "financials": {"detailed_income_expense": "Not provided in flyer", "occupancy": "89%"},
      "tenant_data": "No tenant rent roll provided in extracted flyer.",
      "due_diligence_notes": ["Request rent roll and T12 before underwriting.", "Verify 2024 exterior renovation and new 20-year TPO roof.", "Understand vacant space and lease-up plan behind 89% occupancy."],
      "seller_weakness_items": ["Vacancy exists at 89% occupancy.", "Flyer lacks detailed rent roll and expense backup.", "Buyer can press for full diligence before pricing."],
      "broker_questions": ["Please send rent roll, leases, and T12.", "Which suites are vacant and what are market rent assumptions?", "Can you provide roof warranty and renovation invoices?", "What are current taxes, insurance, and CAM recoveries?", "Are any tenants on month-to-month leases or near expiration?", "What capital items remain after the 2024 renovation?"]
    }$json$::jsonb
WHERE NOT EXISTS (
    SELECT 1 FROM public.committee_reports
    WHERE property_id = $$south_loop_center_houston_tx_2026$$
);

INSERT INTO public.acquisition_decisions (property_id, decision)
SELECT
    $$south_loop_center_houston_tx_2026$$,
    $json${
      "recommendation": "Request more information",
      "reason": "The flyer has attractive traffic/location and potential upside from 89% occupancy, but tenant-level income and expense detail is missing.",
      "suggested_next_step": "Do not underwrite final offer until broker provides rent roll, leases, T12, vacancy schedule, and roof/renovation backup."
    }$json$::jsonb
WHERE NOT EXISTS (
    SELECT 1 FROM public.acquisition_decisions
    WHERE property_id = $$south_loop_center_houston_tx_2026$$
);

COMMIT;
