package mx.vacunapp.personas

import java.time.LocalDate
import java.time.ZoneId
import java.util.Locale
import mx.vacunapp.seguridad.Cuenta
import org.springframework.dao.DuplicateKeyException
import org.springframework.http.HttpStatus
import org.springframework.jdbc.core.simple.JdbcClient
import org.springframework.stereotype.Service
import org.springframework.transaction.support.TransactionTemplate
import org.springframework.web.server.ResponseStatusException

@Service
class Personas(private val jdbc: JdbcClient, private val transacciones: TransactionTemplate) {
    fun buscar(consulta: String, pagina: Int, alcance: Alcance): PaginaPersonas {
        if (consulta.length > 150 || pagina <= 0) invalido("La búsqueda o el número de página no son válidos.")
        val personas = alcance.preparar(jdbc.sql("""
            SELECT p.id_persona, concat_ws(' ', p.nombres, p.primer_apellido, p.segundo_apellido) AS nombre,
                   u.nombre AS unidad, e.nombre AS esquema
            FROM persona p
            LEFT JOIN unidad_salud u USING (id_unidad_salud)
            JOIN esquema e USING (id_esquema)
            WHERE p.activo AND $FILTRO_ACCESO
              AND (strpos(lower(concat_ws(' ', p.nombres, p.primer_apellido, p.segundo_apellido)), lower(:q)) > 0
                   OR p.id_persona::text = :q OR p.curp = upper(:q) OR :q = '')
            ORDER BY p.id_persona
            LIMIT 21 OFFSET :inicio
        """.trimIndent())).param("q", consulta).param("inicio", (pagina - 1L) * 20)
            .query { fila, _ -> PersonaResumen(fila.getLong(1), fila.getString(2), fila.getString(3), fila.getString(4)) }
            .list()
        return PaginaPersonas(personas.take(20), personas.size > 20)
    }

    fun pendientes(id: Long): List<Pendiente> {
        if (!jdbc.sql("SELECT EXISTS (SELECT 1 FROM persona WHERE id_persona = :id)")
                .param("id", id).query(Boolean::class.javaObjectType).single()
        ) noEncontrado("No se encontró la persona.")

        return jdbc.sql("""
            SELECT d.id_esquema_detalle, v.nombre, d.numero_dosis,
                   (p.fecha_nacimiento + make_interval(months => d.edad_objetivo_meses))::date AS objetivo,
                   (p.fecha_nacimiento + make_interval(months => d.edad_objetivo_meses))::date + d.plazo_atraso_dias AS limite,
                   CASE WHEN d.numero_dosis = 1 THEN p.fecha_nacimiento
                        ELSE anterior.fecha_aplicacion + d.intervalo_minimo_dias END AS minima,
                   d.numero_dosis > 1 AND anterior.id_dosis_aplicada IS NULL AS requiere_anterior
            FROM persona p
            JOIN esquema_detalle d USING (id_esquema)
            JOIN vacuna v ON v.id_vacuna = d.id_vacuna
            LEFT JOIN dosis_aplicada actual ON actual.id_persona = p.id_persona AND actual.id_esquema_detalle = d.id_esquema_detalle
            LEFT JOIN esquema_detalle previo ON previo.id_esquema = d.id_esquema AND previo.id_vacuna = d.id_vacuna
                                            AND previo.numero_dosis = d.numero_dosis - 1
            LEFT JOIN dosis_aplicada anterior ON anterior.id_persona = p.id_persona AND anterior.id_esquema_detalle = previo.id_esquema_detalle
            WHERE p.id_persona = :id AND actual.id_dosis_aplicada IS NULL
            ORDER BY objetivo, v.nombre, d.numero_dosis, d.id_esquema_detalle
        """.trimIndent()).param("id", id)
            .query { fila, _ ->
                Pendiente(
                    fila.getInt(1), fila.getString(2), fila.getInt(3),
                    fila.getObject(4, LocalDate::class.java), fila.getObject(5, LocalDate::class.java),
                    fila.getObject(6, LocalDate::class.java), fila.getBoolean(7)
                )
            }.list()
    }

    fun catalogos(cuenta: Cuenta?): Catalogos {
        val unidades = jdbc.sql("""
            SELECT id_unidad_salud, nombre FROM unidad_salud
            WHERE activo AND (:todas OR id_unidad_salud = CAST(:unidad AS integer))
            ORDER BY nombre
        """.trimIndent()).param("todas", cuenta?.rol == "ADMINISTRADOR")
            .param("unidad", cuenta?.unidad)
            .query { fila, _ -> Opcion(fila.getInt(1), fila.getString(2)) }.list()
        val esquemas = jdbc.sql("""
            SELECT id_esquema, nombre || ' · v' || version FROM esquema WHERE activo ORDER BY nombre, version
        """.trimIndent()).query { fila, _ -> Opcion(fila.getInt(1), fila.getString(2)) }.list()
        return Catalogos(unidades, esquemas)
    }

