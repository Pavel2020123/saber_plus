# PR-I5-C3 — Solicitudes estudiantiles

## Reanudación vigente — 16 de octubre de 2026

**C3C cerrado localmente:10/10 casos del guion completados. Sigue C4 — código
institucional privado/revocable y cierre integrado de instituciones.**
Caso10: usuario confirma filtros Cancelada/Rechazada y Pendientes vacío; paginación
20+1 con Siguiente deshabilitado al final y retorno a Página1; Volver conserva
borrador, Salir lo descarta y no reaparece tras cerrar/reabrir la app. Confirma
cambio al docente lector sin solicitudes del alumno ni control reservado al propietario.
Finalmente confirma lectura con texto ampliado según el recorrido solicitado.
No hubo captura ni medición instrumental de escala/overflow: accesibilidad acreditada
por confirmación humana, no auditoría exhaustiva de todas las pantallas.
Evidencia Android/API/SQL repartida entre sesiones temporales identificadas; no
equivale a producción, iOS o nueva regresión global. Casos7–8 limitados a fallo
previo a escritura y recuperación; no pérdida de respuesta posterior al commit.
No se hicieron commits de instituciones, push, merge ni despliegue. Checkpoints
parciales inferiores son antecedentes conservados, no órdenes de repetir casos.

Caso10, reapertura: ante instrucciones de cerrar desde recientes y reabrir,
usuario confirma que el borrador descartado no reaparece. No se borraron datos ni
se reinstaló app. No acredita persistencia de un borrador sin descartar.
Siguiente cambio a teacher-reader@example.invalid: comprobar identidad y ausencia
de acceso de revisión reservado al propietario; después texto ampliado.

Caso10: usuario confirma Salir y reapertura del formulario con campo vacío.
Descarte explícito validado junto con conservación al elegir Volver. No implica
guardar borradores entre reinicios ni crear solicitud. Pendientes reapertura de app,
cambio de cuenta y texto ampliado; sigue9/10.

Caso10, borrador: usuario abre salida del formulario y observa opciones Volver/Salir.
Pulsa Volver y confirma que «Borrador sin enviar» permanece escrito. No se acredita
envío ni persistencia del borrador entre sesiones. Siguiente: repetir salida,
confirmar Salir y reabrir para comprobar descarte explícito; caso10 todavía abierto.

Caso10, paginación humana confirmada: tras desconexión/reconexión USB, usuario ve
las21 solicitudes y confirma Siguiente→Página2 con una solicitud, Siguiente
deshabilitado y Anterior→Página1. Recuperación USB realizada por usuario tras bloqueo
de ejecución de herramienta; no afirmar reconexión automática. Faltan protección
de borrador/salida, reinicio/cambio de cuenta y texto ampliado. Sigue9/10 cerrado.
Siguiente: absent@example.invalid prepara borrador sin enviar para probar salida.

Caso10: usuario confirma Pendientes vacío después de rechazo; sin registros del
filtro anterior. Preparación posterior de paginación: helper backend
tool/prepare_student_requests_pagination.cjs comprobado de sintaxis y ejecutado
solo sobre sesión propia. Crea21 alumnos c3-page-01..21@example.invalid y solicitudes
PENDIENTES por HTTP con mensajes Paginacion C3 01..21; no modifica las decisiones
anteriores. GET propietario comprueba páginas20+1, sin IDs comunes, hayMas true/false.
Preparación sintética, no validación humana de paginación. Siguiente: consultar
Pendientes en Android, Siguiente y Anterior, sin aceptar/rechazar fixtures.

Caso10 en curso: usuario informa que rechazó «Cupo C3» tras restauración y confirma
filtros: una cancelada y la otra rechazada, no pendiente. GET propio verifica
0041de76-c3c5-437e-8d52-5e338e6fe999 CANCELADA/revisión1, «conflicto c3»;
ca1ca099-a4a2-4fb5-936a-5d7fe91653a0 RECHAZADA/revisión1, «Cupo C3».
absent@example.invalid conserva ESTUDIANTE sin vínculo. No repetir el rechazo ni
anotar que vio Cupo C3 pendiente en este paso. Faltan estado vacío de Pendientes,
paginación, borrador/cambio de cuenta y texto ampliado; sigue9/10.

**Checkpoint actual:9/10 casos locales completos; sigue caso10.**
Caso9 cerrado: usuario intenta aprobar durante suspensión y observa «no se pudo
confirmar». SQL mantiene ca1ca099-a4a2-4fb5-936a-5d7fe91653a0 PENDIENTE/revisión0,
absent@example.invalid sin vínculo, solo creación auditada y ninguna aprobación.
Restaurada principal propia a APROBADA; limiteEstudiantes=NULL como al inicio.
Se acreditan bloqueo de revisión obsoleta, cupo y suspensión en este alcance local;
no afirmar que el mensaje genérico distinguió suspensión o conflicto de versión.
Siguiente: Consultar estado, filtro Canceladas para ver «conflicto c3», volver a
Pendientes para «Cupo C3»; luego paginación y protección de borrador/cambio de cuenta.
Los avances parciales inferiores se conservan como secuencia histórica, no pendientes actuales.

Caso9, suspensión preparada: usuario confirma pendiente «Cupo C3» con Aceptar
habilitado tras consultar. SQL cambia solo principal propia
c3dc8e83-af9a-4714-b0bd-e6f1325693fa de APROBADA a SUSPENDIDA;
solicitud ca1ca099-a4a2-4fb5-936a-5d7fe91653a0 sigue PENDIENTE/revisión0.
Restauración obligatoria al terminar: APROBADA; límite ya restaurado a NULL.
Siguiente gesto: Aceptar/Confirmar sin refrescar. No se acredita bloqueo hasta
respuesta humana y contraste persistido. Preparación por herramienta, no decisión humana.

Caso9, cupo confirmado: usuario intenta aceptar «Cupo C3» y observa aviso de cupo1.
SQL conserva ca1ca099-a4a2-4fb5-936a-5d7fe91653a0 PENDIENTE/revisión0;
absent@example.invalid sin institución, una creación auditada, ninguna aprobación.
Se restaura limiteEstudiantes=NULL (valor anterior) en principal propia, APROBADA.
Siguiente: consultar estado Android para habilitar revisión antes de preparar
suspensión temporal. No suspender hasta confirmar pendiente visible; caso9 sigue abierto.

Caso9: usuario confirma que Consultar estado retira la solicitud cancelada de pendientes.
Conflicto obsoleto validado; cupo preparado después, aún sin resultado humano:
por HTTP se crea ca1ca099-a4a2-4fb5-936a-5d7fe91653a0 para absent@example.invalid,
mensaje «Cupo C3», PENDIENTE/revisión0. Como fixture sintético se crea/aprueba para
zero@example.invalid la5c044c9e-f967-4631-b480-dc45ded2e1af, ocupando un cupo.
SQL configura limiteEstudiantes=1 solo en institución principal propia, tras verificar
un alumno vinculado. Valor anterior NULL, restaurar al finalizar el escenario.
Intento previo de límite0 rechazado por CHECK, no persistió; no alterar esa protección.
Estas acciones son preparación por herramientas, no pruebas humanas adicionales.
Siguiente: propietario consulta y trata de aceptar «Cupo C3»; debe impedir ingreso.

Caso9, intento obsoleto observado: usuario pulsa Aceptar/Confirmar en lista antigua
y reporta «no se pudo confirmar». No afirmó ver mensaje específico de versión.
GET propio posterior conserva0041de76-c3c5-437e-8d52-5e338e6fe999 CANCELADA/revisión1,
sin sobrescritura a APROBADA. Falta consulta humana de estado y retiro de pendientes;
cupos/suspensión todavía no probados en este caso. Siguen8/10 casos completos.

Caso9, conflicto preparado: usuario confirma pendiente visible en pantalla del
propietario. Desde sesión HTTP separada de absent@example.invalid se cancela por
DELETE autenticado la0041de76-c3c5-437e-8d52-5e338e6fe999 con revisión0;
respuesta CANCELADA/revisión1. Es acción de herramienta para provocar concurrencia,
no cancelación humana en Android. Una ejecución previa sin resultado fue detenida;
GET posterior todavía PENDIENTE/revisión0 antes del DELETE confirmado. Falta intento
humano de Aceptar desde la lista antigua, sin refrescar; no acreditar rechazo aún.

Avance caso9: usuario entra como absent@example.invalid y confirma envío/PENDIENTE.
GET propio verifica una solicitud0041de76-c3c5-437e-8d52-5e338e6fe999,
PENDIENTE/revisión0, mensaje real «conflicto c3», institución principal. Todavía
no se ha provocado conflicto ni ejecutado cancelación/decisión. Siguiente: propietario
abre esa pendiente en Android antes de cambiarla desde una sesión separada.

