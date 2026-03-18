# Посмотреть на изменение LSN и WAL после изменения данных
## Сравнение LSN до и после INSERT


LSN ДО insert:

```

 lsn_before_insert
-------------------
 0/4D9A0F28

```


ДЕЛАЮ INSERT:

```

INSERT INTO petshopschema.food (id, brand_name, food_type) VALUES (1234567, 'Poorina', 'very tasty');

```

LSN после insert:


```

 lsn_after_insert
------------------
 0/4D9A3890

```


## Сравнение WAL до и после commit


До commit:

```

BEGIN;
CREATE TEMP TABLE temp_wal_stats_before AS
SELECT wal_records, wal_fpi, wal_bytes, stats_reset
FROM pg_stat_wal;



 wal_records | wal_fpi | wal_bytes |          stats_reset
-------------+---------+-----------+-------------------------------
      140692 |   16498 | 128294875 | 2026-02-28 13:37:13.788636+03

```

Выполняем вставку:


```

insert into petshopschema.food (id, brand_name, food_type) values (112234567, 'pooooorina', 'tasty tasty');

```

Коммитим и сверяем данные:

```

select wal_records, wal_fpi, wal_bytes from pg_stat_wal;

 wal_records | wal_fpi | wal_bytes
-------------+---------+-----------
      140804 |   16527 | 128438846

```
## Анализ WAL размера после массовой операции

Общий размер всех файлов:

```

SELECT pg_size_pretty(SUM(size)) AS total_wal_size
FROM pg_ls_waldir();


192 MEGABYTES

```

Количество файлов:

```

SELECT COUNT(*) AS number_of_wal_files
FROM pg_ls_waldir();

Ответ - 12;

```
# Сделать дамп БД и накатить его на новую чистую БД
## Dump только структуры базы
## Dump одной таблицы
# Создать несколько seed
## Добавление тестовых данных 
## Проверка идемпотентности seed (ON CONFLICT и др)
