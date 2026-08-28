-- AW Plaza, Clearwood Crossing, and Meadow III Retail.
-- Idempotent, insert-only seed data for the existing production schema.

BEGIN;

-- AW Plaza
INSERT INTO public.properties (
  property_id, property_name, address, property_type, asking_price, noi,
  cap_rate, occupancy, building_sf, land_sf, year_built, broker_name,
  broker_email, broker_phone, source_pdf, major_risks, missing_information,
  estimated_arv, unit_count, opportunity_zone, value_add, extraction_confidence
)
SELECT
  'aw_plaza_houston_tx_2026', 'AW Plaza',
  '13660 Westheimer Rd, Houston, TX 77077', 'Neighborhood retail center',
  '$3,300,000', '$234,402 current / $309,790 Year 1 pro forma',
  '7.1% current / 9.39% Year 1 pro forma', '83.1%',
  '15,824 SF offering summary; 15,995 SF rent roll', '47,045 SF (1.08 acres)',
  '1980', 'Ryan DeGennaro', 'ryan.degennaro@partnersrealestate.com',
  '713-316-7059', 'AW Plaza - Retail Center.pdf',
  to_jsonb(ARRAY[
    'One 2,700 SF suite is vacant, representing 16.9% of GLA',
    'Foot Spa is month-to-month',
    'P&A Complete Auto Repair pays materially below the other shop rents',
    'Building area differs between the offering summary and rent roll',
    'Property was built in 1980 and the OM identifies 100-year flood risk',
    'Year 1 return depends on leasing the vacancy and renewing Foot Spa'
  ]::text[]),
  to_jsonb(ARRAY[
    'Trailing-12-month operating statement and general ledger',
    'Executed leases, amendments, guaranties, options, and estoppels',
    'Tenant payment history, deposits, and financial statements',
    'Vacant-suite leasing proposal, TI and commission obligations',
    'Roof, HVAC, structure, parking, environmental, and flood documentation',
    'Current tax bill, insurance policy, and CAM reconciliations',
    'Billboard lease and permit documentation',
    'Reconciliation of 15,824 SF offering area to 15,995 SF rent roll'
  ]::text[]),
  'Year 1 pro forma value is $3,300,000 at a 9.39% cap; current NOI supports the asking price at approximately 7.10%',
  6, NULL, true, 94
WHERE NOT EXISTS (
  SELECT 1 FROM public.properties WHERE property_id = 'aw_plaza_houston_tx_2026'
);

INSERT INTO public.documents (property_id, file_name, file_type, drive_file_id, processed_at, status)
SELECT -1967068965, 'AW Plaza - Retail Center.pdf', 'application/pdf',
  'offering-memorandums/AW Plaza - Retail Center.pdf', now(), 'processed'
WHERE NOT EXISTS (
  SELECT 1 FROM public.documents WHERE property_id = -1967068965
    AND file_name = 'AW Plaza - Retail Center.pdf'
);

INSERT INTO public.brokers (property_id, broker_name, broker_company, broker_email, broker_phone)
SELECT -1967068965, 'Ryan DeGennaro', 'Partners Real Estate',
  'ryan.degennaro@partnersrealestate.com', '713-316-7059'
WHERE NOT EXISTS (
  SELECT 1 FROM public.brokers WHERE property_id = -1967068965
    AND broker_email = 'ryan.degennaro@partnersrealestate.com'
);

INSERT INTO public.financial_reports (
  property_id, rental_income, recoveries, other_income, gross_income, taxes,
  insurance, cam, utilities, management_fee, total_expenses, noi, cap_rate,
  occupancy, source_pdf, confidence, raw_json
)
SELECT
  'aw_plaza_houston_tx_2026', '$248,592', '$69,773', '$18,000 billboard included in rental income',
  '$318,365', '$36,644', '$19,054', '$20,712 repairs/grounds/dumpster',
  '$6,936', '$0 current / $11,530 Year 1', '$83,963', '$234,402',
  '7.10% calculated current / 9.39% Year 1 pro forma', '83.1%',
  'AW Plaza - Retail Center.pdf', 94,
  jsonb_build_object(
    'current', jsonb_build_object('base_rent',248592,'recoveries',69773,'effective_gross_revenue',318365,'expenses',83963,'noi',234402),
    'year_1_pro_forma', jsonb_build_object('base_rent',309790,'recoveries',97159,'effective_gross_revenue',406949,'expenses',97159,'noi',309790),
    'financing', jsonb_build_object('loan_amount',2145000,'interest_rate_pct',6.5,'amortization_years',25,'debt_service',173798,'dscr',1.78),
    'assumptions', to_jsonb(ARRAY['Foot Spa renews at a 5% increase','Vacant suite leases at $20/SF','Expenses grow 2% annually']::text[])
  )
