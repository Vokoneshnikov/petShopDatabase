--
-- PostgreSQL database dump
--

\restrict MmIregr7M2HKgEbw51DXLePKXv7QxhUn5NsIWtnKdQJNcWMDLpC1ZubPNn1EFzV

-- Dumped from database version 17.6
-- Dumped by pg_dump version 17.6

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET transaction_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

--
-- Name: petshopschema; Type: SCHEMA; Schema: -; Owner: postgres
--

CREATE SCHEMA petshopschema;


ALTER SCHEMA petshopschema OWNER TO postgres;

--
-- Name: profession_enum; Type: TYPE; Schema: petshopschema; Owner: postgres
--

CREATE TYPE petshopschema.profession_enum AS ENUM (
    'Кипер',
    'Уборщик'
);


ALTER TYPE petshopschema.profession_enum OWNER TO postgres;

--
-- Name: add_pet_to_petshop(character varying, integer, integer, integer, integer, integer); Type: PROCEDURE; Schema: petshopschema; Owner: postgres
--

CREATE PROCEDURE petshopschema.add_pet_to_petshop(IN p_name character varying, IN p_age integer, IN p_owner_id integer, IN p_breed_id integer, IN p_food_id integer, IN p_petshop_id integer)
    LANGUAGE plpgsql
    AS $$
DECLARE
    v_capacity int;
    v_current int;
BEGIN
    SELECT pets_capacity
    INTO v_capacity
    FROM petshopschema.petshop
    WHERE id = p_petshop_id;

    IF v_capacity IS NULL THEN
        RAISE EXCEPTION 'Petshop % not found', p_petshop_id;
    END IF;

    SELECT COUNT(*)
    INTO v_current
    FROM petshopschema.pet
    WHERE petshop_id = p_petshop_id;

    IF v_current >= v_capacity THEN
        RAISE EXCEPTION
            'Petshop % is full: % / % pets',
            p_petshop_id, v_current, v_capacity;
    END IF;

    INSERT INTO petshopschema.pet(name, age, owner_id, breed_id, food_id, petshop_id)
    VALUES (p_name, p_age, p_owner_id, p_breed_id, p_food_id, p_petshop_id);
END;
$$;


ALTER PROCEDURE petshopschema.add_pet_to_petshop(IN p_name character varying, IN p_age integer, IN p_owner_id integer, IN p_breed_id integer, IN p_food_id integer, IN p_petshop_id integer) OWNER TO postgres;

--
-- Name: assign_pet_to_cage(integer, integer); Type: PROCEDURE; Schema: petshopschema; Owner: postgres
--

CREATE PROCEDURE petshopschema.assign_pet_to_cage(IN p_pet_id integer, IN p_cage_id integer)
    LANGUAGE plpgsql
    AS $$
DECLARE
    v_pet_type_id int;
    v_cage_type_id int;
    v_current_pet int;
BEGIN
    SELECT b.animal_type_id
    INTO v_pet_type_id
    FROM petshopschema.pet p
    JOIN petshopschema.breed b ON p.breed_id = b.id
    WHERE p.id = p_pet_id;

    SELECT animal_type_id, current_pet_id
    INTO v_cage_type_id, v_current_pet
    FROM petshopschema.cage
    WHERE id = p_cage_id;

    CASE
        WHEN v_pet_type_id IS NULL THEN
            RAISE EXCEPTION 'Pet % has no breed/type', p_pet_id;

        WHEN v_cage_type_id IS NULL THEN
            RAISE EXCEPTION 'Cage % has no animal type', p_cage_id;

        WHEN v_cage_type_id <> v_pet_type_id THEN
            RAISE EXCEPTION
              'Cage % type (%) does not match pet % type (%)',
              p_cage_id, v_cage_type_id, p_pet_id, v_pet_type_id;

        WHEN v_current_pet IS NOT NULL THEN
            RAISE EXCEPTION
              'Cage % is already occupied by pet %',
              p_cage_id, v_current_pet;

        ELSE
            UPDATE petshopschema.cage
            SET current_pet_id = p_pet_id
            WHERE id = p_cage_id;

            RAISE NOTICE 'Pet % assigned to cage %', p_pet_id, p_cage_id;
    END CASE;
END;
$$;


ALTER PROCEDURE petshopschema.assign_pet_to_cage(IN p_pet_id integer, IN p_cage_id integer) OWNER TO postgres;

--
-- Name: fn_count_pets_by_type(text); Type: FUNCTION; Schema: petshopschema; Owner: postgres
--

CREATE FUNCTION petshopschema.fn_count_pets_by_type(p_type_name text) RETURNS integer
    LANGUAGE plpgsql
    AS $$
DECLARE
    v_type_id int;
    v_cnt int;
BEGIN
    SELECT id
    INTO v_type_id
    FROM petshopschema.animal_type
    WHERE name = p_type_name;

    IF v_type_id IS NULL THEN
        RAISE EXCEPTION 'Animal type % not found', p_type_name;
    END IF;

    SELECT COUNT(*)
    INTO v_cnt
    FROM petshopschema.pet p
    JOIN petshopschema.breed b ON p.breed_id = b.id
    WHERE b.animal_type_id = v_type_id;

    RETURN v_cnt;
END;
$$;


ALTER FUNCTION petshopschema.fn_count_pets_by_type(p_type_name text) OWNER TO postgres;

--
-- Name: fn_get_pet_age(integer); Type: FUNCTION; Schema: petshopschema; Owner: postgres
--

CREATE FUNCTION petshopschema.fn_get_pet_age(p_pet_id integer) RETURNS integer
    LANGUAGE sql
    AS $$
    SELECT age
    FROM petshopschema.pet
    WHERE id = p_pet_id;
