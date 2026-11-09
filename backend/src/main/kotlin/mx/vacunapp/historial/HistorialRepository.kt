package mx.vacunapp.historial

import java.time.LocalDate
import java.util.Optional
import org.springframework.core.io.ClassPathResource
import org.springframework.jdbc.core.ResultSetExtractor
import org.springframework.jdbc.core.simple.JdbcClient
import org.springframework.stereotype.Repository

data class Aplicacion(
    val id: Long,
    val vacuna: String,
    val numeroDosis: Int,
    val fechaAplicacion: LocalDate,
    val lote: String,
    val unidad: String
)

data class Historial(val idPersona: Long, val nombre: String, val aplicaciones: List<Aplicacion>)

@Repository
open class HistorialRepository(private val jdbc: JdbcClient) {
    private val consulta = ClassPathResource("historial.sql").inputStream.bufferedReader().use { it.readText() }

    open fun buscar(id: Long): Historial? = jdbc.sql(consulta).param("id", id).query(ResultSetExtractor<Optional<Historial>> { filas ->
        if (!filas.next()) {
            Optional.empty()
        } else {
            val nombre = listOfNotNull(
                filas.getString("nombres"),
                filas.getString("primer_apellido"),
                filas.getString("segundo_apellido")
            ).joinToString(" ")
            val aplicaciones = mutableListOf<Aplicacion>()
            do {
                val idAplicacion = filas.getObject("id_dosis_aplicada", Long::class.javaObjectType)
                if (idAplicacion != null) {
                    aplicaciones.add(
                        Aplicacion(
                            idAplicacion, filas.getString("vacuna"), filas.getInt("numero_dosis"),
                            filas.getObject("fecha_aplicacion", LocalDate::class.java),
                            filas.getString("lote"), filas.getString("unidad")
                        )
                    )
                }
            } while (filas.next())
            Optional.of(Historial(id, nombre, aplicaciones))
        }
    }).orElse(null)
}
