const $ = (id) => document.getElementById(id);
const fechaLocal = new Intl.DateTimeFormat("es-MX", { dateStyle: "medium", timeZone: "UTC" });
const fechaMexico = new Intl.DateTimeFormat("en-CA", { timeZone: "America/Mexico_City", dateStyle: "short" });
const hoy = () => {
  const partes = Object.fromEntries(fechaMexico.formatToParts().map(({ type, value }) => [type, value]));
  return `${partes.year}-${partes.month}-${partes.day}`;
};
const fecha = (valor) => fechaLocal.format(new Date(`${valor}T00:00:00Z`));
const puedeEditar = () => ["ADMINISTRADOR", "PERSONAL_SALUD"].includes(sesion?.rol);

let sesion;
let pagina = 1;
let textoBusqueda = "";
let seleccion;
let cargaDirectorio = 0;
let cargaExpediente = 0;

async function api(url, { method = "GET", body } = {}) {
  const headers = { Accept: "application/json" };
  if (method === "POST") headers[sesion.cabeceraCsrf] = sesion.csrf;
  if (body && !(body instanceof URLSearchParams)) {
    headers["Content-Type"] = "application/json";
    body = JSON.stringify(body);
  }
  const respuesta = await fetch(url, { method, headers, body });
  if (respuesta.status === 204) return;
  const tipo = respuesta.headers.get("Content-Type") ?? "";
  const datos = tipo.includes("json") ? await respuesta.json() : null;
  if (!respuesta.ok) {
    const mensajes = { 400: "Revisa los datos ingresados.", 401: "Revisa tus credenciales o vuelve a iniciar sesión.",
      403: "Tu sesión o tus permisos no permiten esta acción.", 404: "No se encontró el registro." };
    throw new Error(datos?.detail ?? mensajes[respuesta.status] ?? "No fue posible completar la operación.");
  }
  return datos;
}

function aviso(mensaje = "", error = false) {
  $("estado").hidden = !mensaje;
  $("estado").textContent = mensaje;
  $("estado").toggleAttribute("data-error", error);
}

function nodo(tag, valor, clase) {
  const el = document.createElement(tag);
  el.textContent = valor ?? "";
  if (clase) el.className = clase;
  return el;
}

function limpiarExpediente() {
  ++cargaExpediente;
  seleccion = undefined;
  $("expediente").hidden = true;
  $("sin-expediente").hidden = false;
  $("sin-expediente").textContent = "Selecciona una persona para consultar su expediente.";
  for (const id of ["folio", "persona-nombre", "persona-unidad", "historial", "pendientes"]) $(id).replaceChildren();
  resaltarSeleccion();
}

async function cargarSesion() {
  ++cargaDirectorio;
  limpiarExpediente();
  $("personas").replaceChildren();
  $("workspace").hidden = true;
  sesion = await api("/api/sesion");
  $("demo").hidden = !sesion.demo;
  $("impresion-demo").hidden = !sesion.demo;
  $("ayuda-demo").hidden = !sesion.demo;
  $("correo").textContent = sesion.correo ?? "";
  $("sesion").textContent = sesion.correo ? "Cerrar sesión" : "Iniciar sesión";
  $("sesion").hidden = false;
  $("nueva-persona").hidden = !puedeEditar();
  $("workspace").hidden = !sesion.demo && !sesion.correo;
  if ($("workspace").hidden) {
    aviso("Inicia sesión para consultar los expedientes.");
    return;
  }
  aviso();
  textoBusqueda = $("consulta").value = "";
  await cargarDirectorio(1);
}