$$;


ALTER FUNCTION petshopschema.fn_get_pet_age(p_pet_id integer) OWNER TO postgres;

--
-- Name: fn_pet_and_owner(integer); Type: FUNCTION; Schema: petshopschema; Owner: postgres
--

CREATE FUNCTION petshopschema.fn_pet_and_owner(p_pet_id integer) RETURNS text
    LANGUAGE sql
    AS $$
    SELECT p.name || ' (' || COALESCE(c.surname, 'no owner') || ')'
    FROM petshopschema.pet p
    LEFT JOIN petshopschema.client c ON c.id = p.owner_id
    WHERE p.id = p_pet_id;
$$;


ALTER FUNCTION petshopschema.fn_pet_and_owner(p_pet_id integer) OWNER TO postgres;

--
-- Name: fn_petshop_free_places(integer); Type: FUNCTION; Schema: petshopschema; Owner: postgres
--

CREATE FUNCTION petshopschema.fn_petshop_free_places(p_petshop_id integer) RETURNS integer
    LANGUAGE plpgsql
    AS $$
DECLARE
    v_capacity int;
    v_count int;
    v_free int;
BEGIN
    SELECT pets_capacity
    INTO v_capacity
    FROM petshopschema.petshop
    WHERE id = p_petshop_id;

    IF v_capacity IS NULL THEN
        RAISE EXCEPTION 'Petshop % not found', p_petshop_id;
    END IF;

    SELECT COUNT(*)
    INTO v_count
    FROM petshopschema.pet
    WHERE petshop_id = p_petshop_id;

    v_free := v_capacity - v_count;
    RETURN v_free;

EXCEPTION
    WHEN others THEN
        RAISE NOTICE 'Error in fn_petshop_free_places: %', SQLERRM;
        RETURN NULL;
END;
$$;


ALTER FUNCTION petshopschema.fn_petshop_free_places(p_petshop_id integer) OWNER TO postgres;

--
-- Name: fn_total_accessories_for_pet(integer); Type: FUNCTION; Schema: petshopschema; Owner: postgres
--

CREATE FUNCTION petshopschema.fn_total_accessories_for_pet(p_pet_id integer) RETURNS integer
    LANGUAGE plpgsql
    AS $$
DECLARE
    v_total int;
BEGIN
    SELECT count(*)
    INTO v_total
    FROM petshopschema.pet_accessorie
    WHERE pet_id = p_pet_id;

    RETURN v_total;
END;
$$;


ALTER FUNCTION petshopschema.fn_total_accessories_for_pet(p_pet_id integer) OWNER TO postgres;

--
-- Name: free_cage_on_pet_change(); Type: FUNCTION; Schema: petshopschema; Owner: postgres
--

CREATE FUNCTION petshopschema.free_cage_on_pet_change() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    -- Освобождаем клетку, если этот питомец где‑то сидел
    UPDATE petshopschema.cage
    SET current_pet_id = NULL
    WHERE current_pet_id = OLD.id;

    RETURN OLD;  -- для AFTER DELETE/UPDATE можно вернуть OLD
END;
$$;


ALTER FUNCTION petshopschema.free_cage_on_pet_change() OWNER TO postgres;

--
-- Name: get_client_pets(integer); Type: FUNCTION; Schema: petshopschema; Owner: postgres
--

CREATE FUNCTION petshopschema.get_client_pets(in_client_id integer) RETURNS TABLE(pet_id integer, pet_name character varying, pet_age integer, petshop_id integer, petshop_name character varying)
    LANGUAGE plpgsql
    AS $$
BEGIN
    RETURN QUERY
    SELECT
        p.id       AS pet_id,
        p.name     AS pet_name,
        p.age      AS pet_age,
        s.id       AS petshop_id,
        s.name     AS petshop_name
    FROM petshopschema.pet AS p
    LEFT JOIN petshopschema.petshop AS s
        ON s.id = p.petshop_id
    WHERE p.owner_id = in_client_id;
END;
$$;


ALTER FUNCTION petshopschema.get_client_pets(in_client_id integer) OWNER TO postgres;

--
-- Name: petshop_pet_count(integer); Type: FUNCTION; Schema: petshopschema; Owner: postgres
--

CREATE FUNCTION petshopschema.petshop_pet_count(p_petshop_id integer) RETURNS integer
    LANGUAGE sql
    AS $$
    SELECT COUNT(*)
    FROM petshopschema.pet
    WHERE petshop_id = p_petshop_id;
$$;


ALTER FUNCTION petshopschema.petshop_pet_count(p_petshop_id integer) OWNER TO postgres;

--
-- Name: redistribute_pets_between_cages(integer); Type: PROCEDURE; Schema: petshopschema; Owner: postgres
--

CREATE PROCEDURE petshopschema.redistribute_pets_between_cages(IN in_petshop_id integer)
    LANGUAGE plpgsql
    AS $$
DECLARE
    v_pet_id        integer;
    v_animal_type_id integer;
    v_cage_id       integer;
BEGIN
    -- Перебираем всех питомцев этого магазина,
    -- которые ещё не находятся ни в одной клетке
    FOR v_pet_id, v_animal_type_id IN
        SELECT
            p.id,
            at.id AS animal_type_id
        FROM petshopschema.pet AS p
        JOIN petshopschema.breed AS b
            ON b.id = p.breed_id
        JOIN petshopschema.animal_type AS at
            ON at.id = b.animal_type_id
        LEFT JOIN petshopschema.cage AS c_used
            ON c_used.current_pet_id = p.id
        WHERE p.petshop_id = in_petshop_id
          AND c_used.id IS NULL           -- питомец ещё не сидит в клетке
    LOOP
        -- Ищем первую свободную клетку подходящего типа в этом магазине
        SELECT c.id
        INTO v_cage_id
        FROM petshopschema.cage AS c
        WHERE c.petshop_id = in_petshop_id
          AND c.animal_type_id = v_animal_type_id
          AND c.current_pet_id IS NULL
        LIMIT 1;

        -- Если подходящей свободной клетки нет — пропускаем питомца
        IF v_cage_id IS NULL THEN
            CONTINUE;
        END IF;

        -- Сажаем питомца в найденную клетку
        UPDATE petshopschema.cage
        SET current_pet_id = v_pet_id
        WHERE id = v_cage_id;
    END LOOP;
