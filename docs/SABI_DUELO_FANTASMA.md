# Sabi — primera renovación: Duelo fantasma

18 de septiembre de 2026. **G-SABI-1A: preproducción documentada**.
No hay nueva animación implementada, archivo Rive producido ni prueba visual de
esta renovación. Las reglas y recursos del juego existente se conservan.

## Objetivo elegido

Un Sabi consistente corre tras el fantasma de su récord. Cuando el resultado
confirma que lo supera, lo atrapa, lo levanta con ambas manos y celebra.
Si no lo supera, el fantasma escapa y Sabi muestra decepción breve y se recupera.
La celebración no utiliza la transformación musculosa de las referencias.

## Decisión técnica propuesta, no dependencia instalada

Animar un único personaje articulado: mismas piezas, colores, proporciones y logo
durante toda la secuencia. Rive es una opción de autoría e integración; animación
vectorial programada en Flutter es otra. No hay todavía elección definitiva ni
archivo `.riv`. Un PNG generado no contiene huesos, capas ni estados de animación.

La IA de imagen a video puede servir como referencia de movimiento o una secuencia
pregrabada revisada. No equivale a un personaje interactivo y no garantiza conservar
manos, logo o silueta; no se acepta automáticamente como arte final del juego.
No crear poses independientes y alternarlas como sustituto del movimiento continuo.

## Recursos que se prepararán

- Una referencia maestra de Sabi basada en el ajolote turquesa/branquias coral
  compartido por el usuario, con camiseta y logo S⁺ intactos.
- Vista lateral/tres cuartos apta para correr y vista de celebración coherente.
- Piezas de cabeza, rostro, torso, brazos, manos, piernas, cola y branquias;
  completar las zonas ocultas para que no aparezcan huecos al mover articulaciones.
- Reutilizar o adaptar el fantasma vectorial existente, sin exigir una nueva mascota.
- Definir puntos de agarre para las dos manos y orden de capas: el fantasma no
  atraviesa brazos/cabeza, no cambia de tamaño al agarrarlo ni flota fuera del agarre.
- Mantener el logo como recurso estable; no regenerarlo en cada pose ni reflejarlo
  al invertir la dirección del personaje.

## Secuencia propuesta

| Momento | Movimiento | Condición |
| --- | --- | --- |
| Preparado | Respiración y parpadeo suaves. | Pantalla visible y partida lista. |
| Carrera | Ciclo continuo de piernas/brazos, cola y branquias acompañan. | Partida activa; progreso ligado a puntos reales. |
| Alcance | Sabi desacelera y acerca ambas manos. | Resultado final válido de nuevo récord. |
| Captura | Ambas manos sujetan al fantasma en puntos estables. | Continuación de la misma celebración. |
| Alzar | Levanta al fantasma por encima de la cabeza. | Sin cortes ni cambio de modelo. |
| Celebrar | Pequeños saltos y expresión alegre sosteniéndolo. | Secuencia breve, omisible y una sola vez por resultado. |
| Escape | El fantasma se aleja; Sabi se detiene y recupera el ánimo. | Récord conservado, no un error de red. |

Tiempos exactos, cámara y poses finales se ajustan con un prototipo visible, no se
dan por aprobados todavía. No ocultar preguntas ni retrasar su lectura o respuesta.

## Integración con el código existente

Archivos inspeccionados:

- `lib/features/games/ghost_duel/presentation/ghost_race_panel.dart`: muestra la
  carrera en dos carriles, escala compartida y diferencia de puntos; el marcador
  del jugador es actualmente un icono, no Sabi.
- `lib/features/games/ghost_duel/presentation/ghost_character.dart`: fantasma actual.
- `lib/features/games/ghost_duel/domain/ghost_duel_models.dart`: checkpoints,
  comparación de récords y `GhostDuelOutcome`.
- `lib/features/games/trivia_rush/presentation/trivia_rush_page.dart`: integra el
  panel de carrera. Inspeccionar el cierre y guardado antes de conectar animaciones.

Conservar `firstRecord`, `newRecord` y `keptRecord`. Una ventaja momentánea sobre
un checkpoint no prueba que se haya superado el récord final. No deducir la captura
solo de `currentScore > ghostScore` durante la partida. Conservar los desempates y
las reglas de intentos asistidos actuales; no inventar XP ni escribir récords desde
la animación. Si falla la confirmación, mostrar estado pendiente/error, no derrota.
La primera partida forma el récord y no representa atrapar uno previo inexistente.

## Entregas pequeñas

1. **G-SABI-1A — Esta guía:** alcance, storyboard, límites y puntos de integración.
2. **G-SABI-1B — Personaje articulado y muestra de carrera:** preparar arte maestro,
   elegir Rive o Flutter vectorial y revisar consistencia en una muestra aislada.
3. **G-SABI-1C — Captura, elevación y escape:** construir y revisar las transiciones.
4. **G-SABI-1D — Integración y pruebas:** conectar al resultado real y verificar
   accesibilidad, rendimiento, ciclo de vida y reglas existentes.

G-SABI-1B–1D están pendientes. Esta guía no representa el cierre de Duelo fantasma,
P5, D3 ni de la integración de juegos en producción.

## Criterios de aceptación futura

- Misma cara, manos, branquias, proporciones y logo durante todo el movimiento.
- Carrera sin salto visual al repetir el ciclo; contacto de manos convincente.
- No reproducir la victoria al reconstruir el widget o reintentar el guardado.
- Con reducción de movimiento, pose estática y resultado textual equivalente.
- Pausar fuera de ruta o con app en segundo plano; liberar controladores al salir.
- Texto ampliado, pantalla pequeña y contraste legibles sin tapar preguntas.
- Probar primer récord, empate/desempates, intento asistido, victoria, récord
  conservado, errores de red y salida/reentrada, sin cambiar puntuación ni historial.

## Fuentes consultadas para elegir herramienta

- Rive: editor, huesos/mallas y runtimes: https://rive.app/features
- Runway: imagen a video y guía de movimiento:
  https://help.runwayml.com/hc/en-us/articles/48324313115155-Image-to-Video-Prompting-Guide

Estas herramientas son opciones, no servicios contratados ni conectados al proyecto.
