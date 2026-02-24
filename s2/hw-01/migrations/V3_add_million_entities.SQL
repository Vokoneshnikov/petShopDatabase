-- =====================================================
-- БЛОК 1: Заполнение справочников (малые таблицы)
-- =====================================================

-- 1.1 Заполнение animal_type (низкая кардинальность)
TRUNCATE petshopschema.animal_type CASCADE;
INSERT INTO petshopschema.animal_type (name) VALUES
    ('Собака'),
    ('Кошка'),
    ('Попугай'),
    ('Хомяк'),
    ('Рыбка'),
    ('Кролик'),
    ('Морская свинка'),
    ('Шиншилла'),
    ('Рептилия'),
    ('Хорек'),
    ('Мышь'),
    ('Крыса'),
    ('Черепаха'),
    ('Ящерица'),
    ('Лягушка');

-- 1.2 Заполнение petshop (50 магазинов)
TRUNCATE petshopschema.petshop CASCADE;
INSERT INTO petshopschema.petshop (address, name, pets_capacity)
SELECT 
    'ул. ' || chr(65 + (random()*25)::int) || ', д. ' || (random()*100)::int || ', кв. ' || (random()*200)::int as address,
    CASE WHEN random() < 0.7 
         THEN 'ЗООМИР-' || (random()*1000)::int 
         ELSE 'Питомец-' || (random()*1000)::int 
    END as name,
    (random()*450 + 50)::int as pets_capacity
FROM generate_series(1, 50);

-- 1.3 Заполнение breed (200 пород)
TRUNCATE petshopschema.breed CASCADE;
-- Сначала добавляем осмысленные породы (они точно уникальные)
INSERT INTO petshopschema.breed (breed_name, animal_type_id, average_weight) VALUES
-- Собаки (animal_type_id = 1)
('Лабрадор', 1, 30000),
('Немецкая овчарка', 1, 35000),
('Йоркширский терьер', 1, 3000),
('Такса', 1, 9000),
('Бульдог', 1, 25000),
('Пудель', 1, 20000),
('Хаски', 1, 25000),
('Доберман', 1, 35000),
('Ротвейлер', 1, 45000),
('Шпиц', 1, 5000),

-- Кошки (animal_type_id = 2)
('Британская кошка', 2, 5000),
('Шотландская кошка', 2, 5000),
('Сиамская кошка', 2, 4000),
('Мейн-кун', 2, 8000),
('Сфинкс', 2, 3500),
('Персидская кошка', 2, 4500),
('Бенгальская кошка', 2, 5500),
('Абиссинская кошка', 2, 4000),
('Русская голубая', 2, 4500),
('Бурманская кошка', 2, 5000),

-- Попугаи (animal_type_id = 3)
('Волнистый попугай', 3, 50),
('Корелла', 3, 100),
('Ара', 3, 1200),
('Жако', 3, 500),
('Какаду', 3, 800),
('Неразлучник', 3, 60),
('Розелла', 3, 150),
('Сенегальский попугай', 3, 150),
('Амазон', 3, 600),
('Лори', 3, 130),

-- Хомяки (animal_type_id = 4)
('Сирийский хомяк', 4, 150),
('Джунгарский хомяк', 4, 50),
('Хомяк Кэмпбелла', 4, 50),
('Хомяк Роборовского', 4, 30),
('Китайский хомяк', 4, 40),

-- Рыбки (animal_type_id = 5)
('Гуппи', 5, 5),
('Меченосец', 5, 8),
('Скалярия', 5, 30),
('Барбус', 5, 10),
('Золотая рыбка', 5, 50),
('Данио', 5, 5),
('Неон', 5, 3),
('Моллинезия', 5, 10),
('Петушок', 5, 6),
('Сомик', 5, 15),

-- Кролики (animal_type_id = 6)
('Карликовый кролик', 6, 1200),
('Кролик Баран', 6, 2000),
('Рекс', 6, 1500),
('Ангорский кролик', 6, 1800),
('Гермелин', 6, 1100),
('Львиная головка', 6, 1300),
('Вислоухий кролик', 6, 1600),
('Белый великан', 6, 5000),
('Черный великан', 6, 5200),
('Серебристый кролик', 6, 4500);