END;
$$;


ALTER PROCEDURE petshopschema.redistribute_pets_between_cages(IN in_petshop_id integer) OWNER TO postgres;

--
-- Name: transfer_pet_to_petshop(integer, integer); Type: PROCEDURE; Schema: petshopschema; Owner: postgres
--

CREATE PROCEDURE petshopschema.transfer_pet_to_petshop(IN p_pet_id integer, IN p_new_petshop_id integer)
    LANGUAGE plpgsql
    AS $$
BEGIN
    UPDATE petshopschema.pet
    SET petshop_id = p_new_petshop_id
    WHERE id = p_pet_id;
END;
$$;


ALTER PROCEDURE petshopschema.transfer_pet_to_petshop(IN p_pet_id integer, IN p_new_petshop_id integer) OWNER TO postgres;

SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: accessorie; Type: TABLE; Schema: petshopschema; Owner: postgres
--

CREATE TABLE petshopschema.accessorie (
    id integer NOT NULL,
    name character varying(200) NOT NULL
);


ALTER TABLE petshopschema.accessorie OWNER TO postgres;

--
-- Name: accessorie_id_seq; Type: SEQUENCE; Schema: petshopschema; Owner: postgres
--

CREATE SEQUENCE petshopschema.accessorie_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE petshopschema.accessorie_id_seq OWNER TO postgres;

--
-- Name: accessorie_id_seq; Type: SEQUENCE OWNED BY; Schema: petshopschema; Owner: postgres
--

ALTER SEQUENCE petshopschema.accessorie_id_seq OWNED BY petshopschema.accessorie.id;


--
-- Name: animal_type; Type: TABLE; Schema: petshopschema; Owner: postgres
--

CREATE TABLE petshopschema.animal_type (
    id integer NOT NULL,
    name character varying(32) NOT NULL
);


ALTER TABLE petshopschema.animal_type OWNER TO postgres;

--
-- Name: animal_type_id_seq; Type: SEQUENCE; Schema: petshopschema; Owner: postgres
--

CREATE SEQUENCE petshopschema.animal_type_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE petshopschema.animal_type_id_seq OWNER TO postgres;

--
-- Name: animal_type_id_seq; Type: SEQUENCE OWNED BY; Schema: petshopschema; Owner: postgres
--

ALTER SEQUENCE petshopschema.animal_type_id_seq OWNED BY petshopschema.animal_type.id;


--
-- Name: breed; Type: TABLE; Schema: petshopschema; Owner: postgres
--

CREATE TABLE petshopschema.breed (
    id integer NOT NULL,
    breed_name character varying(64) NOT NULL,
    animal_type_id integer,
    average_weight integer
);


ALTER TABLE petshopschema.breed OWNER TO postgres;

--
-- Name: breed_id_seq; Type: SEQUENCE; Schema: petshopschema; Owner: postgres
--

CREATE SEQUENCE petshopschema.breed_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE petshopschema.breed_id_seq OWNER TO postgres;

--
-- Name: breed_id_seq; Type: SEQUENCE OWNED BY; Schema: petshopschema; Owner: postgres
--

ALTER SEQUENCE petshopschema.breed_id_seq OWNED BY petshopschema.breed.id;


--
-- Name: cage; Type: TABLE; Schema: petshopschema; Owner: postgres
--

CREATE TABLE petshopschema.cage (
    id integer NOT NULL,
    animal_type_id integer,
    current_pet_id integer,
    petshop_id integer
);


ALTER TABLE petshopschema.cage OWNER TO postgres;

--
-- Name: cage_id_seq; Type: SEQUENCE; Schema: petshopschema; Owner: postgres
--

CREATE SEQUENCE petshopschema.cage_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE petshopschema.cage_id_seq OWNER TO postgres;

--
-- Name: cage_id_seq; Type: SEQUENCE OWNED BY; Schema: petshopschema; Owner: postgres
--

ALTER SEQUENCE petshopschema.cage_id_seq OWNED BY petshopschema.cage.id;


--
-- Name: cleaning_assignments; Type: TABLE; Schema: petshopschema; Owner: postgres
--

CREATE TABLE petshopschema.cleaning_assignments (
    cleaner_id integer NOT NULL,
    cage_id integer NOT NULL,
    cleaning_date date NOT NULL,
    is_completed boolean DEFAULT false
);


ALTER TABLE petshopschema.cleaning_assignments OWNER TO postgres;

--
-- Name: client; Type: TABLE; Schema: petshopschema; Owner: postgres
--

CREATE TABLE petshopschema.client (
    id integer NOT NULL,
    name character varying(32) NOT NULL,
    surname character varying(64) NOT NULL,
    passport_data character varying(10) NOT NULL,
    petshop_id integer
);


ALTER TABLE petshopschema.client OWNER TO postgres;

--
-- Name: client_id_seq; Type: SEQUENCE; Schema: petshopschema; Owner: postgres
--

CREATE SEQUENCE petshopschema.client_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE petshopschema.client_id_seq OWNER TO postgres;

--
-- Name: client_id_seq; Type: SEQUENCE OWNED BY; Schema: petshopschema; Owner: postgres
--

