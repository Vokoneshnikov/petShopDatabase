1. Настроить docker-compose
```

 docker compose up -d

```
2. Создание bucket:

Получение токена

```

docker exec -it influxdb3-core influxdb3 create token --admin

```

Создание бд:

```

 curl.exe "http://localhost:8181/api/v3/write_lp?db=testdb" -H "Authorization: Bearer apiv3_-_tITSPFFnRHGNNXUsyoRaOsocKy8HK5dMVaXSt3PyetrvwzaP0FFm3IgHwbMVOpOCUkHcOfzbohlf_k-6k7bw" --data-raw "cpu,host=pc1\` usage=12.5"

```

Запись тестовых данных:

```

curl.exe "http://localhost:8181/api/v3/write_lp?db=testdb" -H "Authorization: Bearer apiv3_-_tITSPFFnRHGNNXUsyoRaOsocKy8HK5dMVaXSt3PyetrvwzaP0FFm3IgHwbMVOpOCUkHcOfzbohlf_k-6k7bw" --data-raw 'cpu,host=pc1 usage=12.5'

```

Чтение: 

```

curl.exe -G "http://localhost:8181/api/v3/query_sql" -H 'Authorization: Bearer apiv3_-_tITSPFFnRHGNNXUsyoRaOsocKy8HK5dMVaXSt3PyetrvwzaP0FFm3IgHwbMVOpOCUkHcOfzbohlf_k-6k7bw' --data-urlencode "db=testdb" --data-urlencode "q=SELECT * FROM cpu LIMIT 10"



[{"host":"pc1","time":"2026-04-21T21:28:02.170094662","usage":12.5}]

```
2) Вставить несколько записей

Вставка данных:

![alt text](image-1.png)

Select:

![alt text](image-2.png)

3) Выбрать все данные за последние 5 минут:
![alt text](image-3.png)
4) Отобразить результат
 - Сделано выше

5) Сгруппировать SELECT по тегу location (например, среднее значение по комнатам)

```

SELECT 
    location, 
    AVG(value) AS average_temperature
FROM temperature
WHERE time >= now() - interval '1 hour'
GROUP BY location


```
![alt text](image-4.png)
