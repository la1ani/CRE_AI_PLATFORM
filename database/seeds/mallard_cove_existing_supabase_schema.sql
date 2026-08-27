-- Mallard Cove seed matching the current live Supabase schema copied from Schema Visualizer.
-- This version is safe for live use: it updates matching Mallard Cove rows or
-- inserts them if missing. It does not delete existing rows.

BEGIN;

-- Current live schema uses text property_id in some tables and bigint
-- property_id in others. These stable ids keep the deal grouped in both sets.
-- Text id: mallard_cove_conroe_tx_2026
-- Numeric id: 1001

WITH data AS (
    SELECT
        'mallard_cove_conroe_tx_2026'::text AS property_id,
        'Mallard Cove Professional Building'::text AS property_name,
        '2643-2751 S Loop 336 W, Conroe, TX 77304'::text AS address,
        'Class A multi-tenant retail/office park'::text AS property_type,
        '$6,250,000'::text AS asking_price,
        '$492,575'::text AS noi,
        '8.0%'::text AS cap_rate,
        '100.0%'::text AS occupancy,
        '20,000 SF'::text AS building_sf,
        '4.167 acres / approx. 181,515 SF'::text AS land_sf,
        '2022'::text AS year_built,
        'Linda Crumley; Brigham Hedges'::text AS broker_name,
        'linda.crumley@svn.com; brigham.hedges@svn.com'::text AS broker_email,
        '281-367-2220 ext 119; 281-367-2220 ext 143'::text AS broker_phone,
        '9d5debbf-b7dd-4943-9e8d-e66df2b91f9b.pdf'::text AS source_pdf,
        '["Short WALT around 2.5 years","Two gross leases create owner expense exposure","Compassionate Care expires 2027 and pays the highest annual rent","Compassionate Care renewal option may cap rent growth","No full T12 shown in OM","No lease abstracts or executed lease copies included in OM","Several tenants appear local or small-business rather than national-credit tenants"]'::jsonb AS major_risks,
        '["T12 operating statement","Current rent roll in Excel","Executed leases and amendments","Tax bills","Insurance quote or policy","CAM reconciliation history","Tenant payment ledger","Roof/HVAC/parking responsibility detail","Environmental, drainage, detention pond, and easement detail","Reason for sale and debt status"]'::jsonb AS missing_information,
        8::integer AS unit_count,
        false::boolean AS value_add,
        95::integer AS extraction_confidence
)
UPDATE public.properties p
SET property_name = d.property_name,
    address = d.address,
    property_type = d.property_type,
    asking_price = d.asking_price,
    noi = d.noi,
    cap_rate = d.cap_rate,
    occupancy = d.occupancy,
    building_sf = d.building_sf,
    land_sf = d.land_sf,
    year_built = d.year_built,
    broker_name = d.broker_name,
    broker_email = d.broker_email,
    broker_phone = d.broker_phone,
    source_pdf = d.source_pdf,
    major_risks = d.major_risks,
    missing_information = d.missing_information,
    unit_count = d.unit_count,
    value_add = d.value_add,
    extraction_confidence = d.extraction_confidence
FROM data d
WHERE p.property_id = d.property_id OR p.address = d.address;

