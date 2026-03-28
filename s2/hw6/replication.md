#### Настроить потоковую репликацию
##### Развертывание 3 инстансов PostgreSQL
```
docker-compose -up
```

##### Настройка Physical Streaming Replication
1. Настройка мастер
```
docker exec -it pg-master psql -U postgres -d homework 
```

```
-- Создаем пользователя для репликации
CREATE ROLE replicator WITH REPLICATION LOGIN PASSWORD 'repl_password';

-- Проверяем/выставляем уровень WAL 
ALTER SYSTEM SET wal_level = 'logical';
ALTER SYSTEM SET max_wal_senders = 10;
ALTER SYSTEM SET wal_keep_size = '1024MB';
```

Перезапуск контейнерв мастер
```
docker restart pg-master
```

2. Клонирование базы на Физическую реплику (Replica 1)
```
# Останавливаем реплику
docker stop pg-replica-physical

# Очищаем её data-директорию 
docker run --rm -v $(docker volume inspect --format '{{ .Mountpoint }}' homework_pg-replica-physical-data):/data alpine rm -rf /data/* 2>/dev/null || true

# Запускаем pg_basebackup прямо внутрь реплики, подключившись к мастеру
docker run --rm -it \
  --network homework_pg-net \
  -v homework_pg-replica-physical-data:/var/lib/postgresql/data \
  postgres:15 \
  pg_basebackup -h pg-master -U replicator -D /var/lib/postgresql/data -Fp -Xs -R -P
```

Запуск физической реплики
```
docker start pg-replica-physical
```

#### Проверка репликации данных
1. Вставка данных на мастер
```
docker exec -it pg-master psql -U postgres -d homework
```

```
CREATE TABLE test_physical (id SERIAL PRIMARY KEY, val TEXT);
INSERT INTO test_physical (val) VALUES ('это мастер');
```

2. Проверка наличия строки на репликах
```
docker exec -it pg-replica-physical psql -U postgres -d homework
```

```
SELECT * FROM test_physical;
```

Вывод:
```
 id |    val
----+------------
  1 | это мастер
(1 row)
```

3. Что произойдет если попробовать вставить данные на реплике
INSERT на Replica 1
```
INSERT INTO test_physical (val) VALUES ('Попытка записи на реплике');
```

Вывод:
```
ERROR:  cannot execute INSERT in a read-only transaction
```

#### Анализ replication lag
1. Создать нагрузку INSERT
```
for i in {1..10000}; do 
  docker exec -i pg-master psql -U postgres -d homework -c "INSERT INTO test_physical (val) VALUES ('Сообщения нагрузки №$i');" > /dev/null
done
```

```
 application_name | client_addr | sent_lag | write_lag | flush_lag | replay_lag
------------------+-------------+----------+-----------+-----------+------------
 walreceiver      | 172.19.0.4  |        0 |         0 |         0 |          0
(1 row)
```

```
 application_name | client_addr | sent_lag | write_lag | flush_lag | replay_lag
------------------+-------------+----------+-----------+-----------+------------
 walreceiver      | 172.19.0.4  |        0 |         0 |         0 |         32
(1 row)
```

```
 application_name | client_addr | sent_lag | write_lag | flush_lag | replay_lag
------------------+-------------+----------+-----------+-----------+------------
 walreceiver      | 172.19.0.4  |        0 |         0 |         0 |         48
(1 row)
```

```
 application_name | client_addr | sent_lag | write_lag | flush_lag | replay_lag
------------------+-------------+----------+-----------+-----------+------------
 walreceiver      | 172.19.0.4  |        0 |         0 |         0 |         56
(1 row)
```

#### Настроить Logical replication
##### 1. Данные реплицируются
1. Создание на master и на replica2 одинаковой таблицы
```
CREATE TABLE test_logical (
    id SERIAL PRIMARY KEY,
    name TEXT,
    description TEXT
);
```

2. Создание Публикации на master
```
CREATE PUBLICATION my_pub FOR TABLE test_logical;
```

3. Создание Подписки на replica2
```
CREATE SUBSCRIPTION my_sub 
CONNECTION 'host=pg-master port=5432 user=postgres password=superpassword dbname=homework' 
PUBLICATION my_pub;
```

4. Проверка репликации данных
Вставка на master
```
INSERT INTO test_logical (name, description) VALUES ('Логика', 'Проверка');
```

Проверка на реплике
```
SELECT * FROM test_logical;
```

Вывод:
```
 id |  name  |  description
----+--------+----------------
  1 | Логика |    Проверка
(1 row)
```

##### DDL не реплицируется 
Добавим новую колонку на master
```
ALTER TABLE test_logical ADD COLUMN age INT;
```

