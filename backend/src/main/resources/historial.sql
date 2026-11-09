SELECT p.id_persona, p.nombres, p.primer_apellido, p.segundo_apellido,
       a.id_dosis_aplicada, v.nombre AS vacuna, d.numero_dosis,
       a.fecha_aplicacion, a.lote, u.nombre AS unidad
FROM persona p
LEFT JOIN dosis_aplicada a ON a.id_persona = p.id_persona
LEFT JOIN esquema_detalle d ON d.id_esquema_detalle = a.id_esquema_detalle
LEFT JOIN vacuna v ON v.id_vacuna = d.id_vacuna
LEFT JOIN unidad_salud u ON u.id_unidad_salud = a.id_unidad_salud
WHERE p.id_persona = :id
ORDER BY a.fecha_aplicacion, a.id_dosis_aplicada