8/10 casos cerrados en el alcance local documentado. Siguen9 (conflictos/cupo/
suspensión) y10 (recorrido final). Servicios anteriores apagados por petición del
propietario; sesión nueva propia saberplus-i2-local-YO1GnL,65 migraciones, API43187
y panel4173. Android mn7tqwg6ozcy9d85 autorizado, reverse43187 y actividad de ensayo
abierta sin reinstalar ni borrar datos. Contraseña nueva solo en flutter-private.json,
clave AUTH_E2E_PASSWORD; no reutilizar credencial ni IDs anteriores.
Helper de preparación ejecutado: principal c3dc8e83-af9a-4714-b0bd-e6f1325693fa,
alternativa77bb1071-edad-4db6-a583-74f96c54783c, cancelada sintética de preparación
13ade584-47a7-4c5f-996d-7006c2c1b38f. No reconstruye ni sustituye evidencia humana
de aprobaciones previas. Alumno para caso9: absent@example.invalid, login HTTP
verificado ESTUDIANTE sin institución ni solicitudes. Preparación, no nuevo caso aprobado.
Siguiente gesto: entrar con ese alumno y preparar pendiente explícita para conflicto
entre sesiones. Los checkpoints inferiores del15 son antecedentes conservados.

## Checkpoint del propietario — 15 de octubre de 2026

**C3A backend y C3B Flutter implementadas localmente. Siguiente: C3C integrado.**
Este frente lo lleva el propietario; el compañero continúa OV-1 de forma independiente.
No cerrar toda la etapa por tener API/pantallas: falta ensayo integrado C3C.
Se mantiene la decisión de esperar para los commits de instituciones; no hacer push,
merge ni despliegue automático.

## Reanudación actual — 15 de octubre de 2026

La API/panel anteriores estaban detenidos y el contenedor de la sesión anterior
ya no existía, aunque quedaban archivos temporales. No usar sus credenciales ni IDs
contra esta base nueva. Nueva sesión propia `saberplus-i2-local-DdRR2v`,65 migraciones;
API43187 y panel4173 HTTP200, Docker Linux y Android autorizado/reverse43187.
APK ajustada ya instalada verificada; actividad abierta sin borrar datos ni reinstalar.

Preparación reproducible: backend `tool/prepare_student_requests_resume.cjs`, con
`SABERPLUS_LOCAL_SESSION` de la sesión nueva. Exige base temporal propia vacía,
rechaza sobrescribir fixtures y no acepta bases externas. Sintaxis y ejecución
aprobadas. Crea propietario/lector/instituciones y ejecuta crear/cancelar por HTTP
para reconstruir el punto de continuación, **no una prueba humana adicional**.
SQL confirma una fila CANCELADA/revisión1, dos auditorías (creación/cancelación),
alumno sin institución. Si falla la preparación, inspeccionar antes de reintentar.

- Institución principal actual: `d9f26224-308a-48eb-b5a2-bc3ffa930b39`.
- Alternativa actual: `a617753a-4915-4da0-88cf-63f5a03965fd`.
- Solicitud de preparación: `cfddf1a2-2012-4d18-a285-234e8a161af8`.
- Cuentas: `student@example.invalid`, `teacher@example.invalid`, `teacher-reader@example.invalid`.
- Contraseña nueva solo en `flutter-private.json` de esta sesión, `AUTH_E2E_PASSWORD`.

**Estado actual:8/10 casos completos en el alcance local documentado. Siguiente: caso9, conflictos.** La cancelación humana anterior
sí fue confirmada y comprobada por SQL antes de detenerse los servicios. Tras
reanudar, usuario confirma que queda Buscar instituciones y no el acceso de solicitud.
Distinguir este chequeo tras reanudación de una secuencia humana ininterrumpida.
Las referencias de sesión/IDs inferiores son evidencia anterior, no parámetros actuales.

## Comportamiento acordado

- Un estudiante sin institución puede pedir ingreso a una institución APROBADA.
- Una sola solicitud pendiente por estudiante; puede consultar historial y cancelarla.
- Solo el propietario docente vigente en la institución aprobada acepta/rechaza.
- Aprobación: vínculo institucional del alumno sin promoverlo a profesor ni asignar grupo,
  con validación atómica del cupo. No trasladar a quien ya pertenece a otra institución.
