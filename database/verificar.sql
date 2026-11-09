-- Tablas del esquema de VacunApp y sus cantidades.
SELECT tabla, registros
FROM (VALUES
    ('rol', (SELECT count(*) FROM rol)),
    ('unidad_salud', (SELECT count(*) FROM unidad_salud)),
    ('usuario', (SELECT count(*) FROM usuario)),
    ('persona', (SELECT count(*) FROM persona)),
    ('vacuna', (SELECT count(*) FROM vacuna)),
    ('esquema', (SELECT count(*) FROM esquema)),
    ('esquema_detalle', (SELECT count(*) FROM esquema_detalle)),
    ('dosis_aplicada', (SELECT count(*) FROM dosis_aplicada))
) AS conteos(tabla, registros);

-- Restricciones declaradas y sus definiciones.
SELECT conrelid::regclass AS tabla, pg_get_constraintdef(oid) AS restriccion
FROM pg_constraint
WHERE connamespace = 'public'::regnamespace
  AND contype IN ('p', 'f', 'u', 'c')
ORDER BY conrelid::regclass::text, contype, conname;

-- Historial de la persona de demostración.
SELECT p.id_persona, p.nombres, v.nombre AS vacuna, d.numero_dosis,
       a.fecha_aplicacion, a.lote, u.nombre AS unidad
FROM persona p
JOIN dosis_aplicada a ON a.id_persona = p.id_persona
JOIN esquema_detalle d ON d.id_esquema_detalle = a.id_esquema_detalle
JOIN vacuna v ON v.id_vacuna = d.id_vacuna
JOIN unidad_salud u ON u.id_unidad_salud = a.id_unidad_salud
WHERE p.id_persona = 1
ORDER BY a.fecha_aplicacion, a.id_dosis_aplicada;

-- Dosis requeridas que todavía no tienen una aplicación.
SELECT p.id_persona, v.nombre AS vacuna, d.numero_dosis
FROM persona p
JOIN esquema_detalle d ON d.id_esquema = p.id_esquema
JOIN vacuna v ON v.id_vacuna = d.id_vacuna
LEFT JOIN dosis_aplicada a
    ON a.id_persona = p.id_persona AND a.id_esquema_detalle = d.id_esquema_detalle
WHERE p.id_persona = 15 AND a.id_dosis_aplicada IS NULL
ORDER BY v.nombre, d.numero_dosis;
