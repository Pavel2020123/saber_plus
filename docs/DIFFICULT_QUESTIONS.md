# Preguntas difíciles

La etapa 6C-H permite que cada estudiante marque una pregunta durante el intento o desde la revisión final y la encuentre después en `Más > Preguntas difíciles`.

## Datos locales

Cada marca se guarda en Drift/SQLite y queda separada por `userId`. La referencia incluye únicamente:

- identificador de la pregunta;
- área, tema y subtema;
- identificador del subtema cuando el intento lo proporciona;
- dificultad y fecha de la marca.

No se guardan el enunciado, las opciones, la selección del estudiante, la respuesta correcta ni la explicación. De esta forma, la función no convierte el banco protegido en contenido descargable.

## Repaso

Si existe un identificador de subtema, al abrir una marca se inicia una práctica nueva de ese subtema. En sesiones donde la API no entregue esa referencia, la app lleva al centro de práctica para que el estudiante elija cómo reforzarla.

Las marcas funcionan sin conexión en el dispositivo. Su sincronización entre dispositivos queda pendiente hasta que el backend publique un contrato específico que conserve la misma protección del banco de preguntas.