WHERE NOT EXISTS (
  SELECT 1 FROM public.financial_reports WHERE property_id = 'aw_plaza_houston_tx_2026'
    AND source_pdf = 'AW Plaza - Retail Center.pdf'
);

INSERT INTO public.rent_rolls (
  property_id, tenant_name, suite, sf, lease_start, lease_end, monthly_rent,
  annual_rent, rent_psf, lease_type, renewal_options, source_pdf
)
SELECT * FROM (VALUES
  ('aw_plaza_houston_tx_2026','The Fade Away Barber Shop & Lounge','13660','4,888','2024-12-15','2029-12-15','$9,500','$114,000','$23.32','NNN','None stated','AW Plaza - Retail Center.pdf'),
  ('aw_plaza_houston_tx_2026','Vacant','13662','2,700',NULL,NULL,'$0','$0','$0','NNN','Vacant suite','AW Plaza - Retail Center.pdf'),
  ('aw_plaza_houston_tx_2026','Flower Deli','13666','1,473','2023-08-01','2028-08-01','$2,450','$29,400','$19.96','NNN','One 5-year option at market rent','AW Plaza - Retail Center.pdf'),
  ('aw_plaza_houston_tx_2026','Foot Spa','13668','1,500',NULL,NULL,'$2,550','$30,600','$20.40','NNN','Month-to-month; tenant reportedly willing to extend','AW Plaza - Retail Center.pdf'),
  ('aw_plaza_houston_tx_2026','P&A Complete Auto Repair','13670','5,434','2024-08-01','2029-09-01','$4,716','$56,592','$10.41','NNN','One 5-year option at market rent','AW Plaza - Retail Center.pdf'),
  ('aw_plaza_houston_tx_2026','Billboard','Billboard','0','2021-06-01','2031-06-01','$1,500','$18,000','$0','Gross','None stated','AW Plaza - Retail Center.pdf')
) AS v(property_id,tenant_name,suite,sf,lease_start,lease_end,monthly_rent,annual_rent,rent_psf,lease_type,renewal_options,source_pdf)
WHERE NOT EXISTS (
  SELECT 1 FROM public.rent_rolls r WHERE r.property_id = v.property_id
    AND r.tenant_name = v.tenant_name AND r.suite = v.suite
);

INSERT INTO public.tenants (
  property_id, tenant, suite, monthly_rent, annual_rent, lease_start, lease_end,
  options, occupancy_status
)
SELECT * FROM (VALUES
  (-1967068965::bigint,'The Fade Away Barber Shop & Lounge','13660',9500::numeric,114000::numeric,DATE '2024-12-15',DATE '2029-12-15','None stated','occupied'),
  (-1967068965::bigint,'Vacant','13662',0::numeric,0::numeric,NULL::date,NULL::date,'Vacant suite','vacant'),
  (-1967068965::bigint,'Flower Deli','13666',2450::numeric,29400::numeric,DATE '2023-08-01',DATE '2028-08-01','One 5-year option at market rent','occupied'),
  (-1967068965::bigint,'Foot Spa','13668',2550::numeric,30600::numeric,NULL::date,NULL::date,'Month-to-month','occupied'),
  (-1967068965::bigint,'P&A Complete Auto Repair','13670',4716::numeric,56592::numeric,DATE '2024-08-01',DATE '2029-09-01','One 5-year option at market rent','occupied'),
  (-1967068965::bigint,'Billboard','Billboard',1500::numeric,18000::numeric,DATE '2021-06-01',DATE '2031-06-01','None stated','occupied')
) AS v(property_id,tenant,suite,monthly_rent,annual_rent,lease_start,lease_end,options,occupancy_status)
WHERE NOT EXISTS (
  SELECT 1 FROM public.tenants t WHERE t.property_id = v.property_id
    AND t.tenant = v.tenant AND t.suite = v.suite
);

