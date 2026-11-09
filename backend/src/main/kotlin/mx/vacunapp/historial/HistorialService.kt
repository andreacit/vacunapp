package mx.vacunapp.historial

import org.springframework.stereotype.Service

@Service
class HistorialService(private val repositorio: HistorialRepository) {
    fun buscar(idPersona: Long): Historial? = repositorio.buscar(idPersona)
}
