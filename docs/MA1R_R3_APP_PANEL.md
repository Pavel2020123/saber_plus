# MA-1R / R3 — App y panel de reportes académicos

Actualización: **18 de octubre de 2026**. Implementación local en ambos repositorios,
rama `feat/ma1r-reportes-preguntas`. Sin commit, push, merge ni despliegue de R1–R3.
La base documental previa sigue siendo una dependencia de integración separada.

Contrato técnico: `backend/docs/MA1R_R2_BACKEND.md` en SaberPlus-Backend.
[Checkpoint maestro](MA1R_REPORTES_PREGUNTAS.md). Acta espejo:
`backend/docs/MA1R_R3_APP_PANEL.md` en el otro repositorio.
No se cambió OV-1 ni su checkpoint, dependencias, rutas generales o permisos docentes.

## Qué puede hacer el estudiante

- Tras calificar práctica por subtema, preguntas aleatorias o simulacro por área,
  abrir la pregunta en Revisión y pulsar **Reportar un problema**. No se muestra
  en la prueba activa ni anticipa soluciones. También se puede reportar un acierto.
- Solo cuenta ESTUDIANTE real, correo verificado y sin cambio de contraseña
  obligatorio. El backend vuelve a comprobar rol, correo y respuesta propia.
  No se habilita en demo, prioridades, adaptativo, histórico, jornada oficial,
  contrarreloj, diagnóstico, juegos, cuaderno o flashcards. No elimina esos módulos.
- Elegir uno de cinco motivos y detalle opcional de hasta 500 puntos de código
  Unicode tras trim; Otro exige al menos 10. Sin adjuntos ni datos personales.
- Confirmación normal o duplicado semántico: se conserva el reporte original,
  sin sustituir su detalle ni reabrirlo. Solo después de confirmar se permite
  comenzar **otro problema** con un motivo diferente; el servidor sigue deduplicando.
- **Mis reportes** consulta el estado actual paginado. El recibo es del envío
  original, no una afirmación del estado actual ni de que la pregunta fue corregida.
  No expone snapshot, identidad de otros alumnos o notas ADMIN.

## Red, borradores y cambio de cuenta

El primer envío crea un UUIDv4 y payload inmutables. Timeout, respuesta inválida,
conflicto o 5xx conservan el mismo intento. Se ofrecen **Consultar recibo** y
**Reintentar mismo envío**, sin reenvío automático ni cambio de texto/motivo.
Un GET404 no demuestra que una escritura en curso haya fallado. Un429 posterior
a un envío incierto tampoco libera el intento. Un rechazo definitivo del primer
envío permite corregir el borrador; no se presume éxito.

Borrador e intento viven **solo en memoria durante esa sesión** y se conservan
al volver a la revisión y reabrir el formulario. No sobreviven a reiniciar la app;
no se almacenan en disco ni se promete una cola offline. Antes de reiniciar, consultar
el recibo; después, consultar Mis reportes para verificar el estado actual.
Cerrar sesión/cambiar cuenta o perder elegibilidad destruye el estado anterior;
respuestas tardías no repueblan el formulario. Se reutiliza SessionDio, que fija
la revisión de sesión antes de ejecutar interceptores; no se envía como otra cuenta.

## ADMIN, demo y cobertura

- Nueva pestaña **Reportes de preguntas**: área, subtema por ID opcional,
  estado, motivo y paginación. Snapshot de recepción y auditoría se muestran como
  texto, nunca HTML ejecutable ni descarga automática de imágenes/enlaces.
- Decisión con confirmación explícita, motivo interno y revisión esperada.
  Pendiente → En revisión → Resuelto/Descartado; cerrados pueden volver a revisión.
  No cambia publicación, notas, XP, recompensas o pertenencia institucional.
- Decisión incierta conserva UUID/revisión/destino/motivo; bloquea otra decisión
  y la navegación de sección hasta reconciliar con el mismo envío. Consultar
  detalle no sustituye el recibo. Logout fuerza limpieza de todos los datos.
  Conflicto definitivo inicial exige cargar versión actual antes de otra decisión.
  La confirmación recarga detalle actual, sin sustituirlo por un recibo antiguo.
- Cobertura pide `reportesVersion=1`: reportes abiertos y preguntas distintas
  afectadas, incluidos IDs archivados. No se comparan con el total publicado.
  Acepta legacy false/null sin inventar cero. Solo un400 al pedir el opt-in permite
  volver al contrato antiguo; fallos de red/autenticación/DB no se ocultan así.
