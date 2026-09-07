# Comparación con el listado anterior 7F–9A

Revisión: 7 de septiembre de 2026. Fuente comparada: auditoría anterior aportada
por el equipo, que situaba el proyecto al terminar 7E.

**Última subetapa implementada: 7F-C3-D2-B. Próxima: continuar 7F-C3-D2.**
Actualización posterior a la conciliación: retiro de escrituras heredadas y
bloqueo común por área implementados localmente; no desplegados. La comparación
original fue documental. Implementado localmente no significa probado
de extremo a extremo con cuentas y contenido reales.

## Lo que ya no debemos contar como trabajo desde cero

- Supabase `saberplus-dev`, conexión Prisma y migraciones iniciales; repositorio
  independiente del backend y despliegue inicial HTTPS en Render.
- Configuración Flutter staging y comprobación pública HTTPS de salud/base y
  rechazo de acceso sin sesión. No equivale a una prueba completa de estudiante.
- Catálogo área > tema > subtema y clasificación específica; evidencia acumulada
  para diagnosticar falencias sin afirmar que un solo error confirma una debilidad.
- Estados editoriales y API de vista previa de importación con validaciones y
  detección de duplicados. Importar y guardar un lote sigue siendo otra función.
- Panel ADMIN, temas/subtemas, lecciones y preguntas/casos en borrador; editor
  con explicaciones y referencias HTTPS, duplicados y revisiones concurrentes.
- C3-D1: revisión, advertencias, bloqueos y confirmación de cambios de estado.
  Recorrido demo disponible; nuevas escrituras reales desactivadas por defecto
  hasta cerrar la unificación de rutas y las comprobaciones de D2.
- C3-D2-A: rutas antiguas de escritura y carga demostrativa HTTP retiradas;
  protocolo común de bloqueo por área. D2 no se cierra hasta resolver legado,
  interactivos y pruebas de concurrencia reales.
- C3-D2-B: herramienta de indexación por lotes y reportes de coincidencias
  implementada localmente. No se procesó la base real ni se reclasificó contenido.
- Juegos/motores, animaciones, audios y límites/analíticas institucionales ya
  implementados se conservan. Sus verificaciones reales y conexiones comerciales
  pendientes no significan reconstruirlos.

## Correspondencia de todas las macroetapas anteriores

Los números de bloque remiten a [ETAPAS_PENDIENTES.md](ETAPAS_PENDIENTES.md).
«Parcial» significa que hay componentes, no que el criterio de cierre esté cumplido.

| Etapa anterior | Estado al comparar | Dónde se completa ahora |
| --- | --- | --- |
| 7F — Supabase/despliegue | Infraestructura inicial hecha; integración completa, archivos, respaldos y producción pendientes. | Bloques 2, 4, 6, 7 y 12. No repetir la creación de Supabase ni Render. |
| 7G — Seguridad de cuentas | Cliente y protecciones parciales; no dar por cerradas sesiones/refresh, eliminación y consentimiento. | Bloque 7; auditoría final en 12/8E–8F. |
| 7H — Sincronización | Persistencia local/cola offline existentes; falta completar contratos entre dispositivos. | Bloques 3 y 8. |
| 7I — Simulacros autoritativos | Interfaces y flujos parciales existentes; faltan contratos avanzados e integridad confirmada por servidor. | Bloque 8 y pruebas en 6/12. |
| 7J — Contenido/administración | Avance importante: C1, C2-A, C2-B1/B2, C3-A/B/C y D1 implementados. Falta cierre real y contenido autorizado. | Bloques 1–5, 9 y 12/cierre 7J. |
| 8A — Derechos comerciales | Límites y funcionalidades institucionales ya existen; activación comercial neutral pendiente. | Bloque 11. |
| 8B — Google Play Billing | Integración real y pruebas de compra pendientes. | Bloque 11. |
| 8C — AdMob | Integración real, consentimiento y frecuencia pendientes. | Bloque 10. |
| 8D — Recompensas seguras | Consumo autoritativo implementado en juegos; emisión por anuncio, SSV y flujo real pendientes. | Bloque 10. |
| 8E — Privacidad/licencias | Cierre documental, eliminación y evidencias pendientes. | Bloques 7 y 12/8E. |
| 8F — Seguridad/rendimiento | Hay controles y pruebas locales, no una certificación de preparación productiva. | Bloque 12/8F. |
| 8G — Pruebas/beta | Pruebas automatizadas existentes; falta la matriz integral de candidato a lanzamiento. | Bloques 2, 6 y 12/8G. |
| 8H — Entrega técnica iOS | Soporte conservado; falta verificar la entrega en macOS/Xcode e iOS. | Bloque 12/8H. |
| 8I — Publicación Google Play | Cuenta de Console iniciada; lanzamiento de la app pendiente. | Bloque 12/8I. |
| 9A — Operación posterior | No figuraba explícitamente en el último resumen; se reincorpora como operación continua. | Nuevo bloque 13. |

