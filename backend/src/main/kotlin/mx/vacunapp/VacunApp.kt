package mx.vacunapp

import org.springframework.boot.autoconfigure.SpringBootApplication
import org.springframework.boot.runApplication

@SpringBootApplication(proxyBeanMethods = false)
class VacunApp

fun main(args: Array<String>) {
    runApplication<VacunApp>(*args)
}
