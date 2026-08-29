# Flashcards académicas

Alcance implementado en la Etapa 6C-E para Android y iOS.

## Fuente de las tarjetas

Las tarjetas se generan localmente a partir de `assets/data/reference_library.json`:

- cada fórmula pregunta por su relación o expresión y muestra uso, variables y alertas;
- cada término del glosario muestra definición, ejemplo y conceptos relacionados.

La versión actual contiene 130 tarjetas: 80 de fórmulas y 50 de glosario. No se copia el banco protegido de preguntas ni se incluyen respuestas de simulacros.

## Sesiones

El estudiante puede filtrar por tipo, área ICFES y cantidad de 5 a 30 tarjetas. En cada tarjeta intenta recordar la respuesta, la revela y elige entre `Repasar` y `Ya la sé`.

Las sesiones priorizan primero las tarjetas no dominadas y, entre ellas, las menos estudiadas. Las tarjetas dominadas siguen disponibles para repasos posteriores.

## Persistencia

Drift guarda por estudiante y tarjeta:

- estado actual de dominio;
- cantidad total de repasos y aciertos;
- fecha del último repaso.

El avance permanece disponible sin conexión y separado entre las cuentas que usan el mismo dispositivo. La sincronización entre dispositivos requerirá un contrato futuro del backend; Flutter no inventa ese endpoint.

## Accesibilidad

La respuesta puede mostrarse tocando la tarjeta o usando un botón explícito. La transición visual se elimina cuando el sistema solicita reducción de movimiento.

