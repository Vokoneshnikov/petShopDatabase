1. Посчитай, сколько питомцев у каждого клиента, и выведи ТОП‑5 владельцев с наибольшим числом животных.

```
with pet_counts as (
 select 
  c.id, c.name, c.surname, count(p.id) as pet_count
 from client c 
 join pet p on c.id = p.owner_id 
 group by c.id, c.name, c.surname 
)
select * 
from pet_counts
order by pet_count desc 
limit 5;
```
<img width="956" height="274" alt="image" src="https://github.com/user-attachments/assets/d99b2694-5dec-4283-830a-4bab915644ae" />

2. --через два связанных CTE вычисли средний возраст питомцев для каждого типа животного. Сначала найди соответствие между pet → breed → animal_type, а затем рассчитай средний возраст по каждому animal_type.
```
with pet_type as (
    select 
        p.id as pet_id,
        p.age,
        a.name as animal_type
    from pet p
    join breed b on p.breed_id = b.id
    join animal_type a on b.animal_type_id = a.id
),
type_avg as (
    select 
        animal_type,
        round(avg(age), 2) as avg_age
    from pet_type
    group by animal_type
)
select *
from type_avg
order by avg_age desc;
```
<img width="666" height="566" alt="image" src="https://github.com/user-attachments/assets/4b9063aa-d5db-4969-a3ca-d0ef21bba448" />

3. --Найди сотрудников, ответственных за животных, которым требуется лечение
```
WITH cage_pets AS (
    SELECT 
        c.id AS cage_id,
        c.current_pet_id AS pet_id
    FROM cage c
    WHERE c.current_pet_id IS NOT NULL
),
pet_meds AS (
    SELECT 
        cp.cage_id,
        m.name AS medication_name
    FROM cage_pets cp
    JOIN pet_medication pm ON cp.pet_id = pm.pet_id
    JOIN medication m ON pm.medication_id = m.id
),
emp_meds AS (
    SELECT 
        e.name AS employee_name,
        e.surname AS employee_surname,
        pm.medication_name
    FROM employee e
    JOIN pet_meds pm ON e.cage_id = pm.cage_id
)
SELECT *
FROM emp_meds
ORDER BY employee_name;
```

4. --UNION.
Найди все имена, встречающиеся среди клиентов и сотрудников (имена могут повторяться в жизни, но нам важны только уникальные).
```
select name 
from client c
union
select name
from employee e
```

5. Выведи все названия магазинов и породы, чтобы посмотреть, какие имена вообще встречаются в магазине.
```
select name from petshop p 
union
select breed_name from breed b
```

6. Показать все типы животных и типы кормов, чтобы сравнить их номенклатуру.
```
SELECT name FROM animal_type
UNION
SELECT food_type FROM food;
```

7. --intersect Найди имена, которые встречаются и у сотрудников, и у клиентов (одно и то же имя у разных людей).
```
select name from client
intersect 
select name from employee;
```

8. --Показать идентификаторы питомцев, которые одновременно находятся в клетках и имеют назначенные лекарства.
```
select current_pet_id from cage where current_pet_id is not null
intersect 
select pet_id from pet_medication;
```
9. --except Вывести все виды животных, для которых нет ни одной породы.
```
select id, name from animal_type
except
select a.id, a.name
from animal_type a
join breed b on b.animal_type_id = a.id;
```

10. --Найди общее количество питомцев у каждого владельца и отобрази его в каждой строке (с деталями о питомце).
```
SELECT
    p.id AS pet_id,
    c.name  ' '  c.surname AS owner_name,
    p.name AS pet_name,
    COUNT(*) OVER (PARTITION BY p.owner_id) AS total_pets_for_owner
FROM pet p
JOIN client c ON c.id = p.owner_id;
```

11. --Пронумеруй питомцев каждого владельца по возрасту (от старшего к младшему).
```
SELECT
    c.name  ' '  c.surname AS owner_name,
    p.name AS pet_name,
    p.age,
    ROW_NUMBER() OVER (PARTITION BY p.owner_id ORDER BY p.age DESC) AS pet_rank
FROM pet p
JOIN client c ON c.id = p.owner_id;
```

12. --Для каждого питомца покажи средний возраст по его владельцу, включая самого питомца и его "соседей" по владельцу (до 1 вверх и вниз).
```
SELECT
    p.id,
    p.name,
    p.age,
    c.name AS owner_name,
    ROUND(AVG(p.age) OVER (
        PARTITION BY p.owner_id
        ORDER BY p.age
        ROWS BETWEEN 1 PRECEDING AND 1 FOLLOWING
    ), 2) AS avg_neighbor_age
FROM pet p
JOIN client c ON c.id = p.owner_id;
```

13. --Для каждого питомца — посчитать, сколько питомцев его владельца находятся в пределах ±2 лет возраста.
```
SELECT
    p.name,
    p.age,
    COUNT(*) OVER (
        PARTITION BY p.owner_id
        ORDER BY p.age
        RANGE BETWEEN 2 PRECEDING AND 2 FOLLOWING
    ) AS count_in_range
FROM pet p;
```

14. --Питомцы, отсортированные по возрасту внутри каждого питомника с возможными пропусками в ранге.
```
SELECT
    p.name,
    p.age,
    pt.name AS shop_name,
    RANK() OVER (PARTITION BY p.petshop_id ORDER BY p.age DESC) AS age_rank
FROM pet p
JOIN petshop pt ON pt.id = p.petshop_id;
```

15. --То же самое, но без "пробелов" в ранге при совпадении возраста.
```
SELECT
    p.name,
    p.age,
    pt.name AS shop_name,
    DENSE_RANK() OVER (PARTITION BY p.petshop_id ORDER BY p.age DESC) AS dense_age_rank
FROM pet p
JOIN petshop pt ON pt.id = p.petshop_id;
```

16. --Найди самого старшего питомца в каждой клетке.
```
WITH ranked AS (
    SELECT
        p.*,
        ROW_NUMBER() OVER (PARTITION BY c.id ORDER BY p.age DESC) AS rn
    FROM cage c
    JOIN pet p ON c.current_pet_id = p.id
)
SELECT *
FROM ranked
WHERE rn = 1;
```

17. --Покажи возраст предыдущего питомца по возрасту среди всех.
```
SELECT
    name,
    age,
    LAG(age) OVER (ORDER BY age) AS prev_pet_age
from pet;
```

18. --Покажи возраст следующего питомца.
```
SELECT
    name,
    age,
    LEAD(age) OVER (ORDER BY age) AS next_pet_age
FROM pet;
```

19. --Покажи самого младшего питомца в каждом магазине.
```
SELECT
    p.name,
    p.age,
    pt.name AS shop_name,
    FIRST_VALUE(p.age) OVER (PARTITION BY p.petshop_id ORDER BY p.age ASC) AS youngest_age_in_shop
FROM pet p
JOIN petshop pt ON pt.id = p.petshop_id;
```

20. --Покажи самого старшего питомца в каждом магазине (только с рамкой ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING — иначе результат будет некорректен).
```
SELECT
    p.name,
    p.age,
    pt.name AS shop_name,
    LAST_VALUE(p.age) OVER (
        PARTITION BY p.petshop_id 
        ORDER BY p.age ASC
        ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING
    ) AS oldest_age_in_shop
FROM pet p
JOIN petshop pt ON pt.id = p.petshop_id;
```

21. 
22. 
