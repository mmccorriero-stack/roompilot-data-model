DROP TABLE IF EXISTS fact_competitor_rates;

CREATE TABLE fact_competitor_rates AS
SELECT
    date(shopper_date) AS shopper_date,
    CAST(strftime('%Y%m%d', date(shopper_date)) AS INTEGER) AS shopper_date_key,

    date(stay_date) AS stay_date,
    CAST(strftime('%Y%m%d', date(stay_date)) AS INTEGER) AS stay_date_key,

    hotel_id,

    COALESCE(NULLIF(trim(competitor_name), ''), 'Unknown') AS competitor_name,
    COALESCE(NULLIF(trim(room_type_raw), ''), 'Unknown') AS room_type_raw,
    COALESCE(NULLIF(trim(board_raw), ''), 'Unknown') AS board_raw,
    COALESCE(NULLIF(trim(cancellation_policy_raw), ''), 'Unknown') AS cancellation_policy_raw,

    ROUND(CAST(price_amount AS REAL), 2) AS price_amount,
    COALESCE(NULLIF(trim(currency_code), ''), 'EUR') AS currency_code,
    COALESCE(NULLIF(trim(availability_status), ''), 'Unknown') AS availability_status,
    COALESCE(NULLIF(trim(source_name), ''), 'Expedia') AS source_name

FROM stg_competitor_rates
WHERE shopper_date IS NOT NULL
  AND stay_date IS NOT NULL
  AND competitor_name IS NOT NULL
  AND trim(competitor_name) <> ''
  AND price_amount IS NOT NULL;
