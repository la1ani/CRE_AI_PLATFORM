-- Insert-only Supabase seed for two uploaded Crexi OM/flyer PDFs.
-- Built for the current live schema shared from Supabase Schema Visualizer.
-- This file does not delete or update existing rows.
--
-- Text property ids:
--   cypress_station_square_houston_tx_2026
--   point_west_center_houston_tx_2026
--
-- Numeric property ids used by bigint property_id tables:
--   Cypress Station Square: -2647658
--   Point West Center: -1916802

BEGIN;

-- ---------------------------------------------------------------------------
-- Cypress Station Square
-- ---------------------------------------------------------------------------

INSERT INTO public.properties (
    property_id, property_name, address, property_type, asking_price, noi,
    cap_rate, occupancy, building_sf, land_sf, year_built, broker_name,
    broker_email, broker_phone, source_pdf, major_risks, missing_information,
    unit_count, value_add, extraction_confidence
)
SELECT
    'cypress_station_square_houston_tx_2026',
    'Cypress Station Square',
    '70 Cypress Creek Parkway, Houston, TX 77090',
    'Shopping Center / Retail Center',
    '$21,410,000',
    '$1,980,452 current / $2,285,301 pro forma',
    '9.25% current / 10.67% pro forma',
    '90.77% occupied / 9.23% vacant',
    '137,565 SF',
    '12.19 AC',
    '1986 / renovated 2019',
    'Alex Wolansky; Gus N. Lagos',
    'alex.wolansky@marcusmillichap.com; gus.lagos@marcusmillichap.com',
    '713-452-4292; 713-452-4257',
    'texas-cypress-station-square.pdf',
    '["9.23% vacancy / 12,704 SF vacant","Large center with many tenant leases to verify","Several lease structures include gross, modified gross, ground lease, CAM caps, or special clauses","Dollar Tree and other tenants have CAM or management fee limitations","Texas High School tenant has a one-time termination right tied to charter loss","Older 1986 construction despite 2019 renovation","No executed leases, T12 backup, environmental report, roof report, or tenant payment ledger included in extracted data"]'::jsonb,
    '["Executed leases and amendments","Current rent roll in Excel","T12 operating statement","Tenant payment history","CAM reconciliation backup","Roof age and roof warranty detail","HVAC responsibility and condition","Environmental report","Property tax bill","Insurance policy and flood premium backup","Vacant suite leasing assumptions","Service contracts","Capital expenditure history"]'::jsonb,
    24,
    true,
    95
WHERE NOT EXISTS (
    SELECT 1 FROM public.properties
    WHERE property_id = 'cypress_station_square_houston_tx_2026'
       OR address = '70 Cypress Creek Parkway, Houston, TX 77090'
);

INSERT INTO public.documents (property_id, file_name, file_type, drive_file_id, processed_at, status)
SELECT -2647658, 'texas-cypress-station-square.pdf', 'offering_memorandum_pdf', NULL, now(), 'processed'
WHERE NOT EXISTS (
    SELECT 1 FROM public.documents
    WHERE property_id = -2647658 AND file_name = 'texas-cypress-station-square.pdf'
);

