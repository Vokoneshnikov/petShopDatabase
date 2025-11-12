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
<img width="1194" height="558" alt="image" src="https://github.com/user-attachments/assets/093c80cb-5416-45a5-9d30-dd6a42fcad84" />

4. Количество аксессуаров у каждого питомца
```
with pet_access_count as (
    select 
        p.id as pet_id,
        p.name as pet_name,
        count(pa.accessorie_id) as accessories_count
    from petshopschema.pet p
    left join petshopschema.pet_accessorie pa on p.id = pa.pet_id
    group by p.id, p.name
),
with_most_accessories as (
    select 
        pet_name,
        accessories_count
    from pet_access_count
    where accessories_count = (
        select max(accessories_count) from pet_access_count
    )
)
select *
from with_most_accessories
```

<img width="357" height="147" alt="image" src="https://github.com/user-attachments/assets/92fe2493-b686-4793-935f-5c3f62cdabab" />

5. Средний вес пород по типу животных
(группировка по типам животных, вычисляется средний вес пород)
```
with breed_weights as (
    select 
        b.id as breed_id,
        b.breed_name,
        a.name as animal_type,
        b.average_weight
    from petshopschema.breed b
    join animal_type a on b.animal_type_id = a.id
),
type_weight_avg as (
    select 
        animal_type,
        round(avg(average_weight), 2) as avg_breed_weight
    from breed_weights
    group by animal_type
)
select *
from type_weight_avg
order by avg_breed_weight desc;
```
<img width="380" height="158" alt="image" src="https://github.com/user-attachments/assets/d43ca97f-8a05-476b-a725-39f3fd1f39a5" />

6.   --UNION.
Найди все имена, встречающиеся среди клиентов и сотрудников (имена могут повторяться в жизни, но нам важны только уникальные).
```
select name 
from client c
union
select name
from employee e
```
<img width="496" height="560" alt="image" src="https://github.com/user-attachments/assets/2faa0828-eba0-4135-80ef-2c2afd17c984" />

7. Выведи все названия магазинов и породы, чтобы посмотреть, какие имена вообще встречаются в магазине.
```
select name from petshop p 
union
select breed_name from breed b
```
<img width="584" height="474" alt="image" src="https://github.com/user-attachments/assets/040c9955-2b6f-4f34-9592-81ed4a4ac2e9" />

8. Показать все типы животных и типы кормов, чтобы сравнить их номенклатуру.
```
SELECT name FROM animal_type
UNION
SELECT food_type FROM food;
```
<img width="550" height="606" alt="image" src="https://github.com/user-attachments/assets/4333d455-44eb-4537-9696-4abf18a90b87" />

9. --intersect Найди имена, которые встречаются и у сотрудников, и у клиентов (одно и то же имя у разных людей).
```
select name from client
intersect 
select name from employee;
```
<img width="568" height="368" alt="image" src="https://github.com/user-attachments/assets/74298544-4cb5-4de1-8e28-906bc7cf163f" />

10. --Показать идентификаторы питомцев, которые одновременно находятся в клетках и имеют назначенные лекарства.
```
select current_pet_id from cage where current_pet_id is not null
intersect 
select pet_id from pet_medication;
```
<img width="508" height="566" alt="image" src="https://github.com/user-attachments/assets/aa81483f-78bb-4762-807b-e841085b3926" />

11. Питомцы, находящиеся в клетках и имеющие лекарства
```
select current_pet_id
from petshopschema.cage
where current_pet_id is not null
intersect
select pet_id
from petshopschema.pet_medication;
```
<img width="182" height="131" alt="image" src="https://github.com/user-attachments/assets/34c50d6e-c014-479e-a267-69452243263a" />

12.  --except Вывести все виды животных, для которых нет ни одной породы.
```
select id, name from animal_type
except
select a.id, a.name
from animal_type a
join breed b on b.animal_type_id = a.id;
```
<img width="724" height="406" alt="image" src="https://github.com/user-attachments/assets/db10ec8c-407f-4828-8a0d-19811e8976d6" />

13. Питомцы, у которых нет ни одного аксессуара
```
select id, name
from petshopschema.pet
except
select p.id, p.name
from petshopschema.pet p
join petshopschema.pet_accessorie pa on p.id = pa.pet_id;
```
<img width="229" height="124" alt="image" src="https://github.com/user-attachments/assets/e6ea6d54-10bc-46b6-9868-ee4f0ab9e02d" />

14. Клетки без питомцев
```
select id
from petshopschema.cage
except
select id
from petshopschema.cage
where current_pet_id is not null;
```
<img width="105" height="111" alt="image" src="https://github.com/user-attachments/assets/272921e4-0c12-4b7c-bfd0-04ac74057917" />

15. --Найди общее количество питомцев у каждого владельца и отобрази его в каждой строке (с деталями о питомце).
```
SELECT
    p.id AS pet_id,
    c.name  ' '  c.surname AS owner_name,
    p.name AS pet_name,
    COUNT(*) OVER (PARTITION BY p.owner_id) AS total_pets_for_owner
FROM pet p
JOIN client c ON c.id = p.owner_id;
```
<img width="1386" height="582" alt="image" src="https://github.com/user-attachments/assets/5bbb9f88-8048-4613-ae1b-8c13d98c5770" />

