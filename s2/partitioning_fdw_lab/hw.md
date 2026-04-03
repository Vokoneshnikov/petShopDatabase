## 1. RANGE partitioning

## создание секционированной таблицы. она не хранит данные на прямую, а только определяет общую структуру для всех секций

### секционирование выполняется по полю trip_date с помощью стратегии RANGE

```
CREATE TABLE trips_range (
    id int,
    city text,
    trip_date date,
    amount int
) PARTITION BY RANGE (trip_date);
```

### секция trips_range_2024 хранит строки, у которых trip_date находится в диапазоне с 1 января 2024 года, до 31 декабря 2024 года

```
CREATE TABLE trips_range_2024 PARTITION OF trips_range
FOR VALUES FROM ('2024-01-01') TO ('2025-01-01');
```

### секция trips_range_2025 хранит строки, у которых trip_date находится в диапазоне с 1 января 2025 года, до 31 декабря 2025 года

```
CREATE TABLE trips_range_2025 PARTITION OF trips_range
FOR VALUES FROM ('2025-01-01') TO ('2026-01-01');
```

### для каждой секции создаются отдельные индексы

```
CREATE INDEX idx_trips_range_2024_date ON trips_range_2024(trip_date);
CREATE INDEX idx_trips_range_2025_date ON trips_range_2025(trip_date);
```

### тестовые данные

```
INSERT INTO trips_range
SELECT
gs,
CASE WHEN gs % 2 = 0 THEN 'Kazan' ELSE 'Moscow' END,
DATE '2024-01-01' + (gs % 700),
gs % 1000
FROM generate_series(1, 10000) gs;
```

```

                                                             QUERY PLAN
-------------------------------------------------------------------------------------------------------------------------------------
 Bitmap Heap Scan on trips_range_2024 trips_range  (cost=4.47..34.87 rows=19 width=44) (actual time=0.055..0.122 rows=465 loops=1)
   Recheck Cond: ((trip_date >= '2024-03-01'::date) AND (trip_date < '2024-04-01'::date))
   Heap Blocks: exact=15
   Buffers: shared hit=17
   ->  Bitmap Index Scan on idx_trips_range_2024_date  (cost=0.00..4.47 rows=19 width=0) (actual time=0.044..0.044 rows=465 loops=1)
         Index Cond: ((trip_date >= '2024-03-01'::date) AND (trip_date < '2024-04-01'::date))
         Buffers: shared hit=2
 Planning:
   Buffers: shared hit=36 read=10
 Planning Time: 0.670 ms
 Execution Time: 0.163 ms
(11 rows)
```

- partition pruning есть
- в плане участвует только секция
- используется битмап индекс скан
- для RANGE-секционирования оптимизация сработала корректно

## 2. LIST partitioning

## создание секционированной таблицы. она не хранит данные напрямую, а определяет общую структуру для секций

```
CREATE TABLE trips_list (
id int,
city text,
trip_date date,
amount int
) PARTITION BY LIST (city);
```

### секционирование выполняется по полю city с помощью стратегии LIST

### секция trips_list_kazan хранит строки, у которых city = Kazan

```
CREATE TABLE trips_list_kazan PARTITION OF trips_list
FOR VALUES IN ('Kazan');
```

### секция trips_list_moscow хранит строки, у которых city = Moscow

```
CREATE TABLE trips_list_moscow PARTITION OF trips_list
FOR VALUES IN ('Moscow');
```

### секция trips_list_other является секцией по умолчанию. туда попадают города, для которых нет отдельной секции

```
CREATE TABLE trips_list_other PARTITION OF trips_list
DEFAULT;
```

### для секций создаются индексы по полю city

```
CREATE INDEX idx_trips_list_kazan_city ON trips_list_kazan(city);
CREATE INDEX idx_trips_list_moscow_city ON trips_list_moscow(city);
```

### тестовые данные

```
INSERT INTO trips_list
SELECT
gs,
CASE
WHEN gs % 3 = 0 THEN 'Kazan'
WHEN gs % 3 = 1 THEN 'Moscow'
ELSE 'Sochi'
END,
DATE '2024-01-01' + (gs % 300),
gs % 1000
FROM generate_series(1, 10000) gs;
```

### запрос

```
EXPLAIN (ANALYZE, BUFFERS)
SELECT *
FROM trips_list
WHERE city = 'Kazan';
```

```
Seq Scan on trips_list_kazan trips_list (cost=0.00..72.66 rows=3333 width=44) (actual time=0.018..0.621 rows=3333 loops=1)
Filter: (city = 'Kazan'::text)
Buffers: shared hit=31
Planning:
Buffers: shared hit=42
Planning Time: 0.411 ms
Execution Time: 0.812 ms
(7 rows)
```

