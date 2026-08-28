-- Point West Center full-PDF cleanup / attachment correction.
-- Source: full 6-page Point West Center flyer supplied 2026-08-28.
-- This script does not delete, truncate, or overwrite unrelated records.
-- It updates only the canonical Point West Center rows and inserts the missing
-- designated broker if that broker row does not already exist.

BEGIN;

UPDATE public.properties
SET source_pdf = 'Point West Center.pdf',
    major_risks = jsonb_build_array(
      'Flyer does not include rent roll or tenant-level lease schedule',
      'Older 1979 construction despite 2019 renovation',
      'Need to verify grocery anchor lease term and credit',
      'Need roof scope backup even though flyer mentions new roof excluding anchor and pad'
    )
WHERE property_id = 'point_west_center_houston_tx_2026';

UPDATE public.documents
SET file_name = 'Point West Center.pdf',
    drive_file_id = 'gdrive:1yuehoBLowKFc4haaqQSGxTtaoHsp0Cjo',
    processed_at = now(),
    status = 'processed'
WHERE property_id = -1916802;

UPDATE public.financial_reports
SET source_pdf = 'Point West Center.pdf',
    raw_json = COALESCE(raw_json, '{}'::jsonb) || jsonb_build_object(
      'source_verified_full_pdf', true,
      'source_page_count', 6,
      'site_plan_tenant_labels', jsonb_build_array(
        'Enson Market','Tacos Don Beto','Thai Style Fast Food','Sonja Hair Salon',
        'TaxBreak','Gessner Medical Center','Parisian Bakery','Noodle Shop Pho 99',
        'Foot Reflexology','L A Fashion','Harwin Income Tax Services','Bar & Lounge',
        'Abi''s Liquor Store','Houston Custom Framing','Variedades Centroamerica',
        'Li''s Hair Salon','Bank of Hope','Watermill Express'
      ),
      'site_plan_not_part_of_property', jsonb_build_array('Total','O''Reilly Auto Parts')
    )
WHERE property_id = 'point_west_center_houston_tx_2026';

INSERT INTO public.brokers (property_id, broker_name, broker_company, broker_email, broker_phone)
SELECT -1916802, 'Sanford Paul Aron', 'Hunington Properties, Inc.', 'sandy@hpiproperties.com', '713-623-6944'
WHERE NOT EXISTS (
  SELECT 1 FROM public.brokers
  WHERE property_id = -1916802 AND lower(broker_name) = lower('Sanford Paul Aron')
);

UPDATE public.analysis
SET recommendation = 'REQUEST MORE INFO. Point West Center is a 100% occupied grocery-anchored center with a 7.71% cap and below-market-rent upside. The complete 6-page sale flyer is now attached, but it does not provide a rent roll, T12, executed leases, or tenant-level lease economics.',
    weaknesses = 'Full 6-page flyer is attached but still provides no tenant-level rent roll or lease economics; older 1979 construction; verify grocery anchor lease; verify new roof scope excluding anchor and pad.'
WHERE property_id = -1916802;

UPDATE public.committee_reports
SET report = jsonb_set(
             jsonb_set(
               report,
               '{summary}',
               to_jsonb('Point West Center is a 100% occupied grocery-anchored Houston retail center offered at $12.75M, $983,053.59 NOI, and 7.71% cap. The complete 6-page sale flyer is attached and confirms below-market rents, signalized traffic, and a new roof on the retail center excluding anchor and pad. Rent roll, T12, and executed leases are still required before full underwriting.'::text)
             ),
             '{broker_questions}',
             to_jsonb(ARRAY[
               'Please send current rent roll in Excel.',
               'Please send T12 operating statement.',
               'Please send all executed leases and amendments, especially the grocery anchor lease.',
               'Please provide tax and insurance backup.',
               'Please provide CAM reconciliation history.',
               'Please provide roof warranty and roof scope, including anchor and pad exclusions.',
               'Are all tenants current on rent?',
               'What is the reason for sale?'
             ]::text[])
           )
WHERE property_id = 'point_west_center_houston_tx_2026';

COMMIT;
