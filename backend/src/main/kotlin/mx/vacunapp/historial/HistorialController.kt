package mx.vacunapp.historial

import mx.vacunapp.personas.AccesoPersonas
import org.springframework.http.ResponseEntity
import org.springframework.security.core.Authentication
import org.springframework.web.bind.annotation.GetMapping
import org.springframework.web.bind.annotation.PathVariable
import org.springframework.web.bind.annotation.RequestMapping
import org.springframework.web.bind.annotation.RestController

@RestController
@RequestMapping("/api/personas")
class HistorialController(private val servicio: HistorialService, private val acceso: AccesoPersonas) {
    @GetMapping("/{id}/historial")
    fun consultar(@PathVariable("id") id: Long, authentication: Authentication?): ResponseEntity<Historial> {
        acceso.comprobar(id, authentication)
        return ResponseEntity.ofNullable(servicio.buscar(id))
    }
}
