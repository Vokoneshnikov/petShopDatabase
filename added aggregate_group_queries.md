Средняя вместимость питомников под названием ЗооЛэнд
```
select name, avg(pets_capacity) as avg_capacity from petshopschema.petshop group by name;
```
<img width="433" height="234" alt="image" src="https://github.com/user-attachments/assets/b46b94a5-167f-4988-a6d9-1b12126e6cd1" />


Средний возраст разных породы
```
select breed_id, avg(age) as avg_pet_age from petshopschema.pet group by breed_id;
```
<img width="444" height="199" alt="image" src="https://github.com/user-attachments/assets/e8823db3-ac30-4ebe-a7e3-f0426f007634" />


Количество животных по кличке (!!)
```
select name, count(*) as count from petshopschema.pet group by name;
```
<img width="379" height="200" alt="image" src="https://github.com/user-attachments/assets/0754577b-9198-4a8e-a231-dca37d869322" />


Количество кормов по классу (премиум и тд) 
```
select food_type, count(*) as count from petshopschema.food group by food_type;
```
<img width="412" height="200" alt="image" src="https://github.com/user-attachments/assets/2d9003c1-0be1-4ee7-81d6-6185dd32ebb4" />


Количество уникальных имен животных (!!)
```
select count(distinct name) from petshopschema.pet;
```
<img width="273" height="177" alt="image" src="https://github.com/user-attachments/assets/af2bcdd5-88cd-4ac8-989f-2e5a0eea0cdd" />


Количество уникальных названий аксессуаров (!!)
```
select count(distinct name) from petshopschema.accessorie;
```
<img width="289" height="148" alt="image" src="https://github.com/user-attachments/assets/8c1d5610-d284-42ea-8751-64f494635f75" />


Самый молодой питомец
```
select min(age) from petshopschema.pet;
```
<img width="294" height="127" alt="image" src="https://github.com/user-attachments/assets/5f9b2a54-70a7-44bb-9fe1-2a903788bacc" />


Вес самой худой породы 
```
select min(average_weight) from petshopschema.breed;
```
<img width="327" height="141" alt="image" src="https://github.com/user-attachments/assets/df6f65d5-b792-428b-8119-8747b28c20f1" />


Cамый взрослый питомец
```
select max(age) from petshopschema.pet;
```
<img width="311" height="141" alt="image" src="https://github.com/user-attachments/assets/d2c17102-c829-43e1-b8bc-6917fcf54f34" />


Самый вместимый питомник 
```
select max(pets_capacity) from petshopschema.petshop;
```
<img width="314" height="119" alt="image" src="https://github.com/user-attachments/assets/aa0d111d-6ce6-49f3-ba5c-ea160b0128ee" />


Вместимость всех филиалов питомника
```
select sum(pets_capacity) from petshopschema.petshop;
```
<img width="334" height="124" alt="image" src="https://github.com/user-attachments/assets/91666f35-04a5-48d9-b7f2-564b0688f95e" />


Сумма веса всех пород
```
select sum(average_weight) from petshopschema.breed;
```
<img width="317" height="120" alt="image" src="https://github.com/user-attachments/assets/7b3f4c8e-a0c3-4ab3-b5b7-f139f3969fd6" />


Все имена клиентов
```
select string_agg(name, ', ') as clients from petshopschema.client;
```
<img width="331" height="146" alt="image" src="https://github.com/user-attachments/assets/f20635ed-4b2a-43f3-a7f5-56a424dcaf6b" />


Названия всех пород
```
select string_agg(breed_name, ', ') as breeds from petshopschema.breed;
```
<img width="424" height="146" alt="image" src="https://github.com/user-attachments/assets/5e513c2c-1683-4e24-b2c7-028445b879f1" />