- Rechazo/cancelación: historial conservado, sin vínculo. Estados privados consultables
  serán los avisos dentro de la app; no hay push, correo ni contador de no leídos en C3A.
- Solicitudes docentes y códigos de grupo existentes no se cambian. Código institucional
  privado y revocable es C4, pendiente.

## Contrato implementado en el backend

Base `/instituciones/ingresos-estudiantes`, JWT y política de correo existentes:

| Operación | Método/ruta | Datos |
|---|---|---|
| Solicitar | POST base | UUID v4 `id`, UUID v4 `institucionId`, `mensaje?` hasta 500. |
| Historial del alumno | GET `/me` | `pagina?`, predeterminada 1. |
| Cancelar | DELETE `/:id` | Entero JSON `revision`. |
| Bandeja del propietario | GET `/pendientes` | `pagina?`, `estado?`, predeterminado PENDIENTE. |
| Decidir | PATCH `/:id/revision` | Entero `revision`, `decision` APROBAR/RECHAZAR. |

Listados de 20 con `solicitudes`, `pagina`, `hayMas` (página máxima10000).
Registro: `id`, `institucion:{id,nombre}`, `estado`, `mensaje`, `revision`,
`fechaCreacion`, `fechaActualizacion` ISO. Bandeja añade `estudianteNombre`.
No hay correos, IDs del estudiante/revisor ni códigos privados en respuestas.
Estado: PENDIENTE/APROBADA/RECHAZADA/CANCELADA.
401 sesión, 403 permisos, 404 ajeno/no disponible, 409 conflicto, 400 datos/cupo.

Generar el UUID del intento **antes de enviar** y conservarlo ante respuesta incierta.
Repetirlo consulta la misma operación, sin duplicar, editar mensaje ni reabrir estado.
Tras cancelar/rechazar, una solicitud nueva usa otro UUID. Consultar ante conflicto;
no reenviar automáticamente con un ID nuevo. Ninguna mutación optimista debe anunciar
aprobación hasta recibir confirmación o reconciliar el estado.

Contrato completo y reproducción: `SaberPlus-Backend/backend/docs/PR_I5_C3_SOLICITUDES.md`.
No copiar credenciales de ensayos al repositorio.

## Evidencia local del backend

14 de octubre: build correcto; Jest **118 suites / 1.411 pruebas**, incluidas37 nuevas;
**14/14 HTTP/PostgreSQL** con65 migraciones en base temporal propia. Comprobados
permisos/privacidad, índice de una pendiente, reintentos idempotentes, cancelación,
aceptación/rechazo, historial, suspensión, capacidad, concurrencia por último cupo,
cancelación contra aceptación y rollback de vínculo/decisión si falla auditoría.
La primera prueba de cupo usó un fixture cero inválido; se corrigió para respetar
la restricción existente y la ejecución final completa pasó sin relajar seguridad.

No hay prueba humana Android ni ensayo Flutter/API de C3 todavía. Migración nueva solo
aplicada en base temporal; sin despliegue Supabase/Render ni pruebas iOS. C2 conserva
sus resultados y observaciones en [acta del logo](PR_I5_C2_LOGO.md).

## C3B implementada — 15 de octubre

1. Cliente/repositorio/modelos con patrones actuales, sin reconstruir arquitectura.
2. Ficha institucional con solicitud y confirmación, mensaje opcional; mostrar estado
   pendiente sin otro formulario; no ofrecer nueva solicitud si ya existe vínculo.
3. Historial privado del alumno: actualizar, paginar, cancelar con confirmación y ver
   aceptación/rechazo, sin filtrar información de otro usuario al cambiar sesión.
4. Bandeja del propietario con confirmar aceptar/rechazar y recarga del estado final;
   docentes lectores sin facultad de decidir. No mezclar con solicitudes docentes.
5. Carga/error/reintento y resultado incierto: conservar UUID/borrador, consultar estado,
   no duplicar ni ocultar conflictos/cupo agotado. Mantener accesibilidad.
6.27 pruebas dirigidas aprobadas: contrato, UUID, validación, privacidad/permisos,
   reintento con mismo ID, reconciliación sin nuevo POST, cancelación, aceptación/rechazo,
   carga/error, filtro/página, límite500, salida y borrador, cambio de cuenta/respuesta
   tardía y ancho320/texto2x. Regresión completa: **834 aprobadas /13 opt-in
   omitidas**; análisis sin incidencias. Una actualización de XP no reinicia el
   borrador: solo se reinicia al cambiar identidad/rol/demo o vínculo institucional.

