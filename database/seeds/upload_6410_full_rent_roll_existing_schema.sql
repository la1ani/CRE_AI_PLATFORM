-- Full normalized rent roll for 6410-6578 FM 1960 Rd.
-- Source OM rent roll totals 136,738 SF: 64,759 SF occupied / 71,979 SF vacant.
-- Insert-only and idempotent. No credentials.

BEGIN;

INSERT INTO rent_rolls (property_id,tenant_name,suite,sf,lease_start,lease_end,monthly_rent,annual_rent,rent_psf,lease_type,renewal_options,source_pdf)
SELECT * FROM (VALUES
('fm_1960_6410_6578_houston_tx_2026','Champions Mart','6424 A-1','3,588','1/1/2000','MTM','$2,332.17','$27,986','$7.80','NNN','MTM','6410-6578 FM 1960 Rd.pdf'),
('fm_1960_6410_6578_houston_tx_2026','VACANT','6428 A-2','2,000',NULL::text,NULL::text,NULL::text,NULL::text,NULL::text,'Vacant',NULL::text,'6410-6578 FM 1960 Rd.pdf'),
('fm_1960_6410_6578_houston_tx_2026','VACANT','6430 A-3','1,583',NULL,NULL,NULL,NULL,NULL,'Vacant',NULL,'6410-6578 FM 1960 Rd.pdf'),
('fm_1960_6410_6578_houston_tx_2026','VACANT','6430 A-4','1,418',NULL,NULL,NULL,NULL,NULL,'Vacant',NULL,'6410-6578 FM 1960 Rd.pdf'),
('fm_1960_6410_6578_houston_tx_2026','VACANT','6436 A-6','1,083',NULL,NULL,NULL,NULL,NULL,'Vacant',NULL,'6410-6578 FM 1960 Rd.pdf'),
('fm_1960_6410_6578_houston_tx_2026','VACANT','6434','1,752',NULL,NULL,NULL,NULL,NULL,'Vacant',NULL,'6410-6578 FM 1960 Rd.pdf'),
('fm_1960_6410_6578_houston_tx_2026','Verizon','6470 C-7','3,500','12/5/2009','11/30/2029','$7,157.50','$85,890','$24.60','NNN','1 x 5 at $25.50/SF at renewal','6410-6578 FM 1960 Rd.pdf'),
('fm_1960_6410_6578_houston_tx_2026','VACANT','6448 B-3','4,698',NULL,NULL,NULL,NULL,NULL,'Vacant',NULL,'6410-6578 FM 1960 Rd.pdf'),
('fm_1960_6410_6578_houston_tx_2026','VACANT','6450 B-4','7,200',NULL,NULL,NULL,NULL,NULL,'Vacant',NULL,'6410-6578 FM 1960 Rd.pdf'),
('fm_1960_6410_6578_houston_tx_2026','Name Brand, Inc','6452 B-5','15,000','11/1/2024','10/31/2029','$13,500','$162,000','$10.80','NNN','2 x 5 at market rate','6410-6578 FM 1960 Rd.pdf'),
('fm_1960_6410_6578_houston_tx_2026','VACANT','6476 B-6','9,600',NULL,NULL,NULL,NULL,NULL,'Vacant',NULL,'6410-6578 FM 1960 Rd.pdf'),
('fm_1960_6410_6578_houston_tx_2026','Carpet Vanilla','6486','5,900','4/18/2014','8/31/2029','$5,172.83','$62,074','$10.56','NNN','1 x 5 at market rate','6410-6578 FM 1960 Rd.pdf'),
('fm_1960_6410_6578_houston_tx_2026','Panang Thai Restaurant','6488 B-8','2,010','1/1/2017','12/31/2026','$2,761.50','$33,138','$16.44','NNN','2 x 5 at market rate','6410-6578 FM 1960 Rd.pdf'),
('fm_1960_6410_6578_houston_tx_2026','Shipley''s Do-Nut','6500-D','2,000','3/6/2024','1/31/2034','$5,400','$64,800','$32.40','NNN','2 x 5; 10% increase every 5 years; step to $35.75/SF on 3/6/2029','6410-6578 FM 1960 Rd.pdf'),
('fm_1960_6410_6578_houston_tx_2026','LaMichuacana Meat Market','6500','13,200','10/1/2025','9/30/2035','$9,350','$112,200','$8.50','NNN','2 x 5 FMV; scheduled annual rent steps','6410-6578 FM 1960 Rd.pdf'),
('fm_1960_6410_6578_houston_tx_2026','VACANT','6500','360',NULL,NULL,NULL,NULL,NULL,'Vacant',NULL,'6410-6578 FM 1960 Rd.pdf'),
('fm_1960_6410_6578_houston_tx_2026','Hertz','6578 E-1','1,240','12/5/2005','7/31/2029','$1,995','$23,940','$19.32','NNN','2 x 5 at market rate','6410-6578 FM 1960 Rd.pdf'),
('fm_1960_6410_6578_houston_tx_2026','Tony''s Automotive','6568 E-3','5,040','10/1/2021','2/28/2027','$5,040','$60,480','$12.00','NNN','N/A','6410-6578 FM 1960 Rd.pdf'),
('fm_1960_6410_6578_houston_tx_2026','Boys Scouts of America','6568','2,321','1/1/2026','12/31/2026','$2,715.58','$32,587','$14.04','NNN','No option shown; market rate at renewal noted','6410-6578 FM 1960 Rd.pdf'),
('fm_1960_6410_6578_houston_tx_2026','VACANT','6568 E-3','9,520',NULL,NULL,NULL,NULL,NULL,'Vacant',NULL,'6410-6578 FM 1960 Rd.pdf'),
('fm_1960_6410_6578_houston_tx_2026','VACANT','6564','2,266',NULL,NULL,NULL,NULL,NULL,'Vacant',NULL,'6410-6578 FM 1960 Rd.pdf'),
('fm_1960_6410_6578_houston_tx_2026','VACANT','6564 E-4','880',NULL,NULL,NULL,NULL,NULL,'Vacant',NULL,'6410-6578 FM 1960 Rd.pdf'),
('fm_1960_6410_6578_houston_tx_2026','Houston Hair Studio','6562 E-6','1,600','2/1/1997','2/28/2027','$1,600','$19,200','$12.00','NNN','1 x 5 at market rate','6410-6578 FM 1960 Rd.pdf'),
('fm_1960_6410_6578_houston_tx_2026','Red Zone Training Center','6560 F-1','9,360','6/1/2022','10/31/2027','$3,900','$46,800','$5.04','NNN','3 x 5 at market rate','6410-6578 FM 1960 Rd.pdf'),
('fm_1960_6410_6578_houston_tx_2026','VACANT','6536 G-1/2/3','12,000',NULL,NULL,NULL,NULL,NULL,'Vacant',NULL,'6410-6578 FM 1960 Rd.pdf'),
('fm_1960_6410_6578_houston_tx_2026','VACANT','13029 B-3','1,336',NULL,NULL,NULL,NULL,NULL,'Vacant',NULL,'6410-6578 FM 1960 Rd.pdf'),
('fm_1960_6410_6578_houston_tx_2026','VACANT','13029 D-3','5,240',NULL,NULL,NULL,NULL,NULL,'Vacant',NULL,'6410-6578 FM 1960 Rd.pdf'),
('fm_1960_6410_6578_houston_tx_2026','VACANT','13027 A-2','908',NULL,NULL,NULL,NULL,NULL,'Vacant',NULL,'6410-6578 FM 1960 Rd.pdf'),
('fm_1960_6410_6578_houston_tx_2026','VACANT','13027 B-2','1,840',NULL,NULL,NULL,NULL,NULL,'Vacant',NULL,'6410-6578 FM 1960 Rd.pdf'),
('fm_1960_6410_6578_houston_tx_2026','VACANT','13027 C-2','420',NULL,NULL,NULL,NULL,NULL,'Vacant',NULL,'6410-6578 FM 1960 Rd.pdf'),
('fm_1960_6410_6578_houston_tx_2026','VACANT','13027 D-2','432',NULL,NULL,NULL,NULL,NULL,'Vacant',NULL,'6410-6578 FM 1960 Rd.pdf'),
('fm_1960_6410_6578_houston_tx_2026','VACANT','13027 F-2','2,259',NULL,NULL,NULL,NULL,NULL,'Vacant',NULL,'6410-6578 FM 1960 Rd.pdf'),
('fm_1960_6410_6578_houston_tx_2026','VACANT','13025 A1/B1','5,184',NULL,NULL,NULL,NULL,NULL,'Vacant',NULL,'6410-6578 FM 1960 Rd.pdf')
) AS v(property_id,tenant_name,suite,sf,lease_start,lease_end,monthly_rent,annual_rent,rent_psf,lease_type,renewal_options,source_pdf)
WHERE NOT EXISTS (
 SELECT 1 FROM rent_rolls r
 WHERE r.property_id=v.property_id AND lower(coalesce(r.tenant_name,''))=lower(coalesce(v.tenant_name,'')) AND coalesce(r.suite,'')=coalesce(v.suite,'')
);