-- Получаем текущее количество записей
DO $$
DECLARE
    current_count INTEGER;
    needed_count INTEGER := 200;
    animal_type_record RECORD;
    i INTEGER;
    unique_name TEXT;
    name_exists BOOLEAN;
BEGIN
    -- Получаем текущее количество пород
    SELECT COUNT(*) INTO current_count FROM petshopschema.breed;
    
    -- Добавляем случайные породы до достижения нужного количества
    WHILE current_count < needed_count LOOP
        -- Генерируем уникальное имя
        LOOP
            unique_name := 'Порода_' || floor(random() * 1000000)::text || '_' || chr(65 + floor(random() * 26)::int);
            
            -- Проверяем, существует ли такое имя
            EXECUTE 'SELECT NOT EXISTS(SELECT 1 FROM petshopschema.breed WHERE breed_name = $1)'
            INTO name_exists USING unique_name;
            
            EXIT WHEN name_exists;
        END LOOP;
        
        -- Вставляем новую породу со случайным типом животных
        INSERT INTO petshopschema.breed (breed_name, animal_type_id, average_weight)
        SELECT 
            unique_name,
            id,
            floor(random() * 49000 + 1000)::int
        FROM petshopschema.animal_type 
        ORDER BY random() 
        LIMIT 1;
        
        current_count := current_count + 1;
    END LOOP;
END $$;

-- 1.4 Заполнение food (1000 позиций)
TRUNCATE petshopschema.food CASCADE;
WITH 
brands AS (SELECT unnest(ARRAY['Royal Canin', 'Purina', 'Hills', 'Acana', 'Orijen', 'Whiskas', 'Pedigree', 'Chappi', 'Sheba', 'Perfect Fit', 'Brit', 'Farmina']) as brand),
types AS (SELECT unnest(ARRAY['Сухой', 'Влажный', 'Консервы', 'Лакомство', 'Витамины', 'Лечебный']) as food_type)
INSERT INTO petshopschema.food (brand_name, food_type)
SELECT 
    brand,
    food_type
FROM brands CROSS JOIN types
ON CONFLICT (brand_name, food_type) DO NOTHING;

-- Добавляем ещё случайных брендов
INSERT INTO petshopschema.food (brand_name, food_type)
SELECT 
    'Бренд_' || (random()*1000)::int,
    'Тип_' || (random()*10)::int
FROM generate_series(1, 800)
ON CONFLICT DO NOTHING;

-- 1.5 Заполнение accessorie (500 аксессуаров)
TRUNCATE petshopschema.accessorie CASCADE;
INSERT INTO petshopschema.accessorie (name)
SELECT unnest(ARRAY[
    'Ошейник', 'Поводок', 'Миска', 'Игрушка', 'Когтеточка', 'Лежанка',
    'Переноска', 'Лоток', 'Наполнитель', 'Расческа', 'Шампунь', 'Амуниция',
    'Клетка', 'Аквариум', 'Террариум', 'Поилка', 'Кормушка', 'Домик'
]);

INSERT INTO petshopschema.accessorie (name)
SELECT 'Аксессуар_' || (random()*10000)::int
FROM generate_series(1, 482);

-- 1.6 Заполнение medication (300 лекарств)
TRUNCATE petshopschema.medication CASCADE;
INSERT INTO petshopschema.medication (name, description)
SELECT 
    'Лекарство_' || (random()*1000)::int as name,
    CASE WHEN random() < 0.7 
         THEN 'Описание_' || (random()*1000)::int 
         ELSE NULL 
    END as description
FROM generate_series(1, 300);

-- =====================================================
-- БЛОК 2: Заполнение клиентов (300,000 записей)
-- =====================================================

TRUNCATE petshopschema.client CASCADE;


DROP TABLE IF EXISTS temp_petshop_ids CASCADE;
DROP TABLE IF EXISTS temp_popular_petshops CASCADE;
DROP TABLE IF EXISTS temp_clients_staging CASCADE;

