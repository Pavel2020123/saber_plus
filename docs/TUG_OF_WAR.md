# Tira y afloja

## Estado actual: experiencia local animada

La etapa 6F-D-B permite jugar contra un rival CPU reutilizando las preguntas públicas y la validación protegida de Trivia Rush. La arena ya incorpora ilustraciones propias para el escenario y los dos competidores, mientras la cuerda, la tensión y los efectos se dibujan y animan desde Flutter para responder al estado real de cada ronda.

## Reglas de la partida

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

## Secuencias visuales y sonoras

- La entrada presenta la arena y coloca a ambos competidores antes de iniciar el reloj de la primera pregunta.
- Durante la espera, los personajes mantienen movimiento ambiental suave y la cuerda refleja la tensión del duelo.
- Al responder, el competidor correspondiente muestra una reacción inmediata sin revelar si acertó antes de resolver la ronda.
- Los tirones rápidos desplazan la cuerda una marca (`±1`) y los tirones fuertes la desplazan dos (`±2`) con una fase adicional de esfuerzo y tensión.
- Un empate de velocidad conserva la posición y muestra la resistencia simultánea de ambos lados.
- Después de cada resolución, los personajes se recuperan antes de habilitar la continuación.
- La victoria y la derrota se representan después del último tirón, para que el resultado no interrumpa el movimiento decisivo.
- Los sonidos de tensión y tirón se disparan en los momentos correspondientes de la animación; los sonidos finales conservan la preferencia general de audio de juegos.

Las animaciones respetan la opción de reducción de movimiento del sistema. Cuando está activa, la arena muestra directamente los estados finales, mantiene la información y los sonidos necesarios, y evita movimientos prolongados o repetitivos.

## Recursos visuales

Los tres PNG de esta etapa viven en `assets/images/games/tug_of_war/`: fondo de arena, competidor del estudiante y rival CPU. La posición de la cuerda, las partículas y los estados de la ronda siguen siendo controlados por código para que el resultado visual coincida con el motor del juego.

## Multijugador en construcción

La etapa 6F-D-C-A ya incorporó al backend el esquema de partidas, emparejamiento, reloj de servidor, rondas idempotentes, abandono y eventos versionados. El contrato se detalla en [TUG_OF_WAR_BACKEND_CONTRACT.md](TUG_OF_WAR_BACKEND_CONTRACT.md).

La etapa 6F-D-C-B también está terminada: el backend dispone de Socket.IO autenticado, salas privadas, presencia, avisos de actualización, reloj autónomo y recuperación versionada. Continúa pendiente 6F-D-C-C para conectar la arena Flutter. No se habilitará chat libre entre jugadores y, hasta terminar esa entrega, la partida visible seguirá siendo local contra CPU.
