-- Los códigos, personas, edades objetivo e intervalos son ficticios.
BEGIN;
INSERT INTO rol (codigo, nombre) VALUES
    ('ADMINISTRADOR','Administración'), ('PERSONAL_SALUD','Personal de salud'), ('CONSULTA','Consulta');

INSERT INTO unidad_salud (codigo, nombre)
SELECT 'U' || n, 'Unidad de prueba ' || n FROM generate_series(1,10) AS n;
INSERT INTO vacuna (codigo, nombre)
SELECT 'V' || n, 'Vacuna de prueba ' || n FROM generate_series(1,10) AS n;
INSERT INTO esquema (codigo, version, nombre)
SELECT 'E' || n, 1, 'Esquema de prueba ' || n FROM generate_series(1,10) AS n;

INSERT INTO persona (nombres, primer_apellido, fecha_nacimiento, sexo, id_unidad_salud, id_esquema)
SELECT 'Persona ' || n, 'Demostración', DATE '2020-01-01', 'ND', u.id_unidad_salud, e.id_esquema
FROM generate_series(1,15) AS n
JOIN unidad_salud u ON u.codigo = 'U' || ((n-1)%10+1)
JOIN esquema e ON e.codigo = 'E' || ((n-1)%10+1)
ORDER BY n;

-- Estas cuentas de prueba no tienen una contraseña utilizable.
INSERT INTO usuario (correo, contrasena_hash, id_rol, id_unidad_salud)
SELECT 'registro' || u.id_unidad_salud || '@example.test', 'NO_HABILITADO', r.id_rol, u.id_unidad_salud
FROM unidad_salud u CROSS JOIN rol r WHERE r.codigo = 'PERSONAL_SALUD';

INSERT INTO esquema_detalle (id_esquema, id_vacuna, numero_dosis, edad_objetivo_meses, intervalo_minimo_dias, plazo_atraso_dias)
SELECT e.id_esquema, v.id_vacuna, d.numero, d.edad, d.intervalo, 30
FROM esquema e
JOIN vacuna v ON v.codigo = 'V' || CASE WHEN e.codigo = 'E2' THEN '1' ELSE substring(e.codigo FROM 2) END
CROSS JOIN (VALUES (1,12,NULL::integer), (2,14,30)) AS d(numero, edad, intervalo);

INSERT INTO dosis_aplicada (id_persona, id_esquema_detalle, id_usuario_registrador, id_unidad_salud, fecha_aplicacion, lote)
SELECT p.id_persona, d.id_esquema_detalle, u.id_usuario, u.id_unidad_salud,
       DATE '2023-01-01' + (d.numero_dosis - 1) * 60, 'DEMO-' || d.numero_dosis
FROM persona p
JOIN esquema_detalle d ON d.id_esquema = p.id_esquema
JOIN usuario u ON u.id_unidad_salud = p.id_unidad_salud
WHERE p.id_persona < 15 AND (d.numero_dosis = 1 OR p.id_persona <= 6);
COMMIT;
