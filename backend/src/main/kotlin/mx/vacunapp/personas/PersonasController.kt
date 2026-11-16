package mx.vacunapp.personas

import java.time.LocalDate
import mx.vacunapp.seguridad.Cuenta
import org.springframework.http.HttpStatus
import org.springframework.security.core.Authentication
import org.springframework.web.bind.annotation.GetMapping
import org.springframework.web.bind.annotation.PathVariable
import org.springframework.web.bind.annotation.PostMapping
import org.springframework.web.bind.annotation.RequestBody
import org.springframework.web.bind.annotation.RequestMapping
import org.springframework.web.bind.annotation.RequestParam
import org.springframework.web.bind.annotation.ResponseStatus
import org.springframework.web.bind.annotation.RestController

@RestController
@RequestMapping("/api/personas")
class PersonasController(private val personas: Personas, private val acceso: AccesoPersonas) {
    @GetMapping
    fun buscar(
        @RequestParam("q", defaultValue = "") consulta: String,
        @RequestParam("pagina", defaultValue = "1") pagina: Int,
        authentication: Authentication?
    ) = personas.buscar(consulta.trim(), pagina, acceso.alcance(authentication))

    @GetMapping("/{id}/pendientes")
    fun pendientes(@PathVariable("id") id: Long, authentication: Authentication?): List<Pendiente> {
        acceso.comprobar(id, authentication)
        return personas.pendientes(id)
    }

    @GetMapping("/catalogos")
    fun catalogos(authentication: Authentication?) = personas.catalogos(authentication?.principal as? Cuenta)

    @PostMapping
    @ResponseStatus(HttpStatus.CREATED)
    fun crear(@RequestBody solicitud: AltaPersona, authentication: Authentication): Creado =
        personas.crear(solicitud, authentication.principal as Cuenta)

    @PostMapping("/{id}/dosis")
    @ResponseStatus(HttpStatus.CREATED)
    fun registrar(@PathVariable("id") id: Long, @RequestBody dosis: AltaDosis, authentication: Authentication): Creado =
        personas.registrar(id, dosis, authentication.principal as Cuenta)
}

data class PersonaResumen(val id: Long, val nombre: String, val unidad: String?, val esquema: String)
data class PaginaPersonas(val personas: List<PersonaResumen>, val hayMas: Boolean)
data class Opcion(val id: Int, val nombre: String)
data class Catalogos(val unidades: List<Opcion>, val esquemas: List<Opcion>)
data class Creado(val id: Long)
data class AltaPersona(
    val nombres: String,
    val primerApellido: String,
    val segundoApellido: String? = null,
    val curp: String? = null,
    val nacimiento: LocalDate,
    val sexo: String,
    val idUnidad: Int,
    val idEsquema: Int
)
data class AltaDosis(val idDetalle: Int, val fecha: LocalDate, val lote: String)
data class Pendiente(
    val id: Int,
    val vacuna: String,
    val numeroDosis: Int,
    val fechaObjetivo: LocalDate,
    val fechaLimite: LocalDate,
    val fechaMinima: LocalDate?,
    val requiereAnterior: Boolean
)
