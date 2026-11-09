--
-- PostgreSQL database dump
--

\restrict bM4PJKMu3rDfBbfgW3CwzT35TpZdmxehEt42ij73yfzVE3mhkQxjpNTHqOL6COG

-- Dumped from database version 17.11 (Debian 17.11-1.pgdg13+2)
-- Dumped by pg_dump version 17.11 (Debian 17.11-1.pgdg13+2)

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

SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: dosis_aplicada; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.dosis_aplicada (
    id_dosis_aplicada bigint NOT NULL,
    id_persona bigint NOT NULL,
    id_esquema_detalle integer NOT NULL,
    id_usuario_registrador bigint NOT NULL,
    id_unidad_salud integer NOT NULL,
    fecha_aplicacion date NOT NULL,
    lote character varying(50) NOT NULL,
    registrado_en timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    CONSTRAINT dosis_aplicada_lote_check CHECK ((btrim((lote)::text) <> ''::text))
);


--
-- Name: dosis_aplicada_id_dosis_aplicada_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.dosis_aplicada_id_dosis_aplicada_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: dosis_aplicada_id_dosis_aplicada_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.dosis_aplicada_id_dosis_aplicada_seq OWNED BY public.dosis_aplicada.id_dosis_aplicada;


--
-- Name: esquema; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.esquema (
    id_esquema integer NOT NULL,
    codigo character varying(30) NOT NULL,
    version smallint NOT NULL,
    nombre character varying(150) NOT NULL,
    descripcion text,
    activo boolean DEFAULT true NOT NULL,
    CONSTRAINT esquema_codigo_check CHECK ((btrim((codigo)::text) <> ''::text)),
    CONSTRAINT esquema_nombre_check CHECK ((btrim((nombre)::text) <> ''::text)),
    CONSTRAINT esquema_version_check CHECK ((version > 0))
);


--
-- Name: esquema_detalle; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.esquema_detalle (
    id_esquema_detalle integer NOT NULL,
    id_esquema integer NOT NULL,
    id_vacuna integer NOT NULL,
    numero_dosis smallint NOT NULL,
    edad_objetivo_meses integer NOT NULL,
    intervalo_minimo_dias integer,
    plazo_atraso_dias integer NOT NULL,
    CONSTRAINT esquema_detalle_check CHECK ((((numero_dosis = 1) AND (intervalo_minimo_dias IS NULL)) OR ((numero_dosis > 1) AND (intervalo_minimo_dias IS NOT NULL) AND (intervalo_minimo_dias >= 0)))),
    CONSTRAINT esquema_detalle_edad_objetivo_meses_check CHECK ((edad_objetivo_meses >= 0)),
    CONSTRAINT esquema_detalle_numero_dosis_check CHECK ((numero_dosis > 0)),
    CONSTRAINT esquema_detalle_plazo_atraso_dias_check CHECK ((plazo_atraso_dias >= 0))
);


--
-- Name: esquema_detalle_id_esquema_detalle_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.esquema_detalle_id_esquema_detalle_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: esquema_detalle_id_esquema_detalle_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.esquema_detalle_id_esquema_detalle_seq OWNED BY public.esquema_detalle.id_esquema_detalle;


--
-- Name: esquema_id_esquema_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.esquema_id_esquema_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: esquema_id_esquema_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.esquema_id_esquema_seq OWNED BY public.esquema.id_esquema;


--
-- Name: persona; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.persona (
    id_persona bigint NOT NULL,
    curp character varying(18),
    nombres character varying(100) NOT NULL,
    primer_apellido character varying(100) NOT NULL,
    segundo_apellido character varying(100),
    fecha_nacimiento date NOT NULL,
    sexo character varying(2) NOT NULL,
    id_unidad_salud integer,
    id_esquema integer NOT NULL,
    activo boolean DEFAULT true NOT NULL,
    CONSTRAINT persona_curp_check CHECK (((char_length((curp)::text) = 18) AND ((curp)::text = upper((curp)::text)))),
    CONSTRAINT persona_nombres_check CHECK ((btrim((nombres)::text) <> ''::text)),
    CONSTRAINT persona_primer_apellido_check CHECK ((btrim((primer_apellido)::text) <> ''::text)),
    CONSTRAINT persona_sexo_check CHECK (((sexo)::text = ANY ((ARRAY['F'::character varying, 'M'::character varying, 'ND'::character varying])::text[])))
);


