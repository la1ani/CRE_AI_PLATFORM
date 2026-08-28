-- Kuykendahl/West Rayford Plaza OM upload for the existing CRE AI Platform schema.
-- Source: Kuykendahl & West Rayford Plaza.pdf
-- Idempotent, insert-only seed data.

BEGIN;

INSERT INTO public.properties (
  property_id,
  property_name,
  address,
  property_type,
  asking_price,
  noi,
  cap_rate,
  occupancy,
  building_sf,
  land_sf,
  year_built,
  broker_name,
  broker_email,
  broker_phone,
  source_pdf,
  major_risks,
  missing_information,
  estimated_arv,
  unit_count,
  opportunity_zone,
  value_add,
  extraction_confidence
)
SELECT
  'kuykendahl_west_rayford_plaza_tomball_tx_2026',
  'Kuykendahl/West Rayford Plaza',
  '24026 Kuykendahl Road, Tomball, TX 77375',
  'Multi-tenant neighborhood retail center',
  '$6,780,000',
  '$457,800',
  '6.75%',
  '100% leased',
  '15,510 SF',
  '103,237 SF (2.37 acres)',
  '2022',
  'Travis Overstreet',
  'Toverstreet@primemgmtinc.com',
  '(281) 257-2225',
  'Kuykendahl & West Rayford Plaza.pdf',
  '["Six local/non-rated tenants with limited published credit information","Don Tomate Meat Market represents about 31.9% of building area and base rent","Four leases commenced in 2025 and have limited operating history at the property","Five of six leases expire between March and October 2030, creating concentrated rollover risk","The OM does not disclose contractual rent escalations, renewal options, guaranties, deposits, or tenant financials","Asking price is approximately $437.14 per building SF"]'::jsonb,
  '["Trailing-12-month operating statement and general ledger","Executed leases, amendments, guaranties, options, assignments, and tenant estoppels","Tenant payment history, deposits, delinquencies, and financial statements","Detailed CAM, property-tax, insurance, and management reconciliations","Current property-tax bill, insurance policy, and renewal quote","Roof, HVAC, structure, pavement, signage, and warranty documentation","Environmental report, property-condition report, survey, title, zoning, and certificates of occupancy","Seller motivation, debt information, and pending litigation or claims","Comparable sales, market rents, tenant-improvement obligations, and leasing commissions"]'::jsonb,
  'Not provided; asking valuation is $6,780,000 at the stated 6.75% cap rate',
  6,
  NULL,
  false,
  90
WHERE NOT EXISTS (
  SELECT 1
  FROM public.properties
  WHERE property_id = 'kuykendahl_west_rayford_plaza_tomball_tx_2026'
);

INSERT INTO public.documents (
  property_id,
  file_name,
  file_type,
  drive_file_id,
  status
)
SELECT
  -2402677375,
  'Kuykendahl & West Rayford Plaza.pdf',
  'application/pdf',
  'offering-memorandums/Kuykendahl & West Rayford Plaza.pdf',
  'processed'
WHERE NOT EXISTS (
  SELECT 1
  FROM public.documents
  WHERE file_name = 'Kuykendahl & West Rayford Plaza.pdf'
);

INSERT INTO public.brokers (
  property_id,
  broker_name,
  broker_company,
  broker_email,
  broker_phone
)
SELECT
  -2402677375,
  'Travis Overstreet',
  'Prime Shopping Center Development Inc.',
  'Toverstreet@primemgmtinc.com',
  '(281) 257-2225'
WHERE NOT EXISTS (
  SELECT 1
  FROM public.brokers
  WHERE property_id = -2402677375
    AND broker_email = 'Toverstreet@primemgmtinc.com'
);