- partition pruning есть
- в плане участвует только секция trips_list_kazan
- секции trips_list_moscow и trips_list_other не сканируются
- индекс не использовался, потому что в секции много строк с одинаковым значением city, поэтому planner выбрал Seq Scan
- для LIST-секционирования оптимизация сработала корректно: PostgreSQL исключил лишние секции

## 3. HASH partitioning

## создание секционированной таблицы. она делит данные по хешу значения id

### секционирование выполняется по полю id с помощью стратегии HASH

```
CREATE TABLE trips_hash (
id int,
city text,
trip_date date,
amount int
) PARTITION BY HASH (id);
```

### создаются 4 hash-секции

```
CREATE TABLE trips_hash_0 PARTITION OF trips_hash
FOR VALUES WITH (MODULUS 4, REMAINDER 0);

CREATE TABLE trips_hash_1 PARTITION OF trips_hash
FOR VALUES WITH (MODULUS 4, REMAINDER 1);

CREATE TABLE trips_hash_2 PARTITION OF trips_hash
FOR VALUES WITH (MODULUS 4, REMAINDER 2);

CREATE TABLE trips_hash_3 PARTITION OF trips_hash
FOR VALUES WITH (MODULUS 4, REMAINDER 3);
```

### для каждой секции создаётся индекс по id

```
CREATE INDEX idx_trips_hash_0_id ON trips_hash_0(id);
CREATE INDEX idx_trips_hash_1_id ON trips_hash_1(id);
CREATE INDEX idx_trips_hash_2_id ON trips_hash_2(id);
CREATE INDEX idx_trips_hash_3_id ON trips_hash_3(id);
```

### тестовые данные

```
INSERT INTO trips_hash
SELECT
gs,
CASE WHEN gs % 2 = 0 THEN 'Kazan' ELSE 'Moscow' END,
DATE '2024-01-01' + (gs % 300),
gs % 1000
FROM generate_series(1, 10000) gs;
```

### запрос

```
EXPLAIN (ANALYZE, BUFFERS)
SELECT *
FROM trips_hash
WHERE id = 100;
```

```
Index Scan using idx_trips_hash_0_id on trips_hash_0 trips_hash (cost=0.28..8.30 rows=1 width=44) (actual time=0.021..0.022 rows=1 loops=1)
Index Cond: (id = 100)
Buffers: shared hit=3
Planning:
Buffers: shared hit=51
Planning Time: 0.487 ms
Execution Time: 0.041 ms
(7 rows)
```

- partition pruning есть
- в плане участвует только одна hash-секция
- используется индекс idx_trips_hash_0_id
- запрос выполняется быстро, потому что PostgreSQL по значению id определил нужную секцию и не сканировал остальные
- HASH-секционирование удобно для равномерного распределения данных по секциям

---

## 4. Partitioning + physical replication

### проверка секционирования на реплике

На master была создана секционированная таблица `trips_range` с секциями `trips_range_2024` и `trips_range_2025`.

После настройки physical replication проверяем наличие секций на реплике.

### команда на реплике

```
SELECT
inhrelid::regclass AS partition,
inhparent::regclass AS parent
FROM pg_inherits;
```

### результат

partition | parent
--------------------+-------------
trips_range_2024 | trips_range
trips_range_2025 | trips_range
trips_list_kazan | trips_list
trips_list_moscow | trips_list
trips_list_other | trips_list
trips_hash_0 | trips_hash
trips_hash_1 | trips_hash
trips_hash_2 | trips_hash
trips_hash_3 | trips_hash
(9 rows)

- секционирование на реплике есть
- все секции, созданные на master, видны на replica
- структура таблиц и партиций полностью совпадает

### почему physical replication “не знает” про секции

физическая репликация работает на уровне WAL и файлов данных PostgreSQL. она не анализирует таблицу как логическую структуру и не принимает решений какая это таблица - обычная или секция. для physical replication секции — это обычные relation-файлы PostgreSQL, изменения которых записываются в WAL и передаются на реплику.

- postgreSQL master создаёт секционированную структуру
- изменения этой структуры попадают в WAL
- replica применяет WAL
- в результате на реплике появляются те же секции

### вывод

физическая репликация полностью копирует состояние кластера PostgreSQL на уровне данных и метаданных. поэтому секционированные таблицы и их секции появляются на реплике автоматически. репликация при этом не работает с секциями отдельно, просто воспроизводит WAL-записи.

## 5. Logical replication

## проверка publish_via_partition_root = off / on