INSERT INTO public.brokers (property_id, broker_name, broker_company, broker_email, broker_phone)
SELECT * FROM (VALUES
    (-2647658::bigint, 'Alex Wolansky, CCIM'::text, 'Marcus & Millichap'::text, 'alex.wolansky@marcusmillichap.com'::text, '713-452-4292'::text),
    (-2647658::bigint, 'Gus N. Lagos'::text, 'Marcus & Millichap'::text, 'gus.lagos@marcusmillichap.com'::text, '713-452-4257'::text),
    (-2647658::bigint, 'Jamie Safier'::text, 'Marcus & Millichap Capital Corporation'::text, 'jamie.safier@marcusmillichap.com'::text, '713-239-0501'::text),
    (-2647658::bigint, 'Thomas Monge'::text, 'Marcus & Millichap Capital Corporation'::text, 'thomas.monge@marcusmillichap.com'::text, '713-239-0515'::text)
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
    'cypress_station_square_houston_tx_2026',
    '$2,109,395 current / $2,342,947 pro forma',
    '$780,249 current / $864,212 pro forma',
    '$2,889,643 current / $3,207,158 pro forma',
    '$909,191.85 current / $921,857.02 pro forma',
    '$1,980,452 current / $2,285,301 pro forma',
    '9.25% current / 10.67% pro forma',
    '90.77% occupied / 9.23% vacant',
    'texas-cypress-station-square.pdf',
    90,
    '{"asking_price":21410000,"current_noi":1980452,"pro_forma_noi":2285301,"current_cap_rate_pct":9.25,"pro_forma_cap_rate_pct":10.67,"price_per_sf":155.64,"building_sf":137565,"land_acres":12.19,"current_base_rental_income":2109395,"pro_forma_base_rental_income":2342947,"current_reimbursement_income":780249,"pro_forma_reimbursement_income":864212,"current_effective_gross_revenue":2889643,"pro_forma_effective_gross_revenue":3207158,"current_total_expenses":909191.85,"pro_forma_total_expenses":921857.02,"expenses_per_sf_current":6.61,"expenses_per_sf_pro_forma":6.70,"loan_terms":{"loan_amount":13916500,"down_payment":7493500,"annual_debt_service":1101635,"ltv_pct":65,"interest_rate_pct":6.25,"term_years":5,"amortization_years":25},"returns":{"current_net_cash_flow_after_debt_service":878817,"pro_forma_net_cash_flow_after_debt_service":1183667,"current_total_return_pct":14.91,"pro_forma_total_return_pct":19.18},"traffic":{"cypress_creek_parkway_vpd":75000,"interstate_45_vpd":200000,"combined_location_vpd":275000},"pro_forma_assumptions":["Lease Suite 38 at $18/SF base rent plus NNN","Lease Suite 44 at $18/SF base rent plus NNN","Lease Suite 46 at $20/SF base rent plus NNN","Lease Suite 48 at $18/SF base rent plus NNN","Lease Suite 84 at $18/SF base rent plus NNN","Lease Suite 102 at $20/SF base rent plus NNN"]}'::jsonb
WHERE NOT EXISTS (
    SELECT 1 FROM public.financial_reports
    WHERE property_id = 'cypress_station_square_houston_tx_2026'
      AND source_pdf = 'texas-cypress-station-square.pdf'
);

INSERT INTO public.rent_rolls (
    property_id, tenant_name, suite, sf, lease_start, lease_end,
    monthly_rent, annual_rent, rent_psf, lease_type, renewal_options, source_pdf
)
SELECT * FROM (VALUES
    ('cypress_station_square_houston_tx_2026','C & C Dining, Inc. (Cilantro Cocina)','10','3,940','2015-12-01','2031-02-28','$8,865 current','$106,380 current','$27.00','NNN','Rent increases through 2031: $27/SF, $28/SF, $29/SF','texas-cypress-station-square.pdf'),
    ('cypress_station_square_houston_tx_2026','VACANT','102','1,015',NULL,NULL,NULL,NULL,NULL,'Vacant','Pro forma assumes lease at $20/SF base rent plus NNN','texas-cypress-station-square.pdf'),
    ('cypress_station_square_houston_tx_2026','FSAF Investment Inc. (Car Stereo Max)','110','4,357','2019-12-01','2029-04-30','$5,000 current','$60,000 current','$13.77','Modified Gross','Lease states NNN reimbursement, but landlord currently charges base rent only; scheduled increases through 2029','texas-cypress-station-square.pdf'),
    ('cypress_station_square_houston_tx_2026','Trakas Sports Cantina','120','5,026',NULL,NULL,'$12,565 after abatement','$150,780 stabilized','$30.00','NNN','2 x 5-year renewal options at FMV or 3% greater than prevailing rent; 10-year rent schedule','texas-cypress-station-square.pdf'),
    ('cypress_station_square_houston_tx_2026','Lisa Jackson (Daiquiriz With A Twist)','124','864','2019-03-13','2029-03-31','$3,501.36 2025-2026','$42,016.32 2025-2026','$48.63','Gross','Annual rent increases through 2029','texas-cypress-station-square.pdf'),
    ('cypress_station_square_houston_tx_2026','Pollo Campero','130','2,751','2017-07-01','2032-06-30','$8,250 current','$99,000 current',NULL,'Ground Lease','Rent increases and four renewal options through 2052','texas-cypress-station-square.pdf'),
    ('cypress_station_square_houston_tx_2026','Rent A Tire, L.P.','16','3,882','2008-07-25','2028-10-31','$7,563.43','$90,761.16','$23.38','NNN','Option 11/1/2028-10/31/2033; CAM increase cap noted','texas-cypress-station-square.pdf'),
    ('cypress_station_square_houston_tx_2026','20/20 Mobile Corp','24','1,100','N/A','2027-10-31','$1,784.75','$21,417.00','$19.47','Modified Gross','No option shown','texas-cypress-station-square.pdf'),
    ('cypress_station_square_houston_tx_2026','J & L Precision Kutz and Styles','30','1,100','2022-09-01','2027-08-31','$1,833.33 current','$21,999.96 current','$20.00','NNN','Option 9/1/2027-8/31/2032; controllable CAM costs capped at 5% annual increase','texas-cypress-station-square.pdf'),
    ('cypress_station_square_houston_tx_2026','Gloss Society Nail Spa','32','1,100',NULL,NULL,'$1,530.83 initial','$18,370 initial','$16.70','NNN','Rent increases through month 60','texas-cypress-station-square.pdf'),
    ('cypress_station_square_houston_tx_2026','VACANT','38','2,475',NULL,NULL,NULL,NULL,NULL,'Vacant','Pro forma assumes lease at $18/SF base rent plus NNN','texas-cypress-station-square.pdf'),
    ('cypress_station_square_houston_tx_2026','Wabash, Ltd.','40','1,100','2016-02-01','2031-01-31','$2,245.83 current','$26,949.96 current','$24.50','NNN','Scheduled increases through 2031','texas-cypress-station-square.pdf'),
    ('cypress_station_square_houston_tx_2026','VACANT','44','2,575',NULL,NULL,NULL,NULL,NULL,'Vacant','Pro forma assumes lease at $18/SF base rent plus NNN','texas-cypress-station-square.pdf'),
    ('cypress_station_square_houston_tx_2026','VACANT','46','1,425',NULL,NULL,NULL,NULL,NULL,'Vacant','Pro forma assumes lease at $20/SF base rent plus NNN','texas-cypress-station-square.pdf'),
    ('cypress_station_square_houston_tx_2026','VACANT','48','2,438',NULL,NULL,NULL,NULL,NULL,'Vacant','Pro forma assumes lease at $18/SF base rent plus NNN','texas-cypress-station-square.pdf'),
    ('cypress_station_square_houston_tx_2026','Milan College','70','31,622','2024-05-22','2032-01-31','$36,892.33','$442,707.96','$14.00','NNN','Major tenant; lease expiration January 2032','texas-cypress-station-square.pdf'),
    ('cypress_station_square_houston_tx_2026','Workforce Solutions','70A','23,500','2024-10-01','2029-06-30','$38,677.08','$464,124.96','$19.75','NNN','Tenant commenced in 2018; option 7/1/2029-6/30/2034 at fair market value','texas-cypress-station-square.pdf'),
    ('cypress_station_square_houston_tx_2026','Houston Kidney Center (DaVita)','72','13,744','2013-01-23','2028-01-31','$11,453.33','$137,439.96','$10.00','NNN','Rent increase 2/1/2028; two renewal options; CAM cap noted','texas-cypress-station-square.pdf'),
    ('cypress_station_square_houston_tx_2026','Hibbett Sports','76','6,400','2024-05-14','2029-10-31','$7,466.67','$89,600.00','$14.00','NNN','Rent increases and three renewal options through 2049','texas-cypress-station-square.pdf'),
    ('cypress_station_square_houston_tx_2026','Dollar Tree Stores','90','9,450','2020-08-01','2030-07-31','$7,481.25','$89,775.00','$9.50','NNN','Exercised option through 2030; tenant cannot be charged management fee; CAM cap noted','texas-cypress-station-square.pdf'),
    ('cypress_station_square_houston_tx_2026','Texas High School for Accelerated Learning','94','11,300','2027-08-01',NULL,'$14,125 year 3','$169,500 year 3','$15.00','NNN','2 x 5-year renewal options; one-time termination right tied to charter loss after month 84 with penalty','texas-cypress-station-square.pdf'),
    ('cypress_station_square_houston_tx_2026','GNC','96','1,600','1993-09-23','2026-10-31','$1,733.00','$20,796.00','$13.00','NNN','Lease expiration October 2026','texas-cypress-station-square.pdf'),
    ('cypress_station_square_houston_tx_2026','ATM Bank of America','ATM','100','2018-11-14','2028-11-30','$1,870.00','$22,440.00',NULL,'NNN','Two renewal options through 2038','texas-cypress-station-square.pdf'),
    ('cypress_station_square_houston_tx_2026','Flor Medica LLC','26','825','2024-12-01','2027-01-31','$1,031.25','$12,375.00','$15.00',NULL,'No option shown','texas-cypress-station-square.pdf'),
    ('cypress_station_square_houston_tx_2026','Core Personnel Staffing Services','28','1,100','2024-01-22','2027-04-21','$1,466.67','$17,600.04','$16.00','NNN','Three renewal options through 2036','texas-cypress-station-square.pdf'),
    ('cypress_station_square_houston_tx_2026','VACANT','84','2,776',NULL,NULL,NULL,NULL,NULL,'Vacant','Pro forma assumes lease at $18/SF base rent plus NNN','texas-cypress-station-square.pdf')
) AS data(property_id, tenant_name, suite, sf, lease_start, lease_end, monthly_rent, annual_rent, rent_psf, lease_type, renewal_options, source_pdf)
WHERE NOT EXISTS (
    SELECT 1 FROM public.rent_rolls r
    WHERE r.property_id = data.property_id
      AND r.tenant_name = data.tenant_name
      AND r.suite = data.suite
);

INSERT INTO public.tenants (
    property_id, tenant, suite, monthly_rent, annual_rent,
    lease_start, lease_end, options, occupancy_status
)
SELECT * FROM (VALUES
    (-2647658::bigint,'C & C Dining, Inc. (Cilantro Cocina)','10',8865::numeric,106380::numeric,'2015-12-01'::date,'2031-02-28'::date,'Rent increases through 2031','occupied'),
    (-2647658::bigint,'VACANT','102',NULL::numeric,NULL::numeric,NULL::date,NULL::date,'Pro forma lease-up at $20/SF plus NNN','vacant'),
    (-2647658::bigint,'FSAF Investment Inc. (Car Stereo Max)','110',5000::numeric,60000::numeric,'2019-12-01'::date,'2029-04-30'::date,'Modified gross risk; scheduled increases','occupied'),
    (-2647658::bigint,'Trakas Sports Cantina','120',12565::numeric,150780::numeric,NULL::date,NULL::date,'2 x 5-year renewal options; lease dates shown by months in OM','occupied'),
    (-2647658::bigint,'Lisa Jackson (Daiquiriz With A Twist)','124',3501.36::numeric,42016.32::numeric,'2019-03-13'::date,'2029-03-31'::date,'Gross lease with scheduled increases','occupied'),
    (-2647658::bigint,'Pollo Campero','130',8250::numeric,99000::numeric,'2017-07-01'::date,'2032-06-30'::date,'Ground lease; options through 2052','occupied'),
    (-2647658::bigint,'Rent A Tire, L.P.','16',7563.43::numeric,90761.16::numeric,'2008-07-25'::date,'2028-10-31'::date,'Option through 2033; CAM cap','occupied'),
    (-2647658::bigint,'20/20 Mobile Corp','24',1784.75::numeric,21417::numeric,NULL::date,'2027-10-31'::date,'No start date shown','occupied'),
    (-2647658::bigint,'J & L Precision Kutz and Styles','30',1833.33::numeric,21999.96::numeric,'2022-09-01'::date,'2027-08-31'::date,'Option through 2032; CAM cap','occupied'),
    (-2647658::bigint,'Gloss Society Nail Spa','32',1530.83::numeric,18370::numeric,NULL::date,NULL::date,'Rent schedule by lease month, no calendar dates shown','occupied'),
    (-2647658::bigint,'VACANT','38',NULL::numeric,NULL::numeric,NULL::date,NULL::date,'Pro forma lease-up at $18/SF plus NNN','vacant'),
    (-2647658::bigint,'Wabash, Ltd.','40',2245.83::numeric,26949.96::numeric,'2016-02-01'::date,'2031-01-31'::date,'Scheduled increases through 2031','occupied'),
    (-2647658::bigint,'VACANT','44',NULL::numeric,NULL::numeric,NULL::date,NULL::date,'Pro forma lease-up at $18/SF plus NNN','vacant'),
    (-2647658::bigint,'VACANT','46',NULL::numeric,NULL::numeric,NULL::date,NULL::date,'Pro forma lease-up at $20/SF plus NNN','vacant'),
    (-2647658::bigint,'VACANT','48',NULL::numeric,NULL::numeric,NULL::date,NULL::date,'Pro forma lease-up at $18/SF plus NNN','vacant'),
    (-2647658::bigint,'Milan College','70',36892.33::numeric,442707.96::numeric,'2024-05-22'::date,'2032-01-31'::date,'Major tenant','occupied'),
    (-2647658::bigint,'Workforce Solutions','70A',38677.08::numeric,464124.96::numeric,'2024-10-01'::date,'2029-06-30'::date,'Option at FMV through 2034','occupied'),
    (-2647658::bigint,'Houston Kidney Center (DaVita)','72',11453.33::numeric,137439.96::numeric,'2013-01-23'::date,'2028-01-31'::date,'CAM cap; options through 2043','occupied'),
    (-2647658::bigint,'Hibbett Sports','76',7466.67::numeric,89600::numeric,'2024-05-14'::date,'2029-10-31'::date,'Options through 2049','occupied'),
    (-2647658::bigint,'Dollar Tree Stores','90',7481.25::numeric,89775::numeric,'2020-08-01'::date,'2030-07-31'::date,'Exercised option; management fee exclusion and CAM cap','occupied'),
    (-2647658::bigint,'Texas High School for Accelerated Learning','94',14125::numeric,169500::numeric,'2027-08-01'::date,NULL::date,'Termination right tied to charter loss after month 84','occupied'),
    (-2647658::bigint,'GNC','96',1733::numeric,20796::numeric,'1993-09-23'::date,'2026-10-31'::date,'Near-term expiration','occupied'),
    (-2647658::bigint,'ATM Bank of America','ATM',1870::numeric,22440::numeric,'2018-11-14'::date,'2028-11-30'::date,'Options through 2038','occupied'),
    (-2647658::bigint,'Flor Medica LLC','26',1031.25::numeric,12375::numeric,'2024-12-01'::date,'2027-01-31'::date,'No option shown','occupied'),
    (-2647658::bigint,'Core Personnel Staffing Services','28',1466.67::numeric,17600.04::numeric,'2024-01-22'::date,'2027-04-21'::date,'Options through 2036','occupied'),
    (-2647658::bigint,'VACANT','84',NULL::numeric,NULL::numeric,NULL::date,NULL::date,'Pro forma lease-up at $18/SF plus NNN','vacant')
) AS data(property_id, tenant, suite, monthly_rent, annual_rent, lease_start, lease_end, options, occupancy_status)
WHERE NOT EXISTS (
    SELECT 1 FROM public.tenants t
    WHERE t.property_id = data.property_id
      AND t.tenant = data.tenant
      AND t.suite = data.suite
);

INSERT INTO public.analysis (
    property_id, due_diligence_score, seller_weakness_score,
    acquisition_score, risk_score, upside_score, overall_score,
    recommendation, missing_items, weaknesses
)
SELECT
    -2647658,
    72,
    62,
    84,
    58,
    86,
    78,
    'PURSUE / REQUEST FULL DILIGENCE. Strong current yield at 9.25% with upside to 10.67% pro forma, meaningful NOI, low price per SF, and value-add vacancy. Underwrite carefully because of lease complexity, vacant suites, CAM caps, and older construction.',
    'Executed leases and amendments; current rent roll in Excel; T12; tenant payment ledger; CAM reconciliation; tax bill; insurance and flood policy; roof/HVAC reports; environmental report; vacant suite leasing pipeline; capital expenditure history.',
    '9.23% vacancy; several lease structures and CAM limitations; Texas High School termination right; GNC near-term expiration; older 1986 construction; large center operational complexity.'
WHERE NOT EXISTS (SELECT 1 FROM public.analysis WHERE property_id = -2647658);

INSERT INTO public.committee_reports (property_id, report)
SELECT
    'cypress_station_square_houston_tx_2026',
    '{"decision":"PURSUE / REQUEST FULL DILIGENCE","summary":"Large Houston retail center offered at $21.41M with $1.98M current NOI, 9.25% current cap, 10.67% pro forma cap, 137,565 SF, 12.19 acres, and 90.77% occupancy. Upside is driven by 12,704 vacant SF and below-market rents. Main risks are lease complexity, CAM caps, special termination language, near-term expirations, and older construction.","seller_weakness_items":["9.23% vacancy","Below-market rents create upside but also negotiation leverage","Complex leases and CAM caps require diligence","Older 1986 construction","Pro forma depends on leasing six vacant suites"],"broker_questions":["Please send T12 and current rent roll in Excel.","Please send all executed leases and amendments.","Which vacant suites have active LOIs or tours?","Please provide CAM reconciliation history.","Please provide roof/HVAC condition and warranty details.","Are all tenants current on rent?","Explain tenant reimbursements for modified gross and gross lease tenants.","Confirm Texas High School termination language and charter status.","Provide tax, insurance, and flood premium backup."]}'::jsonb
WHERE NOT EXISTS (
    SELECT 1 FROM public.committee_reports WHERE property_id = 'cypress_station_square_houston_tx_2026'
);

INSERT INTO public.acquisition_decisions (property_id, decision)
SELECT
    'cypress_station_square_houston_tx_2026',
    '{"decision":"PURSUE / REQUEST FULL DILIGENCE","next_action":"Request T12, current rent roll in Excel, executed leases, CAM reconciliation, tenant ledger, tax bills, insurance/flood policy, roof/HVAC detail, environmental report, and vacant suite leasing pipeline.","offer_posture":"Strong candidate from the first 20 list. Do not price off pro forma until vacancy assumptions and lease economics are verified."}'::jsonb
WHERE NOT EXISTS (
    SELECT 1 FROM public.acquisition_decisions WHERE property_id = 'cypress_station_square_houston_tx_2026'
);

-- ---------------------------------------------------------------------------
-- Point West Center
-- ---------------------------------------------------------------------------

INSERT INTO public.properties (
    property_id, property_name, address, property_type, asking_price, noi,
    cap_rate, occupancy, building_sf, land_sf, year_built, broker_name,
    broker_email, broker_phone, source_pdf, major_risks, missing_information,
    unit_count, value_add, extraction_confidence
)
SELECT
    'point_west_center_houston_tx_2026',
    'Point West Center',
    '5700 S. Gessner Dr., Houston, TX 77036',
    'Grocery-anchored retail center',
    '$12,750,000',
    '$983,053.59',
    '7.71%',
    '100%',
    '80,527 SF',
    '240,730 SF',
    '1979 / renovated 2019',
    'Todd Carlson',
    'todd@hpiproperties.com',
    '713-623-6944',
    'texas-point-west-center.pdf',
    '["Flyer does not include rent roll or tenant-level lease schedule","NOI differs from Crexi export figure and should be reconciled","Older 1979 construction despite 2019 renovation","Need to verify grocery anchor lease term and credit","Need roof scope backup even though flyer mentions new roof excluding anchor and pad"]'::jsonb,
    '["Rent roll","T12 operating statement","Executed leases and amendments","Anchor grocery lease","Tenant sales if available","Tax bill","Insurance quote or policy","CAM reconciliation","Roof warranty and scope","Environmental report","Tenant payment history","Reason for sale"]'::jsonb,
    NULL,
    true,
    82
WHERE NOT EXISTS (
    SELECT 1 FROM public.properties
    WHERE property_id = 'point_west_center_houston_tx_2026'
       OR address = '5700 S. Gessner Dr., Houston, TX 77036'
);

INSERT INTO public.documents (property_id, file_name, file_type, drive_file_id, processed_at, status)
SELECT -1916802, 'texas-point-west-center.pdf', 'offering_flyer_pdf', NULL, now(), 'processed'
WHERE NOT EXISTS (
    SELECT 1 FROM public.documents
    WHERE property_id = -1916802 AND file_name = 'texas-point-west-center.pdf'
);

INSERT INTO public.brokers (property_id, broker_name, broker_company, broker_email, broker_phone)
SELECT -1916802, 'Todd Carlson', 'Hunington Properties, Inc.', 'todd@hpiproperties.com', '713-623-6944'
WHERE NOT EXISTS (
    SELECT 1 FROM public.brokers
    WHERE property_id = -1916802 AND broker_email = 'todd@hpiproperties.com'
);

INSERT INTO public.financial_reports (
    property_id, rental_income, recoveries, gross_income, total_expenses,
    noi, cap_rate, occupancy, source_pdf, confidence, raw_json
)
SELECT
    'point_west_center_houston_tx_2026',
    NULL,
    NULL,
    NULL,
    NULL,
    '$983,053.59',
    '7.71%',
    '100%',
    'texas-point-west-center.pdf',
    65,
    '{"asking_price":12750000,"noi":983053.59,"cap_rate_pct":7.71,"net_rentable_area_sf":80527,"lot_size_sf":240730,"occupancy_pct":100,"year_built":"1979/2019","traffic_counts":{"s_gessner_rd_vpd":17805,"harwin_dr_vpd":8684},"demographics":{"population_2026":{"1_mile":35538,"3_miles":237978,"5_miles":584656},"average_hhi":{"1_mile":58600,"3_miles":85877,"5_miles":111064}},"highlights":["Grocery anchored center with long-term lease","High traffic signalized intersection","New roof on retail center excluding anchor and pad","Below market rents"]}'::jsonb
WHERE NOT EXISTS (
    SELECT 1 FROM public.financial_reports
    WHERE property_id = 'point_west_center_houston_tx_2026'
      AND source_pdf = 'texas-point-west-center.pdf'
);

INSERT INTO public.analysis (
    property_id, due_diligence_score, seller_weakness_score,
    acquisition_score, risk_score, upside_score, overall_score,
    recommendation, missing_items, weaknesses
)
SELECT
    -1916802,
    48,
    42,
    68,
    54,
    62,
    61,
    'REQUEST MORE INFO. Good 100% occupied grocery-anchored center with 7.71% cap and below-market rent upside, but the PDF is a short flyer and does not provide rent roll, T12, lease abstracts, or tenant-level detail.',
    'Rent roll; T12; executed leases and amendments; anchor lease; tax bill; insurance; CAM reconciliation; roof warranty; environmental report; tenant payment history; reason for sale.',
    'Limited flyer data; no tenant-level rent roll; older 1979 construction; verify grocery anchor lease; reconcile NOI against export; verify new roof scope excluding anchor and pad.'
WHERE NOT EXISTS (SELECT 1 FROM public.analysis WHERE property_id = -1916802);

INSERT INTO public.committee_reports (property_id, report)
SELECT
    'point_west_center_houston_tx_2026',
    '{"decision":"REQUEST MORE INFO","summary":"Point West Center is a 100% occupied grocery-anchored Houston retail center offered at $12.75M, $983,053.59 NOI, and 7.71% cap. The flyer highlights below-market rents, signalized traffic, and a new roof on the retail center excluding anchor and pad. The package is thin and requires rent roll, T12, and leases before underwriting.","broker_questions":["Please send current rent roll in Excel.","Please send T12 operating statement.","Please send all executed leases and amendments, especially the grocery anchor lease.","Confirm why NOI differs from the Crexi export number if applicable.","Please provide tax and insurance backup.","Please provide CAM reconciliation history.","Please provide roof warranty and roof scope, including anchor and pad exclusions.","Are all tenants current on rent?","What is the reason for sale?"]}'::jsonb
WHERE NOT EXISTS (
    SELECT 1 FROM public.committee_reports WHERE property_id = 'point_west_center_houston_tx_2026'
);

INSERT INTO public.acquisition_decisions (property_id, decision)
SELECT
    'point_west_center_houston_tx_2026',
    '{"decision":"REQUEST MORE INFO","next_action":"Ask Todd Carlson for rent roll, T12, executed leases, anchor lease, tax/insurance backup, CAM reconciliation, roof warranty/scope, tenant payment history, and reason for sale.","offer_posture":"Potentially interesting grocery-anchored center, but do not make a serious offer from the flyer alone."}'::jsonb
WHERE NOT EXISTS (
    SELECT 1 FROM public.acquisition_decisions WHERE property_id = 'point_west_center_houston_tx_2026'
);

COMMIT;
