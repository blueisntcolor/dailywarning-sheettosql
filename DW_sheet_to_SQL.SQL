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
(GAM.Total_impressions -GAM.Ad_server_impressions)*GAM.Ad_Exchange_Active_View_Average_Viewable_Time__seconds_ AS ViewtimeXAdXImps
FROM `anymanager-playground.DW_db.GAM_Raw` as GAM
LEFT JOIN AM ON GAM.Date=AM.Daily AND GAM.Ad_unit_1=AM.Ad_unit
WHERE
SUBSTR(GAM.Ad_unit_1,3,1) IN  ('_')
AND GAM.Ad_unit_1 NOT IN ('Default')
AND GAM.Total_CPM__CPC__CPD__and_vCPM_revenue____ > 0 
AND GAM.Total_ad_requests >50
GROUP BY 1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17
),

Web1_Distinct AS(
SELECT distinct 
Web1.Country AS Country,
Web1.URL as URL, 
Web1.Date AS Date,
SUM(Web1.AM_Revenue) AS web1_sumrev,
SUM(Web1.Ad_request) as web1_sumAR,
SUM(Web1.Net_profit) as web1_sumnetprofit,
sum(web1.AdXandOB_Rev) as web1_sumAdXandOB_Rev,
SAFE_DIVIDE(SUM(Web1.AM_Revenue),SUM(Web1.Ad_request))*1000 as web1_ARCPM,
FROM GAM_db as Web1
group by 1,2,3
),
Web_1_metric_calculate AS
(
SELECT 
Web1_main.Country AS Country,
Web1_main.URL AS URL,
Web1_main.Date AS Date,
COUNT(CONCAT(GAM_db.URL,GAM_db.Date)) AS Numberofads,
web1_sumAR as AR,
SAFE_DIVIDE(SUM(GAM_db.Programmatic_responses_served),SUM(GAM_db.Ad_request)) as AdX_Coverage,
SAFE_DIVIDE(SUM(GAM_db.AdXandOB_Impressions),SUM(GAM_db.Ad_request)) as AdX_fillrate,
SAFE_DIVIDE(SUM(GAM_db.AM_Sum_Impressions),SUM(GAM_db.Ad_request)) AS Fill_rate,
web1_sumrev as Rev,
SAFE_DIVIDE(SUM(GAM_db.AM_Revenue),SUM(GAM_db.AM_Sum_Impressions))*1000 as CPM,
SAFE_DIVIDE(SUM(GAM_db.AM_Revenue),SUM(GAM_db.Ad_request))*1000 as AR_CPM,
SAFE_DIVIDE(SUM(GAM_db.Net_profit),SUM(GAM_db.Ad_request))*10000 as NP10000AR,
SAFE_DIVIDE(SUM(GAM_db.Ad_Exchange_clicks),SUM(GAM_db.AdXandOB_Impressions)) AS AdX_CTR,
SAFE_DIVIDE(SUM(GAM_db.Ad_Exchange_Active_View_viewable_impressions),SUM(GAM_db.Ad_Exchange_Active_View_measurable_impressions)) AS Viewability,
SAFE_DIVIDE(SUM(GAM_db.ViewtimeXAdXImps),SUM(GAM_db.AdXandOB_Impressions)) AS Viewabletime,
SAFE_DIVIDE(SUM(GAM_db.AdXandOB_Rev),SUM(GAM_db.Ad_request))*1000 AS AdX_ARCPM,
SAFE_DIVIDE(SUM(GAM_db.AdXandOB_Rev),SUM(GAM_db.AM_Revenue)) AS AdXrevtotalrev,
Maxrev_Gam.Maxrev,
get_max_date.max_date,
CASE
WHEN Web1_main.Date=DATE_SUB(get_max_date.max_date, INTERVAL 1 DAY)
THEN
 SUM(web1_sumrev) OVER (
            PARTITION BY  Web1_main.URL
            ORDER BY  Web1_main.Date
            ROWS BETWEEN Current row and current row
          ) 
           -
          
          SUM(web1_sumrev) OVER (
            PARTITION BY Web1_main.URL
            ORDER BY Web1_main.Date
            ROWS BETWEEN 7 PRECEDING AND 7 PRECEDING)
ELSE 0
END AS Rev_Diff,

CASE
WHEN Web1_main.Date=DATE_SUB(get_max_date.max_date, INTERVAL 1 DAY)
THEN
SAFE_DIVIDE
    (
 (SUM(web1_sumAR) OVER (
            PARTITION BY  Web1_main.URL
            ORDER BY  Web1_main.Date
            ROWS BETWEEN Current row and current row
          ) 
           -
          
          SUM(web1_sumAR) OVER (
            PARTITION BY Web1_main.URL
            ORDER BY Web1_main.Date
            ROWS BETWEEN 7 PRECEDING AND 7 PRECEDING))
            ,
            SUM(web1_sumAR) OVER (
            PARTITION BY Web1_main.URL
            ORDER BY Web1_main.Date
            ROWS BETWEEN 7 PRECEDING AND 7 PRECEDING)
            )
        
ELSE 0
END AS AR_Change,

CASE
WHEN Web1_main.Date=DATE_SUB(get_max_date.max_date, INTERVAL 1 DAY)
THEN
SAFE_DIVIDE
    (
 (SUM(web1_ARCPM) OVER (
            PARTITION BY  Web1_main.URL
            ORDER BY  Web1_main.Date
            ROWS BETWEEN Current row and current row
          ) 
           -
          
          SUM(web1_ARCPM) OVER (
            PARTITION BY Web1_main.URL
            ORDER BY Web1_main.Date
            ROWS BETWEEN 7 PRECEDING AND 7 PRECEDING))
            ,
            SUM(web1_ARCPM) OVER (
            PARTITION BY Web1_main.URL
            ORDER BY Web1_main.Date
            ROWS BETWEEN 7 PRECEDING AND 7 PRECEDING)
            )
        
ELSE 0
END AS ARCPM_Change,

CASE
WHEN Web1_main.Date=DATE_SUB(get_max_date.max_date, INTERVAL 1 DAY)
THEN
SAFE_DIVIDE
(
 (SUM(web1_sumrev) OVER (
            PARTITION BY  Web1_main.URL
            ORDER BY  Web1_main.Date
            ROWS BETWEEN Current row and current row
          ) 
           -
          
          SUM(web1_sumrev) OVER (
            PARTITION BY Web1_main.URL
            ORDER BY Web1_main.Date
            ROWS BETWEEN 7 PRECEDING AND 7 PRECEDING))
            ,
          SUM(web1_sumrev) OVER (
          PARTITION BY Web1_main.URL
          ORDER BY Web1_main.Date
          ROWS BETWEEN 7 PRECEDING AND 7 PRECEDING)
)
ELSE 0
END AS Rev_change,

CASE
WHEN Web1_main.Date=DATE_SUB(get_max_date.max_date, INTERVAL 1 DAY)
THEN
SAFE_DIVIDE
(
 (SUM(web1_sumnetprofit) OVER (
            PARTITION BY  Web1_main.URL
            ORDER BY  Web1_main.Date
            ROWS BETWEEN Current row and current row
          ) 
           -
          
          SUM(web1_sumnetprofit) OVER (
            PARTITION BY Web1_main.URL
            ORDER BY Web1_main.Date
            ROWS BETWEEN 7 PRECEDING AND 7 PRECEDING))
            ,
          SUM(web1_sumnetprofit) OVER (
          PARTITION BY Web1_main.URL
          ORDER BY Web1_main.Date
          ROWS BETWEEN 7 PRECEDING AND 7 PRECEDING)
)
ELSE 0
END AS Netprofit_change,

CASE
WHEN Web1_main.Date=get_max_date.max_date
THEN
SAFE_DIVIDE
(
 (SUM(web1_sumAdXandOB_Rev) OVER (
            PARTITION BY  Web1_main.URL
            ORDER BY  Web1_main.Date
            ROWS BETWEEN Current row and current row
          ) 
           -
          SAFE_DIVIDE
          (
          SUM(web1_sumAdXandOB_Rev) OVER (
            PARTITION BY Web1_main.URL
            ORDER BY Web1_main.Date
            ROWS BETWEEN UNBOUNDED PRECEDING AND 4 PRECEDING)
            ,
          COUNT(web1_sumAdXandOB_Rev) OVER (
          PARTITION BY Web1_main.URL
          ORDER BY Web1_main.Date
          ROWS BETWEEN UNBOUNDED PRECEDING AND 4 PRECEDING)))
          ,
          SAFE_DIVIDE(
           SUM(web1_sumAdXandOB_Rev) OVER (
            PARTITION BY Web1_main.URL
            ORDER BY Web1_main.Date
            ROWS BETWEEN UNBOUNDED PRECEDING AND 4 PRECEDING)
            ,
          COUNT(web1_sumAdXandOB_Rev) OVER (
          PARTITION BY Web1_main.URL
          ORDER BY Web1_main.Date
          ROWS BETWEEN UNBOUNDED PRECEDING AND 4 PRECEDING))
  )
ELSE 0
END AS AdXOBrev_changepercentage,

CASE
WHEN Web1_main.Date=get_max_date.max_date
THEN
 SUM(web1_sumAdXandOB_Rev) OVER (
            PARTITION BY  Web1_main.URL
            ORDER BY  Web1_main.Date
            ROWS BETWEEN Current row and current row
          ) 
           -
          SAFE_DIVIDE(
          SUM(web1_sumAdXandOB_Rev) OVER (
            PARTITION BY Web1_main.URL
            ORDER BY Web1_main.Date
            ROWS BETWEEN UNBOUNDED PRECEDING AND 4 PRECEDING)
            ,
          COUNT(web1_sumAdXandOB_Rev) OVER (
          PARTITION BY Web1_main.URL
          ORDER BY Web1_main.Date
          ROWS BETWEEN UNBOUNDED PRECEDING AND 4 PRECEDING))
ELSE 0
END AS AdXOBrev_change,
web1_sumAdXandOB_Rev as AdxandOB_dvRev,
web1_sumrev as AM_dvRev,
SAFE_DIVIDE(web1_sumAdXandOB_Rev,web1_sumrev) AS GAM_divide_AMrev,
SUM(GAM_db.Impressions) AS Total_Impressions,
SUM(GAM_db.AdXandOB_Impressions) as AdXandOB_Impressions,
SuM(GAM_db.Ad_Exchange_clicks) as AdX_clicks
FROM Web1_Distinct AS Web1_main
LEFT JOIN GAM_db on 
Web1_main.URL=GAM_db.URL AND  Web1_main.Date=GAM_db.Date

LEFT JOIN 
(
  SELECT 
   summaxrevbyday.URL as URL,
  MAX(summaxrevbyday.sum_rev) AS Maxrev
  FROM 
      (
        SELECT
        GAM_db.URL as URL, 
        GAM_db.Date AS date,
        SUM(GAM_db.AM_Revenue) as sum_rev
        FROM GAM_db
        GROUP BY 1,2
      ) as summaxrevbyday
  GROUP BY 1
) AS Maxrev_Gam
ON Web1_main.URL=Maxrev_Gam.URL 

LEFT JOIN
(
  SELECT
        GAM_db.URL as URL, 
        MAX(GAM_db.Date) AS max_date,
        FROM GAM_db
        GROUP BY 1
) as get_max_Date 
ON Web1_main.URL=get_max_Date.URL 
Group by 1,2,3,GAM_db.URL, GAM_db.Date,Maxrev_Gam.Maxrev,get_max_date.max_date,web1_sumrev,web1_sumAR,web1_sumnetprofit,web1_sumAdXandOB_Rev,web1_ARCPM
ORDER BY  Web1_main.Country, Web1_main.URL, Web1_main.Date
)

