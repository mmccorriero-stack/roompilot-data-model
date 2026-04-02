DROP TABLE IF EXISTS stg_reservations;

CREATE TABLE stg_reservations (
    hotel_id              INTEGER,
    reservation_id        TEXT,
    booking_date          DATE,
    checkin_date          DATE,
    checkout_date         DATE,
    reservation_status    TEXT,
    agency_name           TEXT,
    channel_raw           TEXT,
    segment_raw           TEXT,
    guest_count           INTEGER,
    rate_plan_code        TEXT,
    daily_rate_amount     NUMERIC,
    total_amount          NUMERIC,
    guest_name            TEXT,
    guest_email           TEXT,
    guest_country         TEXT
);
