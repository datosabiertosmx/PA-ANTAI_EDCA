--
-- PostgreSQL database dump
--

-- Dumped from database version 10.12
-- Dumped by pg_dump version 10.12

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

--
-- Name: dashboard; Type: SCHEMA; Schema: -; Owner: user_dashboard
--

CREATE SCHEMA dashboard;


ALTER SCHEMA dashboard OWNER TO user_dashboard;

--
-- Name: plpgsql; Type: EXTENSION; Schema: -; Owner: 
--

CREATE EXTENSION IF NOT EXISTS plpgsql WITH SCHEMA pg_catalog;


--
-- Name: EXTENSION plpgsql; Type: COMMENT; Schema: -; Owner: 
--

COMMENT ON EXTENSION plpgsql IS 'PL/pgSQL procedural language';


--
-- Name: clone_schema(text, text); Type: FUNCTION; Schema: public; Owner: user_captura
--

CREATE FUNCTION public.clone_schema(source_schema text, dest_schema text) RETURNS void
    LANGUAGE plpgsql
    AS $$
DECLARE
object text;
buffer text;
default_ text;
column_ text;
constraint_name_ text;
constraint_def_ text;
trigger_name_ text; 
trigger_timing_ text; 
trigger_events_ text; 
trigger_orientation_ text;
trigger_action_ text;
owner_ text := 'user_dashboard';
BEGIN
	-- replace existing schema
	EXECUTE 'DROP SCHEMA IF EXISTS ' || dest_schema || ' CASCADE';
	-- create schema
	EXECUTE 'CREATE SCHEMA ' || dest_schema || ' AUTHORIZATION ' || owner_ ;
	-- create sequences
	FOR object IN
		SELECT sequence_name::text FROM information_schema.SEQUENCES WHERE sequence_schema = source_schema
		LOOP
			EXECUTE 'CREATE SEQUENCE ' || dest_schema || '.' || object;
END LOOP;

-- create tables
FOR object IN
	SELECT table_name::text FROM information_schema.TABLES WHERE table_schema = source_schema
	LOOP
		buffer := dest_schema || '.' || object;
		-- create table
		EXECUTE 'CREATE TABLE ' || buffer || ' (LIKE ' || source_schema || '.' || object || ' INCLUDING CONSTRAINTS INCLUDING INDEXES INCLUDING DEFAULTS)';
		-- fix sequence defaults
		FOR column_, default_ IN
			SELECT column_name::text, REPLACE(column_default::text, source_schema||'.', dest_schema||'.') FROM information_schema.COLUMNS WHERE table_schema = dest_schema AND table_name = object AND column_default LIKE 'nextval(%' || source_schema || '.%::regclass)'
			LOOP
				EXECUTE 'ALTER TABLE ' || buffer || ' ALTER COLUMN ' || column_ || ' SET DEFAULT ' || default_;
      END LOOP;
  -- create triggers
  FOR trigger_name_, trigger_timing_, trigger_events_, trigger_orientation_, trigger_action_ IN
    SELECT trigger_name::text, action_timing::text, string_agg(event_manipulation::text, ' OR '), action_orientation::text, action_statement::text FROM information_schema.TRIGGERS WHERE event_object_schema=source_schema and event_object_table=object GROUP BY trigger_name, action_timing, action_orientation, action_statement
      LOOP
        EXECUTE 'CREATE TRIGGER ' || trigger_name_ || ' ' || trigger_timing_ || ' ' || trigger_events_ || ' ON ' || buffer || ' FOR EACH ' || trigger_orientation_ || ' ' || trigger_action_;
    END LOOP;
END LOOP;
-- reiterate tables and create foreign keys
FOR object IN
	SELECT table_name::text FROM information_schema.TABLES WHERE table_schema = source_schema
	LOOP
		buffer := dest_schema || '.' || object;
		-- create foreign keys
		FOR constraint_name_, constraint_def_ IN
			SELECT conname::text, 
      CASE WHEN position( source_schema||'.' in pg_get_constraintdef(pg_constraint.oid)) = 0 THEN 
		  	REPLACE(pg_get_constraintdef(pg_constraint.oid), 'REFERENCES ', 'REFERENCES '|| dest_schema ||'.') 
        ELSE
        REPLACE(pg_get_constraintdef(pg_constraint.oid), source_schema ||'.', dest_schema||'.')
  	  END
      FROM pg_constraint INNER JOIN pg_class ON conrelid=pg_class.oid INNER JOIN pg_namespace ON pg_namespace.oid=pg_class.relnamespace WHERE contype='f' and relname=object and nspname=source_schema
			LOOP
				EXECUTE 'ALTER TABLE '|| buffer ||' ADD CONSTRAINT '|| constraint_name_ ||' '|| constraint_def_;
      END LOOP;
  EXECUTE 'ALTER TABLE ' || buffer || ' OWNER TO ' || owner_;
  END LOOP;
END;

$$;


ALTER FUNCTION public.clone_schema(source_schema text, dest_schema text) OWNER TO user_captura;

--
-- Name: sp_test_gdmx(integer, integer, json); Type: FUNCTION; Schema: public; Owner: user_captura
--

CREATE FUNCTION public.sp_test_gdmx(cp integer, id integer, record json) RETURNS void
    LANGUAGE plpgsql
    AS $$
BEGIN
  INSERT INTO log_gdmx(date, cp, recordid, record)
  VALUES(now(), cp, id,record);
  return;
end; $$;


ALTER FUNCTION public.sp_test_gdmx(cp integer, id integer, record json) OWNER TO user_captura;

SET default_tablespace = '';

SET default_with_oids = false;

--
-- Name: additionalcontactpoints; Type: TABLE; Schema: public; Owner: user_captura
--

CREATE TABLE public.additionalcontactpoints (
    id integer NOT NULL,
    party_id integer,
    type text,
    name text,
    givenname text,
    surname text,
    additionalsurname text,
    email text,
    telephone text,
    faxnumber text,
    url text,
    language text
);


ALTER TABLE public.additionalcontactpoints OWNER TO user_captura;

--
-- Name: additionalcontactpoints_id_seq; Type: SEQUENCE; Schema: public; Owner: user_captura
--

CREATE SEQUENCE public.additionalcontactpoints_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.additionalcontactpoints_id_seq OWNER TO user_captura;

--
-- Name: additionalcontactpoints_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: user_captura
--

ALTER SEQUENCE public.additionalcontactpoints_id_seq OWNED BY public.additionalcontactpoints.id;


--
-- Name: additionalcontactpoints; Type: TABLE; Schema: dashboard; Owner: user_dashboard
--

CREATE TABLE dashboard.additionalcontactpoints (
    id integer DEFAULT nextval('public.additionalcontactpoints_id_seq'::regclass) NOT NULL,
    party_id integer,
    type text,
    name text,
    givenname text,
    surname text,
    additionalsurname text,
    email text,
    telephone text,
    faxnumber text,
    url text,
    language text
);


ALTER TABLE dashboard.additionalcontactpoints OWNER TO user_dashboard;

--
-- Name: additionalcontactpoints_id_seq; Type: SEQUENCE; Schema: dashboard; Owner: user_dashboard
--

CREATE SEQUENCE dashboard.additionalcontactpoints_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE dashboard.additionalcontactpoints_id_seq OWNER TO user_dashboard;

--
-- Name: award; Type: TABLE; Schema: public; Owner: user_captura
--

CREATE TABLE public.award (
    id integer NOT NULL,
    contractingprocess_id integer,
    awardid text,
    title text,
    description text,
    rationale text,
    status text,
    award_date timestamp without time zone,
    value_amount numeric,
    value_currency text,
    contractperiod_startdate timestamp without time zone,
    contractperiod_enddate timestamp without time zone,
    amendment_date timestamp without time zone,
    amendment_rationale text,
    value_amountnet numeric,
    datelastupdate timestamp without time zone
);


ALTER TABLE public.award OWNER TO user_captura;

--
-- Name: award_id_seq; Type: SEQUENCE; Schema: public; Owner: user_captura
--

CREATE SEQUENCE public.award_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.award_id_seq OWNER TO user_captura;

--
-- Name: award_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: user_captura
--

ALTER SEQUENCE public.award_id_seq OWNED BY public.award.id;


--
-- Name: award; Type: TABLE; Schema: dashboard; Owner: user_dashboard
--

CREATE TABLE dashboard.award (
    id integer DEFAULT nextval('public.award_id_seq'::regclass) NOT NULL,
    contractingprocess_id integer,
    awardid text,
    title text,
    description text,
    rationale text,
    status text,
    award_date timestamp without time zone,
    value_amount numeric,
    value_currency text,
    contractperiod_startdate timestamp without time zone,
    contractperiod_enddate timestamp without time zone,
    amendment_date timestamp without time zone,
    amendment_rationale text,
    value_amountnet numeric,
    datelastupdate timestamp without time zone
);


ALTER TABLE dashboard.award OWNER TO user_dashboard;

--
-- Name: award_id_seq; Type: SEQUENCE; Schema: dashboard; Owner: user_dashboard
--

CREATE SEQUENCE dashboard.award_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE dashboard.award_id_seq OWNER TO user_dashboard;

--
-- Name: awardamendmentchanges; Type: TABLE; Schema: public; Owner: user_captura
--

CREATE TABLE public.awardamendmentchanges (
    id integer NOT NULL,
    contractingprocess_id integer,
    award_id integer,
    property text,
    former_value text,
    amendments_date timestamp without time zone,
    amendments_rationale text,
    amendments_id text,
    amendments_description text
);


ALTER TABLE public.awardamendmentchanges OWNER TO user_captura;

--
-- Name: awardamendmentchanges_id_seq; Type: SEQUENCE; Schema: public; Owner: user_captura
--

CREATE SEQUENCE public.awardamendmentchanges_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.awardamendmentchanges_id_seq OWNER TO user_captura;

--
-- Name: awardamendmentchanges_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: user_captura
--

ALTER SEQUENCE public.awardamendmentchanges_id_seq OWNED BY public.awardamendmentchanges.id;


--
-- Name: awardamendmentchanges; Type: TABLE; Schema: dashboard; Owner: user_dashboard
--

CREATE TABLE dashboard.awardamendmentchanges (
    id integer DEFAULT nextval('public.awardamendmentchanges_id_seq'::regclass) NOT NULL,
    contractingprocess_id integer,
    award_id integer,
    property text,
    former_value text,
    amendments_date timestamp without time zone,
    amendments_rationale text,
    amendments_id text,
    amendments_description text
);


ALTER TABLE dashboard.awardamendmentchanges OWNER TO user_dashboard;

--
-- Name: awardamendmentchanges_id_seq; Type: SEQUENCE; Schema: dashboard; Owner: user_dashboard
--

CREATE SEQUENCE dashboard.awardamendmentchanges_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE dashboard.awardamendmentchanges_id_seq OWNER TO user_dashboard;

--
-- Name: awarddocuments; Type: TABLE; Schema: public; Owner: user_captura
--

CREATE TABLE public.awarddocuments (
    id integer NOT NULL,
    contractingprocess_id integer,
    award_id integer,
    document_type text,
    documentid text,
    title text,
    description text,
    url text,
    date_published timestamp without time zone,
    date_modified timestamp without time zone,
    format text,
    language text
);


ALTER TABLE public.awarddocuments OWNER TO user_captura;

--
-- Name: awarddocuments_id_seq; Type: SEQUENCE; Schema: public; Owner: user_captura
--

CREATE SEQUENCE public.awarddocuments_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.awarddocuments_id_seq OWNER TO user_captura;

--
-- Name: awarddocuments_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: user_captura
--

ALTER SEQUENCE public.awarddocuments_id_seq OWNED BY public.awarddocuments.id;


--
-- Name: awarddocuments; Type: TABLE; Schema: dashboard; Owner: user_dashboard
--

CREATE TABLE dashboard.awarddocuments (
    id integer DEFAULT nextval('public.awarddocuments_id_seq'::regclass) NOT NULL,
    contractingprocess_id integer,
    award_id integer,
    document_type text,
    documentid text,
    title text,
    description text,
    url text,
    date_published timestamp without time zone,
    date_modified timestamp without time zone,
    format text,
    language text
);


ALTER TABLE dashboard.awarddocuments OWNER TO user_dashboard;

--
-- Name: awarddocuments_id_seq; Type: SEQUENCE; Schema: dashboard; Owner: user_dashboard
--

CREATE SEQUENCE dashboard.awarddocuments_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE dashboard.awarddocuments_id_seq OWNER TO user_dashboard;

--
-- Name: awarditem; Type: TABLE; Schema: public; Owner: user_captura
--

CREATE TABLE public.awarditem (
    id integer NOT NULL,
    contractingprocess_id integer,
    award_id integer,
    itemid text,
    description text,
    classification_scheme text,
    classification_id text,
    classification_description text,
    classification_uri text,
    quantity integer,
    unit_name text,
    unit_value_amount numeric,
    unit_value_currency text,
    unit_value_amountnet numeric,
    latitude double precision,
    longitude double precision,
    location_postalcode text,
    location_countryname text,
    location_streetaddress text,
    location_region text,
    location_locality text
);


ALTER TABLE public.awarditem OWNER TO user_captura;

--
-- Name: awarditem_id_seq; Type: SEQUENCE; Schema: public; Owner: user_captura
--

CREATE SEQUENCE public.awarditem_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.awarditem_id_seq OWNER TO user_captura;

--
-- Name: awarditem_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: user_captura
--

ALTER SEQUENCE public.awarditem_id_seq OWNED BY public.awarditem.id;


--
-- Name: awarditem; Type: TABLE; Schema: dashboard; Owner: user_dashboard
--

CREATE TABLE dashboard.awarditem (
    id integer DEFAULT nextval('public.awarditem_id_seq'::regclass) NOT NULL,
    contractingprocess_id integer,
    award_id integer,
    itemid text,
    description text,
    classification_scheme text,
    classification_id text,
    classification_description text,
    classification_uri text,
    quantity integer,
    unit_name text,
    unit_value_amount numeric,
    unit_value_currency text,
    unit_value_amountnet numeric,
    latitude double precision,
    longitude double precision,
    location_postalcode text,
    location_countryname text,
    location_streetaddress text,
    location_region text,
    location_locality text
);


ALTER TABLE dashboard.awarditem OWNER TO user_dashboard;

--
-- Name: awarditem_id_seq; Type: SEQUENCE; Schema: dashboard; Owner: user_dashboard
--

CREATE SEQUENCE dashboard.awarditem_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE dashboard.awarditem_id_seq OWNER TO user_dashboard;

--
-- Name: awarditemadditionalclassifications; Type: TABLE; Schema: public; Owner: user_captura
--

CREATE TABLE public.awarditemadditionalclassifications (
    id integer NOT NULL,
    award_id integer,
    awarditem_id integer,
    scheme text,
    description text,
    uri text
);


ALTER TABLE public.awarditemadditionalclassifications OWNER TO user_captura;

--
-- Name: awarditemadditionalclassifications_id_seq; Type: SEQUENCE; Schema: public; Owner: user_captura
--

CREATE SEQUENCE public.awarditemadditionalclassifications_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.awarditemadditionalclassifications_id_seq OWNER TO user_captura;

--
-- Name: awarditemadditionalclassifications_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: user_captura
--

ALTER SEQUENCE public.awarditemadditionalclassifications_id_seq OWNED BY public.awarditemadditionalclassifications.id;


--
-- Name: awarditemadditionalclassifications; Type: TABLE; Schema: dashboard; Owner: user_dashboard
--

CREATE TABLE dashboard.awarditemadditionalclassifications (
    id integer DEFAULT nextval('public.awarditemadditionalclassifications_id_seq'::regclass) NOT NULL,
    award_id integer,
    awarditem_id integer,
    scheme text,
    description text,
    uri text
);


ALTER TABLE dashboard.awarditemadditionalclassifications OWNER TO user_dashboard;

--
-- Name: awarditemadditionalclassifications_id_seq; Type: SEQUENCE; Schema: dashboard; Owner: user_dashboard
--

CREATE SEQUENCE dashboard.awarditemadditionalclassifications_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE dashboard.awarditemadditionalclassifications_id_seq OWNER TO user_dashboard;

--
-- Name: awardsupplier; Type: TABLE; Schema: public; Owner: user_captura
--

CREATE TABLE public.awardsupplier (
    id integer NOT NULL,
    award_id integer,
    parties_id integer
);


ALTER TABLE public.awardsupplier OWNER TO user_captura;

--
-- Name: awardsupplier_id_seq; Type: SEQUENCE; Schema: public; Owner: user_captura
--

CREATE SEQUENCE public.awardsupplier_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.awardsupplier_id_seq OWNER TO user_captura;

--
-- Name: awardsupplier_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: user_captura
--

ALTER SEQUENCE public.awardsupplier_id_seq OWNED BY public.awardsupplier.id;


--
-- Name: awardsupplier; Type: TABLE; Schema: dashboard; Owner: user_dashboard
--

CREATE TABLE dashboard.awardsupplier (
    id integer DEFAULT nextval('public.awardsupplier_id_seq'::regclass) NOT NULL,
    award_id integer,
    parties_id integer
);


ALTER TABLE dashboard.awardsupplier OWNER TO user_dashboard;

--
-- Name: awardsupplier_id_seq; Type: SEQUENCE; Schema: dashboard; Owner: user_dashboard
--

CREATE SEQUENCE dashboard.awardsupplier_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE dashboard.awardsupplier_id_seq OWNER TO user_dashboard;

--
-- Name: budget; Type: TABLE; Schema: public; Owner: user_captura
--

CREATE TABLE public.budget (
    id integer NOT NULL,
    contractingprocess_id integer,
    planning_id integer,
    budget_source text,
    budget_budgetid text,
    budget_description text,
    budget_amount numeric,
    budget_currency text,
    budget_project text,
    budget_projectid text,
    budget_uri text
);


ALTER TABLE public.budget OWNER TO user_captura;

--
-- Name: budget_id_seq; Type: SEQUENCE; Schema: public; Owner: user_captura
--

CREATE SEQUENCE public.budget_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.budget_id_seq OWNER TO user_captura;

--
-- Name: budget_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: user_captura
--

ALTER SEQUENCE public.budget_id_seq OWNED BY public.budget.id;


--
-- Name: budget; Type: TABLE; Schema: dashboard; Owner: user_dashboard
--

CREATE TABLE dashboard.budget (
    id integer DEFAULT nextval('public.budget_id_seq'::regclass) NOT NULL,
    contractingprocess_id integer,
    planning_id integer,
    budget_source text,
    budget_budgetid text,
    budget_description text,
    budget_amount numeric,
    budget_currency text,
    budget_project text,
    budget_projectid text,
    budget_uri text
);


ALTER TABLE dashboard.budget OWNER TO user_dashboard;

--
-- Name: budget_id_seq; Type: SEQUENCE; Schema: dashboard; Owner: user_dashboard
--

CREATE SEQUENCE dashboard.budget_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE dashboard.budget_id_seq OWNER TO user_dashboard;

--
-- Name: budgetbreakdown; Type: TABLE; Schema: public; Owner: user_captura
--

CREATE TABLE public.budgetbreakdown (
    id integer NOT NULL,
    contractingprocess_id integer,
    planning_id integer,
    budgetbreakdown_id text,
    description text,
    amount numeric,
    currency text,
    url text,
    budgetbreakdownperiod_startdate timestamp without time zone,
    budgetbreakdownperiod_enddate timestamp without time zone,
    source_id integer
);


ALTER TABLE public.budgetbreakdown OWNER TO user_captura;

--
-- Name: budgetbreakdown_id_seq; Type: SEQUENCE; Schema: public; Owner: user_captura
--

CREATE SEQUENCE public.budgetbreakdown_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.budgetbreakdown_id_seq OWNER TO user_captura;

--
-- Name: budgetbreakdown_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: user_captura
--

ALTER SEQUENCE public.budgetbreakdown_id_seq OWNED BY public.budgetbreakdown.id;


--
-- Name: budgetbreakdown; Type: TABLE; Schema: dashboard; Owner: user_dashboard
--

CREATE TABLE dashboard.budgetbreakdown (
    id integer DEFAULT nextval('public.budgetbreakdown_id_seq'::regclass) NOT NULL,
    contractingprocess_id integer,
    planning_id integer,
    budgetbreakdown_id text,
    description text,
    amount numeric,
    currency text,
    url text,
    budgetbreakdownperiod_startdate timestamp without time zone,
    budgetbreakdownperiod_enddate timestamp without time zone,
    source_id integer
);


ALTER TABLE dashboard.budgetbreakdown OWNER TO user_dashboard;

--
-- Name: budgetbreakdown_id_seq; Type: SEQUENCE; Schema: dashboard; Owner: user_dashboard
--

CREATE SEQUENCE dashboard.budgetbreakdown_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE dashboard.budgetbreakdown_id_seq OWNER TO user_dashboard;

--
-- Name: budgetclassifications; Type: TABLE; Schema: public; Owner: user_captura
--

CREATE TABLE public.budgetclassifications (
    id integer NOT NULL,
    budgetbreakdown_id integer,
    year integer,
    branch text,
    responsibleunit text,
    finality text,
    function text,
    subfunction text,
    institutionalactivity text,
    budgetprogram text,
    strategicobjective text,
    requestingunit text,
    specificactivity text,
    spendingobject text,
    spendingtype text,
    budgetsource text,
    region text,
    portfoliokey text,
    cve text,
    approved numeric,
    modified numeric,
    executed numeric,
    committed numeric,
    reserved numeric,
    trimester integer
);


ALTER TABLE public.budgetclassifications OWNER TO user_captura;

--
-- Name: budgetclassifications_id_seq; Type: SEQUENCE; Schema: public; Owner: user_captura
--

CREATE SEQUENCE public.budgetclassifications_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.budgetclassifications_id_seq OWNER TO user_captura;

--
-- Name: budgetclassifications_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: user_captura
--

ALTER SEQUENCE public.budgetclassifications_id_seq OWNED BY public.budgetclassifications.id;


--
-- Name: budgetclassifications; Type: TABLE; Schema: dashboard; Owner: user_dashboard
--

CREATE TABLE dashboard.budgetclassifications (
    id integer DEFAULT nextval('public.budgetclassifications_id_seq'::regclass) NOT NULL,
    budgetbreakdown_id integer,
    year integer,
    branch text,
    responsibleunit text,
    finality text,
    function text,
    subfunction text,
    institutionalactivity text,
    budgetprogram text,
    strategicobjective text,
    requestingunit text,
    specificactivity text,
    spendingobject text,
    spendingtype text,
    budgetsource text,
    region text,
    portfoliokey text,
    cve text,
    approved numeric,
    modified numeric,
    executed numeric,
    committed numeric,
    reserved numeric
);


ALTER TABLE dashboard.budgetclassifications OWNER TO user_dashboard;

--
-- Name: budgetclassifications_id_seq; Type: SEQUENCE; Schema: dashboard; Owner: user_dashboard
--

CREATE SEQUENCE dashboard.budgetclassifications_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE dashboard.budgetclassifications_id_seq OWNER TO user_dashboard;

--
-- Name: clarificationmeeting; Type: TABLE; Schema: public; Owner: user_captura
--

CREATE TABLE public.clarificationmeeting (
    id integer NOT NULL,
    clarificationmeetingid text,
    contractingprocess_id integer,
    date timestamp without time zone
);


ALTER TABLE public.clarificationmeeting OWNER TO user_captura;

--
-- Name: clarificationmeeting_id_seq; Type: SEQUENCE; Schema: public; Owner: user_captura
--

CREATE SEQUENCE public.clarificationmeeting_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.clarificationmeeting_id_seq OWNER TO user_captura;

--
-- Name: clarificationmeeting_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: user_captura
--

ALTER SEQUENCE public.clarificationmeeting_id_seq OWNED BY public.clarificationmeeting.id;


--
-- Name: clarificationmeeting; Type: TABLE; Schema: dashboard; Owner: user_dashboard
--

CREATE TABLE dashboard.clarificationmeeting (
    id integer DEFAULT nextval('public.clarificationmeeting_id_seq'::regclass) NOT NULL,
    clarificationmeetingid text,
    contractingprocess_id integer,
    date timestamp without time zone
);


ALTER TABLE dashboard.clarificationmeeting OWNER TO user_dashboard;

--
-- Name: clarificationmeeting_id_seq; Type: SEQUENCE; Schema: dashboard; Owner: user_dashboard
--

CREATE SEQUENCE dashboard.clarificationmeeting_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE dashboard.clarificationmeeting_id_seq OWNER TO user_dashboard;

--
-- Name: clarificationmeetingactor; Type: TABLE; Schema: public; Owner: user_captura
--

CREATE TABLE public.clarificationmeetingactor (
    id integer NOT NULL,
    clarificationmeeting_id integer,
    parties_id integer,
    attender boolean,
    official boolean
);


ALTER TABLE public.clarificationmeetingactor OWNER TO user_captura;

--
-- Name: clarificationmeetingactor_id_seq; Type: SEQUENCE; Schema: public; Owner: user_captura
--

CREATE SEQUENCE public.clarificationmeetingactor_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.clarificationmeetingactor_id_seq OWNER TO user_captura;

--
-- Name: clarificationmeetingactor_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: user_captura
--

ALTER SEQUENCE public.clarificationmeetingactor_id_seq OWNED BY public.clarificationmeetingactor.id;


--
-- Name: clarificationmeetingactor; Type: TABLE; Schema: dashboard; Owner: user_dashboard
--

CREATE TABLE dashboard.clarificationmeetingactor (
    id integer DEFAULT nextval('public.clarificationmeetingactor_id_seq'::regclass) NOT NULL,
    clarificationmeeting_id integer,
    parties_id integer,
    attender boolean,
    official boolean
);


ALTER TABLE dashboard.clarificationmeetingactor OWNER TO user_dashboard;

--
-- Name: clarificationmeetingactor_id_seq; Type: SEQUENCE; Schema: dashboard; Owner: user_dashboard
--

CREATE SEQUENCE dashboard.clarificationmeetingactor_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE dashboard.clarificationmeetingactor_id_seq OWNER TO user_dashboard;

--
-- Name: contract; Type: TABLE; Schema: public; Owner: user_captura
--

CREATE TABLE public.contract (
    id integer NOT NULL,
    contractingprocess_id integer,
    awardid text,
    contractid text,
    title text,
    description text,
    status text,
    period_startdate timestamp without time zone,
    period_enddate timestamp without time zone,
    value_amount numeric,
    value_currency text,
    datesigned timestamp without time zone,
    amendment_date timestamp without time zone,
    amendment_rationale text,
    value_amountnet numeric,
    exchangerate_rate numeric,
    exchangerate_amount numeric DEFAULT 0,
    exchangerate_currency text,
    exchangerate_date timestamp without time zone,
    exchangerate_source text,
    datelastupdate timestamp without time zone,
    surveillancemechanisms text
);


ALTER TABLE public.contract OWNER TO user_captura;

--
-- Name: contract_id_seq; Type: SEQUENCE; Schema: public; Owner: user_captura
--

CREATE SEQUENCE public.contract_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.contract_id_seq OWNER TO user_captura;

--
-- Name: contract_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: user_captura
--

ALTER SEQUENCE public.contract_id_seq OWNED BY public.contract.id;


--
-- Name: contract; Type: TABLE; Schema: dashboard; Owner: user_dashboard
--

CREATE TABLE dashboard.contract (
    id integer DEFAULT nextval('public.contract_id_seq'::regclass) NOT NULL,
    contractingprocess_id integer,
    awardid text,
    contractid text,
    title text,
    description text,
    status text,
    period_startdate timestamp without time zone,
    period_enddate timestamp without time zone,
    value_amount numeric,
    value_currency text,
    datesigned timestamp without time zone,
    amendment_date timestamp without time zone,
    amendment_rationale text,
    value_amountnet numeric,
    exchangerate_rate numeric,
    exchangerate_amount numeric DEFAULT 0,
    exchangerate_currency text,
    exchangerate_date timestamp without time zone,
    exchangerate_source text,
    datelastupdate timestamp without time zone,
    surveillancemechanisms text
);


ALTER TABLE dashboard.contract OWNER TO user_dashboard;

--
-- Name: contract_id_seq; Type: SEQUENCE; Schema: dashboard; Owner: user_dashboard
--

CREATE SEQUENCE dashboard.contract_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE dashboard.contract_id_seq OWNER TO user_dashboard;

--
-- Name: contractamendmentchanges; Type: TABLE; Schema: public; Owner: user_captura
--

CREATE TABLE public.contractamendmentchanges (
    id integer NOT NULL,
    contractingprocess_id integer,
    contract_id integer,
    amendments_date timestamp without time zone,
    amendments_rationale text,
    amendments_id text,
    amendments_description text
);


ALTER TABLE public.contractamendmentchanges OWNER TO user_captura;

--
-- Name: contractamendmentchanges_id_seq; Type: SEQUENCE; Schema: public; Owner: user_captura
--

CREATE SEQUENCE public.contractamendmentchanges_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.contractamendmentchanges_id_seq OWNER TO user_captura;

--
-- Name: contractamendmentchanges_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: user_captura
--

ALTER SEQUENCE public.contractamendmentchanges_id_seq OWNED BY public.contractamendmentchanges.id;


--
-- Name: contractamendmentchanges; Type: TABLE; Schema: dashboard; Owner: user_dashboard
--

CREATE TABLE dashboard.contractamendmentchanges (
    id integer DEFAULT nextval('public.contractamendmentchanges_id_seq'::regclass) NOT NULL,
    contractingprocess_id integer,
    contract_id integer,
    amendments_date timestamp without time zone,
    amendments_rationale text,
    amendments_id text,
    amendments_description text
);


ALTER TABLE dashboard.contractamendmentchanges OWNER TO user_dashboard;

--
-- Name: contractamendmentchanges_id_seq; Type: SEQUENCE; Schema: dashboard; Owner: user_dashboard
--

CREATE SEQUENCE dashboard.contractamendmentchanges_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE dashboard.contractamendmentchanges_id_seq OWNER TO user_dashboard;

--
-- Name: contractdocuments; Type: TABLE; Schema: public; Owner: user_captura
--

CREATE TABLE public.contractdocuments (
    id integer NOT NULL,
    contractingprocess_id integer,
    contract_id integer,
    document_type text,
    documentid text,
    title text,
    description text,
    url text,
    date_published timestamp without time zone,
    date_modified timestamp without time zone,
    format text,
    language text
);


ALTER TABLE public.contractdocuments OWNER TO user_captura;

--
-- Name: contractdocuments_id_seq; Type: SEQUENCE; Schema: public; Owner: user_captura
--

CREATE SEQUENCE public.contractdocuments_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.contractdocuments_id_seq OWNER TO user_captura;

--
-- Name: contractdocuments_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: user_captura
--

ALTER SEQUENCE public.contractdocuments_id_seq OWNED BY public.contractdocuments.id;


--
-- Name: contractdocuments; Type: TABLE; Schema: dashboard; Owner: user_dashboard
--

CREATE TABLE dashboard.contractdocuments (
    id integer DEFAULT nextval('public.contractdocuments_id_seq'::regclass) NOT NULL,
    contractingprocess_id integer,
    contract_id integer,
    document_type text,
    documentid text,
    title text,
    description text,
    url text,
    date_published timestamp without time zone,
    date_modified timestamp without time zone,
    format text,
    language text
);


ALTER TABLE dashboard.contractdocuments OWNER TO user_dashboard;

--
-- Name: contractdocuments_id_seq; Type: SEQUENCE; Schema: dashboard; Owner: user_dashboard
--

CREATE SEQUENCE dashboard.contractdocuments_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE dashboard.contractdocuments_id_seq OWNER TO user_dashboard;

--
-- Name: contractingprocess; Type: TABLE; Schema: public; Owner: user_captura
--

CREATE TABLE public.contractingprocess (
    id integer NOT NULL,
    ocid text,
    description text,
    destino text,
    fecha_creacion date,
    hora_creacion time without time zone,
    stage integer,
    uri text,
    publicationpolicy text,
    license text,
    awardstatus text,
    contractstatus text,
    implementationstatus text,
    published boolean,
    valid boolean,
    date_published timestamp without time zone,
    requirepntupdate boolean,
    pnt_dateupdate timestamp without time zone,
    publisher text,
    updated boolean,
    updated_date timestamp without time zone,
    updated_version text,
    published_version text,
    pnt_published boolean,
    pnt_version text,
    pnt_date timestamp without time zone
);


ALTER TABLE public.contractingprocess OWNER TO user_captura;

--
-- Name: contractingprocess_id_seq; Type: SEQUENCE; Schema: public; Owner: user_captura
--

CREATE SEQUENCE public.contractingprocess_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.contractingprocess_id_seq OWNER TO user_captura;

--
-- Name: contractingprocess_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: user_captura
--

ALTER SEQUENCE public.contractingprocess_id_seq OWNED BY public.contractingprocess.id;


--
-- Name: contractingprocess; Type: TABLE; Schema: dashboard; Owner: user_dashboard
--

CREATE TABLE dashboard.contractingprocess (
    id integer DEFAULT nextval('public.contractingprocess_id_seq'::regclass) NOT NULL,
    ocid text,
    description text,
    destino text,
    fecha_creacion date,
    hora_creacion time without time zone,
    stage integer,
    uri text,
    publicationpolicy text,
    license text,
    awardstatus text,
    contractstatus text,
    implementationstatus text,
    published boolean,
    valid boolean,
    date_published timestamp without time zone,
    requirepntupdate boolean,
    pnt_dateupdate timestamp without time zone,
    publisher text,
    updated boolean,
    updated_date timestamp without time zone,
    updated_version text,
    published_version text,
    pnt_published boolean,
    pnt_version text,
    pnt_date timestamp without time zone
);


ALTER TABLE dashboard.contractingprocess OWNER TO user_dashboard;

--
-- Name: contractingprocess_id_seq; Type: SEQUENCE; Schema: dashboard; Owner: user_dashboard
--

CREATE SEQUENCE dashboard.contractingprocess_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE dashboard.contractingprocess_id_seq OWNER TO user_dashboard;

--
-- Name: contractitem; Type: TABLE; Schema: public; Owner: user_captura
--

CREATE TABLE public.contractitem (
    id integer NOT NULL,
    contractingprocess_id integer,
    contract_id integer,
    itemid text,
    description text,
    classification_scheme text,
    classification_id text,
    classification_description text,
    classification_uri text,
    quantity integer,
    unit_name text,
    unit_value_amount numeric,
    unit_value_currency text,
    unit_value_amountnet numeric,
    latitude double precision,
    longitude double precision,
    location_postalcode text,
    location_countryname text,
    location_streetaddress text,
    location_region text,
    location_locality text
);


ALTER TABLE public.contractitem OWNER TO user_captura;

--
-- Name: contractitem_id_seq; Type: SEQUENCE; Schema: public; Owner: user_captura
--

CREATE SEQUENCE public.contractitem_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.contractitem_id_seq OWNER TO user_captura;

--
-- Name: contractitem_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: user_captura
--

ALTER SEQUENCE public.contractitem_id_seq OWNED BY public.contractitem.id;


--
-- Name: contractitem; Type: TABLE; Schema: dashboard; Owner: user_dashboard
--

CREATE TABLE dashboard.contractitem (
    id integer DEFAULT nextval('public.contractitem_id_seq'::regclass) NOT NULL,
    contractingprocess_id integer,
    contract_id integer,
    itemid text,
    description text,
    classification_scheme text,
    classification_id text,
    classification_description text,
    classification_uri text,
    quantity integer,
    unit_name text,
    unit_value_amount numeric,
    unit_value_currency text,
    unit_value_amountnet numeric,
    latitude double precision,
    longitude double precision,
    location_postalcode text,
    location_countryname text,
    location_streetaddress text,
    location_region text,
    location_locality text
);


ALTER TABLE dashboard.contractitem OWNER TO user_dashboard;

--
-- Name: contractitem_id_seq; Type: SEQUENCE; Schema: dashboard; Owner: user_dashboard
--

CREATE SEQUENCE dashboard.contractitem_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE dashboard.contractitem_id_seq OWNER TO user_dashboard;

--
-- Name: contractitemadditionalclasifications; Type: TABLE; Schema: public; Owner: user_captura
--

CREATE TABLE public.contractitemadditionalclasifications (
    id integer NOT NULL,
    contractingprocess_id integer,
    contract_id integer,
    contractitem_id integer,
    scheme text,
    description text,
    uri text
);


ALTER TABLE public.contractitemadditionalclasifications OWNER TO user_captura;

--
-- Name: contractitemadditionalclasifications_id_seq; Type: SEQUENCE; Schema: public; Owner: user_captura
--

CREATE SEQUENCE public.contractitemadditionalclasifications_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.contractitemadditionalclasifications_id_seq OWNER TO user_captura;

--
-- Name: contractitemadditionalclasifications_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: user_captura
--

ALTER SEQUENCE public.contractitemadditionalclasifications_id_seq OWNED BY public.contractitemadditionalclasifications.id;


--
-- Name: contractitemadditionalclasifications; Type: TABLE; Schema: dashboard; Owner: user_dashboard
--

CREATE TABLE dashboard.contractitemadditionalclasifications (
    id integer DEFAULT nextval('public.contractitemadditionalclasifications_id_seq'::regclass) NOT NULL,
    contractingprocess_id integer,
    contract_id integer,
    contractitem_id integer,
    scheme text,
    description text,
    uri text
);


ALTER TABLE dashboard.contractitemadditionalclasifications OWNER TO user_dashboard;

--
-- Name: contractitemadditionalclasifications_id_seq; Type: SEQUENCE; Schema: dashboard; Owner: user_dashboard
--

CREATE SEQUENCE dashboard.contractitemadditionalclasifications_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE dashboard.contractitemadditionalclasifications_id_seq OWNER TO user_dashboard;

--
-- Name: currency; Type: TABLE; Schema: public; Owner: user_captura
--

CREATE TABLE public.currency (
    id integer NOT NULL,
    entity text,
    currency text,
    currency_eng text,
    alphabetic_code text,
    numeric_code text,
    minor_unit text
);


ALTER TABLE public.currency OWNER TO user_captura;

--
-- Name: currency_id_seq; Type: SEQUENCE; Schema: public; Owner: user_captura
--

CREATE SEQUENCE public.currency_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.currency_id_seq OWNER TO user_captura;

--
-- Name: currency_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: user_captura
--

ALTER SEQUENCE public.currency_id_seq OWNED BY public.currency.id;


--
-- Name: currency; Type: TABLE; Schema: dashboard; Owner: user_dashboard
--

CREATE TABLE dashboard.currency (
    id integer DEFAULT nextval('public.currency_id_seq'::regclass) NOT NULL,
    entity text,
    currency text,
    currency_eng text,
    alphabetic_code text,
    numeric_code text,
    minor_unit text
);


ALTER TABLE dashboard.currency OWNER TO user_dashboard;

--
-- Name: currency_id_seq; Type: SEQUENCE; Schema: dashboard; Owner: user_dashboard
--

CREATE SEQUENCE dashboard.currency_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE dashboard.currency_id_seq OWNER TO user_dashboard;

--
-- Name: documentformat; Type: TABLE; Schema: public; Owner: user_captura
--

CREATE TABLE public.documentformat (
    id integer NOT NULL,
    category text,
    name text,
    template text,
    reference text
);


ALTER TABLE public.documentformat OWNER TO user_captura;

--
-- Name: documentformat_id_seq; Type: SEQUENCE; Schema: public; Owner: user_captura
--

CREATE SEQUENCE public.documentformat_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.documentformat_id_seq OWNER TO user_captura;

--
-- Name: documentformat_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: user_captura
--

ALTER SEQUENCE public.documentformat_id_seq OWNED BY public.documentformat.id;


--
-- Name: documentformat; Type: TABLE; Schema: dashboard; Owner: user_dashboard
--

CREATE TABLE dashboard.documentformat (
    id integer DEFAULT nextval('public.documentformat_id_seq'::regclass) NOT NULL,
    category text,
    name text,
    template text,
    reference text
);


ALTER TABLE dashboard.documentformat OWNER TO user_dashboard;

--
-- Name: documentformat_id_seq; Type: SEQUENCE; Schema: dashboard; Owner: user_dashboard
--

CREATE SEQUENCE dashboard.documentformat_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE dashboard.documentformat_id_seq OWNER TO user_dashboard;

--
-- Name: documentmanagement; Type: TABLE; Schema: public; Owner: user_captura
--

CREATE TABLE public.documentmanagement (
    id integer NOT NULL,
    contractingprocess_id integer,
    origin text,
    document text,
    instance_id text,
    type text,
    register_date timestamp without time zone,
    error text
);


ALTER TABLE public.documentmanagement OWNER TO user_captura;

--
-- Name: documentmanagement_id_seq; Type: SEQUENCE; Schema: public; Owner: user_captura
--

CREATE SEQUENCE public.documentmanagement_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.documentmanagement_id_seq OWNER TO user_captura;

--
-- Name: documentmanagement_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: user_captura
--

ALTER SEQUENCE public.documentmanagement_id_seq OWNED BY public.documentmanagement.id;


--
-- Name: documentmanagement; Type: TABLE; Schema: dashboard; Owner: user_dashboard
--

CREATE TABLE dashboard.documentmanagement (
    id integer DEFAULT nextval('public.documentmanagement_id_seq'::regclass) NOT NULL,
    contractingprocess_id integer,
    origin text,
    document text,
    instance_id text,
    type text,
    register_date timestamp without time zone
);


ALTER TABLE dashboard.documentmanagement OWNER TO user_dashboard;

--
-- Name: documentmanagement_id_seq; Type: SEQUENCE; Schema: dashboard; Owner: user_dashboard
--

CREATE SEQUENCE dashboard.documentmanagement_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE dashboard.documentmanagement_id_seq OWNER TO user_dashboard;

--
-- Name: documenttype; Type: TABLE; Schema: public; Owner: user_captura
--

CREATE TABLE public.documenttype (
    id integer NOT NULL,
    category text,
    code text,
    title text,
    title_esp text,
    description text,
    source text,
    stage integer
);


ALTER TABLE public.documenttype OWNER TO user_captura;

--
-- Name: documenttype_id_seq; Type: SEQUENCE; Schema: public; Owner: user_captura
--

CREATE SEQUENCE public.documenttype_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.documenttype_id_seq OWNER TO user_captura;

--
-- Name: documenttype_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: user_captura
--

ALTER SEQUENCE public.documenttype_id_seq OWNED BY public.documenttype.id;


--
-- Name: documenttype; Type: TABLE; Schema: dashboard; Owner: user_dashboard
--

CREATE TABLE dashboard.documenttype (
    id integer DEFAULT nextval('public.documenttype_id_seq'::regclass) NOT NULL,
    category text,
    code text,
    title text,
    title_esp text,
    description text,
    source text,
    stage integer
);


ALTER TABLE dashboard.documenttype OWNER TO user_dashboard;

--
-- Name: documenttype_id_seq; Type: SEQUENCE; Schema: dashboard; Owner: user_dashboard
--

CREATE SEQUENCE dashboard.documenttype_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE dashboard.documenttype_id_seq OWNER TO user_dashboard;

--
-- Name: gdmx_dictionary; Type: TABLE; Schema: public; Owner: user_captura
--

CREATE TABLE public.gdmx_dictionary (
    id integer NOT NULL,
    document text,
    variable text,
    tablename text,
    field text,
    parent text,
    type text,
    index integer,
    classification text,
    catalog text,
    catalog_field text,
    storeprocedure text
);


ALTER TABLE public.gdmx_dictionary OWNER TO user_captura;

--
-- Name: gdmx_dictionary_id_seq; Type: SEQUENCE; Schema: public; Owner: user_captura
--

CREATE SEQUENCE public.gdmx_dictionary_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.gdmx_dictionary_id_seq OWNER TO user_captura;

--
-- Name: gdmx_dictionary_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: user_captura
--

ALTER SEQUENCE public.gdmx_dictionary_id_seq OWNED BY public.gdmx_dictionary.id;


--
-- Name: gdmx_dictionary; Type: TABLE; Schema: dashboard; Owner: user_dashboard
--

CREATE TABLE dashboard.gdmx_dictionary (
    id integer DEFAULT nextval('public.gdmx_dictionary_id_seq'::regclass) NOT NULL,
    document text,
    variable text,
    tablename text,
    field text,
    parent text,
    type text,
    index integer,
    classification text,
    catalog text,
    catalog_field text,
    storeprocedure text
);


ALTER TABLE dashboard.gdmx_dictionary OWNER TO user_dashboard;

--
-- Name: gdmx_dictionary_id_seq; Type: SEQUENCE; Schema: dashboard; Owner: user_dashboard
--

CREATE SEQUENCE dashboard.gdmx_dictionary_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE dashboard.gdmx_dictionary_id_seq OWNER TO user_dashboard;

--
-- Name: gdmx_document; Type: TABLE; Schema: public; Owner: user_captura
--

CREATE TABLE public.gdmx_document (
    id integer NOT NULL,
    name text,
    stage integer,
    type text,
    tablename text,
    identifier text
);


ALTER TABLE public.gdmx_document OWNER TO user_captura;

--
-- Name: gdmx_document_id_seq; Type: SEQUENCE; Schema: public; Owner: user_captura
--

CREATE SEQUENCE public.gdmx_document_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.gdmx_document_id_seq OWNER TO user_captura;

--
-- Name: gdmx_document_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: user_captura
--

ALTER SEQUENCE public.gdmx_document_id_seq OWNED BY public.gdmx_document.id;


--
-- Name: gdmx_document; Type: TABLE; Schema: dashboard; Owner: user_dashboard
--

CREATE TABLE dashboard.gdmx_document (
    id integer DEFAULT nextval('public.gdmx_document_id_seq'::regclass) NOT NULL,
    name text,
    stage integer,
    type text,
    tablename text,
    identifier text
);


ALTER TABLE dashboard.gdmx_document OWNER TO user_dashboard;

--
-- Name: gdmx_document_id_seq; Type: SEQUENCE; Schema: dashboard; Owner: user_dashboard
--

CREATE SEQUENCE dashboard.gdmx_document_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE dashboard.gdmx_document_id_seq OWNER TO user_dashboard;

--
-- Name: guarantees; Type: TABLE; Schema: public; Owner: user_captura
--

CREATE TABLE public.guarantees (
    id integer NOT NULL,
    contractingprocess_id integer,
    contract_id integer,
    guarantee_id text,
    guaranteetype text,
    date timestamp without time zone,
    guaranteedobligations text,
    value numeric,
    guarantor integer,
    guaranteeperiod_startdate timestamp without time zone,
    guaranteeperiod_enddate timestamp without time zone,
    currency text
);


ALTER TABLE public.guarantees OWNER TO user_captura;

--
-- Name: guarantees_id_seq; Type: SEQUENCE; Schema: public; Owner: user_captura
--

CREATE SEQUENCE public.guarantees_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.guarantees_id_seq OWNER TO user_captura;

--
-- Name: guarantees_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: user_captura
--

ALTER SEQUENCE public.guarantees_id_seq OWNED BY public.guarantees.id;


--
-- Name: guarantees; Type: TABLE; Schema: dashboard; Owner: user_dashboard
--

CREATE TABLE dashboard.guarantees (
    id integer DEFAULT nextval('public.guarantees_id_seq'::regclass) NOT NULL,
    contractingprocess_id integer,
    contract_id integer,
    guarantee_id text,
    guaranteetype text,
    date timestamp without time zone,
    guaranteedobligations text,
    value numeric,
    guarantor integer,
    guaranteeperiod_startdate timestamp without time zone,
    guaranteeperiod_enddate timestamp without time zone,
    currency text
);


ALTER TABLE dashboard.guarantees OWNER TO user_dashboard;

--
-- Name: guarantees_id_seq; Type: SEQUENCE; Schema: dashboard; Owner: user_dashboard
--

CREATE SEQUENCE dashboard.guarantees_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE dashboard.guarantees_id_seq OWNER TO user_dashboard;

--
-- Name: implementation; Type: TABLE; Schema: public; Owner: user_captura
--

CREATE TABLE public.implementation (
    id integer NOT NULL,
    contractingprocess_id integer,
    contract_id integer,
    status text,
    datelastupdate timestamp without time zone
);


ALTER TABLE public.implementation OWNER TO user_captura;

--
-- Name: implementation_id_seq; Type: SEQUENCE; Schema: public; Owner: user_captura
--

CREATE SEQUENCE public.implementation_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.implementation_id_seq OWNER TO user_captura;

--
-- Name: implementation_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: user_captura
--

ALTER SEQUENCE public.implementation_id_seq OWNED BY public.implementation.id;


--
-- Name: implementation; Type: TABLE; Schema: dashboard; Owner: user_dashboard
--

CREATE TABLE dashboard.implementation (
    id integer DEFAULT nextval('public.implementation_id_seq'::regclass) NOT NULL,
    contractingprocess_id integer,
    contract_id integer,
    status text,
    datelastupdate timestamp without time zone
);


ALTER TABLE dashboard.implementation OWNER TO user_dashboard;

--
-- Name: implementation_id_seq; Type: SEQUENCE; Schema: dashboard; Owner: user_dashboard
--

CREATE SEQUENCE dashboard.implementation_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE dashboard.implementation_id_seq OWNER TO user_dashboard;

--
-- Name: implementationdocuments; Type: TABLE; Schema: public; Owner: user_captura
--

CREATE TABLE public.implementationdocuments (
    id integer NOT NULL,
    contractingprocess_id integer,
    contract_id integer,
    implementation_id integer,
    document_type text,
    documentid text,
    title text,
    description text,
    url text,
    date_published timestamp without time zone,
    date_modified timestamp without time zone,
    format text,
    language text
);


ALTER TABLE public.implementationdocuments OWNER TO user_captura;

--
-- Name: implementationdocuments_id_seq; Type: SEQUENCE; Schema: public; Owner: user_captura
--

CREATE SEQUENCE public.implementationdocuments_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.implementationdocuments_id_seq OWNER TO user_captura;

--
-- Name: implementationdocuments_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: user_captura
--

ALTER SEQUENCE public.implementationdocuments_id_seq OWNED BY public.implementationdocuments.id;


--
-- Name: implementationdocuments; Type: TABLE; Schema: dashboard; Owner: user_dashboard
--

CREATE TABLE dashboard.implementationdocuments (
    id integer DEFAULT nextval('public.implementationdocuments_id_seq'::regclass) NOT NULL,
    contractingprocess_id integer,
    contract_id integer,
    implementation_id integer,
    document_type text,
    documentid text,
    title text,
    description text,
    url text,
    date_published timestamp without time zone,
    date_modified timestamp without time zone,
    format text,
    language text
);


ALTER TABLE dashboard.implementationdocuments OWNER TO user_dashboard;

--
-- Name: implementationdocuments_id_seq; Type: SEQUENCE; Schema: dashboard; Owner: user_dashboard
--

CREATE SEQUENCE dashboard.implementationdocuments_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE dashboard.implementationdocuments_id_seq OWNER TO user_dashboard;

--
-- Name: implementationmilestone; Type: TABLE; Schema: public; Owner: user_captura
--

CREATE TABLE public.implementationmilestone (
    id integer NOT NULL,
    contractingprocess_id integer,
    contract_id integer,
    implementation_id integer,
    milestoneid text,
    title text,
    description text,
    duedate timestamp without time zone,
    date_modified timestamp without time zone,
    status text,
    type text
);


ALTER TABLE public.implementationmilestone OWNER TO user_captura;

--
-- Name: implementationmilestone_id_seq; Type: SEQUENCE; Schema: public; Owner: user_captura
--

CREATE SEQUENCE public.implementationmilestone_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.implementationmilestone_id_seq OWNER TO user_captura;

--
-- Name: implementationmilestone_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: user_captura
--

ALTER SEQUENCE public.implementationmilestone_id_seq OWNED BY public.implementationmilestone.id;


--
-- Name: implementationmilestone; Type: TABLE; Schema: dashboard; Owner: user_dashboard
--

CREATE TABLE dashboard.implementationmilestone (
    id integer DEFAULT nextval('public.implementationmilestone_id_seq'::regclass) NOT NULL,
    contractingprocess_id integer,
    contract_id integer,
    implementation_id integer,
    milestoneid text,
    title text,
    description text,
    duedate timestamp without time zone,
    date_modified timestamp without time zone,
    status text,
    type text
);


ALTER TABLE dashboard.implementationmilestone OWNER TO user_dashboard;

--
-- Name: implementationmilestone_id_seq; Type: SEQUENCE; Schema: dashboard; Owner: user_dashboard
--

CREATE SEQUENCE dashboard.implementationmilestone_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE dashboard.implementationmilestone_id_seq OWNER TO user_dashboard;

--
-- Name: implementationmilestonedocuments; Type: TABLE; Schema: public; Owner: user_captura
--

CREATE TABLE public.implementationmilestonedocuments (
    id integer NOT NULL,
    contractingprocess_id integer,
    contract_id integer,
    implementation_id integer,
    document_type text,
    documentid text,
    title text,
    description text,
    url text,
    date_published timestamp without time zone,
    date_modified timestamp without time zone,
    format text,
    language text
);


ALTER TABLE public.implementationmilestonedocuments OWNER TO user_captura;

--
-- Name: implementationmilestonedocuments_id_seq; Type: SEQUENCE; Schema: public; Owner: user_captura
--

CREATE SEQUENCE public.implementationmilestonedocuments_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.implementationmilestonedocuments_id_seq OWNER TO user_captura;

--
-- Name: implementationmilestonedocuments_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: user_captura
--

ALTER SEQUENCE public.implementationmilestonedocuments_id_seq OWNED BY public.implementationmilestonedocuments.id;


--
-- Name: implementationmilestonedocuments; Type: TABLE; Schema: dashboard; Owner: user_dashboard
--

CREATE TABLE dashboard.implementationmilestonedocuments (
    id integer DEFAULT nextval('public.implementationmilestonedocuments_id_seq'::regclass) NOT NULL,
    contractingprocess_id integer,
    contract_id integer,
    implementation_id integer,
    document_type text,
    documentid text,
    title text,
    description text,
    url text,
    date_published timestamp without time zone,
    date_modified timestamp without time zone,
    format text,
    language text
);


ALTER TABLE dashboard.implementationmilestonedocuments OWNER TO user_dashboard;

--
-- Name: implementationmilestonedocuments_id_seq; Type: SEQUENCE; Schema: dashboard; Owner: user_dashboard
--

CREATE SEQUENCE dashboard.implementationmilestonedocuments_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE dashboard.implementationmilestonedocuments_id_seq OWNER TO user_dashboard;

--
-- Name: implementationstatus; Type: TABLE; Schema: public; Owner: user_captura
--

CREATE TABLE public.implementationstatus (
    id integer NOT NULL,
    code text,
    title text,
    title_esp text,
    description text
);


ALTER TABLE public.implementationstatus OWNER TO user_captura;

--
-- Name: implementationstatus_id_seq; Type: SEQUENCE; Schema: public; Owner: user_captura
--

CREATE SEQUENCE public.implementationstatus_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.implementationstatus_id_seq OWNER TO user_captura;

--
-- Name: implementationstatus_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: user_captura
--

ALTER SEQUENCE public.implementationstatus_id_seq OWNED BY public.implementationstatus.id;


--
-- Name: implementationstatus; Type: TABLE; Schema: dashboard; Owner: user_dashboard
--

CREATE TABLE dashboard.implementationstatus (
    id integer DEFAULT nextval('public.implementationstatus_id_seq'::regclass) NOT NULL,
    code text,
    title text,
    title_esp text,
    description text
);


ALTER TABLE dashboard.implementationstatus OWNER TO user_dashboard;

--
-- Name: implementationstatus_id_seq; Type: SEQUENCE; Schema: dashboard; Owner: user_dashboard
--

CREATE SEQUENCE dashboard.implementationstatus_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE dashboard.implementationstatus_id_seq OWNER TO user_dashboard;

--
-- Name: implementationtransactions; Type: TABLE; Schema: public; Owner: user_captura
--

CREATE TABLE public.implementationtransactions (
    id integer NOT NULL,
    contractingprocess_id integer,
    contract_id integer,
    implementation_id integer,
    transactionid text,
    source text,
    implementation_date timestamp without time zone,
    value_amount numeric,
    value_currency text,
    payment_method text,
    uri text,
    payer_name text,
    payer_id text,
    payee_name text,
    payee_id text,
    value_amountnet numeric
);


ALTER TABLE public.implementationtransactions OWNER TO user_captura;

--
-- Name: implementationtransactions_id_seq; Type: SEQUENCE; Schema: public; Owner: user_captura
--

CREATE SEQUENCE public.implementationtransactions_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.implementationtransactions_id_seq OWNER TO user_captura;

--
-- Name: implementationtransactions_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: user_captura
--

ALTER SEQUENCE public.implementationtransactions_id_seq OWNED BY public.implementationtransactions.id;


--
-- Name: implementationtransactions; Type: TABLE; Schema: dashboard; Owner: user_dashboard
--

CREATE TABLE dashboard.implementationtransactions (
    id integer DEFAULT nextval('public.implementationtransactions_id_seq'::regclass) NOT NULL,
    contractingprocess_id integer,
    contract_id integer,
    implementation_id integer,
    transactionid text,
    source text,
    implementation_date timestamp without time zone,
    value_amount numeric,
    value_currency text,
    payment_method text,
    uri text,
    payer_name text,
    payer_id text,
    payee_name text,
    payee_id text,
    value_amountnet numeric
);


ALTER TABLE dashboard.implementationtransactions OWNER TO user_dashboard;

--
-- Name: implementationtransactions_id_seq; Type: SEQUENCE; Schema: dashboard; Owner: user_dashboard
--

CREATE SEQUENCE dashboard.implementationtransactions_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE dashboard.implementationtransactions_id_seq OWNER TO user_dashboard;

--
-- Name: item; Type: TABLE; Schema: public; Owner: user_captura
--

CREATE TABLE public.item (
    id integer NOT NULL,
    classificationid text NOT NULL,
    description text NOT NULL,
    unit text
);


ALTER TABLE public.item OWNER TO user_captura;

--
-- Name: item_id_seq; Type: SEQUENCE; Schema: public; Owner: user_captura
--

CREATE SEQUENCE public.item_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.item_id_seq OWNER TO user_captura;

--
-- Name: item_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: user_captura
--

ALTER SEQUENCE public.item_id_seq OWNED BY public.item.id;


--
-- Name: item; Type: TABLE; Schema: dashboard; Owner: user_dashboard
--

CREATE TABLE dashboard.item (
    id integer DEFAULT nextval('public.item_id_seq'::regclass) NOT NULL,
    classificationid text NOT NULL,
    description text NOT NULL,
    unit text
);


ALTER TABLE dashboard.item OWNER TO user_dashboard;

--
-- Name: item_id_seq; Type: SEQUENCE; Schema: dashboard; Owner: user_dashboard
--

CREATE SEQUENCE dashboard.item_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE dashboard.item_id_seq OWNER TO user_dashboard;

--
-- Name: language; Type: TABLE; Schema: public; Owner: user_captura
--

CREATE TABLE public.language (
    id integer NOT NULL,
    alpha2 character varying(2),
    name text
);


ALTER TABLE public.language OWNER TO user_captura;

--
-- Name: language_id_seq; Type: SEQUENCE; Schema: public; Owner: user_captura
--

CREATE SEQUENCE public.language_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.language_id_seq OWNER TO user_captura;

--
-- Name: language_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: user_captura
--

ALTER SEQUENCE public.language_id_seq OWNED BY public.language.id;


--
-- Name: language; Type: TABLE; Schema: dashboard; Owner: user_dashboard
--

CREATE TABLE dashboard.language (
    id integer DEFAULT nextval('public.language_id_seq'::regclass) NOT NULL,
    alpha2 character varying(2),
    name text
);


ALTER TABLE dashboard.language OWNER TO user_dashboard;

--
-- Name: language_id_seq; Type: SEQUENCE; Schema: dashboard; Owner: user_dashboard
--

CREATE SEQUENCE dashboard.language_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE dashboard.language_id_seq OWNER TO user_dashboard;

--
-- Name: links; Type: TABLE; Schema: public; Owner: user_captura
--

CREATE TABLE public.links (
    id integer NOT NULL,
    json text,
    xlsx text,
    pdf text,
    contractingprocess_id integer
);


ALTER TABLE public.links OWNER TO user_captura;

--
-- Name: links_id_seq; Type: SEQUENCE; Schema: public; Owner: user_captura
--

CREATE SEQUENCE public.links_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.links_id_seq OWNER TO user_captura;

--
-- Name: links_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: user_captura
--

ALTER SEQUENCE public.links_id_seq OWNED BY public.links.id;


--
-- Name: links; Type: TABLE; Schema: dashboard; Owner: user_dashboard
--

CREATE TABLE dashboard.links (
    id integer DEFAULT nextval('public.links_id_seq'::regclass) NOT NULL,
    json text,
    xlsx text,
    pdf text,
    contractingprocess_id integer
);


ALTER TABLE dashboard.links OWNER TO user_dashboard;

--
-- Name: links_id_seq; Type: SEQUENCE; Schema: dashboard; Owner: user_dashboard
--

CREATE SEQUENCE dashboard.links_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE dashboard.links_id_seq OWNER TO user_dashboard;

--
-- Name: log_gdmx; Type: TABLE; Schema: public; Owner: user_captura
--

CREATE TABLE public.log_gdmx (
    id integer NOT NULL,
    date timestamp without time zone,
    cp integer,
    recordid integer,
    record json
);


ALTER TABLE public.log_gdmx OWNER TO user_captura;

--
-- Name: log_gdmx_id_seq; Type: SEQUENCE; Schema: public; Owner: user_captura
--

CREATE SEQUENCE public.log_gdmx_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.log_gdmx_id_seq OWNER TO user_captura;

--
-- Name: log_gdmx_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: user_captura
--

ALTER SEQUENCE public.log_gdmx_id_seq OWNED BY public.log_gdmx.id;


--
-- Name: log_gdmx; Type: TABLE; Schema: dashboard; Owner: user_dashboard
--

CREATE TABLE dashboard.log_gdmx (
    id integer DEFAULT nextval('public.log_gdmx_id_seq'::regclass) NOT NULL,
    date timestamp without time zone,
    cp integer,
    recordid integer,
    record json
);


ALTER TABLE dashboard.log_gdmx OWNER TO user_dashboard;

--
-- Name: log_gdmx_id_seq; Type: SEQUENCE; Schema: dashboard; Owner: user_dashboard
--

CREATE SEQUENCE dashboard.log_gdmx_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE dashboard.log_gdmx_id_seq OWNER TO user_dashboard;

--
-- Name: logs; Type: TABLE; Schema: public; Owner: user_captura
--

CREATE TABLE public.logs (
    id integer NOT NULL,
    version text,
    update_date timestamp without time zone,
    publisher text,
    release_file text,
    release_json json,
    record_json json,
    contractingprocess_id integer,
    version_json json,
    published boolean
);


ALTER TABLE public.logs OWNER TO user_captura;

--
-- Name: logs_id_seq; Type: SEQUENCE; Schema: public; Owner: user_captura
--

CREATE SEQUENCE public.logs_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.logs_id_seq OWNER TO user_captura;

--
-- Name: logs_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: user_captura
--

ALTER SEQUENCE public.logs_id_seq OWNED BY public.logs.id;


--
-- Name: logs; Type: TABLE; Schema: dashboard; Owner: user_dashboard
--

CREATE TABLE dashboard.logs (
    id integer DEFAULT nextval('public.logs_id_seq'::regclass) NOT NULL,
    version text,
    update_date timestamp without time zone,
    publisher text,
    release_file text,
    release_json json,
    record_json json,
    contractingprocess_id integer,
    version_json json,
    published boolean
);


ALTER TABLE dashboard.logs OWNER TO user_dashboard;

--
-- Name: logs_id_seq; Type: SEQUENCE; Schema: dashboard; Owner: user_dashboard
--

CREATE SEQUENCE dashboard.logs_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE dashboard.logs_id_seq OWNER TO user_dashboard;

--
-- Name: memberof; Type: TABLE; Schema: public; Owner: user_captura
--

CREATE TABLE public.memberof (
    id integer NOT NULL,
    memberofid text,
    principal_parties_id integer,
    parties_id integer
);


ALTER TABLE public.memberof OWNER TO user_captura;

--
-- Name: memberof_id_seq; Type: SEQUENCE; Schema: public; Owner: user_captura
--

CREATE SEQUENCE public.memberof_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.memberof_id_seq OWNER TO user_captura;

--
-- Name: memberof_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: user_captura
--

ALTER SEQUENCE public.memberof_id_seq OWNED BY public.memberof.id;


--
-- Name: memberof; Type: TABLE; Schema: dashboard; Owner: user_dashboard
--

CREATE TABLE dashboard.memberof (
    id integer DEFAULT nextval('public.memberof_id_seq'::regclass) NOT NULL,
    memberofid text,
    principal_parties_id integer,
    parties_id integer
);


ALTER TABLE dashboard.memberof OWNER TO user_dashboard;

--
-- Name: memberof_id_seq; Type: SEQUENCE; Schema: dashboard; Owner: user_dashboard
--

CREATE SEQUENCE dashboard.memberof_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE dashboard.memberof_id_seq OWNER TO user_dashboard;

--
-- Name: metadata; Type: TABLE; Schema: dashboard; Owner: user_dashboard
--

CREATE TABLE dashboard.metadata (
    field_name character varying(50) NOT NULL,
    value text
);


ALTER TABLE dashboard.metadata OWNER TO user_dashboard;

--
-- Name: milestonetype; Type: TABLE; Schema: public; Owner: user_captura
--

CREATE TABLE public.milestonetype (
    id integer NOT NULL,
    code text,
    title text,
    description text
);


ALTER TABLE public.milestonetype OWNER TO user_captura;

--
-- Name: milestonetype_id_seq; Type: SEQUENCE; Schema: public; Owner: user_captura
--

CREATE SEQUENCE public.milestonetype_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.milestonetype_id_seq OWNER TO user_captura;

--
-- Name: milestonetype_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: user_captura
--

ALTER SEQUENCE public.milestonetype_id_seq OWNED BY public.milestonetype.id;


--
-- Name: milestonetype; Type: TABLE; Schema: dashboard; Owner: user_dashboard
--

CREATE TABLE dashboard.milestonetype (
    id integer DEFAULT nextval('public.milestonetype_id_seq'::regclass) NOT NULL,
    code text,
    title text,
    description text
);


ALTER TABLE dashboard.milestonetype OWNER TO user_dashboard;

--
-- Name: milestonetype_id_seq; Type: SEQUENCE; Schema: dashboard; Owner: user_dashboard
--

CREATE SEQUENCE dashboard.milestonetype_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE dashboard.milestonetype_id_seq OWNER TO user_dashboard;

--
-- Name: parties; Type: TABLE; Schema: public; Owner: user_captura
--

CREATE TABLE public.parties (
    contractingprocess_id integer,
    id integer NOT NULL,
    partyid text,
    name text,
    "position" text,
    identifier_scheme text,
    identifier_id text,
    identifier_legalname text,
    identifier_uri text,
    address_streetaddress text,
    address_locality text,
    address_region text,
    address_postalcode text,
    address_countryname text,
    contactpoint_name text,
    contactpoint_email text,
    contactpoint_telephone text,
    contactpoint_faxnumber text,
    contactpoint_url text,
    details text,
    naturalperson boolean,
    contactpoint_type text,
    contactpoint_language text,
    surname text,
    additionalsurname text,
    contactpoint_surname text,
    contactpoint_additionalsurname text,
    givenname text,
    contactpoint_givenname text
);


ALTER TABLE public.parties OWNER TO user_captura;

--
-- Name: parties_id_seq; Type: SEQUENCE; Schema: public; Owner: user_captura
--

CREATE SEQUENCE public.parties_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.parties_id_seq OWNER TO user_captura;

--
-- Name: parties_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: user_captura
--

ALTER SEQUENCE public.parties_id_seq OWNED BY public.parties.id;


--
-- Name: parties; Type: TABLE; Schema: dashboard; Owner: user_dashboard
--

CREATE TABLE dashboard.parties (
    contractingprocess_id integer,
    id integer DEFAULT nextval('public.parties_id_seq'::regclass) NOT NULL,
    partyid text,
    name text,
    "position" text,
    identifier_scheme text,
    identifier_id text,
    identifier_legalname text,
    identifier_uri text,
    address_streetaddress text,
    address_locality text,
    address_region text,
    address_postalcode text,
    address_countryname text,
    contactpoint_name text,
    contactpoint_email text,
    contactpoint_telephone text,
    contactpoint_faxnumber text,
    contactpoint_url text,
    details text,
    naturalperson boolean,
    contactpoint_type text,
    contactpoint_language text,
    surname text,
    additionalsurname text,
    contactpoint_surname text,
    contactpoint_additionalsurname text,
    givenname text,
    contactpoint_givenname text
);


ALTER TABLE dashboard.parties OWNER TO user_dashboard;

--
-- Name: parties_id_seq; Type: SEQUENCE; Schema: dashboard; Owner: user_dashboard
--

CREATE SEQUENCE dashboard.parties_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE dashboard.parties_id_seq OWNER TO user_dashboard;

--
-- Name: partiesadditionalidentifiers; Type: TABLE; Schema: public; Owner: user_captura
--

CREATE TABLE public.partiesadditionalidentifiers (
    id integer NOT NULL,
    contractingprocess_id integer,
    parties_id integer,
    scheme text,
    legalname text,
    uri text
);


ALTER TABLE public.partiesadditionalidentifiers OWNER TO user_captura;

--
-- Name: partiesadditionalidentifiers_id_seq; Type: SEQUENCE; Schema: public; Owner: user_captura
--

CREATE SEQUENCE public.partiesadditionalidentifiers_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.partiesadditionalidentifiers_id_seq OWNER TO user_captura;

--
-- Name: partiesadditionalidentifiers_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: user_captura
--

ALTER SEQUENCE public.partiesadditionalidentifiers_id_seq OWNED BY public.partiesadditionalidentifiers.id;


--
-- Name: partiesadditionalidentifiers; Type: TABLE; Schema: dashboard; Owner: user_dashboard
--

CREATE TABLE dashboard.partiesadditionalidentifiers (
    id integer DEFAULT nextval('public.partiesadditionalidentifiers_id_seq'::regclass) NOT NULL,
    contractingprocess_id integer,
    parties_id integer,
    scheme text,
    legalname text,
    uri text
);


ALTER TABLE dashboard.partiesadditionalidentifiers OWNER TO user_dashboard;

--
-- Name: partiesadditionalidentifiers_id_seq; Type: SEQUENCE; Schema: dashboard; Owner: user_dashboard
--

CREATE SEQUENCE dashboard.partiesadditionalidentifiers_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE dashboard.partiesadditionalidentifiers_id_seq OWNER TO user_dashboard;

--
-- Name: paymentmethod; Type: TABLE; Schema: public; Owner: user_captura
--

CREATE TABLE public.paymentmethod (
    id integer NOT NULL,
    code text,
    title text,
    description text
);


ALTER TABLE public.paymentmethod OWNER TO user_captura;

--
-- Name: paymentmethod_id_seq; Type: SEQUENCE; Schema: public; Owner: user_captura
--

CREATE SEQUENCE public.paymentmethod_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.paymentmethod_id_seq OWNER TO user_captura;

--
-- Name: paymentmethod_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: user_captura
--

ALTER SEQUENCE public.paymentmethod_id_seq OWNED BY public.paymentmethod.id;


--
-- Name: paymentmethod; Type: TABLE; Schema: dashboard; Owner: user_dashboard
--

CREATE TABLE dashboard.paymentmethod (
    id integer DEFAULT nextval('public.paymentmethod_id_seq'::regclass) NOT NULL,
    code text,
    title text,
    description text
);


ALTER TABLE dashboard.paymentmethod OWNER TO user_dashboard;

--
-- Name: paymentmethod_id_seq; Type: SEQUENCE; Schema: dashboard; Owner: user_dashboard
--

CREATE SEQUENCE dashboard.paymentmethod_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE dashboard.paymentmethod_id_seq OWNER TO user_dashboard;

--
-- Name: planning; Type: TABLE; Schema: public; Owner: user_captura
--

CREATE TABLE public.planning (
    id integer NOT NULL,
    contractingprocess_id integer,
    hasquotes boolean,
    rationale text
);


ALTER TABLE public.planning OWNER TO user_captura;

--
-- Name: planning_id_seq; Type: SEQUENCE; Schema: public; Owner: user_captura
--

CREATE SEQUENCE public.planning_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.planning_id_seq OWNER TO user_captura;

--
-- Name: planning_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: user_captura
--

ALTER SEQUENCE public.planning_id_seq OWNED BY public.planning.id;


--
-- Name: planning; Type: TABLE; Schema: dashboard; Owner: user_dashboard
--

CREATE TABLE dashboard.planning (
    id integer DEFAULT nextval('public.planning_id_seq'::regclass) NOT NULL,
    contractingprocess_id integer,
    hasquotes boolean,
    rationale text
);


ALTER TABLE dashboard.planning OWNER TO user_dashboard;

--
-- Name: planning_id_seq; Type: SEQUENCE; Schema: dashboard; Owner: user_dashboard
--

CREATE SEQUENCE dashboard.planning_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE dashboard.planning_id_seq OWNER TO user_dashboard;

--
-- Name: planningdocuments; Type: TABLE; Schema: public; Owner: user_captura
--

CREATE TABLE public.planningdocuments (
    id integer NOT NULL,
    contractingprocess_id integer,
    planning_id integer,
    documentid text,
    document_type text,
    title text,
    description text,
    url text,
    date_published timestamp without time zone,
    date_modified timestamp without time zone,
    format text,
    language text
);


ALTER TABLE public.planningdocuments OWNER TO user_captura;

--
-- Name: planningdocuments_id_seq; Type: SEQUENCE; Schema: public; Owner: user_captura
--

CREATE SEQUENCE public.planningdocuments_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.planningdocuments_id_seq OWNER TO user_captura;

--
-- Name: planningdocuments_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: user_captura
--

ALTER SEQUENCE public.planningdocuments_id_seq OWNED BY public.planningdocuments.id;


--
-- Name: planningdocuments; Type: TABLE; Schema: dashboard; Owner: user_dashboard
--

CREATE TABLE dashboard.planningdocuments (
    id integer DEFAULT nextval('public.planningdocuments_id_seq'::regclass) NOT NULL,
    contractingprocess_id integer,
    planning_id integer,
    documentid text,
    document_type text,
    title text,
    description text,
    url text,
    date_published timestamp without time zone,
    date_modified timestamp without time zone,
    format text,
    language text
);


ALTER TABLE dashboard.planningdocuments OWNER TO user_dashboard;

--
-- Name: planningdocuments_id_seq; Type: SEQUENCE; Schema: dashboard; Owner: user_dashboard
--

CREATE SEQUENCE dashboard.planningdocuments_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE dashboard.planningdocuments_id_seq OWNER TO user_dashboard;

--
-- Name: pntreference; Type: TABLE; Schema: public; Owner: user_captura
--

CREATE TABLE public.pntreference (
    id integer NOT NULL,
    contractingprocess_id integer,
    contractid text,
    format integer,
    record_id text,
    "position" integer,
    field_id integer,
    reference_id integer,
    date timestamp without time zone,
    isroot boolean,
    error text
);


ALTER TABLE public.pntreference OWNER TO user_captura;

--
-- Name: pntreference_id_seq; Type: SEQUENCE; Schema: public; Owner: user_captura
--

CREATE SEQUENCE public.pntreference_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.pntreference_id_seq OWNER TO user_captura;

--
-- Name: pntreference_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: user_captura
--

ALTER SEQUENCE public.pntreference_id_seq OWNED BY public.pntreference.id;


--
-- Name: pntreference; Type: TABLE; Schema: dashboard; Owner: user_dashboard
--

CREATE TABLE dashboard.pntreference (
    id integer DEFAULT nextval('public.pntreference_id_seq'::regclass) NOT NULL,
    contractingprocess_id integer,
    contractid text,
    format integer,
    record_id text,
    "position" integer,
    field_id integer,
    reference_id integer,
    date timestamp without time zone,
    isroot boolean,
    error text
);


ALTER TABLE dashboard.pntreference OWNER TO user_dashboard;

--
-- Name: pntreference_id_seq; Type: SEQUENCE; Schema: dashboard; Owner: user_dashboard
--

CREATE SEQUENCE dashboard.pntreference_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE dashboard.pntreference_id_seq OWNER TO user_dashboard;

--
-- Name: prefixocid; Type: TABLE; Schema: public; Owner: user_captura
--

CREATE TABLE public.prefixocid (
    id integer NOT NULL,
    value text
);


ALTER TABLE public.prefixocid OWNER TO user_captura;

--
-- Name: prefixocid_id_seq; Type: SEQUENCE; Schema: public; Owner: user_captura
--

CREATE SEQUENCE public.prefixocid_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.prefixocid_id_seq OWNER TO user_captura;

--
-- Name: prefixocid_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: user_captura
--

ALTER SEQUENCE public.prefixocid_id_seq OWNED BY public.prefixocid.id;


--
-- Name: prefixocid; Type: TABLE; Schema: dashboard; Owner: user_dashboard
--

CREATE TABLE dashboard.prefixocid (
    id integer DEFAULT nextval('public.prefixocid_id_seq'::regclass) NOT NULL,
    value text
);


ALTER TABLE dashboard.prefixocid OWNER TO user_dashboard;

--
-- Name: prefixocid_id_seq; Type: SEQUENCE; Schema: dashboard; Owner: user_dashboard
--

CREATE SEQUENCE dashboard.prefixocid_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE dashboard.prefixocid_id_seq OWNER TO user_dashboard;

--
-- Name: programaticstructure; Type: TABLE; Schema: public; Owner: user_captura
--

CREATE TABLE public.programaticstructure (
    id integer NOT NULL,
    cve text,
    year integer,
    trimester integer,
    branch text,
    branch_desc text,
    finality text,
    finality_desc text,
    function text,
    function_desc text,
    subfunction text,
    subfunction_desc text,
    institutionalactivity text,
    institutionalactivity_desc text,
    budgetprogram text,
    budgetprogram_desc text,
    strategicobjective text,
    strategicobjective_desc text,
    responsibleunit text,
    responsibleunit_desc text,
    requestingunit text,
    requestingunit_desc text,
    spendingtype text,
    spendingtype_desc text,
    specificactivity text,
    specificactivity_desc text,
    spendingobject text,
    spendingobject_desc text,
    region text,
    region_desc text,
    budgetsource text,
    budgetsource_desc text,
    portfoliokey text,
    approvedamount numeric,
    modifiedamount numeric,
    executedamount numeric,
    committedamount numeric,
    reservedamount numeric
);


ALTER TABLE public.programaticstructure OWNER TO user_captura;

--
-- Name: programaticstructure_id_seq; Type: SEQUENCE; Schema: public; Owner: user_captura
--

CREATE SEQUENCE public.programaticstructure_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.programaticstructure_id_seq OWNER TO user_captura;

--
-- Name: programaticstructure_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: user_captura
--

ALTER SEQUENCE public.programaticstructure_id_seq OWNED BY public.programaticstructure.id;


--
-- Name: programaticstructure; Type: TABLE; Schema: dashboard; Owner: user_dashboard
--

CREATE TABLE dashboard.programaticstructure (
    id integer DEFAULT nextval('public.programaticstructure_id_seq'::regclass) NOT NULL,
    cve text,
    year integer,
    trimester integer,
    branch text,
    branch_desc text,
    finality text,
    finality_desc text,
    function text,
    function_desc text,
    subfunction text,
    subfunction_desc text,
    institutionalactivity text,
    institutionalactivity_desc text,
    budgetprogram text,
    budgetprogram_desc text,
    strategicobjective text,
    strategicobjective_desc text,
    responsibleunit text,
    responsibleunit_desc text,
    requestingunit text,
    requestingunit_desc text,
    spendingtype text,
    spendingtype_desc text,
    specificactivity text,
    specificactivity_desc text,
    spendingobject text,
    spendingobject_desc text,
    region text,
    region_desc text,
    budgetsource text,
    budgetsource_desc text,
    portfoliokey text,
    approvedamount numeric,
    modifiedamount numeric,
    executedamount numeric,
    committedamount numeric,
    reservedamount numeric
);


ALTER TABLE dashboard.programaticstructure OWNER TO user_dashboard;

--
-- Name: programaticstructure_id_seq; Type: SEQUENCE; Schema: dashboard; Owner: user_dashboard
--

CREATE SEQUENCE dashboard.programaticstructure_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE dashboard.programaticstructure_id_seq OWNER TO user_dashboard;

--
-- Name: publisher; Type: TABLE; Schema: public; Owner: user_captura
--

CREATE TABLE public.publisher (
    id integer NOT NULL,
    contractingprocess_id integer,
    name text,
    scheme text,
    uid text,
    uri text
);


ALTER TABLE public.publisher OWNER TO user_captura;

--
-- Name: publisher_id_seq; Type: SEQUENCE; Schema: public; Owner: user_captura
--

CREATE SEQUENCE public.publisher_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.publisher_id_seq OWNER TO user_captura;

--
-- Name: publisher_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: user_captura
--

ALTER SEQUENCE public.publisher_id_seq OWNED BY public.publisher.id;


--
-- Name: publisher; Type: TABLE; Schema: dashboard; Owner: user_dashboard
--

CREATE TABLE dashboard.publisher (
    id integer DEFAULT nextval('public.publisher_id_seq'::regclass) NOT NULL,
    contractingprocess_id integer,
    name text,
    scheme text,
    uid text,
    uri text
);


ALTER TABLE dashboard.publisher OWNER TO user_dashboard;

--
-- Name: publisher_id_seq; Type: SEQUENCE; Schema: dashboard; Owner: user_dashboard
--

CREATE SEQUENCE dashboard.publisher_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE dashboard.publisher_id_seq OWNER TO user_dashboard;

--
-- Name: quotes; Type: TABLE; Schema: public; Owner: user_captura
--

CREATE TABLE public.quotes (
    id integer NOT NULL,
    requestforquotes_id integer,
    quotes_id text,
    description text,
    date timestamp without time zone,
    value numeric,
    quoteperiod_startdate timestamp without time zone,
    quoteperiod_enddate timestamp without time zone,
    issuingsupplier_id integer
);


ALTER TABLE public.quotes OWNER TO user_captura;

--
-- Name: quotes_id_seq; Type: SEQUENCE; Schema: public; Owner: user_captura
--

CREATE SEQUENCE public.quotes_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.quotes_id_seq OWNER TO user_captura;

--
-- Name: quotes_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: user_captura
--

ALTER SEQUENCE public.quotes_id_seq OWNED BY public.quotes.id;


--
-- Name: quotes; Type: TABLE; Schema: dashboard; Owner: user_dashboard
--

CREATE TABLE dashboard.quotes (
    id integer DEFAULT nextval('public.quotes_id_seq'::regclass) NOT NULL,
    requestforquotes_id integer,
    quotes_id text,
    description text,
    date timestamp without time zone,
    value numeric,
    quoteperiod_startdate timestamp without time zone,
    quoteperiod_enddate timestamp without time zone,
    issuingsupplier_id integer
);


ALTER TABLE dashboard.quotes OWNER TO user_dashboard;

--
-- Name: quotes_id_seq; Type: SEQUENCE; Schema: dashboard; Owner: user_dashboard
--

CREATE SEQUENCE dashboard.quotes_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE dashboard.quotes_id_seq OWNER TO user_dashboard;

--
-- Name: quotesitems; Type: TABLE; Schema: public; Owner: user_captura
--

CREATE TABLE public.quotesitems (
    id integer NOT NULL,
    quotes_id integer,
    itemid text,
    item text,
    quantity numeric
);


ALTER TABLE public.quotesitems OWNER TO user_captura;

--
-- Name: quotesitems_id_seq; Type: SEQUENCE; Schema: public; Owner: user_captura
--

CREATE SEQUENCE public.quotesitems_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.quotesitems_id_seq OWNER TO user_captura;

--
-- Name: quotesitems_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: user_captura
--

ALTER SEQUENCE public.quotesitems_id_seq OWNED BY public.quotesitems.id;


--
-- Name: quotesitems; Type: TABLE; Schema: dashboard; Owner: user_dashboard
--

CREATE TABLE dashboard.quotesitems (
    id integer DEFAULT nextval('public.quotesitems_id_seq'::regclass) NOT NULL,
    quotes_id integer,
    itemid text,
    item text,
    quantity numeric
);


ALTER TABLE dashboard.quotesitems OWNER TO user_dashboard;

--
-- Name: quotesitems_id_seq; Type: SEQUENCE; Schema: dashboard; Owner: user_dashboard
--

CREATE SEQUENCE dashboard.quotesitems_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE dashboard.quotesitems_id_seq OWNER TO user_dashboard;

--
-- Name: relatedprocedure; Type: TABLE; Schema: public; Owner: user_captura
--

CREATE TABLE public.relatedprocedure (
    id integer NOT NULL,
    contractingprocess_id integer,
    relatedprocedure_id text,
    relationship_type text,
    title text,
    identifier_scheme text,
    relatedprocedure_identifier text,
    url text
);


ALTER TABLE public.relatedprocedure OWNER TO user_captura;

--
-- Name: relatedprocedure_id_seq; Type: SEQUENCE; Schema: public; Owner: user_captura
--

CREATE SEQUENCE public.relatedprocedure_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.relatedprocedure_id_seq OWNER TO user_captura;

--
-- Name: relatedprocedure_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: user_captura
--

ALTER SEQUENCE public.relatedprocedure_id_seq OWNED BY public.relatedprocedure.id;


--
-- Name: relatedprocedure; Type: TABLE; Schema: dashboard; Owner: user_dashboard
--

CREATE TABLE dashboard.relatedprocedure (
    id integer DEFAULT nextval('public.relatedprocedure_id_seq'::regclass) NOT NULL,
    contractingprocess_id integer,
    relatedprocedure_id text,
    relationship_type text,
    title text,
    identifier_scheme text,
    relatedprocedure_identifier text,
    url text
);


ALTER TABLE dashboard.relatedprocedure OWNER TO user_dashboard;

--
-- Name: relatedprocedure_id_seq; Type: SEQUENCE; Schema: dashboard; Owner: user_dashboard
--

CREATE SEQUENCE dashboard.relatedprocedure_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE dashboard.relatedprocedure_id_seq OWNER TO user_dashboard;

--
-- Name: requestforquotes; Type: TABLE; Schema: public; Owner: user_captura
--

CREATE TABLE public.requestforquotes (
    id integer NOT NULL,
    contractingprocess_id integer,
    planning_id integer,
    requestforquotes_id text,
    title text,
    description text,
    period_startdate timestamp without time zone,
    period_enddate timestamp without time zone
);


ALTER TABLE public.requestforquotes OWNER TO user_captura;

--
-- Name: requestforquotes_id_seq; Type: SEQUENCE; Schema: public; Owner: user_captura
--

CREATE SEQUENCE public.requestforquotes_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.requestforquotes_id_seq OWNER TO user_captura;

--
-- Name: requestforquotes_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: user_captura
--

ALTER SEQUENCE public.requestforquotes_id_seq OWNED BY public.requestforquotes.id;


--
-- Name: requestforquotes; Type: TABLE; Schema: dashboard; Owner: user_dashboard
--

CREATE TABLE dashboard.requestforquotes (
    id integer DEFAULT nextval('public.requestforquotes_id_seq'::regclass) NOT NULL,
    contractingprocess_id integer,
    planning_id integer,
    requestforquotes_id text,
    title text,
    description text,
    period_startdate timestamp without time zone,
    period_enddate timestamp without time zone
);


ALTER TABLE dashboard.requestforquotes OWNER TO user_dashboard;

--
-- Name: requestforquotes_id_seq; Type: SEQUENCE; Schema: dashboard; Owner: user_dashboard
--

CREATE SEQUENCE dashboard.requestforquotes_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE dashboard.requestforquotes_id_seq OWNER TO user_dashboard;

--
-- Name: requestforquotesinvitedsuppliers; Type: TABLE; Schema: public; Owner: user_captura
--

CREATE TABLE public.requestforquotesinvitedsuppliers (
    id integer NOT NULL,
    requestforquotes_id integer,
    parties_id integer
);


ALTER TABLE public.requestforquotesinvitedsuppliers OWNER TO user_captura;

--
-- Name: requestforquotesinvitedsuppliers_id_seq; Type: SEQUENCE; Schema: public; Owner: user_captura
--

CREATE SEQUENCE public.requestforquotesinvitedsuppliers_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.requestforquotesinvitedsuppliers_id_seq OWNER TO user_captura;

--
-- Name: requestforquotesinvitedsuppliers_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: user_captura
--

ALTER SEQUENCE public.requestforquotesinvitedsuppliers_id_seq OWNED BY public.requestforquotesinvitedsuppliers.id;


--
-- Name: requestforquotesinvitedsuppliers; Type: TABLE; Schema: dashboard; Owner: user_dashboard
--

CREATE TABLE dashboard.requestforquotesinvitedsuppliers (
    id integer DEFAULT nextval('public.requestforquotesinvitedsuppliers_id_seq'::regclass) NOT NULL,
    requestforquotes_id integer,
    parties_id integer
);


ALTER TABLE dashboard.requestforquotesinvitedsuppliers OWNER TO user_dashboard;

--
-- Name: requestforquotesinvitedsuppliers_id_seq; Type: SEQUENCE; Schema: dashboard; Owner: user_dashboard
--

CREATE SEQUENCE dashboard.requestforquotesinvitedsuppliers_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE dashboard.requestforquotesinvitedsuppliers_id_seq OWNER TO user_dashboard;

--
-- Name: requestforquotesitems; Type: TABLE; Schema: public; Owner: user_captura
--

CREATE TABLE public.requestforquotesitems (
    id integer NOT NULL,
    requestforquotes_id integer,
    itemid text,
    item text,
    quantity integer
);


ALTER TABLE public.requestforquotesitems OWNER TO user_captura;

--
-- Name: requestforquotesitems_id_seq; Type: SEQUENCE; Schema: public; Owner: user_captura
--

CREATE SEQUENCE public.requestforquotesitems_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.requestforquotesitems_id_seq OWNER TO user_captura;

--
-- Name: requestforquotesitems_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: user_captura
--

ALTER SEQUENCE public.requestforquotesitems_id_seq OWNED BY public.requestforquotesitems.id;


--
-- Name: requestforquotesitems; Type: TABLE; Schema: dashboard; Owner: user_dashboard
--

CREATE TABLE dashboard.requestforquotesitems (
    id integer DEFAULT nextval('public.requestforquotesitems_id_seq'::regclass) NOT NULL,
    requestforquotes_id integer,
    itemid text,
    item text,
    quantity integer
);


ALTER TABLE dashboard.requestforquotesitems OWNER TO user_dashboard;

--
-- Name: requestforquotesitems_id_seq; Type: SEQUENCE; Schema: dashboard; Owner: user_dashboard
--

CREATE SEQUENCE dashboard.requestforquotesitems_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE dashboard.requestforquotesitems_id_seq OWNER TO user_dashboard;

--
-- Name: rolecatalog; Type: TABLE; Schema: public; Owner: user_captura
--

CREATE TABLE public.rolecatalog (
    id integer NOT NULL,
    code text,
    title text,
    description text
);


ALTER TABLE public.rolecatalog OWNER TO user_captura;

--
-- Name: rolecatalog_id_seq; Type: SEQUENCE; Schema: public; Owner: user_captura
--

CREATE SEQUENCE public.rolecatalog_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.rolecatalog_id_seq OWNER TO user_captura;

--
-- Name: rolecatalog_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: user_captura
--

ALTER SEQUENCE public.rolecatalog_id_seq OWNED BY public.rolecatalog.id;


--
-- Name: rolecatalog; Type: TABLE; Schema: dashboard; Owner: user_dashboard
--

CREATE TABLE dashboard.rolecatalog (
    id integer DEFAULT nextval('public.rolecatalog_id_seq'::regclass) NOT NULL,
    code text,
    title text,
    description text
);


ALTER TABLE dashboard.rolecatalog OWNER TO user_dashboard;

--
-- Name: rolecatalog_id_seq; Type: SEQUENCE; Schema: dashboard; Owner: user_dashboard
--

CREATE SEQUENCE dashboard.rolecatalog_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE dashboard.rolecatalog_id_seq OWNER TO user_dashboard;

--
-- Name: roles; Type: TABLE; Schema: public; Owner: user_captura
--

CREATE TABLE public.roles (
    contractingprocess_id integer,
    parties_id integer,
    id integer NOT NULL,
    buyer boolean,
    procuringentity boolean,
    supplier boolean,
    tenderer boolean,
    funder boolean,
    enquirer boolean,
    payer boolean,
    payee boolean,
    reviewbody boolean,
    attendee boolean,
    official boolean,
    invitedsupplier boolean,
    issuingsupplier boolean,
    guarantor boolean,
    requestingunit boolean,
    contractingunit boolean,
    technicalunit boolean
);


ALTER TABLE public.roles OWNER TO user_captura;

--
-- Name: roles_id_seq; Type: SEQUENCE; Schema: public; Owner: user_captura
--

CREATE SEQUENCE public.roles_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.roles_id_seq OWNER TO user_captura;

--
-- Name: roles_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: user_captura
--

ALTER SEQUENCE public.roles_id_seq OWNED BY public.roles.id;


--
-- Name: roles; Type: TABLE; Schema: dashboard; Owner: user_dashboard
--

CREATE TABLE dashboard.roles (
    contractingprocess_id integer,
    parties_id integer,
    id integer DEFAULT nextval('public.roles_id_seq'::regclass) NOT NULL,
    buyer boolean,
    procuringentity boolean,
    supplier boolean,
    tenderer boolean,
    funder boolean,
    enquirer boolean,
    payer boolean,
    payee boolean,
    reviewbody boolean,
    attendee boolean,
    official boolean,
    invitedsupplier boolean,
    issuingsupplier boolean,
    guarantor boolean,
    requestingunit boolean,
    contractingunit boolean,
    technicalunit boolean
);


ALTER TABLE dashboard.roles OWNER TO user_dashboard;

--
-- Name: roles_id_seq; Type: SEQUENCE; Schema: dashboard; Owner: user_dashboard
--

CREATE SEQUENCE dashboard.roles_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE dashboard.roles_id_seq OWNER TO user_dashboard;

--
-- Name: tags; Type: TABLE; Schema: public; Owner: user_captura
--

CREATE TABLE public.tags (
    id integer NOT NULL,
    contractingprocess_id integer,
    planning boolean,
    planningupdate boolean,
    tender boolean,
    tenderamendment boolean,
    tenderupdate boolean,
    tendercancellation boolean,
    award boolean,
    awardupdate boolean,
    awardcancellation boolean,
    contract boolean,
    contractupdate boolean,
    contractamendment boolean,
    implementation boolean,
    implementationupdate boolean,
    contracttermination boolean,
    compiled boolean,
    stage integer,
    register_date timestamp without time zone
);


ALTER TABLE public.tags OWNER TO user_captura;

--
-- Name: tags_id_seq; Type: SEQUENCE; Schema: public; Owner: user_captura
--

CREATE SEQUENCE public.tags_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.tags_id_seq OWNER TO user_captura;

--
-- Name: tags_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: user_captura
--

ALTER SEQUENCE public.tags_id_seq OWNED BY public.tags.id;


--
-- Name: tags; Type: TABLE; Schema: dashboard; Owner: user_dashboard
--

CREATE TABLE dashboard.tags (
    id integer DEFAULT nextval('public.tags_id_seq'::regclass) NOT NULL,
    contractingprocess_id integer,
    planning boolean,
    planningupdate boolean,
    tender boolean,
    tenderamendment boolean,
    tenderupdate boolean,
    tendercancellation boolean,
    award boolean,
    awardupdate boolean,
    awardcancellation boolean,
    contract boolean,
    contractupdate boolean,
    contractamendment boolean,
    implementation boolean,
    implementationupdate boolean,
    contracttermination boolean,
    compiled boolean,
    stage integer,
    register_date timestamp without time zone
);


ALTER TABLE dashboard.tags OWNER TO user_dashboard;

--
-- Name: tags_id_seq; Type: SEQUENCE; Schema: dashboard; Owner: user_dashboard
--

CREATE SEQUENCE dashboard.tags_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE dashboard.tags_id_seq OWNER TO user_dashboard;

--
-- Name: tender; Type: TABLE; Schema: public; Owner: user_captura
--

CREATE TABLE public.tender (
    id integer NOT NULL,
    contractingprocess_id integer,
    tenderid text,
    title text,
    description text,
    status text,
    minvalue_amount numeric,
    minvalue_currency text,
    value_amount numeric,
    value_currency text,
    procurementmethod text,
    procurementmethod_details text,
    procurementmethod_rationale text,
    mainprocurementcategory text,
    additionalprocurementcategories text,
    awardcriteria text,
    awardcriteria_details text,
    submissionmethod text,
    submissionmethod_details text,
    tenderperiod_startdate timestamp without time zone,
    tenderperiod_enddate timestamp without time zone,
    enquiryperiod_startdate timestamp without time zone,
    enquiryperiod_enddate timestamp without time zone,
    hasenquiries boolean,
    eligibilitycriteria text,
    awardperiod_startdate timestamp without time zone,
    awardperiod_enddate timestamp without time zone,
    numberoftenderers integer,
    amendment_date timestamp without time zone,
    amendment_rationale text,
    procurementmethod_rationale_id text
);


ALTER TABLE public.tender OWNER TO user_captura;

--
-- Name: tender_id_seq; Type: SEQUENCE; Schema: public; Owner: user_captura
--

CREATE SEQUENCE public.tender_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.tender_id_seq OWNER TO user_captura;

--
-- Name: tender_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: user_captura
--

ALTER SEQUENCE public.tender_id_seq OWNED BY public.tender.id;


--
-- Name: tender; Type: TABLE; Schema: dashboard; Owner: user_dashboard
--

CREATE TABLE dashboard.tender (
    id integer DEFAULT nextval('public.tender_id_seq'::regclass) NOT NULL,
    contractingprocess_id integer,
    tenderid text,
    title text,
    description text,
    status text,
    minvalue_amount numeric,
    minvalue_currency text,
    value_amount numeric,
    value_currency text,
    procurementmethod text,
    procurementmethod_details text,
    procurementmethod_rationale text,
    mainprocurementcategory text,
    additionalprocurementcategories text,
    awardcriteria text,
    awardcriteria_details text,
    submissionmethod text,
    submissionmethod_details text,
    tenderperiod_startdate timestamp without time zone,
    tenderperiod_enddate timestamp without time zone,
    enquiryperiod_startdate timestamp without time zone,
    enquiryperiod_enddate timestamp without time zone,
    hasenquiries boolean,
    eligibilitycriteria text,
    awardperiod_startdate timestamp without time zone,
    awardperiod_enddate timestamp without time zone,
    numberoftenderers integer,
    amendment_date timestamp without time zone,
    amendment_rationale text,
    procurementmethod_rationale_id text
);


ALTER TABLE dashboard.tender OWNER TO user_dashboard;

--
-- Name: tender_id_seq; Type: SEQUENCE; Schema: dashboard; Owner: user_dashboard
--

CREATE SEQUENCE dashboard.tender_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE dashboard.tender_id_seq OWNER TO user_dashboard;

--
-- Name: tenderamendmentchanges; Type: TABLE; Schema: public; Owner: user_captura
--

CREATE TABLE public.tenderamendmentchanges (
    id integer NOT NULL,
    contractingprocess_id integer,
    tender_id integer,
    property text,
    former_value text,
    amendments_date timestamp without time zone,
    amendments_rationale text,
    amendments_id text,
    amendments_description text
);


ALTER TABLE public.tenderamendmentchanges OWNER TO user_captura;

--
-- Name: tenderamendmentchanges_id_seq; Type: SEQUENCE; Schema: public; Owner: user_captura
--

CREATE SEQUENCE public.tenderamendmentchanges_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.tenderamendmentchanges_id_seq OWNER TO user_captura;

--
-- Name: tenderamendmentchanges_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: user_captura
--

ALTER SEQUENCE public.tenderamendmentchanges_id_seq OWNED BY public.tenderamendmentchanges.id;


--
-- Name: tenderamendmentchanges; Type: TABLE; Schema: dashboard; Owner: user_dashboard
--

CREATE TABLE dashboard.tenderamendmentchanges (
    id integer DEFAULT nextval('public.tenderamendmentchanges_id_seq'::regclass) NOT NULL,
    contractingprocess_id integer,
    tender_id integer,
    property text,
    former_value text,
    amendments_date timestamp without time zone,
    amendments_rationale text,
    amendments_id text,
    amendments_description text
);


ALTER TABLE dashboard.tenderamendmentchanges OWNER TO user_dashboard;

--
-- Name: tenderamendmentchanges_id_seq; Type: SEQUENCE; Schema: dashboard; Owner: user_dashboard
--

CREATE SEQUENCE dashboard.tenderamendmentchanges_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE dashboard.tenderamendmentchanges_id_seq OWNER TO user_dashboard;

--
-- Name: tenderdocuments; Type: TABLE; Schema: public; Owner: user_captura
--

CREATE TABLE public.tenderdocuments (
    id integer NOT NULL,
    contractingprocess_id integer,
    tender_id integer,
    document_type text,
    documentid text,
    title text,
    description text,
    url text,
    date_published timestamp without time zone,
    date_modified timestamp without time zone,
    format text,
    language text
);


ALTER TABLE public.tenderdocuments OWNER TO user_captura;

--
-- Name: tenderdocuments_id_seq; Type: SEQUENCE; Schema: public; Owner: user_captura
--

CREATE SEQUENCE public.tenderdocuments_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.tenderdocuments_id_seq OWNER TO user_captura;

--
-- Name: tenderdocuments_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: user_captura
--

ALTER SEQUENCE public.tenderdocuments_id_seq OWNED BY public.tenderdocuments.id;


--
-- Name: tenderdocuments; Type: TABLE; Schema: dashboard; Owner: user_dashboard
--

CREATE TABLE dashboard.tenderdocuments (
    id integer DEFAULT nextval('public.tenderdocuments_id_seq'::regclass) NOT NULL,
    contractingprocess_id integer,
    tender_id integer,
    document_type text,
    documentid text,
    title text,
    description text,
    url text,
    date_published timestamp without time zone,
    date_modified timestamp without time zone,
    format text,
    language text
);


ALTER TABLE dashboard.tenderdocuments OWNER TO user_dashboard;

--
-- Name: tenderdocuments_id_seq; Type: SEQUENCE; Schema: dashboard; Owner: user_dashboard
--

CREATE SEQUENCE dashboard.tenderdocuments_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE dashboard.tenderdocuments_id_seq OWNER TO user_dashboard;

--
-- Name: tenderitem; Type: TABLE; Schema: public; Owner: user_captura
--

CREATE TABLE public.tenderitem (
    id integer NOT NULL,
    contractingprocess_id integer,
    tender_id integer,
    itemid text,
    description text,
    classification_scheme text,
    classification_id text,
    classification_description text,
    classification_uri text,
    quantity integer,
    unit_name text,
    unit_value_amount numeric,
    unit_value_currency text,
    unit_value_amountnet numeric,
    latitude double precision,
    longitude double precision,
    location_postalcode text,
    location_countryname text,
    location_streetaddress text,
    location_region text,
    location_locality text
);


ALTER TABLE public.tenderitem OWNER TO user_captura;

--
-- Name: tenderitem_id_seq; Type: SEQUENCE; Schema: public; Owner: user_captura
--

CREATE SEQUENCE public.tenderitem_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.tenderitem_id_seq OWNER TO user_captura;

--
-- Name: tenderitem_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: user_captura
--

ALTER SEQUENCE public.tenderitem_id_seq OWNED BY public.tenderitem.id;


--
-- Name: tenderitem; Type: TABLE; Schema: dashboard; Owner: user_dashboard
--

CREATE TABLE dashboard.tenderitem (
    id integer DEFAULT nextval('public.tenderitem_id_seq'::regclass) NOT NULL,
    contractingprocess_id integer,
    tender_id integer,
    itemid text,
    description text,
    classification_scheme text,
    classification_id text,
    classification_description text,
    classification_uri text,
    quantity integer,
    unit_name text,
    unit_value_amount numeric,
    unit_value_currency text,
    unit_value_amountnet numeric,
    latitude double precision,
    longitude double precision,
    location_postalcode text,
    location_countryname text,
    location_streetaddress text,
    location_region text,
    location_locality text
);


ALTER TABLE dashboard.tenderitem OWNER TO user_dashboard;

--
-- Name: tenderitem_id_seq; Type: SEQUENCE; Schema: dashboard; Owner: user_dashboard
--

CREATE SEQUENCE dashboard.tenderitem_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE dashboard.tenderitem_id_seq OWNER TO user_dashboard;

--
-- Name: tenderitemadditionalclassifications; Type: TABLE; Schema: public; Owner: user_captura
--

CREATE TABLE public.tenderitemadditionalclassifications (
    id integer NOT NULL,
    contractingprocess_id integer,
    tenderitem_id integer,
    scheme text,
    description text,
    uri text
);


ALTER TABLE public.tenderitemadditionalclassifications OWNER TO user_captura;

--
-- Name: tenderitemadditionalclassifications_id_seq; Type: SEQUENCE; Schema: public; Owner: user_captura
--

CREATE SEQUENCE public.tenderitemadditionalclassifications_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.tenderitemadditionalclassifications_id_seq OWNER TO user_captura;

--
-- Name: tenderitemadditionalclassifications_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: user_captura
--

ALTER SEQUENCE public.tenderitemadditionalclassifications_id_seq OWNED BY public.tenderitemadditionalclassifications.id;


--
-- Name: tenderitemadditionalclassifications; Type: TABLE; Schema: dashboard; Owner: user_dashboard
--

CREATE TABLE dashboard.tenderitemadditionalclassifications (
    id integer DEFAULT nextval('public.tenderitemadditionalclassifications_id_seq'::regclass) NOT NULL,
    contractingprocess_id integer,
    tenderitem_id integer,
    scheme text,
    description text,
    uri text
);


ALTER TABLE dashboard.tenderitemadditionalclassifications OWNER TO user_dashboard;

--
-- Name: tenderitemadditionalclassifications_id_seq; Type: SEQUENCE; Schema: dashboard; Owner: user_dashboard
--

CREATE SEQUENCE dashboard.tenderitemadditionalclassifications_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE dashboard.tenderitemadditionalclassifications_id_seq OWNER TO user_dashboard;

--
-- Name: tendermilestone; Type: TABLE; Schema: public; Owner: user_captura
--

CREATE TABLE public.tendermilestone (
    id integer NOT NULL,
    contractingprocess_id integer,
    tender_id integer,
    milestoneid text,
    title text,
    description text,
    duedate timestamp without time zone,
    date_modified timestamp without time zone,
    status text,
    type text
);


ALTER TABLE public.tendermilestone OWNER TO user_captura;

--
-- Name: tendermilestone_id_seq; Type: SEQUENCE; Schema: public; Owner: user_captura
--

CREATE SEQUENCE public.tendermilestone_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.tendermilestone_id_seq OWNER TO user_captura;

--
-- Name: tendermilestone_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: user_captura
--

ALTER SEQUENCE public.tendermilestone_id_seq OWNED BY public.tendermilestone.id;


--
-- Name: tendermilestone; Type: TABLE; Schema: dashboard; Owner: user_dashboard
--

CREATE TABLE dashboard.tendermilestone (
    id integer DEFAULT nextval('public.tendermilestone_id_seq'::regclass) NOT NULL,
    contractingprocess_id integer,
    tender_id integer,
    milestoneid text,
    title text,
    description text,
    duedate timestamp without time zone,
    date_modified timestamp without time zone,
    status text,
    type text
);


ALTER TABLE dashboard.tendermilestone OWNER TO user_dashboard;

--
-- Name: tendermilestone_id_seq; Type: SEQUENCE; Schema: dashboard; Owner: user_dashboard
--

CREATE SEQUENCE dashboard.tendermilestone_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE dashboard.tendermilestone_id_seq OWNER TO user_dashboard;

--
-- Name: tendermilestonedocuments; Type: TABLE; Schema: public; Owner: user_captura
--

CREATE TABLE public.tendermilestonedocuments (
    id integer NOT NULL,
    contractingprocess_id integer,
    tender_id integer,
    milestone_id integer,
    document_type text,
    documentid text,
    title text,
    description text,
    url text,
    date_published timestamp without time zone,
    date_modified timestamp without time zone,
    format text,
    language text
);


ALTER TABLE public.tendermilestonedocuments OWNER TO user_captura;

--
-- Name: tendermilestonedocuments_id_seq; Type: SEQUENCE; Schema: public; Owner: user_captura
--

CREATE SEQUENCE public.tendermilestonedocuments_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.tendermilestonedocuments_id_seq OWNER TO user_captura;

--
-- Name: tendermilestonedocuments_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: user_captura
--

ALTER SEQUENCE public.tendermilestonedocuments_id_seq OWNED BY public.tendermilestonedocuments.id;


--
-- Name: tendermilestonedocuments; Type: TABLE; Schema: dashboard; Owner: user_dashboard
--

CREATE TABLE dashboard.tendermilestonedocuments (
    id integer DEFAULT nextval('public.tendermilestonedocuments_id_seq'::regclass) NOT NULL,
    contractingprocess_id integer,
    tender_id integer,
    milestone_id integer,
    document_type text,
    documentid text,
    title text,
    description text,
    url text,
    date_published timestamp without time zone,
    date_modified timestamp without time zone,
    format text,
    language text
);


ALTER TABLE dashboard.tendermilestonedocuments OWNER TO user_dashboard;

--
-- Name: tendermilestonedocuments_id_seq; Type: SEQUENCE; Schema: dashboard; Owner: user_dashboard
--

CREATE SEQUENCE dashboard.tendermilestonedocuments_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE dashboard.tendermilestonedocuments_id_seq OWNER TO user_dashboard;

--
-- Name: user_contractingprocess; Type: TABLE; Schema: public; Owner: user_captura
--

CREATE TABLE public.user_contractingprocess (
    id integer NOT NULL,
    user_id text,
    contractingprocess_id integer
);


ALTER TABLE public.user_contractingprocess OWNER TO user_captura;

--
-- Name: user_contractingprocess_id_seq; Type: SEQUENCE; Schema: public; Owner: user_captura
--

CREATE SEQUENCE public.user_contractingprocess_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.user_contractingprocess_id_seq OWNER TO user_captura;

--
-- Name: user_contractingprocess_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: user_captura
--

ALTER SEQUENCE public.user_contractingprocess_id_seq OWNED BY public.user_contractingprocess.id;


--
-- Name: user_contractingprocess; Type: TABLE; Schema: dashboard; Owner: user_dashboard
--

CREATE TABLE dashboard.user_contractingprocess (
    id integer DEFAULT nextval('public.user_contractingprocess_id_seq'::regclass) NOT NULL,
    user_id text,
    contractingprocess_id integer
);


ALTER TABLE dashboard.user_contractingprocess OWNER TO user_dashboard;

--
-- Name: user_contractingprocess_id_seq; Type: SEQUENCE; Schema: dashboard; Owner: user_dashboard
--

CREATE SEQUENCE dashboard.user_contractingprocess_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE dashboard.user_contractingprocess_id_seq OWNER TO user_dashboard;

--
-- Name: metadata; Type: TABLE; Schema: public; Owner: user_captura
--

CREATE TABLE public.metadata (
    field_name character varying(50) NOT NULL,
    value text
);


ALTER TABLE public.metadata OWNER TO user_captura;

--
-- Name: additionalcontactpoints id; Type: DEFAULT; Schema: public; Owner: user_captura
--

ALTER TABLE ONLY public.additionalcontactpoints ALTER COLUMN id SET DEFAULT nextval('public.additionalcontactpoints_id_seq'::regclass);


--
-- Name: award id; Type: DEFAULT; Schema: public; Owner: user_captura
--

ALTER TABLE ONLY public.award ALTER COLUMN id SET DEFAULT nextval('public.award_id_seq'::regclass);


--
-- Name: awardamendmentchanges id; Type: DEFAULT; Schema: public; Owner: user_captura
--

ALTER TABLE ONLY public.awardamendmentchanges ALTER COLUMN id SET DEFAULT nextval('public.awardamendmentchanges_id_seq'::regclass);


--
-- Name: awarddocuments id; Type: DEFAULT; Schema: public; Owner: user_captura
--

ALTER TABLE ONLY public.awarddocuments ALTER COLUMN id SET DEFAULT nextval('public.awarddocuments_id_seq'::regclass);


--
-- Name: awarditem id; Type: DEFAULT; Schema: public; Owner: user_captura
--

ALTER TABLE ONLY public.awarditem ALTER COLUMN id SET DEFAULT nextval('public.awarditem_id_seq'::regclass);


--
-- Name: awarditemadditionalclassifications id; Type: DEFAULT; Schema: public; Owner: user_captura
--

ALTER TABLE ONLY public.awarditemadditionalclassifications ALTER COLUMN id SET DEFAULT nextval('public.awarditemadditionalclassifications_id_seq'::regclass);


--
-- Name: awardsupplier id; Type: DEFAULT; Schema: public; Owner: user_captura
--

ALTER TABLE ONLY public.awardsupplier ALTER COLUMN id SET DEFAULT nextval('public.awardsupplier_id_seq'::regclass);


--
-- Name: budget id; Type: DEFAULT; Schema: public; Owner: user_captura
--

ALTER TABLE ONLY public.budget ALTER COLUMN id SET DEFAULT nextval('public.budget_id_seq'::regclass);


--
-- Name: budgetbreakdown id; Type: DEFAULT; Schema: public; Owner: user_captura
--

ALTER TABLE ONLY public.budgetbreakdown ALTER COLUMN id SET DEFAULT nextval('public.budgetbreakdown_id_seq'::regclass);


--
-- Name: budgetclassifications id; Type: DEFAULT; Schema: public; Owner: user_captura
--

ALTER TABLE ONLY public.budgetclassifications ALTER COLUMN id SET DEFAULT nextval('public.budgetclassifications_id_seq'::regclass);


--
-- Name: clarificationmeeting id; Type: DEFAULT; Schema: public; Owner: user_captura
--

ALTER TABLE ONLY public.clarificationmeeting ALTER COLUMN id SET DEFAULT nextval('public.clarificationmeeting_id_seq'::regclass);


--
-- Name: clarificationmeetingactor id; Type: DEFAULT; Schema: public; Owner: user_captura
--

ALTER TABLE ONLY public.clarificationmeetingactor ALTER COLUMN id SET DEFAULT nextval('public.clarificationmeetingactor_id_seq'::regclass);


--
-- Name: contract id; Type: DEFAULT; Schema: public; Owner: user_captura
--

ALTER TABLE ONLY public.contract ALTER COLUMN id SET DEFAULT nextval('public.contract_id_seq'::regclass);


--
-- Name: contractamendmentchanges id; Type: DEFAULT; Schema: public; Owner: user_captura
--

ALTER TABLE ONLY public.contractamendmentchanges ALTER COLUMN id SET DEFAULT nextval('public.contractamendmentchanges_id_seq'::regclass);


--
-- Name: contractdocuments id; Type: DEFAULT; Schema: public; Owner: user_captura
--

ALTER TABLE ONLY public.contractdocuments ALTER COLUMN id SET DEFAULT nextval('public.contractdocuments_id_seq'::regclass);


--
-- Name: contractingprocess id; Type: DEFAULT; Schema: public; Owner: user_captura
--

ALTER TABLE ONLY public.contractingprocess ALTER COLUMN id SET DEFAULT nextval('public.contractingprocess_id_seq'::regclass);


--
-- Name: contractitem id; Type: DEFAULT; Schema: public; Owner: user_captura
--

ALTER TABLE ONLY public.contractitem ALTER COLUMN id SET DEFAULT nextval('public.contractitem_id_seq'::regclass);


--
-- Name: contractitemadditionalclasifications id; Type: DEFAULT; Schema: public; Owner: user_captura
--

ALTER TABLE ONLY public.contractitemadditionalclasifications ALTER COLUMN id SET DEFAULT nextval('public.contractitemadditionalclasifications_id_seq'::regclass);


--
-- Name: currency id; Type: DEFAULT; Schema: public; Owner: user_captura
--

ALTER TABLE ONLY public.currency ALTER COLUMN id SET DEFAULT nextval('public.currency_id_seq'::regclass);


--
-- Name: documentformat id; Type: DEFAULT; Schema: public; Owner: user_captura
--

ALTER TABLE ONLY public.documentformat ALTER COLUMN id SET DEFAULT nextval('public.documentformat_id_seq'::regclass);


--
-- Name: documentmanagement id; Type: DEFAULT; Schema: public; Owner: user_captura
--

ALTER TABLE ONLY public.documentmanagement ALTER COLUMN id SET DEFAULT nextval('public.documentmanagement_id_seq'::regclass);


--
-- Name: documenttype id; Type: DEFAULT; Schema: public; Owner: user_captura
--

ALTER TABLE ONLY public.documenttype ALTER COLUMN id SET DEFAULT nextval('public.documenttype_id_seq'::regclass);


--
-- Name: gdmx_dictionary id; Type: DEFAULT; Schema: public; Owner: user_captura
--

ALTER TABLE ONLY public.gdmx_dictionary ALTER COLUMN id SET DEFAULT nextval('public.gdmx_dictionary_id_seq'::regclass);


--
-- Name: gdmx_document id; Type: DEFAULT; Schema: public; Owner: user_captura
--

ALTER TABLE ONLY public.gdmx_document ALTER COLUMN id SET DEFAULT nextval('public.gdmx_document_id_seq'::regclass);


--
-- Name: guarantees id; Type: DEFAULT; Schema: public; Owner: user_captura
--

ALTER TABLE ONLY public.guarantees ALTER COLUMN id SET DEFAULT nextval('public.guarantees_id_seq'::regclass);


--
-- Name: implementation id; Type: DEFAULT; Schema: public; Owner: user_captura
--

ALTER TABLE ONLY public.implementation ALTER COLUMN id SET DEFAULT nextval('public.implementation_id_seq'::regclass);


--
-- Name: implementationdocuments id; Type: DEFAULT; Schema: public; Owner: user_captura
--

ALTER TABLE ONLY public.implementationdocuments ALTER COLUMN id SET DEFAULT nextval('public.implementationdocuments_id_seq'::regclass);


--
-- Name: implementationmilestone id; Type: DEFAULT; Schema: public; Owner: user_captura
--

ALTER TABLE ONLY public.implementationmilestone ALTER COLUMN id SET DEFAULT nextval('public.implementationmilestone_id_seq'::regclass);


--
-- Name: implementationmilestonedocuments id; Type: DEFAULT; Schema: public; Owner: user_captura
--

ALTER TABLE ONLY public.implementationmilestonedocuments ALTER COLUMN id SET DEFAULT nextval('public.implementationmilestonedocuments_id_seq'::regclass);


--
-- Name: implementationstatus id; Type: DEFAULT; Schema: public; Owner: user_captura
--

ALTER TABLE ONLY public.implementationstatus ALTER COLUMN id SET DEFAULT nextval('public.implementationstatus_id_seq'::regclass);


--
-- Name: implementationtransactions id; Type: DEFAULT; Schema: public; Owner: user_captura
--

ALTER TABLE ONLY public.implementationtransactions ALTER COLUMN id SET DEFAULT nextval('public.implementationtransactions_id_seq'::regclass);


--
-- Name: item id; Type: DEFAULT; Schema: public; Owner: user_captura
--

ALTER TABLE ONLY public.item ALTER COLUMN id SET DEFAULT nextval('public.item_id_seq'::regclass);


--
-- Name: language id; Type: DEFAULT; Schema: public; Owner: user_captura
--

ALTER TABLE ONLY public.language ALTER COLUMN id SET DEFAULT nextval('public.language_id_seq'::regclass);


--
-- Name: links id; Type: DEFAULT; Schema: public; Owner: user_captura
--

ALTER TABLE ONLY public.links ALTER COLUMN id SET DEFAULT nextval('public.links_id_seq'::regclass);


--
-- Name: log_gdmx id; Type: DEFAULT; Schema: public; Owner: user_captura
--

ALTER TABLE ONLY public.log_gdmx ALTER COLUMN id SET DEFAULT nextval('public.log_gdmx_id_seq'::regclass);


--
-- Name: logs id; Type: DEFAULT; Schema: public; Owner: user_captura
--

ALTER TABLE ONLY public.logs ALTER COLUMN id SET DEFAULT nextval('public.logs_id_seq'::regclass);


--
-- Name: memberof id; Type: DEFAULT; Schema: public; Owner: user_captura
--

ALTER TABLE ONLY public.memberof ALTER COLUMN id SET DEFAULT nextval('public.memberof_id_seq'::regclass);


--
-- Name: milestonetype id; Type: DEFAULT; Schema: public; Owner: user_captura
--

ALTER TABLE ONLY public.milestonetype ALTER COLUMN id SET DEFAULT nextval('public.milestonetype_id_seq'::regclass);


--
-- Name: parties id; Type: DEFAULT; Schema: public; Owner: user_captura
--

ALTER TABLE ONLY public.parties ALTER COLUMN id SET DEFAULT nextval('public.parties_id_seq'::regclass);


--
-- Name: partiesadditionalidentifiers id; Type: DEFAULT; Schema: public; Owner: user_captura
--

ALTER TABLE ONLY public.partiesadditionalidentifiers ALTER COLUMN id SET DEFAULT nextval('public.partiesadditionalidentifiers_id_seq'::regclass);


--
-- Name: paymentmethod id; Type: DEFAULT; Schema: public; Owner: user_captura
--

ALTER TABLE ONLY public.paymentmethod ALTER COLUMN id SET DEFAULT nextval('public.paymentmethod_id_seq'::regclass);


--
-- Name: planning id; Type: DEFAULT; Schema: public; Owner: user_captura
--

ALTER TABLE ONLY public.planning ALTER COLUMN id SET DEFAULT nextval('public.planning_id_seq'::regclass);


--
-- Name: planningdocuments id; Type: DEFAULT; Schema: public; Owner: user_captura
--

ALTER TABLE ONLY public.planningdocuments ALTER COLUMN id SET DEFAULT nextval('public.planningdocuments_id_seq'::regclass);


--
-- Name: pntreference id; Type: DEFAULT; Schema: public; Owner: user_captura
--

ALTER TABLE ONLY public.pntreference ALTER COLUMN id SET DEFAULT nextval('public.pntreference_id_seq'::regclass);


--
-- Name: prefixocid id; Type: DEFAULT; Schema: public; Owner: user_captura
--

ALTER TABLE ONLY public.prefixocid ALTER COLUMN id SET DEFAULT nextval('public.prefixocid_id_seq'::regclass);


--
-- Name: programaticstructure id; Type: DEFAULT; Schema: public; Owner: user_captura
--

ALTER TABLE ONLY public.programaticstructure ALTER COLUMN id SET DEFAULT nextval('public.programaticstructure_id_seq'::regclass);


--
-- Name: publisher id; Type: DEFAULT; Schema: public; Owner: user_captura
--

ALTER TABLE ONLY public.publisher ALTER COLUMN id SET DEFAULT nextval('public.publisher_id_seq'::regclass);


--
-- Name: quotes id; Type: DEFAULT; Schema: public; Owner: user_captura
--

ALTER TABLE ONLY public.quotes ALTER COLUMN id SET DEFAULT nextval('public.quotes_id_seq'::regclass);


--
-- Name: quotesitems id; Type: DEFAULT; Schema: public; Owner: user_captura
--

ALTER TABLE ONLY public.quotesitems ALTER COLUMN id SET DEFAULT nextval('public.quotesitems_id_seq'::regclass);


--
-- Name: relatedprocedure id; Type: DEFAULT; Schema: public; Owner: user_captura
--

ALTER TABLE ONLY public.relatedprocedure ALTER COLUMN id SET DEFAULT nextval('public.relatedprocedure_id_seq'::regclass);


--
-- Name: requestforquotes id; Type: DEFAULT; Schema: public; Owner: user_captura
--

ALTER TABLE ONLY public.requestforquotes ALTER COLUMN id SET DEFAULT nextval('public.requestforquotes_id_seq'::regclass);


--
-- Name: requestforquotesinvitedsuppliers id; Type: DEFAULT; Schema: public; Owner: user_captura
--

ALTER TABLE ONLY public.requestforquotesinvitedsuppliers ALTER COLUMN id SET DEFAULT nextval('public.requestforquotesinvitedsuppliers_id_seq'::regclass);


--
-- Name: requestforquotesitems id; Type: DEFAULT; Schema: public; Owner: user_captura
--

ALTER TABLE ONLY public.requestforquotesitems ALTER COLUMN id SET DEFAULT nextval('public.requestforquotesitems_id_seq'::regclass);


--
-- Name: rolecatalog id; Type: DEFAULT; Schema: public; Owner: user_captura
--

ALTER TABLE ONLY public.rolecatalog ALTER COLUMN id SET DEFAULT nextval('public.rolecatalog_id_seq'::regclass);


--
-- Name: roles id; Type: DEFAULT; Schema: public; Owner: user_captura
--

ALTER TABLE ONLY public.roles ALTER COLUMN id SET DEFAULT nextval('public.roles_id_seq'::regclass);


--
-- Name: tags id; Type: DEFAULT; Schema: public; Owner: user_captura
--

ALTER TABLE ONLY public.tags ALTER COLUMN id SET DEFAULT nextval('public.tags_id_seq'::regclass);


--
-- Name: tender id; Type: DEFAULT; Schema: public; Owner: user_captura
--

ALTER TABLE ONLY public.tender ALTER COLUMN id SET DEFAULT nextval('public.tender_id_seq'::regclass);


--
-- Name: tenderamendmentchanges id; Type: DEFAULT; Schema: public; Owner: user_captura
--

ALTER TABLE ONLY public.tenderamendmentchanges ALTER COLUMN id SET DEFAULT nextval('public.tenderamendmentchanges_id_seq'::regclass);


--
-- Name: tenderdocuments id; Type: DEFAULT; Schema: public; Owner: user_captura
--

ALTER TABLE ONLY public.tenderdocuments ALTER COLUMN id SET DEFAULT nextval('public.tenderdocuments_id_seq'::regclass);


--
-- Name: tenderitem id; Type: DEFAULT; Schema: public; Owner: user_captura
--

ALTER TABLE ONLY public.tenderitem ALTER COLUMN id SET DEFAULT nextval('public.tenderitem_id_seq'::regclass);


--
-- Name: tenderitemadditionalclassifications id; Type: DEFAULT; Schema: public; Owner: user_captura
--

ALTER TABLE ONLY public.tenderitemadditionalclassifications ALTER COLUMN id SET DEFAULT nextval('public.tenderitemadditionalclassifications_id_seq'::regclass);


--
-- Name: tendermilestone id; Type: DEFAULT; Schema: public; Owner: user_captura
--

ALTER TABLE ONLY public.tendermilestone ALTER COLUMN id SET DEFAULT nextval('public.tendermilestone_id_seq'::regclass);


--
-- Name: tendermilestonedocuments id; Type: DEFAULT; Schema: public; Owner: user_captura
--

ALTER TABLE ONLY public.tendermilestonedocuments ALTER COLUMN id SET DEFAULT nextval('public.tendermilestonedocuments_id_seq'::regclass);


--
-- Name: user_contractingprocess id; Type: DEFAULT; Schema: public; Owner: user_captura
--

ALTER TABLE ONLY public.user_contractingprocess ALTER COLUMN id SET DEFAULT nextval('public.user_contractingprocess_id_seq'::regclass);


--
-- Data for Name: additionalcontactpoints; Type: TABLE DATA; Schema: dashboard; Owner: user_dashboard
--

COPY dashboard.additionalcontactpoints (id, party_id, type, name, givenname, surname, additionalsurname, email, telephone, faxnumber, url, language) FROM stdin;
\.


--
-- Data for Name: award; Type: TABLE DATA; Schema: dashboard; Owner: user_dashboard
--

COPY dashboard.award (id, contractingprocess_id, awardid, title, description, rationale, status, award_date, value_amount, value_currency, contractperiod_startdate, contractperiod_enddate, amendment_date, amendment_rationale, value_amountnet, datelastupdate) FROM stdin;
\.


--
-- Data for Name: awardamendmentchanges; Type: TABLE DATA; Schema: dashboard; Owner: user_dashboard
--

COPY dashboard.awardamendmentchanges (id, contractingprocess_id, award_id, property, former_value, amendments_date, amendments_rationale, amendments_id, amendments_description) FROM stdin;
\.


--
-- Data for Name: awarddocuments; Type: TABLE DATA; Schema: dashboard; Owner: user_dashboard
--

COPY dashboard.awarddocuments (id, contractingprocess_id, award_id, document_type, documentid, title, description, url, date_published, date_modified, format, language) FROM stdin;
\.


--
-- Data for Name: awarditem; Type: TABLE DATA; Schema: dashboard; Owner: user_dashboard
--

COPY dashboard.awarditem (id, contractingprocess_id, award_id, itemid, description, classification_scheme, classification_id, classification_description, classification_uri, quantity, unit_name, unit_value_amount, unit_value_currency, unit_value_amountnet, latitude, longitude, location_postalcode, location_countryname, location_streetaddress, location_region, location_locality) FROM stdin;
\.


--
-- Data for Name: awarditemadditionalclassifications; Type: TABLE DATA; Schema: dashboard; Owner: user_dashboard
--

COPY dashboard.awarditemadditionalclassifications (id, award_id, awarditem_id, scheme, description, uri) FROM stdin;
\.


--
-- Data for Name: awardsupplier; Type: TABLE DATA; Schema: dashboard; Owner: user_dashboard
--

COPY dashboard.awardsupplier (id, award_id, parties_id) FROM stdin;
\.


--
-- Data for Name: budget; Type: TABLE DATA; Schema: dashboard; Owner: user_dashboard
--

COPY dashboard.budget (id, contractingprocess_id, planning_id, budget_source, budget_budgetid, budget_description, budget_amount, budget_currency, budget_project, budget_projectid, budget_uri) FROM stdin;
\.


--
-- Data for Name: budgetbreakdown; Type: TABLE DATA; Schema: dashboard; Owner: user_dashboard
--

COPY dashboard.budgetbreakdown (id, contractingprocess_id, planning_id, budgetbreakdown_id, description, amount, currency, url, budgetbreakdownperiod_startdate, budgetbreakdownperiod_enddate, source_id) FROM stdin;
\.


--
-- Data for Name: budgetclassifications; Type: TABLE DATA; Schema: dashboard; Owner: user_dashboard
--

COPY dashboard.budgetclassifications (id, budgetbreakdown_id, year, branch, responsibleunit, finality, function, subfunction, institutionalactivity, budgetprogram, strategicobjective, requestingunit, specificactivity, spendingobject, spendingtype, budgetsource, region, portfoliokey, cve, approved, modified, executed, committed, reserved) FROM stdin;
\.


--
-- Data for Name: clarificationmeeting; Type: TABLE DATA; Schema: dashboard; Owner: user_dashboard
--

COPY dashboard.clarificationmeeting (id, clarificationmeetingid, contractingprocess_id, date) FROM stdin;
\.


--
-- Data for Name: clarificationmeetingactor; Type: TABLE DATA; Schema: dashboard; Owner: user_dashboard
--

COPY dashboard.clarificationmeetingactor (id, clarificationmeeting_id, parties_id, attender, official) FROM stdin;
\.


--
-- Data for Name: contract; Type: TABLE DATA; Schema: dashboard; Owner: user_dashboard
--

COPY dashboard.contract (id, contractingprocess_id, awardid, contractid, title, description, status, period_startdate, period_enddate, value_amount, value_currency, datesigned, amendment_date, amendment_rationale, value_amountnet, exchangerate_rate, exchangerate_amount, exchangerate_currency, exchangerate_date, exchangerate_source, datelastupdate, surveillancemechanisms) FROM stdin;
\.


--
-- Data for Name: contractamendmentchanges; Type: TABLE DATA; Schema: dashboard; Owner: user_dashboard
--

COPY dashboard.contractamendmentchanges (id, contractingprocess_id, contract_id, amendments_date, amendments_rationale, amendments_id, amendments_description) FROM stdin;
\.


--
-- Data for Name: contractdocuments; Type: TABLE DATA; Schema: dashboard; Owner: user_dashboard
--

COPY dashboard.contractdocuments (id, contractingprocess_id, contract_id, document_type, documentid, title, description, url, date_published, date_modified, format, language) FROM stdin;
\.


--
-- Data for Name: contractingprocess; Type: TABLE DATA; Schema: dashboard; Owner: user_dashboard
--

COPY dashboard.contractingprocess (id, ocid, description, destino, fecha_creacion, hora_creacion, stage, uri, publicationpolicy, license, awardstatus, contractstatus, implementationstatus, published, valid, date_published, requirepntupdate, pnt_dateupdate, publisher, updated, updated_date, updated_version, published_version, pnt_published, pnt_version, pnt_date) FROM stdin;
\.


--
-- Data for Name: contractitem; Type: TABLE DATA; Schema: dashboard; Owner: user_dashboard
--

COPY dashboard.contractitem (id, contractingprocess_id, contract_id, itemid, description, classification_scheme, classification_id, classification_description, classification_uri, quantity, unit_name, unit_value_amount, unit_value_currency, unit_value_amountnet, latitude, longitude, location_postalcode, location_countryname, location_streetaddress, location_region, location_locality) FROM stdin;
\.


--
-- Data for Name: contractitemadditionalclasifications; Type: TABLE DATA; Schema: dashboard; Owner: user_dashboard
--

COPY dashboard.contractitemadditionalclasifications (id, contractingprocess_id, contract_id, contractitem_id, scheme, description, uri) FROM stdin;
\.


--
-- Data for Name: currency; Type: TABLE DATA; Schema: dashboard; Owner: user_dashboard
--

COPY dashboard.currency (id, entity, currency, currency_eng, alphabetic_code, numeric_code, minor_unit) FROM stdin;
\.


--
-- Data for Name: documentformat; Type: TABLE DATA; Schema: dashboard; Owner: user_dashboard
--

COPY dashboard.documentformat (id, category, name, template, reference) FROM stdin;
\.


--
-- Data for Name: documentmanagement; Type: TABLE DATA; Schema: dashboard; Owner: user_dashboard
--

COPY dashboard.documentmanagement (id, contractingprocess_id, origin, document, instance_id, type, register_date) FROM stdin;
\.


--
-- Data for Name: documenttype; Type: TABLE DATA; Schema: dashboard; Owner: user_dashboard
--

COPY dashboard.documenttype (id, category, code, title, title_esp, description, source, stage) FROM stdin;
\.


--
-- Data for Name: gdmx_dictionary; Type: TABLE DATA; Schema: dashboard; Owner: user_dashboard
--

COPY dashboard.gdmx_dictionary (id, document, variable, tablename, field, parent, type, index, classification, catalog, catalog_field, storeprocedure) FROM stdin;
\.


--
-- Data for Name: gdmx_document; Type: TABLE DATA; Schema: dashboard; Owner: user_dashboard
--

COPY dashboard.gdmx_document (id, name, stage, type, tablename, identifier) FROM stdin;
\.


--
-- Data for Name: guarantees; Type: TABLE DATA; Schema: dashboard; Owner: user_dashboard
--

COPY dashboard.guarantees (id, contractingprocess_id, contract_id, guarantee_id, guaranteetype, date, guaranteedobligations, value, guarantor, guaranteeperiod_startdate, guaranteeperiod_enddate, currency) FROM stdin;
\.


--
-- Data for Name: implementation; Type: TABLE DATA; Schema: dashboard; Owner: user_dashboard
--

COPY dashboard.implementation (id, contractingprocess_id, contract_id, status, datelastupdate) FROM stdin;
\.


--
-- Data for Name: implementationdocuments; Type: TABLE DATA; Schema: dashboard; Owner: user_dashboard
--

COPY dashboard.implementationdocuments (id, contractingprocess_id, contract_id, implementation_id, document_type, documentid, title, description, url, date_published, date_modified, format, language) FROM stdin;
\.


--
-- Data for Name: implementationmilestone; Type: TABLE DATA; Schema: dashboard; Owner: user_dashboard
--

COPY dashboard.implementationmilestone (id, contractingprocess_id, contract_id, implementation_id, milestoneid, title, description, duedate, date_modified, status, type) FROM stdin;
\.


--
-- Data for Name: implementationmilestonedocuments; Type: TABLE DATA; Schema: dashboard; Owner: user_dashboard
--

COPY dashboard.implementationmilestonedocuments (id, contractingprocess_id, contract_id, implementation_id, document_type, documentid, title, description, url, date_published, date_modified, format, language) FROM stdin;
\.


--
-- Data for Name: implementationstatus; Type: TABLE DATA; Schema: dashboard; Owner: user_dashboard
--

COPY dashboard.implementationstatus (id, code, title, title_esp, description) FROM stdin;
\.


--
-- Data for Name: implementationtransactions; Type: TABLE DATA; Schema: dashboard; Owner: user_dashboard
--

COPY dashboard.implementationtransactions (id, contractingprocess_id, contract_id, implementation_id, transactionid, source, implementation_date, value_amount, value_currency, payment_method, uri, payer_name, payer_id, payee_name, payee_id, value_amountnet) FROM stdin;
\.


--
-- Data for Name: item; Type: TABLE DATA; Schema: dashboard; Owner: user_dashboard
--

COPY dashboard.item (id, classificationid, description, unit) FROM stdin;
\.


--
-- Data for Name: language; Type: TABLE DATA; Schema: dashboard; Owner: user_dashboard
--

COPY dashboard.language (id, alpha2, name) FROM stdin;
\.


--
-- Data for Name: links; Type: TABLE DATA; Schema: dashboard; Owner: user_dashboard
--

COPY dashboard.links (id, json, xlsx, pdf, contractingprocess_id) FROM stdin;
\.


--
-- Data for Name: log_gdmx; Type: TABLE DATA; Schema: dashboard; Owner: user_dashboard
--

COPY dashboard.log_gdmx (id, date, cp, recordid, record) FROM stdin;
\.


--
-- Data for Name: logs; Type: TABLE DATA; Schema: dashboard; Owner: user_dashboard
--

COPY dashboard.logs (id, version, update_date, publisher, release_file, release_json, record_json, contractingprocess_id, version_json, published) FROM stdin;
\.


--
-- Data for Name: memberof; Type: TABLE DATA; Schema: dashboard; Owner: user_dashboard
--

COPY dashboard.memberof (id, memberofid, principal_parties_id, parties_id) FROM stdin;
\.


--
-- Data for Name: metadata; Type: TABLE DATA; Schema: dashboard; Owner: user_dashboard
--

COPY dashboard.metadata (field_name, value) FROM stdin;
\.


--
-- Data for Name: milestonetype; Type: TABLE DATA; Schema: dashboard; Owner: user_dashboard
--

COPY dashboard.milestonetype (id, code, title, description) FROM stdin;
\.


--
-- Data for Name: parties; Type: TABLE DATA; Schema: dashboard; Owner: user_dashboard
--

COPY dashboard.parties (contractingprocess_id, id, partyid, name, "position", identifier_scheme, identifier_id, identifier_legalname, identifier_uri, address_streetaddress, address_locality, address_region, address_postalcode, address_countryname, contactpoint_name, contactpoint_email, contactpoint_telephone, contactpoint_faxnumber, contactpoint_url, details, naturalperson, contactpoint_type, contactpoint_language, surname, additionalsurname, contactpoint_surname, contactpoint_additionalsurname, givenname, contactpoint_givenname) FROM stdin;
\.


--
-- Data for Name: partiesadditionalidentifiers; Type: TABLE DATA; Schema: dashboard; Owner: user_dashboard
--

COPY dashboard.partiesadditionalidentifiers (id, contractingprocess_id, parties_id, scheme, legalname, uri) FROM stdin;
\.


--
-- Data for Name: paymentmethod; Type: TABLE DATA; Schema: dashboard; Owner: user_dashboard
--

COPY dashboard.paymentmethod (id, code, title, description) FROM stdin;
\.


--
-- Data for Name: planning; Type: TABLE DATA; Schema: dashboard; Owner: user_dashboard
--

COPY dashboard.planning (id, contractingprocess_id, hasquotes, rationale) FROM stdin;
\.


--
-- Data for Name: planningdocuments; Type: TABLE DATA; Schema: dashboard; Owner: user_dashboard
--

COPY dashboard.planningdocuments (id, contractingprocess_id, planning_id, documentid, document_type, title, description, url, date_published, date_modified, format, language) FROM stdin;
\.


--
-- Data for Name: pntreference; Type: TABLE DATA; Schema: dashboard; Owner: user_dashboard
--

COPY dashboard.pntreference (id, contractingprocess_id, contractid, format, record_id, "position", field_id, reference_id, date, isroot, error) FROM stdin;
\.


--
-- Data for Name: prefixocid; Type: TABLE DATA; Schema: dashboard; Owner: user_dashboard
--

COPY dashboard.prefixocid (id, value) FROM stdin;
\.


--
-- Data for Name: programaticstructure; Type: TABLE DATA; Schema: dashboard; Owner: user_dashboard
--

COPY dashboard.programaticstructure (id, cve, year, trimester, branch, branch_desc, finality, finality_desc, function, function_desc, subfunction, subfunction_desc, institutionalactivity, institutionalactivity_desc, budgetprogram, budgetprogram_desc, strategicobjective, strategicobjective_desc, responsibleunit, responsibleunit_desc, requestingunit, requestingunit_desc, spendingtype, spendingtype_desc, specificactivity, specificactivity_desc, spendingobject, spendingobject_desc, region, region_desc, budgetsource, budgetsource_desc, portfoliokey, approvedamount, modifiedamount, executedamount, committedamount, reservedamount) FROM stdin;
\.


--
-- Data for Name: publisher; Type: TABLE DATA; Schema: dashboard; Owner: user_dashboard
--

COPY dashboard.publisher (id, contractingprocess_id, name, scheme, uid, uri) FROM stdin;
\.


--
-- Data for Name: quotes; Type: TABLE DATA; Schema: dashboard; Owner: user_dashboard
--

COPY dashboard.quotes (id, requestforquotes_id, quotes_id, description, date, value, quoteperiod_startdate, quoteperiod_enddate, issuingsupplier_id) FROM stdin;
\.


--
-- Data for Name: quotesitems; Type: TABLE DATA; Schema: dashboard; Owner: user_dashboard
--

COPY dashboard.quotesitems (id, quotes_id, itemid, item, quantity) FROM stdin;
\.


--
-- Data for Name: relatedprocedure; Type: TABLE DATA; Schema: dashboard; Owner: user_dashboard
--

COPY dashboard.relatedprocedure (id, contractingprocess_id, relatedprocedure_id, relationship_type, title, identifier_scheme, relatedprocedure_identifier, url) FROM stdin;
\.


--
-- Data for Name: requestforquotes; Type: TABLE DATA; Schema: dashboard; Owner: user_dashboard
--

COPY dashboard.requestforquotes (id, contractingprocess_id, planning_id, requestforquotes_id, title, description, period_startdate, period_enddate) FROM stdin;
\.


--
-- Data for Name: requestforquotesinvitedsuppliers; Type: TABLE DATA; Schema: dashboard; Owner: user_dashboard
--

COPY dashboard.requestforquotesinvitedsuppliers (id, requestforquotes_id, parties_id) FROM stdin;
\.


--
-- Data for Name: requestforquotesitems; Type: TABLE DATA; Schema: dashboard; Owner: user_dashboard
--

COPY dashboard.requestforquotesitems (id, requestforquotes_id, itemid, item, quantity) FROM stdin;
\.


--
-- Data for Name: rolecatalog; Type: TABLE DATA; Schema: dashboard; Owner: user_dashboard
--

COPY dashboard.rolecatalog (id, code, title, description) FROM stdin;
\.


--
-- Data for Name: roles; Type: TABLE DATA; Schema: dashboard; Owner: user_dashboard
--

COPY dashboard.roles (contractingprocess_id, parties_id, id, buyer, procuringentity, supplier, tenderer, funder, enquirer, payer, payee, reviewbody, attendee, official, invitedsupplier, issuingsupplier, guarantor, requestingunit, contractingunit, technicalunit) FROM stdin;
\.


--
-- Data for Name: tags; Type: TABLE DATA; Schema: dashboard; Owner: user_dashboard
--

COPY dashboard.tags (id, contractingprocess_id, planning, planningupdate, tender, tenderamendment, tenderupdate, tendercancellation, award, awardupdate, awardcancellation, contract, contractupdate, contractamendment, implementation, implementationupdate, contracttermination, compiled, stage, register_date) FROM stdin;
\.


--
-- Data for Name: tender; Type: TABLE DATA; Schema: dashboard; Owner: user_dashboard
--

COPY dashboard.tender (id, contractingprocess_id, tenderid, title, description, status, minvalue_amount, minvalue_currency, value_amount, value_currency, procurementmethod, procurementmethod_details, procurementmethod_rationale, mainprocurementcategory, additionalprocurementcategories, awardcriteria, awardcriteria_details, submissionmethod, submissionmethod_details, tenderperiod_startdate, tenderperiod_enddate, enquiryperiod_startdate, enquiryperiod_enddate, hasenquiries, eligibilitycriteria, awardperiod_startdate, awardperiod_enddate, numberoftenderers, amendment_date, amendment_rationale, procurementmethod_rationale_id) FROM stdin;
\.


--
-- Data for Name: tenderamendmentchanges; Type: TABLE DATA; Schema: dashboard; Owner: user_dashboard
--

COPY dashboard.tenderamendmentchanges (id, contractingprocess_id, tender_id, property, former_value, amendments_date, amendments_rationale, amendments_id, amendments_description) FROM stdin;
\.


--
-- Data for Name: tenderdocuments; Type: TABLE DATA; Schema: dashboard; Owner: user_dashboard
--

COPY dashboard.tenderdocuments (id, contractingprocess_id, tender_id, document_type, documentid, title, description, url, date_published, date_modified, format, language) FROM stdin;
\.


--
-- Data for Name: tenderitem; Type: TABLE DATA; Schema: dashboard; Owner: user_dashboard
--

COPY dashboard.tenderitem (id, contractingprocess_id, tender_id, itemid, description, classification_scheme, classification_id, classification_description, classification_uri, quantity, unit_name, unit_value_amount, unit_value_currency, unit_value_amountnet, latitude, longitude, location_postalcode, location_countryname, location_streetaddress, location_region, location_locality) FROM stdin;
\.


--
-- Data for Name: tenderitemadditionalclassifications; Type: TABLE DATA; Schema: dashboard; Owner: user_dashboard
--

COPY dashboard.tenderitemadditionalclassifications (id, contractingprocess_id, tenderitem_id, scheme, description, uri) FROM stdin;
\.


--
-- Data for Name: tendermilestone; Type: TABLE DATA; Schema: dashboard; Owner: user_dashboard
--

COPY dashboard.tendermilestone (id, contractingprocess_id, tender_id, milestoneid, title, description, duedate, date_modified, status, type) FROM stdin;
\.


--
-- Data for Name: tendermilestonedocuments; Type: TABLE DATA; Schema: dashboard; Owner: user_dashboard
--

COPY dashboard.tendermilestonedocuments (id, contractingprocess_id, tender_id, milestone_id, document_type, documentid, title, description, url, date_published, date_modified, format, language) FROM stdin;
\.


--
-- Data for Name: user_contractingprocess; Type: TABLE DATA; Schema: dashboard; Owner: user_dashboard
--

COPY dashboard.user_contractingprocess (id, user_id, contractingprocess_id) FROM stdin;
\.


--
-- Data for Name: additionalcontactpoints; Type: TABLE DATA; Schema: public; Owner: user_captura
--

COPY public.additionalcontactpoints (id, party_id, type, name, givenname, surname, additionalsurname, email, telephone, faxnumber, url, language) FROM stdin;
\.


--
-- Data for Name: award; Type: TABLE DATA; Schema: public; Owner: user_captura
--

COPY public.award (id, contractingprocess_id, awardid, title, description, rationale, status, award_date, value_amount, value_currency, contractperiod_startdate, contractperiod_enddate, amendment_date, amendment_rationale, value_amountnet, datelastupdate) FROM stdin;
\.


--
-- Data for Name: awardamendmentchanges; Type: TABLE DATA; Schema: public; Owner: user_captura
--

COPY public.awardamendmentchanges (id, contractingprocess_id, award_id, property, former_value, amendments_date, amendments_rationale, amendments_id, amendments_description) FROM stdin;
\.


--
-- Data for Name: awarddocuments; Type: TABLE DATA; Schema: public; Owner: user_captura
--

COPY public.awarddocuments (id, contractingprocess_id, award_id, document_type, documentid, title, description, url, date_published, date_modified, format, language) FROM stdin;
\.


--
-- Data for Name: awarditem; Type: TABLE DATA; Schema: public; Owner: user_captura
--

COPY public.awarditem (id, contractingprocess_id, award_id, itemid, description, classification_scheme, classification_id, classification_description, classification_uri, quantity, unit_name, unit_value_amount, unit_value_currency, unit_value_amountnet, latitude, longitude, location_postalcode, location_countryname, location_streetaddress, location_region, location_locality) FROM stdin;
\.


--
-- Data for Name: awarditemadditionalclassifications; Type: TABLE DATA; Schema: public; Owner: user_captura
--

COPY public.awarditemadditionalclassifications (id, award_id, awarditem_id, scheme, description, uri) FROM stdin;
\.


--
-- Data for Name: awardsupplier; Type: TABLE DATA; Schema: public; Owner: user_captura
--

COPY public.awardsupplier (id, award_id, parties_id) FROM stdin;
\.


--
-- Data for Name: budget; Type: TABLE DATA; Schema: public; Owner: user_captura
--

COPY public.budget (id, contractingprocess_id, planning_id, budget_source, budget_budgetid, budget_description, budget_amount, budget_currency, budget_project, budget_projectid, budget_uri) FROM stdin;
\.


--
-- Data for Name: budgetbreakdown; Type: TABLE DATA; Schema: public; Owner: user_captura
--

COPY public.budgetbreakdown (id, contractingprocess_id, planning_id, budgetbreakdown_id, description, amount, currency, url, budgetbreakdownperiod_startdate, budgetbreakdownperiod_enddate, source_id) FROM stdin;
\.


--
-- Data for Name: budgetclassifications; Type: TABLE DATA; Schema: public; Owner: user_captura
--

COPY public.budgetclassifications (id, budgetbreakdown_id, year, branch, responsibleunit, finality, function, subfunction, institutionalactivity, budgetprogram, strategicobjective, requestingunit, specificactivity, spendingobject, spendingtype, budgetsource, region, portfoliokey, cve, approved, modified, executed, committed, reserved, trimester) FROM stdin;
\.


--
-- Data for Name: clarificationmeeting; Type: TABLE DATA; Schema: public; Owner: user_captura
--

COPY public.clarificationmeeting (id, clarificationmeetingid, contractingprocess_id, date) FROM stdin;
\.


--
-- Data for Name: clarificationmeetingactor; Type: TABLE DATA; Schema: public; Owner: user_captura
--

COPY public.clarificationmeetingactor (id, clarificationmeeting_id, parties_id, attender, official) FROM stdin;
\.


--
-- Data for Name: contract; Type: TABLE DATA; Schema: public; Owner: user_captura
--

COPY public.contract (id, contractingprocess_id, awardid, contractid, title, description, status, period_startdate, period_enddate, value_amount, value_currency, datesigned, amendment_date, amendment_rationale, value_amountnet, exchangerate_rate, exchangerate_amount, exchangerate_currency, exchangerate_date, exchangerate_source, datelastupdate, surveillancemechanisms) FROM stdin;
\.


--
-- Data for Name: contractamendmentchanges; Type: TABLE DATA; Schema: public; Owner: user_captura
--

COPY public.contractamendmentchanges (id, contractingprocess_id, contract_id, amendments_date, amendments_rationale, amendments_id, amendments_description) FROM stdin;
\.


--
-- Data for Name: contractdocuments; Type: TABLE DATA; Schema: public; Owner: user_captura
--

COPY public.contractdocuments (id, contractingprocess_id, contract_id, document_type, documentid, title, description, url, date_published, date_modified, format, language) FROM stdin;
\.


--
-- Data for Name: contractingprocess; Type: TABLE DATA; Schema: public; Owner: user_captura
--

COPY public.contractingprocess (id, ocid, description, destino, fecha_creacion, hora_creacion, stage, uri, publicationpolicy, license, awardstatus, contractstatus, implementationstatus, published, valid, date_published, requirepntupdate, pnt_dateupdate, publisher, updated, updated_date, updated_version, published_version, pnt_published, pnt_version, pnt_date) FROM stdin;
\.


--
-- Data for Name: contractitem; Type: TABLE DATA; Schema: public; Owner: user_captura
--

COPY public.contractitem (id, contractingprocess_id, contract_id, itemid, description, classification_scheme, classification_id, classification_description, classification_uri, quantity, unit_name, unit_value_amount, unit_value_currency, unit_value_amountnet, latitude, longitude, location_postalcode, location_countryname, location_streetaddress, location_region, location_locality) FROM stdin;
\.


--
-- Data for Name: contractitemadditionalclasifications; Type: TABLE DATA; Schema: public; Owner: user_captura
--

COPY public.contractitemadditionalclasifications (id, contractingprocess_id, contract_id, contractitem_id, scheme, description, uri) FROM stdin;
\.


--
-- Data for Name: currency; Type: TABLE DATA; Schema: public; Owner: user_captura
--

COPY public.currency (id, entity, currency, currency_eng, alphabetic_code, numeric_code, minor_unit) FROM stdin;
1	AFGHANISTAN	Afgano	Afghani	AFN	971	2
2	MADAGASCAR	Ariary malgache	Malagasy Ariary	MGA	969	2
3	ARUBA	Aruban Guilder	Aruban Florin	AWG	533	2
4	THAILAND	Bath	Baht	THB	764	2
5	PANAMA	Balboa	Balboa	PAB	590	2
6	BELARUS	Belarusian Ruble	Belarusian Ruble	BYR	974	0
7	ETHIOPIA	Birr etíope	Ethiopian Birr	ETB	230	2
8		Bitcoin	Bitcoin	XBT		
9	VENEZUELA (BOLIVARIAN REPUBLIC OF)	Bolívar	Bolívar	VEF	937	2
10	BOLIVIA (PLURINATIONAL STATE OF)	Boliviano	Boliviano	BOB	068	2
11	CABO VERDE	Cabo Verde Escudo	Cabo Verde Escudo	CVE	132	2
12	GHANA	Cedi	Ghana Cedi	GHS	936	2
13	BENIN	CFA Franc BCEAO	CFA Franc BCEAO	XOF	952	0
14	BURKINA FASO	CFA Franc BCEAO	CFA Franc BCEAO	XOF	952	0
15	CÔTE D'IVOIRE	CFA Franc BCEAO	CFA Franc BCEAO	XOF	952	0
16	GUINEA-BISSAU	CFA Franc BCEAO	CFA Franc BCEAO	XOF	952	0
17	MALI	CFA Franc BCEAO	CFA Franc BCEAO	XOF	952	0
18	NIGER (THE)	CFA Franc BCEAO	CFA Franc BCEAO	XOF	952	0
19	SENEGAL	CFA Franc BCEAO	CFA Franc BCEAO	XOF	952	0
20	TOGO	CFA Franc BCEAO	CFA Franc BCEAO	XOF	952	0
21	CAMEROON	CFA Franc BEAC	CFA Franc BEAC	XAF	950	0
22	CENTRAL AFRICAN REPUBLIC (THE)	CFA Franc BEAC	CFA Franc BEAC	XAF	950	0
23	CHAD	CFA Franc BEAC	CFA Franc BEAC	XAF	950	0
24	CONGO (THE)	CFA Franc BEAC	CFA Franc BEAC	XAF	950	0
25	EQUATORIAL GUINEA	CFA Franc BEAC	CFA Franc BEAC	XAF	950	0
26	GABON	CFA Franc BEAC	CFA Franc BEAC	XAF	950	0
27	KENYA	Chelín de Kenia	Kenyan Shilling	KES	404	2
28	TANZANIA, UNITED REPUBLIC OF	Chelín de Tanzania	Tanzanian Shilling	TZS	834	2
29	SOMALIA	Chelín somalí	Somali Shilling	SOS	706	2
30	UGANDA	Chelín ungandés	Uganda Shilling	UGX	800	0
31	COSTA RICA	Colón de Costa Rica	Costa Rican Colon	CRC	188	2
32	EL SALVADOR	Colón de El Salvador	El Salvador Colon	SVC	222	2
33	COMOROS (THE)	Comoro Franc	Comoro Franc	KMF	174	0
34	BOSNIA AND HERZEGOVINA	Convertible Marks	Convertible Mark	BAM	977	2
35	NICARAGUA	Cordoba Oro	Cordoba Oro	NIO	558	2
36		Corona	Koruna	EEK		
37	CZECH REPUBLIC (THE)	Corona Checa	Czech Koruna	CZK	203	2
38	DENMARK	Corona danesa	Danish Krone	DKK	208	2
39	FAROE ISLANDS (THE)	Corona danesa	Danish Krone	DKK	208	2
40	GREENLAND	Corona danesa	Danish Krone	DKK	208	2
41	ICELAND	Corona de Islandia	Iceland Krona	ISK	352	0
42	BOUVET ISLAND	Corona noruega	Norwegian Krone	NOK	578	2
43	NORWAY	Corona noruega	Norwegian Krone	NOK	578	2
44	SVALBARD AND JAN MAYEN	Corona noruega	Norwegian Krone	NOK	578	2
45	SWEDEN	Corona sueca	Swedish Krona	SEK	752	2
46	GAMBIA (THE)	Dalasi	Dalasi	GMD	270	2
47	MACEDONIA (THE FORMER YUGOSLAV REPUBLIC OF)	Denar	Denar	MKD	807	2
48	ALGERIA	Dinar argelino	Algerian Dinar	DZD	012	2
49	BAHRAIN	Dinar de Bahrein	Bahraini Dinar	BHD	048	3
50	IRAQ	Dinar iraquí	Iraqi Dinar	IQD	368	3
51	JORDAN	Dinar jordano	Jordanian Dinar	JOD	400	3
52	KUWAIT	Dinar kuwaití	Kuwaiti Dinar	KWD	414	3
53	LIBYA	Dinar libio	Libyan Dinar	LYD	434	3
54	SERBIA	Dinar serbio	Serbian Dinar	RSD	941	2
55	TUNISIA	Dinar tunecino TOP Paanga	Tunisian Dinar	TND	788	3
56	UNITED ARAB EMIRATES (THE)	Dirham de los Emiratos Árabes Unidos	UAE Dirham	AED	784	2
57	MOROCCO	Dirham marroquí	Moroccan Dirham	MAD	504	2
58	WESTERN SAHARA	Dirham marroquí	Moroccan Dirham	MAD	504	2
59	SAO TOME AND PRINCIPE	Dobra	Dobra	STD	678	2
60	AUSTRALIA	Dólar australiano	Australian Dollar	AUD	036	2
61	CHRISTMAS ISLAND	Dólar australiano	Australian Dollar	AUD	036	2
62	COCOS (KEELING) ISLANDS (THE)	Dólar australiano	Australian Dollar	AUD	036	2
63	HEARD ISLAND AND McDONALD ISLANDS	Dólar australiano	Australian Dollar	AUD	036	2
64	KIRIBATI	Dólar australiano	Australian Dollar	AUD	036	2
65	NORFOLK ISLAND	Dólar australiano	Australian Dollar	AUD	036	2
66	NAURU	Dólar australiano	Australian Dollar	AUD	036	2
67	TUVALU	Dólar australiano	Australian Dollar	AUD	036	2
68	BERMUDA	Dólar bermudeño	Bermudian Dollar	BMD	060	2
69	CANADA	Dólar canadiense	Canadian Dollar	CAD	124	2
70	BARBADOS	Dólar de Barbados	Barbados Dollar	BBD	052	2
71	BELIZE	Dólar de Belice	Belize Dollar	BZD	084	2
72	BRUNEI DARUSSALAM	Dólar de Brunei	Brunei Dollar	BND	096	2
73	FIJI	Dólar de Fiji	Fiji Dollar	FJD	242	2
74	GUYANA	Dólar de Guyana	Guyana Dollar	GYD	328	2
75	HONG KONG	Dólar de Hong Kong	Hong Kong Dollar	HKD	344	2
76	BAHAMAS (THE)	Dólar de las Bahamas	Bahamian Dollar	BSD	044	2
77	CAYMAN ISLANDS (THE)	Dólar de las Islas Caimán	Cayman Islands Dollar	KYD	136	2
78	SOLOMON ISLANDS	Dólar de las Islas Salomón	Solomon Islands Dollar	SBD	090	2
79	NAMIBIA	Dólar de Namibia	Namibia Dollar	NAD	516	2
80	COOK ISLANDS (THE)	Dólar de Nueva Zelanda	New Zealand Dollar	NZD	554	2
81	NEW ZEALAND	Dólar de Nueva Zelanda	New Zealand Dollar	NZD	554	2
82	NIUE	Dólar de Nueva Zelanda	New Zealand Dollar	NZD	554	2
83	PITCAIRN	Dólar de Nueva Zelanda	New Zealand Dollar	NZD	554	2
84	TOKELAU	Dólar de Nueva Zelanda	New Zealand Dollar	NZD	554	2
85	SINGAPORE	Dólar de Singapur	Singapore Dollar	SGD	702	2
86	SURINAME	Dólar de Surinam	Surinam Dollar	SRD	968	2
87	TRINIDAD AND TOBAGO	Dólar de Trinidad y Tobago	Trinidad and Tobago Dollar	TTD	780	2
88	ZIMBABWE	Dólar de Zimbabwe	Zimbabwe Dollar	ZWL	932	2
89	ANGUILLA	Dólar del Caribe Oriental	East Caribbean Dollar	XCD	951	2
90	ANTIGUA AND BARBUDA	Dólar del Caribe Oriental	East Caribbean Dollar	XCD	951	2
91	DOMINICA	Dólar del Caribe Oriental	East Caribbean Dollar	XCD	951	2
92	GRENADA	Dólar del Caribe Oriental	East Caribbean Dollar	XCD	951	2
93	MONTSERRAT	Dólar del Caribe Oriental	East Caribbean Dollar	XCD	951	2
94	SAINT KITTS AND NEVIS	Dólar del Caribe Oriental	East Caribbean Dollar	XCD	951	2
95	SAINT LUCIA	Dólar del Caribe Oriental	East Caribbean Dollar	XCD	951	2
96	SAINT VINCENT AND THE GRENADINES	Dólar del Caribe Oriental	East Caribbean Dollar	XCD	951	2
97	AMERICAN SAMOA	Dólar estadounidense	US Dollar	USD	840	2
98	BONAIRE, SINT EUSTATIUS AND SABA	Dólar estadounidense	US Dollar	USD	840	2
99	BRITISH INDIAN OCEAN TERRITORY (THE)	Dólar estadounidense	US Dollar	USD	840	2
100	ECUADOR	Dólar estadounidense	US Dollar	USD	840	2
101	EL SALVADOR	Dólar estadounidense	US Dollar	USD	840	2
102	GUAM	Dólar estadounidense	US Dollar	USD	840	2
103	HAITI	Dólar estadounidense	US Dollar	USD	840	2
104	MARSHALL ISLANDS (THE)	Dólar estadounidense	US Dollar	USD	840	2
105	MICRONESIA (FEDERATED STATES OF)	Dólar estadounidense	US Dollar	USD	840	2
106	NORTHERN MARIANA ISLANDS (THE)	Dólar estadounidense	US Dollar	USD	840	2
107	PALAU	Dólar estadounidense	US Dollar	USD	840	2
108	PANAMA	Dólar estadounidense	US Dollar	USD	840	2
109	PUERTO RICO	Dólar estadounidense	US Dollar	USD	840	2
110	TIMOR-LESTE	Dólar estadounidense	US Dollar	USD	840	2
111	TURKS AND CAICOS ISLANDS (THE)	Dólar estadounidense	US Dollar	USD	840	2
112	UNITED STATES MINOR OUTLYING ISLANDS (THE)	Dólar estadounidense	US Dollar	USD	840	2
113	UNITED STATES OF AMERICA (THE)	Dólar estadounidense	US Dollar	USD	840	2
114	VIRGIN ISLANDS (BRITISH)	Dólar estadounidense	US Dollar	USD	840	2
115	VIRGIN ISLANDS (U.S.)	Dólar estadounidense	US Dollar	USD	840	2
116	UNITED STATES OF AMERICA (THE)	Dólar estadounidense (día siguiente)	US Dollar (Next day)	USN	997	2
117	UNITED STATES OF AMERICA (THE)	Dólar estadounidense (el mismo día)	US Dollar (Same day)	USN	997	2
118	JAMAICA	Dólar jamaicano	Jamaican Dollar	JMD	388	2
119	LIBERIA	Dólar liberiano	Liberian Dollar	LRD	430	2
120	VIET NAM	Dong	Dong	VND	704	0
121	ARMENIA	Dram Armenio	Armenian Dram	AMD	051	2
122	ÅLAND ISLANDS	Euro	Euro	EUR	978	2
123	ANDORRA	Euro	Euro	EUR	978	2
124	AUSTRIA	Euro	Euro	EUR	978	2
125	BELGIUM	Euro	Euro	EUR	978	2
126	CYPRUS	Euro	Euro	EUR	978	2
127	ESTONIA	Euro	Euro	EUR	978	2
128	EUROPEAN UNION	Euro	Euro	EUR	978	2
129	FINLAND	Euro	Euro	EUR	978	2
130	FRANCE	Euro	Euro	EUR	978	2
131	FRENCH GUIANA	Euro	Euro	EUR	978	2
132	FRENCH SOUTHERN TERRITORIES (THE)	Euro	Euro	EUR	978	2
133	GERMANY	Euro	Euro	EUR	978	2
134	GREECE	Euro	Euro	EUR	978	2
135	GUADELOUPE	Euro	Euro	EUR	978	2
136	HOLY SEE (THE)	Euro	Euro	EUR	978	2
137	IRELAND	Euro	Euro	EUR	978	2
138	ITALY	Euro	Euro	EUR	978	2
139	LATVIA	Euro	Euro	EUR	978	2
140	LITHUANIA	Euro	Euro	EUR	978	2
141	LUXEMBOURG	Euro	Euro	EUR	978	2
142	MALTA	Euro	Euro	EUR	978	2
143	MARTINIQUE	Euro	Euro	EUR	978	2
144	MAYOTTE	Euro	Euro	EUR	978	2
145	MONACO	Euro	Euro	EUR	978	2
146	MONTENEGRO	Euro	Euro	EUR	978	2
147	NETHERLANDS (THE)	Euro	Euro	EUR	978	2
148	PORTUGAL	Euro	Euro	EUR	978	2
149	RÉUNION	Euro	Euro	EUR	978	2
150	SAINT BARTHÉLEMY	Euro	Euro	EUR	978	2
151	SAINT MARTIN (FRENCH PART)	Euro	Euro	EUR	978	2
152	SAINT PIERRE AND MIQUELON	Euro	Euro	EUR	978	2
153	SAN MARINO	Euro	Euro	EUR	978	2
154	SLOVAKIA	Euro	Euro	EUR	978	2
155	SLOVENIA	Euro	Euro	EUR	978	2
156	SPAIN	Euro	Euro	EUR	978	2
157	HUNGARY	Forint	Forint	HUF	348	2
158	FRENCH POLYNESIA	Franco CFP	CFP Franc	XPF	953	0
159	NEW CALEDONIA	Franco CFP	CFP Franc	XPF	953	0
160	WALLIS AND FUTUNA	Franco CFP	CFP Franc	XPF	953	0
161	CONGO (THE DEMOCRATIC REPUBLIC OF THE)	Franco Congolés	Congolese Franc	CDF	976	2
162	BURUNDI	Franco de Burundi	Burundi Franc	BIF	108	0
163	DJIBOUTI	Franco de Djibouti	Djibouti Franc	DJF	262	0
164	RWANDA	Franco ruanda	Rwanda Franc	RWF	646	0
165	LIECHTENSTEIN	Franco suizo	Swiss Franc	CHF	756	2
166	SWITZERLAND	Franco suizo	Swiss Franc	CHF	756	2
167	HAITI	Gourde	Gourde	HTG	332	2
168	PARAGUAY	Guaraní	Guarani	PYG	600	0
169	GUINEA	Guinea Franc	Guinea Franc	GNF	324	0
170	UKRAINE	Hryvnia	Hryvnia	UAH	980	2
171	INTERNATIONAL MONETARY FUND (IMF) 	SDR (Special Drawing Right)	SDR (Special Drawing Right)	XDR	960	N.A.
172	PAPUA NEW GUINEA	Kina	Kina	PGK	598	2
173	LAO PEOPLE’S DEMOCRATIC REPUBLIC (THE)	Kip	Kip	LAK	418	2
174	CROATIA	Kuna	Kuna	HRK	191	2
175		Kwacha zambiano	Kwacha zambiano	ZMK		
176	ANGOLA	Kwanza	Kwanza	AOA	973	2
177	MYANMAR	Kyat	Kyat	MMK	104	2
178	GEORGIA	Lari	Lari	GEL	981	2
179	ALBANIA	Lek	Lek	ALL	008	2
180	HONDURAS	Lempira	Lempira	HNL	340	2
181	SIERRA LEONE	Leone	Leone	SLL	694	2
182	MOLDOVA (THE REPUBLIC OF)	Leu moldavo	Moldovan Leu	MDL	498	2
183	ROMANIA	Leu rumano	Romanian Leu	RON	946	2
184	BULGARIA	Lev búlgaro	Bulgarian Lev	BGN	975	2
185	GIBRALTAR	Libra de Gilbraltar	Gibraltar Pound	GIP	292	2
186	FALKLAND ISLANDS (THE) [MALVINAS]	Libra de las Islas Malvinas	Falkland Islands Pound	FKP	238	2
187	SAINT HELENA, ASCENSION AND TRISTAN DA CUNHA	Libra de Santa Helena	Saint Helena Pound	SHP	654	2
188	EGYPT	Libra egipcia	Egyptian Pound	EGP	818	2
189	GUERNSEY	Libra esterlina	Pound Sterling	GBP	826	2
190	ISLE OF MAN	Libra esterlina	Pound Sterling	GBP	826	2
191	JERSEY	Libra esterlina	Pound Sterling	GBP	826	2
192	UNITED KINGDOM OF GREAT BRITAIN AND NORTHERN IRELAND (THE)	Libra esterlina	Pound Sterling	GBP	826	2
193	LEBANON	Libra libanesa	Lebanese Pound	LBP	422	2
194	SYRIAN ARAB REPUBLIC	Libra siria	Syrian Pound	SYP	760	2
195	SUDAN (THE)	Libra sudanesa	Sudanese Pound	SDG	938	2
196	SOUTH SUDAN	Libra sudanesa	South Sudanese Pound	SSP	728	2
197	SWAZILAND	Lilangeni	Lilangeni	SZL	748	2
198	TURKEY	Lira turca	Lira turca	TRY	949	2
199	LESOTHO	Loti	Loti	LSL	426	2
200		Litas de Lituana	Litas de Lituana	LTL		
201		Lats letón	Lats letón	LvL		
202	MALAWI	Malawi Kwacha	Malawi Kwacha	MWK	454	2
203	TURKMENISTAN	Manat	Turkmenistan New Manat	TMT	934	2
204	AZERBAIJAN	Manat Azerbaiyano	Azerbaijanian Manat	AZN	944	2
205	MOZAMBIQUE	Metical	Mozambique Metical	MZN	943	2
206	BOLIVIA (PLURINATIONAL STATE OF)	Mvdol	Mvdol	BOV	984	2
207	NIGERIA	Naira	Naira	NGN	566	2
208	ERITREA	Nakfa	Nakfa	ERN	232	2
209	CURAÇAO	Netherlands Antillean Guilder	Netherlands Antillean Guilder	ANG	532	2
210	SINT MAARTEN (DUTCH PART)	Netherlands Antillean Guilder	Netherlands Antillean Guilder	ANG	532	2
211	BHUTAN	Ngultrum	Ngultrum	BTN	064	2
212	TAIWAN (PROVINCE OF CHINA)	Nuevo dólar de Taiwán	New Taiwan Dollar	TWD	901	2
213	ISRAEL	Nuevo shekel israelí	New Israeli Sheqel	ILS	376	2
214	PERU	Nuevo Sol	Sol	PEN	604	2
215	MAURITANIA	Ouguiya	Ouguiya	MRO	478	2
216	MACAO	Pataca	Pataca	MOP	446	2
217	ARGENTINA	Peso argentino	Argentine Peso	ARS	032	2
218	CHILE	Peso chileno	Chilean Peso	CLP	152	0
219	COLOMBIA	Peso colombiano	Colombian Peso	COP	170	2
220	CUBA	Peso Convertible	Peso Convertible	CUC	931	2
221	CUBA	Peso cubano	Cuban Peso	CUP	192	2
222	DOMINICAN REPUBLIC (THE)	Peso Dominicano	Dominican Peso	DOP	214	2
223	MEXICO	Peso Mexicano	Mexican Peso	MXN	484	2
224	URUGUAY	Peso Uruguayo	Peso Uruguayo	UYU	858	2
225	PHILIPPINES (THE)	Philippine Peso	Philippine Peso	PHP	608	2
226	BOTSWANA	Pula	Pula	BWP	072	2
227	GUATEMALA	Quetzal	Quetzal	GTQ	320	2
228	LESOTHO	Rand	Rand	ZAR	710	2
229	NAMIBIA	Rand	Rand	ZAR	710	2
230	SOUTH AFRICA	Rand	Rand	ZAR	710	2
231	BRAZIL	Real brasileño	Brazilian Real	BRL	986	2
232	QATAR	Rial de Qatar	Qatari Rial	QAR	634	2
233	IRAN (ISLAMIC REPUBLIC OF)	Rial iraní	Iranian Rial	IRR	364	2
234	OMAN	Rial Omani	Rial Omani	OMR	512	3
235	YEMEN	Rial yenemí	Yemeni Rial	YER	886	2
236	CAMBODIA	Riel	Riel	KHR	116	2
237	MALAYSIA	Ringgit malayo	Malaysian Ringgit	MYR	458	2
238	SAUDI ARABIA	Riyal saudita	Saudi Riyal	SAR	682	2
239	RUSSIAN FEDERATION (THE)	Rublo ruso	Russian Ruble	RUB	643	2
240	MALDIVES	Rufiyaa	Rufiyaa	MVR	462	2
241	INDONESIA	Rupia	Rupiah	IDR	360	2
242	MAURITIUS	Rupia de Mauricio	Mauritius Rupee	MUR	480	2
243	PAKISTAN	Rupia de Pakistán	Pakistan Rupee	PKR	586	2
244	SEYCHELLES	Rupia de Seychelles	Seychelles Rupee	SCR	690	2
245	SRI LANKA	Rupia de Sri Lanka	Sri Lanka Rupee	LKR	144	2
246	BHUTAN	Rupia india	Indian Rupee	INR	356	2
247	INDIA	Rupia india	Indian Rupee	INR	356	2
248	NEPAL	Rupia nepalí	Nepalese Rupee	NPR	524	2
249	KYRGYZSTAN	Som	Som	KGS	417	2
250	TAJIKISTAN	Somoni	Somoni	TJS	972	2
251	UZBEKISTAN	Suma de Uzbekistán	Uzbekistan Sum	UZS	860	2
252	BANGLADESH	Taka	Taka	BDT	050	2
253	SAMOA	Tala	Tala	WST	882	2
254	KAZAKHSTAN	Tenge	Tenge	KZT	398	2
255	MONGOLIA	Tugrik	Tugrik	MNT	496	2
256	MEXICO	Unidad de Inversión Mexicana (UDI)	Mexican Unidad de Inversion (UDI)	MXV	979	2
257	COLOMBIA	Unidad de Valor Real	Unidad de Valor Real	COU	970	2
258	CHILE	Unidades de Fomento	Unidad de Fomento	CLF	990	4
259	URUGUAY	Uruguay Peso en Unidades Indexadas	Uruguay Peso en Unidades Indexadas (URUIURUI)	UYI	940	0
260	VANUATU	Vatu	Vatu	VUV	548	0
261	KOREA (THE REPUBLIC OF)	Won	Won	KRW	410	0
262	KOREA (THE DEMOCRATIC PEOPLE’S REPUBLIC OF)	Won de Corea del Norte	North Korean Won	KPW	408	2
263	JAPAN	Yen	Yen	JPY	392	0
264	CHINA	Yuan Renminbi	Yuan Renminbi	CNY	156	2
265	POLAND	Zloty	Zloty	PLN	985	2
\.


--
-- Data for Name: documentformat; Type: TABLE DATA; Schema: public; Owner: user_captura
--

COPY public.documentformat (id, category, name, template, reference) FROM stdin;
1	application	1d-interleaved-parityfec	application/1d-interleaved-parityfec	[RFC6015]
2	application	3gpdash-qoe-report+xml	application/3gpdash-qoe-report+xml	[_3GPP][Ozgur_Oyman]
3	application	3gpp-ims+xml	application/3gpp-ims+xml	[John_M_Meredith]
4	application	A2L	application/A2L	[ASAM][Thomas_Thomsen]
5	application	activemessage	application/activemessage	[Ehud_Shapiro]
6	application	activemessage	application/activemessage	[Ehud_Shapiro]
7	application	alto-costmap+json	application/alto-costmap+json	[RFC7285]
8	application	alto-costmapfilter+json	application/alto-costmapfilter+json	[RFC7285]
9	application	alto-directory+json	application/alto-directory+json	[RFC7285]
10	application	alto-endpointprop+json	application/alto-endpointprop+json	[RFC7285]
11	application	alto-endpointpropparams+json	application/alto-endpointpropparams+json	[RFC7285]
12	application	alto-endpointcost+json	application/alto-endpointcost+json	[RFC7285]
13	application	alto-endpointcostparams+json	application/alto-endpointcostparams+json	[RFC7285]
14	application	alto-error+json	application/alto-error+json	[RFC7285]
15	application	alto-networkmapfilter+json	application/alto-networkmapfilter+json	[RFC7285]
16	application	alto-networkmap+json	application/alto-networkmap+json	[RFC7285]
17	application	AML	application/AML	[ASAM][Thomas_Thomsen]
18	application	andrew-inset	application/andrew-inset	[Nathaniel_Borenstein]
19	application	applefile	application/applefile	[Patrik_Faltstrom]
20	application	ATF	application/ATF	[ASAM][Thomas_Thomsen]
21	application	ATFX	application/ATFX	[ASAM][Thomas_Thomsen]
22	application	atom+xml	application/atom+xml	[RFC4287][RFC5023]
23	application	atomcat+xml	application/atomcat+xml	[RFC5023]
24	application	atomdeleted+xml	application/atomdeleted+xml	[RFC6721]
25	application	atomicmail	application/atomicmail	[Nathaniel_Borenstein]
26	application	atomsvc+xml	application/atomsvc+xml	[RFC5023]
27	application	ATXML	application/ATXML	[ASAM][Thomas_Thomsen]
28	application	auth-policy+xml	application/auth-policy+xml	[RFC4745]
29	application	bacnet-xdd+zip	application/bacnet-xdd+zip	[ASHRAE][Dave_Robin]
30	application	batch-SMTP	application/batch-SMTP	[RFC2442]
31	application	beep+xml	application/beep+xml	[RFC3080]
32	application	calendar+json	application/calendar+json	[RFC7265]
33	application	calendar+xml	application/calendar+xml	[RFC6321]
34	application	call-completion	application/call-completion	[RFC6910]
35	application	CALS-1840	application/CALS-1840	[RFC1895]
36	application	cbor	application/cbor	[RFC7049]
37	application	ccmp+xml	application/ccmp+xml	[RFC6503]
38	application	ccxml+xml	application/ccxml+xml	[RFC4267]
39	application	CDFX+XML	application/CDFX+XML	[ASAM][Thomas_Thomsen]
40	application	cdmi-capability	application/cdmi-capability	[RFC6208]
41	application	cdmi-container	application/cdmi-container	[RFC6208]
42	application	cdmi-domain	application/cdmi-domain	[RFC6208]
43	application	cdmi-object	application/cdmi-object	[RFC6208]
44	application	cdmi-queue	application/cdmi-queue	[RFC6208]
45	application	cdni	application/cdni	[RFC7736]
46	application	CEA	application/CEA	[ASAM][Thomas_Thomsen]
47	application	cea-2018+xml	application/cea-2018+xml	[Gottfried_Zimmermann]
48	application	cellml+xml	application/cellml+xml	[RFC4708]
49	application	cfw	application/cfw	[RFC6230]
50	application	clue_info+xml	application/clue_info+xml	[RFC-ietf-clue-data-model-schema-17]
51	application	cms	application/cms	[RFC7193]
52	application	cnrp+xml	application/cnrp+xml	[RFC3367]
53	application	coap-group+json	application/coap-group+json	[RFC7390]
54	application	commonground	application/commonground	[David_Glazer]
55	application	conference-info+xml	application/conference-info+xml	[RFC4575]
56	application	cpl+xml	application/cpl+xml	[RFC3880]
57	application	csrattrs	application/csrattrs	[RFC7030]
58	application	csta+xml	application/csta+xml	[Ecma_International_Helpdesk]
59	application	CSTAdata+xml	application/CSTAdata+xml	[Ecma_International_Helpdesk]
60	application	csvm+json	application/csvm+json	[W3C][Ivan_Herman]
61	application	cybercash	application/cybercash	[Donald_E._Eastlake_3rd]
62	application	dash+xml	application/dash+xml	[Thomas_Stockhammer][ISO-IEC_JTC1]
63	application	dashdelta	application/dashdelta	[David_Furbeck]
64	application	davmount+xml	application/davmount+xml	[RFC4709]
65	application	dca-rft	application/dca-rft	[Larry_Campbell]
66	application	DCD	application/DCD	[ASAM][Thomas_Thomsen]
67	application	dec-dx	application/dec-dx	[Larry_Campbell]
68	application	dialog-info+xml	application/dialog-info+xml	[RFC4235]
69	application	dicom	application/dicom	[RFC3240]
70	application	dicom+json	application/dicom+json	[DICOM_Standards_Committee][David_Clunie][James_F_Philbin]
71	application	dicom+xml	application/dicom+xml	[DICOM_Standards_Committee][David_Clunie][James_F_Philbin]
72	application	DII	application/DII	[ASAM][Thomas_Thomsen]
73	application	DIT	application/DIT	[ASAM][Thomas_Thomsen]
74	application	dns	application/dns	[RFC4027]
75	application	dskpp+xml	application/dskpp+xml	[RFC6063]
76	application	dssc+der	application/dssc+der	[RFC5698]
77	application	dssc+xml	application/dssc+xml	[RFC5698]
78	application	dvcs	application/dvcs	[RFC3029]
79	application	ecmascript	application/ecmascript	[RFC4329]
80	application	EDI-consent	application/EDI-consent	[RFC1767]
81	application	EDIFACT	application/EDIFACT	[RFC1767]
82	application	EDI-X12	application/EDI-X12	[RFC1767]
83	application	efi	application/efi	[UEFI_Forum][Samer_El-Haj-Mahmoud]
84	application	EmergencyCallData.Comment+xml	application/EmergencyCallData.Comment+xml	[RFC7852]
85	application	EmergencyCallData.DeviceInfo+xml	application/EmergencyCallData.DeviceInfo+xml	[RFC7852]
86	application	EmergencyCallData.ProviderInfo+xml	application/EmergencyCallData.ProviderInfo+xml	[RFC7852]
87	application	EmergencyCallData.ServiceInfo+xml	application/EmergencyCallData.ServiceInfo+xml	[RFC7852]
88	application	EmergencyCallData.SubscriberInfo+xml	application/EmergencyCallData.SubscriberInfo+xml	[RFC7852]
89	application	emma+xml		[W3C][http://www.w3.org/TR/2007/CR-emma-20071211/#media-type-registration][ISO-IEC JTC1]
90	application	emotionml+xml	application/emotionml+xml	[W3C][Kazuyuki_Ashimura]
91	application	encaprtp	application/encaprtp	[RFC6849]
92	application	epp+xml	application/epp+xml	[RFC5730]
93	application	epub+zip	application/epub+zip	[International_Digital_Publishing_Forum][William_McCoy]
94	application	eshop	application/eshop	[Steve_Katz]
95	application	example	application/example	[RFC4735]
96	application	exi		[W3C][http://www.w3.org/TR/2009/CR-exi-20091208/#mediaTypeRegistration]
97	application	fastinfoset	application/fastinfoset	[ITU-T_ASN.1_Rapporteur]
98	application	fastsoap	application/fastsoap	[ITU-T_ASN.1_Rapporteur]
99	application	fdt+xml	application/fdt+xml	[RFC6726]
100	application	fits	application/fits	[RFC4047]
101	application	font-sfnt	application/font-sfnt	[Levantovsky][ISO-IEC JTC1]
102	application	font-tdpfr	application/font-tdpfr	[RFC3073]
103	application	font-woff	application/font-woff	[W3C]
104	application	framework-attributes+xml	application/framework-attributes+xml	[RFC6230]
105	application	geo+json	application/geo+json	[RFC7946]
106	application	gzip	application/gzip	[RFC6713]
107	application	H224	application/H224	[RFC4573]
108	application	held+xml	application/held+xml	[RFC5985]
109	application	http	application/http	[RFC7230]
110	application	hyperstudio	application/hyperstudio	[Michael_Domino]
111	application	ibe-key-request+xml	application/ibe-key-request+xml	[RFC5408]
112	application	ibe-pkg-reply+xml	application/ibe-pkg-reply+xml	[RFC5408]
113	application	ibe-pp-data	application/ibe-pp-data	[RFC5408]
114	application	iges	application/iges	[Curtis_Parks]
115	application	im-iscomposing+xml	application/im-iscomposing+xml	[RFC3994]
116	application	index	application/index	[RFC2652]
117	application	index.cmd	application/index.cmd	[RFC2652]
118	application	index.obj	application/index-obj	[RFC2652]
119	application	index.response	application/index.response	[RFC2652]
120	application	index.vnd	application/index.vnd	[RFC2652]
121	application	inkml+xml	application/inkml+xml	[Kazuyuki_Ashimura]
122	application	iotp	application/IOTP	[RFC2935]
123	application	ipfix	application/ipfix	[RFC5655]
124	application	ipp	application/ipp	[RFC-sweet-rfc2910bis-09]
125	application	isup	application/ISUP	[RFC3204]
126	application	its+xml	application/its+xml	[W3C][ITS-IG-W3C]
127	application	javascript	application/javascript	[RFC4329]
128	application	jose	application/jose	[RFC7515]
129	application	jose+json	application/jose+json	[RFC7515]
130	application	jrd+json	application/jrd+json	[RFC7033]
131	application	json	application/json	[RFC7159]
132	application	json-patch+json	application/json-patch+json	[RFC6902]
133	application	json-seq	application/json-seq	[RFC7464]
134	application	jwk+json	application/jwk+json	[RFC7517]
135	application	jwk-set+json	application/jwk-set+json	[RFC7517]
136	application	jwt	application/jwt	[RFC7519]
137	application	kpml-request+xml	application/kpml-request+xml	[RFC4730]
138	application	kpml-response+xml	application/kpml-response+xml	[RFC4730]
139	application	ld+json	application/ld+json	[W3C][Ivan_Herman]
140	application	lgr+xml	application/lgr+xml	[RFC7940]
141	application	link-format	application/link-format	[RFC6690]
142	application	load-control+xml	application/load-control+xml	[RFC7200]
143	application	lost+xml	application/lost+xml	[RFC5222]
144	application	lostsync+xml	application/lostsync+xml	[RFC6739]
145	application	LXF	application/LXF	[ASAM][Thomas_Thomsen]
146	application	mac-binhex40	application/mac-binhex40	[Patrik_Faltstrom]
147	application	macwriteii	application/macwriteii	[Paul_Lindner]
148	application	mads+xml	application/mads+xml	[RFC6207]
149	application	marc	application/marc	[RFC2220]
150	application	marcxml+xml	application/marcxml+xml	[RFC6207]
151	application	mathematica	application/mathematica	[Wolfram]
152	application	mathml-content+xml		[W3C][http://www.w3.org/TR/MathML3/appendixb.html]
153	application	mathml-presentation+xml		[W3C][http://www.w3.org/TR/MathML3/appendixb.html]
154	application	mathml+xml		[W3C][http://www.w3.org/TR/MathML3/appendixb.html]
155	application	mbms-associated-procedure-description+xml	application/mbms-associated-procedure-description+xml	[_3GPP]
156	application	mbms-deregister+xml	application/mbms-deregister+xml	[_3GPP]
157	application	mbms-envelope+xml	application/mbms-envelope+xml	[_3GPP]
158	application	mbms-msk-response+xml	application/mbms-msk-response+xml	[_3GPP]
159	application	mbms-msk+xml	application/mbms-msk+xml	[_3GPP]
160	application	mbms-protection-description+xml	application/mbms-protection-description+xml	[_3GPP]
161	application	mbms-reception-report+xml	application/mbms-reception-report+xml	[_3GPP]
162	application	mbms-register-response+xml	application/mbms-register-response+xml	[_3GPP]
163	application	mbms-register+xml	application/mbms-register+xml	[_3GPP]
164	application	mbms-schedule+xml	application/mbms-schedule+xml	[_3GPP][Eric_Turcotte]
165	application	mbms-user-service-description+xml	application/mbms-user-service-description+xml	[_3GPP]
166	application	mbox	application/mbox	[RFC4155]
167	application	media_control+xml	application/media_control+xml	[RFC5168]
168	application	media-policy-dataset+xml	application/media-policy-dataset+xml	[RFC6796]
169	application	mediaservercontrol+xml	application/mediaservercontrol+xml	[RFC5022]
170	application	merge-patch+json	application/merge-patch+json	[RFC7396]
171	application	metalink4+xml	application/metalink4+xml	[RFC5854]
172	application	mets+xml	application/mets+xml	[RFC6207]
173	application	MF4	application/MF4	[ASAM][Thomas_Thomsen]
174	application	mikey	application/mikey	[RFC3830]
175	application	mods+xml	application/mods+xml	[RFC6207]
176	application	moss-keys	application/moss-keys	[RFC1848]
177	application	moss-signature	application/moss-signature	[RFC1848]
178	application	mosskey-data	application/mosskey-data	[RFC1848]
179	application	mosskey-request	application/mosskey-request	[RFC1848]
180	application	mp21	application/mp21	[RFC6381][David_Singer]
181	application	mp4	application/mp4	[RFC4337][RFC6381]
182	application	mpeg4-generic	application/mpeg4-generic	[RFC3640]
183	application	mpeg4-iod	application/mpeg4-iod	[RFC4337]
184	application	mpeg4-iod-xmt	application/mpeg4-iod-xmt	[RFC4337]
185	application	mrb-consumer+xml	application/mrb-consumer+xml	[RFC6917]
186	application	mrb-publish+xml	application/mrb-publish+xml	[RFC6917]
187	application	msc-ivr+xml	application/msc-ivr+xml	[RFC6231]
188	application	msc-mixer+xml	application/msc-mixer+xml	[RFC6505]
189	application	msword	application/msword	[Paul_Lindner]
190	application	mxf	application/mxf	[RFC4539]
191	application	nasdata	application/nasdata	[RFC4707]
192	application	news-checkgroups	application/news-checkgroups	[RFC5537]
193	application	news-groupinfo	application/news-groupinfo	[RFC5537]
194	application	news-transmission	application/news-transmission	[RFC5537]
195	application	nlsml+xml	application/nlsml+xml	[RFC6787]
196	application	nss	application/nss	[Michael_Hammer]
197	application	ocsp-request	application/ocsp-request	[RFC6960]
198	application	ocsp-response	application/ocsp-response	[RFC6960]
199	application	octet-stream	application/octet-stream	[RFC2045][RFC2046]
200	application	oda	application/ODA	[RFC2045][RFC2046]
201	application	ODX	application/ODX	[ASAM][Thomas_Thomsen]
202	application	oebps-package+xml	application/oebps-package+xml	[RFC4839]
203	application	ogg	application/ogg	[RFC5334][RFC7845]
204	application	oxps	application/oxps	[Ecma_International_Helpdesk]
205	application	p2p-overlay+xml	application/p2p-overlay+xml	[RFC6940]
206	application	parityfec		[RFC5109]
207	application	patch-ops-error+xml	application/patch-ops-error+xml	[RFC5261]
208	application	pdf	application/pdf	[RFC3778]
209	application	PDX	application/PDX	[ASAM][Thomas_Thomsen]
210	application	pgp-encrypted	application/pgp-encrypted	[RFC3156]
211	application	pgp-keys		[RFC3156]
212	application	pgp-signature	application/pgp-signature	[RFC3156]
213	application	pidf-diff+xml	application/pidf-diff+xml	[RFC5262]
214	application	pidf+xml	application/pidf+xml	[RFC3863]
215	application	pkcs10	application/pkcs10	[RFC5967]
216	application	pkcs7-mime	application/pkcs7-mime	[RFC5751][RFC7114]
217	application	pkcs7-signature	application/pkcs7-signature	[RFC5751]
218	application	pkcs8	application/pkcs8	[RFC5958]
219	application	pkcs12	application/pkcs12	[IETF]
220	application	pkix-attr-cert	application/pkix-attr-cert	[RFC5877]
221	application	pkix-cert	application/pkix-cert	[RFC2585]
222	application	pkix-crl	application/pkix-crl	[RFC2585]
223	application	pkix-pkipath	application/pkix-pkipath	[RFC6066]
224	application	pkixcmp	application/pkixcmp	[RFC2510]
225	application	pls+xml	application/pls+xml	[RFC4267]
226	application	poc-settings+xml	application/poc-settings+xml	[RFC4354]
227	application	postscript	application/postscript	[RFC2045][RFC2046]
228	application	ppsp-tracker+json	application/ppsp-tracker+json	[RFC7846]
229	application	problem+json	application/problem+json	[RFC7807]
230	application	problem+xml	application/problem+xml	[RFC7807]
231	application	provenance+xml	application/provenance+xml	[W3C][Ivan_Herman]
232	application	prs.alvestrand.titrax-sheet	application/prs.alvestrand.titrax-sheet	[Harald_T._Alvestrand]
233	application	prs.cww	application/prs.cww	[Khemchart_Rungchavalnont]
234	application	prs.hpub+zip	application/prs.hpub+zip	[Giulio_Zambon]
235	application	prs.nprend	application/prs.nprend	[Jay_Doggett]
236	application	prs.plucker	application/prs.plucker	[Bill_Janssen]
237	application	prs.rdf-xml-crypt	application/prs.rdf-xml-crypt	[Toby_Inkster]
238	application	prs.xsf+xml	application/prs.xsf+xml	[Maik_Stührenberg]
239	application	pskc+xml	application/pskc+xml	[RFC6030]
240	application	rdf+xml	application/rdf+xml	[RFC3870]
241	application	qsig	application/QSIG	[RFC3204]
242	application	raptorfec	application/raptorfec	[RFC6682]
243	application	rdap+json	application/rdap+json	[RFC7483]
244	application	reginfo+xml	application/reginfo+xml	[RFC3680]
245	application	relax-ng-compact-syntax	application/relax-ng-compact-syntax	[http://www.jtc1sc34.org/repository/0661.pdf]
246	application	remote-printing	application/remote-printing	[RFC1486][Marshall_Rose]
247	application	reputon+json	application/reputon+json	[RFC7071]
248	application	resource-lists-diff+xml	application/resource-lists-diff+xml	[RFC5362]
249	application	resource-lists+xml	application/resource-lists+xml	[RFC4826]
250	application	rfc+xml	application/rfc+xml	[RFC-iab-xml2rfc-04]
251	application	riscos	application/riscos	[Nick_Smith]
252	application	rlmi+xml	application/rlmi+xml	[RFC4662]
253	application	rls-services+xml	application/rls-services+xml	[RFC4826]
254	application	rpki-ghostbusters	application/rpki-ghostbusters	[RFC6493]
255	application	rpki-manifest	application/rpki-manifest	[RFC6481]
256	application	rpki-roa	application/rpki-roa	[RFC6481]
257	application	rpki-updown	application/rpki-updown	[RFC6492]
258	application	rtf	application/rtf	[Paul_Lindner]
259	application	rtploopback	application/rtploopback	[RFC6849]
260	application	rtx	application/rtx	[RFC4588]
261	application	samlassertion+xml	application/samlassertion+xml	[OASIS_Security_Services_Technical_Committee_SSTC]
262	application	samlmetadata+xml	application/samlmetadata+xml	[OASIS_Security_Services_Technical_Committee_SSTC]
263	application	sbml+xml	application/sbml+xml	[RFC3823]
264	application	scaip+xml	application/scaip+xml	[SIS][Oskar_Jonsson]
265	application	scim+json	application/scim+json	[RFC7644]
266	application	scvp-cv-request	application/scvp-cv-request	[RFC5055]
267	application	scvp-cv-response	application/scvp-cv-response	[RFC5055]
268	application	scvp-vp-request	application/scvp-vp-request	[RFC5055]
269	application	scvp-vp-response	application/scvp-vp-response	[RFC5055]
270	application	sdp	application/sdp	[RFC4566]
271	application	sep-exi	application/sep-exi	[Robby_Simpson][ZigBee]
272	application	sep+xml	application/sep+xml	[Robby_Simpson][ZigBee]
273	application	session-info	application/session-info	[_3GPP][Frederic_Firmin]
274	application	set-payment	application/set-payment	[Brian_Korver]
275	application	set-payment-initiation	application/set-payment-initiation	[Brian_Korver]
276	application	set-registration	application/set-registration	[Brian_Korver]
277	application	set-registration-initiation	application/set-registration-initiation	[Brian_Korver]
278	application	sgml	application/SGML	[RFC1874]
279	application	sgml-open-catalog	application/sgml-open-catalog	[Paul_Grosso]
280	application	shf+xml	application/shf+xml	[RFC4194]
281	application	sieve	application/sieve	[RFC5228]
282	application	simple-filter+xml	application/simple-filter+xml	[RFC4661]
283	application	simple-message-summary	application/simple-message-summary	[RFC3842]
284	application	simpleSymbolContainer	application/simpleSymbolContainer	[_3GPP]
285	application	slate	application/slate	[Terry_Crowley]
286	application	smil - OBSOLETED in favor of application/smil+xml	application/smil	[RFC4536]
287	application	smil+xml	application/smil+xml	[RFC4536]
288	application	smpte336m	application/smpte336m	[RFC6597]
289	application	soap+fastinfoset	application/soap+fastinfoset	[ITU-T_ASN.1_Rapporteur]
290	application	soap+xml	application/soap+xml	[RFC3902]
291	application	sparql-query		[W3C][http://www.w3.org/TR/2007/CR-rdf-sparql-query-20070614/#mediaType]
292	application	sparql-results+xml		[W3C][http://www.w3.org/TR/2007/CR-rdf-sparql-XMLres-20070925/#mime]
293	application	spirits-event+xml	application/spirits-event+xml	[RFC3910]
294	application	sql	application/sql	[RFC6922]
295	application	srgs	application/srgs	[RFC4267]
296	application	srgs+xml	application/srgs+xml	[RFC4267]
297	application	sru+xml	application/sru+xml	[RFC6207]
298	application	ssml+xml	application/ssml+xml	[RFC4267]
299	application	tamp-apex-update	application/tamp-apex-update	[RFC5934]
300	application	tamp-apex-update-confirm	application/tamp-apex-update-confirm	[RFC5934]
301	application	tamp-community-update	application/tamp-community-update	[RFC5934]
302	application	tamp-community-update-confirm	application/tamp-community-update-confirm	[RFC5934]
303	application	tamp-error	application/tamp-error	[RFC5934]
304	application	tamp-sequence-adjust	application/tamp-sequence-adjust	[RFC5934]
305	application	tamp-sequence-adjust-confirm	application/tamp-sequence-adjust-confirm	[RFC5934]
306	application	tamp-status-query	application/tamp-status-query	[RFC5934]
307	application	tamp-status-response	application/tamp-status-response	[RFC5934]
308	application	tamp-update	application/tamp-update	[RFC5934]
309	application	tamp-update-confirm	application/tamp-update-confirm	[RFC5934]
310	application	tei+xml	application/tei+xml	[RFC6129]
311	application	thraud+xml	application/thraud+xml	[RFC5941]
312	application	timestamp-query	application/timestamp-query	[RFC3161]
313	application	timestamp-reply	application/timestamp-reply	[RFC3161]
314	application	timestamped-data	application/timestamped-data	[RFC5955]
315	application	ttml+xml	application/ttml+xml	[W3C][W3C_Timed_Text_Working_Group]
316	application	tve-trigger	application/tve-trigger	[Linda_Welsh]
317	application	ulpfec	application/ulpfec	[RFC5109]
318	application	urc-grpsheet+xml	application/urc-grpsheet+xml	[Gottfried_Zimmermann][ISO-IEC JTC1]
319	application	urc-ressheet+xml	application/urc-ressheet+xml	[Gottfried_Zimmermann][ISO-IEC JTC1]
320	application	urc-targetdesc+xml	application/urc-targetdesc+xml	[Gottfried_Zimmermann][ISO-IEC JTC1]
321	application	urc-uisocketdesc+xml	application/urc-uisocketdesc+xml	[Gottfried_Zimmermann]
322	application	vcard+json	application/vcard+json	[RFC7095]
323	application	vcard+xml	application/vcard+xml	[RFC6351]
324	application	vemmi	application/vemmi	[RFC2122]
325	application	vnd.3gpp.access-transfer-events+xml	application/vnd.3gpp.access-transfer-events+xml	[Frederic_Firmin]
326	application	vnd.3gpp.bsf+xml	application/vnd.3gpp.bsf+xml	[John_M_Meredith]
327	application	vnd.3gpp.mid-call+xml	application/vnd.3gpp.mid-call+xml	[Frederic_Firmin]
328	application	vnd.3gpp.pic-bw-large	application/vnd.3gpp.pic-bw-large	[John_M_Meredith]
1162	application	wita	application/wita	[Larry_Campbell]
329	application	vnd.3gpp.pic-bw-small	application/vnd.3gpp.pic-bw-small	[John_M_Meredith]
330	application	vnd.3gpp.pic-bw-var	application/vnd.3gpp.pic-bw-var	[John_M_Meredith]
331	application	vnd.3gpp-prose-pc3ch+xml	application/vnd.3gpp-prose-pc3ch+xml	[Frederic_Firmin]
332	application	vnd.3gpp-prose+xml	application/vnd.3gpp-prose+xml	[Frederic_Firmin]
333	application	vnd.3gpp.sms	application/vnd.3gpp.sms	[John_M_Meredith]
334	application	vnd.3gpp.sms+xml	application/vnd.3gpp.sms+xml	[Frederic_Firmin]
335	application	vnd.3gpp.srvcc-ext+xml	application/vnd.3gpp.srvcc-ext+xml	[Frederic_Firmin]
336	application	vnd.3gpp.SRVCC-info+xml	application/vnd.3gpp.SRVCC-info+xml	[Frederic_Firmin]
337	application	vnd.3gpp.state-and-event-info+xml	application/vnd.3gpp.state-and-event-info+xml	[Frederic_Firmin]
338	application	vnd.3gpp.ussd+xml	application/vnd.3gpp.ussd+xml	[Frederic_Firmin]
339	application	vnd.3gpp2.bcmcsinfo+xml	application/vnd.3gpp2.bcmcsinfo+xml	[Andy_Dryden]
340	application	vnd.3gpp2.sms	application/vnd.3gpp2.sms	[AC_Mahendran]
341	application	vnd.3gpp2.tcap	application/vnd.3gpp2.tcap	[AC_Mahendran]
342	application	vnd.3lightssoftware.imagescal	application/vnd.3lightssoftware.imagescal	[Gus_Asadi]
343	application	vnd.3M.Post-it-Notes	application/vnd.3M.Post-it-Notes	[Michael_OBrien]
344	application	vnd.accpac.simply.aso	application/vnd.accpac.simply.aso	[Steve_Leow]
345	application	vnd.accpac.simply.imp	application/vnd.accpac.simply.imp	[Steve_Leow]
346	application	vnd.acucobol	application/vnd-acucobol	[Dovid_Lubin]
347	application	vnd.acucorp	application/vnd.acucorp	[Dovid_Lubin]
348	application	vnd.adobe.flash.movie	application/vnd.adobe.flash-movie	[Henrik_Andersson]
349	application	vnd.adobe.formscentral.fcdt	application/vnd.adobe.formscentral.fcdt	[Chris_Solc]
350	application	vnd.adobe.fxp	application/vnd.adobe.fxp	[Robert_Brambley][Steven_Heintz]
351	application	vnd.adobe.partial-upload	application/vnd.adobe.partial-upload	[Tapani_Otala]
352	application	vnd.adobe.xdp+xml	application/vnd.adobe.xdp+xml	[John_Brinkman]
353	application	vnd.adobe.xfdf	application/vnd.adobe.xfdf	[Roberto_Perelman]
354	application	vnd.aether.imp	application/vnd.aether.imp	[Jay_Moskowitz]
355	application	vnd.ah-barcode	application/vnd.ah-barcode	[Katsuhiko_Ichinose]
356	application	vnd.ahead.space	application/vnd.ahead.space	[Tor_Kristensen]
357	application	vnd.airzip.filesecure.azf	application/vnd.airzip.filesecure.azf	[Daniel_Mould][Gary_Clueit]
358	application	vnd.airzip.filesecure.azs	application/vnd.airzip.filesecure.azs	[Daniel_Mould][Gary_Clueit]
359	application	vnd.amazon.mobi8-ebook	application/vnd.amazon.mobi8-ebook	[Kim_Scarborough]
360	application	vnd.americandynamics.acc	application/vnd.americandynamics.acc	[Gary_Sands]
361	application	vnd.amiga.ami	application/vnd.amiga.ami	[Kevin_Blumberg]
362	application	vnd.amundsen.maze+xml	application/vnd.amundsen.maze+xml	[Mike_Amundsen]
363	application	vnd.anki	application/vnd.anki	[Kerrick_Staley]
364	application	vnd.anser-web-certificate-issue-initiation	application/vnd.anser-web-certificate-issue-initiation	[Hiroyoshi_Mori]
365	application	vnd.antix.game-component	application/vnd.antix.game-component	[Daniel_Shelton]
366	application	vnd.apache.thrift.binary	application/vnd.apache.thrift.binary	[Roger_Meier]
367	application	vnd.apache.thrift.compact	application/vnd.apache.thrift.compact	[Roger_Meier]
368	application	vnd.apache.thrift.json	application/vnd.apache.thrift.json	[Roger_Meier]
369	application	vnd.api+json	application/vnd.api+json	[Steve_Klabnik]
370	application	vnd.apple.mpegurl	application/vnd.apple.mpegurl	[David_Singer][Roger_Pantos]
371	application	vnd.apple.installer+xml	application/vnd.apple.installer+xml	[Peter_Bierman]
372	application	vnd.arastra.swi - OBSOLETED in favor of application/vnd.aristanetworks.swi	application/vnd.arastra.swi	[Bill_Fenner]
373	application	vnd.aristanetworks.swi	application/vnd.aristanetworks.swi	[Bill_Fenner]
374	application	vnd.artsquare	application/vnd.artsquare	[Christopher_Smith]
375	application	vnd.astraea-software.iota	application/vnd.astraea-software.iota	[Christopher_Snazell]
376	application	vnd.audiograph	application/vnd.audiograph	[Horia_Cristian_Slusanschi]
377	application	vnd.autopackage	application/vnd.autopackage	[Mike_Hearn]
378	application	vnd.avistar+xml	application/vnd.avistar+xml	[Vladimir_Vysotsky]
379	application	vnd.balsamiq.bmml+xml	application/vnd.balsamiq.bmml+xml	[Giacomo_Guilizzoni]
380	application	vnd.balsamiq.bmpr	application/vnd.balsamiq.bmpr	[Giacomo_Guilizzoni]
381	application	vnd.bekitzur-stech+json	application/vnd.bekitzur-stech+json	[Jegulsky]
382	application	vnd.biopax.rdf+xml	application/vnd.biopax.rdf+xml	[Pathway_Commons]
383	application	vnd.blueice.multipass	application/vnd.blueice.multipass	[Thomas_Holmstrom]
384	application	vnd.bluetooth.ep.oob	application/vnd.bluetooth.ep.oob	[Mike_Foley]
385	application	vnd.bluetooth.le.oob	application/vnd.bluetooth.le.oob	[Mark_Powell]
386	application	vnd.bmi	application/vnd.bmi	[Tadashi_Gotoh]
387	application	vnd.businessobjects	application/vnd.businessobjects	[Philippe_Imoucha]
388	application	vnd.cab-jscript	application/vnd.cab-jscript	[Joerg_Falkenberg]
389	application	vnd.canon-cpdl	application/vnd.canon-cpdl	[Shin_Muto]
390	application	vnd.canon-lips	application/vnd.canon-lips	[Shin_Muto]
391	application	vnd.cendio.thinlinc.clientconf	application/vnd.cendio.thinlinc.clientconf	[Peter_Astrand]
392	application	vnd.century-systems.tcp_stream	application/vnd.century-systems.tcp_stream	[Shuji_Fujii]
393	application	vnd.chemdraw+xml	application/vnd.chemdraw+xml	[Glenn_Howes]
394	application	vnd.chess-pgn	application/vnd.chess-pgn	[Kim_Scarborough]
395	application	vnd.chipnuts.karaoke-mmd	application/vnd.chipnuts.karaoke-mmd	[Chunyun_Xiong]
396	application	vnd.cinderella	application/vnd.cinderella	[Ulrich_Kortenkamp]
397	application	vnd.cirpack.isdn-ext	application/vnd.cirpack.isdn-ext	[Pascal_Mayeux]
398	application	vnd.citationstyles.style+xml	application/vnd.citationstyles.style+xml	[Rintze_M._Zelle]
399	application	vnd.claymore	application/vnd.claymore	[Ray_Simpson]
400	application	vnd.cloanto.rp9	application/vnd.cloanto.rp9	[Mike_Labatt]
401	application	vnd.clonk.c4group	application/vnd.clonk.c4group	[Guenther_Brammer]
402	application	vnd.cluetrust.cartomobile-config	application/vnd.cluetrust.cartomobile-config	[Gaige_Paulsen]
403	application	vnd.cluetrust.cartomobile-config-pkg	application/vnd.cluetrust.cartomobile-config-pkg	[Gaige_Paulsen]
404	application	vnd.coffeescript	application/vnd.coffeescript	[Devyn_Collier_Johnson]
405	application	vnd.collection.doc+json	application/vnd.collection.doc+json	[Irakli_Nadareishvili]
406	application	vnd.collection+json	application/vnd.collection+json	[Mike_Amundsen]
407	application	vnd.collection.next+json	application/vnd.collection.next+json	[Ioseb_Dzmanashvili]
408	application	vnd.comicbook+zip	application/vnd.comicbook+zip	[Kim_Scarborough]
409	application	vnd.commerce-battelle	application/vnd.commerce-battelle	[David_Applebaum]
410	application	vnd.commonspace	application/vnd.commonspace	[Ravinder_Chandhok]
411	application	vnd.coreos.ignition+json	application/vnd.coreos.ignition+json	[Alex_Crawford]
412	application	vnd.cosmocaller	application/vnd.cosmocaller	[Steve_Dellutri]
413	application	vnd.contact.cmsg	application/vnd.contact.cmsg	[Frank_Patz]
414	application	vnd.crick.clicker	application/vnd.crick.clicker	[Andrew_Burt]
415	application	vnd.crick.clicker.keyboard	application/vnd.crick.clicker.keyboard	[Andrew_Burt]
416	application	vnd.crick.clicker.palette	application/vnd.crick.clicker.palette	[Andrew_Burt]
417	application	vnd.crick.clicker.template	application/vnd.crick.clicker.template	[Andrew_Burt]
418	application	vnd.crick.clicker.wordbank	application/vnd.crick.clicker.wordbank	[Andrew_Burt]
419	application	vnd.criticaltools.wbs+xml	application/vnd.criticaltools.wbs+xml	[Jim_Spiller]
420	application	vnd.ctc-posml	application/vnd.ctc-posml	[Bayard_Kohlhepp]
421	application	vnd.ctct.ws+xml	application/vnd.ctct.ws+xml	[Jim_Ancona]
422	application	vnd.cups-pdf	application/vnd.cups-pdf	[Michael_Sweet]
423	application	vnd.cups-postscript	application/vnd.cups-postscript	[Michael_Sweet]
424	application	vnd.cups-ppd	application/vnd.cups-ppd	[Michael_Sweet]
425	application	vnd.cups-raster	application/vnd.cups-raster	[Michael_Sweet]
426	application	vnd.cups-raw	application/vnd.cups-raw	[Michael_Sweet]
427	application	vnd.curl	application/vnd-curl	[Robert_Byrnes]
428	application	vnd.cyan.dean.root+xml	application/vnd.cyan.dean.root+xml	[Matt_Kern]
429	application	vnd.cybank	application/vnd.cybank	[Nor_Helmee]
430	application	vnd.d2l.coursepackage1p0+zip	application/vnd.d2l.coursepackage1p0+zip	[Viktor_Haag]
431	application	vnd.dart	application/vnd-dart	[Anders_Sandholm]
432	application	vnd.data-vision.rdz	application/vnd.data-vision.rdz	[James_Fields]
433	application	vnd.debian.binary-package	application/vnd.debian.binary-package	[Charles_Plessy]
434	application	vnd.dece.data	application/vnd.dece.data	[Michael_A_Dolan]
435	application	vnd.dece.ttml+xml	application/vnd.dece.ttml+xml	[Michael_A_Dolan]
436	application	vnd.dece.unspecified	application/vnd.dece.unspecified	[Michael_A_Dolan]
437	application	vnd.dece.zip	application/vnd.dece-zip	[Michael_A_Dolan]
438	application	vnd.denovo.fcselayout-link	application/vnd.denovo.fcselayout-link	[Michael_Dixon]
439	application	vnd.desmume.movie	application/vnd.desmume-movie	[Henrik_Andersson]
440	application	vnd.dir-bi.plate-dl-nosuffix	application/vnd.dir-bi.plate-dl-nosuffix	[Yamanaka]
441	application	vnd.dm.delegation+xml	application/vnd.dm.delegation+xml	[Axel_Ferrazzini]
442	application	vnd.dna	application/vnd.dna	[Meredith_Searcy]
443	application	vnd.document+json	application/vnd.document+json	[Tom_Christie]
444	application	vnd.dolby.mobile.1	application/vnd.dolby.mobile.1	[Steve_Hattersley]
445	application	vnd.dolby.mobile.2	application/vnd.dolby.mobile.2	[Steve_Hattersley]
446	application	vnd.doremir.scorecloud-binary-document	application/vnd.doremir.scorecloud-binary-document	[Erik_Ronström]
447	application	vnd.dpgraph	application/vnd.dpgraph	[David_Parker]
448	application	vnd.dreamfactory	application/vnd.dreamfactory	[William_C._Appleton]
449	application	vnd.drive+json	application/vnd.drive+json	[Keith_Kester]
450	application	vnd.dtg.local	application/vnd.dtg.local	[Ali_Teffahi]
451	application	vnd.dtg.local.flash	application/vnd.dtg.local.flash	[Ali_Teffahi]
452	application	vnd.dtg.local.html	application/vnd.dtg.local-html	[Ali_Teffahi]
453	application	vnd.dvb.ait	application/vnd.dvb.ait	[Peter_Siebert][Michael_Lagally]
454	application	vnd.dvb.dvbj	application/vnd.dvb.dvbj	[Peter_Siebert][Michael_Lagally]
455	application	vnd.dvb.esgcontainer	application/vnd.dvb.esgcontainer	[Joerg_Heuer]
456	application	vnd.dvb.ipdcdftnotifaccess	application/vnd.dvb.ipdcdftnotifaccess	[Roy_Yue]
457	application	vnd.dvb.ipdcesgaccess	application/vnd.dvb.ipdcesgaccess	[Joerg_Heuer]
458	application	vnd.dvb.ipdcesgaccess2	application/vnd.dvb.ipdcesgaccess2	[Jerome_Marcon]
459	application	vnd.dvb.ipdcesgpdd	application/vnd.dvb.ipdcesgpdd	[Jerome_Marcon]
460	application	vnd.dvb.ipdcroaming	application/vnd.dvb.ipdcroaming	[Yiling_Xu]
461	application	vnd.dvb.iptv.alfec-base	application/vnd.dvb.iptv.alfec-base	[Jean-Baptiste_Henry]
462	application	vnd.dvb.iptv.alfec-enhancement	application/vnd.dvb.iptv.alfec-enhancement	[Jean-Baptiste_Henry]
463	application	vnd.dvb.notif-aggregate-root+xml	application/vnd.dvb.notif-aggregate-root+xml	[Roy_Yue]
464	application	vnd.dvb.notif-container+xml	application/vnd.dvb.notif-container+xml	[Roy_Yue]
465	application	vnd.dvb.notif-generic+xml	application/vnd.dvb.notif-generic+xml	[Roy_Yue]
466	application	vnd.dvb.notif-ia-msglist+xml	application/vnd.dvb.notif-ia-msglist+xml	[Roy_Yue]
467	application	vnd.dvb.notif-ia-registration-request+xml	application/vnd.dvb.notif-ia-registration-request+xml	[Roy_Yue]
468	application	vnd.dvb.notif-ia-registration-response+xml	application/vnd.dvb.notif-ia-registration-response+xml	[Roy_Yue]
469	application	vnd.dvb.notif-init+xml	application/vnd.dvb.notif-init+xml	[Roy_Yue]
470	application	vnd.dvb.pfr	application/vnd.dvb.pfr	[Peter_Siebert][Michael_Lagally]
471	application	vnd.dvb.service	application/vnd.dvb_service	[Peter_Siebert][Michael_Lagally]
472	application	vnd.dxr	application/vnd-dxr	[Michael_Duffy]
473	application	vnd.dynageo	application/vnd.dynageo	[Roland_Mechling]
474	application	vnd.dzr	application/vnd.dzr	[Carl_Anderson]
475	application	vnd.easykaraoke.cdgdownload	application/vnd.easykaraoke.cdgdownload	[Iain_Downs]
476	application	vnd.ecdis-update	application/vnd.ecdis-update	[Gert_Buettgenbach]
477	application	vnd.ecowin.chart	application/vnd.ecowin.chart	[Thomas_Olsson]
478	application	vnd.ecowin.filerequest	application/vnd.ecowin.filerequest	[Thomas_Olsson]
479	application	vnd.ecowin.fileupdate	application/vnd.ecowin.fileupdate	[Thomas_Olsson]
480	application	vnd.ecowin.series	application/vnd.ecowin.series	[Thomas_Olsson]
481	application	vnd.ecowin.seriesrequest	application/vnd.ecowin.seriesrequest	[Thomas_Olsson]
482	application	vnd.ecowin.seriesupdate	application/vnd.ecowin.seriesupdate	[Thomas_Olsson]
483	application	vnd.emclient.accessrequest+xml	application/vnd.emclient.accessrequest+xml	[Filip_Navara]
484	application	vnd.enliven	application/vnd.enliven	[Paul_Santinelli_Jr.]
485	application	vnd.enphase.envoy	application/vnd.enphase.envoy	[Chris_Eich]
486	application	vnd.eprints.data+xml	application/vnd.eprints.data+xml	[Tim_Brody]
487	application	vnd.epson.esf	application/vnd.epson.esf	[Shoji_Hoshina]
488	application	vnd.epson.msf	application/vnd.epson.msf	[Shoji_Hoshina]
489	application	vnd.epson.quickanime	application/vnd.epson.quickanime	[Yu_Gu]
490	application	vnd.epson.salt	application/vnd.epson.salt	[Yasuhito_Nagatomo]
491	application	vnd.epson.ssf	application/vnd.epson.ssf	[Shoji_Hoshina]
492	application	vnd.ericsson.quickcall	application/vnd.ericsson.quickcall	[Paul_Tidwell]
493	application	vnd.espass-espass+zip	application/vnd.espass-espass+zip	[Marcus_Ligi_Büschleb]
494	application	vnd.eszigno3+xml	application/vnd.eszigno3+xml	[Szilveszter_Tóth]
495	application	vnd.etsi.aoc+xml	application/vnd.etsi.aoc+xml	[Shicheng_Hu]
496	application	vnd.etsi.asic-s+zip	application/vnd.etsi.asic-s+zip	[Miguel_Angel_Reina_Ortega]
497	application	vnd.etsi.asic-e+zip	application/vnd.etsi.asic-e+zip	[Miguel_Angel_Reina_Ortega]
498	application	vnd.etsi.cug+xml	application/vnd.etsi.cug+xml	[Shicheng_Hu]
499	application	vnd.etsi.iptvcommand+xml	application/vnd.etsi.iptvcommand+xml	[Shicheng_Hu]
500	application	vnd.etsi.iptvdiscovery+xml	application/vnd.etsi.iptvdiscovery+xml	[Shicheng_Hu]
501	application	vnd.etsi.iptvprofile+xml	application/vnd.etsi.iptvprofile+xml	[Shicheng_Hu]
502	application	vnd.etsi.iptvsad-bc+xml	application/vnd.etsi.iptvsad-bc+xml	[Shicheng_Hu]
503	application	vnd.etsi.iptvsad-cod+xml	application/vnd.etsi.iptvsad-cod+xml	[Shicheng_Hu]
504	application	vnd.etsi.iptvsad-npvr+xml	application/vnd.etsi.iptvsad-npvr+xml	[Shicheng_Hu]
505	application	vnd.etsi.iptvservice+xml	application/vnd.etsi.iptvservice+xml	[Miguel_Angel_Reina_Ortega]
506	application	vnd.etsi.iptvsync+xml	application/vnd.etsi.iptvsync+xml	[Miguel_Angel_Reina_Ortega]
507	application	vnd.etsi.iptvueprofile+xml	application/vnd.etsi.iptvueprofile+xml	[Shicheng_Hu]
508	application	vnd.etsi.mcid+xml	application/vnd.etsi.mcid+xml	[Shicheng_Hu]
509	application	vnd.etsi.mheg5	application/vnd.etsi.mheg5	[Miguel_Angel_Reina_Ortega][Ian_Medland]
510	application	vnd.etsi.overload-control-policy-dataset+xml	application/vnd.etsi.overload-control-policy-dataset+xml	[Miguel_Angel_Reina_Ortega]
511	application	vnd.etsi.pstn+xml	application/vnd.etsi.pstn+xml	[Jiwan_Han][Thomas_Belling]
512	application	vnd.etsi.sci+xml	application/vnd.etsi.sci+xml	[Shicheng_Hu]
513	application	vnd.etsi.simservs+xml	application/vnd.etsi.simservs+xml	[Shicheng_Hu]
514	application	vnd.etsi.timestamp-token	application/vnd.etsi.timestamp-token	[Miguel_Angel_Reina_Ortega]
515	application	vnd.etsi.tsl+xml	application/vnd.etsi.tsl+xml	[Shicheng_Hu]
516	application	vnd.etsi.tsl.der	application/vnd.etsi.tsl.der	[Shicheng_Hu]
517	application	vnd.eudora.data	application/vnd.eudora.data	[Pete_Resnick]
518	application	vnd.ezpix-album	application/vnd.ezpix-album	[ElectronicZombieCorp]
519	application	vnd.ezpix-package	application/vnd.ezpix-package	[ElectronicZombieCorp]
520	application	vnd.f-secure.mobile	application/vnd.f-secure.mobile	[Samu_Sarivaara]
521	application	vnd.fastcopy-disk-image	application/vnd.fastcopy-disk-image	[Thomas_Huth]
522	application	vnd.fdf	application/vnd-fdf	[Steve_Zilles]
523	application	vnd.fdsn.mseed	application/vnd.fdsn.mseed	[Chad_Trabant]
524	application	vnd.fdsn.seed	application/vnd.fdsn.seed	[Chad_Trabant]
525	application	vnd.ffsns	application/vnd.ffsns	[Holstage]
526	application	vnd.filmit.zfc	application/vnd.filmit.zfc	[Harms_Moeller]
527	application	vnd.fints	application/vnd.fints	[Ingo_Hammann]
528	application	vnd.firemonkeys.cloudcell	application/vnd.firemonkeys.cloudcell	[Alex_Dubov]
529	application	vnd.FloGraphIt	application/vnd.FloGraphIt	[Dick_Floersch]
530	application	vnd.fluxtime.clip	application/vnd.fluxtime.clip	[Marc_Winter]
531	application	vnd.font-fontforge-sfd	application/vnd.font-fontforge-sfd	[George_Williams]
532	application	vnd.framemaker	application/vnd.framemaker	[Mike_Wexler]
533	application	vnd.frogans.fnc	application/vnd.frogans.fnc	[Alexis_Tamas]
534	application	vnd.frogans.ltf	application/vnd.frogans.ltf	[Alexis_Tamas]
535	application	vnd.fsc.weblaunch	application/vnd.fsc.weblaunch	[Derek_Smith]
536	application	vnd.fujitsu.oasys	application/vnd.fujitsu.oasys	[Nobukazu_Togashi]
537	application	vnd.fujitsu.oasys2	application/vnd.fujitsu.oasys2	[Nobukazu_Togashi]
538	application	vnd.fujitsu.oasys3	application/vnd.fujitsu.oasys3	[Seiji_Okudaira]
539	application	vnd.fujitsu.oasysgp	application/vnd.fujitsu.oasysgp	[Masahiko_Sugimoto]
540	application	vnd.fujitsu.oasysprs	application/vnd.fujitsu.oasysprs	[Masumi_Ogita]
541	application	vnd.fujixerox.ART4	application/vnd.fujixerox.ART4	[Fumio_Tanabe]
542	application	vnd.fujixerox.ART-EX	application/vnd.fujixerox.ART-EX	[Fumio_Tanabe]
543	application	vnd.fujixerox.ddd	application/vnd.fujixerox.ddd	[Masanori_Onda]
544	application	vnd.fujixerox.docuworks	application/vnd.fujixerox.docuworks	[Yasuo_Taguchi]
545	application	vnd.fujixerox.docuworks.binder	application/vnd.fujixerox.docuworks.binder	[Takashi_Matsumoto]
546	application	vnd.fujixerox.docuworks.container	application/vnd.fujixerox.docuworks.container	[Kiyoshi_Tashiro]
547	application	vnd.fujixerox.HBPL	application/vnd.fujixerox.HBPL	[Fumio_Tanabe]
548	application	vnd.fut-misnet	application/vnd.fut-misnet	[Jann_Pruulman]
549	application	vnd.fuzzysheet	application/vnd.fuzzysheet	[Simon_Birtwistle]
550	application	vnd.genomatix.tuxedo	application/vnd.genomatix.tuxedo	[Torben_Frey]
551	application	vnd.geo+json (OBSOLETED by [RFC7946] in favor of application/geo+json)	application/vnd.geo+json	[Sean_Gillies]
552	application	vnd.geocube+xml - OBSOLETED by request	application/vnd.geocube+xml	[Francois_Pirsch]
553	application	vnd.geogebra.file	application/vnd.geogebra.file	[GeoGebra][Yves_Kreis]
554	application	vnd.geogebra.tool	application/vnd.geogebra.tool	[GeoGebra][Yves_Kreis]
555	application	vnd.geometry-explorer	application/vnd.geometry-explorer	[Michael_Hvidsten]
556	application	vnd.geonext	application/vnd.geonext	[Matthias_Ehmann]
557	application	vnd.geoplan	application/vnd.geoplan	[Christian_Mercat]
558	application	vnd.geospace	application/vnd.geospace	[Christian_Mercat]
559	application	vnd.gerber	application/vnd.gerber	[Thomas_Weyn]
560	application	vnd.globalplatform.card-content-mgt	application/vnd.globalplatform.card-content-mgt	[Gil_Bernabeu]
561	application	vnd.globalplatform.card-content-mgt-response	application/vnd.globalplatform.card-content-mgt-response	[Gil_Bernabeu]
562	application	vnd.gmx - DEPRECATED	application/vnd.gmx	[Christian_V._Sciberras]
563	application	vnd.google-earth.kml+xml	application/vnd.google-earth.kml+xml	[Michael_Ashbridge]
564	application	vnd.google-earth.kmz	application/vnd.google-earth.kmz	[Michael_Ashbridge]
565	application	vnd.gov.sk.e-form+xml	application/vnd.gov.sk.e-form+xml	[Peter_Biro][Stefan_Szilva]
566	application	vnd.gov.sk.e-form+zip	application/vnd.gov.sk.e-form+zip	[Peter_Biro][Stefan_Szilva]
567	application	vnd.gov.sk.xmldatacontainer+xml	application/vnd.gov.sk.xmldatacontainer+xml	[Peter_Biro][Stefan_Szilva]
568	application	vnd.grafeq	application/vnd.grafeq	[Jeff_Tupper]
569	application	vnd.gridmp	application/vnd.gridmp	[Jeff_Lawson]
570	application	vnd.groove-account	application/vnd.groove-account	[Todd_Joseph]
571	application	vnd.groove-help	application/vnd.groove-help	[Todd_Joseph]
572	application	vnd.groove-identity-message	application/vnd.groove-identity-message	[Todd_Joseph]
573	application	vnd.groove-injector	application/vnd.groove-injector	[Todd_Joseph]
574	application	vnd.groove-tool-message	application/vnd.groove-tool-message	[Todd_Joseph]
575	application	vnd.groove-tool-template	application/vnd.groove-tool-template	[Todd_Joseph]
576	application	vnd.groove-vcard	application/vnd.groove-vcard	[Todd_Joseph]
577	application	vnd.hal+json	application/vnd.hal+json	[Mike_Kelly]
578	application	vnd.hal+xml	application/vnd.hal+xml	[Mike_Kelly]
579	application	vnd.HandHeld-Entertainment+xml	application/vnd.HandHeld-Entertainment+xml	[Eric_Hamilton]
580	application	vnd.hbci	application/vnd.hbci	[Ingo_Hammann]
581	application	vnd.hcl-bireports	application/vnd.hcl-bireports	[Doug_R._Serres]
582	application	vnd.hdt	application/vnd.hdt	[Javier_D._Fernández]
583	application	vnd.heroku+json	application/vnd.heroku+json	[Wesley_Beary]
584	application	vnd.hhe.lesson-player	application/vnd.hhe.lesson-player	[Randy_Jones]
585	application	vnd.hp-HPGL	application/vnd.hp-HPGL	[Bob_Pentecost]
586	application	vnd.hp-hpid	application/vnd.hp-hpid	[Aloke_Gupta]
587	application	vnd.hp-hps	application/vnd.hp-hps	[Steve_Aubrey]
588	application	vnd.hp-jlyt	application/vnd.hp-jlyt	[Amir_Gaash]
589	application	vnd.hp-PCL	application/vnd.hp-PCL	[Bob_Pentecost]
590	application	vnd.hp-PCLXL	application/vnd.hp-PCLXL	[Bob_Pentecost]
591	application	vnd.httphone	application/vnd.httphone	[Franck_Lefevre]
592	application	vnd.hydrostatix.sof-data	application/vnd.hydrostatix.sof-data	[Allen_Gillam]
593	application	vnd.hyperdrive+json	application/vnd.hyperdrive+json	[Daniel_Sims]
594	application	vnd.hzn-3d-crossword	application/vnd.hzn-3d-crossword	[James_Minnis]
595	application	vnd.ibm.afplinedata	application/vnd.ibm.afplinedata	[Roger_Buis]
596	application	vnd.ibm.electronic-media	application/vnd.ibm.electronic-media	[Bruce_Tantlinger]
597	application	vnd.ibm.MiniPay	application/vnd.ibm.MiniPay	[Amir_Herzberg]
598	application	vnd.ibm.modcap	application/vnd.ibm.modcap	[Reinhard_Hohensee]
599	application	vnd.ibm.rights-management	application/vnd.ibm.rights-management	[Bruce_Tantlinger]
600	application	vnd.ibm.secure-container	application/vnd.ibm.secure-container	[Bruce_Tantlinger]
601	application	vnd.iccprofile	application/vnd.iccprofile	[Phil_Green]
602	application	vnd.ieee.1905	application/vnd.ieee.1905	[Purva_R_Rajkotia]
603	application	vnd.igloader	application/vnd.igloader	[Tim_Fisher]
604	application	vnd.immervision-ivp	application/vnd.immervision-ivp	[Mathieu_Villegas]
605	application	vnd.immervision-ivu	application/vnd.immervision-ivu	[Mathieu_Villegas]
606	application	vnd.ims.imsccv1p1	application/vnd.ims.imsccv1p1	[Lisa_Mattson]
607	application	vnd.ims.imsccv1p2	application/vnd.ims.imsccv1p2	[Lisa_Mattson]
608	application	vnd.ims.imsccv1p3	application/vnd.ims.imsccv1p3	[Lisa_Mattson]
609	application	vnd.ims.lis.v2.result+json	application/vnd.ims.lis.v2.result+json	[Lisa_Mattson]
610	application	vnd.ims.lti.v2.toolconsumerprofile+json	application/vnd.ims.lti.v2.toolconsumerprofile+json	[Lisa_Mattson]
611	application	vnd.ims.lti.v2.toolproxy.id+json	application/vnd.ims.lti.v2.toolproxy.id+json	[Lisa_Mattson]
612	application	vnd.ims.lti.v2.toolproxy+json	application/vnd.ims.lti.v2.toolproxy+json	[Lisa_Mattson]
613	application	vnd.ims.lti.v2.toolsettings+json	application/vnd.ims.lti.v2.toolsettings+json	[Lisa_Mattson]
614	application	vnd.ims.lti.v2.toolsettings.simple+json	application/vnd.ims.lti.v2.toolsettings.simple+json	[Lisa_Mattson]
615	application	vnd.informedcontrol.rms+xml	application/vnd.informedcontrol.rms+xml	[Mark_Wahl]
616	application	vnd.infotech.project	application/vnd.infotech.project	[Charles_Engelke]
617	application	vnd.infotech.project+xml	application/vnd.infotech.project+xml	[Charles_Engelke]
618	application	vnd.informix-visionary - OBSOLETED in favor of application/vnd.visionary	application/vnd.informix-visionary	[Christopher_Gales]
619	application	vnd.innopath.wamp.notification	application/vnd.innopath.wamp.notification	[Takanori_Sudo]
620	application	vnd.insors.igm	application/vnd.insors.igm	[Jon_Swanson]
621	application	vnd.intercon.formnet	application/vnd.intercon.formnet	[Tom_Gurak]
622	application	vnd.intergeo	application/vnd.intergeo	[Yves_Kreis_2]
623	application	vnd.intertrust.digibox	application/vnd.intertrust.digibox	[Luke_Tomasello]
624	application	vnd.intertrust.nncp	application/vnd.intertrust.nncp	[Luke_Tomasello]
625	application	vnd.intu.qbo	application/vnd.intu.qbo	[Greg_Scratchley]
626	application	vnd.intu.qfx	application/vnd.intu.qfx	[Greg_Scratchley]
627	application	vnd.iptc.g2.catalogitem+xml	application/vnd.iptc.g2.catalogitem+xml	[Michael_Steidl]
628	application	vnd.iptc.g2.conceptitem+xml	application/vnd.iptc.g2.conceptitem+xml	[Michael_Steidl]
629	application	vnd.iptc.g2.knowledgeitem+xml	application/vnd.iptc.g2.knowledgeitem+xml	[Michael_Steidl]
630	application	vnd.iptc.g2.newsitem+xml	application/vnd.iptc.g2.newsitem+xml	[Michael_Steidl]
631	application	vnd.iptc.g2.newsmessage+xml	application/vnd.iptc.g2.newsmessage+xml	[Michael_Steidl]
632	application	vnd.iptc.g2.packageitem+xml	application/vnd.iptc.g2.packageitem+xml	[Michael_Steidl]
633	application	vnd.iptc.g2.planningitem+xml	application/vnd.iptc.g2.planningitem+xml	[Michael_Steidl]
634	application	vnd.ipunplugged.rcprofile	application/vnd.ipunplugged.rcprofile	[Per_Ersson]
635	application	vnd.irepository.package+xml	application/vnd.irepository.package+xml	[Martin_Knowles]
636	application	vnd.is-xpr	application/vnd.is-xpr	[Satish_Navarajan]
637	application	vnd.isac.fcs	application/vnd.isac.fcs	[Ryan_Brinkman]
638	application	vnd.jam	application/vnd.jam	[Brijesh_Kumar]
639	application	vnd.japannet-directory-service	application/vnd.japannet-directory-service	[Kiyofusa_Fujii]
640	application	vnd.japannet-jpnstore-wakeup	application/vnd.japannet-jpnstore-wakeup	[Jun_Yoshitake]
641	application	vnd.japannet-payment-wakeup	application/vnd.japannet-payment-wakeup	[Kiyofusa_Fujii]
642	application	vnd.japannet-registration	application/vnd.japannet-registration	[Jun_Yoshitake]
643	application	vnd.japannet-registration-wakeup	application/vnd.japannet-registration-wakeup	[Kiyofusa_Fujii]
644	application	vnd.japannet-setstore-wakeup	application/vnd.japannet-setstore-wakeup	[Jun_Yoshitake]
645	application	vnd.japannet-verification	application/vnd.japannet-verification	[Jun_Yoshitake]
646	application	vnd.japannet-verification-wakeup	application/vnd.japannet-verification-wakeup	[Kiyofusa_Fujii]
647	application	vnd.jcp.javame.midlet-rms	application/vnd.jcp.javame.midlet-rms	[Mikhail_Gorshenev]
648	application	vnd.jisp	application/vnd.jisp	[Sebastiaan_Deckers]
649	application	vnd.joost.joda-archive	application/vnd.joost.joda-archive	[Joost]
650	application	vnd.jsk.isdn-ngn	application/vnd.jsk.isdn-ngn	[Yokoyama_Kiyonobu]
651	application	vnd.kahootz	application/vnd.kahootz	[Tim_Macdonald]
652	application	vnd.kde.karbon	application/vnd.kde.karbon	[David_Faure]
653	application	vnd.kde.kchart	application/vnd.kde.kchart	[David_Faure]
654	application	vnd.kde.kformula	application/vnd.kde.kformula	[David_Faure]
655	application	vnd.kde.kivio	application/vnd.kde.kivio	[David_Faure]
656	application	vnd.kde.kontour	application/vnd.kde.kontour	[David_Faure]
657	application	vnd.kde.kpresenter	application/vnd.kde.kpresenter	[David_Faure]
658	application	vnd.kde.kspread	application/vnd.kde.kspread	[David_Faure]
659	application	vnd.kde.kword	application/vnd.kde.kword	[David_Faure]
660	application	vnd.kenameaapp	application/vnd.kenameaapp	[Dirk_DiGiorgio-Haag]
661	application	vnd.kidspiration	application/vnd.kidspiration	[Jack_Bennett]
662	application	vnd.Kinar	application/vnd.Kinar	[Hemant_Thakkar]
663	application	vnd.koan	application/vnd.koan	[Pete_Cole]
664	application	vnd.kodak-descriptor	application/vnd.kodak-descriptor	[Michael_J._Donahue]
665	application	vnd.las.las+xml	application/vnd.las.las+xml	[Rob_Bailey]
666	application	vnd.liberty-request+xml	application/vnd.liberty-request+xml	[Brett_McDowell]
667	application	vnd.llamagraphics.life-balance.desktop	application/vnd.llamagraphics.life-balance.desktop	[Catherine_E._White]
668	application	vnd.llamagraphics.life-balance.exchange+xml	application/vnd.llamagraphics.life-balance.exchange+xml	[Catherine_E._White]
669	application	vnd.lotus-1-2-3	application/vnd.lotus-1-2-3	[Paul_Wattenberger]
670	application	vnd.lotus-approach	application/vnd.lotus-approach	[Paul_Wattenberger]
671	application	vnd.lotus-freelance	application/vnd.lotus-freelance	[Paul_Wattenberger]
672	application	vnd.lotus-notes	application/vnd.lotus-notes	[Michael_Laramie]
673	application	vnd.lotus-organizer	application/vnd.lotus-organizer	[Paul_Wattenberger]
674	application	vnd.lotus-screencam	application/vnd.lotus-screencam	[Paul_Wattenberger]
675	application	vnd.lotus-wordpro	application/vnd.lotus-wordpro	[Paul_Wattenberger]
676	application	vnd.macports.portpkg	application/vnd.macports.portpkg	[James_Berry]
677	application	vnd.macports.portpkg	application/vnd.macports.portpkg	[James_Berry]
678	application	vnd.mapbox-vector-tile	application/vnd.mapbox-vector-tile	[Blake_Thompson]
679	application	vnd.marlin.drm.actiontoken+xml	application/vnd.marlin.drm.actiontoken+xml	[Gary_Ellison]
680	application	vnd.marlin.drm.conftoken+xml	application/vnd.marlin.drm.conftoken+xml	[Gary_Ellison]
681	application	vnd.marlin.drm.license+xml	application/vnd.marlin.drm.license+xml	[Gary_Ellison]
682	application	vnd.marlin.drm.mdcf	application/vnd.marlin.drm.mdcf	[Gary_Ellison]
683	application	vnd.mason+json	application/vnd.mason+json	[Jorn_Wildt]
684	application	vnd.maxmind.maxmind-db	application/vnd.maxmind.maxmind-db	[William_Stevenson]
685	application	vnd.mcd	application/vnd.mcd	[Tadashi_Gotoh]
686	application	vnd.medcalcdata	application/vnd.medcalcdata	[Frank_Schoonjans]
687	application	vnd.mediastation.cdkey	application/vnd.mediastation.cdkey	[Henry_Flurry]
688	application	vnd.meridian-slingshot	application/vnd.meridian-slingshot	[Eric_Wedel]
689	application	vnd.MFER	application/vnd.MFER	[Masaaki_Hirai]
690	application	vnd.mfmp	application/vnd.mfmp	[Yukari_Ikeda]
691	application	vnd.micro+json	application/vnd.micro+json	[Dali_Zheng]
692	application	vnd.micrografx.flo	application/vnd.micrografx.flo	[Joe_Prevo]
693	application	vnd.micrografx.igx	application/vnd.micrografx-igx	[Joe_Prevo]
694	application	vnd.microsoft.portable-executable	application/vnd.microsoft.portable-executable	[Henrik_Andersson]
695	application	vnd.miele+json	application/vnd.miele+json	[Nils_Langhammer]
696	application	vnd.mif	application/vnd-mif	[Mike_Wexler]
697	application	vnd.minisoft-hp3000-save	application/vnd.minisoft-hp3000-save	[Chris_Bartram]
698	application	vnd.mitsubishi.misty-guard.trustweb	application/vnd.mitsubishi.misty-guard.trustweb	[Tanaka]
699	application	vnd.Mobius.DAF	application/vnd.Mobius.DAF	[Allen_K._Kabayama]
700	application	vnd.Mobius.DIS	application/vnd.Mobius.DIS	[Allen_K._Kabayama]
701	application	vnd.Mobius.MBK	application/vnd.Mobius.MBK	[Alex_Devasia]
702	application	vnd.Mobius.MQY	application/vnd.Mobius.MQY	[Alex_Devasia]
703	application	vnd.Mobius.MSL	application/vnd.Mobius.MSL	[Allen_K._Kabayama]
704	application	vnd.Mobius.PLC	application/vnd.Mobius.PLC	[Allen_K._Kabayama]
705	application	vnd.Mobius.TXF	application/vnd.Mobius.TXF	[Allen_K._Kabayama]
706	application	vnd.mophun.application	application/vnd.mophun.application	[Bjorn_Wennerstrom]
707	application	vnd.mophun.certificate	application/vnd.mophun.certificate	[Bjorn_Wennerstrom]
708	application	vnd.motorola.flexsuite	application/vnd.motorola.flexsuite	[Mark_Patton]
709	application	vnd.motorola.flexsuite.adsi	application/vnd.motorola.flexsuite.adsi	[Mark_Patton]
710	application	vnd.motorola.flexsuite.fis	application/vnd.motorola.flexsuite.fis	[Mark_Patton]
711	application	vnd.motorola.flexsuite.gotap	application/vnd.motorola.flexsuite.gotap	[Mark_Patton]
712	application	vnd.motorola.flexsuite.kmr	application/vnd.motorola.flexsuite.kmr	[Mark_Patton]
713	application	vnd.motorola.flexsuite.ttc	application/vnd.motorola.flexsuite.ttc	[Mark_Patton]
714	application	vnd.motorola.flexsuite.wem	application/vnd.motorola.flexsuite.wem	[Mark_Patton]
715	application	vnd.motorola.iprm	application/vnd.motorola.iprm	[Rafie_Shamsaasef]
716	application	vnd.mozilla.xul+xml	application/vnd.mozilla.xul+xml	[Braden_N_McDaniel]
717	application	vnd.ms-artgalry	application/vnd.ms-artgalry	[Dean_Slawson]
718	application	vnd.ms-asf	application/vnd.ms-asf	[Eric_Fleischman]
719	application	vnd.ms-cab-compressed	application/vnd.ms-cab-compressed	[Kim_Scarborough]
720	application	vnd.ms-3mfdocument	application/vnd.ms-3mfdocument	[Shawn_Maloney]
721	application	vnd.ms-excel	application/vnd.ms-excel	[Sukvinder_S._Gill]
722	application	vnd.ms-excel.addin.macroEnabled.12	application/vnd.ms-excel.addin.macroEnabled.12	[Chris_Rae]
723	application	vnd.ms-excel.sheet.binary.macroEnabled.12	application/vnd.ms-excel.sheet.binary.macroEnabled.12	[Chris_Rae]
724	application	vnd.ms-excel.sheet.macroEnabled.12	application/vnd.ms-excel.sheet.macroEnabled.12	[Chris_Rae]
725	application	vnd.ms-excel.template.macroEnabled.12	application/vnd.ms-excel.template.macroEnabled.12	[Chris_Rae]
726	application	vnd.ms-fontobject	application/vnd.ms-fontobject	[Kim_Scarborough]
727	application	vnd.ms-htmlhelp	application/vnd.ms-htmlhelp	[Anatoly_Techtonik]
728	application	vnd.ms-ims	application/vnd.ms-ims	[Eric_Ledoux]
729	application	vnd.ms-lrm	application/vnd.ms-lrm	[Eric_Ledoux]
730	application	vnd.ms-office.activeX+xml	application/vnd.ms-office.activeX+xml	[Chris_Rae]
731	application	vnd.ms-officetheme	application/vnd.ms-officetheme	[Chris_Rae]
732	application	vnd.ms-playready.initiator+xml	application/vnd.ms-playready.initiator+xml	[Daniel_Schneider]
733	application	vnd.ms-powerpoint	application/vnd.ms-powerpoint	[Sukvinder_S._Gill]
734	application	vnd.ms-powerpoint.addin.macroEnabled.12	application/vnd.ms-powerpoint.addin.macroEnabled.12	[Chris_Rae]
735	application	vnd.ms-powerpoint.presentation.macroEnabled.12	application/vnd.ms-powerpoint.presentation.macroEnabled.12	[Chris_Rae]
736	application	vnd.ms-powerpoint.slide.macroEnabled.12	application/vnd.ms-powerpoint.slide.macroEnabled.12	[Chris_Rae]
737	application	vnd.ms-powerpoint.slideshow.macroEnabled.12	application/vnd.ms-powerpoint.slideshow.macroEnabled.12	[Chris_Rae]
738	application	vnd.ms-powerpoint.template.macroEnabled.12	application/vnd.ms-powerpoint.template.macroEnabled.12	[Chris_Rae]
739	application	vnd.ms-PrintDeviceCapabilities+xml	application/vnd.ms-PrintDeviceCapabilities+xml	[Justin_Hutchings]
740	application	vnd.ms-PrintSchemaTicket+xml	application/vnd.ms-PrintSchemaTicket+xml	[Justin_Hutchings]
741	application	vnd.ms-project	application/vnd.ms-project	[Sukvinder_S._Gill]
742	application	vnd.ms-tnef	application/vnd.ms-tnef	[Sukvinder_S._Gill]
743	application	vnd.ms-windows.devicepairing	application/vnd.ms-windows.devicepairing	[Justin_Hutchings]
744	application	vnd.ms-windows.nwprinting.oob	application/vnd.ms-windows.nwprinting.oob	[Justin_Hutchings]
745	application	vnd.ms-windows.printerpairing	application/vnd.ms-windows.printerpairing	[Justin_Hutchings]
746	application	vnd.ms-windows.wsd.oob	application/vnd.ms-windows.wsd.oob	[Justin_Hutchings]
747	application	vnd.ms-wmdrm.lic-chlg-req	application/vnd.ms-wmdrm.lic-chlg-req	[Kevin_Lau]
748	application	vnd.ms-wmdrm.lic-resp	application/vnd.ms-wmdrm.lic-resp	[Kevin_Lau]
749	application	vnd.ms-wmdrm.meter-chlg-req	application/vnd.ms-wmdrm.meter-chlg-req	[Kevin_Lau]
750	application	vnd.ms-wmdrm.meter-resp	application/vnd.ms-wmdrm.meter-resp	[Kevin_Lau]
751	application	vnd.ms-word.document.macroEnabled.12	application/vnd.ms-word.document.macroEnabled.12	[Chris_Rae]
752	application	vnd.ms-word.template.macroEnabled.12	application/vnd.ms-word.template.macroEnabled.12	[Chris_Rae]
753	application	vnd.ms-works	application/vnd.ms-works	[Sukvinder_S._Gill]
754	application	vnd.ms-wpl	application/vnd.ms-wpl	[Dan_Plastina]
755	application	vnd.ms-xpsdocument	application/vnd.ms-xpsdocument	[Jesse_McGatha]
756	application	vnd.msa-disk-image	application/vnd.msa-disk-image	[Thomas_Huth]
757	application	vnd.mseq	application/vnd.mseq	[Gwenael_Le_Bodic]
758	application	vnd.msign	application/vnd.msign	[Malte_Borcherding]
759	application	vnd.multiad.creator	application/vnd.multiad.creator	[Steve_Mills]
760	application	vnd.multiad.creator.cif	application/vnd.multiad.creator.cif	[Steve_Mills]
761	application	vnd.musician	application/vnd.musician	[Greg_Adams]
762	application	vnd.music-niff	application/vnd.music-niff	[Tim_Butler]
763	application	vnd.muvee.style	application/vnd.muvee.style	[Chandrashekhara_Anantharamu]
764	application	vnd.mynfc	application/vnd.mynfc	[Franck_Lefevre]
765	application	vnd.ncd.control	application/vnd.ncd.control	[Lauri_Tarkkala]
766	application	vnd.ncd.reference	application/vnd.ncd.reference	[Lauri_Tarkkala]
767	application	vnd.nearst.inv+json	application/vnd.nearst.inv+json	[Thomas_Schoffelen]
768	application	vnd.nervana	application/vnd.nervana	[Steve_Judkins]
769	application	vnd.netfpx	application/vnd.netfpx	[Andy_Mutz]
770	application	vnd.neurolanguage.nlu	application/vnd.neurolanguage.nlu	[Dan_DuFeu]
771	application	vnd.nintendo.snes.rom	application/vnd.nintendo.snes.rom	[Henrik_Andersson]
772	application	vnd.nintendo.nitro.rom	application/vnd.nintendo.nitro.rom	[Henrik_Andersson]
773	application	vnd.nitf	application/vnd.nitf	[Steve_Rogan]
774	application	vnd.noblenet-directory	application/vnd.noblenet-directory	[Monty_Solomon]
775	application	vnd.noblenet-sealer	application/vnd.noblenet-sealer	[Monty_Solomon]
776	application	vnd.noblenet-web	application/vnd.noblenet-web	[Monty_Solomon]
777	application	vnd.nokia.catalogs	application/vnd.nokia.catalogs	[Nokia]
778	application	vnd.nokia.conml+wbxml	application/vnd.nokia.conml+wbxml	[Nokia]
779	application	vnd.nokia.conml+xml	application/vnd.nokia.conml+xml	[Nokia]
780	application	vnd.nokia.iptv.config+xml	application/vnd.nokia.iptv.config+xml	[Nokia]
781	application	vnd.nokia.iSDS-radio-presets	application/vnd.nokia.iSDS-radio-presets	[Nokia]
782	application	vnd.nokia.landmark+wbxml	application/vnd.nokia.landmark+wbxml	[Nokia]
783	application	vnd.nokia.landmark+xml	application/vnd.nokia.landmark+xml	[Nokia]
784	application	vnd.nokia.landmarkcollection+xml	application/vnd.nokia.landmarkcollection+xml	[Nokia]
785	application	vnd.nokia.ncd	application/vnd.nokia.ncd	[Nokia]
786	application	vnd.nokia.n-gage.ac+xml	application/vnd.nokia.n-gage.ac+xml	[Nokia]
787	application	vnd.nokia.n-gage.data	application/vnd.nokia.n-gage.data	[Nokia]
788	application	vnd.nokia.n-gage.symbian.install - OBSOLETE; no replacement given	application/vnd.nokia.n-gage.symbian.install	[Nokia]
789	application	vnd.nokia.pcd+wbxml	application/vnd.nokia.pcd+wbxml	[Nokia]
790	application	vnd.nokia.pcd+xml	application/vnd.nokia.pcd+xml	[Nokia]
791	application	vnd.nokia.radio-preset	application/vnd.nokia.radio-preset	[Nokia]
792	application	vnd.nokia.radio-presets	application/vnd.nokia.radio-presets	[Nokia]
793	application	vnd.novadigm.EDM	application/vnd.novadigm.EDM	[Janine_Swenson]
794	application	vnd.novadigm.EDX	application/vnd.novadigm.EDX	[Janine_Swenson]
795	application	vnd.novadigm.EXT	application/vnd.novadigm.EXT	[Janine_Swenson]
796	application	vnd.ntt-local.content-share	application/vnd.ntt-local.content-share	[Akinori_Taya]
797	application	vnd.ntt-local.file-transfer	application/vnd.ntt-local.file-transfer	[NTT-local]
798	application	vnd.ntt-local.ogw_remote-access	application/vnd.ntt-local.ogw_remote-access	[NTT-local]
799	application	vnd.ntt-local.sip-ta_remote	application/vnd.ntt-local.sip-ta_remote	[NTT-local]
800	application	vnd.ntt-local.sip-ta_tcp_stream	application/vnd.ntt-local.sip-ta_tcp_stream	[NTT-local]
801	application	vnd.oasis.opendocument.chart	application/vnd.oasis.opendocument.chart	[Svante_Schubert][OASIS]
802	application	vnd.oasis.opendocument.chart-template	application/vnd.oasis.opendocument.chart-template	[Svante_Schubert][OASIS]
803	application	vnd.oasis.opendocument.database	application/vnd.oasis.opendocument.database	[Svante_Schubert][OASIS]
804	application	vnd.oasis.opendocument.formula	application/vnd.oasis.opendocument.formula	[Svante_Schubert][OASIS]
805	application	vnd.oasis.opendocument.formula-template	application/vnd.oasis.opendocument.formula-template	[Svante_Schubert][OASIS]
806	application	vnd.oasis.opendocument.graphics	application/vnd.oasis.opendocument.graphics	[Svante_Schubert][OASIS]
807	application	vnd.oasis.opendocument.graphics-template	application/vnd.oasis.opendocument.graphics-template	[Svante_Schubert][OASIS]
808	application	vnd.oasis.opendocument.image	application/vnd.oasis.opendocument.image	[Svante_Schubert][OASIS]
809	application	vnd.oasis.opendocument.image-template	application/vnd.oasis.opendocument.image-template	[Svante_Schubert][OASIS]
810	application	vnd.oasis.opendocument.presentation	application/vnd.oasis.opendocument.presentation	[Svante_Schubert][OASIS]
811	application	vnd.oasis.opendocument.presentation-template	application/vnd.oasis.opendocument.presentation-template	[Svante_Schubert][OASIS]
812	application	vnd.oasis.opendocument.spreadsheet	application/vnd.oasis.opendocument.spreadsheet	[Svante_Schubert][OASIS]
813	application	vnd.oasis.opendocument.spreadsheet-template	application/vnd.oasis.opendocument.spreadsheet-template	[Svante_Schubert][OASIS]
814	application	vnd.oasis.opendocument.text	application/vnd.oasis.opendocument.text	[Svante_Schubert][OASIS]
815	application	vnd.oasis.opendocument.text-master	application/vnd.oasis.opendocument.text-master	[Svante_Schubert][OASIS]
816	application	vnd.oasis.opendocument.text-template	application/vnd.oasis.opendocument.text-template	[Svante_Schubert][OASIS]
817	application	vnd.oasis.opendocument.text-web	application/vnd.oasis.opendocument.text-web	[Svante_Schubert][OASIS]
818	application	vnd.obn	application/vnd.obn	[Matthias_Hessling]
819	application	vnd.oftn.l10n+json	application/vnd.oftn.l10n+json	[Eli_Grey]
820	application	vnd.oipf.contentaccessdownload+xml	application/vnd.oipf.contentaccessdownload+xml	[Claire_DEsclercs]
821	application	vnd.oipf.contentaccessstreaming+xml	application/vnd.oipf.contentaccessstreaming+xml	[Claire_DEsclercs]
822	application	vnd.oipf.cspg-hexbinary	application/vnd.oipf.cspg-hexbinary	[Claire_DEsclercs]
823	application	vnd.oipf.dae.svg+xml	application/vnd.oipf.dae.svg+xml	[Claire_DEsclercs]
824	application	vnd.oipf.dae.xhtml+xml	application/vnd.oipf.dae.xhtml+xml	[Claire_DEsclercs]
825	application	vnd.oipf.mippvcontrolmessage+xml	application/vnd.oipf.mippvcontrolmessage+xml	[Claire_DEsclercs]
826	application	vnd.oipf.pae.gem	application/vnd.oipf.pae.gem	[Claire_DEsclercs]
827	application	vnd.oipf.spdiscovery+xml	application/vnd.oipf.spdiscovery+xml	[Claire_DEsclercs]
828	application	vnd.oipf.spdlist+xml	application/vnd.oipf.spdlist+xml	[Claire_DEsclercs]
829	application	vnd.oipf.ueprofile+xml	application/vnd.oipf.ueprofile+xml	[Claire_DEsclercs]
830	application	vnd.oipf.userprofile+xml	application/vnd.oipf.userprofile+xml	[Claire_DEsclercs]
831	application	vnd.olpc-sugar	application/vnd.olpc-sugar	[John_Palmieri]
832	application	vnd.oma.bcast.associated-procedure-parameter+xml	application/vnd.oma.bcast.associated-procedure-parameter+xml	[Uwe_Rauschenbach][Open_Mobile_Naming_Authority]
833	application	vnd.oma.bcast.drm-trigger+xml	application/vnd.oma.bcast.drm-trigger+xml	[Uwe_Rauschenbach][Open_Mobile_Naming_Authority]
834	application	vnd.oma.bcast.imd+xml	application/vnd.oma.bcast.imd+xml	[Uwe_Rauschenbach][Open_Mobile_Naming_Authority]
835	application	vnd.oma.bcast.ltkm	application/vnd.oma.bcast.ltkm	[Uwe_Rauschenbach][Open_Mobile_Naming_Authority]
836	application	vnd.oma.bcast.notification+xml	application/vnd.oma.bcast.notification+xml	[Uwe_Rauschenbach][Open_Mobile_Naming_Authority]
837	application	vnd.oma.bcast.provisioningtrigger	application/vnd.oma.bcast.provisioningtrigger	[Uwe_Rauschenbach][Open_Mobile_Naming_Authority]
838	application	vnd.oma.bcast.sgboot	application/vnd.oma.bcast.sgboot	[Uwe_Rauschenbach][Open_Mobile_Naming_Authority]
839	application	vnd.oma.bcast.sgdd+xml	application/vnd.oma.bcast.sgdd+xml	[Uwe_Rauschenbach][Open_Mobile_Naming_Authority]
840	application	vnd.oma.bcast.sgdu	application/vnd.oma.bcast.sgdu	[Uwe_Rauschenbach][Open_Mobile_Naming_Authority]
841	application	vnd.oma.bcast.simple-symbol-container	application/vnd.oma.bcast.simple-symbol-container	[Uwe_Rauschenbach][Open_Mobile_Naming_Authority]
842	application	vnd.oma.bcast.smartcard-trigger+xml	application/vnd.oma.bcast.smartcard-trigger+xml	[Uwe_Rauschenbach][Open_Mobile_Naming_Authority]
843	application	vnd.oma.bcast.sprov+xml	application/vnd.oma.bcast.sprov+xml	[Uwe_Rauschenbach][Open_Mobile_Naming_Authority]
844	application	vnd.oma.bcast.stkm	application/vnd.oma.bcast.stkm	[Uwe_Rauschenbach][Open_Mobile_Naming_Authority]
845	application	vnd.oma.cab-address-book+xml	application/vnd.oma.cab-address-book+xml	[Hao_Wang][OMA]
846	application	vnd.oma.cab-feature-handler+xml	application/vnd.oma.cab-feature-handler+xml	[Hao_Wang][OMA]
847	application	vnd.oma.cab-pcc+xml	application/vnd.oma.cab-pcc+xml	[Hao_Wang][OMA]
848	application	vnd.oma.cab-subs-invite+xml	application/vnd.oma.cab-subs-invite+xml	[Hao_Wang][OMA]
849	application	vnd.oma.cab-user-prefs+xml	application/vnd.oma.cab-user-prefs+xml	[Hao_Wang][OMA]
850	application	vnd.oma.dcd	application/vnd.oma.dcd	[Avi_Primo][Open_Mobile_Naming_Authority]
851	application	vnd.oma.dcdc	application/vnd.oma.dcdc	[Avi_Primo][Open_Mobile_Naming_Authority]
852	application	vnd.oma.dd2+xml	application/vnd.oma.dd2+xml	[Jun_Sato][Open_Mobile_Alliance_BAC_DLDRM_Working_Group]
853	application	vnd.oma.drm.risd+xml	application/vnd.oma.drm.risd+xml	[Uwe_Rauschenbach][Open_Mobile_Naming_Authority]
854	application	vnd.oma.group-usage-list+xml	application/vnd.oma.group-usage-list+xml	[Sean_Kelley][OMA_Presence_and_Availability_PAG_Working_Group]
855	application	vnd.oma.lwm2m+json	application/vnd.oma.lwm2m+json	[John_Mudge][Open_Mobile_Naming_Authority]
856	application	vnd.oma.lwm2m+tlv	application/vnd.oma.lwm2m+tlv	[John_Mudge][Open_Mobile_Naming_Authority]
857	application	vnd.oma.pal+xml	application/vnd.oma.pal+xml	[Brian_McColgan][Open_Mobile_Naming_Authority]
858	application	vnd.oma.poc.detailed-progress-report+xml	application/vnd.oma.poc.detailed-progress-report+xml	[OMA_Push_to_Talk_over_Cellular_POC_Working_Group]
859	application	vnd.oma.poc.final-report+xml	application/vnd.oma.poc.final-report+xml	[OMA_Push_to_Talk_over_Cellular_POC_Working_Group]
860	application	vnd.oma.poc.groups+xml	application/vnd.oma.poc.groups+xml	[Sean_Kelley][OMA_Push_to_Talk_over_Cellular_POC_Working_Group]
861	application	vnd.oma.poc.invocation-descriptor+xml	application/vnd.oma.poc.invocation-descriptor+xml	[OMA_Push_to_Talk_over_Cellular_POC_Working_Group]
1014	application	vnd.route66.link66+xml	application/vnd.route66.link66+xml	[Sybren_Kikstra]
862	application	vnd.oma.poc.optimized-progress-report+xml	application/vnd.oma.poc.optimized-progress-report+xml	[OMA_Push_to_Talk_over_Cellular_POC_Working_Group]
863	application	vnd.oma.push	application/vnd.oma.push	[Bryan_Sullivan][OMA]
864	application	vnd.oma.scidm.messages+xml	application/vnd.oma.scidm.messages+xml	[Wenjun_Zeng][Open_Mobile_Naming_Authority]
865	application	vnd.oma.xcap-directory+xml	application/vnd.oma.xcap-directory+xml	[Sean_Kelley][OMA_Presence_and_Availability_PAG_Working_Group]
866	application	vnd.omads-email+xml	application/vnd.omads-email+xml	[OMA_Data_Synchronization_Working_Group]
867	application	vnd.omads-file+xml	application/vnd.omads-file+xml	[OMA_Data_Synchronization_Working_Group]
868	application	vnd.omads-folder+xml	application/vnd.omads-folder+xml	[OMA_Data_Synchronization_Working_Group]
869	application	vnd.omaloc-supl-init	application/vnd.omaloc-supl-init	[Julien_Grange]
870	application	vnd.oma-scws-config	application/vnd.oma-scws-config	[Ilan_Mahalal]
871	application	vnd.oma-scws-http-request	application/vnd.oma-scws-http-request	[Ilan_Mahalal]
872	application	vnd.oma-scws-http-response	application/vnd.oma-scws-http-response	[Ilan_Mahalal]
873	application	vnd.onepager	application/vnd.onepager	[Nathan_Black]
874	application	vnd.openblox.game-binary	application/vnd.openblox.game-binary	[Mark_Otaris]
875	application	vnd.openblox.game+xml	application/vnd.openblox.game+xml	[Mark_Otaris]
876	application	vnd.openeye.oeb	application/vnd.openeye.oeb	[Craig_Bruce]
877	application	vnd.openstreetmap.data+xml	application/vnd.openstreetmap.data+xml	[Paul_Norman]
878	application	vnd.openxmlformats-officedocument.custom-properties+xml	application/vnd.openxmlformats-officedocument.custom-properties+xml	[Makoto_Murata]
879	application	vnd.openxmlformats-officedocument.customXmlProperties+xml	application/vnd.openxmlformats-officedocument.customXmlProperties+xml	[Makoto_Murata]
880	application	vnd.openxmlformats-officedocument.drawing+xml	application/vnd.openxmlformats-officedocument.drawing+xml	[Makoto_Murata]
881	application	vnd.openxmlformats-officedocument.drawingml.chart+xml	application/vnd.openxmlformats-officedocument.drawingml.chart+xml	[Makoto_Murata]
882	application	vnd.openxmlformats-officedocument.drawingml.chartshapes+xml	application/vnd.openxmlformats-officedocument.drawingml.chartshapes+xml	[Makoto_Murata]
883	application	vnd.openxmlformats-officedocument.drawingml.diagramColors+xml	application/vnd.openxmlformats-officedocument.drawingml.diagramColors+xml	[Makoto_Murata]
884	application	vnd.openxmlformats-officedocument.drawingml.diagramData+xml	application/vnd.openxmlformats-officedocument.drawingml.diagramData+xml	[Makoto_Murata]
885	application	vnd.openxmlformats-officedocument.drawingml.diagramLayout+xml	application/vnd.openxmlformats-officedocument.drawingml.diagramLayout+xml	[Makoto_Murata]
886	application	vnd.openxmlformats-officedocument.drawingml.diagramStyle+xml	application/vnd.openxmlformats-officedocument.drawingml.diagramStyle+xml	[Makoto_Murata]
887	application	vnd.openxmlformats-officedocument.extended-properties+xml	application/vnd.openxmlformats-officedocument.extended-properties+xml	[Makoto_Murata]
888	application	vnd.openxmlformats-officedocument.presentationml.commentAuthors+xml	application/vnd.openxmlformats-officedocument.presentationml.commentAuthors+xml	[Makoto_Murata]
889	application	vnd.openxmlformats-officedocument.presentationml.comments+xml	application/vnd.openxmlformats-officedocument.presentationml.comments+xml	[Makoto_Murata]
890	application	vnd.openxmlformats-officedocument.presentationml.handoutMaster+xml	application/vnd.openxmlformats-officedocument.presentationml.handoutMaster+xml	[Makoto_Murata]
891	application	vnd.openxmlformats-officedocument.presentationml.notesMaster+xml	application/vnd.openxmlformats-officedocument.presentationml.notesMaster+xml	[Makoto_Murata]
892	application	vnd.openxmlformats-officedocument.presentationml.notesSlide+xml	application/vnd.openxmlformats-officedocument.presentationml.notesSlide+xml	[Makoto_Murata]
893	application	vnd.openxmlformats-officedocument.presentationml.presentation	application/vnd.openxmlformats-officedocument.presentationml.presentation	[Makoto_Murata]
894	application	vnd.openxmlformats-officedocument.presentationml.presentation.main+xml	application/vnd.openxmlformats-officedocument.presentationml.presentation.main+xml	[Makoto_Murata]
895	application	vnd.openxmlformats-officedocument.presentationml.presProps+xml	application/vnd.openxmlformats-officedocument.presentationml.presProps+xml	[Makoto_Murata]
896	application	vnd.openxmlformats-officedocument.presentationml.slide	application/vnd.openxmlformats-officedocument.presentationml.slide	[Makoto_Murata]
897	application	vnd.openxmlformats-officedocument.presentationml.slide+xml	application/vnd.openxmlformats-officedocument.presentationml.slide+xml	[Makoto_Murata]
898	application	vnd.openxmlformats-officedocument.presentationml.slideLayout+xml	application/vnd.openxmlformats-officedocument.presentationml.slideLayout+xml	[Makoto_Murata]
899	application	vnd.openxmlformats-officedocument.presentationml.slideMaster+xml	application/vnd.openxmlformats-officedocument.presentationml.slideMaster+xml	[Makoto_Murata]
900	application	vnd.openxmlformats-officedocument.presentationml.slideshow	application/vnd.openxmlformats-officedocument.presentationml.slideshow	[Makoto_Murata]
901	application	vnd.openxmlformats-officedocument.presentationml.slideshow.main+xml	application/vnd.openxmlformats-officedocument.presentationml.slideshow.main+xml	[Makoto_Murata]
902	application	vnd.openxmlformats-officedocument.presentationml.slideUpdateInfo+xml	application/vnd.openxmlformats-officedocument.presentationml.slideUpdateInfo+xml	[Makoto_Murata]
903	application	vnd.openxmlformats-officedocument.presentationml.tableStyles+xml	application/vnd.openxmlformats-officedocument.presentationml.tableStyles+xml	[Makoto_Murata]
904	application	vnd.openxmlformats-officedocument.presentationml.tags+xml	application/vnd.openxmlformats-officedocument.presentationml.tags+xml	[Makoto_Murata]
905	application	vnd.openxmlformats-officedocument.presentationml.template	application/vnd.openxmlformats-officedocument.presentationml-template	[Makoto_Murata]
906	application	vnd.openxmlformats-officedocument.presentationml.template.main+xml	application/vnd.openxmlformats-officedocument.presentationml.template.main+xml	[Makoto_Murata]
907	application	vnd.openxmlformats-officedocument.presentationml.viewProps+xml	application/vnd.openxmlformats-officedocument.presentationml.viewProps+xml	[Makoto_Murata]
1015	application	vnd.rs-274x	application/vnd.rs-274x	[Lee_Harding]
908	application	vnd.openxmlformats-officedocument.spreadsheetml.calcChain+xml	application/vnd.openxmlformats-officedocument.spreadsheetml.calcChain+xml	[Makoto_Murata]
909	application	vnd.openxmlformats-officedocument.spreadsheetml.chartsheet+xml	application/vnd.openxmlformats-officedocument.spreadsheetml.chartsheet+xml	[Makoto_Murata]
910	application	vnd.openxmlformats-officedocument.spreadsheetml.comments+xml	application/vnd.openxmlformats-officedocument.spreadsheetml.comments+xml	[Makoto_Murata]
911	application	vnd.openxmlformats-officedocument.spreadsheetml.connections+xml	application/vnd.openxmlformats-officedocument.spreadsheetml.connections+xml	[Makoto_Murata]
912	application	vnd.openxmlformats-officedocument.spreadsheetml.dialogsheet+xml	application/vnd.openxmlformats-officedocument.spreadsheetml.dialogsheet+xml	[Makoto_Murata]
913	application	vnd.openxmlformats-officedocument.spreadsheetml.externalLink+xml	application/vnd.openxmlformats-officedocument.spreadsheetml.externalLink+xml	[Makoto_Murata]
914	application	vnd.openxmlformats-officedocument.spreadsheetml.pivotCacheDefinition+xml	application/vnd.openxmlformats-officedocument.spreadsheetml.pivotCacheDefinition+xml	[Makoto_Murata]
915	application	vnd.openxmlformats-officedocument.spreadsheetml.pivotCacheRecords+xml	application/vnd.openxmlformats-officedocument.spreadsheetml.pivotCacheRecords+xml	[Makoto_Murata]
916	application	vnd.openxmlformats-officedocument.spreadsheetml.pivotTable+xml	application/vnd.openxmlformats-officedocument.spreadsheetml.pivotTable+xml	[Makoto_Murata]
917	application	vnd.openxmlformats-officedocument.spreadsheetml.queryTable+xml	application/vnd.openxmlformats-officedocument.spreadsheetml.queryTable+xml	[Makoto_Murata]
918	application	vnd.openxmlformats-officedocument.spreadsheetml.revisionHeaders+xml	application/vnd.openxmlformats-officedocument.spreadsheetml.revisionHeaders+xml	[Makoto_Murata]
919	application	vnd.openxmlformats-officedocument.spreadsheetml.revisionLog+xml	application/vnd.openxmlformats-officedocument.spreadsheetml.revisionLog+xml	[Makoto_Murata]
920	application	vnd.openxmlformats-officedocument.spreadsheetml.sharedStrings+xml	application/vnd.openxmlformats-officedocument.spreadsheetml.sharedStrings+xml	[Makoto_Murata]
921	application	vnd.openxmlformats-officedocument.spreadsheetml.sheet	application/vnd.openxmlformats-officedocument.spreadsheetml.sheet	[Makoto_Murata]
922	application	vnd.openxmlformats-officedocument.spreadsheetml.sheet.main+xml	application/vnd.openxmlformats-officedocument.spreadsheetml.sheet.main+xml	[Makoto_Murata]
923	application	vnd.openxmlformats-officedocument.spreadsheetml.sheetMetadata+xml	application/vnd.openxmlformats-officedocument.spreadsheetml.sheetMetadata+xml	[Makoto_Murata]
924	application	vnd.openxmlformats-officedocument.spreadsheetml.styles+xml	application/vnd.openxmlformats-officedocument.spreadsheetml.styles+xml	[Makoto_Murata]
925	application	vnd.openxmlformats-officedocument.spreadsheetml.table+xml	application/vnd.openxmlformats-officedocument.spreadsheetml.table+xml	[Makoto_Murata]
926	application	vnd.openxmlformats-officedocument.spreadsheetml.tableSingleCells+xml	application/vnd.openxmlformats-officedocument.spreadsheetml.tableSingleCells+xml	[Makoto_Murata]
927	application	vnd.openxmlformats-officedocument.spreadsheetml.template	application/vnd.openxmlformats-officedocument.spreadsheetml-template	[Makoto_Murata]
928	application	vnd.openxmlformats-officedocument.spreadsheetml.template.main+xml	application/vnd.openxmlformats-officedocument.spreadsheetml.template.main+xml	[Makoto_Murata]
929	application	vnd.openxmlformats-officedocument.spreadsheetml.userNames+xml	application/vnd.openxmlformats-officedocument.spreadsheetml.userNames+xml	[Makoto_Murata]
930	application	vnd.openxmlformats-officedocument.spreadsheetml.volatileDependencies+xml	application/vnd.openxmlformats-officedocument.spreadsheetml.volatileDependencies+xml	[Makoto_Murata]
931	application	vnd.openxmlformats-officedocument.spreadsheetml.worksheet+xml	application/vnd.openxmlformats-officedocument.spreadsheetml.worksheet+xml	[Makoto_Murata]
932	application	vnd.openxmlformats-officedocument.theme+xml	application/vnd.openxmlformats-officedocument.theme+xml	[Makoto_Murata]
933	application	vnd.openxmlformats-officedocument.themeOverride+xml	application/vnd.openxmlformats-officedocument.themeOverride+xml	[Makoto_Murata]
934	application	vnd.openxmlformats-officedocument.vmlDrawing	application/vnd.openxmlformats-officedocument.vmlDrawing	[Makoto_Murata]
935	application	vnd.openxmlformats-officedocument.wordprocessingml.comments+xml	application/vnd.openxmlformats-officedocument.wordprocessingml.comments+xml	[Makoto_Murata]
936	application	vnd.openxmlformats-officedocument.wordprocessingml.document	application/vnd.openxmlformats-officedocument.wordprocessingml.document	[Makoto_Murata]
937	application	vnd.openxmlformats-officedocument.wordprocessingml.document.glossary+xml	application/vnd.openxmlformats-officedocument.wordprocessingml.document.glossary+xml	[Makoto_Murata]
938	application	vnd.openxmlformats-officedocument.wordprocessingml.document.main+xml	application/vnd.openxmlformats-officedocument.wordprocessingml.document.main+xml	[Makoto_Murata]
939	application	vnd.openxmlformats-officedocument.wordprocessingml.endnotes+xml	application/vnd.openxmlformats-officedocument.wordprocessingml.endnotes+xml	[Makoto_Murata]
940	application	vnd.openxmlformats-officedocument.wordprocessingml.fontTable+xml	application/vnd.openxmlformats-officedocument.wordprocessingml.fontTable+xml	[Makoto_Murata]
941	application	vnd.openxmlformats-officedocument.wordprocessingml.footer+xml	application/vnd.openxmlformats-officedocument.wordprocessingml.footer+xml	[Makoto_Murata]
942	application	vnd.openxmlformats-officedocument.wordprocessingml.footnotes+xml	application/vnd.openxmlformats-officedocument.wordprocessingml.footnotes+xml	[Makoto_Murata]
943	application	vnd.openxmlformats-officedocument.wordprocessingml.numbering+xml	application/vnd.openxmlformats-officedocument.wordprocessingml.numbering+xml	[Makoto_Murata]
944	application	vnd.openxmlformats-officedocument.wordprocessingml.settings+xml	application/vnd.openxmlformats-officedocument.wordprocessingml.settings+xml	[Makoto_Murata]
945	application	vnd.openxmlformats-officedocument.wordprocessingml.styles+xml	application/vnd.openxmlformats-officedocument.wordprocessingml.styles+xml	[Makoto_Murata]
946	application	vnd.openxmlformats-officedocument.wordprocessingml.template	application/vnd.openxmlformats-officedocument.wordprocessingml-template	[Makoto_Murata]
947	application	vnd.openxmlformats-officedocument.wordprocessingml.template.main+xml	application/vnd.openxmlformats-officedocument.wordprocessingml.template.main+xml	[Makoto_Murata]
1016	application	vnd.ruckus.download	application/vnd.ruckus.download	[Jerry_Harris]
948	application	vnd.openxmlformats-officedocument.wordprocessingml.webSettings+xml	application/vnd.openxmlformats-officedocument.wordprocessingml.webSettings+xml	[Makoto_Murata]
949	application	vnd.openxmlformats-package.core-properties+xml	application/vnd.openxmlformats-package.core-properties+xml	[Makoto_Murata]
950	application	vnd.openxmlformats-package.digital-signature-xmlsignature+xml	application/vnd.openxmlformats-package.digital-signature-xmlsignature+xml	[Makoto_Murata]
951	application	vnd.openxmlformats-package.relationships+xml	application/vnd.openxmlformats-package.relationships+xml	[Makoto_Murata]
952	application	vnd.oracle.resource+json	application/vnd.oracle.resource+json	[Ning_Dong]
953	application	vnd.orange.indata	application/vnd.orange.indata	[CHATRAS_Bruno]
954	application	vnd.osa.netdeploy	application/vnd.osa.netdeploy	[Steven_Klos]
955	application	vnd.osgeo.mapguide.package	application/vnd.osgeo.mapguide.package	[Jason_Birch]
956	application	vnd.osgi.bundle	application/vnd.osgi.bundle	[Peter_Kriens]
957	application	vnd.osgi.dp	application/vnd.osgi.dp	[Peter_Kriens]
958	application	vnd.osgi.subsystem	application/vnd.osgi.subsystem	[Peter_Kriens]
959	application	vnd.otps.ct-kip+xml	application/vnd.otps.ct-kip+xml	[Magnus_Nystrom]
960	application	vnd.oxli.countgraph	application/vnd.oxli.countgraph	[C._Titus_Brown]
961	application	vnd.pagerduty+json	application/vnd.pagerduty+json	[Steve_Rice]
962	application	vnd.palm	application/vnd.palm	[Gavin_Peacock]
963	application	vnd.panoply	application/vnd.panoply	[Natarajan_Balasundara]
964	application	vnd.paos.xml	application/vnd.paos+xml	[John_Kemp]
965	application	vnd.pawaafile	application/vnd.pawaafile	[Prakash_Baskaran]
966	application	vnd.pcos	application/vnd.pcos	[Slawomir_Lisznianski]
967	application	vnd.pg.format	application/vnd.pg.format	[April_Gandert]
968	application	vnd.pg.osasli	application/vnd.pg.osasli	[April_Gandert]
969	application	vnd.piaccess.application-licence	application/vnd.piaccess.application-licence	[Lucas_Maneos]
970	application	vnd.picsel	application/vnd.picsel	[Giuseppe_Naccarato]
971	application	vnd.pmi.widget	application/vnd.pmi.widget	[Rhys_Lewis]
972	application	vnd.poc.group-advertisement+xml	application/vnd.poc.group-advertisement+xml	[Sean_Kelley][OMA_Push_to_Talk_over_Cellular_POC_Working_Group]
973	application	vnd.pocketlearn	application/vnd.pocketlearn	[Jorge_Pando]
974	application	vnd.powerbuilder6	application/vnd.powerbuilder6	[David_Guy]
975	application	vnd.powerbuilder6-s	application/vnd.powerbuilder6-s	[David_Guy]
976	application	vnd.powerbuilder7	application/vnd.powerbuilder7	[Reed_Shilts]
977	application	vnd.powerbuilder75	application/vnd.powerbuilder75	[Reed_Shilts]
978	application	vnd.powerbuilder75-s	application/vnd.powerbuilder75-s	[Reed_Shilts]
979	application	vnd.powerbuilder7-s	application/vnd.powerbuilder7-s	[Reed_Shilts]
980	application	vnd.preminet	application/vnd.preminet	[Juoko_Tenhunen]
981	application	vnd.previewsystems.box	application/vnd.previewsystems.box	[Roman_Smolgovsky]
982	application	vnd.proteus.magazine	application/vnd.proteus.magazine	[Pete_Hoch]
983	application	vnd.publishare-delta-tree	application/vnd.publishare-delta-tree	[Oren_Ben-Kiki]
984	application	vnd.pvi.ptid1	application/vnd.pvi.ptid1	[Charles_P._Lamb]
985	application	vnd.pwg-multiplexed	application/vnd.pwg-multiplexed	[RFC3391]
986	application	vnd.pwg-xhtml-print+xml	application/vnd.pwg-xhtml-print+xml	[Don_Wright]
987	application	vnd.qualcomm.brew-app-res	application/vnd.qualcomm.brew-app-res	[Glenn_Forrester]
988	application	vnd.quarantainenet	application/vnd.quarantainenet	[Casper_Joost_Eyckelhof]
989	application	vnd.Quark.QuarkXPress	application/vnd.Quark.QuarkXPress	[Hannes_Scheidler]
990	application	vnd.quobject-quoxdocument	application/vnd.quobject-quoxdocument	[Matthias_Ludwig]
991	application	vnd.radisys.moml+xml	application/vnd.radisys.moml+xml	[RFC5707]
992	application	vnd.radisys.msml-audit-conf+xml	application/vnd.radisys.msml-audit-conf+xml	[RFC5707]
993	application	vnd.radisys.msml-audit-conn+xml	application/vnd.radisys.msml-audit-conn+xml	[RFC5707]
994	application	vnd.radisys.msml-audit-dialog+xml	application/vnd.radisys.msml-audit-dialog+xml	[RFC5707]
995	application	vnd.radisys.msml-audit-stream+xml	application/vnd.radisys.msml-audit-stream+xml	[RFC5707]
996	application	vnd.radisys.msml-audit+xml	application/vnd.radisys.msml-audit+xml	[RFC5707]
997	application	vnd.radisys.msml-conf+xml	application/vnd.radisys.msml-conf+xml	[RFC5707]
998	application	vnd.radisys.msml-dialog-base+xml	application/vnd.radisys.msml-dialog-base+xml	[RFC5707]
999	application	vnd.radisys.msml-dialog-fax-detect+xml	application/vnd.radisys.msml-dialog-fax-detect+xml	[RFC5707]
1000	application	vnd.radisys.msml-dialog-fax-sendrecv+xml	application/vnd.radisys.msml-dialog-fax-sendrecv+xml	[RFC5707]
1001	application	vnd.radisys.msml-dialog-group+xml	application/vnd.radisys.msml-dialog-group+xml	[RFC5707]
1002	application	vnd.radisys.msml-dialog-speech+xml	application/vnd.radisys.msml-dialog-speech+xml	[RFC5707]
1003	application	vnd.radisys.msml-dialog-transform+xml	application/vnd.radisys.msml-dialog-transform+xml	[RFC5707]
1004	application	vnd.radisys.msml-dialog+xml	application/vnd.radisys.msml-dialog+xml	[RFC5707]
1005	application	vnd.radisys.msml+xml	application/vnd.radisys.msml+xml	[RFC5707]
1006	application	vnd.rainstor.data	application/vnd.rainstor.data	[Kevin_Crook]
1007	application	vnd.rapid	application/vnd.rapid	[Etay_Szekely]
1008	application	vnd.rar	application/vnd.rar	[Kim_Scarborough]
1009	application	vnd.realvnc.bed	application/vnd.realvnc.bed	[Nick_Reeves]
1010	application	vnd.recordare.musicxml	application/vnd.recordare.musicxml	[Michael_Good]
1011	application	vnd.recordare.musicxml+xml	application/vnd.recordare.musicxml+xml	[Michael_Good]
1012	application	vnd.RenLearn.rlprint	application/vnd.renlearn.rlprint	[James_Wick]
1013	application	vnd.rig.cryptonote	application/vnd.rig.cryptonote	[Ken_Jibiki]
1017	application	vnd.s3sms	application/vnd.s3sms	[Lauri_Tarkkala]
1018	application	vnd.sailingtracker.track	application/vnd.sailingtracker.track	[Heikki_Vesalainen]
1019	application	vnd.sbm.cid	application/vnd.sbm.cid	[Shinji_Kusakari]
1020	application	vnd.sbm.mid2	application/vnd.sbm.mid2	[Masanori_Murai]
1021	application	vnd.scribus	application/vnd.scribus	[Craig_Bradney]
1022	application	vnd.sealed.3df	application/vnd.sealed.3df	[John_Kwan]
1023	application	vnd.sealed.csf	application/vnd.sealed.csf	[John_Kwan]
1024	application	vnd.sealed.doc	application/vnd.sealed-doc	[David_Petersen]
1025	application	vnd.sealed.eml	application/vnd.sealed-eml	[David_Petersen]
1026	application	vnd.sealed.mht	application/vnd.sealed-mht	[David_Petersen]
1027	application	vnd.sealed.net	application/vnd.sealed.net	[Martin_Lambert]
1028	application	vnd.sealed.ppt	application/vnd.sealed-ppt	[David_Petersen]
1029	application	vnd.sealed.tiff	application/vnd.sealed-tiff	[John_Kwan][Martin_Lambert]
1030	application	vnd.sealed.xls	application/vnd.sealed-xls	[David_Petersen]
1031	application	vnd.sealedmedia.softseal.html	application/vnd.sealedmedia.softseal-html	[David_Petersen]
1032	application	vnd.sealedmedia.softseal.pdf	application/vnd.sealedmedia.softseal-pdf	[David_Petersen]
1033	application	vnd.seemail	application/vnd.seemail	[Steve_Webb]
1034	application	vnd.sema	application/vnd-sema	[Anders_Hansson]
1035	application	vnd.semd	application/vnd.semd	[Anders_Hansson]
1036	application	vnd.semf	application/vnd.semf	[Anders_Hansson]
1037	application	vnd.shana.informed.formdata	application/vnd.shana.informed.formdata	[Guy_Selzler]
1038	application	vnd.shana.informed.formtemplate	application/vnd.shana.informed.formtemplate	[Guy_Selzler]
1039	application	vnd.shana.informed.interchange	application/vnd.shana.informed.interchange	[Guy_Selzler]
1040	application	vnd.shana.informed.package	application/vnd.shana.informed.package	[Guy_Selzler]
1041	application	vnd.SimTech-MindMapper	application/vnd.SimTech-MindMapper	[Patrick_Koh]
1042	application	vnd.siren+json	application/vnd.siren+json	[Kevin_Swiber]
1043	application	vnd.smaf	application/vnd.smaf	[Hiroaki_Takahashi]
1044	application	vnd.smart.notebook	application/vnd.smart.notebook	[Jonathan_Neitz]
1045	application	vnd.smart.teacher	application/vnd.smart.teacher	[Michael_Boyle]
1046	application	vnd.software602.filler.form+xml	application/vnd.software602.filler.form+xml	[Jakub_Hytka][Martin_Vondrous]
1047	application	vnd.software602.filler.form-xml-zip	application/vnd.software602.filler.form-xml-zip	[Jakub_Hytka][Martin_Vondrous]
1048	application	vnd.solent.sdkm+xml	application/vnd.solent.sdkm+xml	[Cliff_Gauntlett]
1049	application	vnd.spotfire.dxp	application/vnd.spotfire.dxp	[Stefan_Jernberg]
1050	application	vnd.spotfire.sfs	application/vnd.spotfire.sfs	[Stefan_Jernberg]
1051	application	vnd.sss-cod	application/vnd.sss-cod	[Asang_Dani]
1052	application	vnd.sss-dtf	application/vnd.sss-dtf	[Eric_Bruno]
1053	application	vnd.sss-ntf	application/vnd.sss-ntf	[Eric_Bruno]
1054	application	vnd.stepmania.package	application/vnd.stepmania.package	[Henrik_Andersson]
1055	application	vnd.stepmania.stepchart	application/vnd.stepmania.stepchart	[Henrik_Andersson]
1056	application	vnd.street-stream	application/vnd.street-stream	[Glenn_Levitt]
1057	application	vnd.sun.wadl+xml	application/vnd.sun.wadl+xml	[Marc_Hadley]
1058	application	vnd.sus-calendar	application/vnd.sus-calendar	[Jonathan_Niedfeldt]
1059	application	vnd.svd	application/vnd.svd	[Scott_Becker]
1060	application	vnd.swiftview-ics	application/vnd.swiftview-ics	[Glenn_Widener]
1061	application	vnd.syncml.dm.notification	application/vnd.syncml.dm.notification	[Peter_Thompson][OMA-DM_Work_Group]
1062	application	vnd.syncml.dmddf+xml	application/vnd.syncml.dmddf+xml	[OMA-DM_Work_Group]
1063	application	vnd.syncml.dmtnds+wbxml	application/vnd.syncml.dmtnds+wbxml	[OMA-DM_Work_Group]
1064	application	vnd.syncml.dmtnds+xml	application/vnd.syncml.dmtnds+xml	[OMA-DM_Work_Group]
1065	application	vnd.syncml.dmddf+wbxml	application/vnd.syncml.dmddf+wbxml	[OMA-DM_Work_Group]
1066	application	vnd.syncml.dm+wbxml	application/vnd.syncml.dm+wbxml	[OMA-DM_Work_Group]
1067	application	vnd.syncml.dm+xml	application/vnd.syncml.dm+xml	[Bindu_Rama_Rao][OMA-DM_Work_Group]
1068	application	vnd.syncml.ds.notification	application/vnd.syncml.ds.notification	[OMA_Data_Synchronization_Working_Group]
1069	application	vnd.syncml+xml	application/vnd.syncml+xml	[OMA_Data_Synchronization_Working_Group]
1070	application	vnd.tao.intent-module-archive	application/vnd.tao.intent-module-archive	[Daniel_Shelton]
1071	application	vnd.tcpdump.pcap	application/vnd.tcpdump.pcap	[Guy_Harris][Glen_Turner]
1072	application	vnd.tml	application/vnd.tml	[Joey_Smith]
1073	application	vnd.tmd.mediaflex.api+xml	application/vnd.tmd.mediaflex.api+xml	[Alex_Sibilev]
1074	application	vnd.tmobile-livetv	application/vnd.tmobile-livetv	[Nicolas_Helin]
1075	application	vnd.tri.onesource	application/vnd.tri.onesource	[Rick_Rupp]
1076	application	vnd.trid.tpt	application/vnd.trid.tpt	[Frank_Cusack]
1077	application	vnd.triscape.mxs	application/vnd.triscape.mxs	[Steven_Simonoff]
1078	application	vnd.trueapp	application/vnd.trueapp	[J._Scott_Hepler]
1079	application	vnd.truedoc	application/vnd.truedoc	[Brad_Chase]
1080	application	vnd.ubisoft.webplayer	application/vnd.ubisoft.webplayer	[Martin_Talbot]
1081	application	vnd.ufdl	application/vnd.ufdl	[Dave_Manning]
1082	application	vnd.uiq.theme	application/vnd.uiq.theme	[Tim_Ocock]
1083	application	vnd.umajin	application/vnd.umajin	[Jamie_Riden]
1084	application	vnd.unity	application/vnd.unity	[Unity3d]
1085	application	vnd.uoml+xml	application/vnd.uoml+xml	[Arne_Gerdes]
1086	application	vnd.uplanet.alert	application/vnd.uplanet.alert	[Bruce_Martin]
1087	application	vnd.uplanet.alert-wbxml	application/vnd.uplanet.alert-wbxml	[Bruce_Martin]
1088	application	vnd.uplanet.bearer-choice	application/vnd.uplanet.bearer-choice	[Bruce_Martin]
1089	application	vnd.uplanet.bearer-choice-wbxml	application/vnd.uplanet.bearer-choice-wbxml	[Bruce_Martin]
1090	application	vnd.uplanet.cacheop	application/vnd.uplanet.cacheop	[Bruce_Martin]
1091	application	vnd.uplanet.cacheop-wbxml	application/vnd.uplanet.cacheop-wbxml	[Bruce_Martin]
1092	application	vnd.uplanet.channel	application/vnd.uplanet.channel	[Bruce_Martin]
1093	application	vnd.uplanet.channel-wbxml	application/vnd.uplanet.channel-wbxml	[Bruce_Martin]
1094	application	vnd.uplanet.list	application/vnd.uplanet.list	[Bruce_Martin]
1095	application	vnd.uplanet.listcmd	application/vnd.uplanet.listcmd	[Bruce_Martin]
1096	application	vnd.uplanet.listcmd-wbxml	application/vnd.uplanet.listcmd-wbxml	[Bruce_Martin]
1097	application	vnd.uplanet.list-wbxml	application/vnd.uplanet.list-wbxml	[Bruce_Martin]
1098	application	vnd.uri-map	application/vnd.uri-map	[Sebastian_Baer]
1099	application	vnd.uplanet.signal	application/vnd.uplanet.signal	[Bruce_Martin]
1100	application	vnd.valve.source.material	application/vnd.valve.source.material	[Henrik_Andersson]
1101	application	vnd.vcx	application/vnd.vcx	[Taisuke_Sugimoto]
1102	application	vnd.vd-study	application/vnd.vd-study	[Luc_Rogge]
1103	application	vnd.vectorworks	application/vnd.vectorworks	[Lyndsey_Ferguson][Biplab_Sarkar]
1104	application	vnd.vel+json	application/vnd.vel+json	[James_Wigger]
1105	application	vnd.verimatrix.vcas	application/vnd.verimatrix.vcas	[Petr_Peterka]
1106	application	vnd.vidsoft.vidconference	application/vnd.vidsoft.vidconference	[Robert_Hess]
1107	application	vnd.visio	application/vnd.visio	[Troy_Sandal]
1108	application	vnd.visionary	application/vnd.visionary	[Gayatri_Aravindakumar]
1109	application	vnd.vividence.scriptfile	application/vnd.vividence.scriptfile	[Mark_Risher]
1110	application	vnd.vsf	application/vnd.vsf	[Delton_Rowe]
1111	application	vnd.wap.sic	application/vnd.wap.sic	[WAP-Forum]
1112	application	vnd.wap.slc	application/vnd.wap-slc	[WAP-Forum]
1113	application	vnd.wap.wbxml	application/vnd.wap-wbxml	[Peter_Stark]
1114	application	vnd.wap.wmlc	application/vnd-wap-wmlc	[Peter_Stark]
1115	application	vnd.wap.wmlscriptc	application/vnd.wap.wmlscriptc	[Peter_Stark]
1116	application	vnd.webturbo	application/vnd.webturbo	[Yaser_Rehem]
1117	application	vnd.wfa.p2p	application/vnd.wfa.p2p	[Mick_Conley]
1118	application	vnd.wfa.wsc	application/vnd.wfa.wsc	[Wi-Fi_Alliance]
1119	application	vnd.windows.devicepairing	application/vnd.windows.devicepairing	[Priya_Dandawate]
1120	application	vnd.wmc	application/vnd.wmc	[Thomas_Kjornes]
1121	application	vnd.wmf.bootstrap	application/vnd.wmf.bootstrap	[Thinh_Nguyenphu][Prakash_Iyer]
1122	application	vnd.wolfram.mathematica	application/vnd.wolfram.mathematica	[Wolfram]
1123	application	vnd.wolfram.mathematica.package	application/vnd.wolfram.mathematica.package	[Wolfram]
1124	application	vnd.wolfram.player	application/vnd.wolfram.player	[Wolfram]
1125	application	vnd.wordperfect	application/vnd.wordperfect	[Kim_Scarborough]
1126	application	vnd.wqd	application/vnd.wqd	[Jan_Bostrom]
1127	application	vnd.wrq-hp3000-labelled	application/vnd.wrq-hp3000-labelled	[Chris_Bartram]
1128	application	vnd.wt.stf	application/vnd.wt.stf	[Bill_Wohler]
1129	application	vnd.wv.csp+xml	application/vnd.wv.csp+xml	[John_Ingi_Ingimundarson]
1130	application	vnd.wv.csp+wbxml	application/vnd.wv.csp+wbxml	[Matti_Salmi]
1131	application	vnd.wv.ssp+xml	application/vnd.wv.ssp+xml	[John_Ingi_Ingimundarson]
1132	application	vnd.xacml+json	application/vnd.xacml+json	[David_Brossard]
1133	application	vnd.xara	application/vnd.xara	[David_Matthewman]
1134	application	vnd.xfdl	application/vnd.xfdl	[Dave_Manning]
1135	application	vnd.xfdl.webform	application/vnd.xfdl.webform	[Michael_Mansell]
1136	application	vnd.xmi+xml	application/vnd.xmi+xml	[Fred_Waskiewicz]
1137	application	vnd.xmpie.cpkg	application/vnd.xmpie.cpkg	[Reuven_Sherwin]
1138	application	vnd.xmpie.dpkg	application/vnd.xmpie.dpkg	[Reuven_Sherwin]
1139	application	vnd.xmpie.plan	application/vnd.xmpie.plan	[Reuven_Sherwin]
1140	application	vnd.xmpie.ppkg	application/vnd.xmpie.ppkg	[Reuven_Sherwin]
1141	application	vnd.xmpie.xlim	application/vnd.xmpie.xlim	[Reuven_Sherwin]
1142	application	vnd.yamaha.hv-dic	application/vnd.yamaha.hv-dic	[Tomohiro_Yamamoto]
1143	application	vnd.yamaha.hv-script	application/vnd.yamaha.hv-script	[Tomohiro_Yamamoto]
1144	application	vnd.yamaha.hv-voice	application/vnd.yamaha.hv-voice	[Tomohiro_Yamamoto]
1145	application	vnd.yamaha.openscoreformat.osfpvg+xml	application/vnd.yamaha.openscoreformat.osfpvg+xml	[Mark_Olleson]
1146	application	vnd.yamaha.openscoreformat	application/vnd.yamaha.openscoreformat	[Mark_Olleson]
1147	application	vnd.yamaha.remote-setup	application/vnd.yamaha.remote-setup	[Takehiro_Sukizaki]
1148	application	vnd.yamaha.smaf-audio	application/vnd.yamaha.smaf-audio	[Keiichi_Shinoda]
1149	application	vnd.yamaha.smaf-phrase	application/vnd.yamaha.smaf-phrase	[Keiichi_Shinoda]
1150	application	vnd.yamaha.through-ngn	application/vnd.yamaha.through-ngn	[Takehiro_Sukizaki]
1151	application	vnd.yamaha.tunnel-udpencap	application/vnd.yamaha.tunnel-udpencap	[Takehiro_Sukizaki]
1152	application	vnd.yaoweme	application/vnd.yaoweme	[Jens_Jorgensen]
1153	application	vnd.yellowriver-custom-menu	application/vnd.yellowriver-custom-menu	[Mr._Yellow]
1154	application	vnd.zul	application/vnd.zul	[Rene_Grothmann]
1155	application	vnd.zzazz.deck+xml	application/vnd.zzazz.deck+xml	[Micheal_Hewett]
1156	application	voicexml+xml	application/voicexml+xml	[RFC4267]
1157	application	vq-rtcpxr	application/vq-rtcpxr	[RFC6035]
1158	application	watcherinfo+xml	application/watcherinfo+xml	[RFC3858]
1159	application	whoispp-query	application/whoispp-query	[RFC2957]
1160	application	whoispp-response	application/whoispp-response	[RFC2958]
1161	application	widget		[W3C][Steven_Pemberton][ISO/IEC 19757-2:2003/FDAM-1]
1163	application	wordperfect5.1	application/wordperfect5.1	[Paul_Lindner]
1164	application	wsdl+xml	application/wsdl+xml	[W3C]
1165	application	wspolicy+xml	application/wspolicy+xml	[W3C]
1166	application	x-www-form-urlencoded	application/x-www-form-urlencoded	[W3C][Robin_Berjon]
1167	application	x400-bp	application/x400-bp	[RFC1494]
1168	application	xacml+xml	application/xacml+xml	[RFC7061]
1169	application	xcap-att+xml	application/xcap-att+xml	[RFC4825]
1170	application	xcap-caps+xml	application/xcap-caps+xml	[RFC4825]
1171	application	xcap-diff+xml	application/xcap-diff+xml	[RFC5874]
1172	application	xcap-el+xml	application/xcap-el+xml	[RFC4825]
1173	application	xcap-error+xml	application/xcap-error+xml	[RFC4825]
1174	application	xcap-ns+xml	application/xcap-ns+xml	[RFC4825]
1175	application	xcon-conference-info-diff+xml	application/xcon-conference-info-diff+xml	[RFC6502]
1176	application	xcon-conference-info+xml	application/xcon-conference-info+xml	[RFC6502]
1177	application	xenc+xml	application/xenc+xml	[Joseph_Reagle][XENC_Working_Group]
1178	application	xhtml+xml	application/xhtml+xml	[W3C][Robin_Berjon]
1179	application	xml	application/xml	[RFC7303]
1180	application	xml-dtd	application/xml-dtd	[RFC7303]
1181	application	xml-external-parsed-entity	application/xml-external-parsed-entity	[RFC7303]
1182	application	xml-patch+xml	application/xml-patch+xml	[RFC7351]
1183	application	xmpp+xml	application/xmpp+xml	[RFC3923]
1184	application	xop+xml	application/xop+xml	[Mark_Nottingham]
1185	application	xslt+xml		[W3C][http://www.w3.org/TR/2007/REC-xslt20-20070123/#media-type-registration]
1186	application	xv+xml	application/xv+xml	[RFC4374]
1187	application	yang	application/yang	[RFC6020]
1188	application	yin+xml	application/yin+xml	[RFC6020]
1189	application	zip	application/zip	[Paul_Lindner]
1190	application	zlib	application/zlib	[RFC6713]
\.


--
-- Data for Name: documentmanagement; Type: TABLE DATA; Schema: public; Owner: user_captura
--

COPY public.documentmanagement (id, contractingprocess_id, origin, document, instance_id, type, register_date, error) FROM stdin;
\.


--
-- Data for Name: documenttype; Type: TABLE DATA; Schema: public; Owner: user_captura
--

COPY public.documenttype (id, category, code, title, title_esp, description, source, stage) FROM stdin;
1	intermediate	hearingNotice	Public Hearing Notice	Aviso de audiencia pública	Details of any public hearings that took place as part of the planning for this procurement.		1
2	advanced	feasibilityStudy	Feasibility study	Estudio de factibilidad			1
3	advanced	assetAndLiabilityAssessment	Assesment of government’s assets and liabilities	Evaluación de los activos y responsabilidades del gobierno			1
4	advanced	environmentalImpact	Environmental Impact	Impacto ambiental			1
6	advanced	needsAssessment	Needs Assessment	Justificación de la contratación			1
7	advanced	projectPlan	Project plan	Plan de proyecto			1
8	basic	procurementPlan	Procurement Plan	Proyecto de convocatoria			1
9	intermediate	clarifications	Clarifications to bidders questions	Acta de junta de aclaraciones	Including replies to issues raised in pre-bid conferences.		2
10	basic	technicalSpecifications	Technical Specifications	Anexo técnico	Detailed technical information about goods or services to be provided.		2
11	basic	biddingDocuments	Bidding Documents	Anexos de la convocatoria	Information for potential suppliers, describing the goals of the contract (e.g. goods and services to be procured) and the bidding process.		2
12	advanced	riskProvisions	Provisions for management of risks and liabilities	Cláusulas de riesgos y responsabilidades			2
13	advanced	conflictOfInterest	conflicts of interest uncovered	Conflicto de intereses			2
15	intermediate	eligibilityCriteria	Eligibility Criteria	Criterios de elegibilidad	Detailed documents about the eligibility of bidders.		2
16	basic	evaluationCriteria	Evaluation Criteria	Criterios de evaluación	Information about how bids will be evaluated.		2
17	intermediate	shortlistedFirms	Shortlisted Firms	Empresas preseleccionadas			2
18	advanced	billOfQuantity	Bill Of Quantity	Especificación de cantidades			2
19	advanced	bidders	Information on bidders	Información de los oferentes	Information on bidders or participants,their validation documents and any procedural exemptions for which they qualify		2
20	advanced	debarments	debarments issued	Inhabilitaciones			2
22	advanced	winningBid	Winning Bid	Proposición ganadora			3
23	advanced	complaints	Complaints and decisions	Quejas y aclaraciones			3
24	intermediate	evaluationReports	Evaluation report	Reporte de resultado de la evaluación	Report on the evaluation of the bids and the application of the evaluation criteria, including the justification fo the award		3
25	intermediate	contractArrangements	Arrangements for ending contract	Acuerdos de terminación del contrato			4
26	intermediate	contractSchedule	Schedules and milestones	Anexo del contrato			4
27	advanced	contractAnnexe	Contract Annexe	Anexos del Contrato			4
29	basic	contractNotice	Contract Notice	Datos relevantes del contrato	The formal notice that gives details of a contract being signed and valid to start implementation. This may be a link to a downloadable document		4
30	advanced	contractGuarantees	Guarantees	Garantías del contrato			4
31	advanced	subContract	Subcontracts	Subcontratos	A document detailing subcontracts,  the subcontract itself or a linked OCDS document describing a subcontract.		4
32	basic	contractText	Contract Text	Texto del contrato			4
33	intermediate	finalAudit	Final Audit	Conclusión de la auditoría			5
35	intermediate	financialProgressReport	Financial progress reports	Informe de avance financiero	Dates and amounts of stage payments made (against total amount) and the source of those payments, including cost overruns if any. Structured versions of this data can be provided through transactions.		5
36	intermediate	physicalProgressReport	Physical progress reports	Informe de avance físico	A report on the status of implementation, usually against key milestones.		5
37	intermediate	marketStudies		Resultado de la investigación de mercado			1
38	intermediate	request		Requisición			1
39	intermediate	tenderNotice		Convocatoria			2
40	intermediate	unsuccessfulProcedureNotice		Acta de fallo (desierto)			3
41	intermediate	awardNotice		Notificación de la adjudicación			3
42	intermediate	contractSigned		Contrato			4
43	intermediate	completionCertificate		Dictamen de cumplimiento			5
44	advanced	submissionDocuments	Submission Documents	Documentos de envío	Documentación enviada por un oferente como parte de su propuesta.		3
45	advanced	awardDeferral	Award Deferral	Acta de diferimiento al fallo	Documento formal que modifica la fecha en la que se celebrará el fallo a un momento posterior al que estaba previsto en la convocatoria.		3
46	advanced	cancellationDetails	Cancellation Details	Detalles de cancelación	Documentación de los arreglos, o razones, para la cancelación de un proceso de contratación, adjudicación o contrato específico.		3
47	intermediate	resolutions	Resolutions	Resoluciones	Documentos legales emitidos por la entidad a fin de plasmas sus decisiones. Resolución que nombra la comisión evaluadora, Resolución que adjudica, resolución que declara desierto el acto, resolución que aprueba la licitación.		3
48	basic	notes	Notes	Notas	Documentación con información enviada por parte de la entidad o del contratista.		5
\.


--
-- Data for Name: gdmx_dictionary; Type: TABLE DATA; Schema: public; Owner: user_captura
--

COPY public.gdmx_dictionary (id, document, variable, tablename, field, parent, type, index, classification, catalog, catalog_field, storeprocedure) FROM stdin;
\.


--
-- Data for Name: gdmx_document; Type: TABLE DATA; Schema: public; Owner: user_captura
--

COPY public.gdmx_document (id, name, stage, type, tablename, identifier) FROM stdin;
\.


--
-- Data for Name: guarantees; Type: TABLE DATA; Schema: public; Owner: user_captura
--

COPY public.guarantees (id, contractingprocess_id, contract_id, guarantee_id, guaranteetype, date, guaranteedobligations, value, guarantor, guaranteeperiod_startdate, guaranteeperiod_enddate, currency) FROM stdin;
\.


--
-- Data for Name: implementation; Type: TABLE DATA; Schema: public; Owner: user_captura
--

COPY public.implementation (id, contractingprocess_id, contract_id, status, datelastupdate) FROM stdin;
\.


--
-- Data for Name: implementationdocuments; Type: TABLE DATA; Schema: public; Owner: user_captura
--

COPY public.implementationdocuments (id, contractingprocess_id, contract_id, implementation_id, document_type, documentid, title, description, url, date_published, date_modified, format, language) FROM stdin;
\.


--
-- Data for Name: implementationmilestone; Type: TABLE DATA; Schema: public; Owner: user_captura
--

COPY public.implementationmilestone (id, contractingprocess_id, contract_id, implementation_id, milestoneid, title, description, duedate, date_modified, status, type) FROM stdin;
\.


--
-- Data for Name: implementationmilestonedocuments; Type: TABLE DATA; Schema: public; Owner: user_captura
--

COPY public.implementationmilestonedocuments (id, contractingprocess_id, contract_id, implementation_id, document_type, documentid, title, description, url, date_published, date_modified, format, language) FROM stdin;
\.


--
-- Data for Name: implementationstatus; Type: TABLE DATA; Schema: public; Owner: user_captura
--

COPY public.implementationstatus (id, code, title, title_esp, description) FROM stdin;
1	None	none	Ninguno	
2	planning	planning	En planeación	
3	ongoing	ongoing	En progreso	
4	concluded	concluded	En finiquito	
\.


--
-- Data for Name: implementationtransactions; Type: TABLE DATA; Schema: public; Owner: user_captura
--

COPY public.implementationtransactions (id, contractingprocess_id, contract_id, implementation_id, transactionid, source, implementation_date, value_amount, value_currency, payment_method, uri, payer_name, payer_id, payee_name, payee_id, value_amountnet) FROM stdin;
\.


--
-- Data for Name: item; Type: TABLE DATA; Schema: public; Owner: user_captura
--

COPY public.item (id, classificationid, description, unit) FROM stdin;
\.


--
-- Data for Name: language; Type: TABLE DATA; Schema: public; Owner: user_captura
--

COPY public.language (id, alpha2, name) FROM stdin;
1	aa	Afar
2	ab	Abkhazian
3	ae	Avestan
4	af	Afrikaans
5	ak	Akan
6	am	Amharic
7	an	Aragonese
8	ar	Arabic
9	as	Assamese
10	av	Avaric
11	ay	Aymara
12	az	Azerbaijani
13	ba	Bashkir
14	be	Belarusian
15	bg	Bulgarian
16	bh	Bihari languages
17	bi	Bislama
18	bm	Bambara
19	bn	Bengali
20	bo	Tibetan
21	br	Breton
22	bs	Bosnian
23	ca	Catalan; Valencian
24	ce	Chechen
25	ch	Chamorro
26	co	Corsican
27	cr	Cree
28	cs	Czech
29	cu	Church Slavic; Old Slavonic; Church Slavonic; Old Bulgarian; Old Church Slavonic
30	cv	Chuvash
31	cy	Welsh
32	da	Danish
33	de	German
34	dv	Divehi; Dhivehi; Maldivian
35	dz	Dzongkha
36	ee	Ewe
37	el	Greek, Modern (1453-)
38	en	English
39	eo	Esperanto
40	es	Spanish; Castilian
41	et	Estonian
42	eu	Basque
43	fa	Persian
44	ff	Fulah
45	fi	Finnish
46	fj	Fijian
47	fo	Faroese
48	fr	French
49	fy	Western Frisian
50	ga	Irish
51	gd	Gaelic; Scottish Gaelic
52	gl	Galician
53	gn	Guarani
54	gu	Gujarati
55	gv	Manx
56	ha	Hausa
57	he	Hebrew
58	hi	Hindi
59	ho	Hiri Motu
60	hr	Croatian
61	ht	Haitian; Haitian Creole
62	hu	Hungarian
63	hy	Armenian
64	hz	Herero
65	ia	Interlingua (International Auxiliary Language Association)
66	id	Indonesian
67	ie	Interlingue; Occidental
68	ig	Igbo
69	ii	Sichuan Yi; Nuosu
70	ik	Inupiaq
71	io	Ido
72	is	Icelandic
73	it	Italian
74	iu	Inuktitut
75	ja	Japanese
76	jv	Javanese
77	ka	Georgian
78	kg	Kongo
79	ki	Kikuyu; Gikuyu
80	kj	Kuanyama; Kwanyama
81	kk	Kazakh
82	kl	Kalaallisut; Greenlandic
83	km	Central Khmer
84	kn	Kannada
85	ko	Korean
86	kr	Kanuri
87	ks	Kashmiri
88	ku	Kurdish
89	kv	Komi
90	kw	Cornish
91	ky	Kirghiz; Kyrgyz
92	la	Latin
93	lb	Luxembourgish; Letzeburgesch
94	lg	Ganda
95	li	Limburgan; Limburger; Limburgish
96	ln	Lingala
97	lo	Lao
98	lt	Lithuanian
99	lu	Luba-Katanga
100	lv	Latvian
101	mg	Malagasy
102	mh	Marshallese
103	mi	Maori
104	mk	Macedonian
105	ml	Malayalam
106	mn	Mongolian
107	mr	Marathi
108	ms	Malay
109	mt	Maltese
110	my	Burmese
111	na	Nauru
112	nb	Bokmål, Norwegian; Norwegian Bokmål
113	nd	Ndebele, North; North Ndebele
114	ne	Nepali
115	ng	Ndonga
116	nl	Dutch; Flemish
117	nn	Norwegian Nynorsk; Nynorsk, Norwegian
118	no	Norwegian
119	nr	Ndebele, South; South Ndebele
120	nv	Navajo; Navaho
121	ny	Chichewa; Chewa; Nyanja
122	oc	Occitan (post 1500); Provençal
123	oj	Ojibwa
124	om	Oromo
125	or	Oriya
126	os	Ossetian; Ossetic
127	pa	Panjabi; Punjabi
128	pi	Pali
129	pl	Polish
130	ps	Pushto; Pashto
131	pt	Portuguese
132	qu	Quechua
133	rm	Romansh
134	rn	Rundi
135	ro	Romanian; Moldavian; Moldovan
136	ru	Russian
137	rw	Kinyarwanda
138	sa	Sanskrit
139	sc	Sardinian
140	sd	Sindhi
141	se	Northern Sami
142	sg	Sango
143	si	Sinhala; Sinhalese
144	sk	Slovak
145	sl	Slovenian
146	sm	Samoan
147	sn	Shona
148	so	Somali
149	sq	Albanian
150	sr	Serbian
151	ss	Swati
152	st	Sotho, Southern
153	su	Sundanese
154	sv	Swedish
155	sw	Swahili
156	ta	Tamil
157	te	Telugu
158	tg	Tajik
159	th	Thai
160	ti	Tigrinya
161	tk	Turkmen
162	tl	Tagalog
163	tn	Tswana
164	to	Tonga (Tonga Islands)
165	tr	Turkish
166	ts	Tsonga
167	tt	Tatar
168	tw	Twi
169	ty	Tahitian
170	ug	Uighur; Uyghur
171	uk	Ukrainian
172	ur	Urdu
173	uz	Uzbek
174	ve	Venda
175	vi	Vietnamese
176	vo	Volapük
177	wa	Walloon
178	wo	Wolof
179	xh	Xhosa
180	yi	Yiddish
181	yo	Yoruba
182	za	Zhuang; Chuang
183	zh	Chinese
184	zu	Zulu
\.


--
-- Data for Name: links; Type: TABLE DATA; Schema: public; Owner: user_captura
--

COPY public.links (id, json, xlsx, pdf, contractingprocess_id) FROM stdin;
\.


--
-- Data for Name: log_gdmx; Type: TABLE DATA; Schema: public; Owner: user_captura
--

COPY public.log_gdmx (id, date, cp, recordid, record) FROM stdin;
\.


--
-- Data for Name: logs; Type: TABLE DATA; Schema: public; Owner: user_captura
--

COPY public.logs (id, version, update_date, publisher, release_file, release_json, record_json, contractingprocess_id, version_json, published) FROM stdin;
\.


--
-- Data for Name: memberof; Type: TABLE DATA; Schema: public; Owner: user_captura
--

COPY public.memberof (id, memberofid, principal_parties_id, parties_id) FROM stdin;
\.


--
-- Data for Name: metadata; Type: TABLE DATA; Schema: public; Owner: user_captura
--

COPY public.metadata (field_name, value) FROM stdin;
\.


--
-- Data for Name: milestonetype; Type: TABLE DATA; Schema: public; Owner: user_captura
--

COPY public.milestonetype (id, code, title, description) FROM stdin;
1	preProcurement	Pre-procurement milestones	For events during the planning or pre-procurement phase of a process, such as the preparation of key studies.
2	approval	Approval	For events such as the sign-off of a contract or project.
3	engagement	Engagement milestones	For engagement milestones, such as a public hearing.
4	assessment	Assessment milestones	For assessment and adjudication milestones, such as the meeting date of a committee.
5	delivery	Delivery milestones	For delivery milestones, such as the date when a good or service should be provided.
6	reporting	Reporting milestones	For reporting milestones, such as when key reports should be provided.
7	financing	Financing milestones	For events such as planned payments, or equity transfers in public private partnership projects.
8	publicNotices	Public notices	For milestones in which aspects related to public works are specified, such as the closure of streets, changes of traffic, etc.
\.


--
-- Data for Name: parties; Type: TABLE DATA; Schema: public; Owner: user_captura
--

COPY public.parties (contractingprocess_id, id, partyid, name, "position", identifier_scheme, identifier_id, identifier_legalname, identifier_uri, address_streetaddress, address_locality, address_region, address_postalcode, address_countryname, contactpoint_name, contactpoint_email, contactpoint_telephone, contactpoint_faxnumber, contactpoint_url, details, naturalperson, contactpoint_type, contactpoint_language, surname, additionalsurname, contactpoint_surname, contactpoint_additionalsurname, givenname, contactpoint_givenname) FROM stdin;
\.


--
-- Data for Name: partiesadditionalidentifiers; Type: TABLE DATA; Schema: public; Owner: user_captura
--

COPY public.partiesadditionalidentifiers (id, contractingprocess_id, parties_id, scheme, legalname, uri) FROM stdin;
\.


--
-- Data for Name: paymentmethod; Type: TABLE DATA; Schema: public; Owner: user_captura
--

COPY public.paymentmethod (id, code, title, description) FROM stdin;
1	cash	Cash	
2	check	Check	
3	wireTransfer	Wire Transfer	
\.


--
-- Data for Name: planning; Type: TABLE DATA; Schema: public; Owner: user_captura
--

COPY public.planning (id, contractingprocess_id, hasquotes, rationale) FROM stdin;
\.


--
-- Data for Name: planningdocuments; Type: TABLE DATA; Schema: public; Owner: user_captura
--

COPY public.planningdocuments (id, contractingprocess_id, planning_id, documentid, document_type, title, description, url, date_published, date_modified, format, language) FROM stdin;
\.


--
-- Data for Name: pntreference; Type: TABLE DATA; Schema: public; Owner: user_captura
--

COPY public.pntreference (id, contractingprocess_id, contractid, format, record_id, "position", field_id, reference_id, date, isroot, error) FROM stdin;
\.


--
-- Data for Name: prefixocid; Type: TABLE DATA; Schema: public; Owner: user_captura
--

COPY public.prefixocid (id, value) FROM stdin;
\.


--
-- Data for Name: programaticstructure; Type: TABLE DATA; Schema: public; Owner: user_captura
--

COPY public.programaticstructure (id, cve, year, trimester, branch, branch_desc, finality, finality_desc, function, function_desc, subfunction, subfunction_desc, institutionalactivity, institutionalactivity_desc, budgetprogram, budgetprogram_desc, strategicobjective, strategicobjective_desc, responsibleunit, responsibleunit_desc, requestingunit, requestingunit_desc, spendingtype, spendingtype_desc, specificactivity, specificactivity_desc, spendingobject, spendingobject_desc, region, region_desc, budgetsource, budgetsource_desc, portfoliokey, approvedamount, modifiedamount, executedamount, committedamount, reservedamount) FROM stdin;
\.


--
-- Data for Name: publisher; Type: TABLE DATA; Schema: public; Owner: user_captura
--

COPY public.publisher (id, contractingprocess_id, name, scheme, uid, uri) FROM stdin;
\.


--
-- Data for Name: quotes; Type: TABLE DATA; Schema: public; Owner: user_captura
--

COPY public.quotes (id, requestforquotes_id, quotes_id, description, date, value, quoteperiod_startdate, quoteperiod_enddate, issuingsupplier_id) FROM stdin;
\.


--
-- Data for Name: quotesitems; Type: TABLE DATA; Schema: public; Owner: user_captura
--

COPY public.quotesitems (id, quotes_id, itemid, item, quantity) FROM stdin;
\.


--
-- Data for Name: relatedprocedure; Type: TABLE DATA; Schema: public; Owner: user_captura
--

COPY public.relatedprocedure (id, contractingprocess_id, relatedprocedure_id, relationship_type, title, identifier_scheme, relatedprocedure_identifier, url) FROM stdin;
\.


--
-- Data for Name: requestforquotes; Type: TABLE DATA; Schema: public; Owner: user_captura
--

COPY public.requestforquotes (id, contractingprocess_id, planning_id, requestforquotes_id, title, description, period_startdate, period_enddate) FROM stdin;
\.


--
-- Data for Name: requestforquotesinvitedsuppliers; Type: TABLE DATA; Schema: public; Owner: user_captura
--

COPY public.requestforquotesinvitedsuppliers (id, requestforquotes_id, parties_id) FROM stdin;
\.


--
-- Data for Name: requestforquotesitems; Type: TABLE DATA; Schema: public; Owner: user_captura
--

COPY public.requestforquotesitems (id, requestforquotes_id, itemid, item, quantity) FROM stdin;
\.


--
-- Data for Name: rolecatalog; Type: TABLE DATA; Schema: public; Owner: user_captura
--

COPY public.rolecatalog (id, code, title, description) FROM stdin;
1	buyer	Buyer	The buyer is the entity whose budget will be used to purchase the goods.
2	procuringEntity	Procuring Entity	The entity managing the procurement, which may be different from the buyer who is paying / using the items being procured.
3	supplier	Supplier	The entity awarded or contracted to provide supplies, works or services.
4	tenderer	Tenderer	All entities who submit a tender
5	funder	Funder	The funder is an entity providing money or finance for this contracting process.
6	enquirer	Enquirer	A party who has made an enquiry during the enquiry phase of a contracting process.
7	payer	Payer	A party making a payment from a transaction
8	payee	Payee	A party in receipt of a payment from a transaction
9	reviewBody	Review Body	A party responsible for the review of this procurement process. This party often has a role in any challenges made to the contract award.
\.


--
-- Data for Name: roles; Type: TABLE DATA; Schema: public; Owner: user_captura
--

COPY public.roles (contractingprocess_id, parties_id, id, buyer, procuringentity, supplier, tenderer, funder, enquirer, payer, payee, reviewbody, attendee, official, invitedsupplier, issuingsupplier, guarantor, requestingunit, contractingunit, technicalunit) FROM stdin;
\.


--
-- Data for Name: tags; Type: TABLE DATA; Schema: public; Owner: user_captura
--

COPY public.tags (id, contractingprocess_id, planning, planningupdate, tender, tenderamendment, tenderupdate, tendercancellation, award, awardupdate, awardcancellation, contract, contractupdate, contractamendment, implementation, implementationupdate, contracttermination, compiled, stage, register_date) FROM stdin;
\.


--
-- Data for Name: tender; Type: TABLE DATA; Schema: public; Owner: user_captura
--

COPY public.tender (id, contractingprocess_id, tenderid, title, description, status, minvalue_amount, minvalue_currency, value_amount, value_currency, procurementmethod, procurementmethod_details, procurementmethod_rationale, mainprocurementcategory, additionalprocurementcategories, awardcriteria, awardcriteria_details, submissionmethod, submissionmethod_details, tenderperiod_startdate, tenderperiod_enddate, enquiryperiod_startdate, enquiryperiod_enddate, hasenquiries, eligibilitycriteria, awardperiod_startdate, awardperiod_enddate, numberoftenderers, amendment_date, amendment_rationale, procurementmethod_rationale_id) FROM stdin;
\.


--
-- Data for Name: tenderamendmentchanges; Type: TABLE DATA; Schema: public; Owner: user_captura
--

COPY public.tenderamendmentchanges (id, contractingprocess_id, tender_id, property, former_value, amendments_date, amendments_rationale, amendments_id, amendments_description) FROM stdin;
\.


--
-- Data for Name: tenderdocuments; Type: TABLE DATA; Schema: public; Owner: user_captura
--

COPY public.tenderdocuments (id, contractingprocess_id, tender_id, document_type, documentid, title, description, url, date_published, date_modified, format, language) FROM stdin;
\.


--
-- Data for Name: tenderitem; Type: TABLE DATA; Schema: public; Owner: user_captura
--

COPY public.tenderitem (id, contractingprocess_id, tender_id, itemid, description, classification_scheme, classification_id, classification_description, classification_uri, quantity, unit_name, unit_value_amount, unit_value_currency, unit_value_amountnet, latitude, longitude, location_postalcode, location_countryname, location_streetaddress, location_region, location_locality) FROM stdin;
\.


--
-- Data for Name: tenderitemadditionalclassifications; Type: TABLE DATA; Schema: public; Owner: user_captura
--

COPY public.tenderitemadditionalclassifications (id, contractingprocess_id, tenderitem_id, scheme, description, uri) FROM stdin;
\.


--
-- Data for Name: tendermilestone; Type: TABLE DATA; Schema: public; Owner: user_captura
--

COPY public.tendermilestone (id, contractingprocess_id, tender_id, milestoneid, title, description, duedate, date_modified, status, type) FROM stdin;
\.


--
-- Data for Name: tendermilestonedocuments; Type: TABLE DATA; Schema: public; Owner: user_captura
--

COPY public.tendermilestonedocuments (id, contractingprocess_id, tender_id, milestone_id, document_type, documentid, title, description, url, date_published, date_modified, format, language) FROM stdin;
\.


--
-- Data for Name: user_contractingprocess; Type: TABLE DATA; Schema: public; Owner: user_captura
--

COPY public.user_contractingprocess (id, user_id, contractingprocess_id) FROM stdin;
\.


--
-- Name: additionalcontactpoints_id_seq; Type: SEQUENCE SET; Schema: dashboard; Owner: user_dashboard
--

SELECT pg_catalog.setval('dashboard.additionalcontactpoints_id_seq', 1, false);


--
-- Name: award_id_seq; Type: SEQUENCE SET; Schema: dashboard; Owner: user_dashboard
--

SELECT pg_catalog.setval('dashboard.award_id_seq', 1, false);


--
-- Name: awardamendmentchanges_id_seq; Type: SEQUENCE SET; Schema: dashboard; Owner: user_dashboard
--

SELECT pg_catalog.setval('dashboard.awardamendmentchanges_id_seq', 1, false);


--
-- Name: awarddocuments_id_seq; Type: SEQUENCE SET; Schema: dashboard; Owner: user_dashboard
--

SELECT pg_catalog.setval('dashboard.awarddocuments_id_seq', 1, false);


--
-- Name: awarditem_id_seq; Type: SEQUENCE SET; Schema: dashboard; Owner: user_dashboard
--

SELECT pg_catalog.setval('dashboard.awarditem_id_seq', 1, false);


--
-- Name: awarditemadditionalclassifications_id_seq; Type: SEQUENCE SET; Schema: dashboard; Owner: user_dashboard
--

SELECT pg_catalog.setval('dashboard.awarditemadditionalclassifications_id_seq', 1, false);


--
-- Name: awardsupplier_id_seq; Type: SEQUENCE SET; Schema: dashboard; Owner: user_dashboard
--

SELECT pg_catalog.setval('dashboard.awardsupplier_id_seq', 1, false);


--
-- Name: budget_id_seq; Type: SEQUENCE SET; Schema: dashboard; Owner: user_dashboard
--

SELECT pg_catalog.setval('dashboard.budget_id_seq', 1, false);


--
-- Name: budgetbreakdown_id_seq; Type: SEQUENCE SET; Schema: dashboard; Owner: user_dashboard
--

SELECT pg_catalog.setval('dashboard.budgetbreakdown_id_seq', 1, false);


--
-- Name: budgetclassifications_id_seq; Type: SEQUENCE SET; Schema: dashboard; Owner: user_dashboard
--

SELECT pg_catalog.setval('dashboard.budgetclassifications_id_seq', 1, false);


--
-- Name: clarificationmeeting_id_seq; Type: SEQUENCE SET; Schema: dashboard; Owner: user_dashboard
--

SELECT pg_catalog.setval('dashboard.clarificationmeeting_id_seq', 1, false);


--
-- Name: clarificationmeetingactor_id_seq; Type: SEQUENCE SET; Schema: dashboard; Owner: user_dashboard
--

SELECT pg_catalog.setval('dashboard.clarificationmeetingactor_id_seq', 1, false);


--
-- Name: contract_id_seq; Type: SEQUENCE SET; Schema: dashboard; Owner: user_dashboard
--

SELECT pg_catalog.setval('dashboard.contract_id_seq', 1, false);


--
-- Name: contractamendmentchanges_id_seq; Type: SEQUENCE SET; Schema: dashboard; Owner: user_dashboard
--

SELECT pg_catalog.setval('dashboard.contractamendmentchanges_id_seq', 1, false);


--
-- Name: contractdocuments_id_seq; Type: SEQUENCE SET; Schema: dashboard; Owner: user_dashboard
--

SELECT pg_catalog.setval('dashboard.contractdocuments_id_seq', 1, false);


--
-- Name: contractingprocess_id_seq; Type: SEQUENCE SET; Schema: dashboard; Owner: user_dashboard
--

SELECT pg_catalog.setval('dashboard.contractingprocess_id_seq', 1, false);


--
-- Name: contractitem_id_seq; Type: SEQUENCE SET; Schema: dashboard; Owner: user_dashboard
--

SELECT pg_catalog.setval('dashboard.contractitem_id_seq', 1, false);


--
-- Name: contractitemadditionalclasifications_id_seq; Type: SEQUENCE SET; Schema: dashboard; Owner: user_dashboard
--

SELECT pg_catalog.setval('dashboard.contractitemadditionalclasifications_id_seq', 1, false);


--
-- Name: currency_id_seq; Type: SEQUENCE SET; Schema: dashboard; Owner: user_dashboard
--

SELECT pg_catalog.setval('dashboard.currency_id_seq', 1, false);


--
-- Name: documentformat_id_seq; Type: SEQUENCE SET; Schema: dashboard; Owner: user_dashboard
--

SELECT pg_catalog.setval('dashboard.documentformat_id_seq', 1, false);


--
-- Name: documentmanagement_id_seq; Type: SEQUENCE SET; Schema: dashboard; Owner: user_dashboard
--

SELECT pg_catalog.setval('dashboard.documentmanagement_id_seq', 1, false);


--
-- Name: documenttype_id_seq; Type: SEQUENCE SET; Schema: dashboard; Owner: user_dashboard
--

SELECT pg_catalog.setval('dashboard.documenttype_id_seq', 1, false);


--
-- Name: gdmx_dictionary_id_seq; Type: SEQUENCE SET; Schema: dashboard; Owner: user_dashboard
--

SELECT pg_catalog.setval('dashboard.gdmx_dictionary_id_seq', 1, false);


--
-- Name: gdmx_document_id_seq; Type: SEQUENCE SET; Schema: dashboard; Owner: user_dashboard
--

SELECT pg_catalog.setval('dashboard.gdmx_document_id_seq', 1, false);


--
-- Name: guarantees_id_seq; Type: SEQUENCE SET; Schema: dashboard; Owner: user_dashboard
--

SELECT pg_catalog.setval('dashboard.guarantees_id_seq', 1, false);


--
-- Name: implementation_id_seq; Type: SEQUENCE SET; Schema: dashboard; Owner: user_dashboard
--

SELECT pg_catalog.setval('dashboard.implementation_id_seq', 1, false);


--
-- Name: implementationdocuments_id_seq; Type: SEQUENCE SET; Schema: dashboard; Owner: user_dashboard
--

SELECT pg_catalog.setval('dashboard.implementationdocuments_id_seq', 1, false);


--
-- Name: implementationmilestone_id_seq; Type: SEQUENCE SET; Schema: dashboard; Owner: user_dashboard
--

SELECT pg_catalog.setval('dashboard.implementationmilestone_id_seq', 1, false);


--
-- Name: implementationmilestonedocuments_id_seq; Type: SEQUENCE SET; Schema: dashboard; Owner: user_dashboard
--

SELECT pg_catalog.setval('dashboard.implementationmilestonedocuments_id_seq', 1, false);


--
-- Name: implementationstatus_id_seq; Type: SEQUENCE SET; Schema: dashboard; Owner: user_dashboard
--

SELECT pg_catalog.setval('dashboard.implementationstatus_id_seq', 1, false);


--
-- Name: implementationtransactions_id_seq; Type: SEQUENCE SET; Schema: dashboard; Owner: user_dashboard
--

SELECT pg_catalog.setval('dashboard.implementationtransactions_id_seq', 1, false);


--
-- Name: item_id_seq; Type: SEQUENCE SET; Schema: dashboard; Owner: user_dashboard
--

SELECT pg_catalog.setval('dashboard.item_id_seq', 1, false);


--
-- Name: language_id_seq; Type: SEQUENCE SET; Schema: dashboard; Owner: user_dashboard
--

SELECT pg_catalog.setval('dashboard.language_id_seq', 1, false);


--
-- Name: links_id_seq; Type: SEQUENCE SET; Schema: dashboard; Owner: user_dashboard
--

SELECT pg_catalog.setval('dashboard.links_id_seq', 1, false);


--
-- Name: log_gdmx_id_seq; Type: SEQUENCE SET; Schema: dashboard; Owner: user_dashboard
--

SELECT pg_catalog.setval('dashboard.log_gdmx_id_seq', 1, false);


--
-- Name: logs_id_seq; Type: SEQUENCE SET; Schema: dashboard; Owner: user_dashboard
--

SELECT pg_catalog.setval('dashboard.logs_id_seq', 1, false);


--
-- Name: memberof_id_seq; Type: SEQUENCE SET; Schema: dashboard; Owner: user_dashboard
--

SELECT pg_catalog.setval('dashboard.memberof_id_seq', 1, false);


--
-- Name: milestonetype_id_seq; Type: SEQUENCE SET; Schema: dashboard; Owner: user_dashboard
--

SELECT pg_catalog.setval('dashboard.milestonetype_id_seq', 1, false);


--
-- Name: parties_id_seq; Type: SEQUENCE SET; Schema: dashboard; Owner: user_dashboard
--

SELECT pg_catalog.setval('dashboard.parties_id_seq', 1, false);


--
-- Name: partiesadditionalidentifiers_id_seq; Type: SEQUENCE SET; Schema: dashboard; Owner: user_dashboard
--

SELECT pg_catalog.setval('dashboard.partiesadditionalidentifiers_id_seq', 1, false);


--
-- Name: paymentmethod_id_seq; Type: SEQUENCE SET; Schema: dashboard; Owner: user_dashboard
--

SELECT pg_catalog.setval('dashboard.paymentmethod_id_seq', 1, false);


--
-- Name: planning_id_seq; Type: SEQUENCE SET; Schema: dashboard; Owner: user_dashboard
--

SELECT pg_catalog.setval('dashboard.planning_id_seq', 1, false);


--
-- Name: planningdocuments_id_seq; Type: SEQUENCE SET; Schema: dashboard; Owner: user_dashboard
--

SELECT pg_catalog.setval('dashboard.planningdocuments_id_seq', 1, false);


--
-- Name: pntreference_id_seq; Type: SEQUENCE SET; Schema: dashboard; Owner: user_dashboard
--

SELECT pg_catalog.setval('dashboard.pntreference_id_seq', 1, false);


--
-- Name: prefixocid_id_seq; Type: SEQUENCE SET; Schema: dashboard; Owner: user_dashboard
--

SELECT pg_catalog.setval('dashboard.prefixocid_id_seq', 1, false);


--
-- Name: programaticstructure_id_seq; Type: SEQUENCE SET; Schema: dashboard; Owner: user_dashboard
--

SELECT pg_catalog.setval('dashboard.programaticstructure_id_seq', 1, false);


--
-- Name: publisher_id_seq; Type: SEQUENCE SET; Schema: dashboard; Owner: user_dashboard
--

SELECT pg_catalog.setval('dashboard.publisher_id_seq', 1, false);


--
-- Name: quotes_id_seq; Type: SEQUENCE SET; Schema: dashboard; Owner: user_dashboard
--

SELECT pg_catalog.setval('dashboard.quotes_id_seq', 1, false);


--
-- Name: quotesitems_id_seq; Type: SEQUENCE SET; Schema: dashboard; Owner: user_dashboard
--

SELECT pg_catalog.setval('dashboard.quotesitems_id_seq', 1, false);


--
-- Name: relatedprocedure_id_seq; Type: SEQUENCE SET; Schema: dashboard; Owner: user_dashboard
--

SELECT pg_catalog.setval('dashboard.relatedprocedure_id_seq', 1, false);


--
-- Name: requestforquotes_id_seq; Type: SEQUENCE SET; Schema: dashboard; Owner: user_dashboard
--

SELECT pg_catalog.setval('dashboard.requestforquotes_id_seq', 1, false);


--
-- Name: requestforquotesinvitedsuppliers_id_seq; Type: SEQUENCE SET; Schema: dashboard; Owner: user_dashboard
--

SELECT pg_catalog.setval('dashboard.requestforquotesinvitedsuppliers_id_seq', 1, false);


--
-- Name: requestforquotesitems_id_seq; Type: SEQUENCE SET; Schema: dashboard; Owner: user_dashboard
--

SELECT pg_catalog.setval('dashboard.requestforquotesitems_id_seq', 1, false);


--
-- Name: rolecatalog_id_seq; Type: SEQUENCE SET; Schema: dashboard; Owner: user_dashboard
--

SELECT pg_catalog.setval('dashboard.rolecatalog_id_seq', 1, false);


--
-- Name: roles_id_seq; Type: SEQUENCE SET; Schema: dashboard; Owner: user_dashboard
--

SELECT pg_catalog.setval('dashboard.roles_id_seq', 1, false);


--
-- Name: tags_id_seq; Type: SEQUENCE SET; Schema: dashboard; Owner: user_dashboard
--

SELECT pg_catalog.setval('dashboard.tags_id_seq', 1, false);


--
-- Name: tender_id_seq; Type: SEQUENCE SET; Schema: dashboard; Owner: user_dashboard
--

SELECT pg_catalog.setval('dashboard.tender_id_seq', 1, false);


--
-- Name: tenderamendmentchanges_id_seq; Type: SEQUENCE SET; Schema: dashboard; Owner: user_dashboard
--

SELECT pg_catalog.setval('dashboard.tenderamendmentchanges_id_seq', 1, false);


--
-- Name: tenderdocuments_id_seq; Type: SEQUENCE SET; Schema: dashboard; Owner: user_dashboard
--

SELECT pg_catalog.setval('dashboard.tenderdocuments_id_seq', 1, false);


--
-- Name: tenderitem_id_seq; Type: SEQUENCE SET; Schema: dashboard; Owner: user_dashboard
--

SELECT pg_catalog.setval('dashboard.tenderitem_id_seq', 1, false);


--
-- Name: tenderitemadditionalclassifications_id_seq; Type: SEQUENCE SET; Schema: dashboard; Owner: user_dashboard
--

SELECT pg_catalog.setval('dashboard.tenderitemadditionalclassifications_id_seq', 1, false);


--
-- Name: tendermilestone_id_seq; Type: SEQUENCE SET; Schema: dashboard; Owner: user_dashboard
--

SELECT pg_catalog.setval('dashboard.tendermilestone_id_seq', 1, false);


--
-- Name: tendermilestonedocuments_id_seq; Type: SEQUENCE SET; Schema: dashboard; Owner: user_dashboard
--

SELECT pg_catalog.setval('dashboard.tendermilestonedocuments_id_seq', 1, false);


--
-- Name: user_contractingprocess_id_seq; Type: SEQUENCE SET; Schema: dashboard; Owner: user_dashboard
--

SELECT pg_catalog.setval('dashboard.user_contractingprocess_id_seq', 1, false);


--
-- Name: additionalcontactpoints_id_seq; Type: SEQUENCE SET; Schema: public; Owner: user_captura
--

SELECT pg_catalog.setval('public.additionalcontactpoints_id_seq', 1, false);


--
-- Name: award_id_seq; Type: SEQUENCE SET; Schema: public; Owner: user_captura
--

SELECT pg_catalog.setval('public.award_id_seq', 1, false);


--
-- Name: awardamendmentchanges_id_seq; Type: SEQUENCE SET; Schema: public; Owner: user_captura
--

SELECT pg_catalog.setval('public.awardamendmentchanges_id_seq', 1, false);


--
-- Name: awarddocuments_id_seq; Type: SEQUENCE SET; Schema: public; Owner: user_captura
--

SELECT pg_catalog.setval('public.awarddocuments_id_seq', 1, false);


--
-- Name: awarditem_id_seq; Type: SEQUENCE SET; Schema: public; Owner: user_captura
--

SELECT pg_catalog.setval('public.awarditem_id_seq', 1, false);


--
-- Name: awarditemadditionalclassifications_id_seq; Type: SEQUENCE SET; Schema: public; Owner: user_captura
--

SELECT pg_catalog.setval('public.awarditemadditionalclassifications_id_seq', 1, false);


--
-- Name: awardsupplier_id_seq; Type: SEQUENCE SET; Schema: public; Owner: user_captura
--

SELECT pg_catalog.setval('public.awardsupplier_id_seq', 1, false);


--
-- Name: budget_id_seq; Type: SEQUENCE SET; Schema: public; Owner: user_captura
--

SELECT pg_catalog.setval('public.budget_id_seq', 1, false);


--
-- Name: budgetbreakdown_id_seq; Type: SEQUENCE SET; Schema: public; Owner: user_captura
--

SELECT pg_catalog.setval('public.budgetbreakdown_id_seq', 1, false);


--
-- Name: budgetclassifications_id_seq; Type: SEQUENCE SET; Schema: public; Owner: user_captura
--

SELECT pg_catalog.setval('public.budgetclassifications_id_seq', 1, false);


--
-- Name: clarificationmeeting_id_seq; Type: SEQUENCE SET; Schema: public; Owner: user_captura
--

SELECT pg_catalog.setval('public.clarificationmeeting_id_seq', 1, false);


--
-- Name: clarificationmeetingactor_id_seq; Type: SEQUENCE SET; Schema: public; Owner: user_captura
--

SELECT pg_catalog.setval('public.clarificationmeetingactor_id_seq', 1, false);


--
-- Name: contract_id_seq; Type: SEQUENCE SET; Schema: public; Owner: user_captura
--

SELECT pg_catalog.setval('public.contract_id_seq', 1, false);


--
-- Name: contractamendmentchanges_id_seq; Type: SEQUENCE SET; Schema: public; Owner: user_captura
--

SELECT pg_catalog.setval('public.contractamendmentchanges_id_seq', 1, false);


--
-- Name: contractdocuments_id_seq; Type: SEQUENCE SET; Schema: public; Owner: user_captura
--

SELECT pg_catalog.setval('public.contractdocuments_id_seq', 1, false);


--
-- Name: contractingprocess_id_seq; Type: SEQUENCE SET; Schema: public; Owner: user_captura
--

SELECT pg_catalog.setval('public.contractingprocess_id_seq', 1, false);


--
-- Name: contractitem_id_seq; Type: SEQUENCE SET; Schema: public; Owner: user_captura
--

SELECT pg_catalog.setval('public.contractitem_id_seq', 1, false);


--
-- Name: contractitemadditionalclasifications_id_seq; Type: SEQUENCE SET; Schema: public; Owner: user_captura
--

SELECT pg_catalog.setval('public.contractitemadditionalclasifications_id_seq', 1, false);


--
-- Name: currency_id_seq; Type: SEQUENCE SET; Schema: public; Owner: user_captura
--

SELECT pg_catalog.setval('public.currency_id_seq', 1, false);


--
-- Name: documentformat_id_seq; Type: SEQUENCE SET; Schema: public; Owner: user_captura
--

SELECT pg_catalog.setval('public.documentformat_id_seq', 1, false);


--
-- Name: documentmanagement_id_seq; Type: SEQUENCE SET; Schema: public; Owner: user_captura
--

SELECT pg_catalog.setval('public.documentmanagement_id_seq', 1, false);


--
-- Name: documenttype_id_seq; Type: SEQUENCE SET; Schema: public; Owner: user_captura
--

SELECT pg_catalog.setval('public.documenttype_id_seq', 1, false);


--
-- Name: gdmx_dictionary_id_seq; Type: SEQUENCE SET; Schema: public; Owner: user_captura
--

SELECT pg_catalog.setval('public.gdmx_dictionary_id_seq', 1, false);


--
-- Name: gdmx_document_id_seq; Type: SEQUENCE SET; Schema: public; Owner: user_captura
--

SELECT pg_catalog.setval('public.gdmx_document_id_seq', 1, false);


--
-- Name: guarantees_id_seq; Type: SEQUENCE SET; Schema: public; Owner: user_captura
--

SELECT pg_catalog.setval('public.guarantees_id_seq', 1, false);


--
-- Name: implementation_id_seq; Type: SEQUENCE SET; Schema: public; Owner: user_captura
--

SELECT pg_catalog.setval('public.implementation_id_seq', 1, false);


--
-- Name: implementationdocuments_id_seq; Type: SEQUENCE SET; Schema: public; Owner: user_captura
--

SELECT pg_catalog.setval('public.implementationdocuments_id_seq', 1, false);


--
-- Name: implementationmilestone_id_seq; Type: SEQUENCE SET; Schema: public; Owner: user_captura
--

SELECT pg_catalog.setval('public.implementationmilestone_id_seq', 1, false);


--
-- Name: implementationmilestonedocuments_id_seq; Type: SEQUENCE SET; Schema: public; Owner: user_captura
--

SELECT pg_catalog.setval('public.implementationmilestonedocuments_id_seq', 1, false);


--
-- Name: implementationstatus_id_seq; Type: SEQUENCE SET; Schema: public; Owner: user_captura
--

SELECT pg_catalog.setval('public.implementationstatus_id_seq', 1, false);


--
-- Name: implementationtransactions_id_seq; Type: SEQUENCE SET; Schema: public; Owner: user_captura
--

SELECT pg_catalog.setval('public.implementationtransactions_id_seq', 1, false);


--
-- Name: item_id_seq; Type: SEQUENCE SET; Schema: public; Owner: user_captura
--

SELECT pg_catalog.setval('public.item_id_seq', 1, false);


--
-- Name: language_id_seq; Type: SEQUENCE SET; Schema: public; Owner: user_captura
--

SELECT pg_catalog.setval('public.language_id_seq', 1, false);


--
-- Name: links_id_seq; Type: SEQUENCE SET; Schema: public; Owner: user_captura
--

SELECT pg_catalog.setval('public.links_id_seq', 1, false);


--
-- Name: log_gdmx_id_seq; Type: SEQUENCE SET; Schema: public; Owner: user_captura
--

SELECT pg_catalog.setval('public.log_gdmx_id_seq', 1, false);


--
-- Name: logs_id_seq; Type: SEQUENCE SET; Schema: public; Owner: user_captura
--

SELECT pg_catalog.setval('public.logs_id_seq', 1, false);


--
-- Name: memberof_id_seq; Type: SEQUENCE SET; Schema: public; Owner: user_captura
--

SELECT pg_catalog.setval('public.memberof_id_seq', 1, false);


--
-- Name: milestonetype_id_seq; Type: SEQUENCE SET; Schema: public; Owner: user_captura
--

SELECT pg_catalog.setval('public.milestonetype_id_seq', 1, false);


--
-- Name: parties_id_seq; Type: SEQUENCE SET; Schema: public; Owner: user_captura
--

SELECT pg_catalog.setval('public.parties_id_seq', 1, false);


--
-- Name: partiesadditionalidentifiers_id_seq; Type: SEQUENCE SET; Schema: public; Owner: user_captura
--

SELECT pg_catalog.setval('public.partiesadditionalidentifiers_id_seq', 1, false);


--
-- Name: paymentmethod_id_seq; Type: SEQUENCE SET; Schema: public; Owner: user_captura
--

SELECT pg_catalog.setval('public.paymentmethod_id_seq', 1, false);


--
-- Name: planning_id_seq; Type: SEQUENCE SET; Schema: public; Owner: user_captura
--

SELECT pg_catalog.setval('public.planning_id_seq', 1, false);


--
-- Name: planningdocuments_id_seq; Type: SEQUENCE SET; Schema: public; Owner: user_captura
--

SELECT pg_catalog.setval('public.planningdocuments_id_seq', 1, false);


--
-- Name: pntreference_id_seq; Type: SEQUENCE SET; Schema: public; Owner: user_captura
--

SELECT pg_catalog.setval('public.pntreference_id_seq', 1, false);


--
-- Name: prefixocid_id_seq; Type: SEQUENCE SET; Schema: public; Owner: user_captura
--

SELECT pg_catalog.setval('public.prefixocid_id_seq', 1, false);


--
-- Name: programaticstructure_id_seq; Type: SEQUENCE SET; Schema: public; Owner: user_captura
--

SELECT pg_catalog.setval('public.programaticstructure_id_seq', 1, false);


--
-- Name: publisher_id_seq; Type: SEQUENCE SET; Schema: public; Owner: user_captura
--

SELECT pg_catalog.setval('public.publisher_id_seq', 1, false);


--
-- Name: quotes_id_seq; Type: SEQUENCE SET; Schema: public; Owner: user_captura
--

SELECT pg_catalog.setval('public.quotes_id_seq', 1, false);


--
-- Name: quotesitems_id_seq; Type: SEQUENCE SET; Schema: public; Owner: user_captura
--

SELECT pg_catalog.setval('public.quotesitems_id_seq', 1, false);


--
-- Name: relatedprocedure_id_seq; Type: SEQUENCE SET; Schema: public; Owner: user_captura
--

SELECT pg_catalog.setval('public.relatedprocedure_id_seq', 1, false);


--
-- Name: requestforquotes_id_seq; Type: SEQUENCE SET; Schema: public; Owner: user_captura
--

SELECT pg_catalog.setval('public.requestforquotes_id_seq', 1, false);


--
-- Name: requestforquotesinvitedsuppliers_id_seq; Type: SEQUENCE SET; Schema: public; Owner: user_captura
--

SELECT pg_catalog.setval('public.requestforquotesinvitedsuppliers_id_seq', 1, false);


--
-- Name: requestforquotesitems_id_seq; Type: SEQUENCE SET; Schema: public; Owner: user_captura
--

SELECT pg_catalog.setval('public.requestforquotesitems_id_seq', 1, false);


--
-- Name: rolecatalog_id_seq; Type: SEQUENCE SET; Schema: public; Owner: user_captura
--

SELECT pg_catalog.setval('public.rolecatalog_id_seq', 1, false);


--
-- Name: roles_id_seq; Type: SEQUENCE SET; Schema: public; Owner: user_captura
--

SELECT pg_catalog.setval('public.roles_id_seq', 1, false);


--
-- Name: tags_id_seq; Type: SEQUENCE SET; Schema: public; Owner: user_captura
--

SELECT pg_catalog.setval('public.tags_id_seq', 1, false);


--
-- Name: tender_id_seq; Type: SEQUENCE SET; Schema: public; Owner: user_captura
--

SELECT pg_catalog.setval('public.tender_id_seq', 1, false);


--
-- Name: tenderamendmentchanges_id_seq; Type: SEQUENCE SET; Schema: public; Owner: user_captura
--

SELECT pg_catalog.setval('public.tenderamendmentchanges_id_seq', 1, false);


--
-- Name: tenderdocuments_id_seq; Type: SEQUENCE SET; Schema: public; Owner: user_captura
--

SELECT pg_catalog.setval('public.tenderdocuments_id_seq', 1, false);


--
-- Name: tenderitem_id_seq; Type: SEQUENCE SET; Schema: public; Owner: user_captura
--

SELECT pg_catalog.setval('public.tenderitem_id_seq', 1, false);


--
-- Name: tenderitemadditionalclassifications_id_seq; Type: SEQUENCE SET; Schema: public; Owner: user_captura
--

SELECT pg_catalog.setval('public.tenderitemadditionalclassifications_id_seq', 1, false);


--
-- Name: tendermilestone_id_seq; Type: SEQUENCE SET; Schema: public; Owner: user_captura
--

SELECT pg_catalog.setval('public.tendermilestone_id_seq', 1, false);


--
-- Name: tendermilestonedocuments_id_seq; Type: SEQUENCE SET; Schema: public; Owner: user_captura
--

SELECT pg_catalog.setval('public.tendermilestonedocuments_id_seq', 1, false);


--
-- Name: user_contractingprocess_id_seq; Type: SEQUENCE SET; Schema: public; Owner: user_captura
--

SELECT pg_catalog.setval('public.user_contractingprocess_id_seq', 1, false);


--
-- Name: additionalcontactpoints additionalcontactpoints_pkey; Type: CONSTRAINT; Schema: dashboard; Owner: user_dashboard
--

ALTER TABLE ONLY dashboard.additionalcontactpoints
    ADD CONSTRAINT additionalcontactpoints_pkey PRIMARY KEY (id);


--
-- Name: award award_pkey; Type: CONSTRAINT; Schema: dashboard; Owner: user_dashboard
--

ALTER TABLE ONLY dashboard.award
    ADD CONSTRAINT award_pkey PRIMARY KEY (id);


--
-- Name: awardamendmentchanges awardamendmentchanges_pkey; Type: CONSTRAINT; Schema: dashboard; Owner: user_dashboard
--

ALTER TABLE ONLY dashboard.awardamendmentchanges
    ADD CONSTRAINT awardamendmentchanges_pkey PRIMARY KEY (id);


--
-- Name: awarddocuments awarddocuments_pkey; Type: CONSTRAINT; Schema: dashboard; Owner: user_dashboard
--

ALTER TABLE ONLY dashboard.awarddocuments
    ADD CONSTRAINT awarddocuments_pkey PRIMARY KEY (id);


--
-- Name: awarditem awarditem_pkey; Type: CONSTRAINT; Schema: dashboard; Owner: user_dashboard
--

ALTER TABLE ONLY dashboard.awarditem
    ADD CONSTRAINT awarditem_pkey PRIMARY KEY (id);


--
-- Name: awarditemadditionalclassifications awarditemadditionalclassifications_pkey; Type: CONSTRAINT; Schema: dashboard; Owner: user_dashboard
--

ALTER TABLE ONLY dashboard.awarditemadditionalclassifications
    ADD CONSTRAINT awarditemadditionalclassifications_pkey PRIMARY KEY (id);


--
-- Name: awardsupplier awardsupplier_pkey; Type: CONSTRAINT; Schema: dashboard; Owner: user_dashboard
--

ALTER TABLE ONLY dashboard.awardsupplier
    ADD CONSTRAINT awardsupplier_pkey PRIMARY KEY (id);


--
-- Name: budget budget_pkey; Type: CONSTRAINT; Schema: dashboard; Owner: user_dashboard
--

ALTER TABLE ONLY dashboard.budget
    ADD CONSTRAINT budget_pkey PRIMARY KEY (id);


--
-- Name: budgetbreakdown budgetbreakdown_pkey; Type: CONSTRAINT; Schema: dashboard; Owner: user_dashboard
--

ALTER TABLE ONLY dashboard.budgetbreakdown
    ADD CONSTRAINT budgetbreakdown_pkey PRIMARY KEY (id);


--
-- Name: budgetclassifications budgetclassifications_pkey; Type: CONSTRAINT; Schema: dashboard; Owner: user_dashboard
--

ALTER TABLE ONLY dashboard.budgetclassifications
    ADD CONSTRAINT budgetclassifications_pkey PRIMARY KEY (id);


--
-- Name: clarificationmeeting clarificationmeeting_pkey; Type: CONSTRAINT; Schema: dashboard; Owner: user_dashboard
--

ALTER TABLE ONLY dashboard.clarificationmeeting
    ADD CONSTRAINT clarificationmeeting_pkey PRIMARY KEY (id);


--
-- Name: clarificationmeetingactor clarificationmeetingactor_pkey; Type: CONSTRAINT; Schema: dashboard; Owner: user_dashboard
--

ALTER TABLE ONLY dashboard.clarificationmeetingactor
    ADD CONSTRAINT clarificationmeetingactor_pkey PRIMARY KEY (id);


--
-- Name: contract contract_pkey; Type: CONSTRAINT; Schema: dashboard; Owner: user_dashboard
--

ALTER TABLE ONLY dashboard.contract
    ADD CONSTRAINT contract_pkey PRIMARY KEY (id);


--
-- Name: contractamendmentchanges contractamendmentchanges_pkey; Type: CONSTRAINT; Schema: dashboard; Owner: user_dashboard
--

ALTER TABLE ONLY dashboard.contractamendmentchanges
    ADD CONSTRAINT contractamendmentchanges_pkey PRIMARY KEY (id);


--
-- Name: contractdocuments contractdocuments_pkey; Type: CONSTRAINT; Schema: dashboard; Owner: user_dashboard
--

ALTER TABLE ONLY dashboard.contractdocuments
    ADD CONSTRAINT contractdocuments_pkey PRIMARY KEY (id);


--
-- Name: contractingprocess contractingprocess_pkey; Type: CONSTRAINT; Schema: dashboard; Owner: user_dashboard
--

ALTER TABLE ONLY dashboard.contractingprocess
    ADD CONSTRAINT contractingprocess_pkey PRIMARY KEY (id);


--
-- Name: contractitem contractitem_pkey; Type: CONSTRAINT; Schema: dashboard; Owner: user_dashboard
--

ALTER TABLE ONLY dashboard.contractitem
    ADD CONSTRAINT contractitem_pkey PRIMARY KEY (id);


--
-- Name: contractitemadditionalclasifications contractitemadditionalclasifications_pkey; Type: CONSTRAINT; Schema: dashboard; Owner: user_dashboard
--

ALTER TABLE ONLY dashboard.contractitemadditionalclasifications
    ADD CONSTRAINT contractitemadditionalclasifications_pkey PRIMARY KEY (id);


--
-- Name: currency currency_pkey; Type: CONSTRAINT; Schema: dashboard; Owner: user_dashboard
--

ALTER TABLE ONLY dashboard.currency
    ADD CONSTRAINT currency_pkey PRIMARY KEY (id);


--
-- Name: documentformat documentformat_pkey; Type: CONSTRAINT; Schema: dashboard; Owner: user_dashboard
--

ALTER TABLE ONLY dashboard.documentformat
    ADD CONSTRAINT documentformat_pkey PRIMARY KEY (id);


--
-- Name: documentmanagement documentmanagement_pkey; Type: CONSTRAINT; Schema: dashboard; Owner: user_dashboard
--

ALTER TABLE ONLY dashboard.documentmanagement
    ADD CONSTRAINT documentmanagement_pkey PRIMARY KEY (id);


--
-- Name: documenttype documenttype_code_key; Type: CONSTRAINT; Schema: dashboard; Owner: user_dashboard
--

ALTER TABLE ONLY dashboard.documenttype
    ADD CONSTRAINT documenttype_code_key UNIQUE (code);


--
-- Name: documenttype documenttype_pkey; Type: CONSTRAINT; Schema: dashboard; Owner: user_dashboard
--

ALTER TABLE ONLY dashboard.documenttype
    ADD CONSTRAINT documenttype_pkey PRIMARY KEY (id);


--
-- Name: gdmx_dictionary gdmx_dictionary_pkey; Type: CONSTRAINT; Schema: dashboard; Owner: user_dashboard
--

ALTER TABLE ONLY dashboard.gdmx_dictionary
    ADD CONSTRAINT gdmx_dictionary_pkey PRIMARY KEY (id);


--
-- Name: gdmx_document gdmx_document_pkey; Type: CONSTRAINT; Schema: dashboard; Owner: user_dashboard
--

ALTER TABLE ONLY dashboard.gdmx_document
    ADD CONSTRAINT gdmx_document_pkey PRIMARY KEY (id);


--
-- Name: guarantees guarantees_pkey; Type: CONSTRAINT; Schema: dashboard; Owner: user_dashboard
--

ALTER TABLE ONLY dashboard.guarantees
    ADD CONSTRAINT guarantees_pkey PRIMARY KEY (id);


--
-- Name: implementation implementation_pkey; Type: CONSTRAINT; Schema: dashboard; Owner: user_dashboard
--

ALTER TABLE ONLY dashboard.implementation
    ADD CONSTRAINT implementation_pkey PRIMARY KEY (id);


--
-- Name: implementationdocuments implementationdocuments_pkey; Type: CONSTRAINT; Schema: dashboard; Owner: user_dashboard
--

ALTER TABLE ONLY dashboard.implementationdocuments
    ADD CONSTRAINT implementationdocuments_pkey PRIMARY KEY (id);


--
-- Name: implementationmilestone implementationmilestone_pkey; Type: CONSTRAINT; Schema: dashboard; Owner: user_dashboard
--

ALTER TABLE ONLY dashboard.implementationmilestone
    ADD CONSTRAINT implementationmilestone_pkey PRIMARY KEY (id);


--
-- Name: implementationmilestonedocuments implementationmilestonedocuments_pkey; Type: CONSTRAINT; Schema: dashboard; Owner: user_dashboard
--

ALTER TABLE ONLY dashboard.implementationmilestonedocuments
    ADD CONSTRAINT implementationmilestonedocuments_pkey PRIMARY KEY (id);


--
-- Name: implementationstatus implementationstatus_pkey; Type: CONSTRAINT; Schema: dashboard; Owner: user_dashboard
--

ALTER TABLE ONLY dashboard.implementationstatus
    ADD CONSTRAINT implementationstatus_pkey PRIMARY KEY (id);


--
-- Name: implementationtransactions implementationtransactions_pkey; Type: CONSTRAINT; Schema: dashboard; Owner: user_dashboard
--

ALTER TABLE ONLY dashboard.implementationtransactions
    ADD CONSTRAINT implementationtransactions_pkey PRIMARY KEY (id);


--
-- Name: item item_pkey; Type: CONSTRAINT; Schema: dashboard; Owner: user_dashboard
--

ALTER TABLE ONLY dashboard.item
    ADD CONSTRAINT item_pkey PRIMARY KEY (id);


--
-- Name: language language_pkey; Type: CONSTRAINT; Schema: dashboard; Owner: user_dashboard
--

ALTER TABLE ONLY dashboard.language
    ADD CONSTRAINT language_pkey PRIMARY KEY (id);


--
-- Name: links links_pkey; Type: CONSTRAINT; Schema: dashboard; Owner: user_dashboard
--

ALTER TABLE ONLY dashboard.links
    ADD CONSTRAINT links_pkey PRIMARY KEY (id);


--
-- Name: log_gdmx log_gdmx_pkey; Type: CONSTRAINT; Schema: dashboard; Owner: user_dashboard
--

ALTER TABLE ONLY dashboard.log_gdmx
    ADD CONSTRAINT log_gdmx_pkey PRIMARY KEY (id);


--
-- Name: logs logs_pkey; Type: CONSTRAINT; Schema: dashboard; Owner: user_dashboard
--

ALTER TABLE ONLY dashboard.logs
    ADD CONSTRAINT logs_pkey PRIMARY KEY (id);


--
-- Name: memberof memberof_pkey; Type: CONSTRAINT; Schema: dashboard; Owner: user_dashboard
--

ALTER TABLE ONLY dashboard.memberof
    ADD CONSTRAINT memberof_pkey PRIMARY KEY (id);


--
-- Name: metadata metadata_pkey; Type: CONSTRAINT; Schema: dashboard; Owner: user_dashboard
--

ALTER TABLE ONLY dashboard.metadata
    ADD CONSTRAINT metadata_pkey PRIMARY KEY (field_name);


--
-- Name: milestonetype milestonetype_pkey; Type: CONSTRAINT; Schema: dashboard; Owner: user_dashboard
--

ALTER TABLE ONLY dashboard.milestonetype
    ADD CONSTRAINT milestonetype_pkey PRIMARY KEY (id);


--
-- Name: parties parties_pkey; Type: CONSTRAINT; Schema: dashboard; Owner: user_dashboard
--

ALTER TABLE ONLY dashboard.parties
    ADD CONSTRAINT parties_pkey PRIMARY KEY (id);


--
-- Name: partiesadditionalidentifiers partiesadditionalidentifiers_pkey; Type: CONSTRAINT; Schema: dashboard; Owner: user_dashboard
--

ALTER TABLE ONLY dashboard.partiesadditionalidentifiers
    ADD CONSTRAINT partiesadditionalidentifiers_pkey PRIMARY KEY (id);


--
-- Name: paymentmethod paymentmethod_pkey; Type: CONSTRAINT; Schema: dashboard; Owner: user_dashboard
--

ALTER TABLE ONLY dashboard.paymentmethod
    ADD CONSTRAINT paymentmethod_pkey PRIMARY KEY (id);


--
-- Name: planning planning_pkey; Type: CONSTRAINT; Schema: dashboard; Owner: user_dashboard
--

ALTER TABLE ONLY dashboard.planning
    ADD CONSTRAINT planning_pkey PRIMARY KEY (id);


--
-- Name: planningdocuments planningdocuments_pkey; Type: CONSTRAINT; Schema: dashboard; Owner: user_dashboard
--

ALTER TABLE ONLY dashboard.planningdocuments
    ADD CONSTRAINT planningdocuments_pkey PRIMARY KEY (id);


--
-- Name: pntreference pntreference_pkey; Type: CONSTRAINT; Schema: dashboard; Owner: user_dashboard
--

ALTER TABLE ONLY dashboard.pntreference
    ADD CONSTRAINT pntreference_pkey PRIMARY KEY (id);


--
-- Name: prefixocid prefixocid_pkey; Type: CONSTRAINT; Schema: dashboard; Owner: user_dashboard
--

ALTER TABLE ONLY dashboard.prefixocid
    ADD CONSTRAINT prefixocid_pkey PRIMARY KEY (id);


--
-- Name: programaticstructure programaticstructure_pkey; Type: CONSTRAINT; Schema: dashboard; Owner: user_dashboard
--

ALTER TABLE ONLY dashboard.programaticstructure
    ADD CONSTRAINT programaticstructure_pkey PRIMARY KEY (id);


--
-- Name: publisher publisher_pkey; Type: CONSTRAINT; Schema: dashboard; Owner: user_dashboard
--

ALTER TABLE ONLY dashboard.publisher
    ADD CONSTRAINT publisher_pkey PRIMARY KEY (id);


--
-- Name: quotes quotes_pkey; Type: CONSTRAINT; Schema: dashboard; Owner: user_dashboard
--

ALTER TABLE ONLY dashboard.quotes
    ADD CONSTRAINT quotes_pkey PRIMARY KEY (id);


--
-- Name: quotesitems quotesitems_pkey; Type: CONSTRAINT; Schema: dashboard; Owner: user_dashboard
--

ALTER TABLE ONLY dashboard.quotesitems
    ADD CONSTRAINT quotesitems_pkey PRIMARY KEY (id);


--
-- Name: relatedprocedure relatedprocedure_pkey; Type: CONSTRAINT; Schema: dashboard; Owner: user_dashboard
--

ALTER TABLE ONLY dashboard.relatedprocedure
    ADD CONSTRAINT relatedprocedure_pkey PRIMARY KEY (id);


--
-- Name: requestforquotes requestforquotes_pkey; Type: CONSTRAINT; Schema: dashboard; Owner: user_dashboard
--

ALTER TABLE ONLY dashboard.requestforquotes
    ADD CONSTRAINT requestforquotes_pkey PRIMARY KEY (id);


--
-- Name: requestforquotesinvitedsuppliers requestforquotesinvitedsuppliers_pkey; Type: CONSTRAINT; Schema: dashboard; Owner: user_dashboard
--

ALTER TABLE ONLY dashboard.requestforquotesinvitedsuppliers
    ADD CONSTRAINT requestforquotesinvitedsuppliers_pkey PRIMARY KEY (id);


--
-- Name: requestforquotesitems requestforquotesitems_pkey; Type: CONSTRAINT; Schema: dashboard; Owner: user_dashboard
--

ALTER TABLE ONLY dashboard.requestforquotesitems
    ADD CONSTRAINT requestforquotesitems_pkey PRIMARY KEY (id);


--
-- Name: rolecatalog rolecatalog_pkey; Type: CONSTRAINT; Schema: dashboard; Owner: user_dashboard
--

ALTER TABLE ONLY dashboard.rolecatalog
    ADD CONSTRAINT rolecatalog_pkey PRIMARY KEY (id);


--
-- Name: roles roles_pkey; Type: CONSTRAINT; Schema: dashboard; Owner: user_dashboard
--

ALTER TABLE ONLY dashboard.roles
    ADD CONSTRAINT roles_pkey PRIMARY KEY (id);


--
-- Name: tags tags_pkey; Type: CONSTRAINT; Schema: dashboard; Owner: user_dashboard
--

ALTER TABLE ONLY dashboard.tags
    ADD CONSTRAINT tags_pkey PRIMARY KEY (id);


--
-- Name: tender tender_pkey; Type: CONSTRAINT; Schema: dashboard; Owner: user_dashboard
--

ALTER TABLE ONLY dashboard.tender
    ADD CONSTRAINT tender_pkey PRIMARY KEY (id);


--
-- Name: tenderamendmentchanges tenderamendmentchanges_pkey; Type: CONSTRAINT; Schema: dashboard; Owner: user_dashboard
--

ALTER TABLE ONLY dashboard.tenderamendmentchanges
    ADD CONSTRAINT tenderamendmentchanges_pkey PRIMARY KEY (id);


--
-- Name: tenderdocuments tenderdocuments_pkey; Type: CONSTRAINT; Schema: dashboard; Owner: user_dashboard
--

ALTER TABLE ONLY dashboard.tenderdocuments
    ADD CONSTRAINT tenderdocuments_pkey PRIMARY KEY (id);


--
-- Name: tenderitem tenderitem_pkey; Type: CONSTRAINT; Schema: dashboard; Owner: user_dashboard
--

ALTER TABLE ONLY dashboard.tenderitem
    ADD CONSTRAINT tenderitem_pkey PRIMARY KEY (id);


--
-- Name: tenderitemadditionalclassifications tenderitemadditionalclassifications_pkey; Type: CONSTRAINT; Schema: dashboard; Owner: user_dashboard
--

ALTER TABLE ONLY dashboard.tenderitemadditionalclassifications
    ADD CONSTRAINT tenderitemadditionalclassifications_pkey PRIMARY KEY (id);


--
-- Name: tendermilestone tendermilestone_pkey; Type: CONSTRAINT; Schema: dashboard; Owner: user_dashboard
--

ALTER TABLE ONLY dashboard.tendermilestone
    ADD CONSTRAINT tendermilestone_pkey PRIMARY KEY (id);


--
-- Name: tendermilestonedocuments tendermilestonedocuments_pkey; Type: CONSTRAINT; Schema: dashboard; Owner: user_dashboard
--

ALTER TABLE ONLY dashboard.tendermilestonedocuments
    ADD CONSTRAINT tendermilestonedocuments_pkey PRIMARY KEY (id);


--
-- Name: user_contractingprocess user_contractingprocess_pkey; Type: CONSTRAINT; Schema: dashboard; Owner: user_dashboard
--

ALTER TABLE ONLY dashboard.user_contractingprocess
    ADD CONSTRAINT user_contractingprocess_pkey PRIMARY KEY (id);


--
-- Name: additionalcontactpoints additionalcontactpoints_pkey; Type: CONSTRAINT; Schema: public; Owner: user_captura
--

ALTER TABLE ONLY public.additionalcontactpoints
    ADD CONSTRAINT additionalcontactpoints_pkey PRIMARY KEY (id);


--
-- Name: award award_pkey; Type: CONSTRAINT; Schema: public; Owner: user_captura
--

ALTER TABLE ONLY public.award
    ADD CONSTRAINT award_pkey PRIMARY KEY (id);


--
-- Name: awardamendmentchanges awardamendmentchanges_pkey; Type: CONSTRAINT; Schema: public; Owner: user_captura
--

ALTER TABLE ONLY public.awardamendmentchanges
    ADD CONSTRAINT awardamendmentchanges_pkey PRIMARY KEY (id);


--
-- Name: awarddocuments awarddocuments_pkey; Type: CONSTRAINT; Schema: public; Owner: user_captura
--

ALTER TABLE ONLY public.awarddocuments
    ADD CONSTRAINT awarddocuments_pkey PRIMARY KEY (id);


--
-- Name: awarditem awarditem_pkey; Type: CONSTRAINT; Schema: public; Owner: user_captura
--

ALTER TABLE ONLY public.awarditem
    ADD CONSTRAINT awarditem_pkey PRIMARY KEY (id);


--
-- Name: awarditemadditionalclassifications awarditemadditionalclassifications_pkey; Type: CONSTRAINT; Schema: public; Owner: user_captura
--

ALTER TABLE ONLY public.awarditemadditionalclassifications
    ADD CONSTRAINT awarditemadditionalclassifications_pkey PRIMARY KEY (id);


--
-- Name: awardsupplier awardsupplier_pkey; Type: CONSTRAINT; Schema: public; Owner: user_captura
--

ALTER TABLE ONLY public.awardsupplier
    ADD CONSTRAINT awardsupplier_pkey PRIMARY KEY (id);


--
-- Name: budget budget_pkey; Type: CONSTRAINT; Schema: public; Owner: user_captura
--

ALTER TABLE ONLY public.budget
    ADD CONSTRAINT budget_pkey PRIMARY KEY (id);


--
-- Name: budgetbreakdown budgetbreakdown_pkey; Type: CONSTRAINT; Schema: public; Owner: user_captura
--

ALTER TABLE ONLY public.budgetbreakdown
    ADD CONSTRAINT budgetbreakdown_pkey PRIMARY KEY (id);


--
-- Name: budgetclassifications budgetclassifications_pkey; Type: CONSTRAINT; Schema: public; Owner: user_captura
--

ALTER TABLE ONLY public.budgetclassifications
    ADD CONSTRAINT budgetclassifications_pkey PRIMARY KEY (id);


--
-- Name: clarificationmeeting clarificationmeeting_pkey; Type: CONSTRAINT; Schema: public; Owner: user_captura
--

ALTER TABLE ONLY public.clarificationmeeting
    ADD CONSTRAINT clarificationmeeting_pkey PRIMARY KEY (id);


--
-- Name: clarificationmeetingactor clarificationmeetingactor_pkey; Type: CONSTRAINT; Schema: public; Owner: user_captura
--

ALTER TABLE ONLY public.clarificationmeetingactor
    ADD CONSTRAINT clarificationmeetingactor_pkey PRIMARY KEY (id);


--
-- Name: contract contract_pkey; Type: CONSTRAINT; Schema: public; Owner: user_captura
--

ALTER TABLE ONLY public.contract
    ADD CONSTRAINT contract_pkey PRIMARY KEY (id);


--
-- Name: contractamendmentchanges contractamendmentchanges_pkey; Type: CONSTRAINT; Schema: public; Owner: user_captura
--

ALTER TABLE ONLY public.contractamendmentchanges
    ADD CONSTRAINT contractamendmentchanges_pkey PRIMARY KEY (id);


--
-- Name: contractdocuments contractdocuments_pkey; Type: CONSTRAINT; Schema: public; Owner: user_captura
--

ALTER TABLE ONLY public.contractdocuments
    ADD CONSTRAINT contractdocuments_pkey PRIMARY KEY (id);


--
-- Name: contractingprocess contractingprocess_pkey; Type: CONSTRAINT; Schema: public; Owner: user_captura
--

ALTER TABLE ONLY public.contractingprocess
    ADD CONSTRAINT contractingprocess_pkey PRIMARY KEY (id);


--
-- Name: contractitem contractitem_pkey; Type: CONSTRAINT; Schema: public; Owner: user_captura
--

ALTER TABLE ONLY public.contractitem
    ADD CONSTRAINT contractitem_pkey PRIMARY KEY (id);


--
-- Name: contractitemadditionalclasifications contractitemadditionalclasifications_pkey; Type: CONSTRAINT; Schema: public; Owner: user_captura
--

ALTER TABLE ONLY public.contractitemadditionalclasifications
    ADD CONSTRAINT contractitemadditionalclasifications_pkey PRIMARY KEY (id);


--
-- Name: currency currency_pkey; Type: CONSTRAINT; Schema: public; Owner: user_captura
--

ALTER TABLE ONLY public.currency
    ADD CONSTRAINT currency_pkey PRIMARY KEY (id);


--
-- Name: documentformat documentformat_pkey; Type: CONSTRAINT; Schema: public; Owner: user_captura
--

ALTER TABLE ONLY public.documentformat
    ADD CONSTRAINT documentformat_pkey PRIMARY KEY (id);


--
-- Name: documentmanagement documentmanagement_pkey; Type: CONSTRAINT; Schema: public; Owner: user_captura
--

ALTER TABLE ONLY public.documentmanagement
    ADD CONSTRAINT documentmanagement_pkey PRIMARY KEY (id);


--
-- Name: documenttype documenttype_code_key; Type: CONSTRAINT; Schema: public; Owner: user_captura
--

ALTER TABLE ONLY public.documenttype
    ADD CONSTRAINT documenttype_code_key UNIQUE (code);


--
-- Name: documenttype documenttype_code_key1; Type: CONSTRAINT; Schema: public; Owner: user_captura
--

ALTER TABLE ONLY public.documenttype
    ADD CONSTRAINT documenttype_code_key1 UNIQUE (code);


--
-- Name: documenttype documenttype_code_key2; Type: CONSTRAINT; Schema: public; Owner: user_captura
--

ALTER TABLE ONLY public.documenttype
    ADD CONSTRAINT documenttype_code_key2 UNIQUE (code);


--
-- Name: documenttype documenttype_code_key3; Type: CONSTRAINT; Schema: public; Owner: user_captura
--

ALTER TABLE ONLY public.documenttype
    ADD CONSTRAINT documenttype_code_key3 UNIQUE (code);


--
-- Name: documenttype documenttype_pkey; Type: CONSTRAINT; Schema: public; Owner: user_captura
--

ALTER TABLE ONLY public.documenttype
    ADD CONSTRAINT documenttype_pkey PRIMARY KEY (id);


--
-- Name: gdmx_dictionary gdmx_dictionary_pkey; Type: CONSTRAINT; Schema: public; Owner: user_captura
--

ALTER TABLE ONLY public.gdmx_dictionary
    ADD CONSTRAINT gdmx_dictionary_pkey PRIMARY KEY (id);


--
-- Name: gdmx_document gdmx_document_pkey; Type: CONSTRAINT; Schema: public; Owner: user_captura
--

ALTER TABLE ONLY public.gdmx_document
    ADD CONSTRAINT gdmx_document_pkey PRIMARY KEY (id);


--
-- Name: guarantees guarantees_pkey; Type: CONSTRAINT; Schema: public; Owner: user_captura
--

ALTER TABLE ONLY public.guarantees
    ADD CONSTRAINT guarantees_pkey PRIMARY KEY (id);


--
-- Name: implementation implementation_pkey; Type: CONSTRAINT; Schema: public; Owner: user_captura
--

ALTER TABLE ONLY public.implementation
    ADD CONSTRAINT implementation_pkey PRIMARY KEY (id);


--
-- Name: implementationdocuments implementationdocuments_pkey; Type: CONSTRAINT; Schema: public; Owner: user_captura
--

ALTER TABLE ONLY public.implementationdocuments
    ADD CONSTRAINT implementationdocuments_pkey PRIMARY KEY (id);


--
-- Name: implementationmilestone implementationmilestone_pkey; Type: CONSTRAINT; Schema: public; Owner: user_captura
--

ALTER TABLE ONLY public.implementationmilestone
    ADD CONSTRAINT implementationmilestone_pkey PRIMARY KEY (id);


--
-- Name: implementationmilestonedocuments implementationmilestonedocuments_pkey; Type: CONSTRAINT; Schema: public; Owner: user_captura
--

ALTER TABLE ONLY public.implementationmilestonedocuments
    ADD CONSTRAINT implementationmilestonedocuments_pkey PRIMARY KEY (id);


--
-- Name: implementationstatus implementationstatus_pkey; Type: CONSTRAINT; Schema: public; Owner: user_captura
--

ALTER TABLE ONLY public.implementationstatus
    ADD CONSTRAINT implementationstatus_pkey PRIMARY KEY (id);


--
-- Name: implementationtransactions implementationtransactions_pkey; Type: CONSTRAINT; Schema: public; Owner: user_captura
--

ALTER TABLE ONLY public.implementationtransactions
    ADD CONSTRAINT implementationtransactions_pkey PRIMARY KEY (id);


--
-- Name: item item_pkey; Type: CONSTRAINT; Schema: public; Owner: user_captura
--

ALTER TABLE ONLY public.item
    ADD CONSTRAINT item_pkey PRIMARY KEY (id);


--
-- Name: language language_pkey; Type: CONSTRAINT; Schema: public; Owner: user_captura
--

ALTER TABLE ONLY public.language
    ADD CONSTRAINT language_pkey PRIMARY KEY (id);


--
-- Name: links links_pkey; Type: CONSTRAINT; Schema: public; Owner: user_captura
--

ALTER TABLE ONLY public.links
    ADD CONSTRAINT links_pkey PRIMARY KEY (id);


--
-- Name: log_gdmx log_gdmx_pkey; Type: CONSTRAINT; Schema: public; Owner: user_captura
--

ALTER TABLE ONLY public.log_gdmx
    ADD CONSTRAINT log_gdmx_pkey PRIMARY KEY (id);


--
-- Name: logs logs_pkey; Type: CONSTRAINT; Schema: public; Owner: user_captura
--

ALTER TABLE ONLY public.logs
    ADD CONSTRAINT logs_pkey PRIMARY KEY (id);


--
-- Name: memberof memberof_pkey; Type: CONSTRAINT; Schema: public; Owner: user_captura
--

ALTER TABLE ONLY public.memberof
    ADD CONSTRAINT memberof_pkey PRIMARY KEY (id);


--
-- Name: milestonetype milestonetype_pkey; Type: CONSTRAINT; Schema: public; Owner: user_captura
--

ALTER TABLE ONLY public.milestonetype
    ADD CONSTRAINT milestonetype_pkey PRIMARY KEY (id);


--
-- Name: parties parties_pkey; Type: CONSTRAINT; Schema: public; Owner: user_captura
--

ALTER TABLE ONLY public.parties
    ADD CONSTRAINT parties_pkey PRIMARY KEY (id);


--
-- Name: partiesadditionalidentifiers partiesadditionalidentifiers_pkey; Type: CONSTRAINT; Schema: public; Owner: user_captura
--

ALTER TABLE ONLY public.partiesadditionalidentifiers
    ADD CONSTRAINT partiesadditionalidentifiers_pkey PRIMARY KEY (id);


--
-- Name: paymentmethod paymentmethod_pkey; Type: CONSTRAINT; Schema: public; Owner: user_captura
--

ALTER TABLE ONLY public.paymentmethod
    ADD CONSTRAINT paymentmethod_pkey PRIMARY KEY (id);


--
-- Name: metadata pk_metadata_id; Type: CONSTRAINT; Schema: public; Owner: user_captura
--

ALTER TABLE ONLY public.metadata
    ADD CONSTRAINT pk_metadata_id PRIMARY KEY (field_name);


--
-- Name: planning planning_pkey; Type: CONSTRAINT; Schema: public; Owner: user_captura
--

ALTER TABLE ONLY public.planning
    ADD CONSTRAINT planning_pkey PRIMARY KEY (id);


--
-- Name: planningdocuments planningdocuments_pkey; Type: CONSTRAINT; Schema: public; Owner: user_captura
--

ALTER TABLE ONLY public.planningdocuments
    ADD CONSTRAINT planningdocuments_pkey PRIMARY KEY (id);


--
-- Name: pntreference pntreference_pkey; Type: CONSTRAINT; Schema: public; Owner: user_captura
--

ALTER TABLE ONLY public.pntreference
    ADD CONSTRAINT pntreference_pkey PRIMARY KEY (id);


--
-- Name: prefixocid prefixocid_pkey; Type: CONSTRAINT; Schema: public; Owner: user_captura
--

ALTER TABLE ONLY public.prefixocid
    ADD CONSTRAINT prefixocid_pkey PRIMARY KEY (id);


--
-- Name: programaticstructure programaticstructure_pkey; Type: CONSTRAINT; Schema: public; Owner: user_captura
--

ALTER TABLE ONLY public.programaticstructure
    ADD CONSTRAINT programaticstructure_pkey PRIMARY KEY (id);


--
-- Name: publisher publisher_pkey; Type: CONSTRAINT; Schema: public; Owner: user_captura
--

ALTER TABLE ONLY public.publisher
    ADD CONSTRAINT publisher_pkey PRIMARY KEY (id);


--
-- Name: quotes quotes_pkey; Type: CONSTRAINT; Schema: public; Owner: user_captura
--

ALTER TABLE ONLY public.quotes
    ADD CONSTRAINT quotes_pkey PRIMARY KEY (id);


--
-- Name: quotesitems quotesitems_pkey; Type: CONSTRAINT; Schema: public; Owner: user_captura
--

ALTER TABLE ONLY public.quotesitems
    ADD CONSTRAINT quotesitems_pkey PRIMARY KEY (id);


--
-- Name: relatedprocedure relatedprocedure_pkey; Type: CONSTRAINT; Schema: public; Owner: user_captura
--

ALTER TABLE ONLY public.relatedprocedure
    ADD CONSTRAINT relatedprocedure_pkey PRIMARY KEY (id);


--
-- Name: requestforquotes requestforquotes_pkey; Type: CONSTRAINT; Schema: public; Owner: user_captura
--

ALTER TABLE ONLY public.requestforquotes
    ADD CONSTRAINT requestforquotes_pkey PRIMARY KEY (id);


--
-- Name: requestforquotesinvitedsuppliers requestforquotesinvitedsuppliers_pkey; Type: CONSTRAINT; Schema: public; Owner: user_captura
--

ALTER TABLE ONLY public.requestforquotesinvitedsuppliers
    ADD CONSTRAINT requestforquotesinvitedsuppliers_pkey PRIMARY KEY (id);


--
-- Name: requestforquotesitems requestforquotesitems_pkey; Type: CONSTRAINT; Schema: public; Owner: user_captura
--

ALTER TABLE ONLY public.requestforquotesitems
    ADD CONSTRAINT requestforquotesitems_pkey PRIMARY KEY (id);


--
-- Name: rolecatalog rolecatalog_pkey; Type: CONSTRAINT; Schema: public; Owner: user_captura
--

ALTER TABLE ONLY public.rolecatalog
    ADD CONSTRAINT rolecatalog_pkey PRIMARY KEY (id);


--
-- Name: roles roles_pkey; Type: CONSTRAINT; Schema: public; Owner: user_captura
--

ALTER TABLE ONLY public.roles
    ADD CONSTRAINT roles_pkey PRIMARY KEY (id);


--
-- Name: tags tags_pkey; Type: CONSTRAINT; Schema: public; Owner: user_captura
--

ALTER TABLE ONLY public.tags
    ADD CONSTRAINT tags_pkey PRIMARY KEY (id);


--
-- Name: tender tender_pkey; Type: CONSTRAINT; Schema: public; Owner: user_captura
--

ALTER TABLE ONLY public.tender
    ADD CONSTRAINT tender_pkey PRIMARY KEY (id);


--
-- Name: tenderamendmentchanges tenderamendmentchanges_pkey; Type: CONSTRAINT; Schema: public; Owner: user_captura
--

ALTER TABLE ONLY public.tenderamendmentchanges
    ADD CONSTRAINT tenderamendmentchanges_pkey PRIMARY KEY (id);


--
-- Name: tenderdocuments tenderdocuments_pkey; Type: CONSTRAINT; Schema: public; Owner: user_captura
--

ALTER TABLE ONLY public.tenderdocuments
    ADD CONSTRAINT tenderdocuments_pkey PRIMARY KEY (id);


--
-- Name: tenderitem tenderitem_pkey; Type: CONSTRAINT; Schema: public; Owner: user_captura
--

ALTER TABLE ONLY public.tenderitem
    ADD CONSTRAINT tenderitem_pkey PRIMARY KEY (id);


--
-- Name: tenderitemadditionalclassifications tenderitemadditionalclassifications_pkey; Type: CONSTRAINT; Schema: public; Owner: user_captura
--

ALTER TABLE ONLY public.tenderitemadditionalclassifications
    ADD CONSTRAINT tenderitemadditionalclassifications_pkey PRIMARY KEY (id);


--
-- Name: tendermilestone tendermilestone_pkey; Type: CONSTRAINT; Schema: public; Owner: user_captura
--

ALTER TABLE ONLY public.tendermilestone
    ADD CONSTRAINT tendermilestone_pkey PRIMARY KEY (id);


--
-- Name: tendermilestonedocuments tendermilestonedocuments_pkey; Type: CONSTRAINT; Schema: public; Owner: user_captura
--

ALTER TABLE ONLY public.tendermilestonedocuments
    ADD CONSTRAINT tendermilestonedocuments_pkey PRIMARY KEY (id);


--
-- Name: user_contractingprocess user_contractingprocess_pkey; Type: CONSTRAINT; Schema: public; Owner: user_captura
--

ALTER TABLE ONLY public.user_contractingprocess
    ADD CONSTRAINT user_contractingprocess_pkey PRIMARY KEY (id);


--
-- Name: award award_contractingprocess_id_fkey; Type: FK CONSTRAINT; Schema: dashboard; Owner: user_dashboard
--

ALTER TABLE ONLY dashboard.award
    ADD CONSTRAINT award_contractingprocess_id_fkey FOREIGN KEY (contractingprocess_id) REFERENCES dashboard.contractingprocess(id) ON DELETE CASCADE;


--
-- Name: awardamendmentchanges awardamendmentchanges_award_id_fkey; Type: FK CONSTRAINT; Schema: dashboard; Owner: user_dashboard
--

ALTER TABLE ONLY dashboard.awardamendmentchanges
    ADD CONSTRAINT awardamendmentchanges_award_id_fkey FOREIGN KEY (award_id) REFERENCES dashboard.award(id) ON DELETE CASCADE;


--
-- Name: awardamendmentchanges awardamendmentchanges_contractingprocess_id_fkey; Type: FK CONSTRAINT; Schema: dashboard; Owner: user_dashboard
--

ALTER TABLE ONLY dashboard.awardamendmentchanges
    ADD CONSTRAINT awardamendmentchanges_contractingprocess_id_fkey FOREIGN KEY (contractingprocess_id) REFERENCES dashboard.contractingprocess(id) ON DELETE CASCADE;


--
-- Name: awarddocuments awarddocuments_award_id_fkey; Type: FK CONSTRAINT; Schema: dashboard; Owner: user_dashboard
--

ALTER TABLE ONLY dashboard.awarddocuments
    ADD CONSTRAINT awarddocuments_award_id_fkey FOREIGN KEY (award_id) REFERENCES dashboard.award(id) ON DELETE CASCADE;


--
-- Name: awarddocuments awarddocuments_contractingprocess_id_fkey; Type: FK CONSTRAINT; Schema: dashboard; Owner: user_dashboard
--

ALTER TABLE ONLY dashboard.awarddocuments
    ADD CONSTRAINT awarddocuments_contractingprocess_id_fkey FOREIGN KEY (contractingprocess_id) REFERENCES dashboard.contractingprocess(id) ON DELETE CASCADE;


--
-- Name: awarditem awarditem_award_id_fkey; Type: FK CONSTRAINT; Schema: dashboard; Owner: user_dashboard
--

ALTER TABLE ONLY dashboard.awarditem
    ADD CONSTRAINT awarditem_award_id_fkey FOREIGN KEY (award_id) REFERENCES dashboard.award(id) ON DELETE CASCADE;


--
-- Name: awarditem awarditem_contractingprocess_id_fkey; Type: FK CONSTRAINT; Schema: dashboard; Owner: user_dashboard
--

ALTER TABLE ONLY dashboard.awarditem
    ADD CONSTRAINT awarditem_contractingprocess_id_fkey FOREIGN KEY (contractingprocess_id) REFERENCES dashboard.contractingprocess(id) ON DELETE CASCADE;


--
-- Name: awarditemadditionalclassifications awarditemadditionalclassifications_award_id_fkey; Type: FK CONSTRAINT; Schema: dashboard; Owner: user_dashboard
--

ALTER TABLE ONLY dashboard.awarditemadditionalclassifications
    ADD CONSTRAINT awarditemadditionalclassifications_award_id_fkey FOREIGN KEY (award_id) REFERENCES dashboard.award(id) ON DELETE CASCADE;


--
-- Name: awarditemadditionalclassifications awarditemadditionalclassifications_awarditem_id_fkey; Type: FK CONSTRAINT; Schema: dashboard; Owner: user_dashboard
--

ALTER TABLE ONLY dashboard.awarditemadditionalclassifications
    ADD CONSTRAINT awarditemadditionalclassifications_awarditem_id_fkey FOREIGN KEY (awarditem_id) REFERENCES dashboard.awarditem(id) ON DELETE CASCADE;


--
-- Name: awardsupplier awardsupplier_award_id_fkey; Type: FK CONSTRAINT; Schema: dashboard; Owner: user_dashboard
--

ALTER TABLE ONLY dashboard.awardsupplier
    ADD CONSTRAINT awardsupplier_award_id_fkey FOREIGN KEY (award_id) REFERENCES dashboard.award(id) ON DELETE CASCADE;


--
-- Name: awardsupplier awardsupplier_parties_id_fkey; Type: FK CONSTRAINT; Schema: dashboard; Owner: user_dashboard
--

ALTER TABLE ONLY dashboard.awardsupplier
    ADD CONSTRAINT awardsupplier_parties_id_fkey FOREIGN KEY (parties_id) REFERENCES dashboard.parties(id) ON DELETE CASCADE;


--
-- Name: budget budget_contractingprocess_id_fkey; Type: FK CONSTRAINT; Schema: dashboard; Owner: user_dashboard
--

ALTER TABLE ONLY dashboard.budget
    ADD CONSTRAINT budget_contractingprocess_id_fkey FOREIGN KEY (contractingprocess_id) REFERENCES dashboard.contractingprocess(id) ON DELETE CASCADE;


--
-- Name: budget budget_planning_id_fkey; Type: FK CONSTRAINT; Schema: dashboard; Owner: user_dashboard
--

ALTER TABLE ONLY dashboard.budget
    ADD CONSTRAINT budget_planning_id_fkey FOREIGN KEY (planning_id) REFERENCES dashboard.planning(id) ON DELETE CASCADE;


--
-- Name: clarificationmeeting clarificationmeeting_contractingprocess_id_fkey; Type: FK CONSTRAINT; Schema: dashboard; Owner: user_dashboard
--

ALTER TABLE ONLY dashboard.clarificationmeeting
    ADD CONSTRAINT clarificationmeeting_contractingprocess_id_fkey FOREIGN KEY (contractingprocess_id) REFERENCES dashboard.contractingprocess(id) ON DELETE CASCADE;


--
-- Name: clarificationmeetingactor clarificationmeetingactor_clarificationmeeting_id_fkey; Type: FK CONSTRAINT; Schema: dashboard; Owner: user_dashboard
--

ALTER TABLE ONLY dashboard.clarificationmeetingactor
    ADD CONSTRAINT clarificationmeetingactor_clarificationmeeting_id_fkey FOREIGN KEY (clarificationmeeting_id) REFERENCES dashboard.clarificationmeeting(id) ON DELETE CASCADE;


--
-- Name: clarificationmeetingactor clarificationmeetingactor_parties_id_fkey; Type: FK CONSTRAINT; Schema: dashboard; Owner: user_dashboard
--

ALTER TABLE ONLY dashboard.clarificationmeetingactor
    ADD CONSTRAINT clarificationmeetingactor_parties_id_fkey FOREIGN KEY (parties_id) REFERENCES dashboard.parties(id) ON DELETE CASCADE;


--
-- Name: contract contract_contractingprocess_id_fkey; Type: FK CONSTRAINT; Schema: dashboard; Owner: user_dashboard
--

ALTER TABLE ONLY dashboard.contract
    ADD CONSTRAINT contract_contractingprocess_id_fkey FOREIGN KEY (contractingprocess_id) REFERENCES dashboard.contractingprocess(id) ON DELETE CASCADE;


--
-- Name: contractamendmentchanges contractamendmentchanges_contract_id_fkey; Type: FK CONSTRAINT; Schema: dashboard; Owner: user_dashboard
--

ALTER TABLE ONLY dashboard.contractamendmentchanges
    ADD CONSTRAINT contractamendmentchanges_contract_id_fkey FOREIGN KEY (contract_id) REFERENCES dashboard.contract(id) ON DELETE CASCADE;


--
-- Name: contractamendmentchanges contractamendmentchanges_contractingprocess_id_fkey; Type: FK CONSTRAINT; Schema: dashboard; Owner: user_dashboard
--

ALTER TABLE ONLY dashboard.contractamendmentchanges
    ADD CONSTRAINT contractamendmentchanges_contractingprocess_id_fkey FOREIGN KEY (contractingprocess_id) REFERENCES dashboard.contractingprocess(id) ON DELETE CASCADE;


--
-- Name: contractdocuments contractdocuments_contract_id_fkey; Type: FK CONSTRAINT; Schema: dashboard; Owner: user_dashboard
--

ALTER TABLE ONLY dashboard.contractdocuments
    ADD CONSTRAINT contractdocuments_contract_id_fkey FOREIGN KEY (contract_id) REFERENCES dashboard.contract(id) ON DELETE CASCADE;


--
-- Name: contractdocuments contractdocuments_contractingprocess_id_fkey; Type: FK CONSTRAINT; Schema: dashboard; Owner: user_dashboard
--

ALTER TABLE ONLY dashboard.contractdocuments
    ADD CONSTRAINT contractdocuments_contractingprocess_id_fkey FOREIGN KEY (contractingprocess_id) REFERENCES dashboard.contractingprocess(id) ON DELETE CASCADE;


--
-- Name: contractitem contractitem_contract_id_fkey; Type: FK CONSTRAINT; Schema: dashboard; Owner: user_dashboard
--

ALTER TABLE ONLY dashboard.contractitem
    ADD CONSTRAINT contractitem_contract_id_fkey FOREIGN KEY (contract_id) REFERENCES dashboard.contract(id) ON DELETE CASCADE;


--
-- Name: contractitem contractitem_contractingprocess_id_fkey; Type: FK CONSTRAINT; Schema: dashboard; Owner: user_dashboard
--

ALTER TABLE ONLY dashboard.contractitem
    ADD CONSTRAINT contractitem_contractingprocess_id_fkey FOREIGN KEY (contractingprocess_id) REFERENCES dashboard.contractingprocess(id) ON DELETE CASCADE;


--
-- Name: contractitemadditionalclasifications contractitemadditionalclasifications_contract_id_fkey; Type: FK CONSTRAINT; Schema: dashboard; Owner: user_dashboard
--

ALTER TABLE ONLY dashboard.contractitemadditionalclasifications
    ADD CONSTRAINT contractitemadditionalclasifications_contract_id_fkey FOREIGN KEY (contract_id) REFERENCES dashboard.contract(id) ON DELETE CASCADE;


--
-- Name: contractitemadditionalclasifications contractitemadditionalclasifications_contractingprocess_id_fkey; Type: FK CONSTRAINT; Schema: dashboard; Owner: user_dashboard
--

ALTER TABLE ONLY dashboard.contractitemadditionalclasifications
    ADD CONSTRAINT contractitemadditionalclasifications_contractingprocess_id_fkey FOREIGN KEY (contractingprocess_id) REFERENCES dashboard.contractingprocess(id) ON DELETE CASCADE;


--
-- Name: contractitemadditionalclasifications contractitemadditionalclasifications_contractitem_id_fkey; Type: FK CONSTRAINT; Schema: dashboard; Owner: user_dashboard
--

ALTER TABLE ONLY dashboard.contractitemadditionalclasifications
    ADD CONSTRAINT contractitemadditionalclasifications_contractitem_id_fkey FOREIGN KEY (contractitem_id) REFERENCES dashboard.contractitem(id) ON DELETE CASCADE;


--
-- Name: implementation implementation_contract_id_fkey; Type: FK CONSTRAINT; Schema: dashboard; Owner: user_dashboard
--

ALTER TABLE ONLY dashboard.implementation
    ADD CONSTRAINT implementation_contract_id_fkey FOREIGN KEY (contract_id) REFERENCES dashboard.contract(id) ON DELETE CASCADE;


--
-- Name: implementation implementation_contractingprocess_id_fkey; Type: FK CONSTRAINT; Schema: dashboard; Owner: user_dashboard
--

ALTER TABLE ONLY dashboard.implementation
    ADD CONSTRAINT implementation_contractingprocess_id_fkey FOREIGN KEY (contractingprocess_id) REFERENCES dashboard.contractingprocess(id) ON DELETE CASCADE;


--
-- Name: implementationdocuments implementationdocuments_contract_id_fkey; Type: FK CONSTRAINT; Schema: dashboard; Owner: user_dashboard
--

ALTER TABLE ONLY dashboard.implementationdocuments
    ADD CONSTRAINT implementationdocuments_contract_id_fkey FOREIGN KEY (contract_id) REFERENCES dashboard.contract(id) ON DELETE CASCADE;


--
-- Name: implementationdocuments implementationdocuments_contractingprocess_id_fkey; Type: FK CONSTRAINT; Schema: dashboard; Owner: user_dashboard
--

ALTER TABLE ONLY dashboard.implementationdocuments
    ADD CONSTRAINT implementationdocuments_contractingprocess_id_fkey FOREIGN KEY (contractingprocess_id) REFERENCES dashboard.contractingprocess(id) ON DELETE CASCADE;


--
-- Name: implementationdocuments implementationdocuments_implementation_id_fkey; Type: FK CONSTRAINT; Schema: dashboard; Owner: user_dashboard
--

ALTER TABLE ONLY dashboard.implementationdocuments
    ADD CONSTRAINT implementationdocuments_implementation_id_fkey FOREIGN KEY (implementation_id) REFERENCES dashboard.implementation(id) ON DELETE CASCADE;


--
-- Name: implementationmilestone implementationmilestone_contract_id_fkey; Type: FK CONSTRAINT; Schema: dashboard; Owner: user_dashboard
--

ALTER TABLE ONLY dashboard.implementationmilestone
    ADD CONSTRAINT implementationmilestone_contract_id_fkey FOREIGN KEY (contract_id) REFERENCES dashboard.contract(id) ON DELETE CASCADE;


--
-- Name: implementationmilestone implementationmilestone_contractingprocess_id_fkey; Type: FK CONSTRAINT; Schema: dashboard; Owner: user_dashboard
--

ALTER TABLE ONLY dashboard.implementationmilestone
    ADD CONSTRAINT implementationmilestone_contractingprocess_id_fkey FOREIGN KEY (contractingprocess_id) REFERENCES dashboard.contractingprocess(id) ON DELETE CASCADE;


--
-- Name: implementationmilestone implementationmilestone_implementation_id_fkey; Type: FK CONSTRAINT; Schema: dashboard; Owner: user_dashboard
--

ALTER TABLE ONLY dashboard.implementationmilestone
    ADD CONSTRAINT implementationmilestone_implementation_id_fkey FOREIGN KEY (implementation_id) REFERENCES dashboard.implementation(id) ON DELETE CASCADE;


--
-- Name: implementationmilestonedocuments implementationmilestonedocuments_contract_id_fkey; Type: FK CONSTRAINT; Schema: dashboard; Owner: user_dashboard
--

ALTER TABLE ONLY dashboard.implementationmilestonedocuments
    ADD CONSTRAINT implementationmilestonedocuments_contract_id_fkey FOREIGN KEY (contract_id) REFERENCES dashboard.contract(id) ON DELETE CASCADE;


--
-- Name: implementationmilestonedocuments implementationmilestonedocuments_contractingprocess_id_fkey; Type: FK CONSTRAINT; Schema: dashboard; Owner: user_dashboard
--

ALTER TABLE ONLY dashboard.implementationmilestonedocuments
    ADD CONSTRAINT implementationmilestonedocuments_contractingprocess_id_fkey FOREIGN KEY (contractingprocess_id) REFERENCES dashboard.contractingprocess(id) ON DELETE CASCADE;


--
-- Name: implementationmilestonedocuments implementationmilestonedocuments_implementation_id_fkey; Type: FK CONSTRAINT; Schema: dashboard; Owner: user_dashboard
--

ALTER TABLE ONLY dashboard.implementationmilestonedocuments
    ADD CONSTRAINT implementationmilestonedocuments_implementation_id_fkey FOREIGN KEY (implementation_id) REFERENCES dashboard.implementation(id) ON DELETE CASCADE;


--
-- Name: implementationtransactions implementationtransactions_contract_id_fkey; Type: FK CONSTRAINT; Schema: dashboard; Owner: user_dashboard
--

ALTER TABLE ONLY dashboard.implementationtransactions
    ADD CONSTRAINT implementationtransactions_contract_id_fkey FOREIGN KEY (contract_id) REFERENCES dashboard.contract(id) ON DELETE CASCADE;


--
-- Name: implementationtransactions implementationtransactions_contractingprocess_id_fkey; Type: FK CONSTRAINT; Schema: dashboard; Owner: user_dashboard
--

ALTER TABLE ONLY dashboard.implementationtransactions
    ADD CONSTRAINT implementationtransactions_contractingprocess_id_fkey FOREIGN KEY (contractingprocess_id) REFERENCES dashboard.contractingprocess(id) ON DELETE CASCADE;


--
-- Name: implementationtransactions implementationtransactions_implementation_id_fkey; Type: FK CONSTRAINT; Schema: dashboard; Owner: user_dashboard
--

ALTER TABLE ONLY dashboard.implementationtransactions
    ADD CONSTRAINT implementationtransactions_implementation_id_fkey FOREIGN KEY (implementation_id) REFERENCES dashboard.implementation(id) ON DELETE CASCADE;


--
-- Name: links links_contractingprocess_id_fkey; Type: FK CONSTRAINT; Schema: dashboard; Owner: user_dashboard
--

ALTER TABLE ONLY dashboard.links
    ADD CONSTRAINT links_contractingprocess_id_fkey FOREIGN KEY (contractingprocess_id) REFERENCES dashboard.contractingprocess(id) ON DELETE CASCADE;


--
-- Name: memberof memberof_parties_id_fkey; Type: FK CONSTRAINT; Schema: dashboard; Owner: user_dashboard
--

ALTER TABLE ONLY dashboard.memberof
    ADD CONSTRAINT memberof_parties_id_fkey FOREIGN KEY (parties_id) REFERENCES dashboard.parties(id) ON DELETE CASCADE;


--
-- Name: memberof memberof_principal_parties_id_fkey; Type: FK CONSTRAINT; Schema: dashboard; Owner: user_dashboard
--

ALTER TABLE ONLY dashboard.memberof
    ADD CONSTRAINT memberof_principal_parties_id_fkey FOREIGN KEY (principal_parties_id) REFERENCES dashboard.parties(id) ON DELETE CASCADE;


--
-- Name: parties parties_contractingprocess_id_fkey; Type: FK CONSTRAINT; Schema: dashboard; Owner: user_dashboard
--

ALTER TABLE ONLY dashboard.parties
    ADD CONSTRAINT parties_contractingprocess_id_fkey FOREIGN KEY (contractingprocess_id) REFERENCES dashboard.contractingprocess(id) ON DELETE CASCADE;


--
-- Name: partiesadditionalidentifiers partiesadditionalidentifiers_contractingprocess_id_fkey; Type: FK CONSTRAINT; Schema: dashboard; Owner: user_dashboard
--

ALTER TABLE ONLY dashboard.partiesadditionalidentifiers
    ADD CONSTRAINT partiesadditionalidentifiers_contractingprocess_id_fkey FOREIGN KEY (contractingprocess_id) REFERENCES dashboard.contractingprocess(id) ON DELETE CASCADE;


--
-- Name: partiesadditionalidentifiers partiesadditionalidentifiers_parties_id_fkey; Type: FK CONSTRAINT; Schema: dashboard; Owner: user_dashboard
--

ALTER TABLE ONLY dashboard.partiesadditionalidentifiers
    ADD CONSTRAINT partiesadditionalidentifiers_parties_id_fkey FOREIGN KEY (parties_id) REFERENCES dashboard.parties(id) ON DELETE CASCADE;


--
-- Name: planning planning_contractingprocess_id_fkey; Type: FK CONSTRAINT; Schema: dashboard; Owner: user_dashboard
--

ALTER TABLE ONLY dashboard.planning
    ADD CONSTRAINT planning_contractingprocess_id_fkey FOREIGN KEY (contractingprocess_id) REFERENCES dashboard.contractingprocess(id) ON DELETE CASCADE;


--
-- Name: planningdocuments planningdocuments_contractingprocess_id_fkey; Type: FK CONSTRAINT; Schema: dashboard; Owner: user_dashboard
--

ALTER TABLE ONLY dashboard.planningdocuments
    ADD CONSTRAINT planningdocuments_contractingprocess_id_fkey FOREIGN KEY (contractingprocess_id) REFERENCES dashboard.contractingprocess(id) ON DELETE CASCADE;


--
-- Name: planningdocuments planningdocuments_planning_id_fkey; Type: FK CONSTRAINT; Schema: dashboard; Owner: user_dashboard
--

ALTER TABLE ONLY dashboard.planningdocuments
    ADD CONSTRAINT planningdocuments_planning_id_fkey FOREIGN KEY (planning_id) REFERENCES dashboard.planning(id) ON DELETE CASCADE;


--
-- Name: publisher publisher_contractingprocess_id_fkey; Type: FK CONSTRAINT; Schema: dashboard; Owner: user_dashboard
--

ALTER TABLE ONLY dashboard.publisher
    ADD CONSTRAINT publisher_contractingprocess_id_fkey FOREIGN KEY (contractingprocess_id) REFERENCES dashboard.contractingprocess(id) ON DELETE CASCADE;


--
-- Name: quotes quotes_issuingsupplier_id_fkey; Type: FK CONSTRAINT; Schema: dashboard; Owner: user_dashboard
--

ALTER TABLE ONLY dashboard.quotes
    ADD CONSTRAINT quotes_issuingsupplier_id_fkey FOREIGN KEY (issuingsupplier_id) REFERENCES dashboard.parties(id) ON DELETE CASCADE;


--
-- Name: quotes quotes_requestforquotes_id_fkey; Type: FK CONSTRAINT; Schema: dashboard; Owner: user_dashboard
--

ALTER TABLE ONLY dashboard.quotes
    ADD CONSTRAINT quotes_requestforquotes_id_fkey FOREIGN KEY (requestforquotes_id) REFERENCES dashboard.requestforquotes(id) ON DELETE CASCADE;


--
-- Name: quotesitems quotesitems_quotes_id_fkey; Type: FK CONSTRAINT; Schema: dashboard; Owner: user_dashboard
--

ALTER TABLE ONLY dashboard.quotesitems
    ADD CONSTRAINT quotesitems_quotes_id_fkey FOREIGN KEY (quotes_id) REFERENCES dashboard.quotes(id) ON DELETE CASCADE;


--
-- Name: requestforquotes requestforquotes_contractingprocess_id_fkey; Type: FK CONSTRAINT; Schema: dashboard; Owner: user_dashboard
--

ALTER TABLE ONLY dashboard.requestforquotes
    ADD CONSTRAINT requestforquotes_contractingprocess_id_fkey FOREIGN KEY (contractingprocess_id) REFERENCES dashboard.contractingprocess(id) ON DELETE CASCADE;


--
-- Name: requestforquotesinvitedsuppliers requestforquotesinvitedsuppliers_parties_id_fkey; Type: FK CONSTRAINT; Schema: dashboard; Owner: user_dashboard
--

ALTER TABLE ONLY dashboard.requestforquotesinvitedsuppliers
    ADD CONSTRAINT requestforquotesinvitedsuppliers_parties_id_fkey FOREIGN KEY (parties_id) REFERENCES dashboard.parties(id);


--
-- Name: requestforquotesinvitedsuppliers requestforquotesinvitedsuppliers_requestforquotes_id_fkey; Type: FK CONSTRAINT; Schema: dashboard; Owner: user_dashboard
--

ALTER TABLE ONLY dashboard.requestforquotesinvitedsuppliers
    ADD CONSTRAINT requestforquotesinvitedsuppliers_requestforquotes_id_fkey FOREIGN KEY (requestforquotes_id) REFERENCES dashboard.requestforquotes(id) ON DELETE CASCADE;


--
-- Name: requestforquotesitems requestforquotesitems_requestforquotes_id_fkey; Type: FK CONSTRAINT; Schema: dashboard; Owner: user_dashboard
--

ALTER TABLE ONLY dashboard.requestforquotesitems
    ADD CONSTRAINT requestforquotesitems_requestforquotes_id_fkey FOREIGN KEY (requestforquotes_id) REFERENCES dashboard.requestforquotes(id) ON DELETE CASCADE;


--
-- Name: roles roles_contractingprocess_id_fkey; Type: FK CONSTRAINT; Schema: dashboard; Owner: user_dashboard
--

ALTER TABLE ONLY dashboard.roles
    ADD CONSTRAINT roles_contractingprocess_id_fkey FOREIGN KEY (contractingprocess_id) REFERENCES dashboard.contractingprocess(id) ON DELETE CASCADE;


--
-- Name: roles roles_parties_id_fkey; Type: FK CONSTRAINT; Schema: dashboard; Owner: user_dashboard
--

ALTER TABLE ONLY dashboard.roles
    ADD CONSTRAINT roles_parties_id_fkey FOREIGN KEY (parties_id) REFERENCES dashboard.parties(id) ON DELETE CASCADE;


--
-- Name: tags tags_contractingprocess_id_fkey; Type: FK CONSTRAINT; Schema: dashboard; Owner: user_dashboard
--

ALTER TABLE ONLY dashboard.tags
    ADD CONSTRAINT tags_contractingprocess_id_fkey FOREIGN KEY (contractingprocess_id) REFERENCES dashboard.contractingprocess(id) ON DELETE CASCADE;


--
-- Name: tender tender_contractingprocess_id_fkey; Type: FK CONSTRAINT; Schema: dashboard; Owner: user_dashboard
--

ALTER TABLE ONLY dashboard.tender
    ADD CONSTRAINT tender_contractingprocess_id_fkey FOREIGN KEY (contractingprocess_id) REFERENCES dashboard.contractingprocess(id) ON DELETE CASCADE;


--
-- Name: tenderamendmentchanges tenderamendmentchanges_contractingprocess_id_fkey; Type: FK CONSTRAINT; Schema: dashboard; Owner: user_dashboard
--

ALTER TABLE ONLY dashboard.tenderamendmentchanges
    ADD CONSTRAINT tenderamendmentchanges_contractingprocess_id_fkey FOREIGN KEY (contractingprocess_id) REFERENCES dashboard.contractingprocess(id) ON DELETE CASCADE;


--
-- Name: tenderamendmentchanges tenderamendmentchanges_tender_id_fkey; Type: FK CONSTRAINT; Schema: dashboard; Owner: user_dashboard
--

ALTER TABLE ONLY dashboard.tenderamendmentchanges
    ADD CONSTRAINT tenderamendmentchanges_tender_id_fkey FOREIGN KEY (tender_id) REFERENCES dashboard.tender(id) ON DELETE CASCADE;


--
-- Name: tenderdocuments tenderdocuments_contractingprocess_id_fkey; Type: FK CONSTRAINT; Schema: dashboard; Owner: user_dashboard
--

ALTER TABLE ONLY dashboard.tenderdocuments
    ADD CONSTRAINT tenderdocuments_contractingprocess_id_fkey FOREIGN KEY (contractingprocess_id) REFERENCES dashboard.contractingprocess(id) ON DELETE CASCADE;


--
-- Name: tenderdocuments tenderdocuments_tender_id_fkey; Type: FK CONSTRAINT; Schema: dashboard; Owner: user_dashboard
--

ALTER TABLE ONLY dashboard.tenderdocuments
    ADD CONSTRAINT tenderdocuments_tender_id_fkey FOREIGN KEY (tender_id) REFERENCES dashboard.tender(id) ON DELETE CASCADE;


--
-- Name: tenderitem tenderitem_contractingprocess_id_fkey; Type: FK CONSTRAINT; Schema: dashboard; Owner: user_dashboard
--

ALTER TABLE ONLY dashboard.tenderitem
    ADD CONSTRAINT tenderitem_contractingprocess_id_fkey FOREIGN KEY (contractingprocess_id) REFERENCES dashboard.contractingprocess(id) ON DELETE CASCADE;


--
-- Name: tenderitem tenderitem_tender_id_fkey; Type: FK CONSTRAINT; Schema: dashboard; Owner: user_dashboard
--

ALTER TABLE ONLY dashboard.tenderitem
    ADD CONSTRAINT tenderitem_tender_id_fkey FOREIGN KEY (tender_id) REFERENCES dashboard.tender(id) ON DELETE CASCADE;


--
-- Name: tenderitemadditionalclassifications tenderitemadditionalclassifications_contractingprocess_id_fkey; Type: FK CONSTRAINT; Schema: dashboard; Owner: user_dashboard
--

ALTER TABLE ONLY dashboard.tenderitemadditionalclassifications
    ADD CONSTRAINT tenderitemadditionalclassifications_contractingprocess_id_fkey FOREIGN KEY (contractingprocess_id) REFERENCES dashboard.contractingprocess(id) ON DELETE CASCADE;


--
-- Name: tenderitemadditionalclassifications tenderitemadditionalclassifications_tenderitem_id_fkey; Type: FK CONSTRAINT; Schema: dashboard; Owner: user_dashboard
--

ALTER TABLE ONLY dashboard.tenderitemadditionalclassifications
    ADD CONSTRAINT tenderitemadditionalclassifications_tenderitem_id_fkey FOREIGN KEY (tenderitem_id) REFERENCES dashboard.tenderitem(id) ON DELETE CASCADE;


--
-- Name: tendermilestone tendermilestone_contractingprocess_id_fkey; Type: FK CONSTRAINT; Schema: dashboard; Owner: user_dashboard
--

ALTER TABLE ONLY dashboard.tendermilestone
    ADD CONSTRAINT tendermilestone_contractingprocess_id_fkey FOREIGN KEY (contractingprocess_id) REFERENCES dashboard.contractingprocess(id) ON DELETE CASCADE;


--
-- Name: tendermilestone tendermilestone_tender_id_fkey; Type: FK CONSTRAINT; Schema: dashboard; Owner: user_dashboard
--

ALTER TABLE ONLY dashboard.tendermilestone
    ADD CONSTRAINT tendermilestone_tender_id_fkey FOREIGN KEY (tender_id) REFERENCES dashboard.tender(id) ON DELETE CASCADE;


--
-- Name: tendermilestonedocuments tendermilestonedocuments_contractingprocess_id_fkey; Type: FK CONSTRAINT; Schema: dashboard; Owner: user_dashboard
--

ALTER TABLE ONLY dashboard.tendermilestonedocuments
    ADD CONSTRAINT tendermilestonedocuments_contractingprocess_id_fkey FOREIGN KEY (contractingprocess_id) REFERENCES dashboard.contractingprocess(id) ON DELETE CASCADE;


--
-- Name: tendermilestonedocuments tendermilestonedocuments_milestone_id_fkey; Type: FK CONSTRAINT; Schema: dashboard; Owner: user_dashboard
--

ALTER TABLE ONLY dashboard.tendermilestonedocuments
    ADD CONSTRAINT tendermilestonedocuments_milestone_id_fkey FOREIGN KEY (milestone_id) REFERENCES dashboard.tendermilestone(id) ON DELETE CASCADE;


--
-- Name: tendermilestonedocuments tendermilestonedocuments_tender_id_fkey; Type: FK CONSTRAINT; Schema: dashboard; Owner: user_dashboard
--

ALTER TABLE ONLY dashboard.tendermilestonedocuments
    ADD CONSTRAINT tendermilestonedocuments_tender_id_fkey FOREIGN KEY (tender_id) REFERENCES dashboard.tender(id) ON DELETE CASCADE;


--
-- Name: user_contractingprocess user_contractingprocess_contractingprocess_id_fkey; Type: FK CONSTRAINT; Schema: dashboard; Owner: user_dashboard
--

ALTER TABLE ONLY dashboard.user_contractingprocess
    ADD CONSTRAINT user_contractingprocess_contractingprocess_id_fkey FOREIGN KEY (contractingprocess_id) REFERENCES dashboard.contractingprocess(id) ON DELETE CASCADE;


--
-- Name: award award_contractingprocess_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: user_captura
--

ALTER TABLE ONLY public.award
    ADD CONSTRAINT award_contractingprocess_id_fkey FOREIGN KEY (contractingprocess_id) REFERENCES public.contractingprocess(id) ON DELETE CASCADE;


--
-- Name: awardamendmentchanges awardamendmentchanges_award_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: user_captura
--

ALTER TABLE ONLY public.awardamendmentchanges
    ADD CONSTRAINT awardamendmentchanges_award_id_fkey FOREIGN KEY (award_id) REFERENCES public.award(id) ON DELETE CASCADE;


--
-- Name: awardamendmentchanges awardamendmentchanges_contractingprocess_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: user_captura
--

ALTER TABLE ONLY public.awardamendmentchanges
    ADD CONSTRAINT awardamendmentchanges_contractingprocess_id_fkey FOREIGN KEY (contractingprocess_id) REFERENCES public.contractingprocess(id) ON DELETE CASCADE;


--
-- Name: awarddocuments awarddocuments_award_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: user_captura
--

ALTER TABLE ONLY public.awarddocuments
    ADD CONSTRAINT awarddocuments_award_id_fkey FOREIGN KEY (award_id) REFERENCES public.award(id) ON DELETE CASCADE;


--
-- Name: awarddocuments awarddocuments_contractingprocess_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: user_captura
--

ALTER TABLE ONLY public.awarddocuments
    ADD CONSTRAINT awarddocuments_contractingprocess_id_fkey FOREIGN KEY (contractingprocess_id) REFERENCES public.contractingprocess(id) ON DELETE CASCADE;


--
-- Name: awarditem awarditem_award_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: user_captura
--

ALTER TABLE ONLY public.awarditem
    ADD CONSTRAINT awarditem_award_id_fkey FOREIGN KEY (award_id) REFERENCES public.award(id) ON DELETE CASCADE;


--
-- Name: awarditem awarditem_contractingprocess_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: user_captura
--

ALTER TABLE ONLY public.awarditem
    ADD CONSTRAINT awarditem_contractingprocess_id_fkey FOREIGN KEY (contractingprocess_id) REFERENCES public.contractingprocess(id) ON DELETE CASCADE;


--
-- Name: awarditemadditionalclassifications awarditemadditionalclassifications_award_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: user_captura
--

ALTER TABLE ONLY public.awarditemadditionalclassifications
    ADD CONSTRAINT awarditemadditionalclassifications_award_id_fkey FOREIGN KEY (award_id) REFERENCES public.award(id) ON DELETE CASCADE;


--
-- Name: awarditemadditionalclassifications awarditemadditionalclassifications_awarditem_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: user_captura
--

ALTER TABLE ONLY public.awarditemadditionalclassifications
    ADD CONSTRAINT awarditemadditionalclassifications_awarditem_id_fkey FOREIGN KEY (awarditem_id) REFERENCES public.awarditem(id) ON DELETE CASCADE;


--
-- Name: awardsupplier awardsupplier_award_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: user_captura
--

ALTER TABLE ONLY public.awardsupplier
    ADD CONSTRAINT awardsupplier_award_id_fkey FOREIGN KEY (award_id) REFERENCES public.award(id) ON DELETE CASCADE;


--
-- Name: awardsupplier awardsupplier_parties_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: user_captura
--

ALTER TABLE ONLY public.awardsupplier
    ADD CONSTRAINT awardsupplier_parties_id_fkey FOREIGN KEY (parties_id) REFERENCES public.parties(id) ON DELETE CASCADE;


--
-- Name: budget budget_contractingprocess_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: user_captura
--

ALTER TABLE ONLY public.budget
    ADD CONSTRAINT budget_contractingprocess_id_fkey FOREIGN KEY (contractingprocess_id) REFERENCES public.contractingprocess(id) ON DELETE CASCADE;


--
-- Name: budget budget_planning_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: user_captura
--

ALTER TABLE ONLY public.budget
    ADD CONSTRAINT budget_planning_id_fkey FOREIGN KEY (planning_id) REFERENCES public.planning(id) ON DELETE CASCADE;


--
-- Name: clarificationmeeting clarificationmeeting_contractingprocess_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: user_captura
--

ALTER TABLE ONLY public.clarificationmeeting
    ADD CONSTRAINT clarificationmeeting_contractingprocess_id_fkey FOREIGN KEY (contractingprocess_id) REFERENCES public.contractingprocess(id) ON DELETE CASCADE;


--
-- Name: clarificationmeetingactor clarificationmeetingactor_clarificationmeeting_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: user_captura
--

ALTER TABLE ONLY public.clarificationmeetingactor
    ADD CONSTRAINT clarificationmeetingactor_clarificationmeeting_id_fkey FOREIGN KEY (clarificationmeeting_id) REFERENCES public.clarificationmeeting(id) ON DELETE CASCADE;


--
-- Name: clarificationmeetingactor clarificationmeetingactor_parties_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: user_captura
--

ALTER TABLE ONLY public.clarificationmeetingactor
    ADD CONSTRAINT clarificationmeetingactor_parties_id_fkey FOREIGN KEY (parties_id) REFERENCES public.parties(id) ON DELETE CASCADE;


--
-- Name: contract contract_contractingprocess_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: user_captura
--

ALTER TABLE ONLY public.contract
    ADD CONSTRAINT contract_contractingprocess_id_fkey FOREIGN KEY (contractingprocess_id) REFERENCES public.contractingprocess(id) ON DELETE CASCADE;


--
-- Name: contractamendmentchanges contractamendmentchanges_contract_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: user_captura
--

ALTER TABLE ONLY public.contractamendmentchanges
    ADD CONSTRAINT contractamendmentchanges_contract_id_fkey FOREIGN KEY (contract_id) REFERENCES public.contract(id) ON DELETE CASCADE;


--
-- Name: contractamendmentchanges contractamendmentchanges_contractingprocess_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: user_captura
--

ALTER TABLE ONLY public.contractamendmentchanges
    ADD CONSTRAINT contractamendmentchanges_contractingprocess_id_fkey FOREIGN KEY (contractingprocess_id) REFERENCES public.contractingprocess(id) ON DELETE CASCADE;


--
-- Name: contractdocuments contractdocuments_contract_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: user_captura
--

ALTER TABLE ONLY public.contractdocuments
    ADD CONSTRAINT contractdocuments_contract_id_fkey FOREIGN KEY (contract_id) REFERENCES public.contract(id) ON DELETE CASCADE;


--
-- Name: contractdocuments contractdocuments_contractingprocess_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: user_captura
--

ALTER TABLE ONLY public.contractdocuments
    ADD CONSTRAINT contractdocuments_contractingprocess_id_fkey FOREIGN KEY (contractingprocess_id) REFERENCES public.contractingprocess(id) ON DELETE CASCADE;


--
-- Name: contractitem contractitem_contract_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: user_captura
--

ALTER TABLE ONLY public.contractitem
    ADD CONSTRAINT contractitem_contract_id_fkey FOREIGN KEY (contract_id) REFERENCES public.contract(id) ON DELETE CASCADE;


--
-- Name: contractitem contractitem_contractingprocess_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: user_captura
--

ALTER TABLE ONLY public.contractitem
    ADD CONSTRAINT contractitem_contractingprocess_id_fkey FOREIGN KEY (contractingprocess_id) REFERENCES public.contractingprocess(id) ON DELETE CASCADE;


--
-- Name: contractitemadditionalclasifications contractitemadditionalclasifications_contract_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: user_captura
--

ALTER TABLE ONLY public.contractitemadditionalclasifications
    ADD CONSTRAINT contractitemadditionalclasifications_contract_id_fkey FOREIGN KEY (contract_id) REFERENCES public.contract(id) ON DELETE CASCADE;


--
-- Name: contractitemadditionalclasifications contractitemadditionalclasifications_contractingprocess_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: user_captura
--

ALTER TABLE ONLY public.contractitemadditionalclasifications
    ADD CONSTRAINT contractitemadditionalclasifications_contractingprocess_id_fkey FOREIGN KEY (contractingprocess_id) REFERENCES public.contractingprocess(id) ON DELETE CASCADE;


--
-- Name: contractitemadditionalclasifications contractitemadditionalclasifications_contractitem_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: user_captura
--

ALTER TABLE ONLY public.contractitemadditionalclasifications
    ADD CONSTRAINT contractitemadditionalclasifications_contractitem_id_fkey FOREIGN KEY (contractitem_id) REFERENCES public.contractitem(id) ON DELETE CASCADE;


--
-- Name: implementation implementation_contract_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: user_captura
--

ALTER TABLE ONLY public.implementation
    ADD CONSTRAINT implementation_contract_id_fkey FOREIGN KEY (contract_id) REFERENCES public.contract(id) ON DELETE CASCADE;


--
-- Name: implementation implementation_contractingprocess_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: user_captura
--

ALTER TABLE ONLY public.implementation
    ADD CONSTRAINT implementation_contractingprocess_id_fkey FOREIGN KEY (contractingprocess_id) REFERENCES public.contractingprocess(id) ON DELETE CASCADE;


--
-- Name: implementationdocuments implementationdocuments_contract_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: user_captura
--

ALTER TABLE ONLY public.implementationdocuments
    ADD CONSTRAINT implementationdocuments_contract_id_fkey FOREIGN KEY (contract_id) REFERENCES public.contract(id) ON DELETE CASCADE;


--
-- Name: implementationdocuments implementationdocuments_contractingprocess_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: user_captura
--

ALTER TABLE ONLY public.implementationdocuments
    ADD CONSTRAINT implementationdocuments_contractingprocess_id_fkey FOREIGN KEY (contractingprocess_id) REFERENCES public.contractingprocess(id) ON DELETE CASCADE;


--
-- Name: implementationdocuments implementationdocuments_implementation_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: user_captura
--

ALTER TABLE ONLY public.implementationdocuments
    ADD CONSTRAINT implementationdocuments_implementation_id_fkey FOREIGN KEY (implementation_id) REFERENCES public.implementation(id) ON DELETE CASCADE;


--
-- Name: implementationmilestone implementationmilestone_contract_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: user_captura
--

ALTER TABLE ONLY public.implementationmilestone
    ADD CONSTRAINT implementationmilestone_contract_id_fkey FOREIGN KEY (contract_id) REFERENCES public.contract(id) ON DELETE CASCADE;


--
-- Name: implementationmilestone implementationmilestone_contractingprocess_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: user_captura
--

ALTER TABLE ONLY public.implementationmilestone
    ADD CONSTRAINT implementationmilestone_contractingprocess_id_fkey FOREIGN KEY (contractingprocess_id) REFERENCES public.contractingprocess(id) ON DELETE CASCADE;


--
-- Name: implementationmilestone implementationmilestone_implementation_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: user_captura
--

ALTER TABLE ONLY public.implementationmilestone
    ADD CONSTRAINT implementationmilestone_implementation_id_fkey FOREIGN KEY (implementation_id) REFERENCES public.implementation(id) ON DELETE CASCADE;


--
-- Name: implementationmilestonedocuments implementationmilestonedocuments_contract_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: user_captura
--

ALTER TABLE ONLY public.implementationmilestonedocuments
    ADD CONSTRAINT implementationmilestonedocuments_contract_id_fkey FOREIGN KEY (contract_id) REFERENCES public.contract(id) ON DELETE CASCADE;


--
-- Name: implementationmilestonedocuments implementationmilestonedocuments_contractingprocess_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: user_captura
--

ALTER TABLE ONLY public.implementationmilestonedocuments
    ADD CONSTRAINT implementationmilestonedocuments_contractingprocess_id_fkey FOREIGN KEY (contractingprocess_id) REFERENCES public.contractingprocess(id) ON DELETE CASCADE;


--
-- Name: implementationmilestonedocuments implementationmilestonedocuments_implementation_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: user_captura
--

ALTER TABLE ONLY public.implementationmilestonedocuments
    ADD CONSTRAINT implementationmilestonedocuments_implementation_id_fkey FOREIGN KEY (implementation_id) REFERENCES public.implementation(id) ON DELETE CASCADE;


--
-- Name: implementationtransactions implementationtransactions_contract_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: user_captura
--

ALTER TABLE ONLY public.implementationtransactions
    ADD CONSTRAINT implementationtransactions_contract_id_fkey FOREIGN KEY (contract_id) REFERENCES public.contract(id) ON DELETE CASCADE;


--
-- Name: implementationtransactions implementationtransactions_contractingprocess_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: user_captura
--

ALTER TABLE ONLY public.implementationtransactions
    ADD CONSTRAINT implementationtransactions_contractingprocess_id_fkey FOREIGN KEY (contractingprocess_id) REFERENCES public.contractingprocess(id) ON DELETE CASCADE;


--
-- Name: implementationtransactions implementationtransactions_implementation_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: user_captura
--

ALTER TABLE ONLY public.implementationtransactions
    ADD CONSTRAINT implementationtransactions_implementation_id_fkey FOREIGN KEY (implementation_id) REFERENCES public.implementation(id) ON DELETE CASCADE;


--
-- Name: links links_contractingprocess_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: user_captura
--

ALTER TABLE ONLY public.links
    ADD CONSTRAINT links_contractingprocess_id_fkey FOREIGN KEY (contractingprocess_id) REFERENCES public.contractingprocess(id) ON DELETE CASCADE;


--
-- Name: memberof memberof_parties_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: user_captura
--

ALTER TABLE ONLY public.memberof
    ADD CONSTRAINT memberof_parties_id_fkey FOREIGN KEY (parties_id) REFERENCES public.parties(id) ON DELETE CASCADE;


--
-- Name: memberof memberof_principal_parties_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: user_captura
--

ALTER TABLE ONLY public.memberof
    ADD CONSTRAINT memberof_principal_parties_id_fkey FOREIGN KEY (principal_parties_id) REFERENCES public.parties(id) ON DELETE CASCADE;


--
-- Name: parties parties_contractingprocess_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: user_captura
--

ALTER TABLE ONLY public.parties
    ADD CONSTRAINT parties_contractingprocess_id_fkey FOREIGN KEY (contractingprocess_id) REFERENCES public.contractingprocess(id) ON DELETE CASCADE;


--
-- Name: partiesadditionalidentifiers partiesadditionalidentifiers_contractingprocess_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: user_captura
--

ALTER TABLE ONLY public.partiesadditionalidentifiers
    ADD CONSTRAINT partiesadditionalidentifiers_contractingprocess_id_fkey FOREIGN KEY (contractingprocess_id) REFERENCES public.contractingprocess(id) ON DELETE CASCADE;


--
-- Name: partiesadditionalidentifiers partiesadditionalidentifiers_parties_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: user_captura
--

ALTER TABLE ONLY public.partiesadditionalidentifiers
    ADD CONSTRAINT partiesadditionalidentifiers_parties_id_fkey FOREIGN KEY (parties_id) REFERENCES public.parties(id) ON DELETE CASCADE;


--
-- Name: planning planning_contractingprocess_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: user_captura
--

ALTER TABLE ONLY public.planning
    ADD CONSTRAINT planning_contractingprocess_id_fkey FOREIGN KEY (contractingprocess_id) REFERENCES public.contractingprocess(id) ON DELETE CASCADE;


--
-- Name: planningdocuments planningdocuments_contractingprocess_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: user_captura
--

ALTER TABLE ONLY public.planningdocuments
    ADD CONSTRAINT planningdocuments_contractingprocess_id_fkey FOREIGN KEY (contractingprocess_id) REFERENCES public.contractingprocess(id) ON DELETE CASCADE;


--
-- Name: planningdocuments planningdocuments_planning_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: user_captura
--

ALTER TABLE ONLY public.planningdocuments
    ADD CONSTRAINT planningdocuments_planning_id_fkey FOREIGN KEY (planning_id) REFERENCES public.planning(id) ON DELETE CASCADE;


--
-- Name: publisher publisher_contractingprocess_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: user_captura
--

ALTER TABLE ONLY public.publisher
    ADD CONSTRAINT publisher_contractingprocess_id_fkey FOREIGN KEY (contractingprocess_id) REFERENCES public.contractingprocess(id) ON DELETE CASCADE;


--
-- Name: quotes quotes_issuingsupplier_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: user_captura
--

ALTER TABLE ONLY public.quotes
    ADD CONSTRAINT quotes_issuingsupplier_id_fkey FOREIGN KEY (issuingsupplier_id) REFERENCES public.parties(id) ON DELETE CASCADE;


--
-- Name: quotes quotes_requestforquotes_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: user_captura
--

ALTER TABLE ONLY public.quotes
    ADD CONSTRAINT quotes_requestforquotes_id_fkey FOREIGN KEY (requestforquotes_id) REFERENCES public.requestforquotes(id) ON DELETE CASCADE;


--
-- Name: quotesitems quotesitems_quotes_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: user_captura
--

ALTER TABLE ONLY public.quotesitems
    ADD CONSTRAINT quotesitems_quotes_id_fkey FOREIGN KEY (quotes_id) REFERENCES public.quotes(id) ON DELETE CASCADE;


--
-- Name: requestforquotes requestforquotes_contractingprocess_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: user_captura
--

ALTER TABLE ONLY public.requestforquotes
    ADD CONSTRAINT requestforquotes_contractingprocess_id_fkey FOREIGN KEY (contractingprocess_id) REFERENCES public.contractingprocess(id) ON DELETE CASCADE;


--
-- Name: requestforquotesinvitedsuppliers requestforquotesinvitedsuppliers_parties_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: user_captura
--

ALTER TABLE ONLY public.requestforquotesinvitedsuppliers
    ADD CONSTRAINT requestforquotesinvitedsuppliers_parties_id_fkey FOREIGN KEY (parties_id) REFERENCES public.parties(id);


--
-- Name: requestforquotesinvitedsuppliers requestforquotesinvitedsuppliers_requestforquotes_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: user_captura
--

ALTER TABLE ONLY public.requestforquotesinvitedsuppliers
    ADD CONSTRAINT requestforquotesinvitedsuppliers_requestforquotes_id_fkey FOREIGN KEY (requestforquotes_id) REFERENCES public.requestforquotes(id) ON DELETE CASCADE;


--
-- Name: requestforquotesitems requestforquotesitems_requestforquotes_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: user_captura
--

ALTER TABLE ONLY public.requestforquotesitems
    ADD CONSTRAINT requestforquotesitems_requestforquotes_id_fkey FOREIGN KEY (requestforquotes_id) REFERENCES public.requestforquotes(id) ON DELETE CASCADE;


--
-- Name: roles roles_contractingprocess_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: user_captura
--

ALTER TABLE ONLY public.roles
    ADD CONSTRAINT roles_contractingprocess_id_fkey FOREIGN KEY (contractingprocess_id) REFERENCES public.contractingprocess(id) ON DELETE CASCADE;


--
-- Name: roles roles_parties_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: user_captura
--

ALTER TABLE ONLY public.roles
    ADD CONSTRAINT roles_parties_id_fkey FOREIGN KEY (parties_id) REFERENCES public.parties(id) ON DELETE CASCADE;


--
-- Name: tags tags_contractingprocess_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: user_captura
--

ALTER TABLE ONLY public.tags
    ADD CONSTRAINT tags_contractingprocess_id_fkey FOREIGN KEY (contractingprocess_id) REFERENCES public.contractingprocess(id) ON DELETE CASCADE;


--
-- Name: tender tender_contractingprocess_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: user_captura
--

ALTER TABLE ONLY public.tender
    ADD CONSTRAINT tender_contractingprocess_id_fkey FOREIGN KEY (contractingprocess_id) REFERENCES public.contractingprocess(id) ON DELETE CASCADE;


--
-- Name: tenderamendmentchanges tenderamendmentchanges_contractingprocess_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: user_captura
--

ALTER TABLE ONLY public.tenderamendmentchanges
    ADD CONSTRAINT tenderamendmentchanges_contractingprocess_id_fkey FOREIGN KEY (contractingprocess_id) REFERENCES public.contractingprocess(id) ON DELETE CASCADE;


--
-- Name: tenderamendmentchanges tenderamendmentchanges_tender_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: user_captura
--

ALTER TABLE ONLY public.tenderamendmentchanges
    ADD CONSTRAINT tenderamendmentchanges_tender_id_fkey FOREIGN KEY (tender_id) REFERENCES public.tender(id) ON DELETE CASCADE;


--
-- Name: tenderdocuments tenderdocuments_contractingprocess_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: user_captura
--

ALTER TABLE ONLY public.tenderdocuments
    ADD CONSTRAINT tenderdocuments_contractingprocess_id_fkey FOREIGN KEY (contractingprocess_id) REFERENCES public.contractingprocess(id) ON DELETE CASCADE;


--
-- Name: tenderdocuments tenderdocuments_tender_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: user_captura
--

ALTER TABLE ONLY public.tenderdocuments
    ADD CONSTRAINT tenderdocuments_tender_id_fkey FOREIGN KEY (tender_id) REFERENCES public.tender(id) ON DELETE CASCADE;


--
-- Name: tenderitem tenderitem_contractingprocess_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: user_captura
--

ALTER TABLE ONLY public.tenderitem
    ADD CONSTRAINT tenderitem_contractingprocess_id_fkey FOREIGN KEY (contractingprocess_id) REFERENCES public.contractingprocess(id) ON DELETE CASCADE;


--
-- Name: tenderitem tenderitem_tender_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: user_captura
--

ALTER TABLE ONLY public.tenderitem
    ADD CONSTRAINT tenderitem_tender_id_fkey FOREIGN KEY (tender_id) REFERENCES public.tender(id) ON DELETE CASCADE;


--
-- Name: tenderitemadditionalclassifications tenderitemadditionalclassifications_contractingprocess_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: user_captura
--

ALTER TABLE ONLY public.tenderitemadditionalclassifications
    ADD CONSTRAINT tenderitemadditionalclassifications_contractingprocess_id_fkey FOREIGN KEY (contractingprocess_id) REFERENCES public.contractingprocess(id) ON DELETE CASCADE;


--
-- Name: tenderitemadditionalclassifications tenderitemadditionalclassifications_tenderitem_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: user_captura
--

ALTER TABLE ONLY public.tenderitemadditionalclassifications
    ADD CONSTRAINT tenderitemadditionalclassifications_tenderitem_id_fkey FOREIGN KEY (tenderitem_id) REFERENCES public.tenderitem(id) ON DELETE CASCADE;


--
-- Name: tendermilestone tendermilestone_contractingprocess_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: user_captura
--

ALTER TABLE ONLY public.tendermilestone
    ADD CONSTRAINT tendermilestone_contractingprocess_id_fkey FOREIGN KEY (contractingprocess_id) REFERENCES public.contractingprocess(id) ON DELETE CASCADE;


--
-- Name: tendermilestone tendermilestone_tender_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: user_captura
--

ALTER TABLE ONLY public.tendermilestone
    ADD CONSTRAINT tendermilestone_tender_id_fkey FOREIGN KEY (tender_id) REFERENCES public.tender(id) ON DELETE CASCADE;


--
-- Name: tendermilestonedocuments tendermilestonedocuments_contractingprocess_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: user_captura
--

ALTER TABLE ONLY public.tendermilestonedocuments
    ADD CONSTRAINT tendermilestonedocuments_contractingprocess_id_fkey FOREIGN KEY (contractingprocess_id) REFERENCES public.contractingprocess(id) ON DELETE CASCADE;


--
-- Name: tendermilestonedocuments tendermilestonedocuments_milestone_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: user_captura
--

ALTER TABLE ONLY public.tendermilestonedocuments
    ADD CONSTRAINT tendermilestonedocuments_milestone_id_fkey FOREIGN KEY (milestone_id) REFERENCES public.tendermilestone(id) ON DELETE CASCADE;


--
-- Name: tendermilestonedocuments tendermilestonedocuments_tender_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: user_captura
--

ALTER TABLE ONLY public.tendermilestonedocuments
    ADD CONSTRAINT tendermilestonedocuments_tender_id_fkey FOREIGN KEY (tender_id) REFERENCES public.tender(id) ON DELETE CASCADE;


--
-- Name: user_contractingprocess user_contractingprocess_contractingprocess_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: user_captura
--

ALTER TABLE ONLY public.user_contractingprocess
    ADD CONSTRAINT user_contractingprocess_contractingprocess_id_fkey FOREIGN KEY (contractingprocess_id) REFERENCES public.contractingprocess(id) ON DELETE CASCADE;


--
-- Name: SCHEMA public; Type: ACL; Schema: -; Owner: postgres
--

GRANT ALL ON SCHEMA public TO user_captura;


--
-- PostgreSQL database dump complete
--