WITH data AS (
    SELECT
        'mallard_cove_conroe_tx_2026'::text AS property_id,
        'Mallard Cove Professional Building'::text AS property_name,
        '2643-2751 S Loop 336 W, Conroe, TX 77304'::text AS address,
        'Class A multi-tenant retail/office park'::text AS property_type,
        '$6,250,000'::text AS asking_price,
        '$492,575'::text AS noi,
        '8.0%'::text AS cap_rate,
        '100.0%'::text AS occupancy,
        '20,000 SF'::text AS building_sf,
        '4.167 acres / approx. 181,515 SF'::text AS land_sf,
        '2022'::text AS year_built,
        'Linda Crumley; Brigham Hedges'::text AS broker_name,
        'linda.crumley@svn.com; brigham.hedges@svn.com'::text AS broker_email,
        '281-367-2220 ext 119; 281-367-2220 ext 143'::text AS broker_phone,
        '9d5debbf-b7dd-4943-9e8d-e66df2b91f9b.pdf'::text AS source_pdf,
        '["Short WALT around 2.5 years","Two gross leases create owner expense exposure","Compassionate Care expires 2027 and pays the highest annual rent","Compassionate Care renewal option may cap rent growth","No full T12 shown in OM","No lease abstracts or executed lease copies included in OM","Several tenants appear local or small-business rather than national-credit tenants"]'::jsonb AS major_risks,
        '["T12 operating statement","Current rent roll in Excel","Executed leases and amendments","Tax bills","Insurance quote or policy","CAM reconciliation history","Tenant payment ledger","Roof/HVAC/parking responsibility detail","Environmental, drainage, detention pond, and easement detail","Reason for sale and debt status"]'::jsonb AS missing_information,
        8::integer AS unit_count,
        false::boolean AS value_add,
        95::integer AS extraction_confidence
)
INSERT INTO public.properties (
    property_id, property_name, address, property_type, asking_price, noi,
    cap_rate, occupancy, building_sf, land_sf, year_built, broker_name,
    broker_email, broker_phone, source_pdf, major_risks, missing_information,
    unit_count, value_add, extraction_confidence
)
SELECT property_id, property_name, address, property_type, asking_price, noi,
       cap_rate, occupancy, building_sf, land_sf, year_built, broker_name,
       broker_email, broker_phone, source_pdf, major_risks, missing_information,
       unit_count, value_add, extraction_confidence
FROM data d
WHERE NOT EXISTS (
    SELECT 1 FROM public.properties p
    WHERE p.property_id = d.property_id OR p.address = d.address
);

WITH data AS (
    SELECT * FROM (VALUES
        (1001::bigint, '9d5debbf-b7dd-4943-9e8d-e66df2b91f9b.pdf'::text, 'offering_memorandum_pdf'::text, NULL::text, now()::timestamp, 'processed'::text)
    ) AS v(property_id, file_name, file_type, drive_file_id, processed_at, status)
)
UPDATE public.documents d
SET file_type = data.file_type,
    drive_file_id = data.drive_file_id,
    processed_at = data.processed_at,
    status = data.status
FROM data
WHERE d.property_id = data.property_id AND d.file_name = data.file_name;

WITH data AS (
    SELECT * FROM (VALUES
        (1001::bigint, '9d5debbf-b7dd-4943-9e8d-e66df2b91f9b.pdf'::text, 'offering_memorandum_pdf'::text, NULL::text, now()::timestamp, 'processed'::text)
    ) AS v(property_id, file_name, file_type, drive_file_id, processed_at, status)
)
INSERT INTO public.documents (property_id, file_name, file_type, drive_file_id, processed_at, status)
SELECT property_id, file_name, file_type, drive_file_id, processed_at, status
FROM data
WHERE NOT EXISTS (
    SELECT 1 FROM public.documents d
    WHERE d.property_id = data.property_id AND d.file_name = data.file_name
);

WITH data AS (
    SELECT * FROM (VALUES
        (1001::bigint, 'Linda Crumley'::text, 'SVN | J. Beard Real Estate'::text, 'linda.crumley@svn.com'::text, '281-367-2220 ext 119'::text),
        (1001::bigint, 'Brigham Hedges'::text, 'SVN | J. Beard Real Estate'::text, 'brigham.hedges@svn.com'::text, '281-367-2220 ext 143'::text)
    ) AS v(property_id, broker_name, broker_company, broker_email, broker_phone)
)
UPDATE public.brokers b
SET broker_name = data.broker_name,
    broker_company = data.broker_company,
    broker_phone = data.broker_phone
FROM data
WHERE b.property_id = data.property_id AND b.broker_email = data.broker_email;

WITH data AS (
    SELECT * FROM (VALUES
        (1001::bigint, 'Linda Crumley'::text, 'SVN | J. Beard Real Estate'::text, 'linda.crumley@svn.com'::text, '281-367-2220 ext 119'::text),
        (1001::bigint, 'Brigham Hedges'::text, 'SVN | J. Beard Real Estate'::text, 'brigham.hedges@svn.com'::text, '281-367-2220 ext 143'::text)
    ) AS v(property_id, broker_name, broker_company, broker_email, broker_phone)
)
INSERT INTO public.brokers (property_id, broker_name, broker_company, broker_email, broker_phone)
SELECT property_id, broker_name, broker_company, broker_email, broker_phone
FROM data
WHERE NOT EXISTS (
    SELECT 1 FROM public.brokers b
    WHERE b.property_id = data.property_id AND b.broker_email = data.broker_email
);

