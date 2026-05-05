```
PS C:\Users\Pc\Desktop\cassandra> docker exec -it cassandra1 nodetool status
Datacenter: datacenter1
=======================
Status=Up/Down
|/ State=Normal/Leaving/Joining/Moving
--  Address     Load        Tokens  Owns (effective)  Host ID                               Rack
UN  172.25.0.2  104.35 KiB  16      100.0%            b7fa8c34-e5bc-42d2-b2c9-e2e7d3bb9259  rack1
UJ  172.25.0.4  128.17 KiB  16      ?                 51777346-c88e-49c9-bfba-1e32e739d15a  rack1
```

заходим:

```
docker exec -it cassandra1 cqlsh
```

### Создать keyspace с replication_factor = 3

```
CREATE KEYSPACE petshop_ks
WITH replication = {
  'class': 'SimpleStrategy',
  'replication_factor': 3
};

USE petshop_ks;

cqlsh:petshop_ks> DESCRIBE KEYSPACE petshop_ks;
CREATE KEYSPACE petshop_ks WITH replication = {'class': 'SimpleStrategy', 'replication_factor': '3'}  AND durable_writes = true;
```

## Создать две таблицы под разные запросы

### поиск заказов по пользователю

```
CREATE TABLE orders_by_customer (
  customer_id uuid,
  order_id uuid,
  order_date timestamp,
  customer_name text,
  product_name text,
  category text,
  price int,
  status text,
  PRIMARY KEY (customer_id, order_date, order_id)
) WITH CLUSTERING ORDER BY (order_date DESC);
```

### те же данные, но поиск по категории

```
CREATE TABLE orders_by_category (
  category text,
  order_id uuid,
  order_date timestamp,
  customer_id uuid,
  customer_name text,
  product_name text,
  price int,
  status text,
  PRIMARY KEY (category, order_date, order_id)
) WITH CLUSTERING ORDER BY (order_date DESC);
```

### добавление одинаковых данных в обе таблицы

```
INSERT INTO orders_by_customer (customer_id, order_id, order_date, customer_name, product_name, category, price, status)
VALUES (11111111-1111-1111-1111-111111111111, aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaa1, toTimestamp(now()), 'Vera', 'Dog food', 'food', 1200, 'created');

INSERT INTO orders_by_category (category, order_id, order_date, customer_id, customer_name, product_name, price, status)
VALUES ('food', aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaa2, toTimestamp(now()), 11111111-1111-1111-1111-111111111111, 'Vera', 'Dog food', 1200, 'created');
```

### select по ключам 1) по пользователю 2) по ключам

```
SELECT * FROM orders_by_customer
WHERE customer_id = 11111111-1111-1111-1111-111111111111;

 customer_id                          | order_date                      | order_id                             | category | customer_name | price | product_name | status
--------------------------------------+---------------------------------+--------------------------------------+----------+---------------+-------+--------------+---------
 11111111-1111-1111-1111-111111111111 | 2026-05-05 18:12:47.216000+0000 | aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaa1 |     food |          Vera |  1200 |     Dog food | created

 SELECT * FROM orders_by_category
WHERE category = 'food';

 category | order_date                      | order_id                             | customer_id                          | customer_name | price | product_name | status
----------+---------------------------------+--------------------------------------+--------------------------------------+---------------+-------+--------------+---------
     food | 2026-05-05 18:14:17.427000+0000 | aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaa2 | 11111111-1111-1111-1111-111111111111 |          Vera |  1200 |     Dog food | created
     food | 2026-05-05 18:14:01.736000+0000 | aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaa3 | 11111111-1111-1111-1111-111111111111 |          Vera |  1200 |     Dog food | created
     food | 2026-05-05 18:13:36.869000+0000 | aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaa2 | 11111111-1111-1111-1111-111111111111 |          Vera |  1200 |     Dog food | created
     food | 2026-05-05 18:12:51.969000+0000 | aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaa1 | 11111111-1111-1111-1111-111111111111 |          Vera |  1200 |     Dog food | created
```

### UPDATE

```
UPDATE orders_by_customer
SET status = 'paid'
WHERE customer_id = 11111111-1111-1111-1111-111111111111
  AND order_date = '2026-05-05 18:14:17'
  AND order_id = aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaa1;
```

### DELETE

```
DELETE FROM orders_by_customer
WHERE customer_id = 11111111-1111-1111-1111-111111111111
  AND order_date = '2026-05-05 18:14:17'
  AND order_id = aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaa1;

  DELETE FROM orders_by_category
WHERE category = 'food'
  AND order_date = '2026-05-05 10:00:00'
  AND order_id = aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaa1;
```

### Ошибка SELECT по неключевому полю

```
SELECT * FROM orders_by_customer
              ... WHERE status = 'paid';
InvalidRequest: Error from server: code=2200 [Invalid query] message="Cannot execute this query as it might involve data filtering and thus may have unpredictable performance. If you want to execute this query despite the performance unpredictability, use ALLOW FILTERING"
```

### Остановить одну ноду

```
docker stop cassandra3

Status=Up/Down
|/ State=Normal/Leaving/Joining/Moving
--  Address     Load       Tokens  Owns (effective)  Host ID                               Rack
UN  172.25.0.2  98.53 KiB  16      100.0%            249766e6-c4af-4e33-b219-47f09d031cdd  rack1
DJ  172.25.0.4  93.47 KiB  16      ?                 4029130a-8452-4e1e-b154-c9b92e302d6b  rack1
```

### Проверить, что чтение и запись работают

```
USE petshop_ks;

INSERT INTO orders_by_category (category, order_id, order_date, customer_id, customer_name, product_name, price, status)
VALUES ('accessories', aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaa9, '2026-05-05 11:00:00', 22222222-2222-2222-2222-222222222222, 'Alex', 'Pet brush', 900, 'created');

SELECT * FROM orders_by_category WHERE category = 'accessories';


 category    | order_date                      | order_id                             | customer_id                          | customer_name | price | product_name | status
-------------+---------------------------------+--------------------------------------+--------------------------------------+---------------+-------+--------------+---------
 accessories | 2026-05-05 11:00:00.000000+0000 | aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaa9 | 22222222-2222-2222-2222-222222222222 |          Alex |   900 |    Pet brush | created

(1 rows)
```

## работает, значит отказоустойчивость есть