INSERT INTO public.financial_reports (
  property_id,
  rental_income,
  recoveries,
  other_income,
  gross_income,
  taxes,
  insurance,
  cam,
  utilities,
  management_fee,
  total_expenses,
  noi,
  cap_rate,
  occupancy,
  source_pdf,
  confidence,
  raw_json
)
SELECT
  'kuykendahl_west_rayford_plaza_tomball_tx_2026',
  '$457,800 annual base rent',
  '$120,978 estimated annual NNN billing at $0.65/SF/month',
  'Not stated',
  '$578,778 inferred base rent plus estimated NNN billing',
  'Not separately stated; included in tenant NNN billing',
  'Not separately stated; included in tenant NNN billing',
  'Not separately stated; included in tenant NNN billing',
  'Not stated',
  'Included in tenant NNN billing; amount not separately stated',
  '$120,978 inferred reimbursed expenses; verify against T12',
  '$457,800 stated',
  '6.75% stated; 6.7522% calculated from stated price and NOI',
  '100% leased',
  'Kuykendahl & West Rayford Plaza.pdf',
  88,
  '{
    "asking_price": 6780000,
    "stated_noi": 457800,
    "stated_cap_rate_percent": 6.75,
    "calculated_cap_rate_percent": 6.7522,
    "building_sf": 15510,
    "land_acres": 2.37,
    "land_sf_calculated": 103237.2,
    "price_per_building_sf": 437.14,
    "monthly_base_rent": 38150,
    "annual_base_rent": 457800,
    "nnn_billing_per_sf_per_month": 0.65,
    "estimated_monthly_nnn_billing": 10081.5,
    "estimated_annual_nnn_billing": 120978,
    "inferred_gross_income": 578778,
    "expense_detail_status": "not provided; NNN expense and recovery assumptions require T12 and reconciliations"
  }'::jsonb
WHERE NOT EXISTS (
  SELECT 1
  FROM public.financial_reports
  WHERE property_id = 'kuykendahl_west_rayford_plaza_tomball_tx_2026'
);

INSERT INTO public.rent_rolls (
  property_id,
  tenant_name,
  suite,
  sf,
  lease_start,
  lease_end,
  monthly_rent,
  annual_rent,
  rent_psf,
  lease_type,
  renewal_options,
  source_pdf
)
SELECT *
FROM (VALUES
  ('kuykendahl_west_rayford_plaza_tomball_tx_2026', 'Papa Peter''s Restaurant', 'Not stated', '2,500', '2024-06-01', '2029-05-31 (calculated from 60-month term)', '$5,625', '$67,500', '$27.00 annual / $2.25 monthly', 'NNN', 'Not stated', 'Kuykendahl & West Rayford Plaza.pdf'),
  ('kuykendahl_west_rayford_plaza_tomball_tx_2026', 'Family Day Spa', 'Not stated', '1,360', '2025-11-01', '2030-10-31 (calculated from 60-month term)', '$3,400', '$40,800', '$30.00 annual / $2.50 monthly', 'NNN', 'Not stated', 'Kuykendahl & West Rayford Plaza.pdf'),
  ('kuykendahl_west_rayford_plaza_tomball_tx_2026', 'Don Tomate Meat Market', 'Not stated', '4,950', '2022-04-01', '2030-03-31 (calculated from 96-month term)', '$12,375', '$148,500', '$30.00 annual / $2.50 monthly', 'NNN', 'Not stated', 'Kuykendahl & West Rayford Plaza.pdf'),
  ('kuykendahl_west_rayford_plaza_tomball_tx_2026', 'Moblo Cabinet Makers', 'Not stated', '1,200', '2025-10-01', '2030-09-30 (calculated from 60-month term)', '$3,000', '$36,000', '$30.00 annual / $2.50 monthly', 'NNN', 'Not stated', 'Kuykendahl & West Rayford Plaza.pdf'),
  ('kuykendahl_west_rayford_plaza_tomball_tx_2026', 'Beperfect Drip & Med Spa', 'Not stated', '2,000', '2025-04-01', '2030-03-31 (calculated from 60-month term)', '$5,000', '$60,000', '$30.00 annual / $2.50 monthly', 'NNN', 'Not stated', 'Kuykendahl & West Rayford Plaza.pdf'),
  ('kuykendahl_west_rayford_plaza_tomball_tx_2026', 'Below Deck', 'Not stated', '3,500', '2025-07-01', '2030-06-30 (calculated from 60-month term)', '$8,750', '$105,000', '$30.00 annual / $2.50 monthly', 'NNN', 'Not stated', 'Kuykendahl & West Rayford Plaza.pdf')
) AS v(
  property_id,
  tenant_name,
  suite,
  sf,
  lease_start,
  lease_end,
  monthly_rent,
  annual_rent,
  rent_psf,
  lease_type,
  renewal_options,
  source_pdf
)
WHERE NOT EXISTS (
  SELECT 1
  FROM public.rent_rolls r
  WHERE r.property_id = v.property_id
    AND r.tenant_name = v.tenant_name
);

