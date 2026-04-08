DROP TABLE IF EXISTS pricing_engine_v2;

CREATE TABLE pricing_engine_v2 AS
WITH pickup_summary AS (
    SELECT
        stay_date,
        hotel_id,
        ROUND(SUM(pickup_rooms), 2) AS pickup_rooms_last_snapshot,
        ROUND(SUM(pickup_revenue), 2) AS pickup_revenue_last_snapshot
    FROM kpi_pickup_daily
    GROUP BY
        stay_date,
        hotel_id
),
base AS (
    SELECT
        k.stay_date,
        k.hotel_id,
        k.hotel_name,

        k.adr AS current_adr,
        k.occupancy_pct,
        k.revpar,
        k.room_nights_sold,
        k.room_revenue,

        m.market_avg_price,
        m.market_min_price,
        m.market_max_price,

        COALESCE(p.pickup_rooms_last_snapshot, 0) AS pickup_rooms,
        COALESCE(p.pickup_revenue_last_snapshot, 0) AS pickup_revenue,

        CAST(julianday(k.stay_date) - julianday('now') AS INTEGER) AS days_to_arrival

    FROM kpi_daily_performance k
    LEFT JOIN kpi_market_daily m
        ON k.stay_date = m.stay_date
       AND k.hotel_id = m.hotel_id
    LEFT JOIN pickup_summary p
        ON k.stay_date = p.stay_date
       AND k.hotel_id = p.hotel_id
),
scored AS (
    SELECT
        *,
        CASE
            WHEN occupancy_pct >= 85 THEN 2
            WHEN occupancy_pct >= 70 THEN 1
            WHEN occupancy_pct < 40 THEN -2
            WHEN occupancy_pct < 55 THEN -1
            ELSE 0
        END AS occ_score,

        CASE
            WHEN market_avg_price IS NULL THEN 0
            WHEN current_adr < market_avg_price * 0.95 THEN 1
            WHEN current_adr > market_avg_price * 1.05 THEN -1
            ELSE 0
        END AS market_score,

        CASE
            WHEN pickup_rooms >= 3 THEN 2
            WHEN pickup_rooms > 0 THEN 1
            WHEN pickup_rooms < 0 THEN -1
            ELSE 0
        END AS pickup_score,

        CASE
            WHEN days_to_arrival <= 3 AND occupancy_pct >= 70 THEN 2
            WHEN days_to_arrival <= 7 AND occupancy_pct >= 60 THEN 1
            WHEN days_to_arrival <= 3 AND occupancy_pct < 40 THEN -2
            WHEN days_to_arrival <= 7 AND occupancy_pct < 50 THEN -1
            ELSE 0
        END AS lead_time_score
    FROM base
)
SELECT
    stay_date,
    hotel_id,
    hotel_name,

    current_adr,
    occupancy_pct,
    revpar,
    room_nights_sold,
    room_revenue,

    market_avg_price,
    market_min_price,
    market_max_price,

    pickup_rooms,
    pickup_revenue,
    days_to_arrival,

    occ_score,
    market_score,
    pickup_score,
    lead_time_score,

    (occ_score + market_score + pickup_score + lead_time_score) AS total_score,

    ROUND(
        CASE
            WHEN (occ_score + market_score + pickup_score + lead_time_score) >= 4 THEN current_adr * 1.15
            WHEN (occ_score + market_score + pickup_score + lead_time_score) = 3 THEN current_adr * 1.10
            WHEN (occ_score + market_score + pickup_score + lead_time_score) = 2 THEN current_adr * 1.07
            WHEN (occ_score + market_score + pickup_score + lead_time_score) = 1 THEN current_adr * 1.03
            WHEN (occ_score + market_score + pickup_score + lead_time_score) = 0 THEN current_adr
            WHEN (occ_score + market_score + pickup_score + lead_time_score) = -1 THEN current_adr * 0.97
            WHEN (occ_score + market_score + pickup_score + lead_time_score) = -2 THEN current_adr * 0.93
            WHEN (occ_score + market_score + pickup_score + lead_time_score) <= -3 THEN current_adr * 0.88
            ELSE current_adr
        END,
        2
    ) AS suggested_price,

    CASE
        WHEN (occ_score + market_score + pickup_score + lead_time_score) >= 4 THEN 'High'
        WHEN (occ_score + market_score + pickup_score + lead_time_score) >= 1 THEN 'Medium'
        ELSE 'Low'
    END AS confidence_level,

    CASE
        WHEN (occ_score + market_score + pickup_score + lead_time_score) >= 4
            THEN 'Domanda molto forte, pickup positivo e finestra corta: aumenta con decisione'
        WHEN (occ_score + market_score + pickup_score + lead_time_score) >= 2
            THEN 'Segnali positivi su domanda e mercato: aumento moderato consigliato'
        WHEN (occ_score + market_score + pickup_score + lead_time_score) = 1
            THEN 'Scenario leggermente favorevole: piccolo aumento possibile'
        WHEN (occ_score + market_score + pickup_score + lead_time_score) = 0
            THEN 'Scenario equilibrato: mantieni la tariffa attuale'
        WHEN (occ_score + market_score + pickup_score + lead_time_score) <= -3
            THEN 'Domanda debole o data vicina con bassa occupazione: riduzione consigliata'
        ELSE 'Scenario prudente: valuta lieve correzione al ribasso'
    END AS explanation

FROM scored;