--
-- Name: persona_id_persona_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.persona_id_persona_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: persona_id_persona_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.persona_id_persona_seq OWNED BY public.persona.id_persona;


--
-- Name: rol; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.rol (
    id_rol smallint NOT NULL,
    codigo character varying(30) NOT NULL,
    nombre character varying(60) NOT NULL,
    CONSTRAINT rol_codigo_check CHECK (((codigo)::text = ANY ((ARRAY['ADMINISTRADOR'::character varying, 'PERSONAL_SALUD'::character varying, 'CONSULTA'::character varying])::text[]))),
    CONSTRAINT rol_nombre_check CHECK ((btrim((nombre)::text) <> ''::text))
);


--
-- Name: rol_id_rol_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.rol_id_rol_seq
    AS smallint
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: rol_id_rol_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.rol_id_rol_seq OWNED BY public.rol.id_rol;


--
-- Name: unidad_salud; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.unidad_salud (
    id_unidad_salud integer NOT NULL,
    codigo character varying(30) NOT NULL,
    nombre character varying(150) NOT NULL,
    direccion character varying(250),
    activo boolean DEFAULT true NOT NULL,
    CONSTRAINT unidad_salud_codigo_check CHECK ((btrim((codigo)::text) <> ''::text)),
    CONSTRAINT unidad_salud_nombre_check CHECK ((btrim((nombre)::text) <> ''::text))
);


--
-- Name: unidad_salud_id_unidad_salud_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.unidad_salud_id_unidad_salud_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: unidad_salud_id_unidad_salud_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.unidad_salud_id_unidad_salud_seq OWNED BY public.unidad_salud.id_unidad_salud;


--
-- Name: usuario; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.usuario (
    id_usuario bigint NOT NULL,
    correo character varying(254) NOT NULL,
    contrasena_hash character varying(255) NOT NULL,
    id_rol smallint NOT NULL,
    id_unidad_salud integer,
    id_persona bigint,
    activo boolean DEFAULT true NOT NULL,
    creado_en timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    CONSTRAINT usuario_contrasena_hash_check CHECK ((btrim((contrasena_hash)::text) <> ''::text)),
    CONSTRAINT usuario_correo_check CHECK ((((correo)::text <> ''::text) AND ((correo)::text = lower(btrim((correo)::text)))))
);


--
-- Name: usuario_id_usuario_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.usuario_id_usuario_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: usuario_id_usuario_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.usuario_id_usuario_seq OWNED BY public.usuario.id_usuario;


--
-- Name: vacuna; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.vacuna (
    id_vacuna integer NOT NULL,
    codigo character varying(30) NOT NULL,
    nombre character varying(150) NOT NULL,
    descripcion text,
    activo boolean DEFAULT true NOT NULL,
    CONSTRAINT vacuna_codigo_check CHECK ((btrim((codigo)::text) <> ''::text)),
    CONSTRAINT vacuna_nombre_check CHECK ((btrim((nombre)::text) <> ''::text))
);


--
-- Name: vacuna_id_vacuna_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.vacuna_id_vacuna_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: vacuna_id_vacuna_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.vacuna_id_vacuna_seq OWNED BY public.vacuna.id_vacuna;


--
-- Name: dosis_aplicada id_dosis_aplicada; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.dosis_aplicada ALTER COLUMN id_dosis_aplicada SET DEFAULT nextval('public.dosis_aplicada_id_dosis_aplicada_seq'::regclass);


--
-- Name: esquema id_esquema; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.esquema ALTER COLUMN id_esquema SET DEFAULT nextval('public.esquema_id_esquema_seq'::regclass);


--
-- Name: esquema_detalle id_esquema_detalle; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.esquema_detalle ALTER COLUMN id_esquema_detalle SET DEFAULT nextval('public.esquema_detalle_id_esquema_detalle_seq'::regclass);


