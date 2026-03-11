# Поиск имен 

```

create index index_for_pets on petshopschema.pet using gin(to_tsvector('russian', name));

```

```

explain (analyze, buffers)
select distinct name from petshopschema.pet where to_tsvector('russian', name) @@ to_tsquery('russian', 'лунный | черн:*');

```
### До:

<img width="900" height="101" alt="image" src="https://github.com/user-attachments/assets/4bb549e3-3ce4-4d35-b113-85e4e5c8895e" />

### После:

<img width="947" height="99" alt="image" src="https://github.com/user-attachments/assets/3dde1256-f894-49c6-a408-9ed105a3b2f3" />

2. Поиск по тегам
```

create index idx_pet_tags_gin on petshopschema.pet using gin(tags);

```

```

explain (analyze, buffers)
select distinct name, tags 
from petshopschema.pet 
where tags @> array['игривый'];

```


### До:

<img width="875" height="98" alt="image" src="https://github.com/user-attachments/assets/b07e5d45-369f-459c-b802-58fc92f33fc6" />

### После

<img width="906" height="101" alt="image" src="https://github.com/user-attachments/assets/a606c84f-bc86-4789-9aef-b7f46e73ad02" />
