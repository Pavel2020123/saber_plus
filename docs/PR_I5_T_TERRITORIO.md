# PR-I5-T — Departamentos y municipios

## Checkpoint del 11 de octubre de 2026

**T1–T4 implementadas; T5 ensayo integrado cerrado en su alcance local.** Se incorporó
la copia oficial DANE DIVIPOLA MGN 2025 y dos rutas autenticadas de consulta.
33 unidades departamentales (Bogotá incluida), 1.122 unidades territoriales,
códigos como texto, nombres originales, fuente, fecha, versión y SHA-256.
Incluye áreas no municipalizadas e isla; no llamar municipios ordinarios a todas.

Fuente: [DANE MGN 2025](https://geoportal.dane.gov.co/mparcgis/rest/services/Divipola/Serv_DIVIPOLA_MGN_2025/MapServer).
El catálogo se empaqueta con el servidor: la app no tendrá que consultar al DANE
directamente. T2 añade persistencia/revisión, probadas en base temporal. No se
asignaron ubicaciones reales por suposición. T3 ahora incorpora los selectores.
No se modificaron XP, certificados ni rankings.

### T2 — Qué quedó listo

- Solicitud e institución guardan códigos y versión oficial, con validación de
  pareja y campos anulables para el legado. La ciudad libre anterior se conserva.
- El cliente antiguo puede seguir enviando ciudad sin códigos: queda sin
  clasificación territorial, incluso si ADMIN aprueba la institución.
- Solo ADMIN traslada la ubicación declarada a la institución al aprobar.
  Puede corregir una institución aprobada mediante otra revisión APROBADA con
  códigos diferentes, revisión vigente, mensaje, nota interna y confirmación.
- Cambios atómicos y auditados: actor, fecha, ubicación anterior/nueva; no
  autorrevisión. Conflictos concurrentes devuelven 409 sin cambios parciales.
- T4 extiende el directorio con filtros y ubicación oficial opcional; no publica
  ciudad libre, contactos, códigos de ingreso ni expedientes. T3 añade selectores ADMIN.
- Alcance inicial: sede representada por ese registro, sin instituciones
  multisede nuevas ni ubicación de estudiantes/GPS. Histórico por año: PR-I6-T.

Backend oficial: `C:\Users\LENOVO 14ALC6\Desktop\SaberPlus-Backend`.
Contrato y procedimiento completos: `backend/docs/PR_I5_T_TERRITORIO.md` de ese
repositorio. No copiar el catálogo a Flutter ni crear otra lista manual.

## Contrato disponible en código

- `GET /instituciones/territorio/departamentos`.
- `GET /instituciones/territorio/departamentos/:departamentoCodigo/municipios`.
- JWT requerido; listas completas del nivel solicitado, sin query/paginación.
- Ambas devuelven `version`, `fuente`, `consultadoEn` y `sha256`.
- Departamento: `codigo`, `nombre`, `anioFuente`.
- Municipio: campos anteriores, `departamentoCodigo` y `tipo` de la fuente.
- Conservar ceros iniciales: `05/05001`, no convertir códigos a números.

## Orden para continuar

1. **PR-I5-T1 — Catálogo/API:** implementada y comprobada automáticamente.
2. **PR-I5-T2 — Persistencia/aprobación:** implementada y probada localmente;
   migración no desplegada. Compatibilidad y alcance detallados arriba.
3. **PR-I5-T3 — Formulario Flutter y revisión ADMIN: implementada.** Seleccionar departamento
   y luego municipio/distrito/unidad territorial; al cambiar el primero se borra
   la selección incompatible. Carga/error/reintento, validación y restauración.
4. **PR-I5-T4 — Filtros del directorio: implementada.** Departamento/municipio opcionales,
   Todos, reinicio de paginación, filtros en servidor antes de paginar y descarte
   de respuestas tardías. Solo instituciones aprobadas. Ubicación desconocida
   no se inventa. Filtro por tipo requiere definir su catálogo aparte.
5. **PR-I5-T5 — Ensayo conjunto: aprobado localmente.** API/PostgreSQL temporal,
   panel y Android: filtros, paginación, vacío/red/reintento, legado, suspensión,
   solicitud/reenvío, aprobación y corrección territorial con historial.

Después: perfil institucional, solicitudes estudiantiles y PR-I6/PR-I6-T.
OV-1 y las demás funcionalidades acordadas siguen vigentes.

## Evidencia y límites

### Cierre vigente T5 — 11 de octubre de 2026

Usuario confirma aprobación final de SaberPlus Ensayo Corrección: panel muestra
Aprobada inmediatamente, conserva ficha e historial anterior; Android muestra
Institución aprobada. Con las confirmaciones anteriores se cierra el ensayo local
de T3/T4/T5: directorio por ubicación/nombre, paginación, cambios rápidos, legado,
errores de red y recuperación de catálogo/listado, ocultación de suspendida,
petición de información, restauración editable, reenvío sin duplicados y aprobación.
Primera institución corregida por ADMIN a Cesar/Valledupar: historial y presencia
en nueva ubicación/ausencia bajo Amazonas/Leticia confirmados en Android.

Límites: sin despliegue, migración remota ni validación iOS; push manual pendiente
del propietario. Consultar `git log` para los commits del cierre. La ficha
suspendida fue comprobada por HTTP 404, no por mensaje humano independiente.
Los códigos 20/20001 en la ficha privada del profesor no tuvieron confirmación
humana específica; el reflejo público sí. Nombres en lugar de códigos en esa
ficha siguen como mejora UX, no implementada. No cierra toda PR-I5 ni perfiles,
solicitudes de ingreso, ranking territorial o producción. Los checkpoints inferiores
son la secuencia histórica, no tareas pendientes que deban repetirse.

Siguiente bloque: perfil institucional y solicitudes estudiantiles de PR-I5.
Guardar coordinadamente ambos repositorios; push manual del propietario.
Regresión Flutter final: **769 aprobadas / 10 opt-in omitidas**, sin fallos;
duración 4:04. Formato de los cinco archivos Flutter modificados comprobado,
sin cambios; analyze sin incidencias en la corrección. Panel **95 aprobadas**,
23 módulos de sintaxis correcta. `git diff --check` limpio en ambos repositorios.

### Checkpoint T5 — 11 de octubre, preparación y ensayo automático

Docker Desktop/motor Linux operativo; celular Android autorizado por USB y
reverse43187 configurado. Sesión local propia nueva con 62 migraciones, API43187
y panel4173 HTTP200. Guion `--territory` **ejecutado y aprobado** contra API y
PostgreSQL reales: nacional20/5, Amazonas20/1, Cesar2, Bogotá1, Antioquia vacío,
nombre+territorio, legado nacional, estados ocultos, privacidad y parejas inválidas.
Evidencia privada `directory-territory-evidence.json` en el directorio temporal
de sesión; no copiar credenciales a Git. APK actual ARM64 compilada con defines
de ejecución sin credenciales, paquete `com.example.saber_plus.i2validation`
comprobado con aapt e instalación USB **Success**. Actividad abierta por ADB.
Usuario confirma en Android el login con la cuenta ficticia nueva y el directorio
nacional con instituciones de ensayo, Página 1, Siguiente y Filtrar por ubicación.
Usuario también confirma Amazonas/Leticia y Página 2 con una sola institución
(ensayo 21), con captura. Los demás filtros y revisión ADMIN siguen pendientes.
La captura detectó selectores pegados, etiquetas superpuestas y códigos internos
visibles: ajuste localizado de espaciado, etiquetas flotantes, resumen con nombres
y búsqueda más compacta, sin cambiar la lógica. Usuario confirma en Android que
las etiquetas ahora se ven bien y que el funcionamiento se conserva.
Validación del ajuste: 12 pruebas de directorio y 3 de catálogo territorial
aprobadas; `flutter analyze` sin incidencias. APK ARM64 i2validation recompilada
e instalada por USB con Success, sin borrar los datos de la app de prueba.

El harness ahora permite únicamente la migración territorial T2 sin commit,
mediante ruta explícita; las migraciones previas siguen leyéndose desde HEAD.
Arranque real aprobado con `pendingTerritoryMigration:true`; esta excepción
sustituye la necesidad de commit previo para ese ensayo concreto. Sin push,
despliegue ni modificación de base remota. Usuario confirma en Android que cambiar
a Cesar limpia el municipio y vuelve a Página 1; seleccionar Valledupar muestra
dos instituciones sin siguiente página. Usuario confirma Bogotá con una
institución y Antioquia sin municipio con mensaje de búsqueda vacía, sin error
de conexión. Usuario confirma que buscar «ensayo 22» con Cesar/Valledupar muestra
solo esa institución y que Todas las ubicaciones conserva el nombre y resultado.
Usuario confirma que vaciar nombre recupera Página 1 del listado nacional y que
ensayo 25 muestra «Ubicación pendiente de clasificar» sin datos inventados.
Tras retirar temporalmente reverse43187, usuario confirma en Android el error
«No pudimos cargar el directorio» al actualizar. Enlace USB restaurado;
usuario confirma que Reintentar recupera
el listado sin cerrar la app ni iniciar sesión otra vez. Tras cortar nuevamente
reverse43187, salir y volver a entrar al directorio, usuario confirma
«Reintentar departamentos» al abrir filtros, sin opciones inventadas. Enlace USB
restaurado; usuario confirma que Reintentar departamentos recupera los selectores
y que Cesar/Valledupar vuelve a mostrar sus dos instituciones. Usuario confirma
que cambiar rápidamente Amazonas → Cesar mantiene Cesar, sin reemplazo por una
respuesta anterior, y que Valledupar muestra dos instituciones. Próxima acción:
Usuario confirma que abrió ensayo 01. Suspendida únicamente esa institución
ficticia en la base temporal propia mediante el guion validado de sesión.
Comprobación HTTP aprobada: detalle 404, búsqueda sin resultados, 24 aprobadas
restantes y cuatro en Página 2 nacional. Usuario confirma en Android que ensayo
01 ya no aparece tras actualizar. La indisponibilidad del detalle tiene evidencia
HTTP 404; no se registra una confirmación humana separada de ese mensaje.
Usuario confirma formulario de solicitud abierto con profesor ficticio.
Próxima acción: completar solicitud ficticia Amazonas/Leticia y enviarla a revisión;
después comprobar persistencia, petición de información y revisión ADMIN.
Durante el envío de ensayo, usuario reporta encabezado inicial redundante
«Solicita la aprobación de tu institución». Ajuste Flutter: encabezado y explicación
inicial solo si no existe solicitud; conservar estado, detalles y correcciones
cuando se requiera información. Cinco pruebas de aprobación aprobadas, incluida
ausencia del encabezado después del envío. Confirmación visual nueva pendiente.
Análisis Flutter sin incidencias; APK i2validation recompilada e instalada por
USB con Success, sin borrar datos. No se cambia el flujo ni la aprobación backend.
Al reabrir solicitud, usuario reporta espera/timeout. Diagnóstico actual: API
health/ready HTTP 200, panel escuchando y PostgreSQL temporal activo; ADB no
detecta dispositivos. No se atribuye a un fallo del formulario: reconectar Android,
restaurar reverse43187 y repetir antes de confirmar el ajuste visual o cerrar T5.
Android reconectado y autorizado; reverse43187 restaurado y verificado, API
health/ready HTTP 200. Tras restablecer el enlace, usuario confirma que carga
la solicitud y aparece el estado indicado, sin encabezado inicial redundante.
Pregunta por los códigos de ubicación registrados: se explicó que no son GPS
ni aprobación. Mejora de legibilidad propuesta (nombres en lugar de códigos),
no implementada todavía en esta ficha. Panel local HTTP 200; próximo paso:
entrar como ADMIN ficticio y abrir la solicitud para pedir información.
Usuario confirma que SaberPlus Ensayo Territorial aparece en el panel ADMIN
local. Próximo paso humano: guardar Requiere información y comprobar en Android
que la solicitud conserva Amazonas/Leticia y permite corregir evidencia.
Desvío del guion confirmado por el usuario: eligió APROBADA, no Requiere
información; en Android aparece institución aprobada. No se acredita todavía
el ensayo de petición de información/restauración editable.
Defecto observado en panel: guardar recargaba ficha pero no listado/filtro,
conservando Pendiente hasta filtrar Aprobadas. Corregido en panel: mover filtro
al estado guardado, volver a Página 1, recargar listado y conservar ficha actual,
con protección frente a cierre/cambio de pantalla. Regresión panel 95 aprobadas,
sintaxis 23 módulos correcta; incluye transiciones a APROBADA y REQUIERE_INFORMACION.
Confirmación humana del ajuste pendiente. No revertir aprobación solo para repetir.
Tras recargar panel, usuario confirma que aparece Aprobada. Esto confirma el estado
guardado, no una nueva transición visual tras guardar. Próxima prueba: corregir
ubicación aprobada a Cesar/Valledupar, verificar historial y reflejo móvil/directorio.
Usuario confirma corrección ADMIN a Cesar/Valledupar: mantiene Aprobada, ficha
abierta e historial de cambio. Reflejo en app/directorio pendiente. Próximo paso:
actualizar estado en Android y consultar nombre con filtros antiguos/nuevos.
Usuario responde «sí aparece» al recorrido móvil. Se registra únicamente presencia
de la institución; falta confirmación explícita de códigos 20/20001 y ausencia
con Amazonas/Leticia antes de acreditar todos los puntos del reflejo territorial.
Tras aclarar navegación (profesor no tiene pestaña Más), usuario cambia a estudiante
y confirma presencia con Cesar/Valledupar y ausencia de esa institución con
Amazonas/Leticia, donde ve otras instituciones. Esto acredita traslado en listado
territorial, no búsqueda vacía por nombre: falta confirmar nombre enviado con Buscar.
Códigos en ficha del profesor no confirmados; petición de información sigue pendiente.
Usuario confirma búsqueda exacta «SaberPlus Ensayo Territorial» bajo Amazonas/Leticia
con mensaje «No encontramos instituciones para esta búsqueda». Combinación nombre/
territorio corregido acreditada. Próximo paso: otra cuenta de profesor ficticia para
petición de información y restauración editable, sin revertir institución aprobada.
Cuenta local adicional teacher-review@example.invalid creada con el guion
--review-teacher: valida sesión temporal propia/etiqueta del contenedor, no usa
base remota ni modifica la aprobación anterior. Misma contraseña privada de sesión,
sin copiarla a Git. Sintaxis del guion correcta. Usuario confirma formulario
abierto con la cuenta adicional y responde «listo» al envío de SaberPlus Ensayo
Corrección con Amazonas/Leticia. Usuario confirma revisión ADMIN a Requiere
información: filtro/listado cambian inmediatamente y ficha permanece abierta.
En Android confirma estado actualizado, formulario editable y Amazonas/Leticia
conservados. Esto acredita petición de información/restauración humana y el
ajuste de sincronización del panel. Próximo paso: corregir evidencia, reenviar
y comprobar mismo registro Pendiente, territorio y texto corregido en ADMIN.
Usuario confirma corrección de evidencia y reenvío: una sola solicitud SaberPlus
Ensayo Corrección en Pendiente, evidencia nueva y Amazonas/Leticia conservados.
Próxima comprobación: aprobación final desde Pendiente, actualización inmediata
de filtro/listado/ficha, historial completo y estado aprobado en Android.

### T4 — Filtros (11 de octubre)

- GET directorio combina `q`, `pagina`, `departamentoCodigo` y `municipioCodigo`.
  Municipio exige departamento; códigos se validan contra el catálogo oficial.
  Filtro SQL antes de skip/take, orden estable nombre/id, máximo 20 por página.
- Lista y detalle devuelven `ubicacion: null` o departamento/municipio con códigos,
  nombres oficiales y tipo territorial. Sin datos personales ni código de acceso.
  Legado sin clasificación sigue nacionalmente, no aparece por ubicación inventada.
- Flutter: botón Filtrar por ubicación, Todos y Todas las ubicaciones; cambiar
  departamento limpia municipio, cada cambio reinicia página 1 y las respuestas
  anteriores no reemplazan la consulta nueva. Fallos de catálogo ofrecen reintento;
  no cambian silenciosamente el filtro. Se muestran ubicaciones en lista/detalle.
- Demo explícita: un colegio Amazonas/Leticia y otro sin clasificación.
- T4 no agrega migración, ranking geográfico, afiliación, perfil completo ni tipo
  institucional. No usa GPS ni busca domicilio de estudiantes.

Pruebas dirigidas iniciales: 54 backend (directorio/catálogo) y 14 Flutter
(directorio/catálogo). Regresión backend: **1.319 aprobadas / 114 suites**;
Prisma generate y Nest build correctos, Prettier conforme.
Regresión Flutter: **769 aprobadas / 10 opt-in omitidas**, analyze sin incidencias;
incluye caso adicional de respuesta tardía tras cambiar de departamento.
313 enlaces locales Markdown comprobados, cero destinos ausentes. Sin commit/push.
Guion local `backend/tool/test_local_institution_directory.mjs --territory`
preparado, **no ejecutado en T4**. No confundir dobles HTTP/Prisma con SQL real.

### Guion de T5 para retomar

1. Revisar ambos repositorios; el harness lee migraciones de HEAD y admite solo
   la migración territorial T2 pendiente por ruta explícita. Guardar cambios
   coordinadamente para relevo. No ejecutar contra Render/Supabase ni usar datos reales.
2. Iniciar nueva sesión local propia con API, PostgreSQL temporal y panel; conectar
   Android USB, depuración/instalación autorizadas y pantalla desbloqueada.
   Credenciales temporales solo en archivos privados de sesión, nunca en docs/git.
3. Ejecutar el guion `--territory` con `SABERPLUS_LOCAL_SESSION` de esa sesión.
   Prepara 25 aprobadas: 21 Amazonas/Leticia, 2 Cesar/Valledupar, 1 Bogotá y 1
   legado sin ubicación; cuatro no aprobadas ocultas también con territorio.
   Comprobar paginación filtrada 20/1, filtro + nombre y errores de pareja.
4. Instalar APK actual contra esa API. En directorio: nacional 20/5; Amazonas
   20/1; Cesar 2; Bogotá 1; Antioquia vacío. Cambiar departamento limpia municipio
   y vuelve a página 1. Todas las ubicaciones recupera el legado. Revisar detalle.
5. Probar red caída/reintento del listado y catálogo, cambio rápido de filtro,
   conservar selección al paginar y ocultación tras suspender una institución.
6. Con profesor/ADMIN ficticios probar T3: solicitud con pareja válida, restaurar
   cuando se pida información, aprobar y corregir ubicación con historial y
   revisión vigente. Verificar que directorio use la ubicación ADMIN confirmada.
7. Documentar cada confirmación humana/HTTP/SQL por separado y el siguiente paso.
   Si falla un caso, repararlo y repetirlo antes de cerrar T5. No repetir juegos.

**T3, 11 de octubre:** formulario Flutter exige departamento y municipio del
catálogo autenticado; restaura códigos guardados, elimina selección al cambiar
departamento, controla versiones y respuestas tardías y ofrece reintento.
No solicita domicilio/GPS. Conserva ciudad anterior si no cambia la ubicación;
para selección nueva envía el nombre del municipio en el campo compatible ciudad.
Los estados no editables muestran ciudad declarada y códigos, sin inferir nombres.
ADMIN exige pareja para aprobar; puede corregir una institución aprobada con
revisión/confirmación/nota, sin suspenderla. Rechazar o pedir información no exige
que el catálogo esté disponible. Escrituras inciertas obligan a consultar estado.
Demo explícita con Amazonas/Leticia, Bogotá y Cesar/Valledupar, nunca fallback de red.

Pruebas dirigidas Flutter: **8 aprobadas**, más **8 del profesor** tras actualizar
su fixture para simular también el catálogo. La primera regresión detectó timeout
en esa prueba antigua por dependencia remota no simulada; corregido y repetido:
regresión completa **765 aprobadas / 10 opt-in omitidas**. `flutter analyze`
sin incidencias y formato conforme. Panel: **93 pruebas aprobadas**, sintaxis de
**23 módulos** correcta; 9 pruebas territoriales/revisión repetidas tras formatear.
311 enlaces locales Markdown comprobados, sin archivos destino ausentes.
No se reinstaló APK, no se probaron estos formularios en
celular/navegador real, no se desplegó ni se aplicaron migraciones remotamente.

**T2:** 66 pruebas dirigidas; regresión backend de **1.311 pruebas / 114 suites**,
Prisma generate, Nest build y tsc aprobados. **16 casos PostgreSQL 16 reales**
aprobados con Docker local, 62 migraciones (61 previas + T2), preservación de
registros anteriores, permisos, auditoría, duplicados y concurrencia. Contenedor
propio eliminado al finalizar. No se ejecutaron Flutter/Android porque aquí solo
se modificaron documentos. No se desplegó ni se aplicó la migración remotamente.

La sesión móvil anterior se cerró para liberar el motor de Prisma. Sus datos y
credenciales de ensayo eran temporales; iniciar sesión de prueba nueva cuando
corresponda. Guardar T1/T2 antes de usar el harness móvil que lee migraciones de HEAD.

**Antecedente T1:** 59 tests backend dirigidos aprobados (30 territoriales, 16 directorio,
13 aprobación); compilación Nest y carga del catálogo desde `dist` aprobadas.
Regresión completa backend: **113 suites / 1.304 pruebas aprobadas**; Prettier
conforme y sintaxis del importador comprobada. No se ejecutó Flutter al cambiar
solo documentación en este repositorio.
Las pruebas HTTP usan dobles de autenticación/base, no PostgreSQL real.
T1 no tuvo prueba física nueva porque todavía no había cambio visual. El ensayo
PR-I5A/B sigue cerrado en su alcance anterior, no acredita T2–T5.

## Relevo

Leer primero [ETAPAS_PENDIENTES](ETAPAS_PENDIENTES.md), este checkpoint y el
contrato backend. Verificar ambos repositorios/rama/diff. T5 cerrada localmente:
continuar con perfil institucional y solicitudes, sin repetir Rescate/T5 ni suponer
servicios de una sesión pasada todavía activos.
Separar commits funcionales y actualizar evidencia tras cada ensayo. No desplegar
ni ejecutar migraciones remotas por esta nota. El propietario hace el push.
