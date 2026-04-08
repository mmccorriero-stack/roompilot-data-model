DROP TABLE IF EXISTS rp_kpi_market_daily;

CREATE TABLE rp_kpi_market_daily AS
SELECT
    stay_date,
    stay_date_key,
    hotel_id,
    source_system,

    ROUND(AVG(price_amount), 2) AS market_avg_price,
    MIN(price_amount) AS market_min_price,
    MAX(price_amount) AS market_max_price,

    COUNT(DISTINCT competitor_name) AS competitors_count

FROM rp_fact_competitor_rates
GROUP BY
    stay_date,
    stay_date_key,
    hotel_id,
    source_system;
