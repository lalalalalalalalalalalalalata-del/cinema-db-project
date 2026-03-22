--жанры
INSERT INTO genres (name) VALUES ('Комедия'), ('Драма'), ('Боевик'), ('Ужасы'), ('Мелодрама'), ('Фантастика')
ON CONFLICT (name) DO NOTHING;

--фильмы
INSERT INTO films (title, description, genre_id, duration_minutes, age_rating, country, release_date) VALUES
('Оппенгеймер', 'История создателя атомной бомбы', (SELECT id FROM genres WHERE name='Драма'), 180, 18, 'США', '2023-07-21'),
('Барби', 'Кукольная жизнь', (SELECT id FROM genres WHERE name='Комедия'), 114, 12, 'США', '2023-07-21'),
('Дюна: Часть вторая', 'Продолжение эпической саги', (SELECT id FROM genres WHERE name='Фантастика'), 166, 16, 'США', '2024-03-01'),
('Человек-паук: Паутина вселенных', 'Мультфильм о Пауке', (SELECT id FROM genres WHERE name='Боевик'), 140, 12, 'США', '2023-06-02'),
('Гладиатор 2', 'Эпический боевик', (SELECT id FROM genres WHERE name='Боевик'), 150, 16, 'США', '2024-11-22')
ON CONFLICT DO NOTHING;

--залы
INSERT INTO halls (name, rows_count, seats_per_row, hall_type) VALUES
('Зал 1', 10, 12, 'Standard'),
('Зал 2', 8, 10, 'VIP'),
('Зал 3', 15, 20, 'IMAX')
ON CONFLICT DO NOTHING;


DO $$
DECLARE
    hall_id INTEGER;
    r INTEGER;
    s INTEGER;
BEGIN
    FOR hall_id IN SELECT id FROM halls LOOP
        -- Проверяем, есть ли уже места в этом зале
        IF NOT EXISTS (SELECT 1 FROM seats WHERE hall_id = hall_id LIMIT 1) THEN
            -- Получаем количество рядов и мест из halls
            FOR r IN 1..(SELECT rows_count FROM halls WHERE id = hall_id) LOOP
                FOR s IN 1..(SELECT seats_per_row FROM halls WHERE id = hall_id) LOOP
                    INSERT INTO seats (hall_id, row_number, seat_number, seat_type)
                    VALUES (hall_id, r, s,
                        CASE WHEN hall_id = 2 THEN 'VIP' ELSE 'Standard' END);
                END LOOP;
            END LOOP;
        END IF;
    END LOOP;
END $$;

--пользователи
INSERT INTO users (full_name, email, phone, birth_date, password_hash) VALUES
('Иван Иванов', 'ivan@example.com', '+71234567890', '2000-01-01', 'hash1'),
('Петр Петров', 'petr@example.com', '+79876543210', '1950-05-10', 'hash2'),
('Анна Смирнова', 'anna@example.com', '+79161234567', '2005-07-15', 'hash3')
ON CONFLICT (email) DO NOTHING;

--сеансы (некоторые в прошлом, некоторые в будущем)
INSERT INTO sessions (film_id, hall_id, start_time, base_price) VALUES
((SELECT id FROM films WHERE title='Оппенгеймер'), 1, '2025-03-20 10:00:00', 300),
((SELECT id FROM films WHERE title='Барби'), 2, '2025-03-20 12:00:00', 400),
((SELECT id FROM films WHERE title='Дюна: Часть вторая'), 3, '2025-03-20 19:00:00', 500),
((SELECT id FROM films WHERE title='Оппенгеймер'), 1, '2025-03-21 10:00:00', 300),
((SELECT id FROM films WHERE title='Человек-паук: Паутина вселенных'), 2, '2025-03-21 14:00:00', 400),
((SELECT id FROM films WHERE title='Гладиатор 2'), 3, '2025-03-22 21:00:00', 600),
--будущие сеансы (для проверки свободных мест)
((SELECT id FROM films WHERE title='Оппенгеймер'), 1, CURRENT_DATE + INTERVAL '1 day' + INTERVAL '10 hours', 300)
ON CONFLICT DO NOTHING;


INSERT INTO tickets (session_id, seat_id, user_id, status, sale_time, payment_method)
SELECT s.id, seat.id, u.id, 'paid', NOW() - INTERVAL '1 day', 'card'
FROM sessions s
CROSS JOIN (SELECT id FROM seats WHERE hall_id = 1 LIMIT 3) seat
CROSS JOIN users u
WHERE s.id = (SELECT id FROM sessions WHERE start_time = '2025-03-20 10:00:00')
LIMIT 3;

--билеты со статусом booked
INSERT INTO tickets (session_id, seat_id, user_id, status, sale_time)
SELECT s.id, seat.id, u.id, 'booked', NOW() - INTERVAL '2 hours'
FROM sessions s
CROSS JOIN (SELECT id FROM seats WHERE hall_id = 1 LIMIT 2 OFFSET 3) seat
CROSS JOIN users u
WHERE s.id = (SELECT id FROM sessions WHERE start_time = '2025-03-21 10:00:00')
LIMIT 2;