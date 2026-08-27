# Contrato académico móvil

Contrato auditado contra el backend NestJS de `Pavel2020123/Icfes_Vida` para la Etapa 3.

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

El diagnóstico inicial actual clasifica falencias por **área**, no por tema o subtema individual. La identificación fina se construye con el historial de respuestas, el cuaderno de errores, el progreso y el repaso adaptativo, que sí prioriza áreas y subtemas débiles. Por ejemplo, recomendar “regla de tres” requiere que las preguntas estén asociadas a ese subtema y que los errores lleguen al historial/adaptativo.
