grant connect on database petshopdatabase to app, readonly, updater;
grant usage on schema petshopschema to app, readonly, updater;
grant select, update, delete, insert on all tables in schema petshopschema to app;
grant select on all tables in schema petshopschema to readonly;
grant update, select on all tables in schema petshopschema to updater;