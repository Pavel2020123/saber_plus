# Índice de documentación de SaberPlus

- [Orientación por intereses y territorio](ORIENTACION_Y_TERRITORIO.md): nuevas
  entregas PR-I5-T/PR-I6-T/OV-1, criterios de privacidad y colección propuesta de Sabi.

**Estado vigente, 5 de octubre:** PR-I1 y PR-I2 hasta I2-4 fusionados en ambos
repositorios. Sigue I2-5; no hay cierre E2E/productivo. Leer el estado superior de
[ETAPAS_PENDIENTES](ETAPAS_PENDIENTES.md) y [PROMPT_RELEVO](PROMPT_RELEVO.md).
El índice y la nota de septiembre inferiores se conservan como historial;
sus instrucciones de detener PR-I2 o comenzar PR-I1 están superadas.

**30 de septiembre — PR-I1 V1:** [diseño aprobado y precisiones resueltas de `xpRulesVersion = 1`, sección 12](PR_I1_AUDITORIA_FORMULAS.md#12-diseño-numérico-aprobado--xprulesversion--1). Half-up, denominadores, presencia y penalización atómica definidos; Tira por abandono usa Qpartida. No quedan ambigüedades de producto identificadas; requisitos técnicos de habilitación en 12.7. Historial superado conservado. Detenerse: implementación, commit, push y PR-I2 no autorizados. PR-I1 no cerrado. [Plan maestro original](PLAN_MAESTRO_COMPETITIVO.md) conservado.

Actualizado: 28 de septiembre de 2026. Inventario del README y todos los Markdown
bajo `docs/`. No sustituye contratos ni acredita auditoría completa del código.
El README de recursos iOS es una plantilla de plataforma, no una etapa del producto.

## Cómo leer sin perder la ruta

1. [RELEVO_EQUIPO](RELEVO_EQUIPO.md): repositorios, ramas, pruebas y entrega.
2. [Ruta vigente](ETAPAS_PENDIENTES.md#ruta-vigente-del-equipo): estados y dependencias;
   próxima entrega I2-5. MA-3C ya implementada localmente, ensayo real pendiente.
3. [Arquitectura](ARQUITECTURA_Y_ESTRUCTURA.md) y contrato de la función elegida.
4. [PROMPT_RELEVO](PROMPT_RELEVO.md): bloque completo para el nuevo asistente.

## Jerarquía y mantenimiento

Las decisiones confirmadas más recientes y la ruta vigente definen el alcance.
Los contratos por módulo documentan interfaces/reglas; si discrepan del código,
registrar el hallazgo y resolverlo explícitamente. No elegir el texto más cómodo.
Las auditorías e historiales reflejan su fecha: sus conteos y «siguientes» no son
resultados actuales ni permiso para repetir etapas. Cada entrega actualiza ruta,
relevo, README, historial y contrato; añadir aquí nuevos documentos. No cambiar
fechas o resultados de pruebas antiguas para aparentar una validación reciente.

## Documentación del otro repositorio

Clonar también `Pavel2020123/SaberPlus-Backend`. Leer su `README.md`,
`backend/README.md`, `admin/README.md` y contratos relevantes (por ejemplo
`backend/DEFERRED_REVIEW.md`, `backend/LEARNING_MAP.md`, `backend/BANK_COVERAGE.md`).
Sus rutas se resuelven dentro de ese repositorio; no son archivos ausentes de Flutter.
Los scripts reales de `package.json` y migraciones se verifican antes de ejecutar.
P5/D3 y operaciones compartidas continúan pausadas.

## Inventario

### Empezar aquí y decidir el trabajo

- [README.md](../README.md) — SaberPlus móvil.
- [ARQUITECTURA_Y_ESTRUCTURA.md](ARQUITECTURA_Y_ESTRUCTURA.md) — SaberPlus: estructura y arquitectura para el equipo.
- [ETAPAS_PENDIENTES.md](ETAPAS_PENDIENTES.md) — SaberPlus — etapas pendientes y ruta vigente del equipo.
- [FUNCIONALIDADES_PARA_EL_EQUIPO.md](FUNCIONALIDADES_PARA_EL_EQUIPO.md) — SaberPlus — funcionalidades y estado para el equipo.
- [GUIA_TRABAJO_COMPANEROS.md](GUIA_TRABAJO_COMPANEROS.md) — SaberPlus — guía de trabajo para compañeros.
- [PROMPT_RELEVO.md](PROMPT_RELEVO.md) — Prompt para continuar SaberPlus con otro chat.
- [RELEVO_EQUIPO.md](RELEVO_EQUIPO.md) — Relevo del equipo — empezar aquí.
- [ROADMAP_MOVIL.md](ROADMAP_MOVIL.md) — Roadmap móvil de SaberPlus.

### Historia y auditorías fechadas (no ruta actual)

- [AUDITORIA_DATOS_2026-09-09.md](AUDITORIA_DATOS_2026-09-09.md) — Auditoría focalizada: sesión, red y persistencia móvil.
- [AUDITORIA_PROYECTO_2026-09-09.md](AUDITORIA_PROYECTO_2026-09-09.md) — Auditoría de SaberPlus — 9 de septiembre de 2026.
- [AUDITORIA_UX_2026-09-09.md](AUDITORIA_UX_2026-09-09.md) — Auditoría de navegación y experiencia de uso — 9 de septiembre de 2026.
- [CONCILIACION_ROADMAP.md](CONCILIACION_ROADMAP.md) — Comparación con el listado anterior 7F–9A.
- [ESCUDO_DEL_CONOCIMIENTO.md](ESCUDO_DEL_CONOCIMIENTO.md) — JN-4 — Escudo del conocimiento.
- [HISTORIAL_ETAPAS.md](HISTORIAL_ETAPAS.md) — Historial completo de etapas de SaberPlus.
- [REVISION_REANUDACION_2026-09-27.md](REVISION_REANUDACION_2026-09-27.md) — Revisión acotada de reanudación — 27 de septiembre de 2026.

### Instituciones, profesor y comunidad

- [COMMUNITY_TOOLS.md](COMMUNITY_TOOLS.md) — Anuncios, referidos, soporte y calculadora.
- [GROUP_LINKING.md](GROUP_LINKING.md) — Grupos y vinculación segura.
- [INSTITUTION_ADMINISTRATION.md](INSTITUTION_ADMINISTRATION.md) — Administración institucional.
- [PROFESOR_P1.md](PROFESOR_P1.md) — Profesor P1 — métricas, textos y navegación.
- [PROFESOR_P2.md](PROFESOR_P2.md) — Profesor P2 — ficha individual de evidencia.
- [PROFESOR_P3_A.md](PROFESOR_P3_A.md) — Profesor P3-A — base de prioridades docentes.
- [PROFESOR_P3_B.md](PROFESOR_P3_B.md) — Profesor P3-B — pantallas, práctica dirigida y seguimiento.
- [PROFESOR_P4_A.md](PROFESOR_P4_A.md) — Profesor P4-A — base del tiempo y evolución.
- [PROFESOR_P4_B.md](PROFESOR_P4_B.md) — Profesor P4-B — sincronización y evolución en Flutter.
- [PROFESOR_P4_C.md](PROFESOR_P4_C.md) — P4-C — Solicitud y aprobación de instituciones.
- [TEACHER_FREE_PLAN.md](TEACHER_FREE_PLAN.md) — Profesor gratuito e indicadores básicos.
- [TEACHER_INSTITUTION_FOUNDATION.md](TEACHER_INSTITUTION_FOUNDATION.md) — Base de profesor e institución.
- [TEACHER_NO_ADS_PLAN.md](TEACHER_NO_ADS_PLAN.md) — Plan institucional sin anuncios.

### Juegos, insignias, Sabi y audio

- [ANSWER_STREAK_FEEDBACK.md](ANSWER_STREAK_FEEDBACK.md) — Feedback de rachas de aciertos.
- [ASYNC_BATTLES.md](ASYNC_BATTLES.md) — Batallas asíncronas.
- [GAMES_PRODUCTION_CHECKLIST.md](GAMES_PRODUCTION_CHECKLIST.md) — Insumos pendientes para publicar los juegos.
- [GAME_POLISH_GUARDIAN.md](GAME_POLISH_GUARDIAN.md) — 6F-P — Pulido de juegos, racha y desafío del guardián.
- [GAMIFICATION_CONTRACT.md](GAMIFICATION_CONTRACT.md) — Contrato móvil de gamificación.
- [GHOST_DUEL.md](GHOST_DUEL.md) — Duelo fantasma.
- [INSIGNIAS_Y_JUEGOS_VIGENTES.md](INSIGNIAS_Y_JUEGOS_VIGENTES.md) — Insignias y juegos vigentes — 27 de septiembre de 2026.
- [MEMORY_MATCH.md](MEMORY_MATCH.md) — Memoria académica.
- [MOTION.md](MOTION.md) — Movimiento y transiciones.
- [PERFILES_RANKINGS_INSIGNIAS.md](PERFILES_RANKINGS_INSIGNIAS.md) — Perfiles, rankings e insignias — ampliación acordada.
- [RANKING_PRIVACY.md](RANKING_PRIVACY.md) — Ranking con privacidad por defecto.
- [RESCATE_DE_ESTRELLAS.md](RESCATE_DE_ESTRELLAS.md) — JN-2 — Rescate de estrellas.
- [SABI_DUELO_FANTASMA.md](SABI_DUELO_FANTASMA.md) — Sabi — primera renovación: Duelo fantasma.
- [SABI_Y_JUEGOS_APROBADOS.md](SABI_Y_JUEGOS_APROBADOS.md) — Sabi y ampliaciones aprobadas.
- [SALTO_A_LA_CIMA.md](SALTO_A_LA_CIMA.md) — JN-1 — Salto a la cima.
- [TRIVIA_RUSH.md](TRIVIA_RUSH.md) — Trivia Rush.
- [TRIVIA_RUSH_BACKEND_CONTRACT.md](TRIVIA_RUSH_BACKEND_CONTRACT.md) — Contrato backend de Trivia Rush.
- [TUG_OF_WAR.md](TUG_OF_WAR.md) — Tira y afloja.
- [TUG_OF_WAR_BACKEND_CONTRACT.md](TUG_OF_WAR_BACKEND_CONTRACT.md) — Contrato del backend de Tira y afloja.
- [licenses/AUDIO_LICENSES.md](licenses/AUDIO_LICENSES.md) — Registro de licencias de audio.

### API, panel, infraestructura, privacidad y comercio

- [ACADEMIC_CATALOG.md](ACADEMIC_CATALOG.md) — 7F-C2-B1 — Base del catálogo académico.
- [ADMIN_PANEL.md](ADMIN_PANEL.md) — 7F-C3-D2-F — Verificación PostgreSQL local.
- [AUTH_CONTRACT.md](AUTH_CONTRACT.md) — Contrato real de autenticación.
- [BUSINESS_MODEL.md](BUSINESS_MODEL.md) — Modelo de negocio móvil.
- [COBERTURA_DEL_BANCO.md](COBERTURA_DEL_BANCO.md) — MA-1 — Cobertura básica del banco.
- [CONTENT_ADMINISTRATION.md](CONTENT_ADMINISTRATION.md) — Administración y publicación de contenido.
- [CONTENT_IMPORT_FORMAT.md](CONTENT_IMPORT_FORMAT.md) — Importación masiva de contenido.
- [FLUTTER_STAGING_CONNECTION.md](FLUTTER_STAGING_CONNECTION.md) — 7F-B3-A — Flutter conectado al servidor de staging.
- [OFFLINE_CONTENT.md](OFFLINE_CONTENT.md) — Contenido sin conexión.
- [OFFLINE_SYNC.md](OFFLINE_SYNC.md) — Sincronización segura sin conexión.
- [RENDER_STAGING_DEPLOYMENT.md](RENDER_STAGING_DEPLOYMENT.md) — Backend HTTPS de staging en Render.
- [SESSION_SECURITY_WELLBEING.md](SESSION_SECURITY_WELLBEING.md) — Sesión por dispositivo, integridad y descansos.
- [SUPABASE_DEPLOYMENT.md](SUPABASE_DEPLOYMENT.md) — Supabase para el backend de SaberPlus.

### Estudio, práctica y herramientas personales

- [ACADEMIC_ACTIVITY_REPORT.md](ACADEMIC_ACTIVITY_REPORT.md) — Resumen semanal y comparativo mensual.
- [ACADEMIC_CONTRACT.md](ACADEMIC_CONTRACT.md) — Contrato académico móvil.
- [ACADEMIC_PROFILE.md](ACADEMIC_PROFILE.md) — Perfil académico central.
- [ACADEMIC_SEARCH.md](ACADEMIC_SEARCH.md) — Búsqueda académica móvil.
- [CAREER_ORIENTATION.md](CAREER_ORIENTATION.md) — Orientación de carreras y universidades.
- [CONTINUE_LEARNING.md](CONTINUE_LEARNING.md) — Continúa donde quedaste.
- [DAILY_MISTAKE_REVIEW.md](DAILY_MISTAKE_REVIEW.md) — Repaso de errores del día.
- [DIFFICULT_QUESTIONS.md](DIFFICULT_QUESTIONS.md) — Preguntas difíciles.
- [EXAM_COUNTDOWN.md](EXAM_COUNTDOWN.md) — Contador global del examen.
- [FAVORITES.md](FAVORITES.md) — Favoritos académicos.
- [FLASHCARDS.md](FLASHCARDS.md) — Flashcards académicas.
- [HISTORICAL_SIMULATIONS.md](HISTORICAL_SIMULATIONS.md) — Banco autorizado de simulacros por año.
- [LEARNING_EVIDENCE.md](LEARNING_EVIDENCE.md) — 7F-C2-B2 — Diagnóstico por temas y subtemas.
- [MAPA_APRENDIZAJE.md](MAPA_APRENDIZAJE.md) — MA-2 — Mapa de aprendizaje.
- [NATIONAL_SCORE_COMPARISON.md](NATIONAL_SCORE_COMPARISON.md) — Comparación con referencias nacionales.
- [OFFICIAL_OPPORTUNITIES.md](OFFICIAL_OPPORTUNITIES.md) — Becas y oportunidades oficiales.
- [POMODORO.md](POMODORO.md) — Pomodoro de enfoque.
- [PRACTICE_CONTRACT.md](PRACTICE_CONTRACT.md) — Contrato móvil de práctica y preguntas aleatorias.
- [PREFERENCES_NOTIFICATIONS.md](PREFERENCES_NOTIFICATIONS.md) — Preferencias y notificaciones locales.
- [PROGRESS_CONTRACT.md](PROGRESS_CONTRACT.md) — Contrato móvil de progreso y cuaderno de errores.
- [REFERENCE_LIBRARY.md](REFERENCE_LIBRARY.md) — Biblioteca académica móvil.
- [REPASO_DIFERIDO.md](REPASO_DIFERIDO.md) — MA-3 — Repaso diferido.
- [SCORE_PROJECTION.md](SCORE_PROJECTION.md) — Proyección orientativa de puntaje.
- [SIMULACRO_150.md](SIMULACRO_150.md) — Simulacro de 150 preguntas AM/PM.
- [SIMULATION_COMPARISON.md](SIMULATION_COMPARISON.md) — Comparación entre simulacros.
- [STUDY_CONTRACT.md](STUDY_CONTRACT.md) — Contrato de contenido académico móvil.
- [STUDY_TIME.md](STUDY_TIME.md) — Tiempo total estudiado.
- [SYLLABUS_COUNTDOWN.md](SYLLABUS_COUNTDOWN.md) — Countdown del temario por materia.
- [TIME_TRIALS.md](TIME_TRIALS.md) — Pruebas contrarreloj.


