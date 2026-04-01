-- Nome: Revenue by Channel
-- Descrizione: Revenue totale per canale

SELECT
    c.channel_name,
    SUM(r.room_revenue) AS total_revenue
FROM reservations r
JOIN channels c ON r.channel_id = c.channel_id
WHERE r.status = 'Confirmed'
GROUP BY c.channel_name
ORDER BY total_revenue DESC;
