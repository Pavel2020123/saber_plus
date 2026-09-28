# Flashcards académicas

Alcance implementado en la Etapa 6C-E para Android y iOS.

## Fuente de las tarjetas

Las tarjetas se generan localmente a partir de `assets/data/reference_library.json`:

- cada fórmula pregunta por su relación o expresión y muestra uso, variables y alertas;
- cada término del glosario muestra definición, ejemplo y conceptos relacionados.

La versión actual contiene 130 tarjetas: 80 de fórmulas y 50 de glosario. No se copia el banco protegido de preguntas ni se incluyen respuestas de simulacros.

## Sesiones

El estudiante puede filtrar por tipo, área ICFES y cantidad de 5 a 30 tarjetas. En cada tarjeta intenta recordar la respuesta, la revela y elige entre `Repasar` y `Ya la sé`.

La práctica libre prioriza tarjetas no recordadas en autoevaluación y las menos
estudiadas. El campo histórico `mastered` es una autodeclaración, no dominio acreditado.

## Persistencia

Drift guarda por estudiante y tarjeta:

- estado autodeclarado de recuerdo (campo histórico de práctica libre);
- cantidad total de repasos y aciertos;
- fecha del último repaso.

La práctica libre permanece disponible sin conexión y separada por cuenta. Sus
contadores históricos siguen locales. **MA-3A/B/C añade una agenda separada** con
API, cola durable y sincronización, sin importar esos contadores como retención.
Pendientes/próximos se abren desde Flashcards; cuenta real requerida, demo sin
agenda remota. Ver [REPASO_DIFERIDO.md](REPASO_DIFERIDO.md). Falta ensayo real.

## Accesibilidad

La respuesta puede mostrarse tocando la tarjeta o usando un botón explícito. La transición visual se elimina cuando el sistema solicita reducción de movimiento.