--
-- Name: persona id_persona; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.persona ALTER COLUMN id_persona SET DEFAULT nextval('public.persona_id_persona_seq'::regclass);


--
-- Name: rol id_rol; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.rol ALTER COLUMN id_rol SET DEFAULT nextval('public.rol_id_rol_seq'::regclass);


--
-- Name: unidad_salud id_unidad_salud; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.unidad_salud ALTER COLUMN id_unidad_salud SET DEFAULT nextval('public.unidad_salud_id_unidad_salud_seq'::regclass);


--
-- Name: usuario id_usuario; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.usuario ALTER COLUMN id_usuario SET DEFAULT nextval('public.usuario_id_usuario_seq'::regclass);


--
-- Name: vacuna id_vacuna; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.vacuna ALTER COLUMN id_vacuna SET DEFAULT nextval('public.vacuna_id_vacuna_seq'::regclass);


--
-- Data for Name: dosis_aplicada; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.dosis_aplicada (id_dosis_aplicada, id_persona, id_esquema_detalle, id_usuario_registrador, id_unidad_salud, fecha_aplicacion, lote, registrado_en) FROM stdin;
1	1	1	1	1	2023-01-01	DEMO-1	2026-11-09 13:15:12.762951+00
2	11	1	1	1	2023-01-01	DEMO-1	2026-11-09 13:15:12.762951+00
3	1	2	1	1	2023-03-02	DEMO-2	2026-11-09 13:15:12.762951+00
4	2	3	2	2	2023-01-01	DEMO-1	2026-11-09 13:15:12.762951+00
5	12	3	2	2	2023-01-01	DEMO-1	2026-11-09 13:15:12.762951+00
6	2	4	2	2	2023-03-02	DEMO-2	2026-11-09 13:15:12.762951+00
7	3	5	3	3	2023-01-01	DEMO-1	2026-11-09 13:15:12.762951+00
8	13	5	3	3	2023-01-01	DEMO-1	2026-11-09 13:15:12.762951+00
9	3	6	3	3	2023-03-02	DEMO-2	2026-11-09 13:15:12.762951+00
10	4	7	4	4	2023-01-01	DEMO-1	2026-11-09 13:15:12.762951+00
11	14	7	4	4	2023-01-01	DEMO-1	2026-11-09 13:15:12.762951+00
12	4	8	4	4	2023-03-02	DEMO-2	2026-11-09 13:15:12.762951+00
13	5	9	5	5	2023-01-01	DEMO-1	2026-11-09 13:15:12.762951+00
14	5	10	5	5	2023-03-02	DEMO-2	2026-11-09 13:15:12.762951+00
15	6	11	6	6	2023-01-01	DEMO-1	2026-11-09 13:15:12.762951+00
16	6	12	6	6	2023-03-02	DEMO-2	2026-11-09 13:15:12.762951+00
17	7	13	7	7	2023-01-01	DEMO-1	2026-11-09 13:15:12.762951+00
18	8	15	8	8	2023-01-01	DEMO-1	2026-11-09 13:15:12.762951+00
19	9	17	9	9	2023-01-01	DEMO-1	2026-11-09 13:15:12.762951+00
20	10	19	10	10	2023-01-01	DEMO-1	2026-11-09 13:15:12.762951+00
\.


--
-- Data for Name: esquema; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.esquema (id_esquema, codigo, version, nombre, descripcion, activo) FROM stdin;
1	E1	1	Esquema de prueba 1	\N	t
2	E2	1	Esquema de prueba 2	\N	t
3	E3	1	Esquema de prueba 3	\N	t
4	E4	1	Esquema de prueba 4	\N	t
5	E5	1	Esquema de prueba 5	\N	t
6	E6	1	Esquema de prueba 6	\N	t
7	E7	1	Esquema de prueba 7	\N	t
8	E8	1	Esquema de prueba 8	\N	t
9	E9	1	Esquema de prueba 9	\N	t
10	E10	1	Esquema de prueba 10	\N	t
\.


--
-- Data for Name: esquema_detalle; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.esquema_detalle (id_esquema_detalle, id_esquema, id_vacuna, numero_dosis, edad_objetivo_meses, intervalo_minimo_dias, plazo_atraso_dias) FROM stdin;
1	1	1	1	12	\N	30
2	1	1	2	14	30	30
3	2	1	1	12	\N	30
4	2	1	2	14	30	30
5	3	3	1	12	\N	30
6	3	3	2	14	30	30
7	4	4	1	12	\N	30
8	4	4	2	14	30	30
9	5	5	1	12	\N	30
10	5	5	2	14	30	30
11	6	6	1	12	\N	30
12	6	6	2	14	30	30
13	7	7	1	12	\N	30
14	7	7	2	14	30	30
15	8	8	1	12	\N	30
16	8	8	2	14	30	30
17	9	9	1	12	\N	30
18	9	9	2	14	30	30
19	10	10	1	12	\N	30
20	10	10	2	14	30	30
\.


--
-- Data for Name: persona; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.persona (id_persona, curp, nombres, primer_apellido, segundo_apellido, fecha_nacimiento, sexo, id_unidad_salud, id_esquema, activo) FROM stdin;
1	\N	Persona 1	Demostración	\N	2020-01-01	ND	1	1	t
2	\N	Persona 2	Demostración	\N	2020-01-01	ND	2	2	t
3	\N	Persona 3	Demostración	\N	2020-01-01	ND	3	3	t
4	\N	Persona 4	Demostración	\N	2020-01-01	ND	4	4	t
5	\N	Persona 5	Demostración	\N	2020-01-01	ND	5	5	t
6	\N	Persona 6	Demostración	\N	2020-01-01	ND	6	6	t
7	\N	Persona 7	Demostración	\N	2020-01-01	ND	7	7	t
8	\N	Persona 8	Demostración	\N	2020-01-01	ND	8	8	t
9	\N	Persona 9	Demostración	\N	2020-01-01	ND	9	9	t
10	\N	Persona 10	Demostración	\N	2020-01-01	ND	10	10	t
11	\N	Persona 11	Demostración	\N	2020-01-01	ND	1	1	t
12	\N	Persona 12	Demostración	\N	2020-01-01	ND	2	2	t
13	\N	Persona 13	Demostración	\N	2020-01-01	ND	3	3	t
14	\N	Persona 14	Demostración	\N	2020-01-01	ND	4	4	t
15	\N	Persona 15	Demostración	\N	2020-01-01	ND	5	5	t
\.


--
-- Data for Name: rol; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.rol (id_rol, codigo, nombre) FROM stdin;
1	ADMINISTRADOR	Administración
2	PERSONAL_SALUD	Personal de salud
3	CONSULTA	Consulta
\.


--
-- Data for Name: unidad_salud; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.unidad_salud (id_unidad_salud, codigo, nombre, direccion, activo) FROM stdin;
1	U1	Unidad de prueba 1	\N	t
2	U2	Unidad de prueba 2	\N	t
3	U3	Unidad de prueba 3	\N	t
4	U4	Unidad de prueba 4	\N	t
5	U5	Unidad de prueba 5	\N	t
6	U6	Unidad de prueba 6	\N	t
7	U7	Unidad de prueba 7	\N	t
8	U8	Unidad de prueba 8	\N	t
9	U9	Unidad de prueba 9	\N	t
10	U10	Unidad de prueba 10	\N	t
\.


--
-- Data for Name: usuario; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.usuario (id_usuario, correo, contrasena_hash, id_rol, id_unidad_salud, id_persona, activo, creado_en) FROM stdin;
1	registro1@example.test	NO_HABILITADO	2	1	\N	t	2026-11-09 13:15:12.762951+00
2	registro2@example.test	NO_HABILITADO	2	2	\N	t	2026-11-09 13:15:12.762951+00
3	registro3@example.test	NO_HABILITADO	2	3	\N	t	2026-11-09 13:15:12.762951+00
4	registro4@example.test	NO_HABILITADO	2	4	\N	t	2026-11-09 13:15:12.762951+00
5	registro5@example.test	NO_HABILITADO	2	5	\N	t	2026-11-09 13:15:12.762951+00
6	registro6@example.test	NO_HABILITADO	2	6	\N	t	2026-11-09 13:15:12.762951+00
7	registro7@example.test	NO_HABILITADO	2	7	\N	t	2026-11-09 13:15:12.762951+00
8	registro8@example.test	NO_HABILITADO	2	8	\N	t	2026-11-09 13:15:12.762951+00
9	registro9@example.test	NO_HABILITADO	2	9	\N	t	2026-11-09 13:15:12.762951+00
10	registro10@example.test	NO_HABILITADO	2	10	\N	t	2026-11-09 13:15:12.762951+00
\.