Rutas de acceso: estudiante → Más → acceso contextual de ingreso, solo cuando procede;
para crear → Buscar instituciones → ficha → Solicitar ingreso. Propietario → Espacio del profesor →
Solicitudes de estudiantes. La bandeja no reemplaza la administración docente.
Se invalida contexto institucional al cambiar de cuenta real, no solo al cambiar demo.
La demostración explica que necesita cuenta real; nunca envía ni simula un ingreso.

### Ajuste UX solicitado durante caso2 — 15 de octubre

- Sin solicitud, cancelada, aprobada o cuenta vinculada: no hay acceso permanente
  «Mis solicitudes» en Más. Se conserva «Buscar instituciones» y «Mi institución y grupos».
- Pendiente: acceso «Solicitud de ingreso · Pendiente», con nombre y consulta manual.
- Última solicitud rechazada sin consultar: «Respuesta a tu solicitud de ingreso».
  Al abrir y mostrar el resultado se recuerda la lectura y se retira el acceso rápido;
  el rechazo sigue visible en el historial, no se borra del backend.
- Lectura es una preferencia **local por cuenta y UUID/revisión**, no sincronizada entre
  dispositivos. No almacena mensaje/credenciales ni cambia permisos/decisiones. Si falla
  la preferencia, se conserva el aviso y el resultado; no se marca lectura ficticia.
- Se actualiza al volver de solicitudes, cambiar de cuenta, reactivar la ruta/app y
  al pulsar actualizar. Un fallo de red ofrece reintento, no inventa pendiente ni vacío.
- Si la aprobación llega con perfil de sesión antiguo, se solicita actualizar el vínculo.
  «Mi institución y grupos» diferencia institución aceptada sin grupos de cuenta sin vínculo;
  no se asigna un grupo automáticamente. Contexto de grupos se invalida por cuenta/vínculo.
- Backend, migraciones y la solicitud humana pendiente se conservan. No hay nuevas
  migraciones ni despliegue por este ajuste. Regresión anterior834/13 no se declara
  reejecutada después de este cambio. Verificación: **86/86 pruebas dirigidas** de
  acceso contextual/solicitudes/grupos/router/accesibilidad aprobadas (12 nuevas),
  análisis sin incidencias y APK de ensayo nueva compilada. Instalación y confirmación
  humana del menú se registran debajo; no equivalen a aprobar los demás casos.

APK ajustada instalada por USB con **Success**, paquete `.i2validation` verificado,
sin borrar datos; actividad abierta. SQL conserva la solicitud humana
`2b4a7c92-32ef-4809-89a5-7f8f7060bd09` PENDIENTE/revisión0. API200/reverse43187
vigentes. Pendiente humano: abrir Más y confirmar acceso contextual; después abrirlo
y comprobar pendiente sin formulario. No se decidió ni canceló la solicitud por herramientas.

## Siguiente trabajo exacto — C3C integrado

### Preparación ejecutada — 15 de octubre

- Sesión temporal propia `saberplus-i2-local-PBB898`,65 migraciones, API43187
  y panel4173 HTTP200, configuración del panel sin demo y apuntando a API local.
- Android `mn7tqwg6ozcy9d85` autorizado; reverse43187 comprobado.
  APK debug nueva compilada, paquete `.i2validation` verificado, instalación
  **Success** sin borrar datos; actividad abierta. No confirma todavía la pantalla humana.
- Alumno `student@example.invalid` sin vínculo ni solicitudes; propietario
  `teacher@example.invalid`; lector `teacher-reader@example.invalid` con rol
  institucional ADMINISTRADOR, sin facultad de revisar solicitudes estudiantiles.
- Institución aprobada `Institucion de ensayo C3`, ID
  `a9b7bf03-0734-4d16-96c4-63f2f9ef293a` (Leticia/Amazonas); alternativa aprobada
  `Institucion alternativa C3`, ID `7055cc6a-451a-47bd-b788-6f3f3a33f425` (Valledupar/Cesar).
- Smoke HTTP local: login, historial/bandeja vacíos y privados, estudiante sin permiso
  de bandeja, detalle disponible y tipos JSON estrictos aprobados. No creó solicitudes.
