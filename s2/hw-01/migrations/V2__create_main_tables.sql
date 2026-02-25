BEGIN;


CREATE TABLE IF NOT EXISTS petshopschema.accessorie
(
    id serial NOT NULL,
    name character varying(200) COLLATE pg_catalog."default" NOT NULL,
    CONSTRAINT accessorie_pkey PRIMARY KEY (id)
);

CREATE TABLE IF NOT EXISTS petshopschema.animal_type
(
    id serial NOT NULL,
    name character varying(32) COLLATE pg_catalog."default" NOT NULL,
    CONSTRAINT animal_type_pkey PRIMARY KEY (id),
    CONSTRAINT animal_type_name_key UNIQUE (name)
);

CREATE TABLE IF NOT EXISTS petshopschema.breed
(
    id serial NOT NULL,
    breed_name character varying(64) COLLATE pg_catalog."default" NOT NULL,
    animal_type_id integer,
    average_weight integer,
    CONSTRAINT breed_pkey PRIMARY KEY (id),
    CONSTRAINT breed_name_unique UNIQUE (breed_name)
);

CREATE TABLE IF NOT EXISTS petshopschema.cage
(
    id serial NOT NULL,
    animal_type_id integer,
    current_pet_id integer,
    petshop_id integer,
    CONSTRAINT cage_pkey PRIMARY KEY (id),
    CONSTRAINT current_pet_unique UNIQUE (current_pet_id)
);

CREATE TABLE IF NOT EXISTS petshopschema.cleaning_assignments
(
    cleaner_id integer NOT NULL,
    cage_id integer NOT NULL,
    cleaning_date date NOT NULL,
    is_completed boolean DEFAULT false,
    CONSTRAINT cleaning_assignments_pkey PRIMARY KEY (cleaner_id, cage_id, cleaning_date)
);

CREATE TABLE IF NOT EXISTS petshopschema.client
(
    id serial NOT NULL,
    name character varying(32) COLLATE pg_catalog."default" NOT NULL,
    surname character varying(64) COLLATE pg_catalog."default" NOT NULL,
    passport_data character varying(10) COLLATE pg_catalog."default" NOT NULL,
    petshop_id integer,
    CONSTRAINT client_pkey PRIMARY KEY (id),
    CONSTRAINT client_passport_data_key UNIQUE (passport_data)
);

CREATE TABLE IF NOT EXISTS petshopschema.employee
(
    id serial NOT NULL,
    name character varying(32) COLLATE pg_catalog."default" NOT NULL,
    surname character varying(32) COLLATE pg_catalog."default" NOT NULL,
    petshop_id integer NOT NULL,
    profession petshopschema.profession_enum,
    CONSTRAINT employee_pkey PRIMARY KEY (id)
);

CREATE TABLE IF NOT EXISTS petshopschema.food
(
    id serial NOT NULL,
    brand_name character varying(32) COLLATE pg_catalog."default" NOT NULL,
    food_type character varying(32) COLLATE pg_catalog."default" NOT NULL,
    CONSTRAINT food_pkey PRIMARY KEY (id),
    CONSTRAINT brand_food_type_unique UNIQUE (brand_name, food_type)
);

CREATE TABLE IF NOT EXISTS petshopschema.keeper_assignments
(
    keeper_id integer NOT NULL,
    pet_id integer NOT NULL,
    assignment_date date,
    CONSTRAINT keeper_assignments_pkey PRIMARY KEY (keeper_id, pet_id)
);

CREATE TABLE IF NOT EXISTS petshopschema.medication
(
    id serial NOT NULL,
    name character varying(64) COLLATE pg_catalog."default" NOT NULL,
    description character varying(256) COLLATE pg_catalog."default",
    CONSTRAINT medication_pkey PRIMARY KEY (id)
);

CREATE TABLE IF NOT EXISTS petshopschema.pet
(
    id serial NOT NULL,
    name character varying(64) COLLATE pg_catalog."default" NOT NULL,
    age integer,
    owner_id integer,
    breed_id integer,
    food_id integer,
    petshop_id integer,
    CONSTRAINT pet_pkey PRIMARY KEY (id),
    CONSTRAINT owner_pet_name_unique UNIQUE (owner_id, name)
);

CREATE TABLE IF NOT EXISTS petshopschema.pet_accessorie
(
    pet_id integer NOT NULL,
    accessorie_id integer NOT NULL,
    CONSTRAINT pet_accessorie_pkey PRIMARY KEY (pet_id, accessorie_id)
);

CREATE TABLE IF NOT EXISTS petshopschema.pet_medication
(
    pet_id integer NOT NULL,
    medication_id integer NOT NULL,
    CONSTRAINT pet_medication_pkey PRIMARY KEY (pet_id, medication_id)
);


CREATE TABLE IF NOT EXISTS petshopschema.petshop
(
    id serial NOT NULL,
    address character varying(64) COLLATE pg_catalog."default" NOT NULL,
    name character varying(64) COLLATE pg_catalog."default" NOT NULL DEFAULT 'ЗООМИР'::character varying,
    pets_capacity integer NOT NULL,
    CONSTRAINT petshop_pkey PRIMARY KEY (id)
);

ALTER TABLE IF EXISTS petshopschema.breed
    ADD CONSTRAINT breed_animal_type_id_fkey FOREIGN KEY (animal_type_id)
    REFERENCES petshopschema.animal_type (id) MATCH SIMPLE
    ON UPDATE NO ACTION
    ON DELETE NO ACTION;


