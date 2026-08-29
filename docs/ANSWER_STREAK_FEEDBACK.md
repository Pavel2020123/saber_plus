# Feedback de rachas de aciertos

Alcance implementado en la Etapa 6C-G para Android y iOS.

## Comportamiento

- La racha se calcula con el orden de la revisión que devuelve el servidor después de calificar el intento.
- Tres o más respuestas correctas consecutivas desbloquean el feedback.
- La pantalla de resultado muestra la racha más larga y reproduce una sola vez el sonido de éxito y la vibración corta.
- Una respuesta incorrecta reinicia el conteo consecutivo.
- El estudiante puede desactivar por separado el sonido y la vibración en `Más > Preferencias`, sin ocultar la confirmación visual.

Flutter no revela ni infiere respuestas correctas mientras la práctica está abierta. Esto conserva la protección del banco y evita premiar una selección antes de que el backend la confirme.

## Recurso sonoro

El archivo `assets/audio/answer_streak_success.mp3` dura aproximadamente 1,83 segundos y se reproduce al 65 % del volumen. Se incluye dentro de la aplicación y no requiere conexión a internet.

Antes de publicar, se debe conservar la fuente, el autor y la licencia del archivo para comprobar que permite uso comercial y redistribución dentro de una aplicación móvil.
