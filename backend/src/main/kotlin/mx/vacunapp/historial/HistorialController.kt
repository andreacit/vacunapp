package mx.vacunapp.historial

import org.springframework.http.ResponseEntity
import org.springframework.web.bind.annotation.GetMapping
import org.springframework.web.bind.annotation.PathVariable
import org.springframework.web.bind.annotation.RequestMapping
import org.springframework.web.bind.annotation.RestController

@RestController
@RequestMapping("/api/personas")
class HistorialController(private val servicio: HistorialService) {
    @GetMapping("/{id}/historial")
    fun consultar(@PathVariable("id") id: Long): ResponseEntity<Historial> {
        if (id <= 0) return ResponseEntity.badRequest().build()
        return ResponseEntity.ofNullable(servicio.buscar(id))
    }
}