El texto antiguo decía **14**, pero enumeraba **15 macroetapas**: cinco entre
7F y 7J, nueve entre 8A y 8I, más 9A. Eran 14 anteriores al lanzamiento y una
posterior. Los **13 bloques actuales** agrupan y dividen ese trabajo de otra
manera; no sirven para calcular cuántas etapas se terminaron por una resta.

## Pendientes que se hicieron explícitos al recuperar el listado

- Eliminación de cuenta/datos, conservación, cierre remoto/todas las sesiones,
  causas de revocación, auditoría mínima, SMTP y protección contra intentos repetidos.
- Sincronización de flashcards, objetivo del examen y tiempo estudiado; evaluación
  del punto de reanudación y pruebas de aislamiento/limpieza de descargas.
- Integridad AM/PM en servidor, formato y derechos del banco histórico, omisiones,
  recuperación idempotente e historial completo de modalidades.
- Fuentes/derechos del contenido, mínimos del banco, soporte real y actualización
  versionada de becas, universidades, programas y referencias nacionales.
- Modalidad de los productos, notificaciones de Play, administrar plan, precios
  de tienda, estados comerciales, reportes de anuncios y falta de inventario.
- Desglose de privacidad/licencias, seguridad/carga, beta, iOS y publicación,
  incluyendo almacenamiento lleno, cuentas de revisión y recuperación operativa.
- 9A completo y la lista opcional: push, mejoras de Pomodoro, consultas de backend,
  expansión de juegos/cosméticos, importación masiva, automatización de fuentes
  y eventual App Store. No se convierten en obligaciones nuevas para lanzar.

## Evidencia local y límites de la revisión

- [ROADMAP_MOVIL.md](ROADMAP_MOVIL.md): casillas y alcance de etapas implementadas.
- [ADMIN_PANEL.md](ADMIN_PANEL.md): editores, D1, límites y pruebas pendientes.
- [FLUTTER_STAGING_CONNECTION.md](FLUTTER_STAGING_CONNECTION.md): comprobación
  pública realizada y distinción respecto a 7F-B3-B.
- [FLASHCARDS.md](FLASHCARDS.md), [STUDY_TIME.md](STUDY_TIME.md) y
  [OFFLINE_SYNC.md](OFFLINE_SYNC.md): persistencia local y contratos remotos pendientes.
- [POMODORO.md](POMODORO.md): no reproduce audio/vibración al finalizar.
- [GAMIFICATION_CONTRACT.md](GAMIFICATION_CONTRACT.md): certificado de logros
  existente frente al contrato pendiente de completar una materia.
- [GAMES_PRODUCTION_CHECKLIST.md](GAMES_PRODUCTION_CHECKLIST.md): concesiones,
  contenido, recursos y verificaciones reales aún necesarias.

No se inspeccionó ni modificó infraestructura remota en esta comparación. La
vigencia de políticas comerciales/legales se verificará con fuentes oficiales
al ejecutar las etapas correspondientes, no se deduce de este documento antiguo.
