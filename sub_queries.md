1. Вывести список питомцев с вычисляемым полем «полных лет через 2 года» и округлить его вниз
```
select pet.id, pet.name, floor(pet.age + 2) as age_plus_2
from pet;
```
<img width="1564" height="608" alt="image" src="https://github.com/user-attachments/assets/13a60fb4-60a3-49bc-97fc-bb949af0daa7" />
2. Сколько уникальных типов животных содержится в базе? 
```
select count(distinct animal_type.name)
from animal_type;
```
<img width="1860" height="408" alt="image" src="https://github.com/user-attachments/assets/2bff7f63-32e3-47c6-be82-11daf21fc90c" />
3. Сформировать колонку «ФИО сотрудника» (конкатенация employee.name и employee.surname) и вывести первые 2 строки.
```
select employee.name  ' '  employee.surname as fio
from employee 
limit 2;
```
<img width="2014" height="514" alt="image" src="https://github.com/user-attachments/assets/c9b6526e-9fb0-40a8-b72a-74316eaf30b2" />
4.Сформировать таблицу «Питомец — Порода — Тип животного»
```
select p.name, b.breed_name, animal_type.name
from pet p join breed b on p.breed_id = b.id,
breed join animal_type on animal_type_id = animal_type.id;
```
<img width="1568" height="830" alt="image" src="https://github.com/user-attachments/assets/5ec3a105-5e77-4e22-b7b0-67ae45ef1e88" />
5. Для каждого питомца вывести используемый корм
```
select p.name, f.food_type
from pet p join food f on p.food_id = f.id;
```
<img width="1496" height="576" alt="image" src="https://github.com/user-attachments/assets/95538cba-f538-4765-835e-3b644a9de927" />
6. Вывести «Клетка — Зоомагазин — Текущий питомец» (если есть): cage.id, petshop.name, pet.name через левое соединение клетки с текущим питомцем.
```
select
    cage.id,
    petshop.name,
    pet.name
from cage left join pet on cage.current_pet_id = pet.id       
left join petshop on cage.petshop_id = petshop.id;
```
<img width="1532" height="878" alt="image" src="https://github.com/user-attachments/assets/69aefe7c-8321-4e72-a2c9-c59b73747471" />

7. Сколько питомцев старше 5 лет?
```
select p.name, p.age 
from pet p 
where p.age > 5
```
<img width="1240" height="430" alt="image" src="https://github.com/user-attachments/assets/fcc7328e-1a6e-4e41-880b-e5170346bb39" />
8. Вывести сотрудников, чья профессия начинается на «вет» (использовать LIKE), отсортировать по фамилии. 
```
select e.surname , e.profession 
from employee e 
where e.profession like 'Vet'
order by e.surname;
```
<img width="1652" height="430" alt="image" src="https://github.com/user-attachments/assets/26aed742-9b31-4838-b394-b60a634b5ffe" />
9. Найти все пустые клетки (current_pet_id IS NULL) конкретного зоомагазина по petshop_id. 
```
select
    c.id,
    c.animal_type_id,
    c.petshop_id
from 
    cage c
where 
    c.current_pet_id is null
    and c.petshop_id = 3;  
```

<img width="1492" height="718" alt="image" src="https://github.com/user-attachments/assets/389f21a7-a866-4bdb-a040-4f2442aead46" />
10. Для каждого зоомагазина посчитать число питомцев. Оставить только те магазины, где число питомцев ≥ 1% от pets_capacity. 
Вывести также процент заполненности, округлив вниз до целого. 
```
SELECT 
    ps.id,
    ps.name,
    COUNT(p.id) AS pet_count,
    ps.pets_capacity,
    FLOOR(COUNT(p.id) * 100.0 / ps.pets_capacity) AS fill_percent
FROM 
    petshop ps
JOIN 
    pet p ON p.petshop_id = ps.id
GROUP BY 
    ps.id, ps.name, ps.pets_capacity
HAVING 
    COUNT(p.id) >= ps.pets_capacity * 0.01;
```
<img width="1968" height="918" alt="image" src="https://github.com/user-attachments/assets/fd7b9252-954a-4f7f-a210-255cbe3338b8" />
11. По каждому типу животного посчитать средний возраст содержащихся питомцев. Оставить только типы со средним возрастом > 3 лет.
```
SELECT 
    at.name AS animal_type,
    AVG(p.age) AS avg_age
FROM 
    pet p
JOIN 
    breed b ON p.breed_id = b.id
JOIN 
    animal_type at ON b.animal_type_id = at.id
GROUP BY 
    at.name
HAVING 
    AVG(p.age) > 3;
```
<img width="2128" height="786" alt="image" src="https://github.com/user-attachments/assets/1bc86342-4b01-4a0e-9d57-32f134f3dc7f" />
12. Для каждой породы посчитать, у скольких питомцев этой породы есть хотя бы одно назначенное лекарство (pet_medication). Оставить породы с количеством ≥ 0. 
```
SELECT 
    b.breed_name AS breed_name,
    COUNT(DISTINCT pm.pet_id) AS pets_with_meds
FROM 
    pet p
JOIN 
    breed b ON p.breed_id = b.id
JOIN 
    pet_medication pm ON p.id = pm.pet_id
GROUP BY 
    b.breed_name
HAVING 
    COUNT(DISTINCT pm.pet_id) >= 0;
```
<img width="2100" height="948" alt="image" src="https://github.com/user-attachments/assets/2b6bc566-0705-4b35-84af-89a674eaceef" />
13. Найти зоомагазины, чья вместимость строго больше, чем вместимость у всех других магазинов (использовать > ALL по подзапросу). 
```
SELECT 
    *
FROM 
    petshop ps
WHERE 
    ps.pets_capacity > ALL (
        SELECT pets_capacity FROM petshop WHERE id <> ps.id
    );
```
<img width="2132" height="810" alt="image" src="https://github.com/user-attachments/assets/9b0b7844-32ce-4e68-95d7-f609c29e41e7" />
14. Вывести породы, у которых average_weight строго выше, чем у всех остальных пород того же типа животного 
```
SELECT 
    b1.*
FROM 
    breed b1
WHERE 
    b1.average_weight > ALL (
        SELECT b2.average_weight 
        FROM breed b2 
        WHERE b2.animal_type_id = b1.animal_type_id AND b2.id <> b1.id
    );
```
<img width="1866" height="902" alt="image" src="https://github.com/user-attachments/assets/5efdd7ca-53a5-4021-9f53-bd0b5cacc9c7" />
15. Найти питомцев, чей возраст больше возраста всех остальных питомцев их же зоомагазина
```
SELECT 
    p1.*
FROM 
    pet p1
WHERE 
    p1.age > ALL (
        SELECT p2.age 
        FROM pet p2 
        WHERE p2.petshop_id = p1.petshop_id AND p2.id <> p1.id
    );
```

<img width="1888" height="852" alt="image" src="https://github.com/user-attachments/assets/329f60a7-9038-4796-9916-fdb47e93d3f5" />
16. Вывести клиентов, у которых есть питомцы пород, у которых average_weight > 10. Использовать IN по набору breed.id из подзапроса. 
```
SELECT 
    DISTINCT c.*
FROM 
    client c
JOIN 
    pet p ON p.owner_id = c.id
WHERE 
    p.breed_id IN (
        SELECT id FROM breed WHERE average_weight > 10
    );
```

<img width="2126" height="808" alt="image" src="https://github.com/user-attachments/assets/83bd5b83-2f95-4462-ae0b-06acfaa81c27" />
17. Найти питомцев, находящихся в зоомагазинах из топ-3 по pets_capacity (подзапрос с ORDER BY и LIMIT, затем IN). 
```
SELECT 
    p.*
FROM 
    pet p
WHERE 
    p.petshop_id IN (
        SELECT id 
        FROM petshop 
        ORDER BY pets_capacity DESC 
        LIMIT 3
    );
```

