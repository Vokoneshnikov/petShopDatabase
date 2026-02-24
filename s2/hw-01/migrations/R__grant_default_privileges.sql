
alter default privileges in schema petshopschema 
    grant select, insert, update, delete on tables to app;

alter default privileges in schema petshopschema 
    grant select on tables to readonly;

alter default privileges in schema petshopschema 
    grant select, update on tables to updater;

alter default privileges in schema petshopschema 
    grant usage, select on sequences to app;

alter default privileges in schema petshopschema 
    grant usage, select on sequences to updater;