INSERT INTO public.tenants (
  property_id,
  tenant,
  suite,
  monthly_rent,
  annual_rent,
  lease_start,
  lease_end,
  options,
  occupancy_status
)
SELECT *
FROM (VALUES
  (-2402677375::bigint, 'Papa Peter''s Restaurant', 'Not stated', 5625::numeric, 67500::numeric, '2024-06-01'::date, '2029-05-31'::date, 'Not stated', 'Occupied'),
  (-2402677375::bigint, 'Family Day Spa', 'Not stated', 3400::numeric, 40800::numeric, '2025-11-01'::date, '2030-10-31'::date, 'Not stated', 'Occupied'),
  (-2402677375::bigint, 'Don Tomate Meat Market', 'Not stated', 12375::numeric, 148500::numeric, '2022-04-01'::date, '2030-03-31'::date, 'Not stated', 'Occupied'),
  (-2402677375::bigint, 'Moblo Cabinet Makers', 'Not stated', 3000::numeric, 36000::numeric, '2025-10-01'::date, '2030-09-30'::date, 'Not stated', 'Occupied'),
  (-2402677375::bigint, 'Beperfect Drip & Med Spa', 'Not stated', 5000::numeric, 60000::numeric, '2025-04-01'::date, '2030-03-31'::date, 'Not stated', 'Occupied'),
  (-2402677375::bigint, 'Below Deck', 'Not stated', 8750::numeric, 105000::numeric, '2025-07-01'::date, '2030-06-30'::date, 'Not stated', 'Occupied')
) AS v(
  property_id,
  tenant,
  suite,
  monthly_rent,
  annual_rent,
  lease_start,
  lease_end,
  options,
  occupancy_status
)
WHERE NOT EXISTS (
  SELECT 1
  FROM public.tenants t
  WHERE t.property_id = v.property_id
    AND t.tenant = v.tenant
);

INSERT INTO public.analysis (
  property_id,
  due_diligence_score,
  seller_weakness_score,
  acquisition_score,
  risk_score,
  upside_score,
  overall_score,
  recommendation,
  missing_items,
  weaknesses
)
SELECT
  -2402677375,
  55,
  45,
  68,
  48,
  62,
  61,
  'HOLD / REQUEST MORE INFORMATION',
  'T12; general ledger; all leases and amendments; guaranties; estoppels; tenant financials and payment histories; CAM reconciliations; tax and insurance bills; roof/HVAC and warranty records; environmental and property-condition reports; survey; title; zoning; seller motivation; market-rent and sales comparables',
  'Local/non-rated tenant base; Don Tomate concentration; four leases began in 2025; five leases expire during 2030; rent escalations, options, guaranties, deposits, and tenant-credit support are not disclosed; high asking price per SF'
WHERE NOT EXISTS (
  SELECT 1
  FROM public.analysis
  WHERE property_id = -2402677375
);

INSERT INTO public.committee_reports (
  property_id,
  report
)
SELECT
  'kuykendahl_west_rayford_plaza_tomball_tx_2026',
  '{
    "property_summary": {
      "name": "Kuykendahl/West Rayford Plaza",
      "address": "24026 Kuykendahl Road, Tomball, TX 77375",
      "asset_type": "Multi-tenant neighborhood retail center",
      "year_built": 2022,
      "building_sf": 15510,
      "land_acres": 2.37,
      "occupancy_percent": 100,
      "tenant_count": 6
    },
    "valuation": {
      "asking_price": 6780000,
      "stated_noi": 457800,
      "stated_cap_rate_percent": 6.75,
      "calculated_cap_rate_percent": 6.7522,
      "price_per_sf": 437.14,
      "preliminary_value_at_7_00_cap": 6540000,
      "preliminary_value_at_7_25_cap": 6314483,
      "preliminary_value_at_7_50_cap": 6104000
    },
    "strengths": [
      "2022 construction",
      "100% leased",
      "All six leases are presented as NNN",
      "Strong reported household incomes and traffic counts",
      "Direct Kuykendahl Road access, visibility, and tenant pylon signage",
      "Service, restaurant, medical-wellness, grocery, and cabinet-maker tenant mix"
    ],
    "risks": [
      "Local/non-rated tenants with limited disclosed credit support",
      "Don Tomate contributes about 31.9% of building area and base rent",
      "Four tenants commenced in 2025",
      "Five leases expire in 2030",
      "No detailed expense statement or reconciliation is included",
      "No rent escalations, options, guaranties, deposits, or tenant financials are disclosed"
    ],
    "seller_weakness_items": [
      "Limited tenant-credit disclosure",
      "Concentrated 2030 lease rollover",
      "Short operating history for most tenants",
      "High price per building SF",
      "OM support is a marketing rent roll rather than complete lease and operating documentation"
    ],
    "due_diligence_items": [
      "T12 and general ledger",
      "All executed leases, amendments, options, assignments, and guaranties",
      "Estoppels, deposits, payment histories, and tenant financial statements",
      "CAM, tax, insurance, and management reconciliations",
      "Property tax, insurance, roof, HVAC, warranty, environmental, and property-condition records",
      "Survey, title, zoning, access, signage rights, and certificates of occupancy",
      "Seller motivation, loan information, pending claims, TI obligations, and leasing commissions"
    ],
    "broker_questions": [
      "Why is the seller marketing a 2022 property now?",
      "Please provide the T12, current-year monthly operating statement, and general ledger.",
      "Which leases include annual rent escalations, renewal options, termination rights, exclusives, or co-tenancy provisions?",
      "Which leases have personal or corporate guaranties, and what deposits are held?",
      "Please provide tenant payment histories, financial statements, and any delinquency or default notices.",
      "How were the $0.65/SF/month NNN charges calculated, and were any reconciliation balances unpaid?",
      "Are any expenses capped, excluded, grossed up, or not recoverable from tenants?",
      "Are there outstanding TI allowances, landlord work, free rent, brokerage commissions, or tenant concessions?",
      "Who owns and maintains each HVAC unit, the roof, pavement, pylon sign, and utility lines?",
      "Are any 2030 renewals already being negotiated, particularly Don Tomate Meat Market?",
      "Please confirm the occupied and rent-paying status of all six tenants as of closing.",
      "Are there any tax protests, insurance claims, code issues, environmental matters, access disputes, or pending litigation?"
    ],
    "recommendation": "Hold and request complete diligence. Consider pursuit only after lease, credit, payment-history, and NNN-reconciliation verification."
  }'::jsonb
