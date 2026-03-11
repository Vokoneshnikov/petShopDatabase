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

# Nested Loop

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

<img width="316" height="101" alt="image" src="https://github.com/user-attachments/assets/5db7e75a-d88c-40bd-8b65-9a7e666eb446" />

# Hash Loop

В данном Hash запросе таблице Food имеет мало записей - 800, а таблица Pet имеет 100к+

```



```

### Результат:


# Hash Loop

В данном Hash запросе таблице Food имеет мало записей - 800, а таблица Pet имеет 100к+

```



```

### Результат:


# Hash Loop

В данном Hash запросе таблице Food имеет мало записей - 800, а таблица Pet имеет 100к+

```



```

### Результат:


# Hash Loop

В данном Hash запросе таблице Food имеет мало записей - 800, а таблица Pet имеет 100к+

```



```

### Результат:
