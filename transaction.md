1.1 Добавление питомца и обновление клетки в одной транзакции
```
begin;

insert into petshopschema.pet (id, name, age, owner_id, breed_id, food_id, petshop_id)
values (1001, 'Барсик', 2, 3, 2, 2, 2);

update petshopschema.cage
set current_pet_id = 1001
where id = 1; 

commit;
```

Результаты:
```
select * from petshopschema.pet where id = 1001; 
```
<img width="1203" height="175" alt="image" src="https://github.com/user-attachments/assets/4bacbf45-5bed-4441-acba-ac6d8c6a801f" />

```
select * from petshopschema.cage where id = 1;
```
<img width="803" height="160" alt="image" src="https://github.com/user-attachments/assets/f680c167-826e-4f92-b42d-9541116ac212" />


1.2 То же самое, но с rollback
```
begin;

insert into petshopschema.pet (id, name, age, owner_id, breed_id, food_id, petshop_id)
values (1002, 'Шарик', 2, 2, 2, 2, 1);

update petshopschema.cage
set current_pet_id = 1002
where id = 2;

rollback;
```

Результаты:
```
select * from petshopschema.pet where id = 1002;
```
<img width="1104" height="153" alt="image" src="https://github.com/user-attachments/assets/7844649c-eab7-47df-98ea-c2033536f6a1" />

```
select * from petshopschema.cage where id = 2;
```
<img width="756" height="94" alt="image" src="https://github.com/user-attachments/assets/b237fad9-275c-40b4-a9fa-364fb43ba108" />

1.3 Ошибка внутри транзакции (деление на 0)
```
begin;

insert into petshopschema.pet (id, name, age, owner_id, breed_id, food_id, petshop_id)
values (1003, 'Ярик', 3, 3, 1, 1, 1);

select 1 / 0;

commit;
```
<img width="1298" height="338" alt="image" src="https://github.com/user-attachments/assets/69363626-d9af-4ce7-a6e6-237b59cd77f6" />

Результаты:
```
select * from petshopschema.pet where id = 1003;
```
<img width="1082" height="135" alt="image" src="https://github.com/user-attachments/assets/e5ac579f-68f0-45df-8801-c370d3354b72" />

2.1. READ COMMITTED — грязное чтение
<img width="210" height="120" alt="image" src="https://github.com/user-attachments/assets/5b9b2d2c-a8ba-43f6-ae6d-54bd80470865" />T1:
```
begin transaction isolation level read committed;

select age from petshopschema.pet where id = 1; 

update petshopschema.pet
set age = age + 10
where id = 1;
```

T2:
```
begin transaction isolation level read committed;

select age from petshopschema.pet where id = 1;

commit;
```
<img width="218" height="98" alt="image" src="https://github.com/user-attachments/assets/e35fe6b8-3c0d-4bef-bcb0-b8760193b804" />

2.2. READ COMMITTED — неповторяющееся чтение
T1:
```
begin transaction isolation level read committed;

select age from petshopschema.pet where id = 1;

commit;
```
<img width="301" height="130" alt="image" src="https://github.com/user-attachments/assets/5004bc0b-a132-484e-bb15-5f0009b5da79" />

T2:
```
begin transaction isolation level read committed;

update petshopschema.pet
set age = age + 1
where id = 1;

commit;
```

T1:
```
select age from petshopschema.pet where id = 1;  

commit;
```
<img width="240" height="100" alt="image" src="https://github.com/user-attachments/assets/6c308d78-b08c-4c84-ae1c-7f5d30dcf566" />

2.3. REPEATABLE READ — повторное чтение
T1:
```
begin transaction isolation level repeatable read;

select age from petshopschema.pet where id = 1;
```
<img width="202" height="96" alt="image" src="https://github.com/user-attachments/assets/38f83148-79e9-485e-a0dc-d1ae09bea6bc" />

T2:
```
begin transaction isolation level read committed;

update petshopschema.pet
set age = age + 5
where id = 1;

commit;
```

T1:
```
select age from petshopschema.pet where id = 1; 

commit;
```
<img width="231" height="117" alt="image" src="https://github.com/user-attachments/assets/07b13e06-e4d6-429e-bdd3-8ae583fe2c87" />

2.4. REPEATABLE READ — фантомное чтение
T1:
```
begin transaction isolation level repeatable read;

select count(*) as pet_count
from petshopschema.pet
where petshop_id = 1;
```
<img width="239" height="97" alt="image" src="https://github.com/user-attachments/assets/20c97212-7be2-49b7-91bf-c947e20250e0" />

T2:
```
begin transaction isolation level read committed;

insert into petshopschema.pet (id, name, age, owner_id, breed_id, food_id, petshop_id)
values (2001, 'Фантом', 1, 1, 1, 1, 1);

commit;
```

