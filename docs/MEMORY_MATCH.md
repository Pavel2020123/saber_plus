# Memoria académica

El juego de memoria reutiliza las 130 flashcards locales de SaberPlus. No copia preguntas protegidas ni necesita conexión para preparar el tablero.

## Contenido y niveles

El estudiante puede jugar con fórmulas, términos del glosario o una mezcla, además de filtrar por área ICFES. Cada pareja relaciona:

- el nombre o la pregunta de una fórmula con su expresión;
- un término del glosario con su definición.

Los niveles disponibles son:

- fácil: 6 parejas y 12 tarjetas;
- medio: 8 parejas y 16 tarjetas;
- difícil: 10 parejas y 20 tarjetas.

Las tarjetas se mezclan en cada partida. La interfaz registra tiempo, movimientos y parejas encontradas, respeta la preferencia de reducir movimiento y muestra al final el contexto académico de cada pareja.

## Pistas y modelo comercial

La pista revela temporalmente una pareja que todavía no se ha encontrado. En demostración puede utilizarse sin límite y marca la partida como asistida. Cuando se conecte AdMob, cada pista gratuita requerirá una reproducción recompensada iniciada manualmente; una cuenta sin anuncios recibirá la misma pista sin reproducir publicidad.

Las partidas asistidas no podrán establecer récords ni participar en el futuro duelo fantasma. El juego no entrega XP académico ni altera diagnósticos, simulacros o rankings.

## Audio pendiente

Los recursos se incorporarán cuando el equipo conserve una copia de sus licencias:

- `memory_flip.mp3`: giro de tarjeta, entre 0,1 y 0,3 segundos;
- `memory_match.mp3`: pareja encontrada, entre 0,3 y 0,7 segundos;
- `memory_finish.mp3`: tablero completado, entre 1 y 2 segundos.

Los archivos se ubicarán en `assets/audio/`. No se declaran rutas inexistentes en `pubspec.yaml`.

## Siguiente evolución

La Etapa 6F-C añadirá el récord personal y el duelo fantasma. Solo se guardarán resultados de partidas sin pistas y se separarán por nivel, tipo de contenido y área para evitar comparaciones injustas.
