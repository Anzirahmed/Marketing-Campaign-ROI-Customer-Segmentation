-- DATA QUALITY CHECKS
-- Count total records and unique customers
SELECT COUNT(*) AS total_rows, COUNT(DISTINCT "ID") AS distinct_customers
FROM marketing_raw;

-- Check for missing values
SELECT
  SUM(("Income" IS NULL)::int) AS null_income,
  SUM(("Education" IS NULL)::int) AS null_education,
  SUM(("Marital_Status" IS NULL)::int) AS null_marital_status,
  SUM(("Dt_Customer" IS NULL)::int) AS null_date
FROM marketing_raw;

-- Check numeric range sanity
SELECT
  MIN("Income") AS min_income,
  MAX("Income") AS max_income,
  MIN("Recency") AS min_recency,
  MAX("Recency") AS max_recency
FROM marketing_raw;


-- CREATE VIEW: SPENDING SUMMARY

-- Create v_customer_spend
CREATE VIEW v_customer_spend AS
SELECT
  "ID",
  ("Income")::numeric AS income,
  COALESCE("MntWines",0) + COALESCE("MntFruits",0) + COALESCE("MntMeatProducts",0)
  + COALESCE("MntFishProducts",0) + COALESCE("MntSweetProducts",0)
  + COALESCE("MntGoldProds",0) AS total_spend,
  COALESCE("NumWebPurchases",0) AS web_purchases,
  COALESCE("NumCatalogPurchases",0) AS catalog_purchases,
  COALESCE("NumStorePurchases",0) AS store_purchases,
  COALESCE("Recency",0) AS recency_days,
  "Year_Birth",
  "Education",
  "Marital_Status",
  "Kidhome",
  "Teenhome",
  "Response"
FROM marketing_raw;
SELECT * FROM v_customer_spend LIMIT 5;

-- Create v_customer_demo 
CREATE VIEW v_customer_demo AS
SELECT
  *,
  CASE
    WHEN (EXTRACT(YEAR FROM CURRENT_DATE) - "Year_Birth") < 25 THEN '18-24'
    WHEN (EXTRACT(YEAR FROM CURRENT_DATE) - "Year_Birth") BETWEEN 25 AND 34 THEN '25-34'
    WHEN (EXTRACT(YEAR FROM CURRENT_DATE) - "Year_Birth") BETWEEN 35 AND 44 THEN '35-44'
    WHEN (EXTRACT(YEAR FROM CURRENT_DATE) - "Year_Birth") BETWEEN 45 AND 54 THEN '45-54'
    ELSE '55+'
  END AS age_band
FROM v_customer_spend;
SELECT * FROM v_customer_demo LIMIT 5;


-- KPI: CAMPAIGN RESPONSE ANALYSIS
-- Overall campaign response rate
SELECT ROUND(AVG("Response"::decimal)*100,2) AS overall_response_rate_percent
FROM v_customer_demo;

-- Response by education level
SELECT
  "Education",
  COUNT(*) AS n_customers,
  ROUND(AVG("Response"::decimal)*100,2) AS response_rate_percent,
  ROUND(AVG(total_spend),2) AS avg_spend
FROM v_customer_demo
GROUP BY "Education"
ORDER BY response_rate_percent DESC;

-- Response by marital status
SELECT
  "Marital_Status",
  COUNT(*) AS n_customers,
  ROUND(AVG("Response"::decimal)*100,2) AS response_rate_percent,
  ROUND(AVG(total_spend),2) AS avg_spend
FROM v_customer_demo
GROUP BY "Marital_Status"
ORDER BY response_rate_percent DESC;

-- Response by age band
SELECT
  age_band,
  COUNT(*) AS n_customers,
  ROUND(AVG("Response"::decimal)*100,2) AS response_rate_percent,
  ROUND(AVG(total_spend),2) AS avg_spend
FROM v_customer_demo
GROUP BY age_band
ORDER BY response_rate_percent DESC;


-- CORRELATION ANALYSIS
-- Income vs total spend and response
SELECT
  ROUND(CORR(income::numeric, total_spend::numeric)::numeric, 3) AS income_spend_corr,
  ROUND(CORR(income::numeric, "Response"::numeric)::numeric, 3) AS income_response_corr
FROM v_customer_demo;

-- TOP 10 HIGH-VALUE CUSTOMERS
SELECT
  "ID",
  income,
  total_spend,
  "Response",
  age_band,
  "Education",
  "Marital_Status"
FROM v_customer_demo
ORDER BY total_spend DESC
LIMIT 10;

-- BEHAVIORAL SUMMARY BY CHANNEL
-- Average purchase behavior overall
SELECT
  ROUND(AVG(web_purchases),2) AS avg_web,
  ROUND(AVG(catalog_purchases),2) AS avg_catalog,
  ROUND(AVG(store_purchases),2) AS avg_store,
  ROUND(AVG(recency_days),2) AS avg_recency
FROM v_customer_demo;

-- Segment-wise purchase behavior
SELECT
  age_band,
  ROUND(AVG(web_purchases),1) AS avg_web,
  ROUND(AVG(store_purchases),1) AS avg_store,
  ROUND(AVG(recency_days),1) AS avg_recency,
  ROUND(AVG(total_spend),2) AS avg_spend,
  ROUND(AVG("Response"::decimal)*100,2) AS response_rate_percent
FROM v_customer_demo
GROUP BY age_band
ORDER BY avg_spend DESC;


-- EXPORT FEATURES FOR R CLUSTERING
CREATE OR REPLACE VIEW v_cluster_features AS
SELECT
  "ID" AS customer_id,
  income,
  total_spend,
  web_purchases,
  catalog_purchases,
  store_purchases,
  recency_days,
  "Response"
FROM v_customer_demo;

copy (SELECT * FROM v_cluster_features) TO 'F:/marketing_cluster_features.csv' WITH (FORMAT csv, HEADER true);
