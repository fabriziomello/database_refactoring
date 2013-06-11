--
-- PostgreSQL database dump
--

SET client_encoding = 'LATIN1';
SET standard_conforming_strings = off;
SET check_function_bodies = false;
SET client_min_messages = warning;
SET escape_string_warning = off;

--
-- Name: plpgsql; Type: PROCEDURAL LANGUAGE; Schema: -; Owner: postgres
--

CREATE PROCEDURAL LANGUAGE plpgsql;


ALTER PROCEDURAL LANGUAGE plpgsql OWNER TO postgres;

SET search_path = public, pg_catalog;

SET default_tablespace = '';

SET default_with_oids = true;

--
-- Name: customer; Type: TABLE; Schema: public; Owner: postgres; Tablespace: 
--

CREATE TABLE customer (
    code integer NOT NULL,
    name character varying(40),
    phone character varying(20),
    address character varying(40),
    age integer,
    photo character varying(40),
    city character varying(40)
);


ALTER TABLE public.customer OWNER TO postgres;

--
-- Name: customer_code_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE customer_code_seq
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;


ALTER TABLE public.customer_code_seq OWNER TO postgres;

--
-- Name: customer_code_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE customer_code_seq OWNED BY customer.code;


--
-- Name: customer_code_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('customer_code_seq', 28, true);


--
-- Name: databaseconfiguration; Type: TABLE; Schema: public; Owner: postgres; Tablespace: 
--

CREATE TABLE databaseconfiguration (
    schemaversion integer NOT NULL,
    schematimestamp timestamp without time zone DEFAULT now() NOT NULL
);


ALTER TABLE public.databaseconfiguration OWNER TO postgres;

--
-- Name: databaseconfiguration_schemaversion_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE databaseconfiguration_schemaversion_seq
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;


ALTER TABLE public.databaseconfiguration_schemaversion_seq OWNER TO postgres;

--
-- Name: databaseconfiguration_schemaversion_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE databaseconfiguration_schemaversion_seq OWNED BY databaseconfiguration.schemaversion;


--
-- Name: databaseconfiguration_schemaversion_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('databaseconfiguration_schemaversion_seq', 1, true);


--
-- Name: product; Type: TABLE; Schema: public; Owner: postgres; Tablespace: 
--

CREATE TABLE product (
    code integer NOT NULL,
    description character varying(40),
    unit character(2),
    amount numeric(14,2),
    cost numeric(14,2),
    sell_price numeric(14,2)
);


ALTER TABLE public.product OWNER TO postgres;

--
-- Name: product_code_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE product_code_seq
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;


ALTER TABLE public.product_code_seq OWNER TO postgres;

--
-- Name: product_code_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE product_code_seq OWNED BY product.code;


--
-- Name: product_code_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('product_code_seq', 16, true);


--
-- Name: sales; Type: TABLE; Schema: public; Owner: postgres; Tablespace: 
--

CREATE TABLE sales (
    code integer NOT NULL,
    customer integer NOT NULL,
    product integer NOT NULL,
    date_sale date NOT NULL,
    amount numeric(14,2),
    price numeric(14,2)
);


ALTER TABLE public.sales OWNER TO postgres;


CREATE SEQUENCE sales_code_seq
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;


ALTER TABLE public.sales_code_seq OWNER TO postgres;

--
-- Name: customer_code_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE sales_code_seq OWNED BY sales.code;


ALTER TABLE sales ALTER COLUMN code SET DEFAULT nextval('sales_code_seq'::regclass);


SELECT pg_catalog.setval('customer_code_seq', (select max(code) from sales), true);

--
-- Name: customer_code_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('customer_code_seq', 28, true);



--
-- Name: code; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE customer ALTER COLUMN code SET DEFAULT nextval('customer_code_seq'::regclass);


--
-- Name: schemaversion; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE databaseconfiguration ALTER COLUMN schemaversion SET DEFAULT nextval('databaseconfiguration_schemaversion_seq'::regclass);


--
-- Name: code; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE product ALTER COLUMN code SET DEFAULT nextval('product_code_seq'::regclass);