16. Средний возраст питомцев по типу животного, показывая каждого питомца и его тип
```
select 
    p.id as pet_id,
    p.name as pet_name,
    a.name as animal_type,
    p.age,
    round(avg(p.age) over (partition by a.name), 2) as avg_age_for_type
from pet p
join breed b on p.breed_id = b.id
join animal_type a on b.animal_type_id = a.id
order by animal_type, pet_name;
```
<img width="796" height="158" alt="image" src="https://github.com/user-attachments/assets/d1947200-d804-4408-9389-8e90538ccbe4" />

17.  --Пронумеруй питомцев каждого владельца по возрасту (от старшего к младшему).
```
SELECT
    c.name  ' '  c.surname AS owner_name,
    p.name AS pet_name,
    p.age,
    ROW_NUMBER() OVER (PARTITION BY p.owner_id ORDER BY p.age DESC) AS pet_rank
FROM pet p
JOIN client c ON c.id = p.owner_id;
```
<img width="1202" height="568" alt="image" src="https://github.com/user-attachments/assets/c5ca2ebb-140c-45fc-a02a-8a5771851af1" />

18. Ранжирование питомцев по возрасту
```
SELECT
    p.id,
    p.name,
    p.age,
    c.name AS owner_name,
    RANK() OVER (
        PARTITION BY p.owner_id
        ORDER BY p.age DESC
    ) AS age_rank
FROM petshopschema.pet p
JOIN petshopschema.client c ON c.id = p.owner_id;
```
<img width="679" height="141" alt="image" src="https://github.com/user-attachments/assets/d322dce3-de57-4926-8e6f-00927b1c9bfc" />

19.  --Для каждого питомца покажи средний возраст по его владельцу, включая самого питомца и его "соседей" по владельцу (до 1 вверх и вниз).
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
<img width="1370" height="576" alt="image" src="https://github.com/user-attachments/assets/dec528d9-baac-49b6-8dc7-365dae2e20b7" />

21.  --Для каждого питомца — посчитать, сколько питомцев его владельца находятся в пределах ±2 лет возраста.
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
<img width="1124" height="590" alt="image" src="https://github.com/user-attachments/assets/e716ee49-eb0e-46bd-a632-7846d32a271c" />
22. Сколько пород имеют средний вес в диапазоне ±3 кг от текущего значения average_weight
```
select 
    b.breed_name,
    b.average_weight,
    count(*) over (
        order by b.average_weight
        range between 3 preceding and 3 following
    ) as breeds_in_weight_range
from breed b;
```
<img width="626" height="171" alt="image" src="https://github.com/user-attachments/assets/0a1f97b0-3d55-44f8-b6fe-6d5108a9c7b2" />

23. --Питомцы, отсортированные по возрасту внутри каждого питомника с возможными пропусками в ранге.
```
SELECT
    p.name,
    p.age,
    pt.name AS shop_name,
    RANK() OVER (PARTITION BY p.petshop_id ORDER BY p.age DESC) AS age_rank
FROM pet p
JOIN petshop pt ON pt.id = p.petshop_id;
```
<img width="1432" height="602" alt="image" src="https://github.com/user-attachments/assets/341c18e1-38ed-4951-b657-b7b9e364c26c" />

24. --То же самое, но без "пробелов" в ранге при совпадении возраста.
```
SELECT
    p.name,
    p.age,
    pt.name AS shop_name,
    DENSE_RANK() OVER (PARTITION BY p.petshop_id ORDER BY p.age DESC) AS dense_age_rank
FROM pet p
JOIN petshop pt ON pt.id = p.petshop_id;
```
<img width="1148" height="572" alt="image" src="https://github.com/user-attachments/assets/1883d4fc-1be3-4a43-93ad-6d4f9be150bd" />

25. --Найди самого старшего питомца в каждой клетке.
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
<img width="2094" height="742" alt="image" src="https://github.com/user-attachments/assets/0b1ce914-a7ad-4670-aff8-b286ea987f3c" />

26. --Покажи возраст предыдущего питомца по возрасту среди всех.
```
SELECT
    name,
    age,
    LAG(age) OVER (ORDER BY age) AS prev_pet_age
from pet;
```
<img width="1114" height="624" alt="image" src="https://github.com/user-attachments/assets/e14c04cc-5929-4995-9c16-642cb9d1ef81" />

27. --Покажи возраст следующего питомца.
```
SELECT
    name,
    age,
    LEAD(age) OVER (ORDER BY age) AS next_pet_age
FROM pet;
```
<img width="984" height="616" alt="image" src="https://github.com/user-attachments/assets/9ee312e3-84fb-42e1-8309-fc9df25e3443" />

28. --Покажи самого младшего питомца в каждом магазине.
```
SELECT
    p.name,
    p.age,
    pt.name AS shop_name,
    FIRST_VALUE(p.age) OVER (PARTITION BY p.petshop_id ORDER BY p.age ASC) AS youngest_age_in_shop
FROM pet p
JOIN petshop pt ON pt.id = p.petshop_id;
```
<img width="1332" height="584" alt="image" src="https://github.com/user-attachments/assets/3394e217-10f7-4ca4-8187-f1333d3c72f8" />

29. --Покажи самого старшего питомца в каждом магазине (только с рамкой ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING — иначе результат будет некорректен).
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
<img width="1352" height="570" alt="image" src="https://github.com/user-attachments/assets/4ae941aa-cb0c-4ebf-ad2b-43b882d48e7f" />
