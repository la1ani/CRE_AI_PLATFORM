-- Detailed normalized rent-roll and tenant rows for:
-- 4145 Gessner, Plazas at Midtown I, Plazas at Midtown II, Burlington - 10311 I-45 N.
-- 210 Woerner Rd is vacant land and has no tenant rows.
-- Insert-only/idempotent. No credentials.

BEGIN;

INSERT INTO rent_rolls (property_id,tenant_name,suite,sf,lease_start,lease_end,monthly_rent,annual_rent,rent_psf,lease_type,renewal_options,source_pdf)
SELECT * FROM (VALUES
 ('4145_gessner_houston_tx_2026','The UPS Store',NULL::text,'1,400','8/1/2021','8/1/2031','$3,500.00 derived from annual rent','$42,000','$30.00','NNN','1 x 5 years at FMV','100% Leased 6-Tenant Trophy Retail Center.pdf'),
 ('4145_gessner_houston_tx_2026','Marco''s Pizza',NULL::text,'1,350','4/14/2024','4/14/2034','$3,262.50 derived from annual rent','$39,150','$29.00','NNN','2 x 5 years; scheduled annual rent steps to $40,500, $43,200, then option rents $47,520 and $52,272','100% Leased 6-Tenant Trophy Retail Center.pdf'),
 ('4145_gessner_houston_tx_2026','Juarez Mexican Restaurant',NULL::text,'4,600','4/1/2023','3/31/2033','$10,733.33 derived from annual rent','$128,800','$28.00','NNN','1 x 5 years; scheduled annual rent steps to $133,400 then $138,000; option rent $147,200','100% Leased 6-Tenant Trophy Retail Center.pdf'),
 ('4145_gessner_houston_tx_2026','Juarez Mexican Restaurant Patio','Patio','750','3/1/2026','3/31/2033','$550.00','$6,600','$8.80','NNN','1 x 5 years','100% Leased 6-Tenant Trophy Retail Center.pdf'),
 ('4145_gessner_houston_tx_2026','Tom n Tom''s Coffee & Eatery',NULL::text,'2,902','8/24/2024','8/24/2034','$7,054.25 derived from annual rent','$84,651','$29.17','NNN','2 x 5 years; 2% annual rent increases','100% Leased 6-Tenant Trophy Retail Center.pdf'),
 ('4145_gessner_houston_tx_2026','Logos Dental',NULL::text,'2,000','1/1/2026','12/31/2035','$5,500.00 derived from annual rent','$66,000','$33.00','NNN','2 x 5 years at FMV; 2.5% annual increases during months 13-120','100% Leased 6-Tenant Trophy Retail Center.pdf'),
 ('4145_gessner_houston_tx_2026','Behavioral Innovations',NULL::text,'5,226','4/1/2025','4/1/2031','$13,718.25 derived from annual rent','$164,619','$31.50','NNN','2 x 5 years; $0.50/SF annual increases','100% Leased 6-Tenant Trophy Retail Center.pdf'),
 ('plazas_midtown_i_houston_tx_2026','On the Kirb','2521','3,010','Oct-19','Feb-28','$9,030.00 derived from annual base rent','$108,360','$36.00','NNN + MGMT + 7.5% CAM AF; 7.5% controllable CAM cap','1 x 5-year option at $38.00-$40.00/SF; separate patio income $1,000/month is preserved in financial report','Plazas at Midtown I & II.pdf'),
 ('plazas_midtown_i_houston_tx_2026','The Dog House Tavern','2517','2,450','Nov-23','Oct-28','$9,203.83 derived from annual base rent','$110,446','$45.08','NNN + MGMT + 15% CAM AF','No fixed-rate option shown in executive summary','Plazas at Midtown I & II.pdf'),
 ('plazas_midtown_i_houston_tx_2026','Stop-N-Go Gyros (At Lease)','2515','1,050','Feb-27','Jan-34','$3,937.50 derived from annual base rent','$47,250','$45.00','NNN + MGMT + 10% CAM AF; 8% controllable CAM cap','1 x 5-year option at FMV; seller to bridge rent if commencement has not occurred by closing','Plazas at Midtown I & II.pdf'),
 ('plazas_midtown_i_houston_tx_2026','Chalong Thai Eatery','2513','1,050','Sep-24','Jan-31','$4,145.75 derived from annual base rent','$49,749','$47.38','NNN + MGMT + 10% CAM AF','1 x 5-year option at FMV','Plazas at Midtown I & II.pdf'),
 ('plazas_midtown_i_houston_tx_2026','Urban Dental','2511','1,750','Sep-01','Sep-31','$5,250.00 derived from annual base rent','$63,000','$36.00 current schedule / $40.00 executive summary','NNN + MGMT + 15% CAM AF','1 x 5-year option at FMV; scheduled rent steps shown through 2030','Plazas at Midtown I & II.pdf'),
 ('plazas_midtown_i_houston_tx_2026','Supercuts','2509','1,400','Nov-25','Oct-28','$4,993.33 derived from annual base rent','$59,920','$42.80','NNN + MGMT + 10% CAM AF; 7.5% controllable CAM cap','1 x 3-year option at FMV','Plazas at Midtown I & II.pdf'),
 ('plazas_midtown_i_houston_tx_2026','Tiff''s Treats','2507','1,225','Feb-13','Jan-28','$2,964.50 derived from annual base rent','$35,574','$29.04','NNN + MGMT + 15% CAM AF','1 x 5-year option at $31.94/SF','Plazas at Midtown I & II.pdf'),
 ('plazas_midtown_i_houston_tx_2026','Wing Bay','2505','1,225','Dec-25','Dec-35','$4,491.67 derived from annual base rent','$53,900','$44.00','NNN + MGMT + 10% CAM AF; 7% controllable CAM cap','1 x 5-year option at FMV; annual scheduled increases','Plazas at Midtown I & II.pdf'),
 ('plazas_midtown_i_houston_tx_2026','Dripped Birria Tacos (Interior)','2503 Interior','1,576','Mar-24','Mar-34','$7,245.67 derived from annual base rent','$86,948','$55.17','NNN + MGMT + 10% CAM AF','1 x 5-year option at FMV','Plazas at Midtown I & II.pdf'),
 ('plazas_midtown_i_houston_tx_2026','Dripped Birria Tacos (Drive Through)','2503 Drive Through','1,084','Mar-24','Mar-34',NULL::text,NULL::text,'NNN only','NNN + MGMT + 10% CAM AF','1 x 5-year option at FMV; drive-through has no separate base rent','Plazas at Midtown I & II.pdf'),
 ('plazas_midtown_ii_houston_tx_2026','MyEyeDr. (LOI)','100','1,848','May-27','Apr-34','$6,930.00 derived from annual base rent','$83,160','$45.00','NNN + MGMT; 6% controllable CAM cap','1 x 5-year option with 3% annual bumps; LOI assumed to commence 5/1/2027','Plazas at Midtown I & II.pdf'),
 ('plazas_midtown_ii_houston_tx_2026','Dough Zone','300','4,503','Jul-23','Jul-33','$17,914.42 derived from annual base rent','$214,973','$47.74','NNN + MGMT + 10% CAM AF; 7% controllable CAM cap','2 x 5-year options at FMV; separate patio rent $1,272/month with annual bumps is preserved in financial report','Plazas at Midtown I & II.pdf'),
 ('plazas_midtown_ii_houston_tx_2026','The UPS Store','400','1,375','Aug-00','Jul-30','$4,869.83 derived from annual base rent','$58,438','$42.50','NNN + MGMT + 15% CAM AF','1 x 5-year option at FMV','Plazas at Midtown I & II.pdf'),
 ('plazas_midtown_ii_houston_tx_2026','Upscale Cleaners','600','824','May-16','Mar-31','$3,376.33 derived from annual base rent','$40,516','$49.17','NNN + MGMT + 15% CAM AF','1 x 5-year option at FMV','Plazas at Midtown I & II.pdf'),
 ('plazas_midtown_ii_houston_tx_2026','Midtown Dental','700','2,751','May-01','Jun-31','$8,023.75 derived from annual base rent','$96,285','$35.00 current schedule / $42.87 executive summary','NNN + MGMT + 10% CAM AF; 10% controllable CAM cap','1 x 5-year option at FMV; scheduled rent steps shown through 2030','Plazas at Midtown I & II.pdf'),
 ('burlington_10311_i45_houston_tx_2026','Burlington Coat Factory of Texas, L.P.','Single Tenant','30,498','7/1/2026','6/30/2036','$48,111','$577,327','$18.93','NN','4 x 5-year options; 2.80% increase beginning 7/1/2031 to $593,491 annual rent; variable increases at beginning of each option','Burlington Houston TX.pdf')
) AS v(property_id,tenant_name,suite,sf,lease_start,lease_end,monthly_rent,annual_rent,rent_psf,lease_type,renewal_options,source_pdf)
WHERE NOT EXISTS (SELECT 1 FROM rent_rolls r WHERE r.property_id=v.property_id AND lower(coalesce(r.tenant_name,''))=lower(coalesce(v.tenant_name,'')) AND coalesce(r.suite,'')=coalesce(v.suite,''));

