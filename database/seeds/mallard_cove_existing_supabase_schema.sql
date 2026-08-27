-- Mallard Cove seed matching the current live Supabase schema copied from Schema Visualizer.
-- Live-safe version: insert-only. It does not delete or update existing rows.
-- Existing schema uses text property_id in some tables and bigint property_id
-- in others, so this uses both:
--   text property_id: mallard_cove_conroe_tx_2026
--   numeric property_id: -26432751336

BEGIN;

INSERT INTO public.properties (
    property_id, property_name, address, property_type, asking_price, noi,
    cap_rate, occupancy, building_sf, land_sf, year_built, broker_name,
    broker_email, broker_phone, source_pdf, major_risks, missing_information,
    unit_count, value_add, extraction_confidence
)
SELECT
    'mallard_cove_conroe_tx_2026',
    'Mallard Cove Professional Building',
    '2643-2751 S Loop 336 W, Conroe, TX 77304',
    'Class A multi-tenant retail/office park',
    '$6,250,000',
    '$492,575',
    '8.0%',
    '100.0%',
    '20,000 SF',
    '4.167 acres / approx. 181,515 SF',
    '2022',
    'Linda Crumley; Brigham Hedges',
    'linda.crumley@svn.com; brigham.hedges@svn.com',
    '281-367-2220 ext 119; 281-367-2220 ext 143',
    '9d5debbf-b7dd-4943-9e8d-e66df2b91f9b.pdf',
    '["Short WALT around 2.5 years","Two gross leases create owner expense exposure","Compassionate Care expires 2027 and pays the highest annual rent","Compassionate Care renewal option may cap rent growth","No full T12 shown in OM","No lease abstracts or executed lease copies included in OM","Several tenants appear local or small-business rather than national-credit tenants"]'::jsonb,
    '["T12 operating statement","Current rent roll in Excel","Executed leases and amendments","Tax bills","Insurance quote or policy","CAM reconciliation history","Tenant payment ledger","Roof/HVAC/parking responsibility detail","Environmental, drainage, detention pond, and easement detail","Reason for sale and debt status"]'::jsonb,
    8,
    false,
    95
WHERE NOT EXISTS (
    SELECT 1 FROM public.properties
    WHERE property_id = 'mallard_cove_conroe_tx_2026'
       OR address = '2643-2751 S Loop 336 W, Conroe, TX 77304'
);

INSERT INTO public.documents (property_id, file_name, file_type, drive_file_id, processed_at, status)
SELECT -26432751336, '9d5debbf-b7dd-4943-9e8d-e66df2b91f9b.pdf', 'offering_memorandum_pdf', NULL, now(), 'processed'
WHERE NOT EXISTS (
    SELECT 1 FROM public.documents
    WHERE property_id = -26432751336
      AND file_name = '9d5debbf-b7dd-4943-9e8d-e66df2b91f9b.pdf'
);

