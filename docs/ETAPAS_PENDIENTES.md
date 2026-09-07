# SaberPlus — trabajo pendiente tras 7F-C3-D1

Actualizado: 7 de septiembre de 2026. Listado para compartir con el equipo.

**Implementado no equivale a desplegado ni probado en teléfonos.** Render ya
tuvo su despliegue inicial; no hay que repetir esa etapa desde cero. Sí quedan
actualizaciones, migraciones y verificaciones de módulos posteriores.

El roadmap principal conserva las etapas originales. Aquí se agrupan todos sus
pendientes en **13 bloques de trabajo**, incluyendo deuda de etapas anteriores:
12 de preparación del lanzamiento y uno de operación posterior (9A).
No son trece etapas originales nuevas. La comparación con el listado anterior
7F–9A está en [CONCILIACION_ROADMAP.md](CONCILIACION_ROADMAP.md).

## 1. 7F-C3-D2 — Legado y unificación editorial

- Unificar rutas administrativas antiguas y nuevas bajo las mismas validaciones,
  revisiones y bloqueos. Evitar escrituras que salten la protección del editor.
- Indexar huellas de preguntas heredadas mediante un proceso acotado, reanudable
  y verificable. Hoy se bloquea si la comparación supera 2000 candidatos.
- Revisar duplicados y clasificaciones genéricas como Banco General sin
  atribuirles temas inventados ni cambiar resultados históricos.
- Preparar un flujo explícito de reclasificación con destino y revisión humana.
- Completar revisión/publicación de lecciones interactivas CLOZE; D1 las señala
  para revisión especializada y no permite publicarlas por esta vía.
- Probar concurrencia con PostgreSQL y cerrar la condición que mantiene apagada
  `EDITORIAL_PUBLICATION_ENABLED`. No activar antes de esta unificación.

## 2. 7F-C3-D3 — Ensayo editorial real

- Preparar una cuenta ADMIN autorizada y contenido de ensayo propio/autorizado.
- Desplegar las rutas editoriales y autorizar el origen del panel por CORS.
- Probar en navegador real: crear tema, subtema, lección, caso y pregunta;
  revisar, publicar en orden y archivar sin afectar historial.
- Validar errores, duplicados, recursos, caducidad de sesión, dos editores y
  pérdida de conexión. Comprobar permisos de ADMIN frente a profesor/estudiante.
- Revisar accesibilidad del panel y despliegue HTTPS si se compartirá públicamente.

## 3. 7F-C4 — Catálogo versionado y sincronización Flutter/Drift

- Publicar un contrato versionado para detectar altas, cambios y retiradas.
- Actualizar catálogo y lecciones en la app sin recompilar por cada cambio.
- Invalidar/renovar cachés y descargas, conservar progreso y resolver conflictos.
- Asegurar que borradores o contenido archivado no aparezcan en actividades nuevas.
- Probar actualizaciones con conectividad intermitente y contenido previamente descargado.

## 4. 7F-C5 — Imágenes y archivos persistentes

- Supabase Storage con permisos, límites, tipos de archivo y referencias estables.
- Carga desde el panel, metadatos, texto alternativo, derechos y recursos faltantes.
- Ampliar el modelo Respuesta, contrato y Flutter para **imágenes dentro de opciones**.
- Mantener imágenes de enunciados/casos y recursos de lecciones/PDF disponibles
  tras reinicios o despliegues; validar acceso y descarga sin exponer secretos.
- Comprobar compatibilidad con las descargas offline y el catálogo versionado.
- Conservar fuente, titular, licencia y evidencia de autorización del contenido
  (preguntas, casos y lotes), además de los derechos de sus archivos adjuntos.

## 5. 7F-C6 — Auditoría, versiones y recuperación editorial

- Registrar quién cambió qué, cuándo y con qué resultado.
- Consultar versiones anteriores y restaurar de forma controlada.
- Corregir contenido que ya se utilizó sin reescribir resultados de alumnos.
- Definir y probar respaldo/recuperación para las operaciones editoriales.

## 6. 7F-B3-B y 6F-P — Integración móvil, despliegues y Guardián

- Revisar y aplicar las migraciones pendientes con respaldo y ambiente confirmado,
  incluida Guardián; desplegar los módulos nuevos en el backend oficial.
