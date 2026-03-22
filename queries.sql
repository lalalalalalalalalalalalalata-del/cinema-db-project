-- 1. Топ-5 самых кассовых фильмов за всё время
SELECT f.title, SUM(t.price) AS total_revenue
FROM tickets t
JOIN sessions s ON t.session_id = s.id
JOIN films f ON s.film_id = f.id
WHERE t.status = 'paid'
GROUP BY f.id, f.title
ORDER BY total_revenue DESC
LIMIT 5;

-- 2. Расписание сеансов на текущую дату
SELECT s.start_time, s.end_time, f.title, h.name AS hall_name
FROM sessions s
JOIN films f ON s.film_id = f.id
JOIN halls h ON s.hall_id = h.id
WHERE DATE(s.start_time) = CURRENT_DATE
ORDER BY s.start_time;

-- 3. Свободные места на конкретный сеанс (параметр: session_id = 1)
SELECT seat.row_number, seat.seat_number, seat.seat_type
FROM seats seat
WHERE seat.hall_id = (SELECT hall_id FROM sessions WHERE id = 1)
  AND NOT EXISTS (
    SELECT 1 FROM tickets t
    WHERE t.session_id = 1 AND t.seat_id = seat.id AND t.status IN ('booked', 'paid')
  )
ORDER BY seat.row_number, seat.seat_number;

-- 4. Отчёт по выручке за период (параметры: start_date, end_date)
SELECT f.title, COUNT(t.id) AS tickets_sold, SUM(t.price) AS revenue
FROM tickets t
JOIN sessions s ON t.session_id = s.id
JOIN films f ON s.film_id = f.id
WHERE t.sale_time BETWEEN '2025-03-01' AND '2025-03-31'
  AND t.status = 'paid'
GROUP BY f.id, f.title
ORDER BY revenue DESC;

-- 5. Средняя заполняемость залов за месяц (параметры: месяц, год)
SELECT h.name AS hall,
       AVG(occupied_percent) AS avg_occupancy
FROM (
    SELECT s.id AS session_id, h.id AS hall_id,
           100.0 * COUNT(t.id) / (SELECT COUNT(*) FROM seats WHERE hall_id = h.id) AS occupied_percent
    FROM sessions s
    JOIN halls h ON s.hall_id = h.id
    LEFT JOIN tickets t ON t.session_id = s.id AND t.status = 'paid'
    WHERE s.start_time >= '2025-03-01' AND s.start_time < '2025-04-01'
    GROUP BY s.id, h.id
) occupancy
JOIN halls h ON occupancy.hall_id = h.id
GROUP BY h.name;

-- 6. Статистика продаж по возрастным категориям (если у пользователей заполнена дата рождения)
SELECT
    CASE
        WHEN EXTRACT(YEAR FROM AGE(s.start_time, u.birth_date)) < 18 THEN 'до 18'
        WHEN EXTRACT(YEAR FROM AGE(s.start_time, u.birth_date)) BETWEEN 18 AND 25 THEN '18-25'
        WHEN EXTRACT(YEAR FROM AGE(s.start_time, u.birth_date)) BETWEEN 26 AND 40 THEN '26-40'
        ELSE '40+'
    END AS age_group,
    COUNT(t.id) AS tickets_sold
FROM tickets t
JOIN sessions s ON t.session_id = s.id
JOIN users u ON t.user_id = u.id
WHERE u.birth_date IS NOT NULL
GROUP BY age_group
ORDER BY MIN(EXTRACT(YEAR FROM AGE(s.start_time, u.birth_date)));

-- 7. Поиск сеансов, на которые ещё есть свободные места (с количеством свободных)
SELECT s.id, f.title, s.start_time, h.name AS hall,
       COUNT(seat.id) AS total_seats,
       COUNT(t.id) AS sold_tickets,
       COUNT(seat.id) - COUNT(t.id) AS free_seats
FROM sessions s
JOIN films f ON s.film_id = f.id
JOIN halls h ON s.hall_id = h.id
JOIN seats seat ON seat.hall_id = h.id
LEFT JOIN tickets t ON t.session_id = s.id AND t.seat_id = seat.id AND t.status = 'paid'
WHERE s.start_time > NOW()
GROUP BY s.id, f.title, s.start_time, h.name
HAVING COUNT(seat.id) - COUNT(t.id) > 0
ORDER BY s.start_time;

-- 8. История изменений статуса билета (пример для ticket_id = 1)
SELECT old_status, new_status, changed_at, changed_by
FROM ticket_status_log
WHERE ticket_id = 1
ORDER BY changed_at DESC;

-- 9. Фильмы, идущие в данный момент (текущее время между start_time и end_time)
SELECT f.title, s.start_time, s.end_time, h.name AS hall
FROM sessions s
JOIN films f ON s.film_id = f.id
JOIN halls h ON s.hall_id = h.id
WHERE NOW() BETWEEN s.start_time AND s.end_time;

-- 10. Список всех билетов с деталями фильма, сеанса и пользователя
SELECT t.id, f.title, s.start_time, seat.row_number, seat.seat_number,
       u.full_name, t.price, t.status, t.sale_time
FROM tickets t
JOIN sessions s ON t.session_id = s.id
JOIN films f ON s.film_id = f.id
JOIN seats seat ON t.seat_id = seat.id
LEFT JOIN users u ON t.user_id = u.id
ORDER BY t.sale_time DESC;