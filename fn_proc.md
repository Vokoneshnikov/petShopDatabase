# Процедуры
1. Добавить питомца с проверкой вместимости (IF + RAISE)
```
CREATE OR REPLACE PROCEDURE petshopschema.add_pet_to_petshop(
    p_name        varchar,
    p_age         int,
    p_owner_id    int,
    p_breed_id    int,
    p_food_id     int,
    p_petshop_id  int
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_capacity int;
    v_current  int;
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
    p_pet_id        int,
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
    p_pet_id  int,
    p_cage_id int
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_pet_type_id   int;
    v_cage_type_id  int;
    v_current_pet   int;
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
    WHERE id = $1;
$$;
```

6. Возвращает кол-во питомцев в питомнике
```
CREATE OR REPLACE FUNCTION petshopschema.fn_petshop_pet_count(p_petshop_id int)
RETURNS int
LANGUAGE sql
AS $$
    SELECT COUNT(*)
    FROM petshopschema.pet
    WHERE petshop_id = $1;
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
    WHERE p.id = $1;
$$;
```

8. 
9. 
10. 
11.
12.
13.
14.
15.
16. 
17.
18.
19.
