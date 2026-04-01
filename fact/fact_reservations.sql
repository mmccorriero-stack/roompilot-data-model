CREATE TABLE fact_reservations AS
SELECT
    hotel_id,
    reservation_code,
    booking_date,
    check_in_date,
    check_out_date,
    reservation_status,
    agency_name,
    market_source,
    market_segment,
    guest_count,
    rate_plan_code,
    daily_rate_amount,
    total_amount
FROM stg_reservations;