WITH data AS (
    SELECT
        'mallard_cove_conroe_tx_2026'::text AS property_id,
        '$524,450'::text AS rental_income,
        '$78,125'::text AS recoveries,
        '$602,575'::text AS gross_income,
        '$110,000 implied from OM numbers'::text AS total_expenses,
        '$492,575'::text AS noi,
        '8.0% stated / 7.88% actual from NOI and price'::text AS cap_rate,
        '100.0%'::text AS occupancy,
        '9d5debbf-b7dd-4943-9e8d-e66df2b91f9b.pdf'::text AS source_pdf,
        70::integer AS confidence,
        '{"asking_price":6250000,"noi":492575,"stated_cap_rate_pct":8.0,"actual_cap_rate_pct":7.88,"price_per_sf":312.50,"annual_base_rent":524450,"annual_opex_recovery":78125,"gross_income_with_recoveries":602575,"implied_total_expenses":110000,"implied_expenses_psf":5.50,"implied_expense_ratio_pct":18.3,"financing":{"ltv_pct":70,"loan_amount":4375000,"dscr_at_7_5_pct_25_year_amortization":1.27,"dscr_at_8_0_pct_25_year_amortization":1.22},"valuation_scenarios":[{"cap_rate_pct":7.88,"value":6250000,"label":"asking price"},{"cap_rate_pct":8.0,"value":6157188},{"cap_rate_pct":8.5,"value":5795000},{"cap_rate_pct":9.0,"value":5473056},{"cap_rate_pct":9.5,"value":5185000}]}'::jsonb AS raw_json
)
UPDATE public.financial_reports f
SET rental_income = data.rental_income,
    recoveries = data.recoveries,
    gross_income = data.gross_income,
    total_expenses = data.total_expenses,
    noi = data.noi,
    cap_rate = data.cap_rate,
    occupancy = data.occupancy,
    confidence = data.confidence,
    raw_json = data.raw_json
FROM data
WHERE f.property_id = data.property_id AND f.source_pdf = data.source_pdf;

WITH data AS (
    SELECT
        'mallard_cove_conroe_tx_2026'::text AS property_id,
        '$524,450'::text AS rental_income,
        '$78,125'::text AS recoveries,
        '$602,575'::text AS gross_income,
        '$110,000 implied from OM numbers'::text AS total_expenses,
        '$492,575'::text AS noi,
        '8.0% stated / 7.88% actual from NOI and price'::text AS cap_rate,
        '100.0%'::text AS occupancy,
        '9d5debbf-b7dd-4943-9e8d-e66df2b91f9b.pdf'::text AS source_pdf,
        70::integer AS confidence,
        '{"asking_price":6250000,"noi":492575,"stated_cap_rate_pct":8.0,"actual_cap_rate_pct":7.88,"price_per_sf":312.50,"annual_base_rent":524450,"annual_opex_recovery":78125,"gross_income_with_recoveries":602575,"implied_total_expenses":110000,"implied_expenses_psf":5.50,"implied_expense_ratio_pct":18.3,"financing":{"ltv_pct":70,"loan_amount":4375000,"dscr_at_7_5_pct_25_year_amortization":1.27,"dscr_at_8_0_pct_25_year_amortization":1.22},"valuation_scenarios":[{"cap_rate_pct":7.88,"value":6250000,"label":"asking price"},{"cap_rate_pct":8.0,"value":6157188},{"cap_rate_pct":8.5,"value":5795000},{"cap_rate_pct":9.0,"value":5473056},{"cap_rate_pct":9.5,"value":5185000}]}'::jsonb AS raw_json
)
INSERT INTO public.financial_reports (
    property_id, rental_income, recoveries, gross_income, total_expenses,
    noi, cap_rate, occupancy, source_pdf, confidence, raw_json
)
SELECT property_id, rental_income, recoveries, gross_income, total_expenses,
       noi, cap_rate, occupancy, source_pdf, confidence, raw_json
