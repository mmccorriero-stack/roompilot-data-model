DROP TABLE IF EXISTS kpi_daily_performance;

CREATE TABLE kpi_daily_performance AS
SELECT
    i.inventory_date AS stay_date,
    i.inventory_date_key AS stay_date_key,
    i.hotel_id,
    i.hotel_name,

    i.total_units,
    i.ooo_units,
    i.blocked_units,
    i.closed_units,
    i.maintenance_units,
    i.available_units,
    i.is_open,

    COALESCE(COUNT(rn.stay_date), 0) AS room_nights_sold,
    COALESCE(ROUND(SUM(rn.night_revenue), 2), 0) AS room_revenue,

    CASE
        WHEN COUNT(rn.stay_date) > 0
            THEN ROUND(SUM(rn.night_revenue) / COUNT(rn.stay_date), 2)
        ELSE 0
    END AS adr,

    CASE
        WHEN i.available_units > 0
            THEN ROUND(COUNT(rn.stay_date) * 100.0 / i.available_units, 2)
        ELSE 0
    END AS occupancy_pct,

    CASE
        WHEN i.available_units > 0
            THEN ROUND(COALESCE(SUM(rn.night_revenue), 0) / i.available_units, 2)
        ELSE 0
    END AS revpar

FROM fact_inventory_daily i
LEFT JOIN fact_room_nights rn
    ON i.hotel_id = rn.hotel_id
   AND i.inventory_date = rn.stay_date
   AND rn.is_cancelled = 0
GROUP BY
    i.inventory_date,
    i.inventory_date_key,
    i.hotel_id,
    i.hotel_name,
    i.total_units,
    i.ooo_units,
    i.blocked_units,
    i.closed_units,
    i.maintenance_units,
    i.available_units,
    i.is_open;
