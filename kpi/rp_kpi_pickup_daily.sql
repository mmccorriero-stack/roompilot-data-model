DROP TABLE IF EXISTS rp_kpi_pickup_daily;

CREATE TABLE rp_kpi_pickup_daily AS
SELECT
    s1.snapshot_date,
    s1.snapshot_date_key,
    s1.stay_date,
    s1.stay_date_key,
    s1.hotel_id,
    s1.source_system,

    s1.rooms_otb AS rooms_otb_today,
    COALESCE(s2.rooms_otb, 0) AS rooms_otb_yesterday,
    s1.rooms_otb - COALESCE(s2.rooms_otb, 0) AS pickup_rooms,

    s1.revenue_otb AS revenue_otb_today,
    COALESCE(s2.revenue_otb, 0) AS revenue_otb_yesterday,
    ROUND(s1.revenue_otb - COALESCE(s2.revenue_otb, 0), 2) AS pickup_revenue

FROM rp_fact_snapshot_otb s1
LEFT JOIN rp_fact_snapshot_otb s2
    ON s1.hotel_id = s2.hotel_id
   AND s1.stay_date = s2.stay_date
   AND s2.snapshot_date = date(s1.snapshot_date, '-1 day');