- La demo ADMIN usa un reporte ficticio sobre una pregunta archivada existente;
  decisiones/recibos/conteos son en memoria y se pierden al reiniciar. No acredita
  respuestas de alumnos ni simula cuotas, RLS, concurrencia o persistencia real.

## Archivos y verificación reproducible

Flutter: [dominio](../lib/features/question_reports/domain/question_report.dart),
[cliente](../lib/features/question_reports/data/remote_question_report_repository.dart),
[estado por sesión](../lib/features/question_reports/presentation/question_report_controller.dart),
[formulario/lista](../lib/features/question_reports/presentation/question_report_page.dart),
[integración en revisión](../lib/features/practice/presentation/practice_session_page.dart).

```powershell
cd "C:\Users\LENOVO 14ALC6\Desktop\SaberPLus\saber_plus"
& "C:\flutter_sdk\bin\flutter.bat" analyze --no-pub
& "C:\flutter_sdk\bin\flutter.bat" test --no-pub test/question_reports_test.dart test/practice_session_page_test.dart
```

Validación dirigida: **32 pruebas aprobadas** (22 de reportes y 10 de práctica).
Incluye Unicode, permisos, calificación previa, exclusión de prioridades, duplicados,
timeout→consulta/replay,429 posterior incierto, aislamiento de cuenta, texto visible
al iniciar otro motivo, contratos HTTP simulados y error/recarga del listado propio.
Panel: **109 pruebas aprobadas** y sintaxis de **26 módulos**; comandos y detalles
en el acta espejo. HTTP del panel es demo Node efímera en loopback, no API Nest/DB.

Regresión completa posterior del18: `flutter test --no-pub --reporter expanded`,
**917 aprobadas /13 opt-in omitidas**, sin fallos (4min50s). `flutter analyze --no-pub`:
sin incidencias. Formato comprobado en los siete Dart nuevos/modificados.
Las13 opt-in no se ejecutaron ni se cuentan como aprobadas; la regresión no sustituye
R4. No se generó ni instaló un APK ni se hizo un ensayo físico con esta entrega.
Documentación conjunta:35 archivos seleccionados,699 destinos de enlaces locales,
ninguno inexistente; no valida anchors ni páginas externas. Diff sin errores de
whitespace en ambos clones. Las cifras anteriores del17 son antecedentes fechados.

## Siguiente histórico de R3: R4, no repetir instituciones

**Estado posterior del19:** ver [R4](MA1R_R4_VALIDACION_LOCAL.md). Recorrido humano
12/12 y suite PostgreSQL/HTTP45/45 aprobados, incluida corrección de carrera ADMIN
P2010/40001;7 unitarias nuevas, dirigidas100 y regresión Flutter920/13 opt-in omitidas.
Remate de reinstalación del botón inferior confirmado: cierre local R4;
siguen revisión/commits/PR/CI según su acta, no repetir gestos de prueba.
El SQL ya se aplicó en bases temporales propias y estas se limpiaron; no SQL remoto.
El guion inferior conserva el plan anterior al ensayo, no ordena repetirlo.

1. Preparar pruebas PostgreSQL/HTTP aisladas de MA-1R, coordinar migraciones con
   OV-1 y comprobar destino local desechable antes de aplicar SQL. La migración
   de R2 sigue escrita **sin aplicar**; no usar Supabase/Render ni secretos antiguos.
2. Probar roles/evidencia, recibos/rollback/carreras, deduplicación/cuotas/tasa,
   privacidad/RLS y cobertura real. Separar pruebas de servicio de las de demo.
3. Después, recorrido Android/API/panel con cuentas ficticias, red cortada,
   reapertura, cambio de cuenta y conflictos ADMIN; comprobar texto grande/teclado.
   Solo para ese recorrido hará falta el celular USB y los servicios temporales.
4. Registrar resultados reales y después decidir commit/PR/CI/integración.
   No marcar producción ni cierre global por aprobar unitarias; retención,
   proxy/multiinstancia y staging autorizado siguen pendientes. P5/D3 pausadas.

No se instaló APK, arrancó API/base, aplicó SQL ni hizo revisión visual humana
del navegador/teléfono durante R3. Las pruebas de widgets/DOM no sustituyen eso.
