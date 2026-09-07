# SaberPlus — trabajo pendiente tras 7F-C3-D1

Actualizado: 7 de septiembre de 2026. Listado para compartir con el equipo.

**Implementado no equivale a desplegado ni probado en teléfonos.** Render ya
tuvo su despliegue inicial; no hay que repetir esa etapa desde cero. Sí quedan
actualizaciones, migraciones y verificaciones de módulos posteriores.

El roadmap principal conserva las etapas originales. Aquí se agrupan todos sus
pendientes en **12 bloques de trabajo**, incluyendo deuda de etapas anteriores;
no significa que el proyecto tuviera originalmente doce etapas adicionales.

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
- OpenAPI versionado y errores uniformes para app, panel y backend.
- Universal Links/App Links HTTPS con dominio y flujos reales de correo,
  verificación y recuperación comprobados.
- Consentimiento versionado y tratamiento de la audiencia real, incluidos
  adolescentes; revisar privacidad y permisos antes de incorporar SDK comerciales.

## 8. Contratos académicos pendientes de etapas anteriores

- Recuperación idempotente de intentos respaldada por API, sin duplicar respuestas.
- Contrarreloj autoritativo: cierre al vencer y calificación de preguntas omitidas.
- Banco histórico: cargar pruebas propias/autorizadas y publicar su contrato.
- Historial unificado de jornadas AM/PM, ediciones históricas y contrarreloj.
- Sincronización de favoritos y preguntas difíciles entre instalaciones/cambios
  de dispositivo, respetando la sesión única. Hoy la persistencia es local.
- Cerrar política offline de intentos/contenido protegido y precondiciones de
  edición del cuaderno de errores para resolver conflictos sin sobrescrituras silenciosas.

## 9. Certificado por completar una materia

- El certificado de logros ya existe; falta el contrato específico de completar
  el 100 % de una materia, comprobado por el servidor.
- Integrarlo con la colección del perfil, descarga y reglas de emisión.
- Confirmar nombres/plantillas definitivos con el equipo; no reemplazar los
  actuales automáticamente. Pendiente identificado en GAMIFICATION_CONTRACT.md.

## 10. Etapa 8 — Publicidad y recompensas reales

- Configurar e integrar AdMob: identificadores de prueba/producción, ubicaciones,
  consentimiento y límites de frecuencia. No interrumpir concentración/evaluaciones.
- Anuncios recompensados voluntarios con verificación del servidor (SSV),
  concesiones de un solo uso y protección frente a repeticiones/tráfico inválido.
- Contrato real de racha: congelamiento/gracia, vencimiento y recuperación
  del día anterior dentro de su ventana, sin confiar en el reloj local.
- Potenciadores individuales bajo demanda sin tope comercial diario, sujetos a
  disponibilidad y validación; plan sin anuncios solicita la misma recompensa sin video.
- No usar falencias, puntajes o institución para segmentar anuncios.

## 11. Etapa 8 — Google Play Billing y plan sin anuncios

- Configurar productos/ofertas: 9.900 COP mensual, 49.900 semestral,
  promoción 39.900 y 69.900 anual, conforme al modelo acordado.
- Compra y validación del servidor, derechos, renovación, vencimiento,
  restauración, reembolso y cambio de cuenta.
- Retirar anuncios y entregar insignia/cosméticos, sin bloquear contenido
  académico gratuito ni confundir cosméticos con logros académicos.
- Conectar los derechos de profesor con su plan, reemplazando la activación
  administrativa provisional. Revisar límites/costos del plan institucional.
- No integrar Wompi/ePayco en móvil. Mantener la frontera de iOS sin cobros reales.

## 12. Etapa 8 — Producción, calidad y publicación

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

## Fuera del lanzamiento inicial / no son etapas pendientes obligatorias

- Publicación comercial en App Store y cobros StoreKit: solo si se autorizan después.
- Tutores y chat de asesoría: descartados del modelo.
- Más juegos no acordados: no se agregan al camino actual.
- Rediseño visual general del panel: no es prioridad; debe ser funcional y accesible.

Referencias: ROADMAP_MOVIL.md, ADMIN_PANEL.md, BUSINESS_MODEL.md,
FLUTTER_STAGING_CONNECTION.md, GAME_POLISH_GUARDIAN.md,
GAMES_PRODUCTION_CHECKLIST.md, GAMIFICATION_CONTRACT.md y OFFLINE_SYNC.md.