FROM data
WHERE NOT EXISTS (
    SELECT 1 FROM public.financial_reports f
    WHERE f.property_id = data.property_id AND f.source_pdf = data.source_pdf
);

WITH data AS (
    SELECT * FROM (VALUES
        ('mallard_cove_conroe_tx_2026','Compassionate Care Hospice of Southeastern Texas, LLC','2685 Suite A','2,500','2022-05-01','2027-04-30','$6,325','$75,900','$30.36','Gross','Two 3-year terms at lesser of market rates or current lease rate; no rent bumps','9d5debbf-b7dd-4943-9e8d-e66df2b91f9b.pdf'),
        ('mallard_cove_conroe_tx_2026','PowerPath International','2685 Suite B','2,500','2026-07-01','2029-06-30','$5,521','$66,250','$26.50','NNN','None; 3% annual bumps; annual opex recovery $13,750','9d5debbf-b7dd-4943-9e8d-e66df2b91f9b.pdf'),
        ('mallard_cove_conroe_tx_2026','Experience Network, LLC','2671 Suite A','2,500','2024-12-01','2029-11-30','$5,313','$63,750','$25.50','NNN','One 5-year option at market rate; $0.50 annual bumps; annual opex recovery $13,125','9d5debbf-b7dd-4943-9e8d-e66df2b91f9b.pdf'),
        ('mallard_cove_conroe_tx_2026','Quatro Tax, LLC','2671 Suite B','2,500','2025-10-01','2028-09-30','$5,313','$63,750','$25.50','NNN','No option; $0.50 annual bumps; annual opex recovery $13,125','9d5debbf-b7dd-4943-9e8d-e66df2b91f9b.pdf'),
        ('mallard_cove_conroe_tx_2026','Ryan Nelson Chiropractor','2657 Suite A','2,500','2023-02-01','2028-02-29','$5,250','$63,000','$25.20','Gross','None; 5% annual bumps','9d5debbf-b7dd-4943-9e8d-e66df2b91f9b.pdf'),
        ('mallard_cove_conroe_tx_2026','Investar','2657 Suite B','2,500','2024-04-01','2029-03-31','$5,202','$62,425','$24.97','NNN','One 5-year renewal at market rates; 2% annual bumps; annual opex recovery $12,500','9d5debbf-b7dd-4943-9e8d-e66df2b91f9b.pdf'),
        ('mallard_cove_conroe_tx_2026','Manuel Builders','2643 Suite A','2,500','2024-04-01','2030-01-31','$5,365','$64,375','$25.75','NNN','One 5-year renewal at market rates; 3% annual bumps; annual opex recovery $12,500','9d5debbf-b7dd-4943-9e8d-e66df2b91f9b.pdf'),
        ('mallard_cove_conroe_tx_2026','Core Movement Therapy LLC','2643 Suite B','2,500','2026-07-07','2030-06-06','$5,417','$65,000','$26.00','NNN','None; 2.5% annual bumps; annual opex recovery $13,125','9d5debbf-b7dd-4943-9e8d-e66df2b91f9b.pdf')
    ) AS v(property_id, tenant_name, suite, sf, lease_start, lease_end, monthly_rent, annual_rent, rent_psf, lease_type, renewal_options, source_pdf)
)
UPDATE public.rent_rolls r
SET sf = data.sf,
    lease_start = data.lease_start,
    lease_end = data.lease_end,
    monthly_rent = data.monthly_rent,
    annual_rent = data.annual_rent,
    rent_psf = data.rent_psf,
    lease_type = data.lease_type,
    renewal_options = data.renewal_options,
    source_pdf = data.source_pdf
FROM data
WHERE r.property_id = data.property_id AND r.tenant_name = data.tenant_name AND r.suite = data.suite;

