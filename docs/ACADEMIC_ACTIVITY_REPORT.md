# Resumen semanal y comparativo mensual

La etapa 6E-C agrega `Más > Mi perfil > Resumen semanal y mensual`. La pantalla organiza actividad fechada ya disponible y no inventa una calificación ni una proyección del examen.

## Semana actual

La semana se calcula de lunes a domingo en la hora local del dispositivo. Presenta:

- tiempo confirmado de estudio;
- cantidad de sesiones registradas;
- días con al menos una sesión o acción académica;
- acciones académicas agregadas por el backend;
- avance frente a los minutos semanales del plan, cuando el plan publica una meta.

El gráfico diario representa solamente el tiempo registrado. Las acciones se informan como una métrica separada para evitar sumar eventos con minutos.

## Comparación mensual

El comparativo usa meses calendario: desde el primer día del mes actual contra el mes calendario inmediatamente anterior. Compara tiempo, sesiones y días activos registrados localmente. Si el estudiante todavía no tiene datos del mes anterior, la interfaz lo informa en vez de calcular un porcentaje engañoso.

## Disponibilidad y sincronización

El tiempo estudiado procede del historial local del dispositivo. Las acciones académicas de la semana proceden del resumen de gamificación confirmado por el servidor. El contrato actual entrega esa actividad reciente, por lo que no se usa para atribuir acciones a meses anteriores. Si la consulta remota falla, el resumen conserva el tiempo y las sesiones locales, y marca las acciones semanales como no disponibles.

Hasta que el backend publique sincronización de tiempo, el comparativo de minutos puede variar entre dispositivos. Los datos demostrativos continúan aislados y no se envían a producción.
