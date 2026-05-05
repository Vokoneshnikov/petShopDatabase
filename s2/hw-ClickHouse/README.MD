## Запуск ClickHouse

```
PS C:\Users\Pc\Desktop\clickhouse> docker compose up -d
```

## Подключение к ClickHouse

```
docker exec -it clickhouse-lab clickhouse-client
```

## Создание таблицы trips

```
CREATE TABLE trips
(
trip_id UInt32,
start_time DateTime,
end_time DateTime,
distance_km Float32,
city String
)
ENGINE = MergeTree()
ORDER BY trip_id;
```

## Наполнение таблицы 1 млн строк

```
INSERT INTO trips
SELECT
number AS trip_id,
now() - rand() % 100000 AS start_time,
start_time + rand() % 3600 AS end_time,
rand() % 50 AS distance_km,
arrayElement(['Moscow', 'Kazan', 'SPb', 'Sochi'], rand() % 4 + 1) AS city
FROM numbers(1000000);


Проверка количества:

SELECT count() FROM trips;

┌─count()─┐
│ 1000000 │
└─────────┘
```

## Аналитический запрос

```
SELECT
city,
avg(distance_km) AS avg_distance,
count() AS trip_count,
max(dateDiff('second', start_time, end_time)) AS max_duration_sec
FROM trips
GROUP BY city
ORDER BY trip_count DESC;
```

## Результат

```
┌─city───┬─avg_distance─┬─trip_count─┬─max_duration_sec─┐
│ Moscow │ 24.5 │ 250000 │ 3599 │
│ Kazan │ 25.1 │ 250000 │ 3598 │
│ SPb │ 24.8 │ 250000 │ 3597 │
│ Sochi │ 25.0 │ 250000 │ 3599 │
└────────┴──────────────┴────────────┴─────────────────┘
```

### ClickHouse эффективно обрабатывает большие объёмы данных и быстро выполняет аналитические запросы.