INSERT INTO public.analysis (
  property_id, due_diligence_score, seller_weakness_score, acquisition_score,
  risk_score, upside_score, overall_score, recommendation, missing_items, weaknesses
)
SELECT -1967068965, 70, 72, 72, 58, 84, 72,
  'PURSUE SUBJECT TO LEASING AND PROPERTY-CONDITION DILIGENCE',
  'T12; leases and estoppels; vacant-suite economics; tenant payment history; tax, insurance and CAM support; property condition; flood and environmental records; billboard documents; area reconciliation',
  '16.9% vacancy; month-to-month tenant; older 1980 construction; flood-zone disclosure; below-market auto-repair rent; pro forma depends on lease-up'
WHERE NOT EXISTS (SELECT 1 FROM public.analysis WHERE property_id = -1967068965);

INSERT INTO public.committee_reports (property_id, report)
SELECT 'aw_plaza_houston_tx_2026', jsonb_build_object(
  'decision','PURSUE / REQUEST MORE INFORMATION',
  'summary','Value-add Westheimer retail center with current 7.10% cap, 16.9% vacancy, a month-to-month tenant, and a pro forma 9.39% cap after lease-up.',
  'strengths',to_jsonb(ARRAY['Hard-corner Westheimer location','NNN shop leases','Billboard income through 2031','Lease-up and mark-to-market upside']::text[]),
  'red_flags',to_jsonb(ARRAY['Vacant 2,700 SF suite','Foot Spa is month-to-month','1980 construction and flood disclosure','Area discrepancy in OM','Pro forma relies on leasing assumptions']::text[]),
  'valuation',jsonb_build_object('asking_price',3300000,'current_noi',234402,'current_cap_pct',7.103,'year_1_noi',309790,'year_1_cap_pct',9.39),
  'broker_questions',to_jsonb(ARRAY['Send the T12 and general ledger.','Send every lease, amendment, guaranty, option, and estoppel.','What TI and commissions are required for the vacant suite?','Will Foot Spa sign an extension before closing?','Explain the 15,824 SF versus 15,995 SF discrepancy.','Provide roof, HVAC, parking, environmental, and flood records.','Provide the billboard lease and permit.','Why is the seller selling?']::text[])
)
WHERE NOT EXISTS (SELECT 1 FROM public.committee_reports WHERE property_id = 'aw_plaza_houston_tx_2026');

INSERT INTO public.acquisition_decisions (property_id, decision)
SELECT 'aw_plaza_houston_tx_2026', jsonb_build_object(
  'decision','PURSUE / REQUEST MORE INFORMATION',
  'next_action','Underwrite current cash flow, confirm lease-up costs, and complete physical and flood diligence before LOI.',
  'suggested_offer_framework','Price to current NOI and verified lease-up costs; do not pay the full pro forma value without executed leases.',
  'broker_questions',to_jsonb(ARRAY['Provide T12 and rent collections.','Provide executed lease documents and estoppels.','Confirm seller motivation and vacant-suite leasing status.']::text[])
)
WHERE NOT EXISTS (SELECT 1 FROM public.acquisition_decisions WHERE property_id = 'aw_plaza_houston_tx_2026');