--
-- Data for Name: customer; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO customer (code, name, phone, address, age, photo, city) VALUES (1, 'Fabrízio', '55 3434-9876', 'Rua Bento Goncalves', 26, 'images/photos/fabrizio.png', 'Arlington');
INSERT INTO customer (code, name, phone, address, age, photo, city) VALUES (2, 'Robson', '55 3434-5535', 'Rua Julio de Castilhos', 38, 'images/photos/robson.png', 'Arlington');
INSERT INTO customer (code, name, phone, address, age, photo, city) VALUES (3, 'Iuri', '55 3434-9595', 'Rua Conceicao', 23, 'images/photos/iuri.png', 'Lawrence');
INSERT INTO customer (code, name, phone, address, age, photo, city) VALUES (4, 'Anderson', '55 3434-5445', 'Rua Benjamin Constant', 29, 'images/photos/anderson.png', 'Arlington');
INSERT INTO customer (code, name, phone, address, age, photo, city) VALUES (5, 'Luiz Marcelo', '55 3434-2342', 'Av. 28 de Maio', 23, 'images/photos/luizmarcelo.png', 'Cambridge');
INSERT INTO customer (code, name, phone, address, age, photo, city) VALUES (7, 'Felipe', '55 3434-5234', 'Rua Avelino Talini', 30, 'images/photos/felipe.png', 'Arlington');
INSERT INTO customer (code, name, phone, address, age, photo, city) VALUES (8, 'Ricardo', '55 3443-3458', 'Av. dos Giovanaz', 23, 'images/photos/ricardo.png', 'Albany');
INSERT INTO customer (code, name, phone, address, age, photo, city) VALUES (9, 'Cesar', '55 3434-5656', 'Av. General Neto', 25, 'images/photos/cesar.png', 'Somerville');
INSERT INTO customer (code, name, phone, address, age, photo, city) VALUES (10, 'Karina', '55 3434-3454', 'Av. Frederico Hulck', 19, 'images/photos/karina.png', 'Arlington');
INSERT INTO customer (code, name, phone, address, age, photo, city) VALUES (11, 'Paulo', '55 3434-0404', 'Rua dos gringos', 17, 'images/photos/paulo.png', 'Albany');
INSERT INTO customer (code, name, phone, address, age, photo, city) VALUES (12, 'Dalpozzo', '55 3434-1212', 'Rua Hidraulica', 17, 'images/photos/dalpozzo.png', 'Arlington');
INSERT INTO customer (code, name, phone, address, age, photo, city) VALUES (13, 'Evandro', '55 3434-4545', 'Rua Gunsnroses', 19, 'images/photos/evandro.png', 'Albany');
INSERT INTO customer (code, name, phone, address, age, photo, city) VALUES (14, 'Sandro', '55 3434-2344', 'Av. Gumercindo Saraiva', 21, 'images/photos/sandro.png', 'Arlington');
INSERT INTO customer (code, name, phone, address, age, photo, city) VALUES (15, 'Leandro', '55 3434-9393', 'Av. Sao Rafael', 23, 'images/photos/leandro.png', 'Lawrence');
INSERT INTO customer (code, name, phone, address, age, photo, city) VALUES (16, 'Henrique', '55 3434-2424', 'Av. Internacional', 20, 'images/photos/henrique.png', 'Arlington');
INSERT INTO customer (code, name, phone, address, age, photo, city) VALUES (17, 'Marlon', '55 3434-1414', 'Av. Chevrolet', 24, 'images/photos/marlon.png', 'Arlington');
INSERT INTO customer (code, name, phone, address, age, photo, city) VALUES (18, 'Cátia', '55 3434-1814', 'Av. Bianchetti', 24, 'images/photos/catia.png', 'Arlington');
INSERT INTO customer (code, name, phone, address, age, photo, city) VALUES (19, 'Carlos', '55 3434-2822', 'Av. Teutonia', 24, 'images/photos/carlos.png', 'Arlington');
INSERT INTO customer (code, name, phone, address, age, photo, city) VALUES (20, 'Izidro', '55 3434-3332', 'Av. Figui', 24, 'images/photos/izidro.png', 'Arlington');
INSERT INTO customer (code, name, phone, address, age, photo, city) VALUES (21, 'Neuza', '55 3433-3332', 'Av. Figui', 24, 'images/photos/neuza.png', 'Cambridge');
INSERT INTO customer (code, name, phone, address, age, photo, city) VALUES (22, 'Lyndsey', '55 3443-3332', 'Av. dos Kafer', 21, 'images/photos/lyndsey.png', 'Cambridge');
INSERT INTO customer (code, name, phone, address, age, photo, city) VALUES (23, 'Airton', '55 3443-6632', 'Av. Estrelense', 24, 'images/photos/airton.png', 'Cambridge');
INSERT INTO customer (code, name, phone, address, age, photo, city) VALUES (24, 'Henrique', '55 3443-7738', 'Av. Vespasiano', 25, 'images/photos/henrique.png', 'Arlington');
INSERT INTO customer (code, name, phone, address, age, photo, city) VALUES (25, 'André', '55 3443-1128', 'Av. Alemao', 25, 'images/photos/andre.png', 'Arlington');
INSERT INTO customer (code, name, phone, address, age, photo, city) VALUES (26, 'Roberta', '55 3443-3318', 'Av. Meiense', 25, 'images/photos/roberta.png', 'Arlington');
INSERT INTO customer (code, name, phone, address, age, photo, city) VALUES (27, 'Tiago', '55 3443-9868', 'Av. dos Uhrig', 23, 'images/photos/tiago.png', 'Arlington');
INSERT INTO customer (code, name, phone, address, age, photo, city) VALUES (28, 'Eduardo', '55 3443-2298', 'Av. dos Koetz', 23, 'images/photos/eduardo.png', 'Arlington');


--
-- Data for Name: databaseconfiguration; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO databaseconfiguration (schemaversion, schematimestamp) VALUES (1, now());


--
-- Data for Name: product; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO product (code, description, unit, amount, cost, sell_price) VALUES (1, 'chocolate', 'OZ', 100.00, 2.00, 2.50);
INSERT INTO product (code, description, unit, amount, cost, sell_price) VALUES (3, 'notepad', 'PC', 1400.00, 9.00, 12.00);
INSERT INTO product (code, description, unit, amount, cost, sell_price) VALUES (5, 'pencil', 'PC', 800.00, 1.80, 1.10);
INSERT INTO product (code, description, unit, amount, cost, sell_price) VALUES (6, 'soap', 'OZ', 200.00, 0.10, 0.20);
INSERT INTO product (code, description, unit, amount, cost, sell_price) VALUES (7, 'refrigerant', 'PC', 400.00, 1.20, 1.50);
INSERT INTO product (code, description, unit, amount, cost, sell_price) VALUES (8, 'wine bottle', 'PC', 250.00, 4.60, 6.00);
INSERT INTO product (code, description, unit, amount, cost, sell_price) VALUES (9, 'orange', 'OZ', 150.00, 1.70, 2.30);
INSERT INTO product (code, description, unit, amount, cost, sell_price) VALUES (10, 'strawberry', 'OZ', 600.00, 0.90, 1.20);
INSERT INTO product (code, description, unit, amount, cost, sell_price) VALUES (11, 'pineapple', 'OZ', 400.00, 1.80, 2.20);
INSERT INTO product (code, description, unit, amount, cost, sell_price) VALUES (12, 'pants', 'PC', 300.00, 39.00, 52.00);
INSERT INTO product (code, description, unit, amount, cost, sell_price) VALUES (13, 'tshirt', 'PC', 500.00, 19.00, 34.90);
INSERT INTO product (code, description, unit, amount, cost, sell_price) VALUES (14, 'shoe', 'PC', 300.00, 29.00, 49.90);
INSERT INTO product (code, description, unit, amount, cost, sell_price) VALUES (15, 'mouse', 'PC', 200.00, 9.00, 19.90);
INSERT INTO product (code, description, unit, amount, cost, sell_price) VALUES (16, 'access point', 'PC', 100.00, 25.00, 39.90);