<img width="2040" height="898" alt="image" src="https://github.com/user-attachments/assets/7caac760-5546-480a-8f93-2394a3c20520" />
18. Показать сотрудников, работающих в тех магазинах, где есть клетки для типа «Reptile» 
```
SELECT 
    DISTINCT e.*
FROM 
    employee e
WHERE 
    e.petshop_id IN (
        SELECT c.petshop_id
        FROM cage c
        JOIN animal_type at ON c.animal_type_id = at.id
        WHERE at.name = 'Dog'
    );
```

<img width="1674" height="886" alt="image" src="https://github.com/user-attachments/assets/33a86bd4-dbab-475f-b9c2-0a61fe5eede3" />
19. Найти зоомагазины, чья вместимость меньше, чем хотя бы у одного другого магазина (< ANY (SELECT pets_capacity …)), т.е. не максимальные
```
SELECT 
    ps.*
FROM 
    petshop ps
WHERE 
    ps.pets_capacity < ANY (
        SELECT pets_capacity FROM petshop WHERE id <> ps.id
    );
```
<img width="2254" height="762" alt="image" src="https://github.com/user-attachments/assets/15876d7f-f083-40d8-8a22-9427e9dc5ee7" />
20. Вывести питомцев, чей возраст больше, чем хотя бы у одного питомца той же породы 
```
SELECT 
    p1.*
FROM 
    pet p1
WHERE 
    p1.age > ANY (
        SELECT p2.age 
        FROM pet p2 
        WHERE p2.breed_id = p1.breed_id AND p2.id <> p1.id
    );
```
<img width="1846" height="740" alt="image" src="https://github.com/user-attachments/assets/3b95f71a-191c-4af0-a415-ab2f3e0507d3" />
21. Вывести породы, у которых average_weight меньше, чем хотя бы у одной другой породы того же типа 
```
SELECT 
    b1.*
FROM 
    breed b1
WHERE 
    b1.average_weight < ANY (
        SELECT b2.average_weight 
        FROM breed b2 
        WHERE b2.animal_type_id = b1.animal_type_id AND b2.id <> b1.id
    );
```
<img width="1736" height="746" alt="image" src="https://github.com/user-attachments/assets/25769c06-bfd8-446b-b8de-6b0691851bd6" />
22. Вывести клиентов, у которых есть хотя бы один питомец   
```
SELECT 
    c.*
FROM 
    client c
WHERE 
    EXISTS (
        SELECT 1 FROM pet p WHERE p.owner_id = c.id
    );
```
<img width="1466" height="840" alt="image" src="https://github.com/user-attachments/assets/68929753-7dc2-476c-a28b-194fe9c267f5" />
23. Вывести питомцев, которым назначено хотя бы одно лекарство (строка в pet_medication существует).  
```
select 
    p.*
from
    pet p
where
    exists (
        select 1 from pet_medication pm where pm.pet_id = p.id
    );
```
<img width="1876" height="750" alt="image" src="https://github.com/user-attachments/assets/e8bff96e-36f7-4f80-a25f-eaba9e808c4a" />
24. Показать зоомагазины, где существует хотя бы одна пустая клетка  
```
select
 ps.*
from 
 petshop ps
where 
 exists(
  select 1 
  from cage c
  where c.petshop_id = ps.id and c.current_pet_id is null
 );
```
<img width="2056" height="770" alt="image" src="https://github.com/user-attachments/assets/7fdd7898-48ea-4417-a1be-c1b748cf96dd" />
25. Найти клиентов, у которых пара (имя, фамилия) совпадает с парой (имя, фамилия) какого-либо сотрудника: 
```
SELECT 
    c.*
FROM 
    client c
WHERE 
    (c.name, c.surname) IN (
        SELECT e.name, e.surname
        FROM employee e
    );
```
<img width="1870" height="848" alt="image" src="https://github.com/user-attachments/assets/05e9d490-a9c5-41ca-a96f-56e466fbfa75" />
26. Найти дубликаты клеток по паре (petshop_id, animal_type_id): вывести те сочетания, где таких клеток более одной
```
select 
 c.petshop_id,
 c.animal_type_id,
 count(*) as cage_count
from
 cage c 
group by
 c.petshop_id,
 c.animal_type_id 
having count(*) > 1
```
<img width="1964" height="778" alt="image" src="https://github.com/user-attachments/assets/be3a4955-5be9-46e0-9cd0-cc762aaa7fd3" />
27. Найти возможные дубли связей аксессуаров: пары (pet_id, accessorie_id) из pet_accessorie, которые встречаются более одного раза. Вывести такую пару и суммарное количество.
```
SELECT 
    pa.pet_id,
    pa.accessorie_id,
    COUNT(*) AS duplicates
FROM 
    pet_accessorie pa
GROUP BY 
    pa.pet_id, pa.accessorie_id
HAVING 
    COUNT(*) > 1;
```
<img width="1958" height="886" alt="image" src="https://github.com/user-attachments/assets/45fef90d-ed01-48a9-8409-089299e8ae4a" />
28. Вывести список питомцев с количеством назначенных лекарств у каждого
```
select 
 p.name,
 (select
  count(*)
  from 
   pet_medication pm 
  where pm.medication_id = p.id
 ) as meds_count
from
 pet p
```
<img width="1452" height="878" alt="image" src="https://github.com/user-attachments/assets/eca02b47-f4f8-465f-84de-975d229232da" />
29. Питомцы, чей возраст выше среднего по их породе 
```
select 
 p.*
from 
 pet p
where 
 p.age > (
  select avg(p2.age)
  from pet p2
  where p2.breed_id = p.breed_id 
 );
```
<img width="2006" height="988" alt="image" src="https://github.com/user-attachments/assets/0391ff7d-e922-493f-bf72-2c9ca30ab5e8" />
30. Клиенты, у которых больше питомцев, чем среднее по всем
```
SELECT 
    c.*
FROM 
    client c
WHERE 
    (
        SELECT COUNT(*) 
        FROM pet p 
        WHERE p.owner_id = c.id
    ) > (
        SELECT AVG(pet_count)
        FROM (
            SELECT COUNT(*) AS pet_count
            FROM pet
            GROUP BY owner_id
        ) AS sub
    );
```
<img width="1568" height="1110" alt="image" src="https://github.com/user-attachments/assets/31e0b82a-33e5-4376-bf5d-4862fe8a23df" />
31. Магазины, где средний возраст питомцев породы выше глобального
```
SELECT 
    ps.id AS petshop_id,
    ps.name AS petshop_name,
    b.id AS breed_id,
    b.breed_name AS breed_name,
    AVG(p.age) AS local_avg_age
FROM 
    pet p
JOIN 
    petshop ps ON p.petshop_id = ps.id
JOIN 
    breed b ON p.breed_id = b.id
GROUP BY 
    ps.id, ps.name, b.id, b.breed_name
HAVING 
    AVG(p.age) > (
        SELECT AVG(age)
        FROM pet
        WHERE breed_id = b.id
    );
```
<img width="1942" height="1144" alt="image" src="https://github.com/user-attachments/assets/358a36eb-85d5-4b4e-9ea0-876bd7de509d" />
32. Клетки, где у текущего питомца больше аксессуаров, чем в среднем по магазину
```
SELECT 
    c.id AS cage_id,
    c.petshop_id,
    c.current_pet_id
FROM 
    cage c
WHERE 
    c.current_pet_id IS NOT NULL AND
    (
        SELECT COUNT(*) 
        FROM pet_accessorie pa 
        WHERE pa.pet_id = c.current_pet_id
    ) > (
        SELECT AVG(accessories_count)
        FROM (
            SELECT COUNT(pa.accessorie_id) AS accessories_count
            FROM pet p
            LEFT JOIN pet_accessorie pa ON p.id = pa.pet_id
            WHERE p.petshop_id = c.petshop_id
            GROUP BY p.id
        ) AS sub
    );
)
```
<img width="1810" height="1240" alt="image" src="https://github.com/user-attachments/assets/ace7fae1-5671-4d46-a1f2-3e23109ed92c" />
