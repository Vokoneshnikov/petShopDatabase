# Запросы, которые будем проверять:

```

explain (analyze, buffers)
select * from petshopschema.petshop where pets_capacity < 100;

explain (analyze, buffers)
select * from petshopschema.pet where age > 5

explain (analyze, buffers)
select * from petshopschema.client where petshop_id = 28;

explain (analyze, buffers)
select distinct name from petshopschema.client where name like '%А';

explain (analyze, buffers)
select surname where petshopschema.client where surname like 'В%';

```

## 1. Выборка всех питомцев, у которых возраст больше 110 лет:

### Результаты выполнения ДО:


### Создание индекса:

```

create index index_for_pets_capacity on petshopschema.petshop(pets_capacity);

```


### Результаты выполнения ПОСЛЕ:


## 2. Выборка всех питомцев, у которых возраст больше 110 лет:

### Результаты выполнения ДО:


### Создание индекса:

```

create index index_for_pets_capacity on petshopschema.petshop(pets_capacity);

```


### Результаты выполнения ПОСЛЕ:




## 3. Выборка всех питомцев, у которых возраст больше 110 лет:

### Результаты выполнения ДО:


### Создание индекса:

```

create index index_for_pets_capacity on petshopschema.petshop(pets_capacity);

```


### Результаты выполнения ПОСЛЕ:



## 4. Выборка всех питомцев, у которых возраст больше 110 лет:

### Результаты выполнения ДО:


### Создание индекса:

```

create index index_for_pets_capacity on petshopschema.petshop(pets_capacity);

```


### Результаты выполнения ПОСЛЕ:




## 5. Выборка всех питомцев, у которых возраст больше 110 лет:

### Результаты выполнения ДО:


### Создание индекса:

```

create index index_for_pets_capacity on petshopschema.petshop(pets_capacity);

```


### Результаты выполнения ПОСЛЕ:

