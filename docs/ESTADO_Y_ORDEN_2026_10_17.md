# Etapas después de instituciones — revisión del 17 de octubre

**22 de octubre — C5-C2: ENTREGA PARCIAL.** D1–D7 aprobados (7/8), D8a/c/d/e
aprobados; D8b Tira online pendiente por segundo cliente. Ambos repos trabajan
en fix/c5-c2-validacion, sin push/merge/despliegue ni intervención OV-1.
[Entrega](C5C2_ENTREGA_PARCIAL.md) y [acta vigente](C5C2D_VALIDACION_LOCAL.md).
Sigue auditoría de Pavel y preparación de D8b; los estados inferiores son antecedentes.

**21 de octubre — [C5-C2-C validada automáticamente](C5C2C_CONSUMIDORES.md):**
contratos/snapshots y Flutter incorporan imágenes opcionales sin cambiar XP ni
romper JSON antiguo.969 Flutter aprobadas/16 opt-in omitidas,128 suites/1.675
backend y44/44 PostgreSQL/HTTP;70 migraciones temporales, ninguna nueva de C2-C.
**Sigue C2-D:0/8 guiones humanos propuestos**, con Docker/USB al preparar la sesión.
Activación apagada por defecto; sin nuevo ensayo Android ni despliegue. C1 conserva5/5.
Entrega C2-C/relevo: app `e833d6b`, backend `cfba7cd`.
Deuda ESLint previa:27 incidencias verificadas en HEAD, descritas en el acta.
Integrada en main local: app `f912880`/backend `09c763b`; sin push nuevo ni cambios OV-1.

**20 de octubre, continuación vigente:** [C5-A/B](C5_ARCHIVOS.md) validadas localmente:
23/23 PostgreSQL/HTTP, panel124/124 y recorrido Chromium;69 migraciones temporales. Rama `feat/c5-archivos-base`,
sin merge/despliegue. Sigue C Flutter/consumidores
y D integración/operación. Los antecedentes del19 inferiores conservan sus cierres.

