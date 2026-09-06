# Contrato académico móvil

Contrato original auditado contra `Pavel2020123/Icfes_Vida` en la Etapa 3.
El backend oficial actual es `Pavel2020123/SaberPlus-Backend`.

## Inicio académico

El backend todavía no ofrece un endpoint único de bootstrap. Flutter combina en paralelo:

- `GET /calendario-icfes/activo`: convocatoria pública activa o `calendario: null`.
- `GET /diagnostico-inicial`: estado del diagnóstico del estudiante autenticado.
- `GET /plan-estudio/semanal`: estado o plan generado para la semana.

La pantalla de inicio muestra datos del servidor: fecha y calendario ICFES, XP del perfil, siguiente actividad, progreso semanal y resumen del diagnóstico. El modo demostrativo conserva un conjunto aislado de datos locales.

## Diagnóstico inicial

Estados devueltos por `GET /diagnostico-inicial`:

- `NO_INICIADO`.
- `EN_PROGRESO`: incluye `diagnosticoId`, fecha, total y las 15 preguntas reservadas.
- `COMPLETADO`: incluye porcentaje global, nivel, resultados por área, área prioritaria y fortaleza.

`POST /diagnostico-inicial/iniciar` crea una sesión con tres preguntas de cada una de las cinco áreas. Es idempotente para el estudiante: si ya existe, devuelve el estado actual.

Flutter conserva localmente, en almacenamiento cifrado, las opciones elegidas, el tiempo acumulado por pregunta y la posición actual. El borrador se elimina solamente después de que el servidor confirma la finalización.

`POST /diagnostico-inicial/finalizar` recibe exactamente las 15 parejas `preguntaId`/`respuestaId` con su tiempo opcional. La app hace un único envío, mantiene ocultas las respuestas correctas durante la sesión y conserva el resultado aun si la consulta complementaria del cuaderno falla.

Los niveles se calculan en servidor: menos de 50 es `POR_REFORZAR`, entre 50 y 69.9 es `EN_PROCESO`, y desde 70 es `FORTALEZA`.

## Plan semanal

`GET /plan-estudio/semanal` puede devolver:

- `DIAGNOSTICO_PENDIENTE`.
- `FECHA_PENDIENTE`.
- `CONVOCATORIA_FINALIZADA`.
- `SIN_CONTENIDO`.
- `TODO_COMPLETADO`.
- `LISTO`, con resumen y actividades ordenadas por día.

Flutter no recalcula prioridades ni resultados: el backend continúa siendo la autoridad.

## Alcance de recomendaciones

El diagnóstico inicial clasifica el resultado principal por **área**. Al finalizar, cada respuesta incorrecta entra al historial con origen `DIAGNOSTICO`; Flutter consulta `GET /cuaderno-errores` y agrupa esos registros por tema y subtema. Así puede mostrar una recomendación concreta como “Regla de tres — Razones y proporciones — Matemáticas” cuando la pregunta está etiquetada con ese subtema.

Desde **7F-C2-B2**, esa lista se presenta como “Errores para revisar”, no como
falencias confirmadas. El nuevo `GET /diagnostico-evidencia` y la pantalla
“Diagnóstico por temas” requieren evidencia acumulada antes de clasificar un
tema/subtema. El resultado inicial por área sigue siendo una muestra orientativa;
no se cambió retroactivamente su contrato ni la calificación guardada.
Reglas y límites: [LEARNING_EVIDENCE.md](LEARNING_EVIDENCE.md).
