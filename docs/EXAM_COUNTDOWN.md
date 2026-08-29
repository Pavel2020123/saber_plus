# Contador global del examen

Alcance implementado en la Etapa 6C-F para Android y iOS.

## Fuente de verdad

El contador utiliza la convocatoria activa recibida por `GET /calendario/activo`. Flutter no escribe fechas ICFES dentro del código ni calcula cuál calendario corresponde al estudiante.

Cuando el backend no entrega una convocatoria, la franja no aparece. Si entrega una fecha vencida como activa, la app solicita actualizarla en lugar de mostrar una cantidad negativa.

## Comportamiento

- La franja aparece sobre la navegación principal del estudiante y durante el diagnóstico.
- Muestra días completos de calendario, año, calendario A/B y fecha del examen.
- Cambia automáticamente a `ICFES mañana` y `ICFES hoy` cuando corresponde.
- Programa su siguiente actualización para el inicio del día siguiente.
- El estudiante puede minimizarla y volver a expandirla sin ocultarla completamente.
- Inicia minimizada para no quitar espacio a las herramientas de estudio.
- La preferencia minimizada se conserva localmente con `SharedPreferencesAsync`.

El contador no genera notificaciones ni sustituye la consulta de la citación oficial del estudiante.
