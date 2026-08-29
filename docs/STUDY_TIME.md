# Tiempo total estudiado

La etapa 6C-K incorpora `Más > Tiempo estudiado` con el total acumulado, el tiempo de hoy, los últimos siete días y un desglose por actividad.

## Qué tiempo se registra

- Cada bloque Pomodoro que llega realmente a cero suma 25 minutos.
- Una práctica, un simulacro o un repaso adaptativo suma los tiempos de respuesta únicamente después de que la calificación queda confirmada.
- El diagnóstico suma sus tiempos de respuesta únicamente después de finalizar correctamente.

Abrir una lección o dejar una pantalla visible no suma tiempo automáticamente, porque no demuestra que el estudiante esté activo. Un reinicio o un intento duplicado tampoco duplica una actividad ya registrada: cada evento tiene un identificador único por estudiante.

## Persistencia y privacidad

Los registros contienen solamente el estudiante, identificador del evento, fuente, cantidad de segundos y fecha. No guardan preguntas, respuestas ni contenido académico.

El acumulado actual es local al dispositivo y empieza a crecer desde esta versión. El backend auditado no publica todavía un contrato de tiempo total ni permite sincronizar estos eventos entre dispositivos. Cuando exista ese contrato, el identificador idempotente permitirá enviarlos sin duplicar minutos.

El modo demostración usa datos ficticios aislados; una cuenta real nueva comienza en cero.