WHERE NOT EXISTS (
  SELECT 1
  FROM public.committee_reports
  WHERE property_id = 'kuykendahl_west_rayford_plaza_tomball_tx_2026'
);

INSERT INTO public.acquisition_decisions (
  property_id,
  decision
)
SELECT
  'kuykendahl_west_rayford_plaza_tomball_tx_2026',
  '{
    "decision": "request_more_information",
    "recommendation": "HOLD / REQUEST MORE INFORMATION",
    "rationale": "New construction, full occupancy, and NNN leases are attractive, but the OM does not provide sufficient operating-expense support, tenant credit, lease escalations, options, guaranties, or payment history. Most leases are new and rollover is concentrated in 2030.",
    "asking_price": 6780000,
    "stated_noi": 457800,
    "stated_cap_rate_percent": 6.75,
    "preliminary_offer_range": {
      "low": 6104000,
      "high": 6350000,
      "basis": "Approximately 7.21% to 7.50% on stated NOI, subject to complete diligence and tenant-credit review"
    },
    "conditions_before_offer": [
      "Reconcile stated NOI to T12 and general ledger",
      "Confirm every lease term, escalation, option, guaranty, and tenant obligation",
      "Verify tenant payment history, deposits, and financial strength",
      "Confirm full NNN recoverability and resolve CAM reconciliation balances",
      "Complete physical, environmental, title, survey, zoning, and insurance diligence",
      "Quantify near-term capital expenditures, TI obligations, and leasing commissions"
    ]
  }'::jsonb
WHERE NOT EXISTS (
  SELECT 1
  FROM public.acquisition_decisions
  WHERE property_id = 'kuykendahl_west_rayford_plaza_tomball_tx_2026'
);

COMMIT;

SELECT
  (SELECT count(*) FROM public.properties WHERE property_id = 'kuykendahl_west_rayford_plaza_tomball_tx_2026') AS properties,
  (SELECT count(*) FROM public.documents WHERE property_id = -2402677375 AND file_name = 'Kuykendahl & West Rayford Plaza.pdf' AND status = 'processed') AS documents,
  (SELECT count(*) FROM public.brokers WHERE property_id = -2402677375) AS brokers,
  (SELECT count(*) FROM public.financial_reports WHERE property_id = 'kuykendahl_west_rayford_plaza_tomball_tx_2026') AS financial_reports,
  (SELECT count(*) FROM public.rent_rolls WHERE property_id = 'kuykendahl_west_rayford_plaza_tomball_tx_2026') AS rent_rolls,
  (SELECT count(*) FROM public.tenants WHERE property_id = -2402677375) AS tenants,
  (SELECT count(*) FROM public.analysis WHERE property_id = -2402677375) AS analysis,
  (SELECT count(*) FROM public.committee_reports WHERE property_id = 'kuykendahl_west_rayford_plaza_tomball_tx_2026') AS committee_reports,
  (SELECT count(*) FROM public.acquisition_decisions WHERE property_id = 'kuykendahl_west_rayford_plaza_tomball_tx_2026') AS acquisition_decisions;
