# Tiempo total estudiado

La etapa 6C-K incorpora `Más > Tiempo estudiado` con el total acumulado, el tiempo de hoy, los últimos siete días y un desglose por actividad.

## Qué tiempo se registra

- Cada bloque Pomodoro que llega realmente a cero suma 25 minutos.
- Una práctica, un simulacro o un repaso adaptativo suma los tiempos de respuesta únicamente después de que la calificación queda confirmada.
- El diagnóstico suma sus tiempos de respuesta únicamente después de finalizar correctamente.

Abrir una lección o dejar una pantalla visible no suma tiempo automáticamente, porque no demuestra que el estudiante esté activo. Un reinicio o un intento duplicado tampoco duplica una actividad ya registrada: cada evento tiene un identificador único por estudiante.

## Persistencia y privacidad

Los registros contienen solamente el estudiante, identificador del evento, fuente, cantidad de segundos y fecha. No guardan preguntas, respuestas ni contenido académico.

El acumulado histórico de esta pantalla es local al dispositivo. P4-A/B añadió
API de tiempo/evolución y cola durable para nuevos Pomodoros completados; no
importa el historial antiguo ni reenvía tiempos de evaluaciones que ya conoce el
servidor. El resumen remoto y el acumulado local tienen fuentes distintas, no
deben sumarse como si fueran actividades diferentes. Implementación local con
ensayo real pendiente: [PROFESOR_P4_B.md](PROFESOR_P4_B.md).

El modo demostración usa datos ficticios aislados; una cuenta real nueva comienza en cero.
