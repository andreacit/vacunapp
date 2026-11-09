# VacunApp

Base PostgreSQL reproducible y un endpoint de ejemplo en Kotlin con Spring Boot. El entorno contiene datos ficticios.

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

## Probar el endpoint

```powershell
docker compose --profile demo up -d --build
docker compose logs api
curl.exe -i http://localhost:8080/api/personas/1/historial
```

En Linux, usa `curl` en lugar de `curl.exe`. El primer build necesita descargar las imágenes y dependencias. Si cambiaste `API_PORT`, ajusta la URL. El ID 1 tiene dos aplicaciones en la demo, el 15 existe sin aplicaciones y un ID inexistente devuelve 404. Una persona sin aplicaciones devuelve 200 con `aplicaciones: []`. Un identificador no válido devuelve 400.

El controlador recibe la petición, el servicio dirige la consulta y el repositorio ejecuta [historial.sql](backend/src/main/resources/historial.sql) con un parámetro JDBC. El SELECT combina persona, aplicación, detalle, vacuna y unidad. La respuesta contiene `idPersona`, `nombre` y una lista de aplicaciones con `id`, `vacuna`, `numeroDosis`, `fechaAplicacion`, `lote` y `unidad`.

Compose expone los puertos solo en la máquina local. La API se habilita con el perfil de demo y utiliza datos ficticios. Para continuar el desarrollo, el equipo implementará autenticación y autorización, permisos de BD para la cuenta de la API, los demás endpoints y la interfaz. Las reglas que cruzan tablas, como pertenencia al esquema, fechas, secuencia y cuenta de consulta, deberán validarse al incorporar operaciones de escritura.

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