SELECT
*,
CASE
  WHEN main.Date=main.max_date-1 THEN
    CASE
      WHEN main.AR_change <=-0.7 AND main.Rev_diff <-5 THEN 3
      WHEN main.AR_change BETWEEN-0.7 AND -0.4 AND main.Rev_diff <-5 THEN 2
      WHEN main.AR_change >-0.4 THEN 1
      ELSE CAST(0 AS INT64)
    END
  ELSE CAST(0 AS INT64)
END AS Warning_AR,

CASE
  WHEN main.Date=main.max_date-1 THEN
    CASE
      WHEN main.ARCPM_Change <=-0.3 AND main.Rev_diff <-5 THEN 3
      WHEN main.ARCPM_Change BETWEEN-0.3 AND -0.15 AND main.Rev_diff <-5 THEN 2
      WHEN main.ARCPM_Change >-0.15 THEN 1
      ELSE CAST(0 AS INT64)
    END
  ELSE CAST(0 AS INT64)
END AS Warning_ARCPM,

CASE
  WHEN main.Date=main.max_date-1 THEN
    CASE
      WHEN main.Rev_Change <=-0.5 AND main.Rev_diff BETWEEN -20 AND -5  THEN 2
      WHEN main.Rev_Change <=-0.2 AND main.Rev_diff < -20  THEN 3
      ELSE CAST(0 AS INT64)
    END
  ELSE CAST(0 AS INT64)
END AS Warning_Rev,

CASE
  WHEN main.Date=main.max_date-1 THEN
    CASE
      WHEN main.Netprofit_change <0 THEN 3
      ELSE CAST(0 AS INT64)
    END
  ELSE CAST(0 AS INT64)
END AS Warning_Netprofit,

CASE
  WHEN main.Date=main.max_date THEN
    CASE
      WHEN main.AdXOBrev_changepercentage <=-0.5 AND AdXOBrev_change BETWEEN -20 AND -5  THEN 2
      WHEN main.AdXOBrev_changepercentage <=-0.2 AND AdXOBrev_change < -20  THEN 3
      ELSE CAST(0 AS INT64)
    END
  ELSE CAST(0 AS INT64)
END AS Warning_AdXOBRev,
from Web_1_metric_calculate as main