- Se corrigió coerción implícita de `revision`/`mensaje` conservando el tipo original
  en DTO;37 pruebas dirigidas pasan con el mismo modo de conversión que la API.
  HTTP rechaza revisión texto/booleano/null y mensaje numérico. Las cifras de regresión
  anteriores corresponden a la ejecución previa a este ajuste; no son una reejecución.
- Contraseña ficticia solo en `flutter-private.json` de la sesión actual, clave
  `AUTH_E2E_PASSWORD`. Nunca copiarla al repositorio ni incrustarla en APK.

**Estado humano:8/10 en el alcance local documentado. Siguiente: caso9, conflictos.**
Conservar intactos los vínculos aprobados de student@example.invalid y zero@example.invalid.
La captura del usuario confirma Institución vinculada, sin grupos asignados.
Buscar instituciones es el directorio y permanece disponible: no es el acceso de solicitud.
No repetir casos1–3 por notas históricas; el historial cancelado se conserva.
No contar instalar/abrir actividad como aprobación humana. Si expira la sesión, recrear
fixtures propios; no usar estas credenciales o IDs contra otra base.

Preparar sesión temporal propia y65 migraciones con el supervisor backend, API43187,
propietario de institución aprobada, docente lector y alumnos ficticios sin vínculo.
No asumir que fixtures de otro ensayo siguen activos; no publicar contraseñas ni tokens.
Primero ensayos Flutter/API del contrato remoto; después compilar APK de ensayo actual,
instalar por USB y mantener Android desbloqueado/depuración autorizada. Si Windows
bloquea Prisma, detener la API propia antes de regenerar; no tocar servicios externos.

Guion humano: **8 aprobados y2 pendientes en el alcance local documentado**.
Casos7–8 cubren desconexión previa a escritura, no pérdida de respuesta tras guardar.
Las aprobaciones y sus límites se detallan debajo.

| Caso | Comprobar en app y contrastar con API/SQL |
|---|---|
|1| Alumno abre ficha, escribe/cancela confirmación sin enviar; nombre y mensaje correctos. |
|2| Enviar una vez: pendiente sin volver a formulario; consulta/reabrir conserva, sin vínculo previo a aceptar. |
|3| No permite segunda pendiente en otra institución; cancelar con confirmación y conservar historial. |
|4| Propietario ve nombre/mensaje; docente lector y estudiante sin botones de revisión; sin datos ajenos. |
|5| Rechazar y consultar como alumno; aviso hasta consultar, historial conservado y nuevo intento explícito. |
|6| Aceptar: alumno conserva rol ESTUDIANTE sin membresía docente/grupo; acceso rápido desaparece y Mi institución muestra vínculo aunque no haya grupos. |
|7| Sin conexión durante envío/decisión: error sin éxito falso, borrador/UUID conservados, consulta antes de reintentar. |
|8| Recuperar conexión: reconciliar envío ya guardado o reenviar mismo intento sin duplicación; contraste SQL/auditoría. |
|9| Otra sesión cambia revisión/estado, cupo agotado o suspensión: no sobrescribir ni vincular indebidamente. |
|10| Paginación/filtros, salir con borrador, reiniciar/cambiar sesión, texto grande; sin datos cruzados. |

### Caso1 — aprobado localmente,15 de octubre

El usuario confirmó estar en la ficha y, tras escribir, abrir confirmación y pulsar
Volver, confirmó que el texto seguía escrito. SQL de la sesión propia:0 solicitudes
del alumno,0 auditorías de solicitudes, rol ESTUDIANTE y sin vínculo institucional.
Se acredita conservación del borrador y ausencia de envío persistido; no demuestra
todavía envío, aceptación, rechazo ni recuperación de red. Siguiente: caso2.

### Caso2 — aprobado localmente,15 de octubre

Usuario confirma que aparece pendiente tras enviar. SQL: una solicitud
`2b4a7c92-32ef-4809-89a5-7f8f7060bd09` a la institución principal, estado PENDIENTE,
revisión0 y exactamente una auditoría de creación. Alumno conserva ESTUDIANTE,
sin vínculo institucional ni membresía docente. No hubo duplicación en este envío.
Usuario confirmó consulta/reapertura con pendiente y, después del ajuste UX,
confirmó acceso contextual y solicitud visible sin formulario. Reconsulta SQL:
misma solicitud PENDIENTE/revisión0, una creación y sin vínculo. Caso2 cerrado
en este alcance; siguiente caso3, bloqueo de segunda solicitud y cancelación.