-- Создаем временную таблицу для хранения ID магазинов
CREATE TEMP TABLE temp_petshop_ids AS SELECT id FROM petshopschema.petshop;

-- Определяем популярные магазины (30% магазинов)
CREATE TEMP TABLE temp_popular_petshops AS 
SELECT id FROM temp_petshop_ids 
ORDER BY random() 
LIMIT (SELECT round(count(*) * 0.3) FROM temp_petshop_ids);

CREATE TEMP TABLE temp_passports AS
SELECT DISTINCT 
    LPAD((random()*999)::int::text, 3, '0') || '-' || 
    LPAD((random()*999999)::int::text, 6, '0') as passport_data
FROM generate_series(1, 350000)  -- Генерируем с запасом
LIMIT 300000;  -- Берём ровно 300,000 уникальных

-- Создаем индекс для ускорения
CREATE INDEX idx_temp_passports ON temp_passports(passport_data);

-- Создаем временную таблицу с именами и фамилиями
CREATE TEMP TABLE temp_names_surnames AS
WITH 
names_arr AS (
    SELECT unnest(ARRAY['Иван', 'Петр', 'Алексей', 'Дмитрий', 'Сергей', 
                        'Андрей', 'Максим', 'Владимир', 'Евгений', 'Михаил']) as name
),
surnames_arr AS (
    SELECT unnest(ARRAY['Иванов', 'Петров', 'Сидоров', 'Смирнов', 'Кузнецов',
                        'Попов', 'Васильев', 'Михайлов', 'Новиков', 'Федоров',
                        'Морозов', 'Волков', 'Алексеев', 'Лебедев', 'Семенов']) as surname
)
SELECT 
    n.name,
    s.surname,
    random() as rnd  -- для случайного выбора
FROM names_arr n
CROSS JOIN surnames_arr s;

-- Вставляем клиентов одним быстрым INSERT-ом
INSERT INTO petshopschema.client (name, surname, passport_data, petshop_id)
SELECT 
    ns.name,
    ns.surname,
    tp.passport_data,
    CASE 
        WHEN random() < 0.7 
        THEN (SELECT id FROM temp_popular_petshops ORDER BY random() LIMIT 1)
        ELSE (SELECT id FROM temp_petshop_ids 
              WHERE id NOT IN (SELECT id FROM temp_popular_petshops) 
              ORDER BY random() LIMIT 1)
    END as petshop_id
FROM temp_passports tp
CROSS JOIN LATERAL (
    SELECT name, surname 
    FROM temp_names_surnames 
    ORDER BY random() 
    LIMIT 1
) ns;

-- Проверка результатов
SELECT 
    'Всего клиентов:' as description,
    COUNT(*) as count
FROM petshopschema.client
UNION ALL
SELECT 
    'Уникальных паспортов:',
    COUNT(DISTINCT passport_data)
FROM petshopschema.client;

-- Убираем дубликаты паспортов (оставляем только уникальные)
DELETE FROM petshopschema.client 
WHERE id NOT IN (
    SELECT MIN(id) 
    FROM petshopschema.client 
    GROUP BY passport_data
);

-- Проверка, что все паспорта имеют правильную длину
SELECT 
    LENGTH(passport_data) as passport_length,
    COUNT(*) as count
FROM petshopschema.client
GROUP BY LENGTH(passport_data);
-- =====================================================
-- БЛОК 3: Заполнение сотрудников (800 записей)
-- =====================================================




TRUNCATE petshopschema.employee CASCADE;
DROP TABLE IF EXISTS temp_employee_distribution CASCADE;
-- Создаем распределение сотрудников по магазинам
CREATE TEMP TABLE temp_employee_distribution AS
SELECT 
    id as petshop_id,
    CASE 
        WHEN id IN (SELECT id FROM temp_popular_petshops) 
        THEN (random()*30 + 20)::int  -- 20-50 сотрудников в популярных
        ELSE (random()*10 + 5)::int    -- 5-15 в остальных
    END as employee_count
FROM temp_petshop_ids;