INSERT INTO tenants (property_id,tenant,suite,monthly_rent,annual_rent,lease_start,lease_end,options,occupancy_status)
SELECT * FROM (VALUES
(-2465894::bigint,'Champions Mart','6424 A-1',2332.17::numeric,27986::numeric,'2000-01-01'::date,NULL::date,'Month-to-month NNN','occupied'),
(-2465894,'VACANT','6428 A-2',NULL,NULL,NULL,NULL,'2,000 SF vacant','vacant'),
(-2465894,'VACANT','6430 A-3',NULL,NULL,NULL,NULL,'1,583 SF vacant','vacant'),
(-2465894,'VACANT','6430 A-4',NULL,NULL,NULL,NULL,'1,418 SF vacant','vacant'),
(-2465894,'VACANT','6436 A-6',NULL,NULL,NULL,NULL,'1,083 SF vacant','vacant'),
(-2465894,'VACANT','6434',NULL,NULL,NULL,NULL,'1,752 SF vacant','vacant'),
(-2465894,'Verizon','6470 C-7',7157.50,85890,'2009-12-05','2029-11-30','1 x 5 at $25.50/SF at renewal','occupied'),
(-2465894,'VACANT','6448 B-3',NULL,NULL,NULL,NULL,'4,698 SF vacant','vacant'),
(-2465894,'VACANT','6450 B-4',NULL,NULL,NULL,NULL,'7,200 SF vacant','vacant'),
(-2465894,'Name Brand, Inc','6452 B-5',13500,162000,'2024-11-01','2029-10-31','2 x 5 at market rate','occupied'),
(-2465894,'VACANT','6476 B-6',NULL,NULL,NULL,NULL,'9,600 SF vacant','vacant'),
(-2465894,'Carpet Vanilla','6486',5172.83,62074,'2014-04-18','2029-08-31','1 x 5 at market rate','occupied'),
(-2465894,'Panang Thai Restaurant','6488 B-8',2761.50,33138,'2017-01-01','2026-12-31','2 x 5 at market rate','occupied'),
(-2465894,'Shipley''s Do-Nut','6500-D',5400,64800,'2024-03-06','2034-01-31','2 x 5; 10% increase every 5 years','occupied'),
(-2465894,'LaMichuacana Meat Market','6500',9350,112200,'2025-10-01','2035-09-30','2 x 5 FMV; scheduled annual rent steps','occupied'),
(-2465894,'VACANT','6500',NULL,NULL,NULL,NULL,'360 SF vacant','vacant'),
(-2465894,'Hertz','6578 E-1',1995,23940,'2005-12-05','2029-07-31','2 x 5 at market rate','occupied'),
(-2465894,'Tony''s Automotive','6568 E-3',5040,60480,'2021-10-01','2027-02-28','No renewal option shown','occupied'),
(-2465894,'Boys Scouts of America','6568',2715.58,32587,'2026-01-01','2026-12-31','Market rate at renewal noted; no option shown','occupied'),
(-2465894,'VACANT','6568 E-3',NULL,NULL,NULL,NULL,'9,520 SF vacant','vacant'),
(-2465894,'VACANT','6564',NULL,NULL,NULL,NULL,'2,266 SF vacant','vacant'),
(-2465894,'VACANT','6564 E-4',NULL,NULL,NULL,NULL,'880 SF vacant','vacant'),
(-2465894,'Houston Hair Studio','6562 E-6',1600,19200,'1997-02-01','2027-02-28','1 x 5 at market rate','occupied'),
(-2465894,'Red Zone Training Center','6560 F-1',3900,46800,'2022-06-01','2027-10-31','3 x 5 at market rate','occupied'),
(-2465894,'VACANT','6536 G-1/2/3',NULL,NULL,NULL,NULL,'12,000 SF vacant','vacant'),
(-2465894,'VACANT','13029 B-3',NULL,NULL,NULL,NULL,'1,336 SF vacant','vacant'),
(-2465894,'VACANT','13029 D-3',NULL,NULL,NULL,NULL,'5,240 SF vacant','vacant'),
(-2465894,'VACANT','13027 A-2',NULL,NULL,NULL,NULL,'908 SF vacant','vacant'),
(-2465894,'VACANT','13027 B-2',NULL,NULL,NULL,NULL,'1,840 SF vacant','vacant'),
(-2465894,'VACANT','13027 C-2',NULL,NULL,NULL,NULL,'420 SF vacant','vacant'),
(-2465894,'VACANT','13027 D-2',NULL,NULL,NULL,NULL,'432 SF vacant','vacant'),
(-2465894,'VACANT','13027 F-2',NULL,NULL,NULL,NULL,'2,259 SF vacant','vacant'),
(-2465894,'VACANT','13025 A1/B1',NULL,NULL,NULL,NULL,'5,184 SF vacant','vacant')
) AS v(property_id,tenant,suite,monthly_rent,annual_rent,lease_start,lease_end,options,occupancy_status)
WHERE NOT EXISTS (
 SELECT 1 FROM tenants t
 WHERE t.property_id=v.property_id AND lower(coalesce(t.tenant,''))=lower(coalesce(v.tenant,'')) AND coalesce(t.suite,'')=coalesce(v.suite,'')
);

COMMIT;

SELECT
  (SELECT count(*) FROM rent_rolls WHERE property_id='fm_1960_6410_6578_houston_tx_2026') AS rent_roll_rows,
  (SELECT count(*) FROM tenants WHERE property_id=-2465894) AS tenant_rows;