Registrar cada resultado con actor, acción, respuesta humana y evidencia SQL cuando
corresponda; las27 automáticas no sustituyen estas10. Los casos pueden dividirse si
aparecen errores, sin marcar todos aprobados por una confirmación genérica.

### Caso3 — aprobado localmente en el alcance registrado

Desde institución alternativa el usuario observa navegación a la solicitud pendiente
anterior, no un nuevo envío. No confirmó un mensaje explicativo específico: registrar
mejora de claridad para el posterior pulido UX, no afirmar que vio ese aviso.
Luego pulsa Cancelar solicitud → Volver y confirma que sigue pendiente.
SQL: exactamente una solicitud, la original a institución principal, PENDIENTE/revisión0,
una auditoría total de solicitud (creación) y sin vínculo. No se creó segunda ni hubo
cancelación persistida en ese momento previo a Confirmar.

Después el usuario eligió Confirmar y confirmó estado Cancelada. SQL ejecutado antes
de detenerse los servicios verificó la misma fila conservada, CANCELADA/revisión1,
una auditoría de creación y una de cancelación, rol ESTUDIANTE y sin vínculo.
Tras reanudación con fixture cancelado identificado, usuario confirma ausencia del
acceso de solicitud en Más: queda Buscar instituciones y el directorio muestra
las dos instituciones ficticias. Se cierra caso3 con la limitación explícita de que
el último chequeo visual fue después de reconstruir el fixture, no una secuencia
humana ininterrumpida. Historial y auditorías originales se verificaron antes de
la interrupción; no atribuirlos a la base nueva. Siguiente: caso4, permisos.

Después C4 código institucional y cierre integrado. Rediseño visual general y tutorial
inicial se conservan para el final; no condicionan estas pruebas funcionales.

### Caso4 — aprobado localmente: propietario y lector

Usuario confirma dos entradas: cancelada de preparación y nueva pendiente.
SQL: `cfddf1a2-2012-4d18-a285-234e8a161af8` CANCELADA/revisión1 y nueva
`997ed62b-92d4-4f3d-81f0-ca40985fed08` PENDIENTE/revisión0, una creación por fila.
El texto real escrito es `permiso 3`, no el ejemplo propuesto en instrucciones;
no sobrescribirlo para coincidir con el guion. Alumno conserva ESTUDIANTE sin vínculo.
Usuario entra como propietario teacher@example.invalid y confirma solicitud,
mensaje `permiso 3` y botones Aceptar/Rechazar. No se indicó decidir y no se
declara decisión realizada en este caso. Después el usuario entra como lector y
confirma que no aparece Solicitudes de estudiantes. Comprobación HTTP adicional:
lector y alumno reciben403 al consultar la bandeja del propietario con sus propias
sesiones. No se ejecutó una decisión mediante herramientas ni se afirma prueba
humana adicional de acceso forzado. Siguiente caso5: rechazo por propietario.

### Caso5 — aprobado localmente

Usuario, como propietario, confirma rechazo y retiro de pendientes tras Rechazar/
Confirmar. SQL: solicitud `997ed62b-92d4-4f3d-81f0-ca40985fed08` RECHAZADA/revisión1,
mensaje `permiso 3` conservado, una auditoría de creación y una de rechazo.
Alumno sigue ESTUDIANTE sin vínculo. Usuario confirma aviso antes de abrir y luego
confirma que vio Rechazada y que el acceso se retiró al volver a Más; Buscar
instituciones permanece. Lectura local acreditada por observación humana, no por
inspección de almacenamiento ni sincronización entre dispositivos. Usuario envía un
nuevo intento explícito y confirma pendiente junto con las anteriores. SQL verifica
tres filas distintas: cancelada de preparación/revisión1, rechazada/revisión1 intacta
y nueva `86c61a40-2b21-4f63-9474-0d632b0de416` PENDIENTE/revisión0. Una creación por fila;
no se reabrió la rechazada. Texto real nuevo `aprobación c3` (distinto del ejemplo,
conservarlo). Alumno ESTUDIANTE sin institución ni membresía docente. Caso5 cerrado.

### Caso6 — aprobado localmente

