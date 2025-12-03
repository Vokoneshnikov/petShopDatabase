-- ставит возраст питомца по умолчанию, если его не указали (NEW)
```
create or replace function petshopschema.trg_pet_set_default_age()
returns trigger
language plpgsql
as $$
begin
  if new.age is null then
    new.age := 1;
  end if;
  return new;
end;
$$;

drop trigger if exists trg_pet_set_default_age on petshopschema.pet;

create trigger trg_pet_set_default_age
before insert on petshopschema.pet
for each row
execute function petshopschema.trg_pet_set_default_age();
```

-- запрет отрицательного возраста при update (NOW)
```
CREATE TABLE IF NOT EXISTS petshopschema.audit_pet_row (
  audit_id   bigserial PRIMARY KEY,
  changed_at timestamptz NOT NULL DEFAULT now(),
  action     text        NOT NULL,   
  pet_id     int,
  username   text        NOT NULL DEFAULT current_user,
  old_row    jsonb,
  new_row    jsonb
);

CREATE OR REPLACE FUNCTION petshopschema.trg_pet_bu_validate_age()
RETURNS trigger
AS $$
BEGIN
  IF NEW.age IS NULL THEN
    NEW.age := OLD.age;
  END IF;

  IF NEW.age < 0 THEN
    RAISE EXCEPTION 'Pet age cannot be negative (pet id=%)', OLD.id;
  END IF;

  RETURN NEW;
END;
$$
LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_pet_bu_validate_age ON petshopschema.pet;

CREATE TRIGGER trg_pet_bu_validate_age
BEFORE UPDATE OF age ON petshopschema.pet
FOR EACH ROW
EXECUTE FUNCTION petshopschema.trg_pet_bu_validate_age();
```

-- логирование удаления записи о корме (OLD)
```
create table if not exists petshopschema.audit_food_delete (
  id bigserial primary key,
  deleted_at timestamptz default now(),
  food_id int,
  brand_name text,
  food_type text
);

create or replace function petshopschema.trg_food_ad_log_delete()
returns trigger
language plpgsql
as $$
begin
  insert into petshopschema.audit_food_delete(food_id, brand_name, food_type)
  values (old.id, old.brand_name, old.food_type);
  return old;
end;
$$;

drop trigger if exists trg_food_ad_log_delete on petshopschema.food;

create trigger trg_food_ad_log_delete
after delete on petshopschema.food
for each row
execute function petshopschema.trg_food_ad_log_delete();
```

--после delete pet очистка клетки + лог delete (OLD)
```
CREATE OR REPLACE FUNCTION petshopschema.trg_pet_ad_cleanup_cage_and_audit()
RETURNS trigger
AS $$
BEGIN
  UPDATE petshopschema.cage
     SET current_pet_id = NULL
   WHERE current_pet_id = OLD.id;

  INSERT INTO petshopschema.audit_pet_row(action, pet_id, old_row)
  VALUES ('DELETE', OLD.id, to_jsonb(OLD));

  RETURN OLD;
END;
$$
LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_pet_ad_cleanup_cage_and_audit ON petshopschema.pet;

CREATE TRIGGER trg_pet_ad_cleanup_cage_and_audit
AFTER DELETE ON petshopschema.pet
FOR EACH ROW
EXECUTE FUNCTION petshopschema.trg_pet_ad_cleanup_cage_and_audit();
```

-- запрещает пустую фамилию клиента при обновлении (BEFORE)
```
create or replace function petshopschema.trg_client_bu_validate_surname()
returns trigger
language plpgsql
as $$
begin
  if new.surname is null or new.surname = '' then
    raise exception 'surname must not be empty';
  end if;
  return new;
end;
$$;

drop trigger if exists trg_client_bu_validate_surname on petshopschema.client;

create trigger trg_client_bu_validate_surname
before update on petshopschema.client
for each row
execute function petshopschema.trg_client_bu_validate_surname();
```

--запрет дубля pet_id, medication_id в pet_medication (BEFORE)
```
CREATE OR REPLACE FUNCTION petshopschema.trg_pet_medication_bi_prevent_duplicate()
RETURNS trigger
AS $$
BEGIN
  IF EXISTS (
    SELECT 1
      FROM petshopschema.pet_medication pm
     WHERE pm.pet_id = NEW.pet_id
       AND pm.medication_id = NEW.medication_id
  ) THEN
    RAISE EXCEPTION 'Duplicate medication for pet (pet_id=%, medication_id=%)',
      NEW.pet_id, NEW.medication_id;
  END IF;

  RETURN NEW;
END;
$$
LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_pet_medication_bi_prevent_duplicate ON petshopschema.pet_medication;

CREATE TRIGGER trg_pet_medication_bi_prevent_duplicate
BEFORE INSERT ON petshopschema.pet_medication
FOR EACH ROW
EXECUTE FUNCTION petshopschema.trg_pet_medication_bi_prevent_duplicate();
```

-- логирование вставки аксессуара (AFTER)
```
create table if not exists petshopschema.audit_accessorie_insert (
  id bigserial primary key,
  inserted_at timestamptz default now(),
  accessorie_id int,
  name text
);

create or replace function petshopschema.trg_accessorie_ai_log_insert()
returns trigger
language plpgsql
as $$
begin
  insert into petshopschema.audit_accessorie_insert(accessorie_id, name)
  values (new.id, new.name);
  return new;
end;
$$;

drop trigger if exists trg_accessorie_ai_log_insert on petshopschema.accessorie;

create trigger trg_accessorie_ai_log_insert
after insert on petshopschema.accessorie
for each row
execute function petshopschema.trg_accessorie_ai_log_insert();
```

