DROP TABLE IF EXISTS fact_snapshot_otb;

CREATE TABLE fact_snapshot_otb AS
WITH RECURSIVE snapshot_expanded AS (
    SELECT
        fr.reservation_id,
        fr.hotel_id,
        fr.booking_date AS snapshot_date,
        CAST(strftime('%Y%m%d', fr.booking_date) AS INTEGER) AS snapshot_date_key,
        rn.stay_date,
        rn.stay_date_key,
        rn.night_revenue,
        rn.rooms_booked,
        fr.is_cancelled
    FROM fact_reservations fr
    INNER JOIN fact_room_nights rn
        ON fr.reservation_id = rn.reservation_id
    WHERE fr.booking_date IS NOT NULL
      AND rn.stay_date IS NOT NULL
      AND julianday(rn.stay_date) >= julianday(fr.booking_date)
      AND fr.is_cancelled = 0

    UNION ALL

    SELECT
        reservation_id,
        hotel_id,
        date(snapshot_date, '+1 day') AS snapshot_date,
        CAST(strftime('%Y%m%d', date(snapshot_date, '+1 day')) AS INTEGER) AS snapshot_date_key,
        stay_date,
        stay_date_key,
        night_revenue,
        rooms_booked,
        is_cancelled
    FROM snapshot_expanded
    WHERE date(snapshot_date, '+1 day') <= stay_date
)
SELECT
    snapshot_date,
    snapshot_date_key,
    stay_date,
    stay_date_key,
    hotel_id,
    COUNT(*) AS rooms_otb,
    ROUND(SUM(night_revenue), 2) AS revenue_otb,
    CASE
        WHEN COUNT(*) > 0
            THEN ROUND(SUM(night_revenue) / COUNT(*), 2)
        ELSE 0
    END AS adr_otb
FROM snapshot_expanded
GROUP BY
    snapshot_date,
    snapshot_date_key,
    stay_date,
    stay_date_key,
    hotel_id;
