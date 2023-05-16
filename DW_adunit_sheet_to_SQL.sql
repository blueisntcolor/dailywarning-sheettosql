--Declare GAM_Fee
DECLARE Gam_Fee DECIMAL(6,4);
SET GAM_fee=0.0088;
--CTE AM_db 
WITH AM AS(
SELECT 
AM.Ad_Unit as Ad_unit,
AM.Daily as Daily,
AM.Impressions as Impressions,
AM.Profit____ as Profit,
AM.Total_Revenue____ as Total_Revenue
FROM `anymanager-playground.DW_db.AM_Raw` as AM
WHERE
SUBSTR(Ad_Unit,3,1) IN  ('_')
AND Impressions > 0 
AND AM.Profit____ >0
AND AM.Total_Revenue____ > 0.001
),
--CTE GAM_db
GAM_db AS(
SELECT 
LOWER(REGEXP_EXTRACT(GAM.Ad_unit_1, r'_(.*?)_')) as URL,
GAM.Ad_unit_1 as Ad_unit,
GAM.Date as Date,
GAM.Total_impressions as impressions,
GAM.Total_CPM__CPC__CPD__and_vCPM_revenue____ as Total_GAM_Rev,
GAM.Total_ad_requests AS Ad_request,
GAM.Total_fill_rate as total_fill_rate,
GAM.Ad_server_impressions AS Ad_server_impressions,
GAM.Ad_server_CPM__CPC__CPD__and_vCPM_revenue____ AS Ad_server_revenue,
GAM.Ad_Exchange_clicks As Ad_Exchange_clicks,
GAM.Ad_Exchange_CTR AS Ad_Exchange_CTR,
GAM.Ad_Exchange_Active_View_measurable_impressions as Ad_Exchange_Active_View_measurable_impressions,
GAM.Ad_Exchange_Active_View_viewable_impressions as Ad_Exchange_Active_View_viewable_impressions,
GAM.Ad_Exchange_Active_View___viewable_impressions AS Viewability,
GAM.Ad_Exchange_Active_View_Average_Viewable_Time__seconds_ as Viewable_time,
GAM.Programmatic_responses_served AS Programmatic_responses_served,
GAM.Programmatic_match_rate as Programmatic_match_rate,
UPPER(LEFT(GAM.Ad_unit_1,2)) AS Country,
(GAM.Total_CPM__CPC__CPD__and_vCPM_revenue____-Ad_server_CPM__CPC__CPD__and_vCPM_revenue____) as AdXandOB_Rev,
(GAM.Total_impressions -Ad_server_impressions) as AdXandOB_Impressions,
LOWER(REGEXP_EXTRACT(GAM.Ad_unit_1 , r'[^_]*_[^_]*_([^_]*)')) as Device,
SUM(AM.Impressions) as AM_Sum_Impressions,
SAFE_DIVIDE((GAM.Total_impressions -Ad_server_impressions),Programmatic_responses_served) AS Adx_Show_rate,
SAFE_DIVIDE(SUM(AM.Impressions),GAM.Total_ad_requests) as Fill_rate,
SUM(AM.Total_Revenue) as AM_Revenue,
SAFE_DIVIDE(SUM(AM.Total_Revenue),SUM(AM.Impressions))*1000 as CPM,
SAFE_DIVIDE(SUM(AM.Total_Revenue),GAM.Total_ad_requests)*1000 as AR_CPM,
(GAM.Total_ad_requests-GAM.Programmatic_responses_served+GAM.Ad_server_impressions)*GAM_fee/1000 AS GAM_Cost,
SAFE_DIVIDE(SUM(AM.Profit),GAM.Total_ad_requests)*10000 as AANP10000AR,
SUM(AM.Profit)-(GAM.Total_ad_requests-GAM.Programmatic_responses_served+GAM.Ad_server_impressions)*GAM_fee/1000 AS Net_profit,
SUM(AM.Profit) as AM_Gross_profit,
(GAM.Total_impressions -Ad_server_impressions)*GAM.Ad_Exchange_Active_View___viewable_impressions AS ViewtimeXAdXImps
FROM `anymanager-playground.DW_db.GAM_Raw` as GAM
LEFT JOIN AM ON GAM.Date=AM.Daily AND GAM.Ad_unit_1=AM.Ad_unit
WHERE
SUBSTR(GAM.Ad_unit_1,3,1) IN  ('_')
AND GAM.Ad_unit_1 NOT IN ('Default')
AND GAM.Total_CPM__CPC__CPD__and_vCPM_revenue____ > 0 
AND GAM.Total_ad_requests >50
GROUP BY 1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17
)
SELECT
ad_unit1.Country AS Country,
ad_unit1.URL AS URL,
ad_unit1.Ad_unit as DFP_adunits,
ad_unit1.Date as date,
ad_unit1.Ad_request as AR,
ad_unit1.Programmatic_match_rate as AdX_Match_Rate,
ad_unit1.Adx_Show_rate as AdX_Show_rate,
ad_unit1.Fill_rate as Fill_Rate,
ad_unit1.AM_Revenue as Revenue,
ad_unit1.CPM as CPM,
ad_unit1.AR_CPM as AR_CPM,
ad_unit1.AANP10000AR as AANP10000AR,
ad_unit1.Net_profit as Net_Profit,
ad_unit1.Ad_Exchange_CTR as CTR,
ad_unit1.Viewability as Viewability,
ad_unit1.Viewable_time as Viewable_time,
SAFE_DIVIDE(GAM_db.AdXandOB_Rev,ad_unit1.Ad_request)*1000 AS Adx_ARCPM,
SAFE_DIVIDE(GAM_db.AdXandOB_Rev,ad_unit1.AM_Revenue) AS AdxRev_totalRev
FROM GAM_db AS ad_unit1
Left join GAM_db ON ad_unit1.Ad_unit=GAM_db.Ad_unit and ad_unit1.Date=GAM_db.Date
ORDER BY 1,2,3,4