--
-- Data for Name: vacuna; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.vacuna (id_vacuna, codigo, nombre, descripcion, activo) FROM stdin;
1	V1	Vacuna de prueba 1	\N	t
2	V2	Vacuna de prueba 2	\N	t
3	V3	Vacuna de prueba 3	\N	t
4	V4	Vacuna de prueba 4	\N	t
5	V5	Vacuna de prueba 5	\N	t
6	V6	Vacuna de prueba 6	\N	t
7	V7	Vacuna de prueba 7	\N	t
8	V8	Vacuna de prueba 8	\N	t
9	V9	Vacuna de prueba 9	\N	t
10	V10	Vacuna de prueba 10	\N	t
\.


--
-- Name: dosis_aplicada_id_dosis_aplicada_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.dosis_aplicada_id_dosis_aplicada_seq', 20, true);


--
-- Name: esquema_detalle_id_esquema_detalle_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.esquema_detalle_id_esquema_detalle_seq', 20, true);


--
-- Name: esquema_id_esquema_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.esquema_id_esquema_seq', 10, true);


--
-- Name: persona_id_persona_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.persona_id_persona_seq', 15, true);


--
-- Name: rol_id_rol_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.rol_id_rol_seq', 3, true);


--
-- Name: unidad_salud_id_unidad_salud_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.unidad_salud_id_unidad_salud_seq', 10, true);


--
-- Name: usuario_id_usuario_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.usuario_id_usuario_seq', 10, true);


--
-- Name: vacuna_id_vacuna_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.vacuna_id_vacuna_seq', 10, true);


--
-- Name: dosis_aplicada dosis_aplicada_id_persona_id_esquema_detalle_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.dosis_aplicada
    ADD CONSTRAINT dosis_aplicada_id_persona_id_esquema_detalle_key UNIQUE (id_persona, id_esquema_detalle);


--
-- Name: dosis_aplicada dosis_aplicada_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.dosis_aplicada
    ADD CONSTRAINT dosis_aplicada_pkey PRIMARY KEY (id_dosis_aplicada);


--
-- Name: esquema esquema_codigo_version_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.esquema
    ADD CONSTRAINT esquema_codigo_version_key UNIQUE (codigo, version);


--
-- Name: esquema_detalle esquema_detalle_id_esquema_id_vacuna_numero_dosis_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.esquema_detalle
    ADD CONSTRAINT esquema_detalle_id_esquema_id_vacuna_numero_dosis_key UNIQUE (id_esquema, id_vacuna, numero_dosis);


--
-- Name: esquema_detalle esquema_detalle_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.esquema_detalle
    ADD CONSTRAINT esquema_detalle_pkey PRIMARY KEY (id_esquema_detalle);


--
-- Name: esquema esquema_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.esquema
    ADD CONSTRAINT esquema_pkey PRIMARY KEY (id_esquema);


--
-- Name: persona persona_curp_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.persona
    ADD CONSTRAINT persona_curp_key UNIQUE (curp);


--
-- Name: persona persona_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.persona
    ADD CONSTRAINT persona_pkey PRIMARY KEY (id_persona);


--
-- Name: rol rol_codigo_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.rol
    ADD CONSTRAINT rol_codigo_key UNIQUE (codigo);


--
-- Name: rol rol_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.rol
    ADD CONSTRAINT rol_pkey PRIMARY KEY (id_rol);


--
-- Name: unidad_salud unidad_salud_codigo_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.unidad_salud
    ADD CONSTRAINT unidad_salud_codigo_key UNIQUE (codigo);


--
-- Name: unidad_salud unidad_salud_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.unidad_salud
    ADD CONSTRAINT unidad_salud_pkey PRIMARY KEY (id_unidad_salud);


