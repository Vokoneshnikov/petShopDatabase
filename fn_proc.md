# Процедуры
1. Добавить питомца с проверкой вместимости (IF + RAISE)
```
CREATE OR REPLACE PROCEDURE petshopschema.add_pet_to_petshop(
    p_name varchar,
    p_age int,
    p_owner_id int,
    p_breed_id int,
    p_food_id int,
    p_petshop_id int
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_capacity int;
    v_current int;
BEGIN
    SELECT pets_capacity
    INTO v_capacity
    FROM petshopschema.petshop
    WHERE id = p_petshop_id;

    IF v_capacity IS NULL THEN
        RAISE EXCEPTION 'Petshop % not found', p_petshop_id;
    END IF;

    SELECT COUNT(*)
    INTO v_current
    FROM petshopschema.pet
    WHERE petshop_id = p_petshop_id;

    IF v_current >= v_capacity THEN
        RAISE EXCEPTION
            'Petshop % is full: % / % pets',
            p_petshop_id, v_current, v_capacity;
    END IF;

    INSERT INTO petshopschema.pet(name, age, owner_id, breed_id, food_id, petshop_id)
    VALUES (p_name, p_age, p_owner_id, p_breed_id, p_food_id, p_petshop_id);
END;
$$;
```

2. Перевести питомца в другой зоомагазин
```
CREATE OR REPLACE PROCEDURE petshopschema.transfer_pet_to_petshop(
    p_pet_id int,
    p_new_petshop_id int
)
LANGUAGE plpgsql
AS $$
BEGIN
    UPDATE petshopschema.pet
    SET petshop_id = p_new_petshop_id
    WHERE id = p_pet_id;
END;
$$;
```

3. Поселить питомца в клетку (CASE + RAISE)
```
CREATE OR REPLACE PROCEDURE petshopschema.assign_pet_to_cage(
    p_pet_id int,
    p_cage_id int
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_pet_type_id int;
    v_cage_type_id int;
    v_current_pet int;
BEGIN
    SELECT b.animal_type_id
    INTO v_pet_type_id
    FROM petshopschema.pet p
    JOIN petshopschema.breed b ON p.breed_id = b.id
    WHERE p.id = p_pet_id;

    SELECT animal_type_id, current_pet_id
    INTO v_cage_type_id, v_current_pet
    FROM petshopschema.cage
    WHERE id = p_cage_id;

    CASE
        WHEN v_pet_type_id IS NULL THEN
            RAISE EXCEPTION 'Pet % has no breed/type', p_pet_id;

        WHEN v_cage_type_id IS NULL THEN
            RAISE EXCEPTION 'Cage % has no animal type', p_cage_id;

        WHEN v_cage_type_id <> v_pet_type_id THEN
            RAISE EXCEPTION
              'Cage % type (%) does not match pet % type (%)',
              p_cage_id, v_cage_type_id, p_pet_id, v_pet_type_id;

        WHEN v_current_pet IS NOT NULL THEN
            RAISE EXCEPTION
              'Cage % is already occupied by pet %',
              p_cage_id, v_current_pet;

        ELSE
            UPDATE petshopschema.cage
            SET current_pet_id = p_pet_id
            WHERE id = p_cage_id;

            RAISE NOTICE 'Pet % assigned to cage %', p_pet_id, p_cage_id;
    END CASE;
END;
$$;
```

4. Запрос просмотра всех процедур
```
SELECT routine_schema, routine_name
FROM information_schema.routines
WHERE routine_type = 'PROCEDURE'
  AND routine_schema = 'petshopschema';
```
# Функции
5. Возвращает возраст питомца
```
CREATE OR REPLACE FUNCTION petshopschema.fn_get_pet_age(p_pet_id int)
RETURNS int
LANGUAGE sql
AS $$
    SELECT age
    FROM petshopschema.pet
    WHERE id = p_pet_id;
$$;
```

6. Возвращает кол-во питомцев в питомнике
```
CREATE OR REPLACE FUNCTION petshopschema.petshop_pet_count(p_petshop_id int)
RETURNS int
LANGUAGE sql
AS $$
    SELECT COUNT(*)
    FROM petshopschema.pet
    WHERE petshop_id = p_petshop_id;
$$;
```