Solicitud pendiente para propietario: `86c61a40-2b21-4f63-9474-0d632b0de416`, mensaje
`aprobación c3`, Institucion de ensayo C3. Propietario confirma Aceptar/Confirmar,
confirmación de aceptación y retiro de pendientes. SQL: APROBADA/revisión1,
revisor teacher@example.invalid, una creación/una aprobación auditadas. Alumno
ESTUDIANTE vinculado a `d9f26224-308a-48eb-b5a2-bc3ffa930b39`, cero membresías docentes.
La base no contiene grupos (0 filas Clase), no hubo asignación automática.
Usuario confirma ausencia del acceso de solicitud y aporta captura de Mi institución
y grupos: Institución vinculada, sin grupos asignados. La confusión inicial fue abrir
Buscar instituciones (directorio), no un fallo de persistencia. Reconsulta SQL y login
HTTP confirman el vínculo de student@example.invalid. Caso6 cerrado; no repetir aprobación.
Casos7–8 usarán otro alumno ficticio sin vínculo; no desvincular al ya aprobado.

### Caso7 — preparación, todavía no ejecutado en Android

API43187 accesible y Android autorizado con reverse43187. Login HTTP verificado de
zero@example.invalid: ESTUDIANTE sin institución; GET de solicitudes propias devuelve
historial vacío. Usar esa cuenta y la contraseña temporal vigente. Primero abrir ficha
y escribir borrador con conexión; después cortar solo el reverse USB antes del envío.
Ese corte prueba fallo previo al POST, no pérdida de confirmación tras una escritura.
No declarar aprobado hasta observación humana y contraste de solicitudes/auditoría.

Avance humano de caso7: zero@example.invalid prepara un borrador; el texto propuesto
en el guion era «Prueba de conexión C3», no fue leído del dispositivo.
Se retira solo reverse USB43187 antes de enviar, sin detener la API. Usuario confirma
«no se pudo confirmar la operación» y conservación del texto. Se restaura reverse;
GET autenticado de solicitudes propias sigue vacío. No hubo solicitud persistida
en este intento offline. Pendientes consulta desde Android y reintento del mismo
envío (caso8), además del fallo durante decisión; no cerrar todo caso7 todavía.

Recuperación de envío: usuario confirma que Consultar estado actual permite reintentar
el mismo envío y conserva su texto; después confirma PENDIENTE al reintentar una vez.
SQL: única solicitud f790925d-1b8b-4675-a4c2-5bf2844680ec, PENDIENTE/revisión0,
una auditoría SOLICITUD_ESTUDIANTE_CREADA para zero@example.invalid; rol ESTUDIANTE
sin vínculo. Mensaje realmente persistido: «Hola c3», distinto del ejemplo del guion.
Usuario confirma expresamente que «Hola c3» era su texto original: conservación
del borrador acreditada por confirmación humana y valor persistido.
Sin duplicación observada; no prueba pérdida de respuesta después de escritura ni
reenvío duplicado al servidor. Faltan fallo de decisión y alcance restante7–8.

Fallo de decisión: propietario abre la pendiente «Hola c3». Se retira reverse43187
antes de Aceptar/Confirmar. Usuario confirma aviso de operación no confirmada.
SQL posterior: misma f790925d-1b8b-4675-a4c2-5bf2844680ec PENDIENTE/revisión0,
alumno ESTUDIANTE sin institución; solo una auditoría de creación, ninguna decisión.
Se restaura reverse43187. Pendiente consultar estado desde Android y decidir de nuevo
con conexión; no afirmar aprobación ni pérdida de respuesta posterior a escritura.

### Cierre casos7–8 — aprobados localmente con alcance limitado

Tras restaurar conexión, usuario consulta estado y confirma botones de revisión;
pulsa Aceptar/Confirmar una vez y confirma éxito/retiro de pendientes. SQL verifica
f790925d-1b8b-4675-a4c2-5bf2844680ec APROBADA/revisión1, texto «Hola c3»;
zero@example.invalid conserva ESTUDIANTE y queda vinculado a institución principal.
Exactamente una creación y una aprobación auditadas. No hubo aprobación offline,
éxito falso ni duplicación observada en recuperación de creación y decisión.
Casos7–8 cerrados para caída previa a escritura y recuperación por consulta/reintento.
No se inyectó pérdida de respuesta después del commit ni se observó el UUID en tráfico
Android: no atribuir a esta prueba esos alcances. Quedan casos9 y10.