Вставляем данные с учетом новой колонки на master
```
INSERT INTO test_logical (name, description, age) VALUES ('Алекс', 'Тест DDL', 25);
```

Проверяем на реплике
```
SELECT * FROM test_logical;
```

Новой строки нет
Вывод:
```
 id |  name  |  description
----+--------+----------------
  1 | Логика | Проверка связи
```

После ручного применения DDL
```
ALTER TABLE test_logical ADD COLUMN age INT;
```

Все выводит
Вывод:
```
 id |  name  |  description   | age
----+--------+----------------+-----
  1 | Логика | Проверка связи |
  2 | Алекс  | Тест DDL       |  25
```

##### 2. Проверка REPLICA IDENTITY (Таблица без PK)
Создание таблицы без PK на master и replica2
```
CREATE TABLE no_pk (id INT, val TEXT);
```

Добавим её в публикацию на master
```
ALTER PUBLICATION my_pub ADD TABLE no_pk;
```

На replica2 обновим подписку, чтобы она узнала о новой таблице
```
ALTER SUBSCRIPTION my_sub REFRESH PUBLICATION;
```

Проверка вставки и изменения
```
INSERT INTO no_pk VALUES (1, 'Initial');
```
Все ок

```
UPDATE no_pk SET val = 'Updated' WHERE id = 1;
```

Вывод:
```
ERROR:  cannot update table "no_pk" because it does not have a replica identity and publishes updates
```

##### 3. Проверка статуса логической репликации
На master
```
SELECT * FROM pg_stat_replication;
```

Вывод:
```
 pid  | usesysid |  usename   | application_name | client_addr | client_hostname | client_port |         backend_start         | backend_xmin |   state   |  sent_lsn  | write_lsn  | flush_lsn  | replay_lsn | write_lag | flush_lag | replay_lag | sync_priority | sync_state |          reply_time
------+----------+------------+------------------+-------------+-----------------+-------------+-------------------------------+--------------+-----------+------------+------------+------------+------------+-----------+-----------+------------+---------------+------------+-------------------------------
   84 |    16385 | replicator | walreceiver      | 172.19.0.4  |                 |       34828 | 2026-06-02 22:20:28.536822+00 |              | streaming | 0/78780990 | 0/78780990 | 0/78780990 | 0/78780990 |           |           |            |             0 | async      | 2026-06-02 23:01:01.098017+00
 1345 |       10 | postgres   | my_sub           | 172.19.0.3  |                 |       56146 | 2026-06-02 22:52:09.298025+00 |              | streaming | 0/78780990 | 0/78780990 | 0/78780990 | 0/78780990 |           |           |            |             0 | async      | 2026-06-02 23:01:01.167333+00
(2 rows)
```

```
SELECT * FROM pg_replication_slots;
```


Вывод:
```
 slot_name |  plugin  | slot_type | datoid | database | temporary | active | active_pid | xmin | catalog_xmin | restart_lsn | confirmed_flush_lsn | wal_status | safe_wal_size | two_phase
-----------+----------+-----------+--------+----------+-----------+--------+------------+------+--------------+-------------+---------------------+------------+---------------+-----------
 my_sub    | pgoutput | logical   |  16384 | homework | f         | t      |       1345 |      |          891 | 0/78780A40  | 0/78780A78          | reserved   |               | f
(1 row)
```

На реплике
```
SELECT * FROM pg_stat_subscription;
```

```
 subid | subname | pid | relid | received_lsn |      last_msg_send_time       |    last_msg_receipt_time     | latest_end_lsn |        latest_end_time
-------+---------+-----+-------+--------------+-------------------------------+------------------------------+----------------+-------------------------------
 16398 | my_sub  | 237 |       | 0/78780A78   | 2026-06-02 23:03:52.809053+00 | 2026-06-02 23:03:52.80919+00 | 0/78780A78     | 2026-06-02 23:03:52.809053+00
(1 row)
```

#### Как могут пригодится pg_dump/pg_restore для данного вида репликации
Тк логическая репликация не копирует схемы таблиц (DDL) и индексы, инициализировать пустую реплику вручную для большого кол-ва таблиц тяжело.

Вот тут и приходят на помощь pg_dump и pg_restore:

Перенос схемы (без данных): перед созданием подписки мы делаем дамп только структуры БД с мастера и накатываем на реплику:
```
pg_dump -h pg-master -U postgres -d homework --schema-only > schema.sql
# И накатываем на пустую логическую реплику:
psql -h pg-replica-logical -U postgres -d homework -f schema.sql
```
Синхронизация больших баз: если база огромная, мы можем снять дамп данных, восстановить его на реплике, а логическую репликацию запустить с определенной точки (LSN).