7. Возвращает имя питомца и фамилию владельца
```
CREATE OR REPLACE FUNCTION petshopschema.fn_pet_and_owner(p_pet_id int)
RETURNS text
LANGUAGE sql
AS $$
    SELECT p.name || ' (' || COALESCE(c.surname, 'no owner') || ')'
    FROM petshopschema.pet p
    LEFT JOIN petshopschema.client c ON c.id = p.owner_id
    WHERE p.id = p_pet_id;
$$;
```
# Функции с переменными
8. Возвращает свободные места в питомнике
```
CREATE OR REPLACE FUNCTION petshopschema.fn_petshop_free_places(p_petshop_id int)
RETURNS int
LANGUAGE plpgsql
AS $$
DECLARE
    v_capacity int;
    v_count int;
    v_free int;
BEGIN
    SELECT pets_capacity
    INTO v_capacity
    FROM petshopschema.petshop
    WHERE id = p_petshop_id;

    IF v_capacity IS NULL THEN
        RAISE EXCEPTION 'Petshop % not found', p_petshop_id;
    END IF;

    SELECT COUNT(*)
    INTO v_count
    FROM petshopschema.pet
    WHERE petshop_id = p_petshop_id;

    v_free := v_capacity - v_count;
    RETURN v_free;

EXCEPTION
    WHEN others THEN
        RAISE NOTICE 'Error in fn_petshop_free_places: %', SQLERRM;
        RETURN NULL;
END;
$$;
```

9. Возвращает кол-во аксессуаров у питомца
```
CREATE OR REPLACE FUNCTION petshopschema.fn_total_accessories_for_pet(p_pet_id int)
RETURNS int
LANGUAGE plpgsql
AS $$
DECLARE
    v_total int;
BEGIN
    SELECT COALESCE(SUM(amount), 0)
    INTO v_total
    FROM petshopschema.pet_accessorie
    WHERE pet_id = p_pet_id;

    RETURN v_total;
END;
$$;
```

10. Возвращает кол-во животных определеннего типа
```
CREATE OR REPLACE FUNCTION petshopschema.fn_count_pets_by_type(p_type_name text)
RETURNS int
LANGUAGE plpgsql
AS $$
DECLARE
    v_type_id int;
    v_cnt int;
BEGIN
    SELECT id
    INTO v_type_id
    FROM petshopschema.animal_type
    WHERE name = p_type_name;

    IF v_type_id IS NULL THEN
        RAISE EXCEPTION 'Animal type % not found', p_type_name;
    END IF;

    SELECT COUNT(*)
    INTO v_cnt
    FROM petshopschema.pet p
    JOIN petshopschema.breed b ON p.breed_id = b.id
    WHERE b.animal_type_id = v_type_id;

    RETURN v_cnt;
END;
$$;

```

11. Запрос просмотра всех функций
```
SELECT routine_schema, routine_name, data_type
FROM information_schema.routines
WHERE routine_type = 'FUNCTION'
  AND routine_schema = 'petshopschema';
```

12. Заполнение питомника, пока не кончится место
```
DO $$
DECLARE
    v_petshop_id int := 1;     -- предположим, что магазин с id=1 существует
    v_capacity int;
    v_count int;
    i int := 1;
BEGIN
    SELECT pets_capacity
    INTO v_capacity
    FROM petshopschema.petshop
    WHERE id = v_petshop_id;

    SELECT COUNT(*)
    INTO v_count
    FROM petshopschema.pet
    WHERE petshop_id = v_petshop_id;

    WHILE v_count < v_capacity LOOP
        INSERT INTO petshopschema.pet(name, age, petshop_id)
        VALUES ('GeneratedPet_' || i, 1 + i % 10, v_petshop_id);

        v_count := v_count + 1;
        i := i + 1;

        RAISE NOTICE 'Added pet %. Now count = %', i, v_count;
    END LOOP;

    RAISE NOTICE 'Petshop % is now full (% pets)', v_petshop_id, v_count;
END;
$$;
```

13. Проверка соотношения клеток с питомцами
```
DO $$
DECLARE
    v_pets int;
    v_cages int;
BEGIN
    SELECT COUNT(*) INTO v_pets FROM petshopschema.pet;
    SELECT COUNT(*) INTO v_cages FROM petshopschema.cage;

    CASE
        WHEN v_pets = 0 THEN
            RAISE NOTICE 'Нет клеток';
        WHEN v_pets <= v_cages THEN
            RAISE NOTICE 'Все ок, клеток хватит на питомцев';
        ELSE
            RAISE NOTICE 'Клеток меньше, чем питомцев. Плохо!';
    END CASE;
END;
$$;

```

14. Проверка корректности паспортных данных
```
DO $$
BEGIN
    BEGIN
        -- пробуем добавить клиента с существующими паспортными данными
        INSERT INTO petshopschema.client(name, surname, passport_data)
        VALUES ('Test', 'Duplicate', 'AB12345678');

        RAISE NOTICE 'Client inserted successfully';

    EXCEPTION
        WHEN unique_violation THEN
            RAISE NOTICE 'Client with this passport number already exists';

        WHEN others THEN
            RAISE NOTICE 'Unexpected error: %', SQLERRM;
    END;
END;
$$;
```