- Preparar cuentas verificadas de ensayo de estudiante y profesor, convocatoria
  y banco autorizado/publicado. Cargar contenido revisado, no datos personales reales.
- En teléfonos, verificar sesión, diagnóstico, práctica, progreso, recursos,
  certificados, instituciones y roles usando la API real.
- Probar juegos, recuperación tras cierre/pérdida de red y dos dispositivos en
  multijugador; validar reloj, reconexión, ranking y recompensas confirmadas.
- Revisar animaciones, sonido, reducción de movimiento y rendimiento en Android/iOS.
  Los motores y animaciones ya implementados no se cuentan como juegos por rehacer.

## 7. Cierre de identidad, contratos y seguridad

- Backend de **una única sesión/dispositivo activo**, revocación y comprobación
  en cada solicitud protegida; el cliente ya tiene parte de esta frontera.
- Refresh tokens, rotación, expiración y cierre/revocación centralizados.
- Persistir sesiones en PostgreSQL vinculadas a un identificador aleatorio de
  instalación; cerrar remotamente/todas las sesiones y revocar por reemplazo,
  cambio o recuperación de contraseña y eliminación de cuenta. Auditar lo mínimo.
- Implementar eliminación de cuenta/datos y definir conservación, anonimización
  o eliminación por categoría, con revisión de las obligaciones aplicables.
- Verificar límites de solicitudes y defensa contra intentos repetidos de acceso;
  no dar por suficiente una protección existente sin ensayarla en staging.
- OpenAPI versionado y errores uniformes para app, panel y backend.
- Universal Links/App Links HTTPS con dominio y flujos reales de correo,
  verificación y recuperación comprobados.
- Configurar/probar SMTP y conservar enlaces personalizados como respaldo.
- Consentimiento versionado y tratamiento de la audiencia real, incluidos
  adolescentes; revisar privacidad y permisos antes de incorporar SDK comerciales.

## 8. Contratos académicos pendientes de etapas anteriores

- Recuperación idempotente de intentos respaldada por API, sin duplicar respuestas.
- Recuperar resultados tras perder conexión al entregar, sin duplicar calificación
  ni XP. Probar reintentos y caducidad de sesión en la cola offline existente.
- Contrarreloj autoritativo: cierre al vencer y calificación de preguntas omitidas.
- Guardar inicio/vencimiento en servidor, no reiniciar al reabrir la app, admitir
  la entrega parcial según el plazo y separar SIN_RESPUESTA de respuesta incorrecta.
  Rechazar respuestas tardías y permitir consultar el resultado por intento.
- Banco histórico: cargar pruebas propias/autorizadas y publicar su contrato.
- Ediciones y jornadas con titular/licencia/referencia, estados disponible,
  próximamente y restringido; validar el formato acordado de 75 AM + 75 PM,
  150 preguntas y cinco áreas, sin entregar claves antes de la calificación.
- Historial unificado de jornadas AM/PM, ediciones históricas y contrarreloj.
- Incluir prácticas/simulacros por área, correctas, incorrectas, omitidas, duración
  y desglose por materia; extender comparaciones sin rehacer su interfaz existente.
- Integridad AM/PM: recibir y validar en backend eventos de salida de la app.
  Definir tolerancias para llamadas, avisos y accesibilidad; no aplicar reprobación
  automática sin una política institucional explícita.
- Sincronización de favoritos y preguntas difíciles entre instalaciones/cambios
  de dispositivo, respetando la sesión única. Hoy la persistencia es local.
- Sincronizar progreso de flashcards, objetivo personal del examen y tiempo
  estudiado. Sus funciones locales no se rehacen; falta el contrato remoto.
- Evaluar qué estado de «Continúa donde quedaste» conviene sincronizar; no asumir
  que todo intento protegido puede copiarse libremente entre dispositivos.
- Cerrar política offline de intentos/contenido protegido y precondiciones de
  edición del cuaderno de errores para resolver conflictos sin sobrescrituras silenciosas.
- Verificar aislamiento/limpieza de descargas al cambiar de cuenta y evitar
  almacenar permanentemente bancos de claves de respuesta. Distinguir recursos
  públicos descargables de datos privados y resultados autorizados del alumno.

