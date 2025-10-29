<img width="1076" height="135" alt="image" src="https://github.com/user-attachments/assets/c720d6a3-95a3-4b27-a7f8-cf88c6676b26" />**Средняя вместимость питомников под названием ЗооЛэнд**
```
select name, avg(pets_capacity) as avg_capacity from petshopschema.petshop group by name;
```
<img width="433" height="234" alt="image" src="https://github.com/user-attachments/assets/b46b94a5-167f-4988-a6d9-1b12126e6cd1" />


**Средний возраст разных породы**
```
select breed_id, avg(age) as avg_pet_age from petshopschema.pet group by breed_id;
```
<img width="444" height="199" alt="image" src="https://github.com/user-attachments/assets/e8823db3-ac30-4ebe-a7e3-f0426f007634" />


**Количество животных по кличке**
```
select name, count(*) as count from petshopschema.pet group by name;
```
<img width="379" height="200" alt="image" src="https://github.com/user-attachments/assets/0754577b-9198-4a8e-a231-dca37d869322" />


**Количество кормов по классу (премиум и тд) **
```
select food_type, count(*) as count from petshopschema.food group by food_type;
```
<img width="412" height="200" alt="image" src="https://github.com/user-attachments/assets/2d9003c1-0be1-4ee7-81d6-6185dd32ebb4" />


**Количество уникальных кличек животных**
```
select count(distinct name) from petshopschema.pet;
```
<img width="273" height="177" alt="image" src="https://github.com/user-attachments/assets/af2bcdd5-88cd-4ac8-989f-2e5a0eea0cdd" />


**Количество уникальных названий аксессуаров **
```
select count(distinct name) from petshopschema.accessorie;
```
<img width="289" height="148" alt="image" src="https://github.com/user-attachments/assets/8c1d5610-d284-42ea-8751-64f494635f75" />


**Самый молодой питомец**
```
select min(age) from petshopschema.pet;
```
<img width="294" height="127" alt="image" src="https://github.com/user-attachments/assets/5f9b2a54-70a7-44bb-9fe1-2a903788bacc" />


**Вес самой худой породы **
```
select min(average_weight) from petshopschema.breed;
```
<img width="327" height="141" alt="image" src="https://github.com/user-attachments/assets/df6f65d5-b792-428b-8119-8747b28c20f1" />


**Cамый взрослый питомец**
```
select max(age) from petshopschema.pet;
```
<img width="311" height="141" alt="image" src="https://github.com/user-attachments/assets/d2c17102-c829-43e1-b8bc-6917fcf54f34" />


**Самый вместимый питомник **
```
select max(pets_capacity) from petshopschema.petshop;
```
<img width="314" height="119" alt="image" src="https://github.com/user-attachments/assets/aa0d111d-6ce6-49f3-ba5c-ea160b0128ee" />


**Вместимость всех филиалов питомника**
```
select sum(pets_capacity) from petshopschema.petshop;
```
<img width="334" height="124" alt="image" src="https://github.com/user-attachments/assets/91666f35-04a5-48d9-b7f2-564b0688f95e" />


**Сумма веса всех пород**
```
select sum(average_weight) from petshopschema.breed;
```
<img width="317" height="120" alt="image" src="https://github.com/user-attachments/assets/7b3f4c8e-a0c3-4ab3-b5b7-f139f3969fd6" />


**Все имена клиентов**
```
select string_agg(name, ', ') as clients from petshopschema.client;
```
<img width="331" height="146" alt="image" src="https://github.com/user-attachments/assets/f20635ed-4b2a-43f3-a7f5-56a424dcaf6b" />


**Названия всех пород**
```
select string_agg(breed_name, ', ') as breeds from petshopschema.breed;
```
<img width="424" height="146" alt="image" src="https://github.com/user-attachments/assets/5e513c2c-1683-4e24-b2c7-028445b879f1" />


**Количество животных по кличке **
```
select name, count(*) as count from petshopschema.pet group by name;
```
<img width="379" height="200" alt="image" src="https://github.com/user-attachments/assets/0754577b-9198-4a8e-a231-dca37d869322" />


