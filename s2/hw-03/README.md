# Поиск имен (GIN)

```

create index index_for_pets on petshopschema.pet using gin(to_tsvector('russian', name));

```

```

explain (analyze, buffers)
select distinct name from petshopschema.pet where to_tsvector('russian', name) @@ to_tsquery('russian', 'лунный | черн:*');

```
### До:

<img width="900" height="101" alt="image" src="https://github.com/user-attachments/assets/4bb549e3-3ce4-4d35-b113-85e4e5c8895e" />

### После:

<img width="947" height="99" alt="image" src="https://github.com/user-attachments/assets/3dde1256-f894-49c6-a408-9ed105a3b2f3" />

# 2. Поиск по тегам (GIN)
```

create index idx_pet_tags_gin on petshopschema.pet using gin(tags);

```

```

explain (analyze, buffers)
select distinct name, tags 
from petshopschema.pet 
where tags @> array['игривый'];

```


### До:

<img width="875" height="98" alt="image" src="https://github.com/user-attachments/assets/b07e5d45-369f-459c-b802-58fc92f33fc6" />

### После

<img width="906" height="101" alt="image" src="https://github.com/user-attachments/assets/a606c84f-bc86-4789-9aef-b7f46e73ad02" />

# 3. Изменение имен (GIN)


```

create index index_for_client_name on petshopschema.client using gin(to_tsvector('russian', passport_data))

```

```

explain (analyze, buffers)
update petshopschema.client 
set name = 'Глеб'
where passport_data like '%5696';

```


### До:

<img width="647" height="104" alt="image" src="https://github.com/user-attachments/assets/4dd8a8b3-c96a-47cd-8f5f-d9ab98850ca1" />


### После:

<img width="566" height="94" alt="image" src="https://github.com/user-attachments/assets/3f0447f3-30fc-4ba0-aba9-a7e9deb14fca" />

# 4. Изменение имен (GIST)

Аналогично, но GIST:

```

create index index_for_client_name on petshopschema.client using gist(to_tsvector('russian', passport_data))

```

```

explain (analyze, buffers)
update petshopschema.client 
set name = 'Глеб'
where passport_data like '%5696';

```
### До:

<img width="647" height="104" alt="image" src="https://github.com/user-attachments/assets/4dd8a8b3-c96a-47cd-8f5f-d9ab98850ca1" />


### После:

<img width="249" height="108" alt="image" src="https://github.com/user-attachments/assets/7747c7cc-8af5-448d-91ee-cb2332800635" />

# Hash Loop

В данном JOIN запросе таблице Food имеет мало записей - 800, а таблица Pet имеет 100к+

```

explain (analyze, buffers)
select p.name as pet_name, f.brand_name as brand_name
from petshopschema.food f
join petshopschema.pet p on p.food_id = f.id
where p.name like 'Б%'

```

### Результат:
<img width="321" height="287" alt="image" src="https://github.com/user-attachments/assets/130c3b98-b49e-4533-b7a9-1d2a33807c64" />

<img width="809" height="396" alt="image" src="https://github.com/user-attachments/assets/7d512bf0-a66a-4fb6-9024-f6a10f19025f" />

# Hash Loop

В данном Hash запросе таблице Pet больше 100к записей, а у Breed около 100

```

explain (analyze, buffers, format text)
select p.name as pet_name, b.breed_name as pet_breed
from petshopschema.pet p join petshopschema.breed b
on p.breed_id = b.id 

```

### Результат:
<img width="799" height="350" alt="image" src="https://github.com/user-attachments/assets/6433e6d9-71c2-46e2-9065-b226e0bb9ce5" />

<img width="309" height="356" alt="image" src="https://github.com/user-attachments/assets/df6f512f-8f2c-4e47-bb03-305e75cdb18e" />

# Nested Loop

В данном Nested запросе обе таблицы очень маленькие, поэтому он отрабатывает быстро:

```

explain (analyze, buffers, format text)
select at.name as animal_type, b.breed_name as pet_breed
from petshopschema.animal_type at join petshopschema.breed b
on at.id = b.animal_type_id

```

### Результат:
<img width="947" height="349" alt="image" src="https://github.com/user-attachments/assets/b946b8d8-c057-41bf-a8c6-dbea20d1dc6e" />
<img width="342" height="419" alt="image" src="https://github.com/user-attachments/assets/6b48fc3a-16bd-4d5d-999a-f598ad1c8474" />


# Merge Loop

Тут не без помощи нейронки:

```
-- Индекс на внешнем ключе в pet
CREATE INDEX IF NOT EXISTS idx_pet_food_id_sorted 
ON petshopschema.pet(food_id, id);  -- включаем id для уникальности

-- Индекс на первичном ключе в food
CREATE INDEX IF NOT EXISTS idx_food_id_sorted 
ON petshopschema.food(id);

-- Анализируем таблицы
ANALYZE petshopschema.pet;
ANALYZE petshopschema.food;

-- 2. Теперь запрос, который использует Merge Join
EXPLAIN (ANALYZE, BUFFERS, VERBOSE)
SELECT 
    p.name as pet_name,
    p.age,
    f.brand_name,
    f.food_type
FROM petshopschema.pet p
INNER JOIN petshopschema.food f ON p.food_id = f.id
WHERE p.age BETWEEN 1 AND 5
ORDER BY p.food_id; 



```

### Результат:
<img width="1025" height="430" alt="image" src="https://github.com/user-attachments/assets/e45aa899-2309-4c7b-8feb-f9f7da9b16aa" />