WITH data AS (
    SELECT * FROM (VALUES
        ('mallard_cove_conroe_tx_2026','Compassionate Care Hospice of Southeastern Texas, LLC','2685 Suite A','2,500','2022-05-01','2027-04-30','$6,325','$75,900','$30.36','Gross','Two 3-year terms at lesser of market rates or current lease rate; no rent bumps','9d5debbf-b7dd-4943-9e8d-e66df2b91f9b.pdf'),
        ('mallard_cove_conroe_tx_2026','PowerPath International','2685 Suite B','2,500','2026-07-01','2029-06-30','$5,521','$66,250','$26.50','NNN','None; 3% annual bumps; annual opex recovery $13,750','9d5debbf-b7dd-4943-9e8d-e66df2b91f9b.pdf'),
        ('mallard_cove_conroe_tx_2026','Experience Network, LLC','2671 Suite A','2,500','2024-12-01','2029-11-30','$5,313','$63,750','$25.50','NNN','One 5-year option at market rate; $0.50 annual bumps; annual opex recovery $13,125','9d5debbf-b7dd-4943-9e8d-e66df2b91f9b.pdf'),
        ('mallard_cove_conroe_tx_2026','Quatro Tax, LLC','2671 Suite B','2,500','2025-10-01','2028-09-30','$5,313','$63,750','$25.50','NNN','No option; $0.50 annual bumps; annual opex recovery $13,125','9d5debbf-b7dd-4943-9e8d-e66df2b91f9b.pdf'),
        ('mallard_cove_conroe_tx_2026','Ryan Nelson Chiropractor','2657 Suite A','2,500','2023-02-01','2028-02-29','$5,250','$63,000','$25.20','Gross','None; 5% annual bumps','9d5debbf-b7dd-4943-9e8d-e66df2b91f9b.pdf'),
        ('mallard_cove_conroe_tx_2026','Investar','2657 Suite B','2,500','2024-04-01','2029-03-31','$5,202','$62,425','$24.97','NNN','One 5-year renewal at market rates; 2% annual bumps; annual opex recovery $12,500','9d5debbf-b7dd-4943-9e8d-e66df2b91f9b.pdf'),
        ('mallard_cove_conroe_tx_2026','Manuel Builders','2643 Suite A','2,500','2024-04-01','2030-01-31','$5,365','$64,375','$25.75','NNN','One 5-year renewal at market rates; 3% annual bumps; annual opex recovery $12,500','9d5debbf-b7dd-4943-9e8d-e66df2b91f9b.pdf'),
        ('mallard_cove_conroe_tx_2026','Core Movement Therapy LLC','2643 Suite B','2,500','2026-07-07','2030-06-06','$5,417','$65,000','$26.00','NNN','None; 2.5% annual bumps; annual opex recovery $13,125','9d5debbf-b7dd-4943-9e8d-e66df2b91f9b.pdf')
    ) AS v(property_id, tenant_name, suite, sf, lease_start, lease_end, monthly_rent, annual_rent, rent_psf, lease_type, renewal_options, source_pdf)
)
INSERT INTO public.rent_rolls (property_id, tenant_name, suite, sf, lease_start, lease_end, monthly_rent, annual_rent, rent_psf, lease_type, renewal_options, source_pdf)
SELECT property_id, tenant_name, suite, sf, lease_start, lease_end, monthly_rent, annual_rent, rent_psf, lease_type, renewal_options, source_pdf
FROM data
WHERE NOT EXISTS (
    SELECT 1 FROM public.rent_rolls r
    WHERE r.property_id = data.property_id AND r.tenant_name = data.tenant_name AND r.suite = data.suite
);