-- Clearwood Crossing
INSERT INTO public.properties (
  property_id, property_name, address, property_type, asking_price, noi,
  cap_rate, occupancy, building_sf, land_sf, year_built, broker_name,
  broker_email, broker_phone, source_pdf, major_risks, missing_information,
  estimated_arv, unit_count, opportunity_zone, value_add, extraction_confidence
)
SELECT
  'clearwood_crossing_houston_tx_2026', 'Clearwood Crossing',
  '10404 Gulf Fwy, Houston, TX', 'Family-focused multi-tenant retail strip',
  '$5,205,000', '$379,565', '7.29%', '100%', '15,763 SF',
  '1.35 acres (approximately 58,806 SF)', '2016', 'Matt Nega',
  'matt@monarchcommercial.com', '925-430-5787', 'Clearwood Crossing.pdf',
  to_jsonb(ARRAY[
    'Kids Empire occupies 66.43% of GLA and base rent',
    'The suite 400 lease is shown as pending with commencement tied to close of escrow',
    'La Monarca expires in June 2027 with no options',
    'Scheduled recoveries exactly offset all stated expenses and require verification',
    'Kids Empire ownership and financial-strength claims are not supported by tenant financial statements in the OM'
  ]::text[]),
  to_jsonb(ARRAY[
    'Executed suite 400 lease and commencement evidence',
    'Trailing-12-month operating statement, general ledger, and recovery reconciliations',
    'All leases, amendments, guaranties, options, and estoppels',
    'Tenant payment histories and financial statements',
    'Property tax bills, insurance policy, and CAM detail',
    'Roof, HVAC, concrete parking, environmental, survey, title, and warranty reports',
    'Seller motivation and debt information'
  ]::text[]),
  'Asking price $5,205,000 at 7.29%; OM also shows $5,145,000 at 7.40% Strive pricing',
  5, NULL, false, 96
WHERE NOT EXISTS (
  SELECT 1 FROM public.properties WHERE property_id = 'clearwood_crossing_houston_tx_2026'
);

INSERT INTO public.documents (property_id, file_name, file_type, drive_file_id, processed_at, status)
SELECT -283411823, 'Clearwood Crossing.pdf', 'application/pdf',
  'offering-memorandums/Clearwood Crossing.pdf', now(), 'processed'
WHERE NOT EXISTS (
  SELECT 1 FROM public.documents WHERE property_id = -283411823
    AND file_name = 'Clearwood Crossing.pdf'
);

INSERT INTO public.brokers (property_id, broker_name, broker_company, broker_email, broker_phone)
SELECT * FROM (VALUES
  (-283411823::bigint,'Matt Nega','Monarch Commercial Advisors','matt@monarchcommercial.com','925-430-5787'),
  (-283411823::bigint,'Dave Lucas','Monarch Commercial Advisors','dave@monarchcommercial.com','925-744-5217'),
  (-283411823::bigint,'Scott Reid','ParaSell, Inc.','scott@parasellinc.com','949-942-6585')
) AS v(property_id,broker_name,broker_company,broker_email,broker_phone)
WHERE NOT EXISTS (
  SELECT 1 FROM public.brokers b WHERE b.property_id = v.property_id
    AND b.broker_email = v.broker_email
);

INSERT INTO public.financial_reports (
  property_id, rental_income, recoveries, other_income, gross_income, taxes,
  insurance, cam, utilities, management_fee, total_expenses, noi, cap_rate,
  occupancy, source_pdf, confidence, raw_json
)
SELECT
  'clearwood_crossing_houston_tx_2026', '$379,565', '$145,482', '$0', '$525,047',
  '$66,388', '$15,765', '$63,329 CAM/management', '$0 stated',
  'Included in CAM/management', '$145,482', '$379,565', '7.29%', '100%',
  'Clearwood Crossing.pdf', 96,
  jsonb_build_object(
    'price_per_sf',330.20,'scheduled_rent_psf',24.08,'recoveries_psf',9.23,
    'expenses_psf',9.23,'proposed_loan_amount',3435300,'ltv_pct',66,
    'interest_rate_pct',6.13,'amortization_years',30,'term_years',5,
    'debt_service',250479,'dscr',1.52,'cash_on_cash_pct',7.29,
    'alternate_pricing',jsonb_build_object('price',5145000,'cap_rate_pct',7.40,'noi',380730)
  )
WHERE NOT EXISTS (
  SELECT 1 FROM public.financial_reports WHERE property_id = 'clearwood_crossing_houston_tx_2026'
    AND source_pdf = 'Clearwood Crossing.pdf'
);