-- Заполняем сотрудников
INSERT INTO petshopschema.employee (name, surname, petshop_id, profession)
SELECT 
    CASE (random()*9)::int
        WHEN 0 THEN 'Алексей'
        WHEN 1 THEN 'Дмитрий'
        WHEN 2 THEN 'Сергей'
        WHEN 3 THEN 'Андрей'
        WHEN 4 THEN 'Максим'
        WHEN 5 THEN 'Елена'
        WHEN 6 THEN 'Ольга'
        WHEN 7 THEN 'Наталья'
        WHEN 8 THEN 'Татьяна'
        ELSE 'Мария'
    END as name,
    CASE (random()*9)::int
        WHEN 0 THEN 'Кузнецов'
        WHEN 1 THEN 'Попов'
        WHEN 2 THEN 'Васильев'
        WHEN 3 THEN 'Михайлов'
        WHEN 4 THEN 'Новиков'
        WHEN 5 THEN 'Федоров'
        WHEN 6 THEN 'Морозов'
        WHEN 7 THEN 'Волков'
        WHEN 8 THEN 'Алексеев'
        ELSE 'Лебедев'
    END as surname,
    ed.petshop_id,
    -- ИСПРАВЛЕНО: просто строки, без каста к enum типу
    CASE floor(random()*5)::int  -- 0-4 для 5 профессий
        WHEN 0 THEN 'Кипер'::petshopschema.profession_enum
        ELSE 'Уборщик'::petshopschema.profession_enum
    END::petshopschema.profession_enum as profession
FROM temp_employee_distribution ed
CROSS JOIN generate_series(1, ed.employee_count)
WHERE ed.employee_count > 0
LIMIT 800;


-- =====================================================
-- БЛОК 4: Заполнение питомцев (500,000 записей)
-- =====================================================

DROP TABLE IF EXISTS temp_client_ids CASCADE;
DROP TABLE IF EXISTS temp_breed_ids CASCADE;
DROP TABLE IF EXISTS temp_food_ids CASCADE;
DROP TABLE IF EXISTS temp_petshop_ids CASCADE;
DROP TABLE IF EXISTS temp_popular_petshops CASCADE;
DROP TABLE IF EXISTS temp_used_pet_names CASCADE;
DROP TABLE IF EXISTS temp_pet_names CASCADE;

CREATE TEMP TABLE temp_client_ids AS SELECT id FROM petshopschema.client;
CREATE TEMP TABLE temp_breed_ids AS SELECT id FROM petshopschema.breed;
CREATE TEMP TABLE temp_food_ids AS SELECT id FROM petshopschema.food;
CREATE TEMP TABLE temp_petshop_ids AS SELECT id FROM petshopschema.petshop;

CREATE TEMP TABLE temp_popular_petshops AS 
SELECT id FROM temp_petshop_ids 
ORDER BY random() 
LIMIT (SELECT round(count(*) * 0.3) FROM temp_petshop_ids);

CREATE TEMP TABLE temp_used_pet_names (
    owner_id INTEGER,
    pet_name VARCHAR(64),
    PRIMARY KEY (owner_id, pet_name)
);

CREATE TEMP TABLE temp_pet_names AS
SELECT unnest(ARRAY[
    'Барсик', 'Мурка', 'Шарик', 'Бобик', 'Рыжик', 'Пушок', 'Дружок', 'Черныш', 'Беляш', 'Тишка',
    'Васька', 'Кузя', 'Зевс', 'Арес', 'Симба', 'Нала', 'Боня', 'Люся', 'Мася', 'Грей',
    'Рекс', 'Лорд', 'Граф', 'Цезарь', 'Марс', 'Рокки', 'Буч', 'Джек', 'Макс', 'Чарли',
    'Белла', 'Луна', 'Стелла', 'Мила', 'Алиса', 'Жужа', 'Кнопка', 'Бусинка', 'Ласка', 'Ночка',
    'Том', 'Джерри', 'Кеша', 'Гоша', 'Яша', 'Проша', 'Фунтик', 'Пират', 'Тузик', 'Мухтар'
]) as name;

CREATE INDEX idx_temp_used_names ON temp_used_pet_names(owner_id, pet_name);