WITH data AS (
    SELECT * FROM (VALUES
        (1001::bigint,'Compassionate Care Hospice of Southeastern Texas, LLC','2685 Suite A',6325::numeric,75900::numeric,'2022-05-01'::date,'2027-04-30'::date,'Two 3-year terms at lesser of market rates or current lease rate; risk: near-term expiration and gross lease','occupied'),
        (1001::bigint,'PowerPath International','2685 Suite B',5521::numeric,66250::numeric,'2026-07-01'::date,'2029-06-30'::date,'None; 3% annual bumps','occupied'),
        (1001::bigint,'Experience Network, LLC','2671 Suite A',5313::numeric,63750::numeric,'2024-12-01'::date,'2029-11-30'::date,'One 5-year option at market rate; $0.50 annual bumps','occupied'),
        (1001::bigint,'Quatro Tax, LLC','2671 Suite B',5313::numeric,63750::numeric,'2025-10-01'::date,'2028-09-30'::date,'No option; $0.50 annual bumps','occupied'),
        (1001::bigint,'Ryan Nelson Chiropractor','2657 Suite A',5250::numeric,63000::numeric,'2023-02-01'::date,'2028-02-29'::date,'None; 5% annual bumps; risk: gross lease','occupied'),
        (1001::bigint,'Investar','2657 Suite B',5202::numeric,62425::numeric,'2024-04-01'::date,'2029-03-31'::date,'One 5-year renewal at market rates; 2% annual bumps','occupied'),
        (1001::bigint,'Manuel Builders','2643 Suite A',5365::numeric,64375::numeric,'2024-04-01'::date,'2030-01-31'::date,'One 5-year renewal at market rates; 3% annual bumps','occupied'),
        (1001::bigint,'Core Movement Therapy LLC','2643 Suite B',5417::numeric,65000::numeric,'2026-07-07'::date,'2030-06-06'::date,'None; 2.5% annual bumps','occupied')
    ) AS v(property_id, tenant, suite, monthly_rent, annual_rent, lease_start, lease_end, options, occupancy_status)
)
UPDATE public.tenants t
SET monthly_rent = data.monthly_rent,
    annual_rent = data.annual_rent,
    lease_start = data.lease_start,
    lease_end = data.lease_end,
    options = data.options,
    occupancy_status = data.occupancy_status
FROM data
WHERE t.property_id = data.property_id AND t.tenant = data.tenant AND t.suite = data.suite;

WITH data AS (
    SELECT * FROM (VALUES
        (1001::bigint,'Compassionate Care Hospice of Southeastern Texas, LLC','2685 Suite A',6325::numeric,75900::numeric,'2022-05-01'::date,'2027-04-30'::date,'Two 3-year terms at lesser of market rates or current lease rate; risk: near-term expiration and gross lease','occupied'),
        (1001::bigint,'PowerPath International','2685 Suite B',5521::numeric,66250::numeric,'2026-07-01'::date,'2029-06-30'::date,'None; 3% annual bumps','occupied'),
        (1001::bigint,'Experience Network, LLC','2671 Suite A',5313::numeric,63750::numeric,'2024-12-01'::date,'2029-11-30'::date,'One 5-year option at market rate; $0.50 annual bumps','occupied'),
        (1001::bigint,'Quatro Tax, LLC','2671 Suite B',5313::numeric,63750::numeric,'2025-10-01'::date,'2028-09-30'::date,'No option; $0.50 annual bumps','occupied'),
        (1001::bigint,'Ryan Nelson Chiropractor','2657 Suite A',5250::numeric,63000::numeric,'2023-02-01'::date,'2028-02-29'::date,'None; 5% annual bumps; risk: gross lease','occupied'),
        (1001::bigint,'Investar','2657 Suite B',5202::numeric,62425::numeric,'2024-04-01'::date,'2029-03-31'::date,'One 5-year renewal at market rates; 2% annual bumps','occupied'),
        (1001::bigint,'Manuel Builders','2643 Suite A',5365::numeric,64375::numeric,'2024-04-01'::date,'2030-01-31'::date,'One 5-year renewal at market rates; 3% annual bumps','occupied'),
        (1001::bigint,'Core Movement Therapy LLC','2643 Suite B',5417::numeric,65000::numeric,'2026-07-07'::date,'2030-06-06'::date,'None; 2.5% annual bumps','occupied')
    ) AS v(property_id, tenant, suite, monthly_rent, annual_rent, lease_start, lease_end, options, occupancy_status)
)
INSERT INTO public.tenants (property_id, tenant, suite, monthly_rent, annual_rent, lease_start, lease_end, options, occupancy_status)
SELECT property_id, tenant, suite, monthly_rent, annual_rent, lease_start, lease_end, options, occupancy_status
FROM data
WHERE NOT EXISTS (
    SELECT 1 FROM public.tenants t
    WHERE t.property_id = data.property_id AND t.tenant = data.tenant AND t.suite = data.suite
);