INSERT INTO public.rent_rolls (
  property_id, tenant_name, suite, sf, lease_start, lease_end, monthly_rent,
  annual_rent, rent_psf, lease_type, renewal_options, source_pdf
)
SELECT * FROM (VALUES
  ('clearwood_crossing_houston_tx_2026','Little Caesars Pizza','100','1,618','2017-03-29','2032-03-31','$4,530','$54,365','$33.60','NNN; corporate guarantee','12% increase in 2027; one option through 2037','Clearwood Crossing.pdf'),
  ('clearwood_crossing_houston_tx_2026','La Monarca Michoacana','200','1,470','2017-06-10','2027-06-30','$3,463','$41,557','$28.27','NNN; regional company','No options','Clearwood Crossing.pdf'),
  ('clearwood_crossing_houston_tx_2026','World Finance','300','1,134','2021-01-18','2029-01-31','$2,300','$27,602','$24.34','NNN; corporate guarantee','No options','Clearwood Crossing.pdf'),
  ('clearwood_crossing_houston_tx_2026','Lease Pending','400','1,070',NULL,NULL,'$2,140','$25,680','$24.00','NNN; master lease','One year from close of escrow; executed status must be verified','Clearwood Crossing.pdf'),
  ('clearwood_crossing_houston_tx_2026','Kids Empire','500','10,471','2023-10-01','2034-01-31','$19,197','$230,362','$22.00','NNN; corporate guarantee','10% increase in 2029; two 5-year options','Clearwood Crossing.pdf')
) AS v(property_id,tenant_name,suite,sf,lease_start,lease_end,monthly_rent,annual_rent,rent_psf,lease_type,renewal_options,source_pdf)
WHERE NOT EXISTS (
  SELECT 1 FROM public.rent_rolls r WHERE r.property_id = v.property_id
    AND r.tenant_name = v.tenant_name AND r.suite = v.suite
);

INSERT INTO public.tenants (
  property_id, tenant, suite, monthly_rent, annual_rent, lease_start, lease_end,
  options, occupancy_status
)
SELECT * FROM (VALUES
  (-283411823::bigint,'Little Caesars Pizza','100',4530::numeric,54365::numeric,DATE '2017-03-29',DATE '2032-03-31','12% increase in 2027; one option through 2037','occupied'),
  (-283411823::bigint,'La Monarca Michoacana','200',3463::numeric,41557::numeric,DATE '2017-06-10',DATE '2027-06-30','No options','occupied'),
  (-283411823::bigint,'World Finance','300',2300::numeric,27602::numeric,DATE '2021-01-18',DATE '2029-01-31','No options','occupied'),
  (-283411823::bigint,'Lease Pending','400',2140::numeric,25680::numeric,NULL::date,NULL::date,'One year from close of escrow; verify execution','lease_pending'),
  (-283411823::bigint,'Kids Empire','500',19197::numeric,230362::numeric,DATE '2023-10-01',DATE '2034-01-31','10% increase in 2029; two 5-year options','occupied')
) AS v(property_id,tenant,suite,monthly_rent,annual_rent,lease_start,lease_end,options,occupancy_status)
WHERE NOT EXISTS (
  SELECT 1 FROM public.tenants t WHERE t.property_id = v.property_id
    AND t.tenant = v.tenant AND t.suite = v.suite
);

INSERT INTO public.analysis (
  property_id, due_diligence_score, seller_weakness_score, acquisition_score,
  risk_score, upside_score, overall_score, recommendation, missing_items, weaknesses
)
SELECT -283411823, 76, 48, 76, 52, 62, 72,
  'PURSUE SUBJECT TO SUITE 400 AND KIDS EMPIRE DILIGENCE',
  'Executed suite 400 lease; T12 and general ledger; recovery reconciliations; leases, guaranties and estoppels; tenant financials; tax and insurance support; property-condition and environmental reports; seller motivation',
  'Kids Empire concentration; suite 400 lease pending; La Monarca 2027 expiration; recoveries equal all expenses; private tenant credit requires verification'
WHERE NOT EXISTS (SELECT 1 FROM public.analysis WHERE property_id = -283411823);