DO $$
DECLARE
    v_target_count INTEGER := 500000;
    v_current_count INTEGER;
    v_batch_size INTEGER := 1000;
    v_owner_ids INTEGER[];
    v_breed_ids INTEGER[];
    v_food_ids INTEGER[];
    v_petshop_ids INTEGER[];
    v_popular_ids INTEGER[];
    v_name_array TEXT[];
    v_random_owner INTEGER;
    v_random_name TEXT;
    v_age INTEGER;
    v_breed_id INTEGER;
    v_food_id INTEGER;
    v_petshop_id INTEGER;
    v_attempts INTEGER;
    v_max_attempts INTEGER := 100;
    v_inserted BOOLEAN;
BEGIN
    -- Получаем текущее количество питомцев
    SELECT COUNT(*) INTO v_current_count FROM petshopschema.pet;
    
    -- Если уже есть записи, обновляем цель
    IF v_current_count >= v_target_count THEN
        RAISE NOTICE 'Уже есть % записей, цель достигнута', v_current_count;
        RETURN;
    END IF;
    
    -- Загружаем данные в массивы
    SELECT array_agg(id) INTO v_owner_ids FROM temp_client_ids;
    SELECT array_agg(id) INTO v_breed_ids FROM temp_breed_ids;
    SELECT array_agg(id) INTO v_food_ids FROM temp_food_ids;
    SELECT array_agg(id) INTO v_petshop_ids FROM temp_petshop_ids;
    SELECT array_agg(id) INTO v_popular_ids FROM temp_popular_petshops;
    SELECT array_agg(name) INTO v_name_array FROM temp_pet_names;
    
    RAISE NOTICE 'Начинаем генерацию. Нужно: %, уже есть: %', v_target_count, v_current_count;
    
    -- Генерируем пока не достигнем цели
    WHILE v_current_count < v_target_count LOOP
        v_inserted := FALSE;
        v_attempts := 0;
        
        -- Пытаемся вставить с разными именами
        WHILE v_attempts < v_max_attempts AND NOT v_inserted LOOP
            -- Выбираем случайного владельца
            v_random_owner := v_owner_ids[1 + floor(random() * array_length(v_owner_ids, 1))];
            
            -- Выбираем случайное имя
            v_random_name := v_name_array[1 + floor(random() * array_length(v_name_array, 1))];
            
            -- Генерируем остальные данные
            v_age := CASE 
                WHEN random() < 0.5 THEN floor(random()*11 + 1)::int
                WHEN random() < 0.8 THEN floor(random()*24 + 13)::int
                WHEN random() < 0.95 THEN floor(random()*48 + 37)::int
                ELSE floor(random()*35 + 85)::int
            END;
            
            v_breed_id := v_breed_ids[1 + floor(random() * array_length(v_breed_ids, 1))];
            
            IF random() < 0.85 THEN
                v_food_id := v_food_ids[1 + floor(random() * array_length(v_food_ids, 1))];
            ELSE
                v_food_id := NULL;
            END IF;
            
            IF random() < 0.7 AND array_length(v_popular_ids, 1) > 0 THEN
                v_petshop_id := v_popular_ids[1 + floor(random() * array_length(v_popular_ids, 1))];
            ELSE
                v_petshop_id := v_petshop_ids[1 + floor(random() * array_length(v_petshop_ids, 1))];
            END IF;
            
            -- Пытаемся вставить с обработкой конфликта
            BEGIN
                INSERT INTO petshopschema.pet (
                    name, age, owner_id, breed_id, food_id, petshop_id
                ) VALUES (
                    v_random_name, v_age, v_random_owner, v_breed_id, v_food_id, v_petshop_id
                );
                
                -- Если вставка успешна, запоминаем использованное имя
                INSERT INTO temp_used_pet_names (owner_id, pet_name) 
                VALUES (v_random_owner, v_random_name)
                ON CONFLICT DO NOTHING;
                
                v_current_count := v_current_count + 1;
                v_inserted := TRUE;
                
                EXCEPTION WHEN unique_violation THEN
                    -- Имя уже занято, пробуем другое
                    v_attempts := v_attempts + 1;
            END;
        END LOOP;
        
        -- Если не удалось вставить после многих попыток, пробуем с другим владельцем
        IF NOT v_inserted THEN
            -- Просто пропускаем эту итерацию и пробуем снова
            NULL;
        END IF;
        
        -- Прогресс
        IF v_current_count % 10000 = 0 THEN
            RAISE NOTICE 'Сгенерировано % питомцев', v_current_count;
            COMMIT;
        END IF;
    END LOOP;
    
    RAISE NOTICE 'Генерация завершена! Всего: %', v_current_count;