    fun crear(datos: AltaPersona, cuenta: Cuenta): Creado {
        val nombres = datos.nombres.trim()
        val apellido = datos.primerApellido.trim()
        val segundoApellido = datos.segundoApellido?.trim()?.takeIf { it.isNotEmpty() }
        val curp = datos.curp?.trim()?.uppercase(Locale.ROOT)?.takeIf { it.isNotEmpty() }
        if (nombres.length !in 1..100 || apellido.length !in 1..100 || (segundoApellido?.length ?: 0) > 100) {
            invalido("Ingresa nombres y apellidos de hasta 100 caracteres.")
        }
        if (curp != null && !curp.matches(Regex("[A-Z0-9]{18}"))) {
            invalido("La CURP debe tener 18 letras o números.")
        }
        if (datos.sexo !in setOf("F", "M", "ND") || datos.nacimiento > hoy()) {
            invalido("Verifica la fecha de nacimiento y el sexo.")
        }
        if (cuenta.rol != "ADMINISTRADOR" && cuenta.unidad != datos.idUnidad) {
            throw ResponseStatusException(HttpStatus.FORBIDDEN, "Solo puedes dar de alta personas en tu unidad.")
        }
        try {
            val id = jdbc.sql("""
                INSERT INTO persona (nombres, primer_apellido, segundo_apellido, curp, fecha_nacimiento, sexo, id_unidad_salud, id_esquema)
                SELECT :nombres, :apellido, :segundo, :curp, :nacimiento, :sexo, u.id_unidad_salud, e.id_esquema
                FROM unidad_salud u CROSS JOIN esquema e
                WHERE u.activo AND e.activo AND u.id_unidad_salud = :unidad AND e.id_esquema = :esquema
                RETURNING id_persona
            """.trimIndent())
                .param("nombres", nombres).param("apellido", apellido).param("segundo", segundoApellido)
                .param("curp", curp).param("nacimiento", datos.nacimiento).param("sexo", datos.sexo)
                .param("unidad", datos.idUnidad).param("esquema", datos.idEsquema)
                .query(Long::class.javaObjectType).optional()
                .orElseThrow { ResponseStatusException(HttpStatus.BAD_REQUEST, "Elige una unidad y un esquema activos.") }
            return Creado(id)
        } catch (_: DuplicateKeyException) {
            conflicto("Ya existe una persona con esa CURP.")
        }
    }

    fun registrar(id: Long, dosis: AltaDosis, cuenta: Cuenta): Creado {
        val lote = dosis.lote.trim()
        if (id <= 0 || dosis.idDetalle <= 0 || lote.length !in 1..50 || dosis.fecha > hoy()) {
            invalido("Verifica la dosis, el lote y la fecha de aplicación.")
        }
        return checkNotNull(transacciones.execute {
            // Serializa los registros del mismo expediente antes de leer las aplicaciones previas.
            val unidad = jdbc.sql("""
                SELECT p.id_unidad_salud FROM persona p JOIN unidad_salud u USING (id_unidad_salud)
                WHERE p.id_persona = :id AND p.activo AND u.activo
                  AND (:admin OR u.id_unidad_salud = CAST(:unidad AS integer))
                FOR UPDATE OF p
            """.trimIndent()).param("id", id).param("admin", cuenta.rol == "ADMINISTRADOR")
                .param("unidad", cuenta.unidad).query(Int::class.javaObjectType).optional()
                .orElseThrow { ResponseStatusException(HttpStatus.NOT_FOUND, "No se encontró una persona activa en tu unidad.") }

            val pendiente = pendientes(id).find { it.id == dosis.idDetalle }
                ?: conflicto("La dosis ya fue registrada o no pertenece al esquema asignado.")
            if (pendiente.requiereAnterior || pendiente.fechaMinima == null) {
                conflicto("Registra primero la dosis anterior.")
            }
            if (dosis.fecha < pendiente.fechaMinima) {
                invalido("La fecha debe ser igual o posterior a ${pendiente.fechaMinima}.")
            }
            val idAplicacion = jdbc.sql("""
                INSERT INTO dosis_aplicada (id_persona, id_esquema_detalle, id_usuario_registrador, id_unidad_salud, fecha_aplicacion, lote)
                VALUES (:persona, :detalle, :registrador, :unidad, :fecha, :lote)
                ON CONFLICT (id_persona, id_esquema_detalle) DO NOTHING
                RETURNING id_dosis_aplicada
            """.trimIndent()).param("persona", id).param("detalle", dosis.idDetalle).param("registrador", cuenta.id)
                .param("unidad", unidad).param("fecha", dosis.fecha).param("lote", lote)
                .query(Long::class.javaObjectType).optional()
                .orElseThrow { ResponseStatusException(HttpStatus.CONFLICT, "La dosis ya fue registrada.") }
            Creado(idAplicacion)
        })
    }

    private fun hoy() = LocalDate.now(ZoneId.of("America/Mexico_City"))
    private fun invalido(mensaje: String): Nothing = throw ResponseStatusException(HttpStatus.BAD_REQUEST, mensaje)
    private fun conflicto(mensaje: String): Nothing = throw ResponseStatusException(HttpStatus.CONFLICT, mensaje)
    private fun noEncontrado(mensaje: String): Nothing = throw ResponseStatusException(HttpStatus.NOT_FOUND, mensaje)
}
