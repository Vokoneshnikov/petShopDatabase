## Таблица tasks

```sql
CREATE TABLE tasks (
    id            BIGSERIAL PRIMARY KEY,
    task_type     TEXT NOT NULL,
    payload       JSONB NOT NULL,
    status        TEXT NOT NULL DEFAULT 'ready'
                  CHECK (status IN ('ready','running','completed','failed')),
    priority      INT NOT NULL DEFAULT 0,
    scheduled_at  TIMESTAMPTZ NOT NULL DEFAULT now(),
    created_at    TIMESTAMPTZ NOT NULL DEFAULT now(),
    started_at    TIMESTAMPTZ,
    finished_at   TIMESTAMPTZ,
    attempts      INT NOT NULL DEFAULT 0,
    max_attempts  INT NOT NULL DEFAULT 3,
    worker_id     TEXT,
    error_message TEXT
);
```

## Индексы для быстрой выборки

```sql
CREATE INDEX idx_tasks_fetch
    ON tasks (status, priority DESC, scheduled_at) WHERE status = 'ready';
CREATE INDEX idx_tasks_stuck
    ON tasks (started_at) WHERE status = 'running';
CREATE INDEX idx_tasks_created ON tasks (created_at);
```

## Функция уведомления и триггер

```sql
CREATE OR REPLACE FUNCTION notify_new_task() RETURNS trigger AS $$
BEGIN
    PERFORM pg_notify('new_task', NEW.id::text);
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS task_notify ON tasks;
CREATE TRIGGER task_notify
    AFTER INSERT ON tasks
    FOR EACH ROW
    EXECUTE FUNCTION notify_new_task();
```

<img width="458" height="443" alt="image" src="https://github.com/user-attachments/assets/f6d97b30-8c93-4e34-9b8e-64a175732af4" />

<img width="514" height="441" alt="image" src="https://github.com/user-attachments/assets/4e670c77-b92e-44fd-b1f7-7ebe3a658607" />

<img width="499" height="444" alt="image" src="https://github.com/user-attachments/assets/45702f84-b7df-449b-9f50-7c192dfd624b" />

## Лаг очереди

```sql
SELECT now() - scheduled_at AS lag_seconds, status, priority
FROM tasks
WHERE status = 'ready'
ORDER BY scheduled_at
LIMIT 5;
```
### 150 сообщений в секунду

<img width="355" height="203" alt="image" src="https://github.com/user-attachments/assets/5f845e0b-00c8-4bad-a4a0-c4e17f619367" />

### 300 сообщений в секунду

<img width="357" height="204" alt="image" src="https://github.com/user-attachments/assets/5bad1dc3-6a98-4af4-a29f-9d8b382d0b12" />

## Пропускная способность

Вокреры работали 10 секунд

<img width="374" height="78" alt="image" src="https://github.com/user-attachments/assets/ef87e10e-b09e-4b72-8370-2d9637ee4cba" />

Значит пропускная способность ~ 4-5 сообщений/сек

## Приоритеты

```sql
SELECT id, priority, scheduled_at, started_at
FROM tasks
WHERE status = 'completed'
ORDER BY started_at
LIMIT 500;
```

<img width="731" height="715" alt="image" src="https://github.com/user-attachments/assets/7972c770-2914-4d2a-a146-e4aace923b34" />

## Агрессивный автовакум

```sql
ALTER TABLE tasks SET (
    autovacuum_vacuum_scale_factor = 0.01,
    autovacuum_analyze_scale_factor = 0.005,
    autovacuum_vacuum_threshold = 1000
);
```

## Retry Backoff

<img width="1455" height="172" alt="image" src="https://github.com/user-attachments/assets/b6d4ff46-13a5-4e1f-b7ec-23fe528c5079" />

<img width="497" height="441" alt="image" src="https://github.com/user-attachments/assets/02712c49-4fa7-48da-bb8a-cfdf6914de02" />