END;
$$;


SELECT 
    'Всего питомцев:' as description,
    COUNT(*) as count
FROM petshopschema.pet
UNION ALL
SELECT 
    'Уникальных (владелец + имя):',
    COUNT(*)
FROM (
    SELECT owner_id, name, COUNT(*) 
    FROM petshopschema.pet 
    GROUP BY owner_id, name
) t
UNION ALL
SELECT 
    'NULL food_id:',
    COUNT(*)
FROM petshopschema.pet
WHERE food_id IS NULL;


SELECT 
    pets_per_owner,
    COUNT(*) as owners_count
FROM (
    SELECT owner_id, COUNT(*) as pets_per_owner
    FROM petshopschema.pet
    GROUP BY owner_id
) t
GROUP BY pets_per_owner
ORDER BY pets_per_owner;


-- Аксессуары питомцев
TRUNCATE petshopschema.pet_accessorie CASCADE;
INSERT INTO petshopschema.pet_accessorie (pet_id, accessorie_id)
SELECT DISTINCT
    p.id,
    a.id
FROM petshopschema.pet p
CROSS JOIN LATERAL (
    SELECT id FROM petshopschema.accessorie 
    WHERE random() < 0.01  -- Каждый питомец имеет ~1% шанс получить каждый аксессуар
    ORDER BY random() 
    LIMIT (random()*5)::int + 1
) a
WHERE random() < 0.4  -- 40% питомцев имеют аксессуары
ON CONFLICT DO NOTHING;






-- Лекарства питомцев
TRUNCATE petshopschema.pet_medication CASCADE;
INSERT INTO petshopschema.pet_medication (pet_id, medication_id)
SELECT DISTINCT
    p.id,
    m.id
FROM petshopschema.pet p
CROSS JOIN LATERAL (
    SELECT id FROM petshopschema.medication 
    WHERE random() < 0.005
    ORDER BY random() 
    LIMIT (random()*2)::int + 1
) m
WHERE random() < 0.3  -- 30% питомцев на лекарствах
ON CONFLICT DO NOTHING;





-- =====================================================
-- БЛОК 6: Заполнение клеток (600,000 записей)
-- =====================================================

TRUNCATE petshopschema.cage CASCADE;

-- Создаём клетки
INSERT INTO petshopschema.cage (animal_type_id, current_pet_id, petshop_id)
SELECT 
    CASE WHEN random() < 0.8 
         THEN (SELECT id FROM petshopschema.animal_type ORDER BY random() LIMIT 1)
         ELSE NULL 
    END as animal_type_id,
    NULL as current_pet_id,  -- Пока без питомцев
    (SELECT id FROM temp_petshop_ids ORDER BY random() LIMIT 1) as petshop_id
FROM generate_series(1, 600000);






-- ====================================
ДО СЮДА НОРМ

-- ШАГ 1: Очищаем текущих питомцев в клетках
UPDATE petshopschema.cage SET current_pet_id = NULL;

-- ШАГ 2: Создаем временную таблицу с питомцами, которых будем рассаживать
DROP TABLE IF EXISTS temp_pets_for_cages;
CREATE TEMP TABLE temp_pets_for_cages AS
SELECT 
    p.id as pet_id,
    p.petshop_id,
    b.animal_type_id
FROM petshopschema.pet p
LEFT JOIN petshopschema.breed b ON p.breed_id = b.id
WHERE random() < 0.7  -- 70% питомцев
ORDER BY random()
LIMIT (SELECT round(count(*) * 0.7) FROM petshopschema.pet);

