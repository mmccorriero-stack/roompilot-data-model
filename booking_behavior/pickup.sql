-- Nome: Pickup by Booking Date
-- Descrizione: Camere e revenue prenotate per data di prenotazione

SELECT
    booking_date,
    SUM(rooms) AS rooms_picked_up,
    SUM(room_revenue) AS revenue_picked_up
FROM reservations
WHERE status = 'Confirmed'
GROUP BY booking_date
ORDER BY booking_date;
