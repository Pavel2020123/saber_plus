# SaberPlus V1 — Alcance de noviembre de 2026

Decisión del propietario: **9 de octubre de 2026**. Objetivo de sustentación:
15 de noviembre de 2026; es una meta, no una garantía de terminar todo.
Este acuerdo corrige la propuesta que aplazaba también funcionalidades sociales
y vocacionales: **solo se recorta el bloque de integraciones competitivas**.
El orden y los estados vivos se mantienen en
[ETAPAS_PENDIENTES](ETAPAS_PENDIENTES.md#ruta-vigente-del-equipo).

## Qué cambia y qué se conserva

- Competición inicial: **Cima, Guardián y Rescate de estrellas**. Cima y Guardián
  tienen validación local acotada; Rescate sigue pendiente. No implica producción.
- Trivia, Duelo fantasma, Tira y afloja, Memoria (IC-2) y Batallas (IC-3):
  integración competitiva aplazada, no cancelada. Conservar código, contratos,
  migraciones, imágenes y modos normales existentes. Revisar estabilidad de los
  modos que se muestren; no presentar una competición sin validar como disponible.
- **Después de Rescate se continúa con instituciones, no con Trivia.**
- Permanecen perfiles, búsqueda de personas e instituciones, fotos, todas las
  insignias ganadas por año, ranking institucional y filtros territoriales.
- **OV-1, el test vocacional orientativo, permanece**: intereses privados,
  resultados explicables, carreras para explorar y Sabi por profesión. No es un
  diagnóstico psicológico ni determina lo que alguien debe estudiar.
- Permanecen estudio, profesor, ADMIN, mapa de aprendizaje, repaso diferido,
  cobertura del banco, seis certificados, seguridad, sincronización, monetización,
  acabado azul, accesibilidad, Android/iOS y preparación de lanzamiento.
- No se reincorporan Taller de inventos, Escudo, tutores, chat ni funciones no
  acordadas. No rehacer módulos ya implementados para considerarlos terminados.

## Bloques de ejecución y criterios de cierre

Estos bloques agrupan los identificadores existentes; **no borran ni renumeran
el historial**. La tabla detallada del roadmap conserva cada pendiente técnico.

| Orden | Alcance y correspondencia | Evidencia necesaria para cerrar |
|---|---|---|
| 1. Competición inicial | Terminar IC-1C Rescate. Conservar actas IC-1A Cima e IC-1B Guardián. | Modo explícito, permisos, recuperación, reintento, resultado/XP único y ranking; normal sin XP competitivo. Actas por juego con límites. |
| 2. Instituciones | PR-I5/P4-C y PR-I5-T: aprobación ADMIN con evidencia privada, directorio por nombre/departamento/municipio, perfil institucional, solicitudes y avisos, código institucional privado. | Aprobada/rechazada/pendiente, propietario autorizado para editar, permisos de estudiantes y profesor; no confundir código de grupo con institucional. C5 antes de fotos/logo persistentes. |
| 3. Académico, profesor y panel | P5 → D3 cuando se autorice; C4/C6, MA-1/2/3, contratos académicos, contenido 7J y certificados. | Panel → API → app, caché/versiones sin perder progreso, mapas/repasos, seguimiento docente y PDF con nombre registrado. Cinco áreas + curso, todas las lecciones publicadas; área vacía no certifica. Reutilizar ensayo académico ya documentado. |
| 4. Insignias y perfiles | PR-I3/4: TOP 50, premios anuales, alias/avatar/foto, búsqueda y visita a perfiles. | Todas las insignias ganadas, sin límite de tres; 2026 permanece al ganar 2027. Concesión única y correcciones auditadas; detalle muestra juego/año/posición. Premios reales solo de modalidades competitivas validadas, nunca de fixtures. Profesor no jugador. |
| 5. Ranking institucional y ensayo social | PR-I6/6-T/7: aportes y pertenencia histórica, ámbito nacional/departamento/municipio, integración con perfiles. | Sin traslado ni doble conteo de XP histórico; filtros antes de paginar/ordenar. Dos cuentas, privacidad, solicitudes, fotos y conservación de temporadas. Filtro territorial no inventa premios regionales. |
| 6. Test vocacional | OV-1A/B/C/D: contenido/reglas revisados, persistencia privada, cuestionario reanudable y resultados con Sabi. | Preguntas propias/versionadas; empates, incompletos, permisos, repetición e historial. Familias/carreras con motivos, sin certeza ficticia ni exposición pública. Fuentes y revisión de contenido antes de publicación. |
| 7. Cierre funcional y comercial | Identidad/seguridad, sincronizaciones pendientes, 8A/B Billing, 8C/D anuncios/comodines, 8E/F privacidad y preparación operativa. | Sesión única/permisos, recuperación y eliminación; compras/restauración y anuncios de prueba verificados. Ubicaciones de anuncios acordadas con el propietario; sin Wompi/ePayco. No activar servicios/cobros reales sin autorización. |
| 8. Diseño final | UI-F/Sabi: azul S+, botones/componentes, perfiles sobrios, claro/oscuro, animaciones y audios. | Accesibilidad, texto grande, rendimiento y pruebas visuales/físicas. Animaciones complejas se trabajan al final, no bloquean el desarrollo funcional. No rediseñar ADMIN por este acuerdo. |
| 9. Validación y sustentación | QA-1, DOC-1, 8G/8H: regresiones, Android real, compatibilidad y prueba iOS con entorno disponible; guion de presentación. | Registrar ejecutado/fallido/omitido. Entorno reproducible, datos ficticios, recuperación de red, PDF/audio, roles y flujos completos. No afirmar iOS probado solo porque existe su carpeta. |
| 10. Lanzamiento y operación | 8I/9A y cierres operativos de 8E/F. | Firma/AAB, requisitos vigentes de Play, políticas, respaldo/restauración, monitoreo y autorización expresa. Publicación comercial inicial en Google Play; conservar iOS para entrega académica. |

Seguridad, tests y documentación se trabajan **en cada bloque**, no se dejan
para el séptimo o noveno. C5 puede adelantarse como dependencia de archivos.
P5/D3 remotos siguen pausados hasta disponer de entorno/cuentas autorizados;
se puede preparar y validar localmente sin afirmar cierre productivo.

## Fecha, alcance y relevo

Conservar estas funciones aumenta el trabajo: hay implementaciones locales,
integraciones, contenido por revisar y pruebas todavía pendientes. No se fija una
duración por bloque sin revisar su estado real. La sustentación y la publicación
comercial son hitos diferentes; mantener Billing/Ads en la ruta no autoriza cobros
ni promete aprobación de tienda para el 15 de noviembre.

Si la fecha peligra, informar al propietario con evidencia y pedir priorización;
**no quitar OV-1, perfiles u otras funciones silenciosamente**. Identificar en
la presentación qué funciona localmente, qué es demo y qué falta desplegar.

Después de cada prueba actualizar acta y
[checkpoint vivo](ETAPAS_PENDIENTES.md#checkpoint-de-relevo-de-pruebas), incluso
si no termina la etapa. El compañero debe leer ambos repositorios, auditar cambios
recibidos y continuar desde ese punto, no desde una orden antigua.
Usar [prompt general](PROMPT_RELEVO.md) y
[guía operativa de pruebas](RELEVO_PRUEBAS_LOCALES.md). No compartir secretos.

Esta entrega cambia documentación únicamente: no ejecutó nuevas pruebas de juegos,
no retiró código, no activó competición y no desplegó servicios.