**Количество кормов по классу (премиум и тд) **
```
select food_type, count(*) as count from petshopschema.food group by food_type;
```
<img width="412" height="200" alt="image" src="https://github.com/user-attachments/assets/2d9003c1-0be1-4ee7-81d6-6185dd32ebb4" />


**Общий вес животных под id = 3**
```
select animal_type_id, sum(average_weight) as weight  from petshopschema.breed 
group by animal_type_id having animal_type_id = 3;
```
<img width="435" height="135" alt="image" src="https://github.com/user-attachments/assets/42ae92ef-e8db-409c-9067-5487474b2702" />


**Количество животных, длина названия породы которых равна 4**
```
select breed_name, count(*) as breeds from petshopschema.breed
group by breed_name having breed_name like '____';
```
<img width="424" height="147" alt="image" src="https://github.com/user-attachments/assets/50aea48e-1fa6-49f3-9c3b-550cfa009cb9" />


**Группировка клиентов по имени и питомнику, а также отдельно по имени и ID**
```
select name, petshop_id, count(*) as count
from petshopschema.client
group by grouping sets ((name, petshop_id), (name), (id));
```
<img width="524" height="322" alt="image" src="https://github.com/user-attachments/assets/1c2c8719-35ca-49d1-8486-8635b5b87824" />


**Группировка связей питомцев и лекарств по паре ID, а также отдельно по каждому ID**
```
select pet_id, medication_id, count(*) as count
from petshopschema.pet_medication
group by grouping sets ((pet_id, medication_id), (pet_id), (medication_id));
```
<img width="557" height="360" alt="image" src="https://github.com/user-attachments/assets/51ed9242-7b75-4458-834e-6bd46a85b268" />


**Иерархическая агрегация: тип животного -> порода -> (общее итого)**
```
select age, breed_id, count(*) as pet_count
from petshopschema.pet
group by rollup (age, breed_id);
```
<img width="519" height="233" alt="image" src="https://github.com/user-attachments/assets/1018e7a7-d0e6-48d1-9334-be99f7291070" />


**Иерархическая агрегация: питомник -> тип корма -> (общее итого)**
```
select brand_name, food_type, count(*) as food_count
from petshopschema.food
group by rollup (brand_name, food_type);
```
<img width="611" height="366" alt="image" src="https://github.com/user-attachments/assets/ed44c6d3-4097-429e-aa85-2dae742fdf94" />


**Все возможные комбинации группировки: питомник, тип аксессуара и их пересечения**
```
select id, name, count(*) as accessory_count
from petshopschema.accessorie
group by cube (id, name);
```
<img width="603" height="331" alt="image" src="https://github.com/user-attachments/assets/5288d379-16b6-41a0-ae93-600d83663c29" />


**Все возможные комбинации группировки: тип животного, порода и их пересечения**
```
select age, breed_id, avg(age) as avg_age
from petshopschema.pet
group by cube (age, breed_id);
```
<img width="502" height="303" alt="image" src="https://github.com/user-attachments/assets/3ed21822-8c0b-4c1e-be9b-03527579a324" />


**Все питомцы старше 3-x лет**
```
select * from petshopschema.pet where age > 3;
```
<img width="1076" height="135" alt="image" src="https://github.com/user-attachments/assets/34264da7-36bb-4aa2-8f5e-bf5f944c6fd6" />


**Все корма премиум-класса**
```
select * from petshopschema.food where food_type = 'Premium';
```
<img width="541" height="134" alt="image" src="https://github.com/user-attachments/assets/ac09aa25-9f41-48a6-9dc1-ebd8b31914e2" />


**Питомцы, отсортированные по возрасту (от старшего к младшему)**
```
select * from petshopschema.pet order by age desc;
```
<img width="1084" height="164" alt="image" src="https://github.com/user-attachments/assets/5abb6f0f-d88c-4a60-9cb2-ac0ecd1bf961" />


**Породы, отсортированные по среднему весу (от легкой к тяжелой)**
```
select * from petshopschema.breed order by average_weight asc;
```
<img width="774" height="213" alt="image" src="https://github.com/user-attachments/assets/a2fdd34d-17d8-4899-9efd-23a5c84aa30a" />


