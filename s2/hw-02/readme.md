# Запросы, которые будем проверять:

```

explain (analyze, buffers)
select * from petshopschema.pet where age > 110

explain (analyze, buffers)
select * from petshopschema.client where petshop_id = 26;

explain (analyze, buffers)
select distinct name from petshopschema.client where name like '%А';

explain (analyze, buffers)
select distinct surname where petshopschema.client where surname like 'В%';

```

## 1. Выборка всех питомцев, у которых возраст больше 110 лет:

### Результаты выполнения ДО:

<img width="826" height="345" alt="image" src="https://github.com/user-attachments/assets/dce7ac9a-dd54-449a-acbb-9b6dba625f3d" />

### Создание индекса:

```

create index index_for_pets_capacity on petshopschema.petshop(pets_capacity);

```


### Результаты выполнения ПОСЛЕ:

<img width="920" height="287" alt="image" src="https://github.com/user-attachments/assets/52e372e4-2adc-4c38-8931-f0ef5a8fc5c7" />

## 2. Выборка всех клиентов, у которых айди питомника = 26:

### Результаты выполнения ДО:

<img width="793" height="298" alt="image" src="https://github.com/user-attachments/assets/7e1e0041-5c7b-4ab1-be71-7cec8ac2578d" />


### Создание индекса:

```

create index index_for_client_petshop_id on petshopschema.client(petshop_id);

```


### Результаты выполнения ПОСЛЕ:

<img width="949" height="247" alt="image" src="https://github.com/user-attachments/assets/4e5b6438-f0fd-4204-8fb8-f76166d13131" />


## 3. Выборка всех клиентов, у которых имя заканчивается на "А"

### Результаты выполнения ДО:

<img width="950" height="398" alt="image" src="https://github.com/user-attachments/assets/11b09eda-1908-42ab-bcde-0082ca5a0c06" />


### Создание индекса:

```

create index index_for_client_name on petshopschema.client using hash (name)

```


### Результаты выполнения ПОСЛЕ:

<img width="828" height="394" alt="image" src="https://github.com/user-attachments/assets/1054d142-256c-4efb-ada1-6430e5707f24" />


## 4. Выборка фамилий всех клиентов, у которыхх фамилия начинается на "В":

### Результаты выполнения ДО:

<img width="829" height="574" alt="image" src="https://github.com/user-attachments/assets/aea27597-9c1d-40da-a570-ccb1e8a772f0" />


### Создание индекса:

```

create index index_for_client_surname on petshopschema.client(surname)

```


### Результаты выполнения ПОСЛЕ:

<img width="1157" height="352" alt="image" src="https://github.com/user-attachments/assets/94075039-d80f-4a7b-938e-5c204fc683d4" />



## 5. Выборка всех питомцев, у которых возраст больше 110 лет:

### Результаты выполнения ДО:


### Создание индекса:

```

create index index_for_pets_capacity on petshopschema.petshop(pets_capacity);

```


### Результаты выполнения ПОСЛЕ:

