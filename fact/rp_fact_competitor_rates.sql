DROP TABLE IF EXISTS rp_fact_competitor_rates;

CREATE TABLE rp_fact_competitor_rates AS
SELECT
    hotel_id,
    'Expedia' AS source_system,

    date(shopper_date) AS shopper_date,
    CAST(strftime('%Y%m%d', date(shopper_date)) AS INTEGER) AS shopper_date_key,

    date(stay_date) AS stay_date,
    CAST(strftime('%Y%m%d', date(stay_date)) AS INTEGER) AS stay_date_key,

    COALESCE(NULLIF(TRIM(competitor_name), ''), 'Unknown') AS competitor_name,
    COALESCE(NULLIF(TRIM(room_type_raw), ''), 'Unknown') AS room_type_raw,
    COALESCE(NULLIF(TRIM(board_raw), ''), 'Unknown') AS board_raw,
    COALESCE(NULLIF(TRIM(cancellation_policy_raw), ''), 'Unknown') AS cancellation_policy_raw,

    ROUND(CAST(price_amount AS REAL), 2) AS price_amount,
    COALESCE(NULLIF(TRIM(currency_code), ''), 'EUR') AS currency_code,
    COALESCE(NULLIF(TRIM(availability_status), ''), 'Unknown') AS availability_status

FROM stg_competitor_rates
WHERE shopper_date IS NOT NULL
  AND stay_date IS NOT NULL
  AND competitor_name IS NOT NULL
  AND TRIM(competitor_name) <> ''
  AND price_amount IS NOT NULL;