--
-- Data for Name: sales; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO sales (customer, product, date_sale, amount, price) VALUES (1, 1, '2003-10-31', 2.00, 23.99);
INSERT INTO sales (customer, product, date_sale, amount, price) VALUES (1, 2, '2003-10-31', 2.00, 13.99);
INSERT INTO sales (customer, product, date_sale, amount, price) VALUES (1, 3, '2003-10-31', 9.00, 11.99);
INSERT INTO sales (customer, product, date_sale, amount, price) VALUES (1, 5, '2003-10-31', 4.00, 10.00);
INSERT INTO sales (customer, product, date_sale, amount, price) VALUES (1, 7, '2003-10-31', 3.00, 15.00);
INSERT INTO sales (customer, product, date_sale, amount, price) VALUES (1, 12, '2003-10-31', 4.00, 21.00);
INSERT INTO sales (customer, product, date_sale, amount, price) VALUES (1, 13, '2003-10-31', 4.00, 13.99);
INSERT INTO sales (customer, product, date_sale, amount, price) VALUES (2, 2, '2003-10-31', 2.00, 13.99);
INSERT INTO sales (customer, product, date_sale, amount, price) VALUES (2, 4, '2003-10-31', 2.00, 0.50);
INSERT INTO sales (customer, product, date_sale, amount, price) VALUES (2, 6, '2003-10-31', 9.00, 0.20);
INSERT INTO sales (customer, product, date_sale, amount, price) VALUES (2, 8, '2003-10-31', 3.00, 20.00);
INSERT INTO sales (customer, product, date_sale, amount, price) VALUES (2, 8, '2003-11-01', 7.00, 21.00);
INSERT INTO sales (customer, product, date_sale, amount, price) VALUES (2, 14, '2003-10-31', 2.00, 11.99);
INSERT INTO sales (customer, product, date_sale, amount, price) VALUES (3, 1, '2003-10-31', 42.00, 23.99);
INSERT INTO sales (customer, product, date_sale, amount, price) VALUES (3, 3, '2003-10-31', 4.00, 11.99);
INSERT INTO sales (customer, product, date_sale, amount, price) VALUES (3, 5, '2003-10-31', 4.00, 10.00);
INSERT INTO sales (customer, product, date_sale, amount, price) VALUES (3, 7, '2003-10-31', 7.00, 15.00);
INSERT INTO sales (customer, product, date_sale, amount, price) VALUES (3, 15, '2003-10-31', 6.00, 5.00);
INSERT INTO sales (customer, product, date_sale, amount, price) VALUES (4, 2, '2003-10-31', 5.00, 13.99);
INSERT INTO sales (customer, product, date_sale, amount, price) VALUES (4, 4, '2003-10-31', 7.00, 0.50);
INSERT INTO sales (customer, product, date_sale, amount, price) VALUES (4, 6, '2003-10-31', 2.00, 0.20);
INSERT INTO sales (customer, product, date_sale, amount, price) VALUES (4, 8, '2003-10-31', 3.00, 21.00);
INSERT INTO sales (customer, product, date_sale, amount, price) VALUES (4, 16, '2003-10-31', 3.00, 16.00);
INSERT INTO sales (customer, product, date_sale, amount, price) VALUES (5, 1, '2003-10-31', 7.00, 23.99);
INSERT INTO sales (customer, product, date_sale, amount, price) VALUES (5, 3, '2003-10-31', 7.00, 13.00);
INSERT INTO sales (customer, product, date_sale, amount, price) VALUES (5, 5, '2003-10-31', 3.00, 10.00);
INSERT INTO sales (customer, product, date_sale, amount, price) VALUES (5, 7, '2003-10-31', 7.00, 15.00);
INSERT INTO sales (customer, product, date_sale, amount, price) VALUES (6, 2, '2003-10-31', 4.00, 13.99);
INSERT INTO sales (customer, product, date_sale, amount, price) VALUES (6, 4, '2003-10-31', 7.00, 0.59);
INSERT INTO sales (customer, product, date_sale, amount, price) VALUES (6, 6, '2003-10-31', 9.00, 0.20);
INSERT INTO sales (customer, product, date_sale, amount, price) VALUES (6, 8, '2003-10-31', 2.00, 21.00);
INSERT INTO sales (customer, product, date_sale, amount, price) VALUES (7, 1, '2003-10-31', 7.00, 23.00);
INSERT INTO sales (customer, product, date_sale, amount, price) VALUES (7, 3, '2003-10-31', 4.00, 13.00);
INSERT INTO sales (customer, product, date_sale, amount, price) VALUES (7, 5, '2003-10-31', 7.00, 10.59);
INSERT INTO sales (customer, product, date_sale, amount, price) VALUES (7, 7, '2003-10-31', 4.00, 15.00);
INSERT INTO sales (customer, product, date_sale, amount, price) VALUES (8, 2, '2003-10-31', 2.00, 13.99);
INSERT INTO sales (customer, product, date_sale, amount, price) VALUES (8, 4, '2003-10-31', 7.00, 0.59);
INSERT INTO sales (customer, product, date_sale, amount, price) VALUES (8, 8, '2003-10-31', 2.00, 21.00);
INSERT INTO sales (customer, product, date_sale, amount, price) VALUES (9, 1, '2003-10-31', 3.00, 23.00);
INSERT INTO sales (customer, product, date_sale, amount, price) VALUES (9, 3, '2003-10-31', 6.00, 11.99);
INSERT INTO sales (customer, product, date_sale, amount, price) VALUES (9, 5, '2003-10-31', 9.00, 10.00);
INSERT INTO sales (customer, product, date_sale, amount, price) VALUES (9, 7, '2003-10-31', 4.00, 15.00);
INSERT INTO sales (customer, product, date_sale, amount, price) VALUES (10, 2, '2003-10-31', 9.00, 15.00);
INSERT INTO sales (customer, product, date_sale, amount, price) VALUES (10, 4, '2003-10-31', 4.00, 0.59);
INSERT INTO sales (customer, product, date_sale, amount, price) VALUES (10, 6, '2003-10-31', 9.00, 0.29);
INSERT INTO sales (customer, product, date_sale, amount, price) VALUES (10, 8, '2003-10-31', 8.00, 21.00);
INSERT INTO sales (customer, product, date_sale, amount, price) VALUES (19, 1, '2006-08-08', 1.00, 0.00);


