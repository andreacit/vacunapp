# VacunApp

Aplicación web de vacunación en Kotlin con Spring Boot y PostgreSQL. El perfil de demostración usa expedientes ficticios.

## Levantar la base

Abre Docker Desktop y espera a que Docker esté disponible. Clona el repositorio del equipo con `git clone "URL-del-repositorio"`, sustituyendo el ejemplo por la URL de GitHub. Entra a la carpeta que contiene `compose.yaml` y ejecuta en PowerShell:

```powershell
if (-not (Test-Path .env)) { Copy-Item .env.example .env }
docker compose up -d --wait db
docker compose ps
docker compose exec -T db psql -U vacunapp -d vacunapp -c '\dt'
```

Si trabajas en Linux, usa la línea de tu shell para crear `.env` antes de ejecutar los comandos de Docker:

```bash
# Bash
test -f .env || cp .env.example .env
```

```fish
# Fish
test -f .env; or cp .env.example .env
```

El repositorio incluye `.env.example` con valores de demostración. Cada integrante configura su copia local en `.env`, que Git ignora. Si el puerto 5433 está ocupado, cambia `DB_PORT` en ese archivo, por ejemplo a `55439`.

En un volumen vacío, PostgreSQL ejecuta primero [el esquema](database/init/01-esquema.sql) y después [los datos de demostración](database/init/02-datos-demo.sql). El nombre de la base y el usuario son `vacunapp`. Desde la máquina local se conecta a `localhost:5433` por defecto. La contraseña se configura en `.env`.

## Abrir la aplicación

Con Docker Desktop iniciado y el archivo `.env` preparado, ejecuta desde la carpeta del proyecto:

```sh
docker compose --profile demo up -d --build --wait
```

Abre [http://localhost:8080](http://localhost:8080). Si cambiaste `API_PORT`, usa ese puerto en la URL. El primer arranque descarga imágenes y dependencias.

- Busca por nombre, CURP o folio. El folio 1 muestra un historial completo y el folio 15 tiene dos dosis pendientes.
- Para registrar aplicaciones o dar de alta personas, inicia sesión con `registro5@example.test` y la contraseña `VACUNAPP_DEMO_PASSWORD` de `.env`. En un `.env` anterior, copia esa línea de `.env.example` y vuelve a iniciar el servicio. El primer arranque con esa variable habilita la cuenta de demostración si todavía tiene la contraseña de marcador. Editar la variable después no cambia el hash guardado.
- La cuenta de demostración pertenece a la unidad 5. Usa el folio 15 para probar el registro. El expediente se actualiza al guardar una aplicación.
- Para exportar, abre el expediente, elige **Imprimir / Guardar PDF** y selecciona **Guardar como PDF** en el diálogo del navegador.

## API

| Método | Ruta | Función |
| --- | --- | --- |
| GET | `/api/personas?q=&pagina=1` | Buscar expedientes activos, 20 por página |
| GET | `/api/personas/{id}/historial` | Consultar aplicaciones registradas |
| GET | `/api/personas/{id}/pendientes` | Consultar dosis sin aplicación y fechas del esquema asignado |
| GET | `/api/personas/catalogos` | Obtener esquemas y unidades activas para el alta |
| POST | `/api/personas` | Dar de alta una persona |
| POST | `/api/personas/{id}/dosis` | Registrar una aplicación |
| GET | `/api/sesion` | Consultar el estado de la sesión y obtener el token CSRF |

La interfaz inicia sesión en `POST /login` con los campos de formulario `username` y `password`. Los POST requieren la cookie de sesión y la cabecera CSRF indicada por `/api/sesion`. Vuelve a consultar ese endpoint después de iniciar o cerrar sesión.

El endpoint de historial conserva la estructura original. En modo demo puedes probarlo directamente:

```sh
curl -i http://localhost:8080/api/personas/1/historial
```

El historial del folio 15 inicialmente devuelve `200` con `aplicaciones: []`. Un folio inexistente devuelve `404` y uno no válido devuelve `400`.

El registro de dosis valida la unidad, la pertenencia al esquema, la fecha de nacimiento, la secuencia, el intervalo mínimo y que la dosis no se haya registrado antes. Las fechas objetivo y de atraso provienen del esquema de demostración.

Compose publica los puertos en la máquina local. En el perfil `demo` las lecturas de expedientes ficticios están abiertas. Fuera de ese perfil, un administrador puede consultar todos los expedientes, personal de salud puede consultar los de su unidad y una cuenta de consulta puede ver su expediente vinculado. El alta y el registro requieren un rol de escritura. Para usar datos reales aún falta preparar el despliegue y una cuenta de base de datos con permisos limitados.

## Verificar la base y las consultas

```powershell
docker compose cp ./database/verificar.sql db:/tmp/verificar.sql
docker compose exec -T db psql -X -U vacunapp -d vacunapp -v ON_ERROR_STOP=1 -f /tmp/verificar.sql
```

La base recién inicializada contiene ocho tablas. Los conteos esperados son 3 roles, 10 unidades, 10 usuarios, 15 personas, 10 vacunas, 10 esquemas, 20 detalles y 20 aplicaciones. La consulta del historial devuelve dos aplicaciones para la persona 1 y la consulta de pendientes muestra dos dosis para la persona 15. El script también lista las definiciones de PK, FK, UNIQUE y CHECK.

`docker compose down` detiene los servicios y conserva los datos en el volumen. Los scripts de inicio se aplican al crear un volumen vacío. Para cambiar una base existente, aplicar el SQL de modificación correspondiente. `docker compose down -v` elimina los datos locales del proyecto.

## Generar y comprobar el respaldo

El respaldo en texto plano se genera después de comprobar los datos. En PowerShell, desde la carpeta de `compose.yaml`:

```powershell
docker compose exec -T db pg_dump -U vacunapp -d vacunapp --format=plain --no-owner --no-privileges --file=/tmp/respaldo-final.sql
docker compose cp db:/tmp/respaldo-final.sql ./database/respaldos/respaldo-final.sql
docker compose exec -T db createdb -U vacunapp vacunapp_restaurada
docker compose exec -T db psql -X -U vacunapp -d vacunapp_restaurada -v ON_ERROR_STOP=1 --single-transaction -f /tmp/respaldo-final.sql
docker compose exec -T db psql -X -U vacunapp -d vacunapp_restaurada -v ON_ERROR_STOP=1 -f /tmp/verificar.sql
```

El último comando reutiliza el script copiado en la verificación. Compara los conteos y las consultas con la base original. Si `vacunapp_restaurada` ya existe, elige un nombre nuevo y úsalo en los tres comandos correspondientes. El respaldo se escribe dentro del contenedor y se copia como archivo para conservar su codificación. El [respaldo final incluido](database/respaldos/respaldo-final.sql) contiene los datos ficticios de la demostración.