INSERT INTO public.committee_reports (property_id, report)
SELECT 'clearwood_crossing_houston_tx_2026', jsonb_build_object(
  'decision','PURSUE / REQUEST MORE INFORMATION',
  'summary','2016-built, fully leased NNN retail strip at a 7.29% cap with strong tenant synergy, offset by 66.43% Kids Empire concentration and a pending suite 400 lease.',
  'strengths',to_jsonb(ARRAY['100% stated occupancy','All NNN leases','2016 construction and concrete parking','Corporate guarantees on major tenants','Long Kids Empire and Little Caesars terms']::text[]),
  'red_flags',to_jsonb(ARRAY['Kids Empire is 66.43% of GLA','Suite 400 is lease pending','La Monarca expires June 2027','Recoveries exactly match all expenses','Tenant credit claims require documentation']::text[]),
  'valuation',jsonb_build_object('asking_price',5205000,'noi',379565,'cap_rate_pct',7.29,'alternate_price',5145000,'alternate_cap_rate_pct',7.40),
  'broker_questions',to_jsonb(ARRAY['Is the suite 400 lease fully executed and when does rent commence?','Send the T12, general ledger, and CAM reconciliations.','Send all leases, amendments, guaranties, options, and estoppels.','Provide Kids Empire financial statements and payment history.','Has La Monarca discussed renewal?','Provide tax bills, insurance, and property-condition records.','Why is the seller selling?']::text[])
)
WHERE NOT EXISTS (SELECT 1 FROM public.committee_reports WHERE property_id = 'clearwood_crossing_houston_tx_2026');

INSERT INTO public.acquisition_decisions (property_id, decision)
SELECT 'clearwood_crossing_houston_tx_2026', jsonb_build_object(
  'decision','PURSUE / REQUEST MORE INFORMATION',
  'next_action','Confirm suite 400 execution and Kids Empire credit before LOI; audit expense recoveries and tenant collections.',
  'suggested_offer_framework','Underwrite to verified in-place rent and require a closing condition or rent guarantee for suite 400.',
  'broker_questions',to_jsonb(ARRAY['Confirm suite 400 lease status.','Provide Kids Empire credit and lease documents.','Provide T12, collections, and expense reconciliations.']::text[])
)
WHERE NOT EXISTS (SELECT 1 FROM public.acquisition_decisions WHERE property_id = 'clearwood_crossing_houston_tx_2026');

-- Meadow III Retail
INSERT INTO public.properties (
  property_id, property_name, address, property_type, asking_price, noi,
  cap_rate, occupancy, building_sf, land_sf, year_built, broker_name,
  broker_email, broker_phone, source_pdf, major_risks, missing_information,
  estimated_arv, unit_count, opportunity_zone, value_add, extraction_confidence
)
SELECT
  'meadow_iii_retail_richmond_tx_2026', 'Meadow III Retail',
  '7930 West Grand Pkwy, Richmond, TX 77406', 'Multi-tenant retail center',
  '$7,785,357', '$544,975 in-place September 2026', '7.0%', '100%',
  '18,750 SF', '110,207 SF', '2015', 'Daniel Myers',
  'dmyers@apexrealtors.com', '281-339-9888', 'Meadow III Retail.pdf',
  to_jsonb(ARRAY[
    'The flyer provides no rent roll, lease dates, rents, options, or guaranties',
    'The stated NOI is an in-place September 2026 figure and may not represent current collections',
    'Kumo''s Wanderland occupies approximately 51.1% of GLA',
    'No income and expense statement is provided',
    'No tenant-credit, property-condition, environmental, tax, or insurance support is provided'
  ]::text[]),
  to_jsonb(ARRAY[
    'Current rent roll with rents, lease dates, escalations, options, and guaranties',
    'Trailing-12-month operating statement and general ledger',
    'Executed leases, amendments, estoppels, and tenant payment history',
    'Bridge from current NOI to September 2026 in-place NOI',
    'Property taxes, insurance, CAM, management, utilities, and capital expenditures',
    'Roof, HVAC, structure, parking, environmental, survey, title, and warranty reports',
    'Seller motivation, debt, and pending obligations'
  ]::text[]),
  'Asking price $7,785,357 at the stated 7.0% cap on September 2026 NOI of $544,975',
  5, NULL, false, 82