## 9. Certificado por completar una materia

- El certificado de logros ya existe; falta el contrato específico de completar
  el 100 % de una materia, comprobado por el servidor.
- Integrarlo con la colección del perfil, descarga y reglas de emisión.
- Confirmar nombres/plantillas definitivos con el equipo; no reemplazar los
  actuales automáticamente. Pendiente identificado en GAMIFICATION_CONTRACT.md.

## 10. Etapas 8C–8D — Publicidad y recompensas reales

- Configurar e integrar AdMob: identificadores de prueba/producción, ubicaciones,
  consentimiento y límites de frecuencia. No interrumpir concentración/evaluaciones.
- Anuncios recompensados voluntarios con verificación del servidor (SSV),
  concesiones de un solo uso y protección frente a repeticiones/tráfico inválido.
- Contrato real de racha: congelamiento/gracia, vencimiento y recuperación
  del día anterior dentro de su ventana, sin confiar en el reloj local.
- Potenciadores individuales bajo demanda sin tope comercial diario, sujetos a
  disponibilidad y validación; plan sin anuncios solicita la misma recompensa sin video.
- No usar falencias, puntajes o institución para segmentar anuncios.
- No usar respuestas ni carreras para personalización publicitaria. Habilitar
  reporte de anuncios inapropiados y manejar falta de inventario/errores sin
  bloquear estudio ni provocar cargas repetitivas.
- Banners solo fuera de concentración; intersticiales en pausas naturales, con
  límites locales/remotos. Evaluar la hipótesis de 2–3 cada 30 minutos y mayor
  frecuencia para profesores gratuitos sin convertirla en obligación ni spam.
  Retirar publicidad al confirmar el derecho sin anuncios.
- Vincular cada concesión a usuario, recompensa, vencimiento y uso único;
  auditar emisión/consumo. El callback de Flutter no basta para concederla.
- Cada video voluntario concede un potenciador; no recuperar varios días de
  racha acumulados. Mantener partidas asistidas fuera de récords competitivos y
  no alterar diagnóstico, XP académico ni simulacros oficiales.
- Aprovechar el consumo autoritativo de concesiones ya implementado en juegos;
  faltan emisión real, SSV y comprobación integral, no rehacer todos los motores.

## 11. Etapas 8A–8B — Derechos comerciales, Billing y plan sin anuncios

- Configurar productos/ofertas: 9.900 COP mensual, 49.900 semestral,
  promoción 39.900 y 69.900 anual, conforme al modelo acordado.
- Compra y validación del servidor, derechos, renovación, vencimiento,
  restauración, reembolso y cambio de cuenta.
- Retirar anuncios y entregar insignia/cosméticos, sin bloquear contenido
  académico gratuito ni confundir cosméticos con logros académicos.
- Conectar los derechos de profesor con su plan, reemplazando la activación
  administrativa provisional. Revisar límites/costos del plan institucional.
- No integrar Wompi/ePayco en móvil. Mantener la frontera de iOS sin cobros reales.
- Derechos neutrales al proveedor con cuenta, producto, transacción, fechas y
  estados gratuito, pendiente, activo/sin anuncios, gracia, suspendido, vencido y
  reembolsado/revocado. Solo el servidor puede activarlos.
- Confirmar identificadores y modalidad: suscripción renovable o pase fijo.
  Validar comprobantes con Google Play Developer API y procesar notificaciones
  del servidor sobre compras/cambios, con idempotencia y recuperación de eventos.
- Probar cancelación y acceso hasta su vencimiento cuando corresponda, suspensión,
  gracia, revocación, reinstalación y asociación entre cuenta Google y SaberPlus.
- Pantalla «Administrar plan», precios devueltos por Play y pruebas con cuentas
  de licencia. Los precios anteriores son el acuerdo comercial, no valores que
  deban ignorar los productos/ofertas reales de la tienda.
- Los límites institucionales ya implementados (gratis: 1 grupo/40 alumnos;
  plan ampliado: 5 grupos/200 alumnos) se verifican y conectan al derecho comercial;
  no se vuelven a construir analíticas, prioridades ni exportaciones existentes.

## 12. Etapas 8E–8I y cierre 7J — Producción, calidad y publicación

