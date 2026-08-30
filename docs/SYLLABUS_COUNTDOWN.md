# Countdown del temario por materia

La etapa 6D-F convierte la fecha de la convocatoria y el progreso académico en una ruta semanal por materia.

## Fuentes de verdad

Flutter combina únicamente datos ya disponibles en la API:

- convocatoria activa y `fechaExamen` del inicio académico;
- catálogos de las cinco áreas mediante `GET /simulacros/temas?area={AREA}`;
- progreso mediante `GET /simulacros/progreso`.

No se escriben fechas, temarios ni cantidades fijas dentro de la pantalla. Un subtema se considera completado cuando el backend informa un progreso de 100 %.

## Cálculo

La app muestra:

- días de calendario restantes;
- subtemas totales, completados, en progreso y pendientes;
- ritmo sugerido de subtemas por semana;
- progreso y próximos subtemas de cada materia;
- materias ordenadas por cantidad pendiente y luego por menor avance.

El ritmo semanal se obtiene dividiendo los subtemas pendientes entre las semanas disponibles. Las etiquetas “alcanzable”, “exigente” e “intensivo” sirven para presentar esa carga; no reemplazan el diagnóstico ni afirman que un tema esté dominado.

## Estados seguros

- Sin convocatoria: conserva el temario pendiente, pero no inventa una fecha ni un ritmo.
- Convocatoria vencida: solicita actualizarla y evita mostrar días negativos.
- Sin contenido publicado: informa que el temario está pendiente de carga.
- Todo completado: recomienda mantener el conocimiento con repasos y simulacros.

Si el backend cambia el catálogo o el progreso, la pantalla se recalcula al actualizarse. La aplicación no mantiene una segunda copia autoritativa del temario.