логическая репликация работает не на уровне файлов, а на уровне изменений строк. для секционированных таблиц важно, как публикуются изменения от имени конкретной секции или от имени родительской таблицы.

### вариант 1: publish_via_partition_root = off

```
CREATE PUBLICATION pub_part_off
FOR TABLE trips_range
WITH (publish_via_partition_root = false);
```

### При publish_via_partition_root = false изменения публикуются от имени конкретных секций. то есть если строка физически попала в секцию trips_range_2024, то subscriber должен уметь принять изменение именно для этой секции.

### что это означает

- на subscriber желательно иметь такую же структуру секций
- subscriber должен знать секции, в которые приходят изменения
- настройка ближе к физической структуре publisher

### вариант 2: publish_via_partition_root = on

```
CREATE PUBLICATION pub_part_on
FOR TABLE trips_range
WITH (publish_via_partition_root = true);
```

При publish_via_partition_root = true изменения публикуются от имени родительской таблицы. То есть subscriber получает изменение как изменение таблицы trips_range, а не конкретной секции.

### что это означает

- subscriber может работать через родительскую таблицу
- проще поддерживать структуру на стороне подписчика
- логическая репликация становится менее зависимой от физического разбиения на секции

### проверка вставки

На publisher:

```
INSERT INTO trips_range
VALUES (20001, 'Kazan', '2024-05-10', 500);
```

### результат

```
id | city | trip_date | amount
-------+-------+------------+--------
20001 | Kazan | 2024-05-10 | 500
(1 row)
```

- данные реплицируются
- строка доступна на subscriber
- при publish_via_partition_root = on изменение приходит через родительскую таблицу

### вывод

Логическая репликация секционированных таблиц зависит от параметра publish_via_partition_root. Если параметр выключен, изменения публикуются от имени конкретных секций. Если включён, изменения публикуются от имени родительской таблицы.

## 6. FDW sharding

## самостоятельная реализация: 2 шарда и 1 router

В этом блоке реализуется простое шардирование через postgres_fdw.

Используются три PostgreSQL instance:

- pg-shard1 — первый шард
- pg-shard2 — второй шард
- pg-router — router, который подключается к шардам через FDW

## создание таблицы на shard1

```
CREATE TABLE orders (
id int primary key,
customer_id int,
amount int,
city text
);

INSERT INTO orders
SELECT gs, gs % 100, gs % 1000, 'Kazan'
FROM generate_series(1, 5000) gs;
```

### пояснение

На первом шарде хранятся заказы с id от 1 до 5000. Для простоты все строки имеют город Kazan.

## создание таблицы на shard2

```
CREATE TABLE orders (
id int primary key,
customer_id int,
amount int,
city text
);

INSERT INTO orders
SELECT gs, gs % 100, gs % 1000, 'Moscow'
FROM generate_series(5001, 10000) gs;
```

### пояснение

На втором шарде хранятся заказы с id от 5001 до 10000. Для простоты все строки имеют город Moscow.

## настройка router

На router включается расширение postgres_fdw.

```
CREATE EXTENSION postgres_fdw;
```

### создаём подключения к shard1 и shard2

```
CREATE SERVER shard1_server
FOREIGN DATA WRAPPER postgres_fdw
OPTIONS (host 'pg-shard1', port '5432', dbname 'shard1_db');

CREATE SERVER shard2_server
FOREIGN DATA WRAPPER postgres_fdw
OPTIONS (host 'pg-shard2', port '5432', dbname 'shard2_db');
```

### создаём user mapping

```
CREATE USER MAPPING FOR postgres
SERVER shard1_server
OPTIONS (user 'postgres', password 'postgres');

CREATE USER MAPPING FOR postgres
SERVER shard2_server
OPTIONS (user 'postgres', password 'postgres');
```

### создаём foreign tables

```
CREATE FOREIGN TABLE orders_shard1 (
id int,
customer_id int,
amount int,
city text
)
SERVER shard1_server
OPTIONS (schema_name 'public', table_name 'orders');

CREATE FOREIGN TABLE orders_shard2 (
id int,
customer_id int,
amount int,
city text
)
SERVER shard2_server
OPTIONS (schema_name 'public', table_name 'orders');
```

### создаём общую view

```
CREATE VIEW orders_all AS
SELECT * FROM orders_shard1
UNION ALL
SELECT * FROM orders_shard2;
```

### пояснение

Router не хранит сами данные. Он хранит только foreign tables, которые ссылаются на таблицы на shard1 и shard2. View orders_all объединяет данные с двух шардов и позволяет обращаться к ним как к одной общей таблице.