async function cargarDirectorio(nuevaPagina, abrirPrimera = true) {
  const solicitud = ++cargaDirectorio;
  const parametros = new URLSearchParams({ q: textoBusqueda, pagina: nuevaPagina });
  $("resultado").textContent = "Buscando…";
  try {
    const datos = await api(`/api/personas?${parametros}`);
    if (solicitud !== cargaDirectorio) return;
    pagina = nuevaPagina;
    const total = datos.personas.length;
    $("resultado").textContent = total ? `Página ${pagina} · ${total} ${total === 1 ? "resultado" : "resultados"}` : "No se encontraron personas.";
    $("anterior").disabled = pagina === 1;
    $("siguiente").disabled = !datos.hayMas;
    $("paginacion").hidden = pagina === 1 && !datos.hayMas;
    $("personas").replaceChildren(...datos.personas.map((persona) => {
      const item = nodo("li");
      const boton = nodo("button", "", "person");
      boton.dataset.id = persona.id;
      boton.append(nodo("strong", persona.nombre), nodo("span", `Folio ${persona.id} · ${persona.unidad ?? "Sin unidad"}`, "muted"));
      boton.addEventListener("click", () => cargarExpediente(persona, true));
      item.append(boton);
      return item;
    }));
    resaltarSeleccion();
    if (!datos.personas.length) limpiarExpediente();
    else if (abrirPrimera) await cargarExpediente(datos.personas[0]);
  } catch (error) {
    if (solicitud !== cargaDirectorio) return;
    $("resultado").textContent = "";
    aviso(error.message, true);
  }
}

function resaltarSeleccion() {
  $("personas").querySelectorAll("button").forEach((boton) => {
    if (boton.dataset.id === String(seleccion?.id)) boton.setAttribute("aria-current", "true");
    else boton.removeAttribute("aria-current");
  });
}

async function cargarExpediente(persona, enfocar = false) {
  const solicitud = ++cargaExpediente;
  seleccion = persona;
  resaltarSeleccion();
  $("expediente").hidden = true;
  $("sin-expediente").hidden = false;
  $("sin-expediente").textContent = "Cargando expediente…";
  const ruta = `/api/personas/${persona.id}`;
  try {
    const [historial, pendientes] = await Promise.all([api(`${ruta}/historial`), api(`${ruta}/pendientes`)]);
    if (solicitud !== cargaExpediente) return;
    $("folio").textContent = `Folio ${persona.id}`;
    $("persona-nombre").textContent = historial.nombre;
    $("persona-unidad").textContent = [persona.unidad, persona.esquema].filter(Boolean).join(" · ");
    $("total-aplicadas").textContent = historial.aplicaciones.length;
    $("total-pendientes").textContent = pendientes.length;
    $("historial").replaceChildren(tabla(
      ["Vacuna", "Dosis", "Aplicación", "Lote", "Unidad de salud"],
      historial.aplicaciones.map((dosis) => [dosis.vacuna, dosis.numeroDosis, fecha(dosis.fechaAplicacion), dosis.lote, dosis.unidad]),
      "Todavía no hay aplicaciones registradas."
    ));
    const columnas = ["Vacuna", "Dosis", "Fecha objetivo", "Estado"];
    if (puedeEditar()) columnas.push(nodo("span", "Registro", "interactive"));
    $("pendientes").replaceChildren(tabla(columnas, pendientes.map((dosis) => {
      const estado = dosis.requiereAnterior ? "Requiere dosis previa"
        : dosis.fechaLimite < hoy() ? "Fuera de plazo" : "Pendiente";
      const fila = [dosis.vacuna, dosis.numeroDosis, fecha(dosis.fechaObjetivo), estado];
      if (puedeEditar()) {
        const boton = nodo("button", "Registrar", "button secondary interactive");
        boton.disabled = dosis.requiereAnterior || dosis.fechaMinima > hoy();
        boton.setAttribute("aria-label", `Registrar ${dosis.vacuna}, dosis ${dosis.numeroDosis}`);
        boton.addEventListener("click", () => abrirDosis(dosis, persona));
        fila.push(boton);
      }
      return fila;
    }), "No hay dosis pendientes en el esquema asignado."));
    $("sin-expediente").hidden = true;
    $("expediente").hidden = false;
    if (enfocar) {
      $("persona-nombre").tabIndex = -1;
      $("persona-nombre").focus();
    }
  } catch (error) {
    if (solicitud !== cargaExpediente) return;
    $("sin-expediente").textContent = error.message;
  }
}

function tabla(columnas, filas, vacio) {
  if (!filas.length) return nodo("p", vacio, "muted");
  const envoltura = nodo("div", "", "table-wrap");
  envoltura.tabIndex = 0;
  const tabla = nodo("table");
  const encabezado = tabla.createTHead().insertRow();
  columnas.forEach((valor) => {
    const th = nodo("th");
    th.scope = "col";
    agregarCelda(th, valor);
    encabezado.append(th);
  });
  const cuerpo = tabla.createTBody();
  filas.forEach((celdas) => {
    const fila = cuerpo.insertRow();
    celdas.forEach((valor) => agregarCelda(fila.insertCell(), valor));
  });
  envoltura.append(tabla);
  return envoltura;
}

