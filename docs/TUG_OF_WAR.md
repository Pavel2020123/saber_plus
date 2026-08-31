# Tira y afloja

## Estado actual: maqueta funcional local

La primera entrega permite jugar contra un rival CPU reutilizando las preguntas públicas y la validación protegida de Trivia Rush. Los personajes son marcadores provisionales y ningún movimiento utiliza todavía animaciones definitivas.

## Reglas de la maqueta

- Ambos participantes reciben la misma pregunta.
- Cada pregunta permite diez segundos.
- Si uno acierta y el otro falla o no responde, la cuerda avanza dos marcas hacia quien acertó.
- Si ambos aciertan, la cuerda avanza una marca hacia quien respondió primero.
- Una diferencia de hasta 200 milisegundos se considera empate de velocidad.
- Si ninguno acierta, la cuerda no se mueve.
- Gana quien alcanza primero la cuarta marca de su lado.
- La partida local no entrega XP, no modifica rachas y no publica estadísticas.
- No hay potenciadores ni anuncios durante una partida.

## Dificultad del rival

El modo Entrenamiento responde más despacio y comete más errores. Equilibrado es la opción inicial. Desafío responde con mayor rapidez y precisión. Esta simulación solo existe para validar la experiencia antes del multijugador.

## Frontera de seguridad

Flutter envía la respuesta elegida al mismo repositorio protegido de Trivia Rush y no necesita conocer la clave correcta antes de responder. En producción, el servidor deberá ser la fuente de verdad para pregunta, tiempos, respuesta, movimiento de cuerda y resultado.

## Siguiente entrega visual

Sobre esta maqueta se reemplazarán los marcadores por personajes detallados y se incorporarán estados de espera, esfuerzo, tirón, recuperación, tensión, victoria y derrota. Esa etapa no cambiará las reglas del motor ya probado.

## Multijugador pendiente

El backend necesitará emparejamiento, WebSockets autenticados, reloj de servidor, rondas idempotentes, reconexión, abandono, control de versiones de reglas y detección básica de manipulación. No se habilitará chat libre entre jugadores.
