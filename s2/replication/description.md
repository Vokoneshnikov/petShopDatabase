### Схема : фото

## Архитектура состоит из одного master-узла и двух read-only реплик. Репликация настраивается как physical streaming replication: master передаёт WAL записи репликам, которые воспроизводят изменения данных.

## Физическая реплика:

см. фото

```
SELECT pg_is_in_recovery();
```

- true

```
INSERT INTO repl_test VALUES (1, 'from master');
```

- успешно

```
SELECT * FROM repl_test;
```

1 | from master

```
INSERT INTO repl_test VALUES (2, 'from replica');
```

- ошибка read only

```
docker restart pg-replica1
docker exec -it pg-replica1 psql -U postgres -d postgres

SELECT pg_is_in_recovery();
\q

\l
\c petshop_repl
CREATE TABLE repl_test (
    id int PRIMARY KEY,
    name text
);
INSERT INTO repl_test VALUES (1, 'from master');
SELECT * FROM repl_test;
\q

docker exec -it pg-replica1 psql -U postgres -d petshop_repl

SELECT * FROM repl_test;
INSERT INTO repl_test VALUES (2, 'from replica');
\q


SELECT application_name, state, sync_state, sent_lsn, write_lsn, flush_lsn, replay_lsn
FROM pg_stat_replication;
\q
```

### Анализ replication lag

```
SELECT
    sent_lsn,
    replay_lsn,
    pg_wal_lsn_diff(sent_lsn, replay_lsn) AS lag_bytes
FROM pg_stat_replication;
```

Использована функция pg_wal_lsn_diff для оценки задержки.

Если lag_bytes ≈ 0: реплика синхронизирована с master.
Если lag_bytes > 0: наблюдается отставание в применении WAL.

В текущем эксперименте lag 0, реплика практически синхронна.

### Наблюдение lag под нагрузкой

При массовой вставке (10 000 строк) наблюдается рост lag.

Это связано с тем, что:

- master генерирует WAL быстрее
- чем реплика успевает его применить

После завершения нагрузки lag уменьшается.

### Ограничения реплики

Реплика не допускает запись данных.

Любая попытка INSERT/UPDATE приводит к ошибке read-only transaction.

### Вывод

Настроена physical streaming replication:

- данные реплицируются с master на replica
- запись возможна только на master
- реплика работает в режиме read-only
- lag зависит от нагрузки

# Логическая репликация PostgreSQL

## Архитектура

В рамках задания была настроена логическая репликация между двумя экземплярами PostgreSQL:

- **Master (publisher)** — `pg-master-logical`
- **Replica (subscriber)** — `pg-replica1`

Репликация реализована через механизм:

- `PUBLICATION` — источник данных
- `SUBSCRIPTION` — подписчик

---

Для работы логической репликации требуется:

```sql
SHOW wal_level;
```

Результат:

```text
logical
```

Параметр `wal_level` был установлен в значение `logical` через `docker-compose`.

---

## Создание структуры данных

- На master:

```sql
CREATE DATABASE petshop_repl_logical;
\c petshop_repl_logical

CREATE TABLE logical_test (
    id INT PRIMARY KEY,
    name TEXT
);
```

- На replica была создана идентичная структура:

```sql
CREATE DATABASE petshop_repl_logical;
\c petshop_repl_logical

CREATE TABLE logical_test (
    id INT PRIMARY KEY,
    name TEXT
);
```

---

## Настройка publication

- На master:

```sql
CREATE PUBLICATION my_pub FOR TABLE logical_test;
```

- ublication определяет, какие таблицы участвуют в репликации.

---

## Настройка subscription

- На replica:

```sql
CREATE SUBSCRIPTION my_sub
CONNECTION 'host=pg-master-logical port=5432 user=postgres password=postgres dbname=petshop_repl_logical'
PUBLICATION my_pub;
```

- Подписка устанавливает соединение с master и начинает получать изменения.

---

## Проверка репликации данных

На master:

```sql
INSERT INTO logical_test VALUES (1, 'logical works');
```

На replica:

```sql
SELECT * FROM logical_test;
```

- Результат:

```text
1 | logical works
```

Данные успешно реплицируются.

---

## Проверка отсутствия DDL-репликации

- На master:

```sql
ALTER TABLE logical_test ADD COLUMN extra INT;
```

- На replica:

```sql
\d logical_test
```

- Новая колонка отсутствует.

- Вывод: DDL-изменения не реплицируются в logical replication.

---

## Проверка REPLICA IDENTITY

Создание таблицы без первичного ключа:

```sql
CREATE TABLE no_pk (
    name TEXT
);
```

Добавление в publication:

```sql
ALTER PUBLICATION my_pub ADD TABLE no_pk;
```

Попытка обновления:

```sql
UPDATE no_pk SET name = 'test';
```

Результат — ошибка.

Исправление:

```sql
ALTER TABLE no_pk REPLICA IDENTITY FULL;
```

После этого UPDATE начинает реплицироваться.

---

## Проверка статуса репликации

На replica:

```sql
SELECT * FROM pg_stat_subscription;
```

Отображается активная подписка и процесс получения изменений.

---

## Использование pg_dump / pg_restore

Logical replication:

- не переносит структуру базы
- не переносит исторические данные

Поэтому `pg_dump` используется для:

- начальной инициализации схемы
- загрузки исходных данных перед запуском репликации