- Entorno de producción separado del desarrollo, secretos, dominio/configuración,
  respaldo inicial, recuperación comprobada, observabilidad y plan de reversión.
- Revisar vulnerabilidades de dependencias y advertencias técnicas pendientes;
  probar seguridad, accesibilidad, carga, consumo y rendimiento.
- Banco académico suficiente y autorizado; revisión de fórmulas/glosario,
  fechas de examen y vigencia de fuentes de becas, universidades y datos nacionales.
- Completar origen, autor, licencia y fechas de los audios ya integrados; no se
  necesitan sonidos nuevos para la entrega actual. Escucharlos en teléfonos reales.
- Compilar y probar Android e iOS; firma y paquete Android, pruebas internas/beta,
  ficha de tienda, capturas, privacidad, audiencia y declaraciones de SDK/datos.
- Verificar compras/anuncios de prueba, cuentas limpias y configuración sin demo
  antes del lanzamiento comercial en Google Play.

### Contenido y operación editorial (cierre 7J)

- Cargar las cinco áreas, temas/subtemas, lecciones, Markdown, actividades,
  imágenes, videos y PDF autorizados. Revisar exactitud, ortografía, ambigüedad,
  dificultad y explicaciones; el editor admite cuatro opciones dentro de su rango
  actual de 2–6, no hay que rehacerlo por esa diferencia con el listado antiguo.
- Banco piloto: al menos 30 preguntas variadas por área; objetivo inicial de
  producción: 100 o más por área, sujeto a revisión académica y cobertura.
  Revisar las 80 fórmulas y 50 términos de memoria, no solo su cantidad.
- Actualización versionada de becas, programas, universidades y referencias
  nacionales, con fuente y fecha de revisión. No confundir el catálogo informativo
  existente con una actualización remota o automática ya implementada.
- Configurar y probar el número real de soporte WhatsApp; retirar contactos y
  contenido ficticios de producción. La cuenta de soporte la aporta el equipo.

### 8E — Privacidad, documentación y licencias

- Publicar privacidad, términos y procedimiento de eliminación en HTTPS:
  datos recogidos, finalidad, destinatarios y plazos de conservación.
- Inventario de SDK/proveedores y declaraciones de datos/anuncios/audiencia real,
  incluidos usuarios de 15–17 años; revisar requisitos vigentes al implementarlo.
- Revisar avisos de resultados orientativos/no oficiales para proyección,
  comparación nacional, carreras y becas. No se ofrecen tutores ni asesoría personal.
- Conservar evidencia de licencias de preguntas, imágenes, cuadernillos, PDF y
  audios; registrar modificaciones y verificar permisos comerciales/distribución.
  La declaración «libre de regalías» por sí sola no cierra esta comprobación.

### 8F — Seguridad, rendimiento y observabilidad

- Auditar roles, aislamiento entre instituciones, acceso de profesores a sus
  grupos, exportaciones, respuestas correctas, archivos y rutas de descarga.
- Revisar límites de solicitudes de login, juegos, invitaciones y recompensas;
  secretos distintos por ambiente, incluido el de alias, sin filtrarlos a Git/APK/logs.
- Logs sin datos sensibles, captura de errores Flutter/NestJS, latencia,
  disponibilidad y alertas; ensayar respuesta a incidentes y restauración.
- Carga de login, simulacros, Trivia Rush, Socket.IO, ranking y exportaciones;
  memoria, batería, datos y tamaño APK/AAB. Lectores de pantalla, texto ampliado,
  contraste, navegación y todas las animaciones con reducción de movimiento.

### 8G — Pruebas integrales y beta

- Suites Flutter/backend, análisis y compilaciones; E2E contra staging.
- Matriz Android (versiones, teléfono pequeño y tableta), red lenta, modo avión,
  cierres/reapertura, almacenamiento lleno, cuenta cambiada, sesión reemplazada
  y token vencido. Notificaciones/permisos, audio/vibración y los tres modos de tema.
- Compras/anuncios de prueba, racha/potenciadores, multijugador/reconexión/abandono,
  códigos de grupo, invitaciones y exportaciones; sin demo ni usuarios ficticios
  en producción. Prueba interna/cerrada, compañeros probadores y corrección de fallos.