function agregarCelda(celda, valor) {
  if (valor instanceof Node) {
    if (valor.classList.contains("interactive")) celda.classList.add("interactive");
    celda.append(valor);
  } else {
    celda.textContent = valor;
  }
}

function errorFormulario(form, mensaje = "") {
  const error = form.querySelector(".form-error");
  error.textContent = mensaje;
  error.hidden = !mensaje;
}

function abrirDialogo(id) {
  const dialogo = $(id);
  errorFormulario(dialogo.querySelector("form"));
  dialogo.showModal();
}

function manejarFormulario(id, guardar) {
  const form = $(id);
  form.addEventListener("submit", async (evento) => {
    evento.preventDefault();
    const boton = form.querySelector("button:not([type])");
    boton.disabled = true;
    errorFormulario(form);
    try {
      await guardar(new FormData(form));
    } catch (error) {
      errorFormulario(form, error.message);
    } finally {
      boton.disabled = false;
    }
  });
}

function abrirDosis(dosis, persona) {
  const form = $("form-dosis");
  form.reset();
  form.dataset.persona = persona.id;
  form.dataset.detalle = dosis.id;
  $("detalle-dosis").textContent = `${persona.nombre} · ${dosis.vacuna} · Dosis ${dosis.numeroDosis}`;
  form.elements.fecha.min = dosis.fechaMinima;
  form.elements.fecha.max = hoy();
  form.elements.fecha.value = hoy();
  abrirDialogo("dosis");
}

function llenarSelect(select, opciones) {
  select.replaceChildren(...opciones.map(({ id, nombre }) => new Option(nombre, id)));
}

$("busqueda").addEventListener("submit", (evento) => {
  evento.preventDefault();
  aviso();
  textoBusqueda = $("consulta").value.trim();
  cargarDirectorio(1);
});
$("anterior").addEventListener("click", () => cargarDirectorio(pagina - 1));
$("siguiente").addEventListener("click", () => cargarDirectorio(pagina + 1));
$("imprimir").addEventListener("click", () => window.print());
document.querySelectorAll("[data-close]").forEach((boton) => boton.addEventListener("click", () => boton.closest("dialog").close()));

$("sesion").addEventListener("click", async () => {
  if (!sesion.correo) {
    abrirDialogo("login");
    return;
  }
  try {
    await api("/logout", { method: "POST" });
    await cargarSesion();
  } catch (error) {
    aviso(error.message, true);
  }
});
manejarFormulario("form-login", async (datos) => {
  await api("/login", { method: "POST", body: new URLSearchParams(datos) });
  $("form-login").reset();
  $("login").close();
  await cargarSesion().catch((error) => aviso(error.message, true));
});

$("nueva-persona").addEventListener("click", async () => {
  try {
    const catalogos = await api("/api/personas/catalogos");
    if (!catalogos.unidades.length || !catalogos.esquemas.length) {
      aviso("Para dar de alta una persona se requiere una unidad activa y un esquema activo.", true);
      return;
    }
    const form = $("form-alta");
    form.reset();
    llenarSelect(form.elements.idUnidad, catalogos.unidades);
    llenarSelect(form.elements.idEsquema, catalogos.esquemas);
    form.elements.nacimiento.max = hoy();
    abrirDialogo("alta");
  } catch (error) {
    aviso(error.message, true);
  }
});
manejarFormulario("form-alta", async (datos) => {
  const { id } = await api("/api/personas", { method: "POST", body: Object.fromEntries(datos) });
  $("alta").close();
  textoBusqueda = $("consulta").value = String(id);
  aviso(`Persona dada de alta. Folio ${id}.`);
  await cargarDirectorio(1);
});
manejarFormulario("form-dosis", async (datos) => {
  const { persona, detalle } = $("form-dosis").dataset;
  const seleccionAnterior = seleccion;
  const body = { ...Object.fromEntries(datos), idDetalle: Number(detalle) };
  await api(`/api/personas/${persona}/dosis`, { method: "POST", body });
  $("dosis").close();
  aviso("Aplicación registrada.");
  if (seleccion && seleccionAnterior?.id === seleccion.id) await cargarExpediente(seleccion);
});

cargarSesion().catch((error) => aviso(error.message, true));