-- Создаем индексы для ускорения
CREATE INDEX idx_temp_pets_shop ON temp_pets_for_cages(petshop_id);
CREATE INDEX idx_temp_pets_type ON temp_pets_for_cages(animal_type_id);

-- ШАГ 3: Создаем временную таблицу с доступными клетками
DROP TABLE IF EXISTS temp_available_cages;
CREATE TEMP TABLE temp_available_cages AS
SELECT 
    id as cage_id,
    petshop_id,
    animal_type_id
FROM petshopschema.cage
WHERE current_pet_id IS NULL;

CREATE INDEX idx_temp_cages_shop ON temp_available_cages(petshop_id);
CREATE INDEX idx_temp_cages_type ON temp_available_cages(animal_type_id);

-- ШАГ 4: Быстрое распределение (используем курсор для пошаговой обработки)
DO $$
DECLARE
    v_pet_record RECORD;
    v_cage_id INTEGER;
    v_updated_count INTEGER := 0;
    v_total_pets INTEGER;
BEGIN
    -- Получаем общее количество питомцев для распределения
    SELECT COUNT(*) INTO v_total_pets FROM temp_pets_for_cages;
    RAISE NOTICE 'Начинаем распределение % питомцев', v_total_pets;
    
    -- Создаем курсор для итерации по питомцам
    FOR v_pet_record IN SELECT pet_id, petshop_id, animal_type_id FROM temp_pets_for_cages LOOP
        -- Ищем подходящую клетку
        SELECT cage_id INTO v_cage_id
        FROM temp_available_cages
        WHERE petshop_id = v_pet_record.petshop_id
          AND (animal_type_id IS NULL OR animal_type_id = v_pet_record.animal_type_id)
        LIMIT 1
        FOR UPDATE SKIP LOCKED;  -- Блокируем клетку для обновления
        
        -- Если нашли клетку
        IF v_cage_id IS NOT NULL THEN
            -- Обновляем клетку
            UPDATE petshopschema.cage 
            SET current_pet_id = v_pet_record.pet_id
            WHERE id = v_cage_id;
            
            -- Удаляем использованную клетку из временной таблицы
            DELETE FROM temp_available_cages WHERE cage_id = v_cage_id;
            
            v_updated_count := v_updated_count + 1;
            
            IF v_updated_count % 10000 = 0 THEN
                RAISE NOTICE 'Распределено % питомцев', v_updated_count;
                COMMIT;
            END IF;
        END IF;
    END LOOP;
    
    RAISE NOTICE 'Распределение завершено! Посажено % питомцев', v_updated_count;
END;
$$;

-- ШАГ 5: Проверка результатов
SELECT 
    'Всего клеток:' as description,
    COUNT(*) as count
FROM petshopschema.cage
UNION ALL
SELECT 
    'Занято клеток:',
    COUNT(*) 
FROM petshopschema.cage
WHERE current_pet_id IS NOT NULL
UNION ALL
SELECT 
    'Пустых клеток:',
    COUNT(*)
FROM petshopschema.cage
WHERE current_pet_id IS NULL;

-- Очистка
DROP TABLE IF EXISTS temp_pets_for_cages;
DROP TABLE IF EXISTS temp_available_cages;



-- =====================================================
-- БЛОК 7: Заполнение cleaning_assignments (800,000 записей)
-- =====================================================

TRUNCATE petshopschema.cleaning_assignments CASCADE;

-- Получаем ID уборщиков
CREATE TEMP TABLE temp_cleaner_ids AS 
SELECT id FROM petshopschema.employee WHERE profession = 'cleaner';

-- Заполняем задания по уборке
INSERT INTO petshopschema.cleaning_assignments (cleaner_id, cage_id, cleaning_date, is_completed)
SELECT 
    (SELECT id FROM temp_cleaner_ids OFFSET floor(random() * (SELECT count(*) FROM temp_cleaner_ids)) LIMIT 1) as cleaner_id,
    c.id as cage_id,
    (CURRENT_DATE - (random()*30)::int * interval '1 day')::date as cleaning_date,
    random() < 0.9 as is_completed  -- 90% выполнены