INSERT INTO tenants (property_id,tenant,suite,monthly_rent,annual_rent,lease_start,lease_end,options,occupancy_status)
SELECT * FROM (VALUES
 (-3581955298::bigint,'The UPS Store',NULL::text,3500.00::numeric,42000::numeric,'2021-08-01'::date,'2031-08-01'::date,'1 x 5 years at FMV','occupied'),
 (-3581955298::bigint,'Marco''s Pizza',NULL::text,3262.50::numeric,39150::numeric,'2024-04-14'::date,'2034-04-14'::date,'2 x 5 years; scheduled rent steps','occupied'),
 (-3581955298::bigint,'Juarez Mexican Restaurant',NULL::text,10733.33::numeric,128800::numeric,'2023-04-01'::date,'2033-03-31'::date,'1 x 5 years; scheduled rent steps','occupied'),
 (-3581955298::bigint,'Juarez Mexican Restaurant Patio','Patio',550.00::numeric,6600::numeric,'2026-03-01'::date,'2033-03-31'::date,'1 x 5 years','occupied'),
 (-3581955298::bigint,'Tom n Tom''s Coffee & Eatery',NULL::text,7054.25::numeric,84651::numeric,'2024-08-24'::date,'2034-08-24'::date,'2 x 5 years; 2% annual increases','occupied'),
 (-3581955298::bigint,'Logos Dental',NULL::text,5500.00::numeric,66000::numeric,'2026-01-01'::date,'2035-12-31'::date,'2 x 5 years at FMV; 2.5% annual increases months 13-120','occupied'),
 (-3581955298::bigint,'Behavioral Innovations',NULL::text,13718.25::numeric,164619::numeric,'2025-04-01'::date,'2031-04-01'::date,'2 x 5 years; $0.50/SF annual increases','occupied'),
 (-1227442445::bigint,'On the Kirb','2521',9030.00::numeric,108360::numeric,'2019-10-01'::date,'2028-02-29'::date,'1 x 5-year option at $38-$40/SF; patio income separate in financial report','occupied'),
 (-1227442445::bigint,'The Dog House Tavern','2517',9203.83::numeric,110446::numeric,'2023-11-01'::date,'2028-10-31'::date,'No fixed-rate option shown','occupied'),
 (-1227442445::bigint,'Stop-N-Go Gyros (At Lease)','2515',3937.50::numeric,47250::numeric,'2027-02-01'::date,'2034-01-31'::date,'1 x 5-year option at FMV; seller bridge if rent not commenced by closing','at_lease'),
 (-1227442445::bigint,'Chalong Thai Eatery','2513',4145.75::numeric,49749::numeric,'2024-09-01'::date,'2031-01-31'::date,'1 x 5-year option at FMV','occupied'),
 (-1227442445::bigint,'Urban Dental','2511',5250.00::numeric,63000::numeric,'2001-09-01'::date,'2031-09-30'::date,'1 x 5-year option at FMV; scheduled rent steps','occupied'),
 (-1227442445::bigint,'Supercuts','2509',4993.33::numeric,59920::numeric,'2025-11-01'::date,'2028-10-31'::date,'1 x 3-year option at FMV','occupied'),
 (-1227442445::bigint,'Tiff''s Treats','2507',2964.50::numeric,35574::numeric,'2013-02-01'::date,'2028-01-31'::date,'1 x 5-year option at $31.94/SF','occupied'),
 (-1227442445::bigint,'Wing Bay','2505',4491.67::numeric,53900::numeric,'2025-12-01'::date,'2035-12-31'::date,'1 x 5-year option at FMV; annual scheduled increases','occupied'),
 (-1227442445::bigint,'Dripped Birria Tacos (Interior)','2503 Interior',7245.67::numeric,86948::numeric,'2024-03-01'::date,'2034-03-31'::date,'1 x 5-year option at FMV','occupied'),
 (-1227442445::bigint,'Dripped Birria Tacos (Drive Through)','2503 Drive Through',NULL::numeric,NULL::numeric,'2024-03-01'::date,'2034-03-31'::date,'1 x 5-year option at FMV; no separate base rent, NNN only','occupied'),
 (-254224862::bigint,'MyEyeDr. (LOI)','100',6930.00::numeric,83160::numeric,'2027-05-01'::date,'2034-04-30'::date,'1 x 5-year option with 3% annual bumps; LOI assumed start 5/1/2027','loi_pending'),
 (-254224862::bigint,'Dough Zone','300',17914.42::numeric,214973::numeric,'2023-07-01'::date,'2033-07-31'::date,'2 x 5-year options at FMV; patio rent separate in financial report','occupied'),
 (-254224862::bigint,'The UPS Store','400',4869.83::numeric,58438::numeric,'2000-08-01'::date,'2030-07-31'::date,'1 x 5-year option at FMV','occupied'),
 (-254224862::bigint,'Upscale Cleaners','600',3376.33::numeric,40516::numeric,'2016-05-01'::date,'2031-03-31'::date,'1 x 5-year option at FMV','occupied'),
 (-254224862::bigint,'Midtown Dental','700',8023.75::numeric,96285::numeric,'2001-05-01'::date,'2031-06-30'::date,'1 x 5-year option at FMV; scheduled rent steps','occupied'),
 (-3587931579::bigint,'Burlington Coat Factory of Texas, L.P.','Single Tenant',48111::numeric,577327::numeric,'2026-07-01'::date,'2036-06-30'::date,'4 x 5-year options; 2.80% increase 7/1/2031 then variable increases at option starts','occupied')
) AS v(property_id,tenant,suite,monthly_rent,annual_rent,lease_start,lease_end,options,occupancy_status)
WHERE NOT EXISTS (SELECT 1 FROM tenants t WHERE t.property_id=v.property_id AND lower(coalesce(t.tenant,''))=lower(coalesce(v.tenant,'')) AND coalesce(t.suite,'')=coalesce(v.suite,''));

COMMIT;
