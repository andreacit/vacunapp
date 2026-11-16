package mx.vacunapp.seguridad

import java.util.Locale
import org.springframework.beans.factory.annotation.Value
import org.springframework.boot.ApplicationRunner
import org.springframework.context.annotation.Bean
import org.springframework.context.annotation.Configuration
import org.springframework.context.annotation.Profile
import org.springframework.core.env.Environment
import org.springframework.core.env.Profiles
import org.springframework.http.HttpMethod
import org.springframework.jdbc.core.simple.JdbcClient
import org.springframework.security.config.annotation.web.builders.HttpSecurity
import org.springframework.security.core.Authentication
import org.springframework.security.core.CredentialsContainer
import org.springframework.security.core.GrantedAuthority
import org.springframework.security.core.userdetails.UserDetails
import org.springframework.security.core.userdetails.UserDetailsService
import org.springframework.security.core.userdetails.UsernameNotFoundException
import org.springframework.security.crypto.bcrypt.BCryptPasswordEncoder
import org.springframework.security.web.SecurityFilterChain
import org.springframework.security.web.csrf.CsrfToken
import org.springframework.web.bind.annotation.GetMapping
import org.springframework.web.bind.annotation.RestController

private const val REGISTRADOR_DEMO = "registro5@example.test"

class Cuenta(
    val id: Long,
    val rol: String,
    val unidad: Int?,
    val persona: Long?,
    private val correo: String,
    private var hash: String?
) : UserDetails, CredentialsContainer {
    override fun getUsername() = correo
    override fun getPassword() = hash
    override fun eraseCredentials() {
        hash = null
    }
    override fun getAuthorities() = listOf(GrantedAuthority { "ROLE_$rol" })
}

@Configuration(proxyBeanMethods = false)
class Seguridad {
    @Bean
    fun contrasenas() = BCryptPasswordEncoder()

    @Bean
    fun cuentas(jdbc: JdbcClient) = UserDetailsService { correo ->
        jdbc.sql("""
            SELECT u.id_usuario, r.codigo, u.id_unidad_salud, u.id_persona, u.correo, u.contrasena_hash
            FROM usuario u JOIN rol r USING (id_rol)
            WHERE u.correo = :correo AND u.activo AND u.contrasena_hash <> 'NO_HABILITADO'
        """.trimIndent())
            .param("correo", correo.trim().lowercase(Locale.ROOT))
            .query { fila, _ ->
                Cuenta(
                    fila.getLong("id_usuario"), fila.getString("codigo"),
                    fila.getObject("id_unidad_salud", Int::class.javaObjectType),
                    fila.getObject("id_persona", Long::class.javaObjectType),
                    fila.getString("correo"), fila.getString("contrasena_hash")
                )
            }.optional().orElseThrow { UsernameNotFoundException("Cuenta no disponible") }
    }

    @Bean
    @Profile("demo")
    fun habilitarCuentaDemo(
        jdbc: JdbcClient,
        encoder: BCryptPasswordEncoder,
        @Value("\${vacunapp.demo.password:}") password: String
    ) = ApplicationRunner {
        if (password.isNotBlank()) {
            jdbc.sql("""
                UPDATE usuario SET contrasena_hash = :hash
                WHERE correo = :correo AND contrasena_hash = 'NO_HABILITADO'
            """.trimIndent())
                .param("hash", encoder.encode(password))
                .param("correo", REGISTRADOR_DEMO)
                .update()
        }
    }

    @Bean
    fun filtros(http: HttpSecurity, entorno: Environment): SecurityFilterChain {
        val demo = entorno.acceptsProfiles(Profiles.of("demo"))
        return http
            .authorizeHttpRequests { reglas ->
                reglas.requestMatchers("/", "/index.html", "/app.css", "/app.js", "/error", "/api/sesion").permitAll()
                reglas.requestMatchers(HttpMethod.POST, "/api/personas", "/api/personas/*/dosis")
                    .hasAnyRole("ADMINISTRADOR", "PERSONAL_SALUD")
                if (demo) {
                    reglas.requestMatchers(HttpMethod.GET, "/api/personas", "/api/personas/**").permitAll()
                }
                reglas.anyRequest().authenticated()
            }
            .exceptionHandling { errores ->
                errores.authenticationEntryPoint { _, response, _ -> response.status = 401 }
                errores.accessDeniedHandler { _, response, _ -> response.status = 403 }
            }
            .formLogin { login ->
                login.loginPage("/").loginProcessingUrl("/login")
                    .successHandler { _, response, _ -> response.status = 204 }
                    .failureHandler { _, response, _ -> response.status = 401 }
                    .permitAll()
            }
            .logout { logout -> logout.logoutSuccessHandler { _, response, _ -> response.status = 204 } }
            .requestCache { it.disable() }
            .build()
    }
}

@RestController
class SesionController(private val entorno: Environment) {
    @GetMapping("/api/sesion")
    fun sesion(authentication: Authentication?, csrf: CsrfToken): Sesion {
        val cuenta = authentication?.principal as? Cuenta
        return Sesion(
            cuenta?.username, cuenta?.rol, cuenta?.unidad, csrf.headerName, csrf.token,
            entorno.acceptsProfiles(Profiles.of("demo"))
        )
    }
}

data class Sesion(
    val correo: String?,
    val rol: String?,
    val idUnidad: Int?,
    val cabeceraCsrf: String,
    val csrf: String,
    val demo: Boolean
)