FROM petshopschema.cage c
CROSS JOIN generate_series(1, 2)  -- Каждая клетка убирается примерно 2 раза
WHERE random() < 0.7  -- Но не все уборки попадают в БД
LIMIT 800000
ON CONFLICT DO NOTHING;

-- =====================================================
-- БЛОК 8: Заполнение keeper_assignments (400,000 записей)
-- =====================================================

TRUNCATE petshopschema.keeper_assignments CASCADE;

-- Получаем ID киперов
DROP TABLE IF EXISTS temp_cleaner_ids CASCADE;
CREATE TEMP TABLE temp_keeper_ids AS 
SELECT id FROM petshopschema.employee WHERE profession = 'Уборщик';

-- Заполняем назначения киперов
INSERT INTO petshopschema.keeper_assignments (keeper_id, pet_id, assignment_date)
SELECT 
    (SELECT id FROM temp_keeper_ids OFFSET floor(random() * (SELECT count(*) FROM temp_keeper_ids)) LIMIT 1) as keeper_id,
    p.id as pet_id,
    (CURRENT_DATE - (random()*365)::int * interval '1 day')::date as assignment_date
FROM petshopschema.pet p
CROSS JOIN generate_series(1, CASE 
    WHEN random() < 0.7 THEN 1
    WHEN random() < 0.9 THEN 2
    ELSE 3
END)  -- У питомца может быть 1-3 кипера
WHERE random() < 0.8  -- 80% питомцев имеют киперов
LIMIT 400000
ON CONFLICT DO NOTHING;

-- =====================================================
-- БЛОК 9: Проверочные запросы
-- =====================================================

-- Подсчёт записей в таблицах
SELECT 'petshop' as table_name, COUNT(*) as rows_count FROM petshopschema.petshop
UNION ALL
SELECT 'animal_type', COUNT(*) FROM petshopschema.animal_type
UNION ALL
SELECT 'breed', COUNT(*) FROM petshopschema.breed
UNION ALL
SELECT 'food', COUNT(*) FROM petshopschema.food
UNION ALL
SELECT 'accessorie', COUNT(*) FROM petshopschema.accessorie
UNION ALL
SELECT 'medication', COUNT(*) FROM petshopschema.medication
UNION ALL
SELECT 'client', COUNT(*) FROM petshopschema.client
UNION ALL
SELECT 'employee', COUNT(*) FROM petshopschema.employee
UNION ALL
SELECT 'pet', COUNT(*) FROM petshopschema.pet
UNION ALL
SELECT 'cage', COUNT(*) FROM petshopschema.cage
UNION ALL
SELECT 'cleaning_assignments', COUNT(*) FROM petshopschema.cleaning_assignments
UNION ALL
SELECT 'keeper_assignments', COUNT(*) FROM petshopschema.keeper_assignments
UNION ALL
SELECT 'pet_accessorie', COUNT(*) FROM petshopschema.pet_accessorie
UNION ALL
SELECT 'pet_medication', COUNT(*) FROM petshopschema.pet_medication
ORDER BY 1;

-- Проверка распределения клиентов по магазинам (перекос)
SELECT 
    petshop_id,
    COUNT(*) as client_count
FROM petshopschema.client
GROUP BY petshop_id
ORDER BY client_count DESC
LIMIT 10;

-- Проверка NULL значений
SELECT 
    'pet.food_id' as column_name,
    COUNT(*) as total,
    COUNT(food_id) as non_null,
    COUNT(*) - COUNT(food_id) as null_count,
    ROUND(100.0 * (COUNT(*) - COUNT(food_id)) / COUNT(*), 2) as null_percent
FROM petshopschema.pet;

-- Очистка временных таблиц
DROP TABLE IF EXISTS temp_petshop_ids;
DROP TABLE IF EXISTS temp_popular_petshops;
DROP TABLE IF EXISTS temp_employee_distribution;
DROP TABLE IF EXISTS temp_client_ids;
DROP TABLE IF EXISTS temp_breed_ids;
DROP TABLE IF EXISTS temp_food_ids;
DROP TABLE IF EXISTS temp_cleaner_ids;
DROP TABLE IF EXISTS temp_keeper_ids;