ALTER SEQUENCE petshopschema.client_id_seq OWNED BY petshopschema.client.id;


--
-- Name: employee; Type: TABLE; Schema: petshopschema; Owner: postgres
--

CREATE TABLE petshopschema.employee (
    id integer NOT NULL,
    name character varying(32) NOT NULL,
    surname character varying(32) NOT NULL,
    petshop_id integer NOT NULL,
    profession petshopschema.profession_enum
);


ALTER TABLE petshopschema.employee OWNER TO postgres;

--
-- Name: employee_id_seq; Type: SEQUENCE; Schema: petshopschema; Owner: postgres
--

CREATE SEQUENCE petshopschema.employee_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE petshopschema.employee_id_seq OWNER TO postgres;

--
-- Name: employee_id_seq; Type: SEQUENCE OWNED BY; Schema: petshopschema; Owner: postgres
--

ALTER SEQUENCE petshopschema.employee_id_seq OWNED BY petshopschema.employee.id;


--
-- Name: food; Type: TABLE; Schema: petshopschema; Owner: postgres
--

CREATE TABLE petshopschema.food (
    id integer NOT NULL,
    brand_name character varying(32) NOT NULL,
    food_type character varying(32) NOT NULL
);


ALTER TABLE petshopschema.food OWNER TO postgres;

--
-- Name: food_id_seq; Type: SEQUENCE; Schema: petshopschema; Owner: postgres
--

CREATE SEQUENCE petshopschema.food_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE petshopschema.food_id_seq OWNER TO postgres;

--
-- Name: food_id_seq; Type: SEQUENCE OWNED BY; Schema: petshopschema; Owner: postgres
--

ALTER SEQUENCE petshopschema.food_id_seq OWNED BY petshopschema.food.id;


--
-- Name: keeper_assignments; Type: TABLE; Schema: petshopschema; Owner: postgres
--

CREATE TABLE petshopschema.keeper_assignments (
    keeper_id integer NOT NULL,
    pet_id integer NOT NULL,
    assignment_date date
);


ALTER TABLE petshopschema.keeper_assignments OWNER TO postgres;

--
-- Name: medication; Type: TABLE; Schema: petshopschema; Owner: postgres
--

CREATE TABLE petshopschema.medication (
    id integer NOT NULL,
    name character varying(64) NOT NULL,
    description character varying(256)
);


ALTER TABLE petshopschema.medication OWNER TO postgres;

--
-- Name: medication_id_seq; Type: SEQUENCE; Schema: petshopschema; Owner: postgres
--

CREATE SEQUENCE petshopschema.medication_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE petshopschema.medication_id_seq OWNER TO postgres;

--
-- Name: medication_id_seq; Type: SEQUENCE OWNED BY; Schema: petshopschema; Owner: postgres
--

ALTER SEQUENCE petshopschema.medication_id_seq OWNED BY petshopschema.medication.id;


--
-- Name: pet; Type: TABLE; Schema: petshopschema; Owner: postgres
--

CREATE TABLE petshopschema.pet (
    id integer NOT NULL,
    name character varying(64) NOT NULL,
    age integer,
    owner_id integer,
    breed_id integer,
    food_id integer,
    petshop_id integer,
    tags text[],
    CONSTRAINT pet_age_check CHECK (((age > 0) AND (age < 120)))
);


ALTER TABLE petshopschema.pet OWNER TO postgres;

--
-- Name: pet_accessorie; Type: TABLE; Schema: petshopschema; Owner: postgres
--

CREATE TABLE petshopschema.pet_accessorie (
    pet_id integer NOT NULL,
    accessorie_id integer NOT NULL
);


ALTER TABLE petshopschema.pet_accessorie OWNER TO postgres;

--
-- Name: pet_id_seq; Type: SEQUENCE; Schema: petshopschema; Owner: postgres
--

CREATE SEQUENCE petshopschema.pet_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE petshopschema.pet_id_seq OWNER TO postgres;

--
-- Name: pet_id_seq; Type: SEQUENCE OWNED BY; Schema: petshopschema; Owner: postgres
--

ALTER SEQUENCE petshopschema.pet_id_seq OWNED BY petshopschema.pet.id;


--
-- Name: pet_medication; Type: TABLE; Schema: petshopschema; Owner: postgres
--

CREATE TABLE petshopschema.pet_medication (
    pet_id integer NOT NULL,
    medication_id integer NOT NULL
);


ALTER TABLE petshopschema.pet_medication OWNER TO postgres;

--
-- Name: petshop; Type: TABLE; Schema: petshopschema; Owner: postgres
--

CREATE TABLE petshopschema.petshop (
    id integer NOT NULL,
    address character varying(64) NOT NULL,
    name character varying(64) DEFAULT 'ЗООМИР'::character varying NOT NULL,
    pets_capacity integer NOT NULL,
    CONSTRAINT petshop_pets_capacity_check CHECK ((pets_capacity > 0))
);


ALTER TABLE petshopschema.petshop OWNER TO postgres;

--
-- Name: petshop_id_seq; Type: SEQUENCE; Schema: petshopschema; Owner: postgres
--

CREATE SEQUENCE petshopschema.petshop_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE petshopschema.petshop_id_seq OWNER TO postgres;

--
-- Name: petshop_id_seq; Type: SEQUENCE OWNED BY; Schema: petshopschema; Owner: postgres
--

ALTER SEQUENCE petshopschema.petshop_id_seq OWNED BY petshopschema.petshop.id;


--
-- Name: accessorie id; Type: DEFAULT; Schema: petshopschema; Owner: postgres
--