WITH data AS (
    SELECT 1001::bigint AS property_id,
           35::numeric AS due_diligence_score,
           38::numeric AS seller_weakness_score,
           70::numeric AS acquisition_score,
           65::numeric AS risk_score,
           55::numeric AS upside_score,
           58::numeric AS overall_score,
           'HOLD / REQUEST MORE INFO. Do not submit a final offer until T12, executed leases, rent roll Excel, tax bill, insurance bill, CAM reconciliation, and tenant payment history are reviewed. Suggested first offer around $5.75M; move up only if NOI and leases verify.'::text AS recommendation,
           'T12 operating statement; current rent roll in Excel; executed leases and amendments; tax bills; insurance quote or policy; CAM reconciliation history; tenant payment ledger; roof/HVAC/parking responsibility detail; environmental, drainage, detention pond, and easement detail; seller reason for sale and debt status.'::text AS missing_items,
           'Short WALT around 2.5 years; two gross leases; 2027 Compassionate Care expiration; missing T12; no lease abstracts; local tenant exposure; financing may be tight near 8% interest if lender requires 1.25x DSCR.'::text AS weaknesses
)
UPDATE public.analysis a
SET due_diligence_score = data.due_diligence_score,
    seller_weakness_score = data.seller_weakness_score,
    acquisition_score = data.acquisition_score,
    risk_score = data.risk_score,
    upside_score = data.upside_score,
    overall_score = data.overall_score,
    recommendation = data.recommendation,
    missing_items = data.missing_items,
    weaknesses = data.weaknesses
FROM data
WHERE a.property_id = data.property_id;

WITH data AS (
    SELECT 1001::bigint AS property_id,
           35::numeric AS due_diligence_score,
           38::numeric AS seller_weakness_score,
           70::numeric AS acquisition_score,
           65::numeric AS risk_score,
           55::numeric AS upside_score,
           58::numeric AS overall_score,
           'HOLD / REQUEST MORE INFO. Do not submit a final offer until T12, executed leases, rent roll Excel, tax bill, insurance bill, CAM reconciliation, and tenant payment history are reviewed. Suggested first offer around $5.75M; move up only if NOI and leases verify.'::text AS recommendation,
           'T12 operating statement; current rent roll in Excel; executed leases and amendments; tax bills; insurance quote or policy; CAM reconciliation history; tenant payment ledger; roof/HVAC/parking responsibility detail; environmental, drainage, detention pond, and easement detail; seller reason for sale and debt status.'::text AS missing_items,
           'Short WALT around 2.5 years; two gross leases; 2027 Compassionate Care expiration; missing T12; no lease abstracts; local tenant exposure; financing may be tight near 8% interest if lender requires 1.25x DSCR.'::text AS weaknesses
)
INSERT INTO public.analysis (property_id, due_diligence_score, seller_weakness_score, acquisition_score, risk_score, upside_score, overall_score, recommendation, missing_items, weaknesses)
SELECT property_id, due_diligence_score, seller_weakness_score, acquisition_score, risk_score, upside_score, overall_score, recommendation, missing_items, weaknesses
FROM data
WHERE NOT EXISTS (SELECT 1 FROM public.analysis a WHERE a.property_id = data.property_id);

WITH data AS (
    SELECT 'mallard_cove_conroe_tx_2026'::text AS property_id,
           '{"decision":"HOLD / REQUEST MORE INFO","summary":"Stabilized 2022 Class A small-bay retail/office park with 100% occupancy and strong Conroe growth story, but short WALT, two gross leases, missing T12, and limited lease detail require diligence before LOI.","strengths":["100% occupied","New 2022 construction","20,000 SF across eight suites","Mixed tenant base","Conroe growth story"],"red_flags":["Short WALT","Two gross leases","Compassionate Care expires 2027","No full T12","No lease abstracts"],"seller_weakness_score":38,"recommended_first_offer":5750000,"offer_ranges":{"aggressive_buyer_offer":"$5.45M-$5.65M","reasonable_first_offer":"$5.70M-$5.85M","if_clean":"$5.90M-$6.10M"}}'::jsonb AS report
)
UPDATE public.committee_reports c
SET report = data.report
FROM data
WHERE c.property_id = data.property_id;

