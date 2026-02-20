## Почему наша ER - модель соответствует 1NF и 2NF?

### 1. Первая нормальная форма (1NF) - СОБЛЮДАЕТСЯ

- Во всех сущностях есть первичный ключ (id), а у связок - составной ключ из FК (или можно добавить surrogate id, суть не меняется).

- Полей-массивов/списков нет: аксессуары и лекарства у питомца вынесены в отдельные таблицы связей pet_accessorie и pet_medication вместо колонок accessory1, accessory2, ..., что устраняет повторяющиеся группы.

- Значения атомарны.

- Порядок строк и столбцов не имеет значения.

### 2. Вторая нормальная форма (2NF) - СОБЛЮДАЕТСЯ

- Почти везде ключ - одиночный (id), значит не может быть частичных зависимостей: все неключевые атрибуты (name, profession, address, pets_capacity, breed_name, average_weight, и т.д.) зависят от всего ключа своей таблицы.

- В таблицах-связках (pet_accessorie, pet_medication) ключ составной (pet_id, accessorie_id) / (pet_id, medication_id), но неключевых атрибутов там нет.

- В таблицах вроде pet, cage, breed все неключевые поля - либо собственные свойства сущности, либо внешние ключи, и зависят от полного первичного ключа (id) своей таблицы.

## Почему не соответствует 3NF:

### 1) Нет корректной связи Клиент - Питомник

Как было:

1. client связан с petshop только неявно - через pet: client.id <- pet.owner_id и pet.petshop_id -> petshop.id.

### Проблемы:

1. Связь возникает только если у клиента уже есть/был питомец в конкретном питомнике.

2. После того, как питомца заберут, pet.petshop_id может меняться или становиться NULL, и мы теряем историю «клиент - филиал».

3. Невозможно корректно посчитать аналитику по филиалам: обращения, повторные визиты, - т. к. связь «клиент–филиал» не хранится явно.

### Как мы это исправили:

```
alter table petshopschema.client add column petshop_id int references petshopschema.petshop(id);
```

### 2) Сущность employee не решает назначение клетки/питомца

Как было:

- В employee есть поля cage_id и petshop_id. Это создаёт жёсткую 1-к-1 привязку сотрудника к одной клетке и одному филиалу и не хранит историю.

### Проблемы:

1. Нельзя назначить сотрудника на несколько клеток/животных одновременно.

2. Нет временных интервалов — невозможно понять, кто отвечал за клетку/питомца в прошлом.

3. Поле profession — справочник внутри строки; лучше нормализовать.

### Как мы это исправили:

```
alter table petshopschema.employee drop column cage_id;
alter table petshopschema.employee drop column profession;

create type profession_enum as enum ('Кипер', 'Уборщик');
alter table petshopschema.employee add column profession profession_enum;

create table petshopschema.keeper_assignments (
    keeper_id int references employee(id),
    pet_id int references pet(id),
    assignment_date date,
    primary key (keeper_id, pet_id)
);

create table petshopschema.cleaning_assignments (
    cleaner_id int references employee(id),
    cage_id int references cage(id),
    cleaning_date date not null,
    is_completed boolean default false,
    primary key (cleaner_id, cage_id, cleaning_date)
);
```

## Соответствие Бойсу-Кодду:

### Проблемы:

### employee(id, name, …, cage_id, petshop_id)

Здесь содержатся и cage_id, и petshop_id, хотя для каждой клетки в cage задан один petshop_id. Следовательно, во время хранения сотрудника справедливо cage_id -> petshop_id — нарушение BCNF.

### Как исправить:

1. хранить только cage_id, а petshop_id получать через JOIN или
2. хранить только petshop_id, а привязку к клеткам вынести в отдельную связующую таблицу employee_cage(employee_id, cage_id, from_dt, to_dt).

### cage(id, animal_type_id, petshop_id, current_pet_id)

Если в клетке может быть не более одного «текущего» питомца, то фактически current_pet_id определяет и petshop_id (через pet), и вид (animal_type_id через pet -> breed -> animal_type). Это снова зависимости не от ключа id.

### Как исправить:

1. перенести отношение занятости клетки в pet.cage_id и убрать current_pet_id из cage;

### pet(id, name, age, owner_id, breed_id, food_id, petshop_id)

Здесь явных нарушений нет, но petshop_id дублирует информацию, если местоположение питомца определяется клеткой (cage.petshop_id).

_Решение: хранить petshop_id либо в pet, либо выводить через cage - но не в обоих местах._

### breed(id, breed_name, animal_type_id, average_weight)

breed_name уникально, поэтому необходимо зафиксировать UNIQUE(breed_name), тогда это сведёт все зависимости к суперключам (BCNF).

### client(id, name, surname, passport_data)

passport_data однозначно определяет клиента, поэтому нужно добавить UNIQUE(passport_data).

### food(id, brand_name, food_type)

необходимо добавить UNIQUE(brand_name).

#### Исправление базы данных:

```
ALTER TABLE petshopschema.breed ADD CONSTRAINT breed_name_unique UNIQUE (breed_name);

ALTER TABLE petshopschema.food ADD CONSTRAINT brand_food_type_unique UNIQUE (brand_name, food_type);

ALTER TABLE petshopschema.cage ADD CONSTRAINT current_pet_unique UNIQUE (current_pet_id);

ALTER TABLE petshopschema.pet ADD CONSTRAINT owner_pet_name_unique UNIQUE (owner_id, name);
```
<img width="945" height="818" alt="image" src="https://github.com/user-attachments/assets/d1926794-6dae-403f-946f-c79b8d8d1050" />