ALTER TABLE ONLY petshopschema.accessorie ALTER COLUMN id SET DEFAULT nextval('petshopschema.accessorie_id_seq'::regclass);


--
-- Name: animal_type id; Type: DEFAULT; Schema: petshopschema; Owner: postgres
--

ALTER TABLE ONLY petshopschema.animal_type ALTER COLUMN id SET DEFAULT nextval('petshopschema.animal_type_id_seq'::regclass);


--
-- Name: breed id; Type: DEFAULT; Schema: petshopschema; Owner: postgres
--

ALTER TABLE ONLY petshopschema.breed ALTER COLUMN id SET DEFAULT nextval('petshopschema.breed_id_seq'::regclass);


--
-- Name: cage id; Type: DEFAULT; Schema: petshopschema; Owner: postgres
--

ALTER TABLE ONLY petshopschema.cage ALTER COLUMN id SET DEFAULT nextval('petshopschema.cage_id_seq'::regclass);


--
-- Name: client id; Type: DEFAULT; Schema: petshopschema; Owner: postgres
--

ALTER TABLE ONLY petshopschema.client ALTER COLUMN id SET DEFAULT nextval('petshopschema.client_id_seq'::regclass);


--
-- Name: employee id; Type: DEFAULT; Schema: petshopschema; Owner: postgres
--

ALTER TABLE ONLY petshopschema.employee ALTER COLUMN id SET DEFAULT nextval('petshopschema.employee_id_seq'::regclass);


--
-- Name: food id; Type: DEFAULT; Schema: petshopschema; Owner: postgres
--

ALTER TABLE ONLY petshopschema.food ALTER COLUMN id SET DEFAULT nextval('petshopschema.food_id_seq'::regclass);


--
-- Name: medication id; Type: DEFAULT; Schema: petshopschema; Owner: postgres
--

ALTER TABLE ONLY petshopschema.medication ALTER COLUMN id SET DEFAULT nextval('petshopschema.medication_id_seq'::regclass);


--
-- Name: pet id; Type: DEFAULT; Schema: petshopschema; Owner: postgres
--

ALTER TABLE ONLY petshopschema.pet ALTER COLUMN id SET DEFAULT nextval('petshopschema.pet_id_seq'::regclass);


--
-- Name: petshop id; Type: DEFAULT; Schema: petshopschema; Owner: postgres
--

ALTER TABLE ONLY petshopschema.petshop ALTER COLUMN id SET DEFAULT nextval('petshopschema.petshop_id_seq'::regclass);


--
-- Name: accessorie accessorie_pkey; Type: CONSTRAINT; Schema: petshopschema; Owner: postgres
--

ALTER TABLE ONLY petshopschema.accessorie
    ADD CONSTRAINT accessorie_pkey PRIMARY KEY (id);


--
-- Name: animal_type animal_type_name_key; Type: CONSTRAINT; Schema: petshopschema; Owner: postgres
--

ALTER TABLE ONLY petshopschema.animal_type
    ADD CONSTRAINT animal_type_name_key UNIQUE (name);


--
-- Name: animal_type animal_type_pkey; Type: CONSTRAINT; Schema: petshopschema; Owner: postgres
--

ALTER TABLE ONLY petshopschema.animal_type
    ADD CONSTRAINT animal_type_pkey PRIMARY KEY (id);


--
-- Name: food brand_food_type_unique; Type: CONSTRAINT; Schema: petshopschema; Owner: postgres
--

ALTER TABLE ONLY petshopschema.food
    ADD CONSTRAINT brand_food_type_unique UNIQUE (brand_name, food_type);


--
-- Name: breed breed_name_unique; Type: CONSTRAINT; Schema: petshopschema; Owner: postgres
--

ALTER TABLE ONLY petshopschema.breed
    ADD CONSTRAINT breed_name_unique UNIQUE (breed_name);


--
-- Name: breed breed_pkey; Type: CONSTRAINT; Schema: petshopschema; Owner: postgres
--

ALTER TABLE ONLY petshopschema.breed
    ADD CONSTRAINT breed_pkey PRIMARY KEY (id);


--
-- Name: cage cage_pkey; Type: CONSTRAINT; Schema: petshopschema; Owner: postgres
--

ALTER TABLE ONLY petshopschema.cage
    ADD CONSTRAINT cage_pkey PRIMARY KEY (id);


--
-- Name: cleaning_assignments cleaning_assignments_pkey; Type: CONSTRAINT; Schema: petshopschema; Owner: postgres
--

ALTER TABLE ONLY petshopschema.cleaning_assignments
    ADD CONSTRAINT cleaning_assignments_pkey PRIMARY KEY (cleaner_id, cage_id, cleaning_date);


--
-- Name: client client_passport_data_key; Type: CONSTRAINT; Schema: petshopschema; Owner: postgres
--

ALTER TABLE ONLY petshopschema.client
    ADD CONSTRAINT client_passport_data_key UNIQUE (passport_data);


--
-- Name: client client_pkey; Type: CONSTRAINT; Schema: petshopschema; Owner: postgres
--

ALTER TABLE ONLY petshopschema.client
    ADD CONSTRAINT client_pkey PRIMARY KEY (id);


--
-- Name: cage current_pet_unique; Type: CONSTRAINT; Schema: petshopschema; Owner: postgres
--

ALTER TABLE ONLY petshopschema.cage
    ADD CONSTRAINT current_pet_unique UNIQUE (current_pet_id);


--
-- Name: employee employee_pkey; Type: CONSTRAINT; Schema: petshopschema; Owner: postgres
--

ALTER TABLE ONLY petshopschema.employee
    ADD CONSTRAINT employee_pkey PRIMARY KEY (id);


--
-- Name: food food_pkey; Type: CONSTRAINT; Schema: petshopschema; Owner: postgres
--

