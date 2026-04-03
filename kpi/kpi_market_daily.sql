DROP TABLE IF EXISTS kpi_market_daily;

CREATE TABLE kpi_market_daily AS
SELECT
    stay_date,
    hotel_id,

    ROUND(AVG(price_amount), 2) AS market_avg_price,
    MIN(price_amount) AS market_min_price,
    MAX(price_amount) AS market_max_price,

    COUNT(DISTINCT competitor_name) AS competitors_count

FROM fact_competitor_rates
GROUP BY
    stay_date,
    hotel_id;
