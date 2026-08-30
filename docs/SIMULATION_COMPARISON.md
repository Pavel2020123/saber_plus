# Comparación entre simulacros

La etapa 6D-E permite que el estudiante compare dos simulacros calificados de la misma materia y consulte su evolución cronológica.

## Fuente de los datos

Flutter reutiliza `GET /simulacros/historial`. La aplicación no vuelve a calificar preguntas ni modifica porcentajes, respuestas correctas o XP. Únicamente:

- ordena los resultados por fecha;
- calcula la diferencia entre dos porcentajes ya confirmados;
- muestra las respuestas correctas como contexto;
- clasifica el cambio como mejora, estabilidad o oportunidad de refuerzo.

La comparación se restringe a una misma materia. Si dos intentos tienen cantidades diferentes de preguntas, el porcentaje es la medida principal y los aciertos absolutos no se comparan como si fueran equivalentes.

## Criterios visuales

- Mejora: aumento de 5 puntos porcentuales o más.
- Estable: cambio menor de 5 puntos en cualquier dirección.
- Oportunidad de refuerzo: descenso de 5 puntos porcentuales o más.

Estos textos son una ayuda visual, no un diagnóstico nuevo. Las falencias académicas continúan proviniendo del cuaderno de errores y de las etiquetas de tema y subtema del backend.

## Contrato pendiente para una comparación completa

El historial actual contiene los simulacros por área. Para incorporar jornadas AM/PM, ediciones históricas y pruebas contrarreloj, el backend deberá publicar un historial unificado que incluya como mínimo:

- identificador y tipo del simulacro;
- fecha de finalización;
- total, correctas, incorrectas y omitidas;
- porcentaje general;
- desglose por cada una de las cinco áreas;
- duración efectiva y estado confirmado del intento.

La app podrá extender esta pantalla cuando exista ese contrato, sin reconstruir resultados a partir de respuestas descargadas.