WHERE NOT EXISTS (
  SELECT 1 FROM public.properties WHERE property_id = 'meadow_iii_retail_richmond_tx_2026'
);

INSERT INTO public.documents (property_id, file_name, file_type, drive_file_id, processed_at, status)
SELECT -360294286, 'Meadow III Retail.pdf', 'application/pdf',
  'offering-memorandums/Meadow III Retail.pdf', now(), 'processed'
WHERE NOT EXISTS (
  SELECT 1 FROM public.documents WHERE property_id = -360294286
    AND file_name = 'Meadow III Retail.pdf'
);

INSERT INTO public.brokers (property_id, broker_name, broker_company, broker_email, broker_phone)
SELECT -360294286, 'Daniel Myers', 'Apex Realtors', 'dmyers@apexrealtors.com', '281-339-9888'
WHERE NOT EXISTS (
  SELECT 1 FROM public.brokers WHERE property_id = -360294286
    AND broker_email = 'dmyers@apexrealtors.com'
);

INSERT INTO public.financial_reports (
  property_id, rental_income, recoveries, other_income, gross_income, taxes,
  insurance, cam, utilities, management_fee, total_expenses, noi, cap_rate,
  occupancy, source_pdf, confidence, raw_json
)
SELECT
  'meadow_iii_retail_richmond_tx_2026', NULL, NULL, NULL, NULL, NULL, NULL,
  NULL, NULL, NULL, NULL, '$544,975 in-place September 2026', '7.0%', '100%',
  'Meadow III Retail.pdf', 82,
  jsonb_build_object(
    'asking_price',7785357,'noi',544975,'noi_timing','in-place September 2026',
    'cap_rate_pct',7.0,'building_sf',18750,'lot_sf',110207,
    'price_per_sf',415.22,'traffic_count_vpd',48420,
    'missing','No detailed income, recoveries, operating expenses, rent roll, or debt assumptions in flyer'
  )
WHERE NOT EXISTS (
  SELECT 1 FROM public.financial_reports WHERE property_id = 'meadow_iii_retail_richmond_tx_2026'
    AND source_pdf = 'Meadow III Retail.pdf'
);

INSERT INTO public.rent_rolls (
  property_id, tenant_name, suite, sf, lease_start, lease_end, monthly_rent,
  annual_rent, rent_psf, lease_type, renewal_options, source_pdf
)
SELECT * FROM (VALUES
  ('meadow_iii_retail_richmond_tx_2026','Ramble Creek Grill','Not stated','3,836',NULL,NULL,NULL,NULL,NULL,'Not stated','Not stated','Meadow III Retail.pdf'),
  ('meadow_iii_retail_richmond_tx_2026','Kumo''s Wanderland','Not stated','9,589',NULL,NULL,NULL,NULL,NULL,'Not stated','Not stated','Meadow III Retail.pdf'),
  ('meadow_iii_retail_richmond_tx_2026','N&D Nail Spa','Not stated','2,000',NULL,NULL,NULL,NULL,NULL,'Not stated','Not stated','Meadow III Retail.pdf'),
  ('meadow_iii_retail_richmond_tx_2026','Edible Arrangements','Not stated','1,125',NULL,NULL,NULL,NULL,NULL,'Not stated','Not stated','Meadow III Retail.pdf'),
  ('meadow_iii_retail_richmond_tx_2026','Brooklyn Pizzeria','Not stated','2,200',NULL,NULL,NULL,NULL,NULL,'Not stated','Not stated','Meadow III Retail.pdf')
) AS v(property_id,tenant_name,suite,sf,lease_start,lease_end,monthly_rent,annual_rent,rent_psf,lease_type,renewal_options,source_pdf)
WHERE NOT EXISTS (
  SELECT 1 FROM public.rent_rolls r WHERE r.property_id = v.property_id
    AND r.tenant_name = v.tenant_name
);