T1:
```
select count(*) as pet_count
from petshopschema.pet
where petshop_id = 1;

commit;
```
<img width="278" height="119" alt="image" src="https://github.com/user-attachments/assets/3c6e2692-79bb-4811-ba8a-cd52bdde8231" />

2.5. SERIALIZABLE — конфликт и повтор транзакции
T1:
```
begin transaction isolation level serializable;

select pets_capacity
from petshopschema.petshop
where id = 1;

select count(*) as pet_count
from petshopschema.pet
where petshop_id = 1;

insert into petshopschema.pet (name, age, owner_id, breed_id, food_id, petshop_id)
values ('serial-t1-', 1, 1, 1, 1, 1);
```


T2:
```
begin transaction isolation level serializable;

select pets_capacity
from petshopschema.petshop
where id = 1;

select count(*) as pet_count
from petshopschema.pet
where petshop_id = 1;

insert into petshopschema.pet (name, age, owner_id, breed_id, food_id, petshop_id)
values ('serial-t2-', 1, 1, 1, 1, 1);

commit;
```

T1:
```
commit
```
<img width="638" height="219" alt="image" src="https://github.com/user-attachments/assets/09185f5f-6835-4ad2-9d20-6df342d141ba" />


3.1. Один savepoint
Создаём клиента и питомца, откатываемся до создания клиента
```
begin;

-- создаём нового клиента
insert into petshopschema.client (id, name, surname, passport_data, petshop_id)
values (5001, 'Иван', 'Иванов', '9989981254', 1);

savepoint new_client_without_pet;

-- пробуем создать питомца для этого клиента
insert into petshopschema.pet (id, name, age, owner_id, breed_id, food_id, petshop_id)
values (5001, 'Рекс', 4, 5001, 1, 1, 1);

rollback to savepoint new_client_without_pet;

commit;
```
Результаты:
```
select * from petshopschema.client where id = 5001;
```
<img width="836" height="107" alt="image" src="https://github.com/user-attachments/assets/2245515e-55a8-4650-ab90-176d5c068970" />

```
select * from petshopschema.pet where id = 5001;
```
<img width="1087" height="166" alt="image" src="https://github.com/user-attachments/assets/935ff3ef-b6ea-4770-b7b4-ec4c600c9467" />

3.2. Два savepoint
```
begin;

-- cоздаём питомца
insert into petshopschema.pet (id, name, age, owner_id, breed_id, food_id, petshop_id)
values (6001, 'Лорд', 2, 1, 1, 1, 1);

savepoint sp1;

-- добавляем аксессуар этому питомцу
insert into petshopschema.pet_accessorie (pet_id, accessorie_id)
values (6001, 1);  -- подставить существующий accessorie_id

savepoint sp2;

-- добавляем медикамент этому же питомцу
insert into petshopschema.pet_medication (pet_id, medication_id)
values (6001, 1);  -- подставить существующий medication_id

rollback to savepoint sp2;
```

Результаты:
(питомец 6001 существует, есть запись в pet_accessorie, нет записи в pet_medication)
```
select * from petshopschema.pet where id = 6001;
```
<img width="1091" height="127" alt="image" src="https://github.com/user-attachments/assets/08439fe3-001a-4a77-b52f-be4dce35bd5b" />

```
select * from petshopschema.pet_accessorie where pet_id = 6001;
```
<img width="465" height="136" alt="image" src="https://github.com/user-attachments/assets/a5d836f9-52d0-4a6e-a3d7-7ea21c9277bc" />


```
select * from petshopschema.pet_medication where pet_id = 6001;
```
<img width="465" height="123" alt="image" src="https://github.com/user-attachments/assets/02f91981-baf0-463f-bca1-057a531d4064" />

Ещё один откат
```
rollback to savepoint sp1;

commit;
```

Результаты:
(питомец 6001 всё ещё существует, pet_accessorie и pet_medication откатились)
```
select * from petshopschema.pet where id = 6001;
```
<img width="1092" height="122" alt="image" src="https://github.com/user-attachments/assets/1d39dd29-c191-4121-994a-5ff7048bf2dc" />

```

select * from petshopschema.pet_accessorie where pet_id = 6001;
```
<img width="443" height="156" alt="image" src="https://github.com/user-attachments/assets/507cd7ba-b1e6-44a5-939d-3e08312bdda3" />


```
select * from petshopschema.pet_medication where pet_id = 6001;
```
<img width="401" height="121" alt="image" src="https://github.com/user-attachments/assets/fbc3aee3-dd8d-4bcd-8892-720c9ebc9470" />