ALTER TABLE ONLY petshopschema.food
    ADD CONSTRAINT food_pkey PRIMARY KEY (id);


--
-- Name: keeper_assignments keeper_assignments_pkey; Type: CONSTRAINT; Schema: petshopschema; Owner: postgres
--

ALTER TABLE ONLY petshopschema.keeper_assignments
    ADD CONSTRAINT keeper_assignments_pkey PRIMARY KEY (keeper_id, pet_id);


--
-- Name: medication medication_pkey; Type: CONSTRAINT; Schema: petshopschema; Owner: postgres
--

ALTER TABLE ONLY petshopschema.medication
    ADD CONSTRAINT medication_pkey PRIMARY KEY (id);


--
-- Name: pet owner_pet_name_unique; Type: CONSTRAINT; Schema: petshopschema; Owner: postgres
--

ALTER TABLE ONLY petshopschema.pet
    ADD CONSTRAINT owner_pet_name_unique UNIQUE (owner_id, name);


--
-- Name: pet_accessorie pet_accessorie_pkey; Type: CONSTRAINT; Schema: petshopschema; Owner: postgres
--

ALTER TABLE ONLY petshopschema.pet_accessorie
    ADD CONSTRAINT pet_accessorie_pkey PRIMARY KEY (pet_id, accessorie_id);


--
-- Name: pet_medication pet_medication_pkey; Type: CONSTRAINT; Schema: petshopschema; Owner: postgres
--

ALTER TABLE ONLY petshopschema.pet_medication
    ADD CONSTRAINT pet_medication_pkey PRIMARY KEY (pet_id, medication_id);


--
-- Name: pet pet_pkey; Type: CONSTRAINT; Schema: petshopschema; Owner: postgres
--

ALTER TABLE ONLY petshopschema.pet
    ADD CONSTRAINT pet_pkey PRIMARY KEY (id);


--
-- Name: petshop petshop_pkey; Type: CONSTRAINT; Schema: petshopschema; Owner: postgres
--

ALTER TABLE ONLY petshopschema.petshop
    ADD CONSTRAINT petshop_pkey PRIMARY KEY (id);


--
-- Name: idx_food_id_sorted; Type: INDEX; Schema: petshopschema; Owner: postgres
--

CREATE INDEX idx_food_id_sorted ON petshopschema.food USING btree (id);


--
-- Name: idx_pet_food_id_sorted; Type: INDEX; Schema: petshopschema; Owner: postgres
--

CREATE INDEX idx_pet_food_id_sorted ON petshopschema.pet USING btree (food_id, id);


--
-- Name: idx_pet_tags_gin; Type: INDEX; Schema: petshopschema; Owner: postgres
--

CREATE INDEX idx_pet_tags_gin ON petshopschema.pet USING gin (tags);


--
-- Name: index_for_client_name; Type: INDEX; Schema: petshopschema; Owner: postgres
--

CREATE INDEX index_for_client_name ON petshopschema.client USING gist (to_tsvector('russian'::regconfig, (passport_data)::text));


--
-- Name: index_for_client_petshop_id; Type: INDEX; Schema: petshopschema; Owner: postgres
--

CREATE INDEX index_for_client_petshop_id ON petshopschema.client USING btree (petshop_id);


--
-- Name: index_for_client_surname; Type: INDEX; Schema: petshopschema; Owner: postgres
--

CREATE INDEX index_for_client_surname ON petshopschema.client USING btree (surname);


--
-- Name: index_for_pets; Type: INDEX; Schema: petshopschema; Owner: postgres
--

CREATE INDEX index_for_pets ON petshopschema.pet USING gin (to_tsvector('russian'::regconfig, (name)::text));


--
-- Name: index_for_pets_age; Type: INDEX; Schema: petshopschema; Owner: postgres
--

CREATE INDEX index_for_pets_age ON petshopschema.pet USING btree (age);


--
-- Name: pet trg_free_cage_on_pet_delete; Type: TRIGGER; Schema: petshopschema; Owner: postgres
--

CREATE TRIGGER trg_free_cage_on_pet_delete AFTER DELETE ON petshopschema.pet FOR EACH ROW EXECUTE FUNCTION petshopschema.free_cage_on_pet_change();


--
-- Name: pet trg_free_cage_on_pet_update; Type: TRIGGER; Schema: petshopschema; Owner: postgres
--

CREATE TRIGGER trg_free_cage_on_pet_update AFTER UPDATE OF petshop_id ON petshopschema.pet FOR EACH ROW WHEN ((old.petshop_id IS DISTINCT FROM new.petshop_id)) EXECUTE FUNCTION petshopschema.free_cage_on_pet_change();


--
-- Name: breed breed_animal_type_id_fkey; Type: FK CONSTRAINT; Schema: petshopschema; Owner: postgres
--

ALTER TABLE ONLY petshopschema.breed
    ADD CONSTRAINT breed_animal_type_id_fkey FOREIGN KEY (animal_type_id) REFERENCES petshopschema.animal_type(id);


--
-- Name: cage cage_animal_type_id_fkey; Type: FK CONSTRAINT; Schema: petshopschema; Owner: postgres
--

ALTER TABLE ONLY petshopschema.cage
    ADD CONSTRAINT cage_animal_type_id_fkey FOREIGN KEY (animal_type_id) REFERENCES petshopschema.animal_type(id);


--
-- Name: cage cage_current_pet_id_fkey; Type: FK CONSTRAINT; Schema: petshopschema; Owner: postgres
--

ALTER TABLE ONLY petshopschema.cage
    ADD CONSTRAINT cage_current_pet_id_fkey FOREIGN KEY (current_pet_id) REFERENCES petshopschema.pet(id);