### 8H — Entrega técnica iOS, sin publicación comercial

- Compilar en macOS/Xcode, confirmar Bundle ID y permisos realmente necesarios.
- Probar Keychain, Drift/SQLite, notificaciones, PDF/offline, enlaces, audio,
  animaciones y reducción de movimiento en iOS.
- Conservar compras neutrales/simuladas sin activar StoreKit ni publicidad real
  iOS en esta entrega. Mantener iOS es obligatorio; publicarlo en App Store no.

### 8I — Google Play

- Confirmar nombre/applicationId, firma protegida, AAB y versiones; icono, splash,
  capturas, gráfico promocional, descripciones y categoría Educación.
- Declaraciones de contenido/datos/anuncios, privacidad, instrucciones y cuenta
  de revisión si hace falta, países, disponibilidad y productos/precios.
- Verificar los requisitos concretos de pruebas de la cuenta en Play Console,
  corregir advertencias, preparar lanzamiento gradual y reversión documentada.
  Conservar el código/artefactos recuperables y prever una versión correctiva;
  no asumir que la tienda permite instalar un número de versión inferior.

## 13. Etapa 9A — Mantenimiento posterior al lanzamiento

Es operación continua, no una etapa que debamos «terminar» antes de publicar.
Antes del lanzamiento sí se asignan responsables, frecuencia y procedimientos.

- Supervisar API/base, errores Flutter/backend, compras, renovaciones y reembolsos.
- Vigilar tráfico publicitario inválido, ajustar frecuencia según experiencia y
  abandono, revisar costos de Supabase/hosting y preparar capacidad.
- Respaldos automáticos, restauraciones periódicas, rotación de secretos y
  respuesta a incidentes, reportes, bloqueos y contenido inapropiado.
- Mantener preguntas/explicaciones, becas/convocatorias, referencias ICFES,
  programas/enlaces SNIES y licencias/cuadernillos vigentes.
- Actualizar dependencias Flutter/NestJS, revisar cambios de políticas y preparar
  nuevas versiones con un ciclo de revisión y entrega.
- Métricas agregadas de actividad, estudio, retención, uso de simulacros,
  anuncios por usuario y conversión al plan sin anuncios. No enviar respuestas,
  falencias ni puntajes a plataformas publicitarias.

## Mejoras opcionales recuperadas del listado anterior

Registradas para que no se pierdan, **no bloquean la primera publicación** ni
autorizan desarrollarlas todas ahora. Se priorizan después con el equipo.

- Push desde backend (las notificaciones locales ya existen).
- Sincronización remota del Pomodoro y preferencias menores.
- Sonido/vibración al terminar Pomodoro: actualmente no los reproduce; requiere
  una decisión separada del feedback de rachas (ver POMODORO.md).
- Búsqueda académica paginada en backend y filtro diario de errores en servidor;
  no rehacer las pantallas y funciones de búsqueda/repaso existentes.
- Más cosméticos, certificados, juegos, torneos/temporadas y modos de Tira y afloja.
- Importación masiva confirmada desde panel web/tableta: existe la API de vista
  previa Excel/ZIP sin escrituras; **no equivale a un importador que guarde lotes**.
  El camino principal elegido sigue siendo la carga por página, no exigir Excel.
- Actualización automática de oportunidades oficiales desde fuentes verificadas;
  la revisión editorial/versionada inicial sí forma parte del cierre 7J.
- Publicación comercial en App Store y StoreKit completo, solo con nueva decisión.

## Fuera del lanzamiento inicial / no son etapas pendientes obligatorias

- Publicación comercial en App Store y cobros StoreKit: solo si se autorizan después.
- Tutores y chat de asesoría: descartados del modelo.
- Más juegos no acordados: no se agregan al camino actual.
- Rediseño visual general del panel: no es prioridad; debe ser funcional y accesible.

Referencias: ROADMAP_MOVIL.md, ADMIN_PANEL.md, BUSINESS_MODEL.md,
FLUTTER_STAGING_CONNECTION.md, GAME_POLISH_GUARDIAN.md,
GAMES_PRODUCTION_CHECKLIST.md, GAMIFICATION_CONTRACT.md y OFFLINE_SYNC.md.