## простой запрос на все данные

```
EXPLAIN (ANALYZE, VERBOSE)
SELECT count(*)
FROM orders_all;
```

### результат

```
Aggregate (cost=250.00..250.01 rows=1 width=8) (actual time=6.201..6.203 rows=1 loops=1)
Output: count(*)
-> Append (cost=100.00..225.00 rows=10000 width=0) (actual time=1.781..5.654 rows=10000 loops=1)
-> Foreign Scan on public.orders_shard1 (cost=100.00..112.50 rows=5000 width=0) (actual time=1.780..2.704 rows=5000 loops=1)
Output: orders_shard1.id, orders_shard1.customer_id, orders_shard1.amount, orders_shard1.city
Remote SQL: SELECT NULL FROM public.orders
-> Foreign Scan on public.orders_shard2 (cost=100.00..112.50 rows=5000 width=0) (actual time=1.425..2.511 rows=5000 loops=1)
Output: orders_shard2.id, orders_shard2.customer_id, orders_shard2.amount, orders_shard2.city
Remote SQL: SELECT NULL FROM public.orders
Planning Time: 0.621 ms
Execution Time: 6.337 ms
(11 rows)
```

- запрос обращается к обоим шардам
- в плане виден Append
- участвуют orders_shard1 и orders_shard2
- router собирает общий результат
- данные физически лежат на разных PostgreSQL instance

## простой запрос на один шард

```
EXPLAIN (ANALYZE, VERBOSE)
SELECT *
FROM orders_shard1
WHERE city = 'Kazan'
LIMIT 10;
```

### результат

```
Foreign Scan on public.orders_shard1 (cost=100.00..110.00 rows=10 width=44) (actual time=1.119..1.126 rows=10 loops=1)
Output: id, customer_id, amount, city
Remote SQL: SELECT id, customer_id, amount, city FROM public.orders WHERE ((city = 'Kazan'::text)) LIMIT 10::bigint
Planning Time: 0.182 ms
Execution Time: 1.187 ms
(5 rows)
```

- участвует только orders_shard1
- orders_shard2 не участвует
- условие city = Kazan отправлено на удалённый сервер
- это видно по строке Remote SQL
- запрос выполняется быстрее, потому что обращается только к одному шарду

## запрос через общую view

```
EXPLAIN (ANALYZE, VERBOSE)
SELECT *
FROM orders_all
WHERE city = 'Kazan'
LIMIT 10;
```

```
Limit (cost=100.00..110.25 rows=10 width=44) (actual time=1.018..1.034 rows=10 loops=1)
Output: orders_shard1.id, orders_shard1.customer_id, orders_shard1.amount, orders_shard1.city
-> Append (cost=100.00..305.00 rows=200 width=44) (actual time=1.017..1.031 rows=10 loops=1)
-> Foreign Scan on public.orders_shard1 (cost=100.00..152.50 rows=100 width=44) (actual time=1.016..1.028 rows=10 loops=1)
Output: orders_shard1.id, orders_shard1.customer_id, orders_shard1.amount, orders_shard1.city
Remote SQL: SELECT id, customer_id, amount, city FROM public.orders WHERE ((city = 'Kazan'::text))
-> Foreign Scan on public.orders_shard2 (cost=100.00..152.50 rows=100 width=44) (never executed)
Output: orders_shard2.id, orders_shard2.customer_id, orders_shard2.amount, orders_shard2.city
Remote SQL: SELECT id, customer_id, amount, city FROM public.orders WHERE ((city = 'Kazan'::text))
Planning Time: 0.271 ms
Execution Time: 1.091 ms
(11 rows)
```

- запрос выполняется через view orders_all
- план содержит Append, потому что view объединяет два foreign table
- фильтр city = 'Kazan` отправляется на удалённые серверы
- в данном примере orders_shard2 не был выполнен из-за LIMIT, но в общем случае router может обращаться к обеим веткам view
- postgres_fdw не является полноценным автоматическим шардировщиком тк он не знает бизнес-правило, что Kazan лежит только на shard1

## вывод по FDW sharding

Шардирование через postgres_fdw позволяет вручную распределить данные между несколькими PostgreSQL instance и собрать доступ к ним через router.

Router обращается к shard1 и shard2 как к foreign tables. Для пользователя это похоже на работу с общей таблицей, но фактически данные находятся на разных серверах.

Важно, что FDW не делает автоматическое шардирование. Разбиение данных по шардам проектируется вручную. Поэтому для точного запроса на один шард лучше обращаться к конкретной foreign table или проектировать ограничения так, чтобы planner мог исключать лишние источники.