WITH data AS (
    SELECT 'mallard_cove_conroe_tx_2026'::text AS property_id,
           '{"decision":"HOLD / REQUEST MORE INFO","summary":"Stabilized 2022 Class A small-bay retail/office park with 100% occupancy and strong Conroe growth story, but short WALT, two gross leases, missing T12, and limited lease detail require diligence before LOI.","strengths":["100% occupied","New 2022 construction","20,000 SF across eight suites","Mixed tenant base","Conroe growth story"],"red_flags":["Short WALT","Two gross leases","Compassionate Care expires 2027","No full T12","No lease abstracts"],"seller_weakness_score":38,"recommended_first_offer":5750000,"offer_ranges":{"aggressive_buyer_offer":"$5.45M-$5.65M","reasonable_first_offer":"$5.70M-$5.85M","if_clean":"$5.90M-$6.10M"}}'::jsonb AS report
)
INSERT INTO public.committee_reports (property_id, report)
SELECT property_id, report
FROM data
WHERE NOT EXISTS (SELECT 1 FROM public.committee_reports c WHERE c.property_id = data.property_id);

WITH data AS (
    SELECT 'mallard_cove_conroe_tx_2026'::text AS property_id,
           '{"decision":"HOLD / REQUEST MORE INFO","next_action":"Request T12, lease copies, rent roll Excel, tax bill, insurance bill, CAM reconciliation, and tenant payment ledger.","broker_questions":["Please send the T12 operating statement.","Please send current rent roll in Excel.","Please send all executed leases and amendments.","Are all tenants current on rent?","Any late payments in the last 24 months?","Are any tenants requesting concessions or planning not to renew?","Has Compassionate Care indicated renewal intent?","Who is responsible for roof, HVAC, parking lot, landscaping, and exterior repairs?","What are actual 2025 and 2026 property taxes?","What is the current insurance premium?","Are CAM / opex recoveries reconciled annually?","Are the gross lease tenants paying any reimbursements at all?","Is there any debt on the property?","Why is the seller selling a newly built, fully occupied asset?","Any environmental, drainage, detention pond, or easement issues?","Are there tenant guarantees or personal guarantees?","Has the property ever had flooding or water intrusion?","Are any roofs, HVAC units, or parking areas under warranty?","Is the lake / walking path maintained by owner, HOA, or another party?","Can seller provide 2024, 2025, and YTD 2026 P&L?"]}'::jsonb AS decision
)
UPDATE public.acquisition_decisions a
SET decision = data.decision
FROM data
WHERE a.property_id = data.property_id;

WITH data AS (
    SELECT 'mallard_cove_conroe_tx_2026'::text AS property_id,
           '{"decision":"HOLD / REQUEST MORE INFO","next_action":"Request T12, lease copies, rent roll Excel, tax bill, insurance bill, CAM reconciliation, and tenant payment ledger.","broker_questions":["Please send the T12 operating statement.","Please send current rent roll in Excel.","Please send all executed leases and amendments.","Are all tenants current on rent?","Any late payments in the last 24 months?","Are any tenants requesting concessions or planning not to renew?","Has Compassionate Care indicated renewal intent?","Who is responsible for roof, HVAC, parking lot, landscaping, and exterior repairs?","What are actual 2025 and 2026 property taxes?","What is the current insurance premium?","Are CAM / opex recoveries reconciled annually?","Are the gross lease tenants paying any reimbursements at all?","Is there any debt on the property?","Why is the seller selling a newly built, fully occupied asset?","Any environmental, drainage, detention pond, or easement issues?","Are there tenant guarantees or personal guarantees?","Has the property ever had flooding or water intrusion?","Are any roofs, HVAC units, or parking areas under warranty?","Is the lake / walking path maintained by owner, HOA, or another party?","Can seller provide 2024, 2025, and YTD 2026 P&L?"]}'::jsonb AS decision
)
INSERT INTO public.acquisition_decisions (property_id, decision)
SELECT property_id, decision
FROM data
WHERE NOT EXISTS (SELECT 1 FROM public.acquisition_decisions a WHERE a.property_id = data.property_id);

COMMIT;
