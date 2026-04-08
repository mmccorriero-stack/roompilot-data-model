DROP TABLE IF EXISTS rp_fact_reservations;

CREATE TABLE rp_fact_reservations AS
SELECT
    hotel_id,
    source_system,
    reservation_id,

    CASE
        WHEN lower(trim(reservation_status)) IN ('cancelled', 'canceled', 'annullata', 'annullato')
            THEN 'Cancelled'
        WHEN lower(trim(reservation_status)) IN ('confirmed', 'confermata', 'ok')
            THEN 'Confirmed'
        WHEN lower(trim(reservation_status)) IN ('option', 'opzione')
            THEN 'Option'
        WHEN lower(trim(reservation_status)) IN ('no show', 'noshow', 'no-show')
            THEN 'No-show'
        ELSE 'Other'
    END AS reservation_status,

    booking_date,
    CAST(strftime('%Y%m%d', booking_date) AS INTEGER) AS booking_date_key,

    cancellation_date,
    CASE
        WHEN cancellation_date IS NOT NULL
            THEN CAST(strftime('%Y%m%d', cancellation_date) AS INTEGER)
        ELSE NULL
    END AS cancellation_date_key,

    checkin_date,
    CAST(strftime('%Y%m%d', checkin_date) AS INTEGER) AS checkin_date_key,

    checkout_date,
    CAST(strftime('%Y%m%d', checkout_date) AS INTEGER) AS checkout_date_key,

    channel_raw,
    segment_raw,
    rate_plan,
    board_code,
    policy_name,

    COALESCE(rooms_booked, 0) AS rooms_booked,
    COALESCE(stay_nights, 0) AS stay_nights,
    room_daily_price,

    COALESCE(adults, 0) AS adults,
    COALESCE(teens, 0) AS teens,
    COALESCE(children, 0) AS children,
    COALESCE(guest_count, 0) AS guest_count,

    ROUND(COALESCE(room_revenue, 0), 2) AS room_revenue,
    ROUND(COALESCE(city_tax_amount, 0), 2) AS city_tax_amount,
    ROUND(COALESCE(extras_amount, 0), 2) AS extras_amount,
    ROUND(COALESCE(total_amount, 0), 2) AS total_amount,
    ROUND(COALESCE(paid_amount, 0), 2) AS paid_amount,

    guest_name,
    guest_country,

    room_type_code_list,
    room_type_name_list,
    room_name_list,
    tags,

    CASE
        WHEN booking_date IS NOT NULL
         AND checkin_date IS NOT NULL
         AND julianday(checkin_date) - julianday(booking_date) >= 0
            THEN CAST(julianday(checkin_date) - julianday(booking_date) AS INTEGER)
        ELSE NULL
    END AS lead_time,

    CASE
        WHEN lower(trim(reservation_status)) IN ('cancelled', 'canceled', 'annullata', 'annullato')
            THEN 1
        ELSE 0
    END AS is_cancelled

FROM rp_stg_reservations
WHERE reservation_id IS NOT NULL
  AND TRIM(reservation_id) <> '';
