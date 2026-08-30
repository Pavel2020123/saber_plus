# Perfil académico central

La pantalla `Más > Mi perfil` reúne los indicadores académicos que ya pertenecen al estudiante. No mantiene una copia adicional ni calcula datos autoritativos en Flutter.

## Fuentes actuales

- La identidad y el XP provienen de la sesión autenticada.
- El avance de contenido y el porcentaje de aciertos provienen del panel de progreso.
- La racha y los logros provienen del servicio de gamificación.
- El tiempo estudiado proviene del registro local por estudiante, que suma Pomodoros y evaluaciones confirmadas.

Cada fuente tiene un estado independiente. Si una consulta falla, la pantalla conserva los indicadores disponibles y permite actualizar mediante el botón o el gesto de arrastrar hacia abajo.

## Límites de esta entrega

El perfil funciona como punto central y enlaza a las pantallas detalladas existentes. El objetivo personal, el resumen semanal, los comparativos, la proyección de puntaje y la orientación académica se incorporan en las siguientes partes de la etapa 6E y requerirán contratos propios cuando los datos deban sincronizarse entre dispositivos.
