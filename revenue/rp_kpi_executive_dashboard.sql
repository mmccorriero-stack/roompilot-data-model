DROP TABLE IF EXISTS rp_kpi_executive_dashboard;

CREATE TABLE rp_kpi_executive_dashboard AS
SELECT
    hotel_id,
    hotel_name,

    COUNT(DISTINCT stay_date) AS days_in_scope,

    SUM(room_nights_sold) AS total_room_nights_sold,
    ROUND(SUM(room_revenue), 2) AS total_room_revenue,

    ROUND(
        CASE
            WHEN SUM(room_nights_sold) > 0
                THEN SUM(room_revenue) / SUM(room_nights_sold)
            ELSE 0
        END,
        2
    ) AS adr,

    ROUND(AVG(occupancy_pct), 2) AS avg_occupancy_pct,
    ROUND(AVG(revpar), 2) AS avg_revpar,

    MIN(stay_date) AS period_start,
    MAX(stay_date) AS period_end

FROM rp_kpi_daily_performance
GROUP BY
    hotel_id,
    hotel_name;
