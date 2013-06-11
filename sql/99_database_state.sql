--
-- PostgreSQL database dump
--

SET client_encoding = 'LATIN1';
SET standard_conforming_strings = off;
SET check_function_bodies = false;
SET client_min_messages = warning;
SET escape_string_warning = off;

SET search_path = public, pg_catalog;

SET default_tablespace = '';

SET default_with_oids = true;

--
-- Name: state; Type: TABLE; Schema: public; Owner: postgres; Tablespace: 
--

CREATE TABLE state (
    code character(2) NOT NULL,
    description character varying(40)
);


ALTER TABLE public.state OWNER TO postgres;

--
-- Data for Name: state; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO state (code, description) VALUES ('NY', 'New York');
INSERT INTO state (code, description) VALUES ('CA', 'California');
INSERT INTO state (code, description) VALUES ('CO', 'Colorado');
INSERT INTO state (code, description) VALUES ('MA', 'Massachusetts');


--
-- Name: state_code_pk; Type: CONSTRAINT; Schema: public; Owner: postgres; Tablespace: 
--

ALTER TABLE ONLY state
    ADD CONSTRAINT state_pk PRIMARY KEY (code);


--
-- PostgreSQL database dump complete
--

