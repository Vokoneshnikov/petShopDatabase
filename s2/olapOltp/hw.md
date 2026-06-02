- главный факт: fact_task_events
- зерно: 1 строка = 1 задача из tasks

### aналитические вопросы

- какая динамика создания задач по дням?
- какие типы задач самые частые?
- сколько задач обработал каждый воркер и какая доля ошибок?

### измерения:

- dim_date
- dim_task_type
- dim_worker
- dim_priority

### создание таблиц

```
CREATE SCHEMA IF NOT EXISTS olap;

DROP TABLE IF EXISTS olap.fact_task_events;
DROP TABLE IF EXISTS olap.dim_date;
DROP TABLE IF EXISTS olap.dim_task_type;
DROP TABLE IF EXISTS olap.dim_worker;
DROP TABLE IF EXISTS olap.dim_priority;

CREATE TABLE olap.dim_date (
    date_key int PRIMARY KEY,
    full_date date NOT NULL,
    year int NOT NULL,
    month int NOT NULL,
    day int NOT NULL
);

CREATE TABLE olap.dim_task_type (
    task_type_key bigserial PRIMARY KEY,
    task_type text NOT NULL UNIQUE
);

CREATE TABLE olap.dim_worker (
    worker_key bigserial PRIMARY KEY,
    worker_name text NOT NULL UNIQUE
);

CREATE TABLE olap.dim_priority (
    priority_key bigserial PRIMARY KEY,
    priority int NOT NULL UNIQUE,
    priority_name text NOT NULL
);

CREATE TABLE olap.fact_task_events (
    task_id bigint PRIMARY KEY,
    date_key int NOT NULL REFERENCES olap.dim_date(date_key),
    task_type_key bigint NOT NULL REFERENCES olap.dim_task_type(task_type_key),
    worker_key bigint REFERENCES olap.dim_worker(worker_key),
    priority_key bigint NOT NULL REFERENCES olap.dim_priority(priority_key),

    status text NOT NULL,
    attempts int NOT NULL,

    created_at timestamp NOT NULL,
    started_at timestamp,
    finished_at timestamp,

    wait_seconds numeric,
    processing_seconds numeric
);
```

### заполнение измерений

```
INSERT INTO olap.dim_date (date_key, full_date, year, month, day)
SELECT DISTINCT
    to_char(created_at::date, 'YYYYMMDD')::int AS date_key,
    created_at::date AS full_date,
    extract(year from created_at)::int AS year,
    extract(month from created_at)::int AS month,
    extract(day from created_at)::int AS day
FROM tasks;

INSERT INTO olap.dim_task_type (task_type)
SELECT DISTINCT task_type
FROM tasks;

INSERT INTO olap.dim_worker (worker_name)
SELECT DISTINCT locked_by
FROM tasks
WHERE locked_by IS NOT NULL;

INSERT INTO olap.dim_priority (priority, priority_name)
SELECT DISTINCT
    priority,
    CASE
        WHEN priority >= 10 THEN 'critical'
        ELSE 'normal'
    END
FROM tasks;
```

## запросы

- динамика активности по дням

```
SELECT
   dd.full_date,
   count(*) AS task_count
FROM olap.fact_task_events f
JOIN olap.dim_date dd ON dd.date_key = f.date_key
GROUP BY dd.full_date
ORDER BY dd.full_date;

full_date  | task_count
------------+------------
2026-05-19 |      16884
2026-05-20 |        269
(2 rows)
```

- самые популярные типы задач

```
SELECT
    dtt.task_type,
    count(*) AS task_count
FROM olap.fact_task_events f
JOIN olap.dim_task_type dtt ON dtt.task_type_key = f.task_type_key
GROUP BY dtt.task_type
ORDER BY task_count DESC;


         task_type          | task_count
----------------------------+------------
 update_stock               |       4335
 recalculate_product_rating |       4291
 notify_delivery            |       4265
 send_order_email           |       4262
(4 rows)
```

- сколько хадач обработал каждый воркер

```
SELECT
    dw.worker_name,
    f.status,
    count(*) AS task_count
FROM olap.fact_task_events f
JOIN olap.dim_worker dw ON dw.worker_key = f.worker_key
GROUP BY dw.worker_name, f.status
ORDER BY dw.worker_name, f.status;

 worker_name |  status   | task_count
-------------+-----------+------------
 worker-1    | completed |        195
 worker-1    | failed    |         38
 worker-1    | running   |          3
 worker-2    | completed |        177
 worker-2    | failed    |         46
 worker-2    | running   |          3
(6 rows)
```

- среднее ожидание по приоритетам

```
SELECT
    dp.priority_name,
    dp.priority,
    count(*) AS task_count,
    round(avg(f.wait_seconds), 2) AS avg_wait_seconds
FROM olap.fact_task_events f
JOIN olap.dim_priority dp ON dp.priority_key = f.priority_key
WHERE f.started_at IS NOT NULL
GROUP BY dp.priority_name, dp.priority
ORDER BY dp.priority DESC;

 priority_name | priority | task_count | avg_wait_seconds
---------------+----------+------------+------------------
 critical      |       10 |        338 |          4358.52
 normal        |        1 |        124 |           572.20
(2 rows)
```

### вывод: Модель позволяет анализировать динамику нагрузки по дням, популярность типов задач, работу воркеров и влияние приоритета на время ожидания задачи.
