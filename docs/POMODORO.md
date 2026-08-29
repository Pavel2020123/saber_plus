# Pomodoro de enfoque

Las lecciones y las prácticas por subtema, aleatorias o adaptativas incluyen un temporizador opcional de 25 minutos. El estudiante puede iniciarlo, pausarlo, continuarlo y reiniciarlo sin afectar el intento académico.

## Comportamiento

- El estado se comparte al pasar de una lección a una práctica durante la misma sesión de la aplicación.
- El tiempo restante se calcula mediante una hora límite real. Si el sistema suspende temporalmente los ciclos de Flutter, el reloj se corrige al reanudarse.
- Al llegar a cero, el bloque queda marcado visualmente como completado.
- Cerrar sesión reinicia el temporizador para no compartirlo entre cuentas.

Los simulacros no muestran el Pomodoro porque su tiempo pertenece a la evaluación. Sus reglas de duración se implementan por separado en la etapa de simulacros avanzados.

## Límites de esta entrega

El temporizador no se restaura después de cerrar completamente la aplicación. Un bloque que llega realmente a cero suma 25 minutos al tiempo total estudiado; pausar, reiniciar o abandonar un bloque incompleto no agrega minutos.

El Pomodoro no reproduce sonido ni vibración al finalizar. La Etapa 6C-G limita el feedback háptico a las rachas de respuestas correctas; ampliar ese comportamiento al temporizador requiere una decisión independiente.