--
-- Name: cage cage_petshop_id_fkey; Type: FK CONSTRAINT; Schema: petshopschema; Owner: postgres
--

ALTER TABLE ONLY petshopschema.cage
    ADD CONSTRAINT cage_petshop_id_fkey FOREIGN KEY (petshop_id) REFERENCES petshopschema.petshop(id);


--
-- Name: cleaning_assignments cleaning_assignments_cage_id_fkey; Type: FK CONSTRAINT; Schema: petshopschema; Owner: postgres
--

ALTER TABLE ONLY petshopschema.cleaning_assignments
    ADD CONSTRAINT cleaning_assignments_cage_id_fkey FOREIGN KEY (cage_id) REFERENCES petshopschema.cage(id);


--
-- Name: cleaning_assignments cleaning_assignments_cleaner_id_fkey; Type: FK CONSTRAINT; Schema: petshopschema; Owner: postgres
--

ALTER TABLE ONLY petshopschema.cleaning_assignments
    ADD CONSTRAINT cleaning_assignments_cleaner_id_fkey FOREIGN KEY (cleaner_id) REFERENCES petshopschema.employee(id);


--
-- Name: client client_petshop_id_fkey; Type: FK CONSTRAINT; Schema: petshopschema; Owner: postgres
--

ALTER TABLE ONLY petshopschema.client
    ADD CONSTRAINT client_petshop_id_fkey FOREIGN KEY (petshop_id) REFERENCES petshopschema.petshop(id);


--
-- Name: employee employee_petshop_id_fkey; Type: FK CONSTRAINT; Schema: petshopschema; Owner: postgres
--

ALTER TABLE ONLY petshopschema.employee
    ADD CONSTRAINT employee_petshop_id_fkey FOREIGN KEY (petshop_id) REFERENCES petshopschema.petshop(id);


--
-- Name: keeper_assignments keeper_assignments_keeper_id_fkey; Type: FK CONSTRAINT; Schema: petshopschema; Owner: postgres
--

ALTER TABLE ONLY petshopschema.keeper_assignments
    ADD CONSTRAINT keeper_assignments_keeper_id_fkey FOREIGN KEY (keeper_id) REFERENCES petshopschema.employee(id);


--
-- Name: keeper_assignments keeper_assignments_pet_id_fkey; Type: FK CONSTRAINT; Schema: petshopschema; Owner: postgres
--

ALTER TABLE ONLY petshopschema.keeper_assignments
    ADD CONSTRAINT keeper_assignments_pet_id_fkey FOREIGN KEY (pet_id) REFERENCES petshopschema.pet(id);


--
-- Name: pet_accessorie pet_accessorie_accessorie_id_fkey; Type: FK CONSTRAINT; Schema: petshopschema; Owner: postgres
--

ALTER TABLE ONLY petshopschema.pet_accessorie
    ADD CONSTRAINT pet_accessorie_accessorie_id_fkey FOREIGN KEY (accessorie_id) REFERENCES petshopschema.accessorie(id);


--
-- Name: pet_accessorie pet_accessorie_pet_id_fkey; Type: FK CONSTRAINT; Schema: petshopschema; Owner: postgres
--

ALTER TABLE ONLY petshopschema.pet_accessorie
    ADD CONSTRAINT pet_accessorie_pet_id_fkey FOREIGN KEY (pet_id) REFERENCES petshopschema.pet(id);


--
-- Name: pet pet_breed_id_fkey; Type: FK CONSTRAINT; Schema: petshopschema; Owner: postgres
--

ALTER TABLE ONLY petshopschema.pet
    ADD CONSTRAINT pet_breed_id_fkey FOREIGN KEY (breed_id) REFERENCES petshopschema.breed(id);


--
-- Name: pet pet_food_id_fkey; Type: FK CONSTRAINT; Schema: petshopschema; Owner: postgres
--

ALTER TABLE ONLY petshopschema.pet
    ADD CONSTRAINT pet_food_id_fkey FOREIGN KEY (food_id) REFERENCES petshopschema.food(id);


--
-- Name: pet_medication pet_medication_medication_id_fkey; Type: FK CONSTRAINT; Schema: petshopschema; Owner: postgres
--

ALTER TABLE ONLY petshopschema.pet_medication
    ADD CONSTRAINT pet_medication_medication_id_fkey FOREIGN KEY (medication_id) REFERENCES petshopschema.medication(id);


--
-- Name: pet_medication pet_medication_pet_id_fkey; Type: FK CONSTRAINT; Schema: petshopschema; Owner: postgres
--

ALTER TABLE ONLY petshopschema.pet_medication
    ADD CONSTRAINT pet_medication_pet_id_fkey FOREIGN KEY (pet_id) REFERENCES petshopschema.pet(id);


--
-- Name: pet pet_owner_id_fkey; Type: FK CONSTRAINT; Schema: petshopschema; Owner: postgres
--

ALTER TABLE ONLY petshopschema.pet
    ADD CONSTRAINT pet_owner_id_fkey FOREIGN KEY (owner_id) REFERENCES petshopschema.client(id);


--
-- Name: pet pet_petshop_id_fkey; Type: FK CONSTRAINT; Schema: petshopschema; Owner: postgres
--

ALTER TABLE ONLY petshopschema.pet
    ADD CONSTRAINT pet_petshop_id_fkey FOREIGN KEY (petshop_id) REFERENCES petshopschema.petshop(id);


--
-- Name: SCHEMA petshopschema; Type: ACL; Schema: -; Owner: postgres
--

GRANT USAGE ON SCHEMA petshopschema TO app;
GRANT USAGE ON SCHEMA petshopschema TO readonly;
GRANT USAGE ON SCHEMA petshopschema TO updater;