--после delete pet очистка клетки + лог delete (AFTER)
```
CREATE OR REPLACE FUNCTION petshopschema.trg_pet_ad_cleanup_cage_and_audit()
RETURNS trigger
AS $$
BEGIN
  UPDATE petshopschema.cage
     SET current_pet_id = NULL
   WHERE current_pet_id = OLD.id;

  INSERT INTO petshopschema.audit_pet_row(action, pet_id, old_row)
  VALUES ('DELETE', OLD.id, to_jsonb(OLD));

  RETURN OLD;
END;
$$
LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_pet_ad_cleanup_cage_and_audit ON petshopschema.pet;

CREATE TRIGGER trg_pet_ad_cleanup_cage_and_audit
AFTER DELETE ON petshopschema.pet
FOR EACH ROW
EXECUTE FUNCTION petshopschema.trg_pet_ad_cleanup_cage_and_audit();
```

-- теперь вес породы минимум 0.1 (ROW LEVEL)
```
create or replace function petshopschema.trg_breed_bu_min_weight()
returns trigger
language plpgsql
as $$
begin
  if new.average_weight < 0.1 then
    new.average_weight := 0.1;
  end if;
  return new;
end;
$$;

drop trigger if exists trg_breed_bu_min_weight on petshopschema.breed;

create trigger trg_breed_bu_min_weight
before update on petshopschema.breed
for each row
execute function petshopschema.trg_breed_bu_min_weight();
```

--лог попытки смены passport_data (ROW LEVEL)
```
CREATE OR REPLACE FUNCTION petshopschema.trg_client_bu_passport_change_log()
RETURNS trigger
AS $$
BEGIN
  IF NEW.passport_data IS DISTINCT FROM OLD.passport_data THEN
    INSERT INTO petshopschema.audit_client_passport(client_id, old_passport, new_passport)
    VALUES (OLD.id, OLD.passport_data, NEW.passport_data);
  END IF;

  RETURN NEW;
END;
$$
LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_client_bu_passport_change_log ON petshopschema.client;

CREATE TRIGGER trg_client_bu_passport_change_log
BEFORE UPDATE OF passport_data ON petshopschema.client
FOR EACH ROW
EXECUTE FUNCTION petshopschema.trg_client_bu_passport_change_log();
```

--лог “сколько строк вставили в pet” (STATEMENT LEVEL)
```
CREATE OR REPLACE FUNCTION petshopschema.trg_pet_ai_stmt_log()
RETURNS trigger
AS $$
DECLARE
  v_cnt int;
BEGIN
  SELECT COUNT(*) INTO v_cnt FROM new_pets;

  INSERT INTO petshopschema.audit_pet_stmt(action, affected_count)
  VALUES ('STMT_INSERT', v_cnt);

  RETURN NULL;
END;
$$
LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_pet_ai_stmt_log ON petshopschema.pet;

CREATE TRIGGER trg_pet_ai_stmt_log
AFTER INSERT ON petshopschema.pet
REFERENCING NEW TABLE AS new_pets
FOR EACH STATEMENT
EXECUTE FUNCTION petshopschema.trg_pet_ai_stmt_log();
```

-- логирование DELETE из таблицы pet (STATEMENT LEVEL)
```
create or replace function petshopschema.trg_pet_ad_stmt_log()
returns trigger
language plpgsql
as $$
declare
  remaining int;
begin
  select count(*) into remaining from petshopschema.pet;
  insert into petshopschema.audit_pet_stmt(action, affected_count)
  values ('delete pets', remaining);
  return null;
end;
$$;

drop trigger if exists trg_pet_ad_stmt_log on petshopschema.pet;

create trigger trg_pet_ad_stmt_log
after delete on petshopschema.pet
for each statement
execute function petshopschema.trg_pet_ad_stmt_log();
```

Отображение всех триггеров:
```
select
    n.nspname as schema_name,
    c.relname as table_name,
    t.tgname as trigger_name,
    pg_get_triggerdef(t.oid, true) as trigger_definition,
    t.tgenabled
from pg_trigger t
join pg_class c on c.oid = t.tgrelid
join pg_namespace n on n.oid = c.relnamespace
where not t.tgisinternal
  and n.nspname = 'petshopschema'
order by table_name, trigger_name;
```
<img width="1523" height="237" alt="image" src="https://github.com/user-attachments/assets/d197310b-a1e7-406a-9087-73efe7811da8" />


```
select
  n.nspname  AS schema_name,
  c.relname  AS table_name,
  t.tgname   AS trigger_name,
  pg_get_triggerdef(t.oid, true) AS trigger_def,
  t.tgenabled
from pg_trigger t
join pg_class c      ON c.oid = t.tgrelid
join pg_namespace n  ON n.oid = c.relnamespace
where not t.tgisinternal
  AND n.nspname = 'petshopschema'
order by 1,2,3;
```
<img width="1958" height="542" alt="image" src="https://github.com/user-attachments/assets/9280ad95-f95e-40be-9a70-fde73c989e0b" />

кроны???
