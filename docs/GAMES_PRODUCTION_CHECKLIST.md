# Insumos pendientes para publicar los juegos

Esta lista separa lo que debe aportar el equipo de contenido de lo que debe implementar el backend. Flutter no debe contener secretos, claves de respuestas reales ni credenciales de AdMob.

## 1. Audios y licencias

Archivos integrados de Trivia Rush:

- `trivia_correct.mp3`
- `trivia_wrong.mp3`
- `trivia_countdown.mp3`
- `trivia_finish.mp3`

Archivos integrados de memoria:

- `memory_flip.mp3`
- `memory_match.mp3`
- `match_victory.mp3` (cierre compartido de partida)

Archivos integrados para resultados y el futuro juego de tira y afloja:

- `match_found.mp3`
- `match_countdown.mp3`
- `match_victory.mp3`
- `match_defeat.mp3`
- `tug_pull.mp3`
- `tug_rope_strain.mp3`

Los archivos ya están declarados en `pubspec.yaml`, cuentan con una preferencia general y tienen pruebas automatizadas. Antes de publicar falta completar autor, página de origen, URL de descarga, licencia, fecha de descarga y modificaciones en `docs/licenses/AUDIO_LICENSES.md`, además de escucharlos en dispositivos Android e iOS reales.

## 2. Contenido académico

Trivia Rush necesita preguntas revisadas con área, tema, subtema, dificultad, cuatro opciones, respuesta correcta y explicación. La respuesta correcta permanece únicamente en el backend.

Como piloto conviene contar con al menos 30 preguntas variadas por área. Para reducir repeticiones al publicar, el objetivo debe crecer hacia 100 o más por área, repartidas entre dificultad básica, media y avanzada. Todo contenido debe ser propio, autorizado o legalmente reutilizable.

El juego de memoria ya dispone de 80 fórmulas y 50 términos locales. Antes de publicar solo hace falta revisar redacción, símbolos, tildes y atribución del catálogo.

## 3. Contrato autoritativo de Trivia Rush

El motor, la persistencia y el consumo seguro de concesiones quedaron implementados en la etapa 6G-A. Flutter quedó conectado en 6G-B con reloj sincronizado, recuperación y resultados del servidor. El contrato exacto está en `docs/TRIVIA_RUSH_BACKEND_CONTRACT.md`. Falta emitir las concesiones reales mediante AdMob SSV o derechos validados de tienda cuando existan las cuentas comerciales.

El backend NestJS ofrece operaciones versionadas equivalentes a:

1. crear un intento con áreas y duración;
2. entregar preguntas públicas sin la clave correcta;
3. validar una respuesta individual, impedir duplicados y devolver el resultado después de responder;
4. autorizar y consumir un potenciador una sola vez;
5. finalizar por vencimiento y devolver puntaje, combo y diagnóstico confirmado;
6. recuperar un intento vigente de manera idempotente.

El reloj, la secuencia, el puntaje, los checkpoints y la finalización confiable se calculan en el servidor. El cliente puede animarlos, pero no debe convertirse en la fuente de verdad.

## 4. Récord fantasma en la nube

La etapa 6G-C quedó implementada. El servidor consulta el mejor intento limpio por:

- `userId`;
- tipo de juego;
- versión de reglas;
- áreas seleccionadas;
- duración.

Flutter solo consulta ese récord mediante `GET /trivia-rush/fantasma`. El backend lo reconstruye a partir de respuestas finales de un intento ya calificado y nunca acepta un puntaje arbitrario enviado por el teléfono. La respuesta contiene intento de origen, puntaje final, aciertos, mejor combo y checkpoints de tiempo/puntaje. Un cambio en las reglas de puntuación crea una versión nueva y no mezcla récords incompatibles.

No se creó una copia mutable del récord: la fuente de verdad continúa siendo `IntentoTriviaRush` y sus respuestas autoritativas. Esto evita inconsistencias y permite sincronizar automáticamente el fantasma entre dispositivos.

## 5. Persistencia sugerida

Como referencia de diseño, el backend necesita entidades equivalentes a:

- `game_attempts`: usuario, juego, configuración, versión, estado, asistencia, puntaje y fechas;
- `game_checkpoints`: intento, secuencia, tiempo transcurrido y puntaje;
- `personal_game_records`: usuario, juego, configuración y mejor intento confirmado;
- `reward_grants`: recompensa emitida, proveedor, usuario, estado y vencimiento;
- `game_booster_consumptions`: intento, recompensa, potenciador y fecha de consumo.

Los nombres definitivos deben ajustarse a las convenciones de Prisma/PostgreSQL del backend existente.

## 6. AdMob y plan sin anuncios

En la etapa comercial se necesitarán los identificadores de aplicación y unidades de prueba/producción de AdMob para Android. Las recompensas deben validarse mediante Server-Side Verification y convertirse en un `rewardGrantId` de un solo uso. Flutter nunca debe otorgar una ventaja solo porque un callback local diga que el video terminó.

El backend también debe recibir el derecho sin anuncios validado desde Google Play Billing. Una cuenta con ese derecho solicita el mismo potenciador sin mostrar publicidad; las reglas del juego no cambian.

## 7. Datos que no deben registrarse

No se enviarán a publicidad respuestas, falencias, materias débiles, institución, carreras sugeridas ni puntajes. Los registros técnicos deben evitar enunciados completos y respuestas correctas; para observabilidad bastan identificadores, estado, latencia y códigos de error.