--
-- Name: customer_pk; Type: CONSTRAINT; Schema: public; Owner: postgres; Tablespace: 
--

ALTER TABLE ONLY customer
    ADD CONSTRAINT customer_pk PRIMARY KEY (code);


--
-- Name: databaseconfiguration_pk; Type: CONSTRAINT; Schema: public; Owner: postgres; Tablespace: 
--

ALTER TABLE ONLY databaseconfiguration
    ADD CONSTRAINT databaseconfiguration_pk PRIMARY KEY (schemaversion);


--
-- Name: product_pk; Type: CONSTRAINT; Schema: public; Owner: postgres; Tablespace: 
--

ALTER TABLE ONLY product
    ADD CONSTRAINT product_pk PRIMARY KEY (code);


--
-- Name: sales_pk; Type: CONSTRAINT; Schema: public; Owner: postgres; Tablespace: 
--

ALTER TABLE ONLY sales
    ADD CONSTRAINT sales_pk PRIMARY KEY (code);


--
-- Name: public; Type: ACL; Schema: -; Owner: postgres
--

REVOKE ALL ON SCHEMA public FROM PUBLIC;
REVOKE ALL ON SCHEMA public FROM postgres;
GRANT ALL ON SCHEMA public TO postgres;
GRANT ALL ON SCHEMA public TO PUBLIC;


--
-- PostgreSQL database dump complete
--

-- Import Epic Test Framework
--\i tests/epic/epic.sql
