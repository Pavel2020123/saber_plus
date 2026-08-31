# Trivia Rush

Trivia Rush es un juego individual de velocidad. El estudiante elige una materia o una mezcla de las cinco áreas y una ronda de 60, 90 o 120 segundos. No sustituye un simulacro ni altera el XP académico.

## Reglas implementadas

- Cada acierto entrega 100 puntos por el multiplicador activo.
- Los combos 1–2 usan `x1`, 3–5 usan `x2`, 6–9 usan `x3` y desde 10 usan `x4`.
- Un error reinicia el combo, salvo que haya una protección activa.
- La demostración aumenta la dificultad cada diez preguntas; en producción el orden deberá decidirlo el servidor.
- La pantalla final informa aciertos, errores, preguntas saltadas, mejor combo y temas que conviene reforzar.
- Las rondas con potenciadores quedan marcadas como asistidas y no podrán participar en rankings futuros.
- No se muestran anuncios durante la partida.

Los potenciadores disponibles son diez segundos adicionales, descartar dos opciones incorrectas, proteger el combo, saltar una pregunta y obtener una segunda oportunidad. En demostración pueden probarse sin límite. En producción, una cuenta gratuita deberá solicitar cada potenciador manualmente mediante un anuncio recompensado verificado; una cuenta sin anuncios recibirá la misma recompensa sin reproducirlo.

## Protección del banco

La sesión solo contiene enunciados y opciones públicas. Nunca serializa `esCorrecta` ni otra clave de respuesta. La demostración usa un repositorio local aislado; una cuenta real recibe un mensaje explícito mientras se publica el contrato autoritativo.

El backend debe exponer operaciones autenticadas e idempotentes para:

1. crear un intento con áreas y duración;
2. validar una respuesta individual y devolver su resultado únicamente después de responder;
3. autorizar un potenciador con el derecho Premium o la prueba recompensada del servidor;
4. finalizar por vencimiento y guardar puntaje, asistencia y diagnóstico;
5. impedir que una misma respuesta o recompensa se consuma dos veces.

El servidor será la fuente de verdad para el orden de las preguntas, la calificación, el puntaje final y la validez de una recompensa. La aplicación no debe calcular un resultado competitivo confiable usando una clave descargada.

## Audio pendiente de incorporar

Los cinco recursos deben ser cortos, libres de regalías y contar con licencia conservada por el equipo:

- `trivia_correct.mp3`: acierto, entre 0,2 y 0,5 segundos;
- `trivia_wrong.mp3`: error suave, entre 0,2 y 0,5 segundos;
- `trivia_combo.mp3`: subida o *whoosh*, entre 0,5 y 1 segundo;
- `trivia_countdown.mp3`: tic muy breve para los últimos segundos;
- `trivia_finish.mp3`: cierre de ronda, entre 1 y 2 segundos.

Se ubicarán en `assets/audio/`. No se declara un archivo inexistente en `pubspec.yaml`: la conexión de audio se hará después de que el equipo entregue los recursos y confirme sus licencias.
