# Perfil académico central

La pantalla `Más > Mi perfil` reúne los indicadores académicos que ya pertenecen al estudiante. No mantiene una copia adicional ni calcula datos autoritativos en Flutter.

## Fuentes actuales

- La identidad y el XP provienen de la sesión autenticada.
- El avance de contenido y el porcentaje de aciertos provienen del panel de progreso.
- La racha y los logros provienen del servicio de gamificación.
- El tiempo estudiado proviene del registro local por estudiante, que suma Pomodoros y evaluaciones confirmadas.
- La fortaleza y el área prioritaria usan primero el resultado explícito del diagnóstico. Si ese resultado aún no incluye ambas áreas, se derivan de los porcentajes confirmados por materia.

Cada fuente tiene un estado independiente. Si una consulta falla, la pantalla conserva los indicadores disponibles y permite actualizar mediante el botón o el gesto de arrastrar hacia abajo.

## Objetivo personal

El estudiante puede definir y modificar un objetivo entre 100 y 500 puntos, en incrementos de 10. La interfaz lo presenta como una meta elegida por la persona y nunca como una predicción. Por ahora se guarda localmente con una clave separada por usuario; su sincronización entre dispositivos queda pendiente de un contrato del backend.

## Orientación académica

El perfil funciona como punto central y enlaza a la orientación de carreras y universidades. Esa orientación utiliza afinidades entre las áreas estudiadas y familias amplias de formación; no reemplaza una prueba vocacional ni promete admisión. La oferta de programas e instituciones se consulta en las fuentes oficiales del SNIES, sin guardar datos que puedan quedar desactualizados dentro de la aplicación.

Las próximas partes de la etapa 6E incorporarán becas y comparación con datos nacionales mediante fuentes oficiales y contratos actualizables.