**Actualización vigente del19:** [MA-1R/R4](MA1R_R4_VALIDACION_LOCAL.md) con12/12
humanos y45/45 PostgreSQL/HTTP, Flutter920/13 opt-in omitidas, backend121/1567 tras fix de concurrencia,
ADMIN109 y build/análisis aprobados. Remate Android confirmado: R4 cerrada
localmente e integrada a main por [app PR #6](https://github.com/Pavel2020123/saber_plus/pull/6)
(`21757a1`) y [backend PR #9](https://github.com/Pavel2020123/SaberPlus-Backend/pull/9)
(`eef0d40`). CI backend del PR aprobado; QA-1 Flutter remoto pendiente. Sigue C5,
archivos generales, con preparación local. OV-1 separado,
sin despliegue ni nuevas autorizaciones remotas. Notas del17/18 son antecedentes.

Vista de coordinación; no sustituye el inventario único de
[ETAPAS_PENDIENTES](ETAPAS_PENDIENTES.md#ruta-vigente-del-equipo).
Auditoría de documentación activa de planificación/relevo, con comprobación
acotada de MA-1 en código. No es auditoría funcional completa de los dos proyectos.
La auditoría inicial del17 fue documental. Las entregas posteriores registran
R2 backend, [R3 app/panel](MA1R_R3_APP_PANEL.md), validación R4 e integración
Git del19. No se desplegó MA-1R ni se aplicó SQL remoto en esta entrega.

## Qué terminó y qué significa

- **Actualización posterior: etapa 1 completada el 17 de octubre.**
  [App PR #5](https://github.com/Pavel2020123/saber_plus/pull/5) integrado en
  `main` como `e679c5067cf70c935d4e89b6b9b6bce835e951dc`;
  [backend PR #8](https://github.com/Pavel2020123/SaberPlus-Backend/pull/8)
  como `388bb18e52ebd0c0309dcdd437f73397e8d6f66e`.
  [CI del PR](https://github.com/Pavel2020123/SaberPlus-Backend/actions/runs/39071235627)
  y [CI posterior en main](https://github.com/Pavel2020123/SaberPlus-Backend/actions/runs/39071411694)
  aprobados: admin/verify, instalación, build, 119 suites/1.470 pruebas,
  controles locales y auditoría de dependencias. No se desactivaron checks.
  Flutter: análisis sin incidencias y 102 pruebas dirigidas aprobadas ahora
  (código igual al publicado). Sin workflow Flutter; QA-1 sigue abierto.
  No se repitieron las 893 globales ni los ensayos físicos/SQL; no despliegue.
  Los puntos de auditoría siguientes conservan el estado anterior a esta entrega.
- Instituciones: cierre técnico local de directorio/territorio, presentación,
  logo, solicitudes/avisos y código estudiantil. [Acta consolidada](CIERRE_INSTITUCIONES_LOCAL.md).
- Commits locales: app `6bab6be`; backend `7ba93d7` y lockfile `bfce42e`.
  Al revisar, HEAD coincidía con `origin/feat/instituciones-c2c` en ambos clones.
  Eso no acredita PR aprobado, CI verde ni merge remoto a main; no se consultaron
  esos estados en GitHub durante esta auditoría.
- Pruebas de cierre conservadas: Flutter 893 aprobadas/13 opt-in omitidas;
  backend 1.470/119 suites; panel 95/95. No se repitieron al editar estos documentos.
- No desaparecen observaciones: JPEG pequeño original y posteriores
  staging/producción. CI Linux/Node/npm fijados ya quedó comprobado al integrar.
  Logo acotado en PostgreSQL no cierra
  C5 de archivos generales ni evidencia documental privada.
- Cima/Guardián/Rescate y mapa/repaso ya tienen implementaciones y actas: no
  rehacerlos desde cero por instrucciones históricas.

## Frentes independientes

**Compañero: OV-1A/B/C/D en curso según el propietario.** No se ha recibido/verificado
su entrega en estos clones. No cambiar su código ni su CHECKPOINT_OV1, no asignarle
perfiles/insignias automáticamente y no afirmar que terminó alguna fase.

**Propietario: MA-1R completada localmente e integrada.** R1–R4 y su evidencia en
[checkpoint](MA1R_REPORTES_PREGUNTAS.md):12/12 humanos,45/45 HTTP/PostgreSQL,
backend121 suites/1567, Flutter920/13 opt-in omitidas, ADMIN109 y análisis/build.
PR app #6/backend #9 integrados; CI backend del PR aprobado. Solo SQL temporal,
sin despliegue, independiente de OV-1/P5/D3. Sigue preparación local C5.

Antes de nueva implementación: guardar/publicar por separado esta documentación
pendiente y crear rama del nuevo bloque desde main aprobado. No mezclar el próximo módulo con la entrega
institucional ya publicada, ni hacer merge/pull sobre cambios sin guardar. Avisar
al compañero antes de tocar schema.prisma, app.module, navegación, sesión o lockfiles.

## Orden recomendado y pendientes completos

| Paso | Bloque | Qué falta sin rehacer lo existente |
|---|---|---|
|0 | Entrega institucional — completada | PR app #5 y backend #8 integrados en main; CI backend del PR y de main aprobado, análisis Flutter/102 pruebas dirigidas aprobados. QA-1 Flutter remoto pendiente. Sin despliegue; no repetir C2/C3/C4. |
|1 | MA-1R — Reportes académicos — completada en esta fase | R1–R4 cerradas localmente e integradas en main por PR app #6/API #9;12/12 humanos,45/45 HTTP/PostgreSQL y regresiones en acta R4. CI backend del PR aprobado. Sin despliegue/migración remota; staging y operación pendientes. [UX1 Ocultar/Deshacer](MA1R_UX1_OCULTAR_DESHACER.md) sigue propuesta separada, no implementada. |
|2 | C5 — Archivos generales | [C5-A/B](C5_ARCHIVOS.md) validadas:23/23 PostgreSQL/HTTP, panel124/124 y recorrido Chromium. Sigue C Flutter/opciones/PDF/fotos y D integración/operación. Proveedor persistente y evidencia privada siguen pendientes; servicio real requiere autorización. |
|3 | Académico/profesor/ADMIN | P5→D3 cuando se autoricen; catálogo versionado C4 editorial y versiones/restauración C6. Ensayos de mapa MA-2, repaso MA-3, contratos de intentos/AM-PM/historial y seis certificados. Contenido7J se prepara durante el bloque, no solo al final. |
|4 | PR-I3/PR-I4 — Insignias/perfiles | Concesión anual idempotente, historial/correcciones; TOP50 y todas las ganadas, sin límite3. Avatar/foto, alias, búsqueda/visita y privacidad. No conceder premios de modalidades competitivas no validadas. |
|5 | PR-I6/6-T/7 — Instituciones sociales | Ranking nacional/departamento/municipio con pertenencia histórica y sin trasladar XP; ensayo social de dos cuentas/dispositivos y filtros. No es parte del cierre institucional local ya realizado. |
|En paralelo | OV-1 — Compañero | Contenido/reglas, persistencia privada, cuestionario/resultados y validación. Sin XP, ranking ni certificados; familias exploratorias, no diagnóstico. Sabi visual por seis familias, pendiente de assets/UI. |
|6 | Seguridad y cierre comercial | Identidad/sesión única/refresh/revocación, recuperación/eliminación y SMTP; sincronizaciones. Billing/derechos/restauración/reembolsos y anuncios/comodines verificados, ubicaciones acordadas. Sin Wompi/ePayco. |
|7 | Contenido/calidad y privacidad | Carga ADMIN por área/tema/subtema, banco suficiente y explicaciones, fuentes/licencias y soporte. Políticas/retención/SDK reales. Complementa7J/8E, no añade Excel obligatorio. |
|8 | UI-F/Sabi | Ventana por ventana: azul S+, botones/componentes, claro/oscuro, perfiles, accesibilidad y recorrido de bienvenida. Animaciones profesionales y audios al acabado final, después de funciones/integraciones y antes de beta/capturas. |
|9 | QA-1/DOC-1 +8F/8G/8H | CI y deuda técnica, higiene documental, respaldo/restauración/observabilidad, beta integral, red/cuentas/roles, PDF/audio y Android real; iOS solo con entorno disponible. Seguridad/CI se trabajan desde ahora, no se aplazan hasta este paso. |
|10 |8I/9A — Lanzamiento/operación | Firma/AAB, ficha/privacidad/revisión Play, publicación autorizada y gradual, soporte/monitoreo/contenido/costos. Smoke controlado en producción, no tests destructivos automáticos. |
|Posterior | Competición aplazada | Trivia/Duelo/Tira competitivos, Memoria IC-2 y Batallas IC-3; conservar modos normales/motores/arte. No reincorporar Taller de inventos ni Escudo. Nueva priorización antes de activar. |

El orden se puede ajustar por dependencias explícitas, no eliminando funciones.
P5/D3 siguen pausadas: no pedir nuevas credenciales ni desplegar por leer esta tabla.
El segundo reparto tras OV-1 sigue siendo propuesta, no asignación vigente.

## MA-1R integrada: no reiniciar R4

Evidencia actual: [Cobertura](COBERTURA_DEL_BANCO.md) y `backend/BANK_COVERAGE.md`;
`backend/src/admin/bank-coverage.service.ts` conserva por defecto
`reportesDisponibles:false` y `reportes:null`, y ofrece conteos con reportesVersion=1.
R3 consume esa versión con fallback compatible. No cambiar valores a ceros
inventados ni confundir reportes de rivales con reportes de preguntas.

1. **R1 — Auditar y acordar contrato:** localizar pregunta/versión/usuario y
   pantallas existentes, quién puede reportar, motivos, estados de revisión,
   deduplicación/reintento y límites. Proponer reglas pendientes al propietario.
2. **R2 — Backend:** persistencia y endpoints autorizados, auditoría/aislamiento,
   sin publicar/retirar una pregunta automáticamente por recibir un reporte.
3. **R3 — Panel y app:** formulario claro sin exponer respuesta anticipadamente;
   bandeja ADMIN, indicadores de cobertura, fallos/red y confirmaciones coherentes.
4. **R4 — Validación:** unitarias, PostgreSQL/HTTP y recorrido físico, separados en
   acta. Solo después cerrar reportes y dejar ensayo de staging identificado.

R1–R4 completadas localmente, migración aplicada solo a bases temporales.
[R3 app/panel](MA1R_R3_APP_PANEL.md) y [R4](MA1R_R4_VALIDACION_LOCAL.md)
integradas en main por los PR superiores. C5-A comenzó el20: [base local y siguiente verificación](C5_ARCHIVOS.md).
No requiere cambiar intereses vocacionales,
monetización, juegos ni permisos docentes. Si comparte schema/rutas base con OV-1,
coordinar migraciones/archivos antes de editar.

## Correcciones de esta auditoría

Se actualizaron estados de instituciones/commits en las entradas vigentes,
alcance de noviembre (C2 ya probado), funcionalidades (Guardián/Rescate locales),
guías de reparto/relevo que aún remitían al logo y siguientes pasos históricos de
cobertura/mapa. Las actas antiguas no se borran ni se convierten en pruebas nuevas.
La guía compartida de Sabi queda en seis familias, no doce carreras obligatorias;
no se editaron CHECKPOINT_OV1 ni documentos exclusivos del compañero.

Decisiones aún abiertas: integración de entregas y retención/operación de reportes,
documentación pendiente/QA-1, entorno P5/D3, proveedor C5, reglas que falten en ranking institucional y
productos/ubicaciones comerciales. Esta auditoría no las decide silenciosamente.

## Comprobación documental

- Tras registrar la integración, se comprobaron destinos de 609 enlaces locales en 29 documentos seleccionados
  entre ambos repositorios: ninguno apunta a un archivo inexistente. Esto no
  verifica anchors, enlaces externos ni contenido de páginas remotas.
- `git diff --check` sin incidencias en ambos repositorios. Cambios de esta tarea
  limitados a Markdown; sin código, migraciones, assets ni CHECKPOINT_OV1.
- Evidencia de pruebas anteriores conservada, sin declararla reejecutada.
- Entrega documental separada, con publicación manual/PR pendientes. La entrega posterior sí
  integró los commits institucionales previos vía PR; no incorpora esta auditoría.
  Conservados ahora en `docs/estado-post-instituciones`, creada desde origin/main
  con árbol idéntico al código probado. No se descartó ni guardó en stash ningún cambio.
  Mensaje documental en ambos repos: `docs: actualizar etapas tras integrar instituciones`.
  Consultar el hash local con `git log -1 --oneline`; no se hace push ni merge
  documental automáticamente por crear estos commits.