--
-- Name: TABLE accessorie; Type: ACL; Schema: petshopschema; Owner: postgres
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE petshopschema.accessorie TO app;
GRANT SELECT ON TABLE petshopschema.accessorie TO readonly;
GRANT SELECT,UPDATE ON TABLE petshopschema.accessorie TO updater;


--
-- Name: TABLE animal_type; Type: ACL; Schema: petshopschema; Owner: postgres
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE petshopschema.animal_type TO app;
GRANT SELECT ON TABLE petshopschema.animal_type TO readonly;
GRANT SELECT,UPDATE ON TABLE petshopschema.animal_type TO updater;


--
-- Name: TABLE breed; Type: ACL; Schema: petshopschema; Owner: postgres
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE petshopschema.breed TO app;
GRANT SELECT ON TABLE petshopschema.breed TO readonly;
GRANT SELECT,UPDATE ON TABLE petshopschema.breed TO updater;


--
-- Name: TABLE cage; Type: ACL; Schema: petshopschema; Owner: postgres
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE petshopschema.cage TO app;
GRANT SELECT ON TABLE petshopschema.cage TO readonly;
GRANT SELECT,UPDATE ON TABLE petshopschema.cage TO updater;


--
-- Name: TABLE cleaning_assignments; Type: ACL; Schema: petshopschema; Owner: postgres
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE petshopschema.cleaning_assignments TO app;
GRANT SELECT ON TABLE petshopschema.cleaning_assignments TO readonly;
GRANT SELECT,UPDATE ON TABLE petshopschema.cleaning_assignments TO updater;


--
-- Name: TABLE client; Type: ACL; Schema: petshopschema; Owner: postgres
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE petshopschema.client TO app;
GRANT SELECT ON TABLE petshopschema.client TO readonly;
GRANT SELECT,UPDATE ON TABLE petshopschema.client TO updater;


--
-- Name: TABLE employee; Type: ACL; Schema: petshopschema; Owner: postgres
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE petshopschema.employee TO app;
GRANT SELECT ON TABLE petshopschema.employee TO readonly;
GRANT SELECT,UPDATE ON TABLE petshopschema.employee TO updater;


--
-- Name: TABLE food; Type: ACL; Schema: petshopschema; Owner: postgres
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE petshopschema.food TO app;
GRANT SELECT ON TABLE petshopschema.food TO readonly;
GRANT SELECT,UPDATE ON TABLE petshopschema.food TO updater;


--
-- Name: TABLE keeper_assignments; Type: ACL; Schema: petshopschema; Owner: postgres
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE petshopschema.keeper_assignments TO app;
GRANT SELECT ON TABLE petshopschema.keeper_assignments TO readonly;
GRANT SELECT,UPDATE ON TABLE petshopschema.keeper_assignments TO updater;


--
-- Name: TABLE medication; Type: ACL; Schema: petshopschema; Owner: postgres
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE petshopschema.medication TO app;
GRANT SELECT ON TABLE petshopschema.medication TO readonly;
GRANT SELECT,UPDATE ON TABLE petshopschema.medication TO updater;


--
-- Name: TABLE pet; Type: ACL; Schema: petshopschema; Owner: postgres
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE petshopschema.pet TO app;
GRANT SELECT ON TABLE petshopschema.pet TO readonly;
GRANT SELECT,UPDATE ON TABLE petshopschema.pet TO updater;


--
-- Name: TABLE pet_accessorie; Type: ACL; Schema: petshopschema; Owner: postgres
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE petshopschema.pet_accessorie TO app;
GRANT SELECT ON TABLE petshopschema.pet_accessorie TO readonly;
GRANT SELECT,UPDATE ON TABLE petshopschema.pet_accessorie TO updater;


--
-- Name: TABLE pet_medication; Type: ACL; Schema: petshopschema; Owner: postgres
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE petshopschema.pet_medication TO app;
GRANT SELECT ON TABLE petshopschema.pet_medication TO readonly;
GRANT SELECT,UPDATE ON TABLE petshopschema.pet_medication TO updater;


--
-- Name: TABLE petshop; Type: ACL; Schema: petshopschema; Owner: postgres
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE petshopschema.petshop TO app;
GRANT SELECT ON TABLE petshopschema.petshop TO readonly;
GRANT SELECT,UPDATE ON TABLE petshopschema.petshop TO updater;


--
-- Name: DEFAULT PRIVILEGES FOR SEQUENCES; Type: DEFAULT ACL; Schema: petshopschema; Owner: postgres
--

ALTER DEFAULT PRIVILEGES FOR ROLE postgres IN SCHEMA petshopschema GRANT SELECT,USAGE ON SEQUENCES TO app;
ALTER DEFAULT PRIVILEGES FOR ROLE postgres IN SCHEMA petshopschema GRANT SELECT,USAGE ON SEQUENCES TO updater;


--
-- Name: DEFAULT PRIVILEGES FOR TABLES; Type: DEFAULT ACL; Schema: petshopschema; Owner: postgres
--

ALTER DEFAULT PRIVILEGES FOR ROLE postgres IN SCHEMA petshopschema GRANT SELECT,INSERT,DELETE,UPDATE ON TABLES TO app;
ALTER DEFAULT PRIVILEGES FOR ROLE postgres IN SCHEMA petshopschema GRANT SELECT ON TABLES TO readonly;
ALTER DEFAULT PRIVILEGES FOR ROLE postgres IN SCHEMA petshopschema GRANT SELECT,UPDATE ON TABLES TO updater;


--
-- PostgreSQL database dump complete
--

\unrestrict MmIregr7M2HKgEbw51DXLePKXv7QxhUn5NsIWtnKdQJNcWMDLpC1ZubPNn1EFzV

