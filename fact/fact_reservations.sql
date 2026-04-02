DROP TABLE IF EXISTS fact_reservations;

CREATE TABLE fact_reservations AS
SELECT
    reservation_id,
    hotel_id,

    booking_date,
    CAST(strftime('%Y%m%d', booking_date) AS INTEGER) AS booking_date_key,

    checkin_date,
    CAST(strftime('%Y%m%d', checkin_date) AS INTEGER) AS checkin_date_key,

    checkout_date,
    CAST(strftime('%Y%m%d', checkout_date) AS INTEGER) AS checkout_date_key,

    CASE
        WHEN lower(trim(reservation_status)) IN ('cancelled', 'canceled', 'annullata', 'annullato')
            THEN 'Cancelled'
        WHEN lower(trim(reservation_status)) IN ('confirmed', 'confermata', 'ok')
            THEN 'Confirmed'
        WHEN lower(trim(reservation_status)) IN ('no show', 'noshow', 'no-show')
            THEN 'No-show'
        WHEN lower(trim(reservation_status)) IN ('checked-in', 'checked in', 'in house')
            THEN 'Checked-in'
        WHEN lower(trim(reservation_status)) IN ('checked-out', 'checked out', 'departure')
            THEN 'Checked-out'
        ELSE 'Other'
    END AS reservation_status,

    COALESCE(NULLIF(trim(channel_raw), ''), 'Unknown') AS channel,
    COALESCE(NULLIF(trim(segment_raw), ''), 'Unknown') AS segment,
    COALESCE(NULLIF(trim(rate_plan_code), ''), 'Unknown') AS rate_plan_code,

    guest_count,

    1 AS rooms_booked,

    CASE
        WHEN julianday(checkout_date) - julianday(checkin_date) > 0
            THEN CAST(julianday(checkout_date) - julianday(checkin_date) AS INTEGER)
        ELSE 0
    END AS stay_nights,

    CASE
        WHEN julianday(checkin_date) - julianday(booking_date) >= 0
            THEN CAST(julianday(checkin_date) - julianday(booking_date) AS INTEGER)
        ELSE 0
    END AS lead_time,

    daily_rate_amount,

    CASE
        WHEN total_amount IS NOT NULL THEN ROUND(total_amount, 2)
        ELSE NULL
    END AS total_revenue,

    CASE
        WHEN daily_rate_amount IS NOT NULL
             AND julianday(checkout_date) - julianday(checkin_date) > 0
            THEN ROUND(
                daily_rate_amount * (julianday(checkout_date) - julianday(checkin_date)),
                2
            )
        ELSE NULL
    END AS room_revenue,

    CASE
        WHEN lower(trim(reservation_status)) IN ('cancelled', 'canceled', 'annullata', 'annullato')
            THEN 1
        ELSE 0
    END AS is_cancelled,

    agency_name,
    guest_name,
    guest_email,
    guest_country

FROM stg_reservations
WHERE reservation_id IS NOT NULL
  AND trim(reservation_id) <> '';
