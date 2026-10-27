# MA-1R / R4 — Validación integrada local

**Seguimiento del18–19 de octubre de2026. R4 cerrada localmente el19.**
[R3 implementada](MA1R_R3_APP_PANEL.md), [checkpoint maestro](MA1R_REPORTES_PREGUNTAS.md).
OV-1 sigue separado. Integración Git confirmada abajo, sin despliegue ni cambios en producción.

## Entrega Git integrada el19 de octubre

Commits funcionales locales: Flutter `418c291`, backend/panel `a747c32`.
Documentación guardada en Flutter `0a622e6` y backend `6a74f55`.
Rama de entrega: `feat/ma1r-reportes-preguntas`. Push comprobado e integración
autorizada por el propietario: [app PR #6](https://github.com/Pavel2020123/saber_plus/pull/6)
como `21757a1`, [backend PR #9](https://github.com/Pavel2020123/SaberPlus-Backend/pull/9)
como `eef0d40`. [CI backend del PR](https://github.com/Pavel2020123/SaberPlus-Backend/actions/runs/39321480923)
aprobado: admin/verify, instalación, build, pruebas, controles locales y auditoría.
[CI posterior de main](https://github.com/Pavel2020123/SaberPlus-Backend/actions/runs/39321700998)
también aprobado para el merge backend `eef0d40`.
No hay workflow Flutter remoto: QA-1 pendiente, conservar evidencia local sin
presentarla como CI. Esta integración no ejecuta ni autoriza migraciones/despliegues
remotos. Siguiente bloque recomendado: preparación local C5, archivos generales.
Este registro sustituye las esperas para crear commits/publicar/integrar de las notas anteriores.

## Cierre local del19: remate visual confirmado

El propietario solicitó levantar servicios para comprobar la retirada del botón
inferior. Docker Linux/celular USB ARM64 autorizados comprobados; nuevo harness
con67 migraciones temporales, API43187/panel4173 real activos. Salud sin token401
y panel200 comprobados; reverse USB43187 restaurado/listado confirmado. Contenedor
`postgres:16` activo, distinto de las instancias anteriores ya limpiadas.
Preparador normal (sin `--resume-case7`) creó tema de ensayo/dos preguntas y
aprobó3 smoke, sin reportes ni casos humanos nuevos. Es únicamente preparación
para abrir formulario después de una práctica calificada, no repetir12 casos.
Credenciales nuevas solo en `flutter-private.json` del directorio del harness;
no imprimir/versionar ni usar las caducadas. Build Gradle debug finalizado con0,
solo cuatro defines públicos dev/URL local; sin claves en compilación. aapt verificó
paquete separado `com.example.saber_plus.i2validation`/MainActivity. APK nueva del19
(340241645 bytes) enviada por USB e instalación **Success**; Activity abierta y
reverse43187 restaurado. No borró datos ni sustituyó instalación normal.
El propietario confirmó login, abrió Reportar desde la revisión y verificó
ausencia del botón inferior («si no esta»). Escribió el detalle de prueba sin
enviarlo, volvió con la flecha superior y reabrió la misma pregunta: «si sigue
apareciendo». La APK instalada conserva el borrador sin botón redundante.
Es regresión del ajuste del caso8, no caso humano13 ni repetición de12.
**R4 cerrada localmente** con12/12 humanos,45/45 integradas repetidas tras fix y
regresiones indicadas abajo. Entrega Git integrada según el registro superior;
quedan staging/operación y QA-1 separados, sin despliegue efectuado en esta tarea.

## Pruebas automáticas del19: aprobadas

**Corrección posterior a una repetición fallida:** después de43/43 y45/45,
hubo44/45 por carrera ADMIN con200/503 en vez de200/409, sin doble decisión.
Barrera de planificación/DB real confirmó PrismaP2010/SQLSTATE40001. Servicio
corregido para reintentar únicamente conflictos raw40001/40P01 además de los
códigos anteriores, con máximo3 intentos; otros errores conservan503/rollback.
Dirigidas100/100, TypeScript/ESLint del servicio y dos ejecuciones45/45 integradas
tras fix aprobados. La última observa exactamente un conflicto raw40001 real
antes de recuperar200/409, sin duplicar decisión/auditoría.40P01 tiene evidencia
unitaria, no deadlock real inducido. Global post-fix **121 suites/1567 aprobadas**
(121,4s) y build completo correctos. No sumar ejecuciones como casos distintos.
La parte automática terminó; remate visual posterior confirmado arriba.

En `SaberPlus-Backend/backend`, `npm run test:question-reports:postgres` ejecuta
`tool/test_question_reports_postgres.mjs` y `test/question-reports-postgres.test.cjs`.
**45/45 integradas aprobadas**, cero omitidas/canceladas (primera ejecución43/43,
ampliada con medios/paginación; no sumarlas como casos distintos). Instancia nueva
PostgreSQL16 tmpfs/loopback,67 migraciones y credenciales propias, sin `.env`,
sin reutilizar datos humanos ni tocar OV-1/producción; limpieza final comprobada.

Nest/Prisma/guards/DTO/middleware reales con JWT ficticios locales, no mocks de DB
ni bootstrap productivo completo. Cubre roles/correo/evidencia, DTO Unicode,
privacidad/snapshot/ID archivado/FK, recibos/dedupe, carreras de UUID/ADMIN,
rollback SQL real, tasas/cuotas durables, ACL/RLS efectivo, paginación/cobertura.
La pérdida de respuesta después del commit se reprodujo destruyendo el socket:
recibo/replay idénticos sin escritura doble. Es evidencia automática adicional,
distinta del corte previo al envío de los casos humanos5–6. Dos apps HTTP en un
proceso prueban tasa compartida DB, no despliegue distribuido/proxy productivo.
Contrato, comando, alcance y límites en `backend/docs/MA1R_R4_VALIDACION_LOCAL.md`.

Regresión Flutter del19: **920 aprobadas/13 opt-in omitidas** y análisis limpio.
Panel109/109/sintaxis26; controles locales12/12; TypeScript y build completo
backend aprobados. Jest global inicial1559/1 timeout de certificado HTML5s;
archivo aislado8/8 sin modificar código/timeout, repetición global sin otras
suites pesadas **121 suites/1560 aprobadas**, cero fallos (93,5s). Se conserva
la incidencia inicial, no se afirma ni corrige un defecto funcional sin evidencia.
El primer build EPERM por DLL Prisma cargada se resolvió cerrando la sesión
temporal humana con control stop tras verificar propiedad; limpieza confirmada.
Esa base/credenciales ya caducaron. Las bases automáticas también se retiraron;
no se borraron imágenes de Docker ni datos habituales del propietario.

Resultado backend final posterior al fix: **121 suites/1567 aprobadas**,100
dirigidas,45/45 integradas repetidas dos veces, TypeScript/build/ESLint del servicio
correctos. Las1560 globales del párrafo anterior son la ejecución pre-fix, sin las7
unitarias nuevas. No se cambia ni se oculta la incidencia inicial de certificados.

Remate de reinstalación/retirada del botón inferior confirmado: **cierre local R4**.
CI/PR, retención/operación y staging/producción siguen separados; nada se publicó.

## Reanudación del 19 de octubre: recorrido humano completo

La sesión temporal anterior terminó. Se levantó una base tmpfs nueva con las67
migraciones locales, API43187 y panel4173 real. Comprobados HTTP401 sin token en
el listado privado y HTTP200 en el panel; reverse USB43187 restaurado y listado
comprobado. APK debug del18, ya con Más → Mis reportes de preguntas, instalado
por USB con resultado **Success** y MainActivity abierta. No se borró ni sustituyó
la app normal. El propietario confirmó el nuevo acceso y los tres reportes
PENDIENTE: «si muestra 3 preguntas en pendiente». Es el inicio del caso7,
no su aprobación completa. Se retiró solo reverse USB43187 y se comprobó el
listado sin ese mapeo; API401 sin token/panel200 comprobados antes del corte.
El propietario confirmó el error «No pudimos consultar tus reportes» al recargar
sin conexión. Reverse USB43187 restaurado y comprobado; API401 sin token disponible.
Tras pulsar Actualizar estado otra vez, el propietario confirmó «si volvieron
a aparecer»: regresaron los tres pendientes. **Caso7 aprobado; total7/12**.
Se comprobó error explícito al recargar sin red y recuperación al restaurarla,
no una lista vacía presentada como éxito. No se ensayó aquí pérdida de respuesta
tras commit, persistencia tras reiniciar ni la suite integrada restante.

Para retomar sin repetir los seis casos aprobados, el preparador se ejecutó con
`--resume-case7`: crea contenido por ADMIN, completa/califica una práctica por
la API estudiantil y envía tres reportes más un intento duplicado por esa API.
No inserta historial inventado directamente en tablas. Listado propio: tres
PENDIENTE; cobertura: tres abiertos sobre una pregunta distinta. Es preparación
**automática**, no nuevos envíos humanos ni prueba de recuperación de red.
El verificador de solo lectura `--case6` confirmó estructura/recibos/snapshot y
etiquetó esta ejecución `r4-automatic-resume-check-6`, `manualCaseClaim:false`.
Sintaxis de ambos scripts comprobada. En este arranque todavía no se habían
repetido análisis/80 dirigidas del18. Después se ejecutaron análisis y81 dirigidas
por la corrección del botón inferior (ver caso8); la global917 no se repitió.

Quedan **12/12 casos humanos aprobados dentro del alcance documentado**,45/45
integradas, backend121/1567 y Flutter920/13 opt-in omitidas comprobadas. R4
ya está cerrada localmente tras confirmar la reinstalación/eliminación del botón.
Iniciar sesión con credenciales
ficticias nuevas de `flutter-private.json` del directorio actual del harness;
no reutilizar las caducadas. La sesión humana se cerró al completar la evidencia;
no hay siguiente gesto obligatorio hasta preparar la comprobación visual.
No enviar el borrador del8.

## Preparación comprobada

- Docker local Linux disponible; imagen `postgres:16` ya descargada.
- PostgreSQL nuevo en tmpfs, puerto aleatorio solo loopback, propietario/etiqueta
  aleatorios y limpieza acotada del harness existente. No reutiliza `.env` ni bases.
- Allowlist explícita incluye SQL de reportes: **67 migraciones aplicadas solo
  en esta base temporal**. La migración no está aplicada en staging/producción.
- Build Nest/Prisma aprobado. API real en `http://127.0.0.1:43187`, panel en
  `http://127.0.0.1:4173` conectado a esa API, no demo. Configuración del panel
  comprobada HTTP200/modo real. No es el bootstrap productivo completo.
- Script `backend/tool/prepare_question_reports_local.mjs` del otro repo comprueba
  directorio/marker/etiqueta Docker propios antes de crear contenido por ADMIN.
  Tema Matemáticas «Reportes R4 - ensayo …», subtema «Preguntas para probar
  reportes», dos sumas con respuestas y explicación publicadas. No inventa
  historial respondido: el estudiante debe completar su práctica.
- **Tres comprobaciones agrupadas HTTP/DB aprobadas:** Mis reportes vacío para
  estudiante, bandeja ADMIN vacía y cobertura opt-in con dos preguntas/cero reportes.
  Preparación, no suite completa de permisos/concurrencia/RLS.
- **12 pruebas de regresión del control local** aprobadas; son las del harness,
  no los12 casos humanos ni pruebas funcionales nuevas de reportes.
- Android ARM64 autorizado por USB; reverse43187 comprobado. Build debug aprobado,
  paquete separado `com.example.saber_plus.i2validation` verificado con aapt,
  instalación USB **Success** y lanzamiento de MainActivity confirmado. No se
  sustituyó ni borró la instalación normal. Login y caso1 confirmados después
  por el propietario; ver seguimiento humano inferior.

## Acceso y operación

La terminal del harness publica su directorio temporal. Dentro, `flutter-private.json`
guarda AUTH_E2E_PASSWORD ficticia común, generada para esa sesión; no incluirla en
logs, actas, Git ni APK. Cuentas: `student@example.invalid` y `admin@example.invalid`.
`reports-fixtures.json` identifica tema/subtema/preguntas, sin contraseña ni tokens.
No copiar rutas/credenciales de una sesión caducada. El harness termina y limpia
sus recursos a las dos horas o con su control stop; no promete disponibilidad permanente.

## Doce casos humanos: 12/12 aprobados dentro del alcance indicado

1. **Aprobado:** durante práctica activa no aparece Reportar. Confirmación del
   propietario: «no no me aparece reportar un problema». Login confirmado antes.
2. **Aprobado:** tras calificar aparece Reportar con icono «!». El propietario
   abrió el formulario, envió el reporte y confirmó «Reporte recibido, gracias
   por ayudarnos a mejorar». Comprobación SQL de solo lectura: un reporte propio,
   motivo ENUNCIADO_CONFUSO, PENDIENTE/revisión0, un recibo CREAR, una auditoría,
   respuesta propia acreditada y snapshot de recepción de la pregunta original.
   El texto humano difiere del ejemplo sugerido, pero es válido y coincide con
   el recibo: no se reescribió ni se confundió esa diferencia con fallo funcional.
   Script: `backend/tool/verify_question_report_first_send_local.mjs` del otro repo.
3. **Aprobado:** Otro con «corto» exige mínimo10;501 muestra máximo500. Siguiendo
   el paso de eliminar solo el último dígito, el propietario confirmó envío recibido.
   SQL de solo lectura (`verify_question_report_first_send_local.mjs --case3` en
   backend): OTRO con exactamente500 puntos de código, mismo detalle en recibo,
   un recibo/una auditoría para ese reporte y snapshot/evidencia propios. Hay dos
   reportes, por motivos diferentes sobre el mismo ID. El primero conserva detalle,
   estado, revisión, único recibo y auditoría. No se crearon reportes por los
   intentos rechazados en el formulario. No se alteró texto para verificarlo.
4. **Aprobado:** propietario confirmó «Este problema ya estaba reportado» al
   reenviar ENUNCIADO_CONFUSO con texto diferente. Lectura SQL `--case4` aprobada:
   siguen dos reportes, el primero conserva detalle/fecha/revisión0 y una auditoría.
   Hay un segundo recibo CREAR marcado duplicado, UUID diferente y huella de payload
   distinta, ambos sobre el mismo reporte/detalle original. OTRO conserva500 y su
   único recibo/auditoría. El guion de comprobación no escribió ni reenvió nada.
5. **Aprobado:** propietario confirmó que dejó escrito el detalle de
   EXPLICACION_INCORRECTA sin enviar. Se retiró solo reverse TCP43187 del celular
   autorizado; listado posterior sin ese mapeo. API sigue401 sin token y panel200
   en el PC. Tras pulsar Enviar, propietario confirmó «No se pudo confirmar la
   operación» y cuatro botones activos: Consultar recibo, Reintentar mismo envío,
   Mis reportes y Volver. Propietario confirmó motivo/detalle bloqueados y,
   después de restablecer conexión/consultar recibo, «no hay recibo y sigue el
   mismo texto». Lectura SQL posterior al envío offline: siguen los dos
   reportes anteriores, sin tercero y sin cambios en sus recibos/auditoría.
   Reverse USB43187 restaurado y mapeo comprobado; API401/panel200 siguen en PC.
6. **Aprobado para corte previo al envío:** después de consultar sin recibo,
   propietario pulsó Reintentar mismo envío y confirmó «Reporte recibido».
   SQL de solo lectura (`--case6`) aprobado: tres reportes, todos PENDIENTE/revisión0,
   EXPLICACION_INCORRECTA creado una sola vez con un recibo CREAR no duplicado,
   una auditoría, texto igual al recibo y evidencia/snapshot propios. Los dos
   reportes anteriores conservan texto/fecha/auditoría y sus recibos (dos en
   ENUNCIADO_CONFUSO por la deduplicación, uno en OTRO con500). No se capturó el
   UUID local antes del corte: esta lectura no demuestra por sí sola estabilidad
   del UUID cliente ni commit con respuesta perdida; las unitarias cubren el
   primero y la suite de fallos reales sigue pendiente para el segundo.
7. **Aprobado el19:** nuevo acceso desde Más y tres pendientes confirmados;
   tras retirar reverse43187 apareció «No pudimos consultar tus reportes».
   Conexión restaurada y nueva recarga: propietario confirmó que reaparecieron
   los tres. Antecedente del18 conservado a continuación:
   propietario abrió Mis reportes y confirmó reportes en Pendiente.
   Falta error/recuperación de la recarga sin falso vacío; todavía6/12 completos.
   Solicitó X/Deshacer cinco segundos para despejar listados: propuesta separada
   [MA-1R-UX1](MA1R_UX1_OCULTAR_DESHACER.md), no implementada durante R4.
   Al retomar autorizó seguir: celular device y API401 sin token comprobados;
   retirado únicamente reverse USB43187 y listado posterior vacío. Siguiente
   Actualizar estado en Mis reportes. Error/recuperación aún no confirmados.
   El propietario salió de la pantalla antes de confirmar el fallo y detectó
   que no había acceso permanente desde el menú. Se restauró reverse43187,
   comprobado en adb, sin rehacer datos. Caso7 no aprobado por esa interrupción.
   Corrección UX localizada implementada: Más → Mis reportes de preguntas, bajo
   Mi perfil, reutiliza la lista actual para estudiante real/verificado. No abre
   el formulario para preguntas no respondidas ni cambia permisos/contratos.
   No modifica router compartido/OV-1, backend, datos ni la propuesta X/Deshacer.
   Análisis sin incidencias, formato de tres Dart comprobado y80 pruebas dirigidas
   aprobadas: question_reports, practice_session_page, widget y student_request_shortcut.
   Incluye dos nuevas: acceso sin práctica/volver/reabrir y ocultación por rol/
   demo/correo. Sin consulta remota antes de tocar el acceso ni creación de reportes.
   No se repitió la regresión global917 después de esta corrección. Build del18
   aprobado e instalación del19 Success. El19 el propietario confirmó el nuevo
   acceso y los tres pendientes; falta error/recuperación para completar7.
8. **Aprobado el19:** propietario confirmó motivo/detalle conservados al volver
   y reabrir la misma pregunta. También modificó el texto y volvió con la flecha
   superior: «si aun se guarda». Sin envío, reinicio ni cambio de cuenta.
   No acredita Atrás de Android físico ni persistencia al reiniciar/cerrar sesión.
   Por decisión UX se retiró el botón inferior redundante de volver (en borrador
   y recibo); se mantiene la flecha estándar y el estado en el controller actual.
   En ese punto aún no estaba reinstalado; remate posterior instalado y confirmado
   por el propietario en el cierre superior.
   Verificación de la corrección el19: formato comprobado, análisis Flutter sin
   incidencias y81 pruebas dirigidas aprobadas en question_reports,
   practice_session_page, widget y student_request_shortcut. La nueva prueba
   navega con flecha/AppBar y evento Atrás simulado, conserva motivo/texto al
   reabrir y no envía ni consulta reportes. No sustituye validación física de
   Atrás Android ni reinstalación. Regresión global917 no repetida.
9. **Aprobado el19 en su recorrido manual:** propietario cerró sesión y entró
   con zero@example.invalid; confirmó listado vacío («no tengo reportes en esta
   pagina»), sin los tres de student. Al volver a student@example.invalid confirmó
   sus tres reportes y, después de finalizar práctica/reabrir Reportar en la misma
   pregunta, detalle vacío: «si desaparecio esta vacio». El borrador no se envió.
   Sin exposición del listado previo ni persistencia del borrador tras logout.
   No había recibo de envío abierto en este recorrido nuevo: aislamiento de
   recibo pendiente/tardío se cubre en unitarias, no se acredita aquí un envío
   adicional ni ese escenario manual. Sin limpiar datos/reinstalar por este caso.
10. **Aprobado el19:** propietario confirmó los tres pendientes en panel ADMIN,
    abrió Enunciado confuso y recibió instrucciones de pasar a En revisión con
    motivo interno. Tras confirmar y recargar detalle, actualizó Mis reportes en
    el celular: «si aparecen 2 pendientes y uno en revision». Verificación SQL de
    solo lectura `verify_question_report_first_send_local.mjs --case10` aprobada:
    ENUNCIADO_CONFUSO en EN_REVISION/revisión1, una operación DECIDIR de admin,
    recibo con estado/revisión coherentes, dos auditorías (creación y transición
    PENDIENTE → EN_REVISION), motivo interno no vacío/válido y actor ADMIN correcto.
    Otros dos reportes siguen PENDIENTE/revisión0 con única auditoría y sin
    decisiones. Verificador no envía/modifica reportes ni imprime datos privados.
    No exige que el texto humano coincida literalmente con el ejemplo sugerido.
    Fixtures de base automáticos del19, decisión y actualización UI humanas.
    Sintaxis del verificador comprobada; no acredita carreras ni suite R4 completa.
11. **Aprobado el19:** propietario pegó tarjeta de cobertura del subtema de ensayo:
    tema/subtema PUBLICADO; dos publicadas/cero no disponibles, básico2, sin
    explicación0; reportes abiertos3/preguntas distintas1. Es coherente con dos
    pendientes y uno en revisión. Script de lectura `--case11-before` aprobado:
    tres abiertos/una pregunta/dos publicadas, reporte en EN_REVISION/revisión1.
    Guardó hash basal en archivo temporal exclusivo de esta sesión (sin modificar
    DB ni imprimir secretos): preguntas/respuestas/tema/subtema y XP estudiantil/
    balances competitivos. No sobrescribe baseline previa. Sintaxis comprobada.
    Tras cerrar Enunciado confuso como RESUELTO y actualizar cobertura, propietario
    pegó tarjeta con abiertos2/distintas1/publicadas2, tema/subtema PUBLICADO.
    `--case11` aprobado en lectura SQL: reporte RESUELTO/revisión2, tres auditorías,
    transición EN_REVISION → RESUELTO/motivo interno y actor ADMIN, segundo recibo
    DECIDIR con revisión2/RESUELTO y otros dos PENDIENTE/revisión0. Hash igual al
    baseline: preguntas/respuestas/tema/subtema, xpTotal y balances competitivos
    del estudiante no cambiaron durante el cierre. No afirma que los reportes
    resuelvan el contenido académico por sí solos. Total11/12, no cierre R4.
12. **Aprobado el19:** siguiendo el paso de aumentar tamaño de letra, propietario
    confirmó listado legible/operable («si se ve bien») y estado dos pendientes/
    uno resuelto. Después confirmó «si si puedo» al editar el detalle del formulario
    con letra grande/teclado abierto, desplazarse y alcanzar Enviar reporte y Mis
    reportes. No se pidió enviar nada. Verificación humana en este dispositivo,
    no auditoría completa de accesibilidad, lector de pantalla ni todos los tamaños.
    Ese APK aún contenía el botón inferior; APK posterior reinstalada y ausencia/
    conservación del borrador confirmadas en el cierre superior (regresión de8).

Siguiente: revisión de cambios y decidir commits/PR/CI. Suite técnica, regresiones
y remate visual aprobados según sección del19. No repetir ni incrementar casos humanos
sin motivo. Las sesiones anteriores se limpiaron; la sesión nueva del remate se
levantó después. No asumir que sigue activa: el harness caduca/limpia a las dos
horas. Si termina, otra prueba requiere sesión nueva, no credenciales caducadas.
No confundir recibo con estado actual. El corte de casos5–6 fue previo al envío: no prueba respuesta perdida
después de commit. Casos2–4/6 cuentan con lectura SQL; no demuestra races/cuotas/RLS.
Registrar cada confirmación real y los subpasos/repeticiones por correcciones.
Los casos1–12 y el remate posterior están completos: cierre local R4, no producción.
No cortar API/USB sin avisar
cuándo toca el caso5; coordinar para no confundir una desconexión accidental.

## Todavía pendiente

Decidir commit/PR/CI. Reinstalación/remate visual, suite específica PostgreSQL/HTTP
y regresiones ya comprobadas,
no pendientes por las instrucciones históricas del18.
Retención, proxy/multiinstancia y staging autorizado son gates posteriores.