--
-- Name: usuario usuario_correo_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.usuario
    ADD CONSTRAINT usuario_correo_key UNIQUE (correo);


--
-- Name: usuario usuario_id_persona_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.usuario
    ADD CONSTRAINT usuario_id_persona_key UNIQUE (id_persona);


--
-- Name: usuario usuario_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.usuario
    ADD CONSTRAINT usuario_pkey PRIMARY KEY (id_usuario);


--
-- Name: vacuna vacuna_codigo_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.vacuna
    ADD CONSTRAINT vacuna_codigo_key UNIQUE (codigo);


--
-- Name: vacuna vacuna_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.vacuna
    ADD CONSTRAINT vacuna_pkey PRIMARY KEY (id_vacuna);


--
-- Name: dosis_aplicada dosis_aplicada_id_esquema_detalle_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.dosis_aplicada
    ADD CONSTRAINT dosis_aplicada_id_esquema_detalle_fkey FOREIGN KEY (id_esquema_detalle) REFERENCES public.esquema_detalle(id_esquema_detalle) ON DELETE RESTRICT;


--
-- Name: dosis_aplicada dosis_aplicada_id_persona_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.dosis_aplicada
    ADD CONSTRAINT dosis_aplicada_id_persona_fkey FOREIGN KEY (id_persona) REFERENCES public.persona(id_persona) ON DELETE RESTRICT;


--
-- Name: dosis_aplicada dosis_aplicada_id_unidad_salud_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.dosis_aplicada
    ADD CONSTRAINT dosis_aplicada_id_unidad_salud_fkey FOREIGN KEY (id_unidad_salud) REFERENCES public.unidad_salud(id_unidad_salud) ON DELETE RESTRICT;


--
-- Name: dosis_aplicada dosis_aplicada_id_usuario_registrador_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.dosis_aplicada
    ADD CONSTRAINT dosis_aplicada_id_usuario_registrador_fkey FOREIGN KEY (id_usuario_registrador) REFERENCES public.usuario(id_usuario) ON DELETE RESTRICT;


--
-- Name: esquema_detalle esquema_detalle_id_esquema_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.esquema_detalle
    ADD CONSTRAINT esquema_detalle_id_esquema_fkey FOREIGN KEY (id_esquema) REFERENCES public.esquema(id_esquema) ON DELETE RESTRICT;


--
-- Name: esquema_detalle esquema_detalle_id_vacuna_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.esquema_detalle
    ADD CONSTRAINT esquema_detalle_id_vacuna_fkey FOREIGN KEY (id_vacuna) REFERENCES public.vacuna(id_vacuna) ON DELETE RESTRICT;


--
-- Name: persona persona_id_esquema_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.persona
    ADD CONSTRAINT persona_id_esquema_fkey FOREIGN KEY (id_esquema) REFERENCES public.esquema(id_esquema) ON DELETE RESTRICT;


--
-- Name: persona persona_id_unidad_salud_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.persona
    ADD CONSTRAINT persona_id_unidad_salud_fkey FOREIGN KEY (id_unidad_salud) REFERENCES public.unidad_salud(id_unidad_salud) ON DELETE RESTRICT;


--
-- Name: usuario usuario_id_persona_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.usuario
    ADD CONSTRAINT usuario_id_persona_fkey FOREIGN KEY (id_persona) REFERENCES public.persona(id_persona) ON DELETE RESTRICT;


--
-- Name: usuario usuario_id_rol_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.usuario
    ADD CONSTRAINT usuario_id_rol_fkey FOREIGN KEY (id_rol) REFERENCES public.rol(id_rol) ON DELETE RESTRICT;


--
-- Name: usuario usuario_id_unidad_salud_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.usuario
    ADD CONSTRAINT usuario_id_unidad_salud_fkey FOREIGN KEY (id_unidad_salud) REFERENCES public.unidad_salud(id_unidad_salud) ON DELETE RESTRICT;


--
-- PostgreSQL database dump complete
--

\unrestrict bM4PJKMu3rDfBbfgW3CwzT35TpZdmxehEt42ij73yfzVE3mhkQxjpNTHqOL6COG

