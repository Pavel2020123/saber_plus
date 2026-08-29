# Repaso de errores del día

La etapa 6C-I agrega `Practicar > Repasar errores de hoy`. La pantalla consulta el historial real de respuestas incorrectas y conserva para la vista únicamente los fallos cuya fecha local corresponde al día actual.

## Funcionamiento

- Solicita hasta 100 respuestas incorrectas recientes al endpoint de historial existente.
- Descarta resultados de días anteriores.
- Si una pregunta se falló varias veces hoy, muestra solamente el intento incorrecto más reciente.
- Presenta el área, tema, subtema, respuesta elegida, respuesta correcta y explicación que el backend ya autorizó después de calificar.
- Permite marcar cada explicación como repasada y muestra el avance de la sesión actual.
- Ofrece continuar hacia el repaso inteligente para generar un intento nuevo y protegido.

La marca visual de “repasada” dura mientras la pantalla está abierta; no modifica el historial oficial ni crea resultados académicos falsos.

## Protección y límite actual

La app no guarda otra copia del enunciado o las respuestas. Cada apertura vuelve a consultar el historial protegido del estudiante.

El backend actual no acepta un rango de fechas en este endpoint. Por eso Flutter solicita el máximo permitido de 100 respuestas incorrectas y aplica el filtro diario en el dispositivo. Si en el futuro se habilita `desde` y `hasta`, conviene mover el filtro al servidor para cubrir jornadas con más de 100 fallos.