INSERT INTO public.brokers (property_id, broker_name, broker_company, broker_email, broker_phone)
SELECT * FROM (VALUES
    (-26432751336::bigint, 'Linda Crumley'::text, 'SVN | J. Beard Real Estate'::text, 'linda.crumley@svn.com'::text, '281-367-2220 ext 119'::text),
    (-26432751336::bigint, 'Brigham Hedges'::text, 'SVN | J. Beard Real Estate'::text, 'brigham.hedges@svn.com'::text, '281-367-2220 ext 143'::text)
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
    'mallard_cove_conroe_tx_2026',
    '$524,450',
    '$78,125',
    '$602,575',
    '$110,000 implied from OM numbers',
    '$492,575',
    '8.0% stated / 7.88% actual from NOI and price',
    '100.0%',
    '9d5debbf-b7dd-4943-9e8d-e66df2b91f9b.pdf',
    70,
    '{"asking_price":6250000,"noi":492575,"stated_cap_rate_pct":8.0,"actual_cap_rate_pct":7.88,"price_per_sf":312.50,"annual_base_rent":524450,"annual_opex_recovery":78125,"gross_income_with_recoveries":602575,"implied_total_expenses":110000,"implied_expenses_psf":5.50,"implied_expense_ratio_pct":18.3,"financing":{"ltv_pct":70,"loan_amount":4375000,"dscr_at_7_5_pct_25_year_amortization":1.27,"dscr_at_8_0_pct_25_year_amortization":1.22},"valuation_scenarios":[{"cap_rate_pct":7.88,"value":6250000,"label":"asking price"},{"cap_rate_pct":8.0,"value":6157188},{"cap_rate_pct":8.5,"value":5795000},{"cap_rate_pct":9.0,"value":5473056},{"cap_rate_pct":9.5,"value":5185000}]}'::jsonb
WHERE NOT EXISTS (
    SELECT 1 FROM public.financial_reports
    WHERE property_id = 'mallard_cove_conroe_tx_2026'
      AND source_pdf = '9d5debbf-b7dd-4943-9e8d-e66df2b91f9b.pdf'
);

INSERT INTO public.rent_rolls (
    property_id, tenant_name, suite, sf, lease_start, lease_end,
    monthly_rent, annual_rent, rent_psf, lease_type, renewal_options, source_pdf
)
SELECT * FROM (VALUES
    ('mallard_cove_conroe_tx_2026','Compassionate Care Hospice of Southeastern Texas, LLC','2685 Suite A','2,500','2022-05-01','2027-04-30','$6,325','$75,900','$30.36','Gross','Two 3-year terms at lesser of market rates or current lease rate; no rent bumps','9d5debbf-b7dd-4943-9e8d-e66df2b91f9b.pdf'),
    ('mallard_cove_conroe_tx_2026','PowerPath International','2685 Suite B','2,500','2026-07-01','2029-06-30','$5,521','$66,250','$26.50','NNN','None; 3% annual bumps; annual opex recovery $13,750','9d5debbf-b7dd-4943-9e8d-e66df2b91f9b.pdf'),
    ('mallard_cove_conroe_tx_2026','Experience Network, LLC','2671 Suite A','2,500','2024-12-01','2029-11-30','$5,313','$63,750','$25.50','NNN','One 5-year option at market rate; $0.50 annual bumps; annual opex recovery $13,125','9d5debbf-b7dd-4943-9e8d-e66df2b91f9b.pdf'),
    ('mallard_cove_conroe_tx_2026','Quatro Tax, LLC','2671 Suite B','2,500','2025-10-01','2028-09-30','$5,313','$63,750','$25.50','NNN','No option; $0.50 annual bumps; annual opex recovery $13,125','9d5debbf-b7dd-4943-9e8d-e66df2b91f9b.pdf'),
    ('mallard_cove_conroe_tx_2026','Ryan Nelson Chiropractor','2657 Suite A','2,500','2023-02-01','2028-02-29','$5,250','$63,000','$25.20','Gross','None; 5% annual bumps','9d5debbf-b7dd-4943-9e8d-e66df2b91f9b.pdf'),
    ('mallard_cove_conroe_tx_2026','Investar','2657 Suite B','2,500','2024-04-01','2029-03-31','$5,202','$62,425','$24.97','NNN','One 5-year renewal at market rates; 2% annual bumps; annual opex recovery $12,500','9d5debbf-b7dd-4943-9e8d-e66df2b91f9b.pdf'),
    ('mallard_cove_conroe_tx_2026','Manuel Builders','2643 Suite A','2,500','2024-04-01','2030-01-31','$5,365','$64,375','$25.75','NNN','One 5-year renewal at market rates; 3% annual bumps; annual opex recovery $12,500','9d5debbf-b7dd-4943-9e8d-e66df2b91f9b.pdf'),
    ('mallard_cove_conroe_tx_2026','Core Movement Therapy LLC','2643 Suite B','2,500','2026-07-07','2030-06-06','$5,417','$65,000','$26.00','NNN','None; 2.5% annual bumps; annual opex recovery $13,125','9d5debbf-b7dd-4943-9e8d-e66df2b91f9b.pdf')
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
    (-26432751336::bigint,'Compassionate Care Hospice of Southeastern Texas, LLC','2685 Suite A',6325::numeric,75900::numeric,'2022-05-01'::date,'2027-04-30'::date,'Two 3-year terms at lesser of market rates or current lease rate; risk: near-term expiration and gross lease','occupied'),
    (-26432751336::bigint,'PowerPath International','2685 Suite B',5521::numeric,66250::numeric,'2026-07-01'::date,'2029-06-30'::date,'None; 3% annual bumps','occupied'),
    (-26432751336::bigint,'Experience Network, LLC','2671 Suite A',5313::numeric,63750::numeric,'2024-12-01'::date,'2029-11-30'::date,'One 5-year option at market rate; $0.50 annual bumps','occupied'),
    (-26432751336::bigint,'Quatro Tax, LLC','2671 Suite B',5313::numeric,63750::numeric,'2025-10-01'::date,'2028-09-30'::date,'No option; $0.50 annual bumps','occupied'),
    (-26432751336::bigint,'Ryan Nelson Chiropractor','2657 Suite A',5250::numeric,63000::numeric,'2023-02-01'::date,'2028-02-29'::date,'None; 5% annual bumps; risk: gross lease','occupied'),
    (-26432751336::bigint,'Investar','2657 Suite B',5202::numeric,62425::numeric,'2024-04-01'::date,'2029-03-31'::date,'One 5-year renewal at market rates; 2% annual bumps','occupied'),
    (-26432751336::bigint,'Manuel Builders','2643 Suite A',5365::numeric,64375::numeric,'2024-04-01'::date,'2030-01-31'::date,'One 5-year renewal at market rates; 3% annual bumps','occupied'),
    (-26432751336::bigint,'Core Movement Therapy LLC','2643 Suite B',5417::numeric,65000::numeric,'2026-07-07'::date,'2030-06-06'::date,'None; 2.5% annual bumps','occupied')
) AS data(property_id, tenant, suite, monthly_rent, annual_rent, lease_start, lease_end, options, occupancy_status)
WHERE NOT EXISTS (
    SELECT 1 FROM public.tenants t
    WHERE t.property_id = data.property_id AND t.tenant = data.tenant AND t.suite = data.suite
);

INSERT INTO public.analysis (
    property_id, due_diligence_score, seller_weakness_score,
    acquisition_score, risk_score, upside_score, overall_score,
    recommendation, missing_items, weaknesses
)
SELECT
    -26432751336,
    35,
    38,
    70,
    65,
    55,
    58,
    'HOLD / REQUEST MORE INFO. Do not submit a final offer until T12, executed leases, rent roll Excel, tax bill, insurance bill, CAM reconciliation, and tenant payment history are reviewed. Suggested first offer around $5.75M; move up only if NOI and leases verify.',
    'T12 operating statement; current rent roll in Excel; executed leases and amendments; tax bills; insurance quote or policy; CAM reconciliation history; tenant payment ledger; roof/HVAC/parking responsibility detail; environmental, drainage, detention pond, and easement detail; seller reason for sale and debt status.',
    'Short WALT around 2.5 years; two gross leases; 2027 Compassionate Care expiration; missing T12; no lease abstracts; local tenant exposure; financing may be tight near 8% interest if lender requires 1.25x DSCR.'
WHERE NOT EXISTS (
    SELECT 1 FROM public.analysis WHERE property_id = -26432751336
);

INSERT INTO public.committee_reports (property_id, report)
SELECT
    'mallard_cove_conroe_tx_2026',
    '{"decision":"HOLD / REQUEST MORE INFO","summary":"Stabilized 2022 Class A small-bay retail/office park with 100% occupancy and strong Conroe growth story, but short WALT, two gross leases, missing T12, and limited lease detail require diligence before LOI.","strengths":["100% occupied","New 2022 construction","20,000 SF across eight suites","Mixed tenant base","Conroe growth story"],"red_flags":["Short WALT","Two gross leases","Compassionate Care expires 2027","No full T12","No lease abstracts"],"seller_weakness_score":38,"recommended_first_offer":5750000,"offer_ranges":{"aggressive_buyer_offer":"$5.45M-$5.65M","reasonable_first_offer":"$5.70M-$5.85M","if_clean":"$5.90M-$6.10M"}}'::jsonb
WHERE NOT EXISTS (
    SELECT 1 FROM public.committee_reports WHERE property_id = 'mallard_cove_conroe_tx_2026'
);

INSERT INTO public.acquisition_decisions (property_id, decision)
SELECT
    'mallard_cove_conroe_tx_2026',
    '{"decision":"HOLD / REQUEST MORE INFO","next_action":"Request T12, lease copies, rent roll Excel, tax bill, insurance bill, CAM reconciliation, and tenant payment ledger.","broker_questions":["Please send the T12 operating statement.","Please send current rent roll in Excel.","Please send all executed leases and amendments.","Are all tenants current on rent?","Any late payments in the last 24 months?","Are any tenants requesting concessions or planning not to renew?","Has Compassionate Care indicated renewal intent?","Who is responsible for roof, HVAC, parking lot, landscaping, and exterior repairs?","What are actual 2025 and 2026 property taxes?","What is the current insurance premium?","Are CAM / opex recoveries reconciled annually?","Are the gross lease tenants paying any reimbursements at all?","Is there any debt on the property?","Why is the seller selling a newly built, fully occupied asset?","Any environmental, drainage, detention pond, or easement issues?","Are there tenant guarantees or personal guarantees?","Has the property ever had flooding or water intrusion?","Are any roofs, HVAC units, or parking areas under warranty?","Is the lake / walking path maintained by owner, HOA, or another party?","Can seller provide 2024, 2025, and YTD 2026 P&L?"]}'::jsonb
WHERE NOT EXISTS (
    SELECT 1 FROM public.acquisition_decisions WHERE property_id = 'mallard_cove_conroe_tx_2026'
);

COMMIT;
