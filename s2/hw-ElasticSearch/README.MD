1. Формирование индексной структуры
Выполняется HTTP‑запрос типа PUT для создания индекса с именем «products»:

powershell
$url = "http://localhost:9200/products"
Invoke-WebRequest -Uri $url -Method Put -ContentType "application/json"
Результат выполнения:

text
StatusCode        : 200
StatusDescription : OK
Content           : {"acknowledged":true,"shards_acknowledged":true,"index":"products"}
RawContent        : HTTP/1.1 200 OK
                    X-elastic-product: Elasticsearch
                    Content-Length: 67
                    Content-Type: application/json

                    {"acknowledged":true,"shards_acknowledged":true,"index":"products"}
Headers           : {[X-elastic-product, Elasticsearch], [Content-Length, 67], [Content-Type, application/json]}
RawContentLength  : 67
2. Вставка документа без явного идентификатора
Создаётся объект с атрибутами товара, преобразуется в JSON и отправляется методом POST в коллекцию _doc:

powershell
$item = @{
    name     = "Ноутбук Lenovo IdeaPad"
    category = "electronics"
    price    = 65000
    in_stock = $true
    brand    = "Lenovo"
} | ConvertTo-Json

Invoke-RestMethod -Uri "http://localhost:9200/products/_doc" -Method Post -ContentType "application/json" -Body $item
Ответ сервера:

text
_index        : products
_id           : jg_Su50B_pYFh4mtkdxp
_version      : 1
result        : created
_shards       : @{total=2; successful=1; failed=0}
_seq_no       : 0
_primary_term : 1
3. Добавление документа с заданным id = 2
Формируется аналогичный JSON, но отправка идёт методом PUT на конкретный URI с указанием идентификатора:

powershell
$data = @{
    name     = "Смартфон Samsung Galaxy"
    category = "electronics"
    price    = 48000
    in_stock = $true
    brand    = "Samsung"
} | ConvertTo-Json

Invoke-RestMethod -Uri "http://localhost:9200/products/_doc/2" -Method Put -ContentType "application/json" -Body $data
Вывод:

text
_index        : products
_id           : 2
_version      : 1
result        : created
_shards       : @{total=2; successful=1; failed=0}
_seq_no       : 1
_primary_term : 1
4. Наполнение индекса несколькими записями
Последовательно загружаются три товара с идентификаторами 3, 4 и 5:

powershell
# Товар №3
$payload = @{
    name     = "Мышь Logitech"
    category = "accessories"
    price    = 2500
    in_stock = $true
    brand    = "Logitech"
} | ConvertTo-Json
Invoke-RestMethod -Uri "http://localhost:9200/products/_doc/3" -Method Put -ContentType "application/json" -Body $payload

# Товар №4
$payload = @{
    name     = "Наушники Sony"
    category = "electronics"
    price    = 7000
    in_stock = $false
    brand    = "Sony"
} | ConvertTo-Json
Invoke-RestMethod -Uri "http://localhost:9200/products/_doc/4" -Method Put -ContentType "application/json" -Body $payload

# Товар №5
$payload = @{
    name     = "Планшет Apple iPad"
    category = "electronics"
    price    = 52000
    in_stock = $true
    brand    = "Apple"
} | ConvertTo-Json
Invoke-RestMethod -Uri "http://localhost:9200/products/_doc/5" -Method Put -ContentType "application/json" -Body $payload
Результаты (последовательно):

text
_index        : products
_id           : 3
_version      : 1
result        : created
_shards       : @{total=2; successful=1; failed=0}
_seq_no       : 2
_primary_term : 1

_index        : products
_id           : 4
_version      : 1
result        : created
_shards       : @{total=2; successful=1; failed=0}
_seq_no       : 3
_primary_term : 1

_index        : products
_id           : 5
_version      : 1
result        : created
_shards       : @{total=2; successful=1; failed=0}
_seq_no       : 4
_primary_term : 1
5. Частичное обновление документа
Для записи с _id = 4 меняются цена и статус наличия. Используется операция _update и поле doc:

powershell
$changes = @{
    doc = @{
        price    = 7500
        in_stock = $true
    }
} | ConvertTo-Json -Depth 3

Invoke-RestMethod -Uri "http://localhost:9200/products/_update/4" -Method Post -ContentType "application/json" -Body $changes
Ответ:

text
_index        : products
_id           : 4
_version      : 2
result        : updated
_shards       : @{total=2; successful=1; failed=0}
_seq_no       : 5
_primary_term : 1
6. Удаление документа
Удаляется товар с идентификатором 3 (запрос DELETE):

powershell
Invoke-RestMethod -Uri "http://localhost:9200/products/_doc/3?pretty" -Method Delete
Вывод:

text
_index        : products
_id           : 3
_version      : 2
result        : deleted
_shards       : @{total=2; successful=1; failed=0}
_seq_no       : 6
_primary_term : 1
7. Поисковые запросы
7.1. Match‑запрос (поиск по слову в поле name)
powershell
$query = '{
  "query": {
    "match": {
      "name": "Lenovo"
    }
  }
}'

Invoke-RestMethod -Uri "http://localhost:9200/products/_search?pretty" -Method Post -ContentType "application/json" -Body $query
Сокращённый вывод (ключевые поля):

text
took        : 132
timed_out   : False
_shards     : @{total=1; successful=1; skipped=0; failed=0}
hits        : @{total=; max_score=1,2576691; hits=System.Object[]}
7.2. Term‑запрос (точное совпадение по brand.keyword)
powershell
$query = '{
  "query": {
    "term": {
      "brand.keyword": "Samsung"
    }
  }
}'

Invoke-RestMethod -Uri "http://localhost:9200/products/_search?pretty" -Method Post -ContentType "application/json" -Body $query
Результат:

text
took        : 5
timed_out   : False
_shards     : @{total=1; successful=1; skipped=0; failed=0}
hits        : @{total=; max_score=1,3862942; hits=System.Object[]}
7.3. Range‑запрос (цена больше 10000)
powershell
$query = '{
  "query": {
    "range": {
      "price": {
        "gt": 10000
      }
    }
  }
}'

Invoke-RestMethod -Uri "http://localhost:9200/products/_search?pretty" -Method Post -ContentType "application/json" -Body $query