INSERT INTO public.tenants (
  property_id, tenant, suite, monthly_rent, annual_rent, lease_start, lease_end,
  options, occupancy_status
)
SELECT * FROM (VALUES
  (-360294286::bigint,'Ramble Creek Grill','Not stated',NULL::numeric,NULL::numeric,NULL::date,NULL::date,'Not stated','occupied'),
  (-360294286::bigint,'Kumo''s Wanderland','Not stated',NULL::numeric,NULL::numeric,NULL::date,NULL::date,'Not stated','occupied'),
  (-360294286::bigint,'N&D Nail Spa','Not stated',NULL::numeric,NULL::numeric,NULL::date,NULL::date,'Not stated','occupied'),
  (-360294286::bigint,'Edible Arrangements','Not stated',NULL::numeric,NULL::numeric,NULL::date,NULL::date,'Not stated','occupied'),
  (-360294286::bigint,'Brooklyn Pizzeria','Not stated',NULL::numeric,NULL::numeric,NULL::date,NULL::date,'Not stated','occupied')
) AS v(property_id,tenant,suite,monthly_rent,annual_rent,lease_start,lease_end,options,occupancy_status)
WHERE NOT EXISTS (
  SELECT 1 FROM public.tenants t WHERE t.property_id = v.property_id
    AND t.tenant = v.tenant
);

INSERT INTO public.analysis (
  property_id, due_diligence_score, seller_weakness_score, acquisition_score,
  risk_score, upside_score, overall_score, recommendation, missing_items, weaknesses
)
SELECT -360294286, 42, 62, 54, 72, 48, 52,
  'HOLD / REQUEST COMPLETE RENT ROLL AND OPERATING HISTORY',
  'Rent roll; leases and estoppels; T12 and general ledger; current-to-September-2026 NOI bridge; tenant credit; taxes, insurance and CAM; property condition; environmental, survey and title; seller motivation',
  'No rent or lease data; forward-dated NOI; Kumo''s Wanderland concentration; no expense detail; no credit or physical-condition support'
WHERE NOT EXISTS (SELECT 1 FROM public.analysis WHERE property_id = -360294286);

INSERT INTO public.committee_reports (property_id, report)
SELECT 'meadow_iii_retail_richmond_tx_2026', jsonb_build_object(
  'decision','HOLD / REQUEST MORE INFORMATION',
  'summary','Fully occupied 2015 retail center offered at a 7.0% cap, but the flyer omits rent, lease, expense, and tenant-credit details and bases NOI on September 2026 in-place operations.',
  'strengths',to_jsonb(ARRAY['100% stated occupancy','2015 construction','Grand Parkway frontage','Five complementary retail tenants','Strong surrounding demographics']::text[]),
  'red_flags',to_jsonb(ARRAY['No detailed rent roll','No lease dates or rents','September 2026 forward NOI','Kumo''s Wanderland is approximately 51.1% of GLA','No income and expense statement']::text[]),
  'valuation',jsonb_build_object('asking_price',7785357,'noi',544975,'cap_rate_pct',7.0,'price_per_sf',415.22),
  'broker_questions',to_jsonb(ARRAY['Send the current rent roll with all lease economics.','Send the T12, general ledger, and current collections.','Explain the bridge to September 2026 NOI.','Send all leases, amendments, guaranties, options, and estoppels.','Provide tenant financials and payment history.','Provide taxes, insurance, CAM, and property-condition records.','Why is the seller selling?']::text[])
)
WHERE NOT EXISTS (SELECT 1 FROM public.committee_reports WHERE property_id = 'meadow_iii_retail_richmond_tx_2026');

INSERT INTO public.acquisition_decisions (property_id, decision)
SELECT 'meadow_iii_retail_richmond_tx_2026', jsonb_build_object(
  'decision','HOLD / REQUEST MORE INFORMATION',
  'next_action','Do not underwrite an offer until current rent, lease terms, collections, expenses, and the September 2026 NOI bridge are documented.',
  'suggested_offer_framework','Value only verified current NOI; do not capitalize a forward NOI without executed leases and collection support.',
  'broker_questions',to_jsonb(ARRAY['Provide full rent roll and leases.','Provide T12 and NOI bridge.','Provide tenant credit and physical-condition records.']::text[])
)
WHERE NOT EXISTS (SELECT 1 FROM public.acquisition_decisions WHERE property_id = 'meadow_iii_retail_richmond_tx_2026');

COMMIT;
