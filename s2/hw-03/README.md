# Поиск имен 

```

create index index_for_pets on petshopschema.pet using gin(to_tsvector('russian', name));

```

```

explain (analyze, buffers)
select distinct name from petshopschema.pet where to_tsvector('russian', name) @@ to_tsquery('russian', 'лунный | черн:*');

```


