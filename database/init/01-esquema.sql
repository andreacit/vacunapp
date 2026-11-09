BEGIN;
CREATE TABLE rol (
    id_rol SMALLSERIAL PRIMARY KEY,
    codigo VARCHAR(30) NOT NULL UNIQUE CHECK (codigo IN ('ADMINISTRADOR','PERSONAL_SALUD','CONSULTA')),
    nombre VARCHAR(60) NOT NULL CHECK (btrim(nombre) <> '')
);
CREATE TABLE unidad_salud (
    id_unidad_salud SERIAL PRIMARY KEY,
    codigo VARCHAR(30) NOT NULL UNIQUE CHECK (btrim(codigo) <> ''),
    nombre VARCHAR(150) NOT NULL CHECK (btrim(nombre) <> ''),
    direccion VARCHAR(250),
    activo BOOLEAN NOT NULL DEFAULT TRUE
);
CREATE TABLE vacuna (
    id_vacuna SERIAL PRIMARY KEY,
    codigo VARCHAR(30) NOT NULL UNIQUE CHECK (btrim(codigo) <> ''),
    nombre VARCHAR(150) NOT NULL CHECK (btrim(nombre) <> ''),
    descripcion TEXT,
    activo BOOLEAN NOT NULL DEFAULT TRUE
);
CREATE TABLE esquema (
    id_esquema SERIAL PRIMARY KEY,
    codigo VARCHAR(30) NOT NULL CHECK (btrim(codigo) <> ''),
    version SMALLINT NOT NULL CHECK (version > 0),
    nombre VARCHAR(150) NOT NULL CHECK (btrim(nombre) <> ''),
    descripcion TEXT,
    activo BOOLEAN NOT NULL DEFAULT TRUE,
    UNIQUE (codigo, version)
);
CREATE TABLE persona (
    id_persona BIGSERIAL PRIMARY KEY,
    curp VARCHAR(18) UNIQUE CHECK (char_length(curp) = 18 AND curp = upper(curp)),
    nombres VARCHAR(100) NOT NULL CHECK (btrim(nombres) <> ''),
    primer_apellido VARCHAR(100) NOT NULL CHECK (btrim(primer_apellido) <> ''),
    segundo_apellido VARCHAR(100),
    fecha_nacimiento DATE NOT NULL,
    sexo VARCHAR(2) NOT NULL CHECK (sexo IN ('F','M','ND')),
    id_unidad_salud INTEGER REFERENCES unidad_salud ON DELETE RESTRICT,
    id_esquema INTEGER NOT NULL REFERENCES esquema ON DELETE RESTRICT,
    activo BOOLEAN NOT NULL DEFAULT TRUE
);
CREATE TABLE usuario (
    id_usuario BIGSERIAL PRIMARY KEY,
    correo VARCHAR(254) NOT NULL UNIQUE CHECK (correo <> '' AND correo = lower(btrim(correo))),
    contrasena_hash VARCHAR(255) NOT NULL CHECK (btrim(contrasena_hash) <> ''),
    id_rol SMALLINT NOT NULL REFERENCES rol ON DELETE RESTRICT,
    id_unidad_salud INTEGER REFERENCES unidad_salud ON DELETE RESTRICT,
    id_persona BIGINT UNIQUE REFERENCES persona ON DELETE RESTRICT,
    activo BOOLEAN NOT NULL DEFAULT TRUE,
    creado_en TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);
CREATE TABLE esquema_detalle (
    id_esquema_detalle SERIAL PRIMARY KEY,
    id_esquema INTEGER NOT NULL REFERENCES esquema ON DELETE RESTRICT,
    id_vacuna INTEGER NOT NULL REFERENCES vacuna ON DELETE RESTRICT,
    numero_dosis SMALLINT NOT NULL CHECK (numero_dosis > 0),
    edad_objetivo_meses INTEGER NOT NULL CHECK (edad_objetivo_meses >= 0),
    intervalo_minimo_dias INTEGER,
    plazo_atraso_dias INTEGER NOT NULL CHECK (plazo_atraso_dias >= 0),
    CHECK ((numero_dosis = 1 AND intervalo_minimo_dias IS NULL)
        OR (numero_dosis > 1 AND intervalo_minimo_dias IS NOT NULL AND intervalo_minimo_dias >= 0)),
    UNIQUE (id_esquema, id_vacuna, numero_dosis)
);
CREATE TABLE dosis_aplicada (
    id_dosis_aplicada BIGSERIAL PRIMARY KEY,
    id_persona BIGINT NOT NULL REFERENCES persona ON DELETE RESTRICT,
    id_esquema_detalle INTEGER NOT NULL REFERENCES esquema_detalle ON DELETE RESTRICT,
    id_usuario_registrador BIGINT NOT NULL REFERENCES usuario ON DELETE RESTRICT,
    id_unidad_salud INTEGER NOT NULL REFERENCES unidad_salud ON DELETE RESTRICT,
    fecha_aplicacion DATE NOT NULL,
    lote VARCHAR(50) NOT NULL CHECK (btrim(lote) <> ''),
    registrado_en TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    UNIQUE (id_persona, id_esquema_detalle)
);
COMMIT;
