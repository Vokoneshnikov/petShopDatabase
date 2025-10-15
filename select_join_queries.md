## Выборка всех данных из таблицы

### 1) Запросы SELECT + JOIN

1.

```
select * from petshopschema.pet;
```

![alt text](image.png)

```
select * from petshopschema.cage;
```

![alt text](image-1.png)

```
select *
  case
    when name = 'Полина' then passport_data = '9280123472'
    else passport_data
  end
from petshopschema.client;
```

![alt text](image-2.png) 2.

```
select *
  case
    when address = 'ул. Пушкина, 32' then pets_capacity / 2
    when address = 'Московский пр., 3а' then pets_capacity * 3
    else pets_capacity
  end
from petshopschema.petshop;
```

![alt text](image-3.png) 3.

```
select name, surname from petshopschema.client;
select animal_type_id, current_pet_id from petshopschema.cage;
select name, age, owner_id
  case
    when name = 'Мурзилоид' then age + 2
    else age + 1
  end
from petshopschema.pet;
```

![alt text](image-4.png) 4.

```
select brand_name, food_type
  case
    when brand_name = 'Whiskas' then food_type = 'Econom'
    when brand_name = 'Purina one' then food_type = 'Ultra Premium'
    else food_type
  end
from petshopschema.food;
```

![alt text](image-5.png) 5.

```
select passport_data as info, surname from petshopschema.client;
select name as Кличка, age from petshopschema.pet;
```

![alt text](image-6.png) 6.

```
select name, age * 7 as in_human_age from petshopschema.pet;
select address, floor(pets_capacity * 2.5) as new_capacity from petshopschema.petshop;
```

![alt text](image-7.png) 7.

```
select passport_data from petshopschema.client where (passport_data > 1000000000);
select name from petshopschema.pet where (owner_id = 1);
```

![alt text](image-8.png) 8.

```
select name from petshopschema.pet where (id < 5 and age < 7);
select name from petshopschema.employee where (surname = "Иванов" or petshop_id = 1);
```

![alt text](image-9.png) 9.

```
select name from petshopschema.petshop where pets_capacity between 40 and 100;
select name from petshopschema.pet where age between 0 and 7;
```

![alt text](image-10.png) 10.

```
select name, surname, passport_data from petshopschema.client order by surname;
select name, breed_id, owner_id from petshopschema.pet where breed_id < 13 order by name desc;
```

![alt text](image-11.png) 11.

```
select average_weight from petshopschema.breed where breed_name like '% Хаски';
select name from petshopschema.animal_type where name like '_____';
```

![alt text](image-12.png) 12.

```
select distinct name from petshopschema.accessorie;
select distinct name from petshopschema.medication;
```

![alt text](image-13.png) 13.

```
select name, age from petshopschema.pet order by age limit 3;
select name, description from petshopschema.medication order by name desc limit 4 offset 1;
```

![alt text](image-14.png) 14.

```
select * from petshopschema.pet
inner join petshopschema.breed on petshopschema.pet.breed_id = petshopschema.breed.id
inner join petshopschema.animal_type on petshopschema.breed.animal_type_id = petshopschema.animal_type.id
where petshopschema.animal_type.name = 'Собака';
```

![alt text](image-15.png) 15.

```
select *,
CASE
    when name = 'ЗооЛэнд' then pets_capacity * 2
    else pets_capacity
  end
from petshopschema.petshop;
```

![alt text](image-16.png)

```
select *,
  case
    when address = 'ул. Пушкина, 32' then pets_capacity / 2
    when address = 'Московский пр., 3а' then pets_capacity * 3
    else pets_capacity
  end
from petshopschema.petshop;
```

![alt text](image-17.png) 16.

```
select passport_data as info, surname from petshopschema.client;
select name as Кличка, age from petshopschema.pet;
```

![alt text](image-18.png) 17.

```
select name, age * 7 as in_human_age from petshopschema.pet;
select address, floor(pets_capacity * 2.5) as new_capacity from petshopschema.petshop;
```

![alt text](image-20.png) 18.

```
select name, passport_data from petshopschema.client where (passport_data = '9989987654');
select name from petshopschema.pet where (owner_id = 1);
```

![alt text](image-21.png) 19.

```
select name from petshopschema.pet where (id < 5 and age < 5);
select name from petshopschema.employee where (surname = 'Игнатьев' or petshop_id = 1);
```

![alt text](image-22.png) 20.

```
select name, pets_capacity from petshopschema.petshop where pets_capacity between 40 and 100;
select name, age from petshopschema.pet where age between 0 and 7;
```

![alt text](image-23.png) 21.

```
select name, surname, passport_data from petshopschema.client order by surname;
select name, breed_id, owner_id from petshopschema.pet where breed_id < 13 order by name desc;
```

![alt text](image-24.png) 22.

```
select average_weight from petshopschema.breed where breed_name like '%Хаски';
select name from petshopschema.animal_type where name like '_____';
```

![alt text](image-25.png) 23.

```
select distinct name from petshopschema.accessorie;
select distinct name from petshopschema.medication;
```

![alt text](image-26.png) 24.

```
select name, age from petshopschema.pet order by age limit 2;
select name, description from petshopschema.medication order by name desc limit 3 offset 1;
```

![alt text](image-27.png) 25.

```
select * from petshopschema.pet
inner join petshopschema.breed on petshopschema.pet.breed_id = petshopschema.breed.id
where breed_name = 'Бурманский';
```

![alt text](image-28.png) 26.

```
select passport_data
from petshopschema.client left join petshopschema.pet
on petshopschema.client.id = petshopschema.pet.owner_id;
```

![alt text](image-29.png) 27.

```
select brand_name, name
from petshopschema.food cross join petshopschema.medication;
```

![alt text](image-30.png) 28.

```
select name
from petshopschema.employee right join petshopschema.cage
on petshopschema.employee.petshop_id = petshopschema.cage.petshop_id;
```

![alt text](image-32.png)
