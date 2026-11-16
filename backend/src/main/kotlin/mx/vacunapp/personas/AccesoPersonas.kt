package mx.vacunapp.personas

import mx.vacunapp.seguridad.Cuenta
import org.springframework.http.HttpStatus
import org.springframework.jdbc.core.simple.JdbcClient
import org.springframework.security.core.Authentication
import org.springframework.stereotype.Component
import org.springframework.web.server.ResponseStatusException

@Component
class AccesoPersonas(private val jdbc: JdbcClient) {
    fun alcance(authentication: Authentication?): Alcance {
        val cuenta = authentication?.principal as? Cuenta
        return when (cuenta?.rol) {
            null, "ADMINISTRADOR" -> Alcance(true, null, null)
            "PERSONAL_SALUD" -> Alcance(false, cuenta.unidad, null)
            else -> Alcance(false, null, cuenta.persona)
        }
    }

    fun comprobar(id: Long, authentication: Authentication?) {
        if (id <= 0) throw ResponseStatusException(HttpStatus.BAD_REQUEST, "El identificador debe ser positivo.")
        val alcance = alcance(authentication)
        if (alcance.todos) return
        val visible = alcance.preparar(jdbc.sql("""
            SELECT EXISTS (SELECT 1 FROM persona p WHERE p.id_persona = :id AND $FILTRO_ACCESO)
        """.trimIndent())).param("id", id).query(Boolean::class.javaObjectType).single()
        if (!visible) throw ResponseStatusException(HttpStatus.NOT_FOUND, "No se encontró la persona.")
    }
}

const val FILTRO_ACCESO = """
    (:todos OR p.id_unidad_salud = CAST(:unidadCuenta AS integer) OR p.id_persona = CAST(:personaCuenta AS bigint))
"""

data class Alcance(val todos: Boolean, val unidad: Int?, val persona: Long?) {
    fun preparar(consulta: JdbcClient.StatementSpec) =
        consulta.param("todos", todos).param("unidadCuenta", unidad).param("personaCuenta", persona)
}
