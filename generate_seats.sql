-- Генерация мест для всех залов
DO $$
DECLARE
    hall_record RECORD;
    r INTEGER;
    s INTEGER;
    seat_count INTEGER;
BEGIN
    FOR hall_record IN SELECT id, name, rows_count, seats_per_row FROM halls LOOP
        -- Проверяем, есть ли уже места в этом зале
        SELECT COUNT(*) INTO seat_count FROM seats WHERE hall_id = hall_record.id;
        IF seat_count = 0 THEN
            RAISE NOTICE 'Создаю места для зала %', hall_record.name;
            FOR r IN 1..hall_record.rows_count LOOP
                FOR s IN 1..hall_record.seats_per_row LOOP
                    INSERT INTO seats (hall_id, row_number, seat_number, seat_type)
                    VALUES (
                        hall_record.id,
                        r,
                        s,
                        CASE
                            WHEN hall_record.hall_type = 'VIP' THEN 'VIP'
                            ELSE 'Standard'
                        END
                    );
                END LOOP;
            END LOOP;
        ELSE
            RAISE NOTICE 'В зале % уже есть места, пропускаю', hall_record.name;
        END IF;
    END LOOP;
END $$;