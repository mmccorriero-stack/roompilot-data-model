DROP TABLE IF EXISTS stg_wubook_reservations;

CREATE TABLE stg_wubook_reservations AS
WITH base AS (
    SELECT
        "Code" AS reservation_id,
        "Status" AS reservation_status,

        CASE
            WHEN "Created" IS NOT NULL AND TRIM("Created") <> ''
                THEN substr("Created", 7, 4) || '-' || substr("Created", 4, 2) || '-' || substr("Created", 1, 2)
            ELSE NULL
        END AS booking_date,

        CASE
            WHEN "Cancellation" IS NOT NULL AND TRIM("Cancellation") <> ''
                THEN substr("Cancellation", 7, 4) || '-' || substr("Cancellation", 4, 2) || '-' || substr("Cancellation", 1, 2)
            ELSE NULL
        END AS cancellation_date,

        CASE
            WHEN "From" IS NOT NULL AND TRIM("From") <> ''
                THEN substr("From", 7, 4) || '-' || substr("From", 4, 2) || '-' || substr("From", 1, 2)
            ELSE NULL
        END AS checkin_date,

        CASE
            WHEN "To" IS NOT NULL AND TRIM("To") <> ''
                THEN substr("To", 7, 4) || '-' || substr("To", 4, 2) || '-' || substr("To", 1, 2)
            ELSE NULL
        END AS checkout_date,

        COALESCE(NULLIF(TRIM("Agency"), ''), 'Direct') AS channel_raw,
        NULL AS segment_raw,
        NULL AS rate_plan,
        NULLIF(TRIM("Board"), '') AS board_code,
        NULLIF(TRIM("Policy"), '') AS policy_name,

        "Row Type" AS row_type,
        CAST(REPLACE("Price", ',', '.') AS REAL) AS price_amount,
        CAST(REPLACE("Paid", ',', '.') AS REAL) AS paid_amount,
        CAST("Nights" AS INTEGER) AS stay_nights,
        CAST(REPLACE("Room daily price", ',', '.') AS REAL) AS room_daily_price,

        NULLIF(TRIM("Type Code"), '') AS room_type_code,
        NULLIF(TRIM("Type Name"), '') AS room_type_name,
        NULLIF(TRIM("Room Name"), '') AS room_name,

        CAST(COALESCE("Adults", 0) AS INTEGER) AS adults,
        CAST(COALESCE("Teens", 0) AS INTEGER) AS teens,
        CAST(COALESCE("Children", 0) AS INTEGER) AS children,

        NULLIF(TRIM("Booker"), '') AS guest_name,
        NULLIF(TRIM("Country"), '') AS guest_country,
        NULLIF(TRIM("Tags"), '') AS tags

    FROM raw_reservations_wubook
),

agg AS (
    SELECT
        reservation_id,
        MAX(reservation_status) AS reservation_status,
        MAX(booking_date) AS booking_date,
        MAX(cancellation_date) AS cancellation_date,
        MAX(checkin_date) AS checkin_date,
        MAX(checkout_date) AS checkout_date,

        MAX(channel_raw) AS channel_raw,
        MAX(segment_raw) AS segment_raw,
        MAX(rate_plan) AS rate_plan,
        MAX(board_code) AS board_code,
        MAX(policy_name) AS policy_name,

        MAX(stay_nights) AS stay_nights,
        MAX(room_daily_price) AS room_daily_price,

        SUM(CASE WHEN row_type = 'ROOM' THEN 1 ELSE 0 END) AS rooms_booked,

        SUM(CASE WHEN row_type = 'ROOM' THEN adults ELSE 0 END) AS adults,
        SUM(CASE WHEN row_type = 'ROOM' THEN teens ELSE 0 END) AS teens,
        SUM(CASE WHEN row_type = 'ROOM' THEN children ELSE 0 END) AS children,

        SUM(CASE WHEN row_type = 'ROOM' THEN price_amount ELSE 0 END) AS room_revenue,
        SUM(CASE WHEN row_type = 'CITY_TAX_ROOM' THEN price_amount ELSE 0 END) AS city_tax_amount,
        SUM(CASE WHEN row_type = 'EXTRA' THEN price_amount ELSE 0 END) AS extras_amount,
        SUM(CASE WHEN row_type = 'TOTAL' THEN price_amount ELSE 0 END) AS total_amount,

        MAX(paid_amount) AS paid_amount,
        MAX(guest_name) AS guest_name,
        MAX(guest_country) AS guest_country,

        GROUP_CONCAT(DISTINCT CASE WHEN row_type = 'ROOM' THEN room_type_code END) AS room_type_code_list,
        GROUP_CONCAT(DISTINCT CASE WHEN row_type = 'ROOM' THEN room_type_name END) AS room_type_name_list,
        GROUP_CONCAT(DISTINCT CASE WHEN row_type = 'ROOM' THEN room_name END) AS room_name_list,

        MAX(tags) AS tags

    FROM base
    GROUP BY reservation_id
)

INSERT INTO rp_stg_reservations (
    hotel_id,
    source_system,
    reservation_id,
    reservation_status,
    booking_date,
    cancellation_date,
    checkin_date,
    checkout_date,
    channel_raw,
    segment_raw,
    rate_plan,
    board_code,
    policy_name,
    rooms_booked,
    stay_nights,
    room_daily_price,
    adults,
    teens,
    children,
    guest_count,
    room_revenue,
    city_tax_amount,
    extras_amount,
    total_amount,
    paid_amount,
    guest_name,
    guest_country,
    room_type_code_list,
    room_type_name_list,
    room_name_list,
    tags
)
SELECT
    1 AS hotel_id,
    'WuBook' AS source_system,
    reservation_id,
    reservation_status,
    booking_date,
    cancellation_date,
    checkin_date,
    checkout_date,
    channel_raw,
    segment_raw,
    rate_plan,
    board_code,
    policy_name,
    rooms_booked,
    stay_nights,
    room_daily_price,
    adults,
    teens,
    children,
    adults + teens + children AS guest_count,
    room_revenue,
    city_tax_amount,
    extras_amount,
    total_amount,
    paid_amount,
    guest_name,
    guest_country,
    room_type_code_list,
    room_type_name_list,
    room_name_list,
    tags
FROM agg
WHERE reservation_id IS NOT NULL
  AND TRIM(reservation_id) <> '';