ALTER TABLE IF EXISTS petshopschema.cage
    ADD CONSTRAINT cage_animal_type_id_fkey FOREIGN KEY (animal_type_id)
    REFERENCES petshopschema.animal_type (id) MATCH SIMPLE
    ON UPDATE NO ACTION
    ON DELETE NO ACTION;


ALTER TABLE IF EXISTS petshopschema.cage
    ADD CONSTRAINT cage_current_pet_id_fkey FOREIGN KEY (current_pet_id)
    REFERENCES petshopschema.pet (id) MATCH SIMPLE
    ON UPDATE NO ACTION
    ON DELETE NO ACTION;
CREATE INDEX IF NOT EXISTS current_pet_unique
    ON petshopschema.cage(current_pet_id);


ALTER TABLE IF EXISTS petshopschema.cage
    ADD CONSTRAINT cage_petshop_id_fkey FOREIGN KEY (petshop_id)
    REFERENCES petshopschema.petshop (id) MATCH SIMPLE
    ON UPDATE NO ACTION
    ON DELETE NO ACTION;


ALTER TABLE IF EXISTS petshopschema.cleaning_assignments
    ADD CONSTRAINT cleaning_assignments_cage_id_fkey FOREIGN KEY (cage_id)
    REFERENCES petshopschema.cage (id) MATCH SIMPLE
    ON UPDATE NO ACTION
    ON DELETE NO ACTION;


ALTER TABLE IF EXISTS petshopschema.cleaning_assignments
    ADD CONSTRAINT cleaning_assignments_cleaner_id_fkey FOREIGN KEY (cleaner_id)
    REFERENCES petshopschema.employee (id) MATCH SIMPLE
    ON UPDATE NO ACTION
    ON DELETE NO ACTION;


ALTER TABLE IF EXISTS petshopschema.client
    ADD CONSTRAINT client_petshop_id_fkey FOREIGN KEY (petshop_id)
    REFERENCES petshopschema.petshop (id) MATCH SIMPLE
    ON UPDATE NO ACTION
    ON DELETE NO ACTION;


ALTER TABLE IF EXISTS petshopschema.employee
    ADD CONSTRAINT employee_petshop_id_fkey FOREIGN KEY (petshop_id)
    REFERENCES petshopschema.petshop (id) MATCH SIMPLE
    ON UPDATE NO ACTION
    ON DELETE NO ACTION;


ALTER TABLE IF EXISTS petshopschema.keeper_assignments
    ADD CONSTRAINT keeper_assignments_keeper_id_fkey FOREIGN KEY (keeper_id)
    REFERENCES petshopschema.employee (id) MATCH SIMPLE
    ON UPDATE NO ACTION
    ON DELETE NO ACTION;


ALTER TABLE IF EXISTS petshopschema.keeper_assignments
    ADD CONSTRAINT keeper_assignments_pet_id_fkey FOREIGN KEY (pet_id)
    REFERENCES petshopschema.pet (id) MATCH SIMPLE
    ON UPDATE NO ACTION
    ON DELETE NO ACTION;


ALTER TABLE IF EXISTS petshopschema.pet
    ADD CONSTRAINT pet_breed_id_fkey FOREIGN KEY (breed_id)
    REFERENCES petshopschema.breed (id) MATCH SIMPLE
    ON UPDATE NO ACTION
    ON DELETE NO ACTION;


ALTER TABLE IF EXISTS petshopschema.pet
    ADD CONSTRAINT pet_food_id_fkey FOREIGN KEY (food_id)
    REFERENCES petshopschema.food (id) MATCH SIMPLE
    ON UPDATE NO ACTION
    ON DELETE NO ACTION;


ALTER TABLE IF EXISTS petshopschema.pet
    ADD CONSTRAINT pet_owner_id_fkey FOREIGN KEY (owner_id)
    REFERENCES petshopschema.client (id) MATCH SIMPLE
    ON UPDATE NO ACTION
    ON DELETE NO ACTION;


ALTER TABLE IF EXISTS petshopschema.pet
    ADD CONSTRAINT pet_petshop_id_fkey FOREIGN KEY (petshop_id)
    REFERENCES petshopschema.petshop (id) MATCH SIMPLE
    ON UPDATE NO ACTION
    ON DELETE NO ACTION;


ALTER TABLE IF EXISTS petshopschema.pet_accessorie
    ADD CONSTRAINT pet_accessorie_accessorie_id_fkey FOREIGN KEY (accessorie_id)
    REFERENCES petshopschema.accessorie (id) MATCH SIMPLE
    ON UPDATE NO ACTION
    ON DELETE NO ACTION;


ALTER TABLE IF EXISTS petshopschema.pet_accessorie
    ADD CONSTRAINT pet_accessorie_pet_id_fkey FOREIGN KEY (pet_id)
    REFERENCES petshopschema.pet (id) MATCH SIMPLE
    ON UPDATE NO ACTION
    ON DELETE NO ACTION;


ALTER TABLE IF EXISTS petshopschema.pet_medication
    ADD CONSTRAINT pet_medication_medication_id_fkey FOREIGN KEY (medication_id)
    REFERENCES petshopschema.medication (id) MATCH SIMPLE
    ON UPDATE NO ACTION
    ON DELETE NO ACTION;


ALTER TABLE IF EXISTS petshopschema.pet_medication
    ADD CONSTRAINT pet_medication_pet_id_fkey FOREIGN KEY (pet_id)
    REFERENCES petshopschema.pet (id) MATCH SIMPLE
    ON UPDATE NO ACTION
    ON DELETE NO ACTION;

END;