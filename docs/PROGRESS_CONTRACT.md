# Contrato móvil de progreso y cuaderno de errores

Este documento registra el contrato auditado contra el backend NestJS de `Icfes_Vida` para la Etapa 5A. El servidor continúa siendo la fuente de verdad; Flutter presenta los cálculos existentes y no recalifica respuestas.

## Panel de progreso

El resumen combina endpoints protegidos que ya existen:

- `GET /simulacros/progreso`: avance general, subtemas vistos y completados.
- `GET /simulacros/historial-respuestas?limite=1`: total histórico de respuestas, correctas, incorrectas y porcentaje de acierto.
- La misma consulta con `area`: rendimiento histórico independiente para cada una de las cinco áreas ICFES.
- Los XP se leen de la sesión autenticada devuelta por el perfil.

El límite de una respuesta reduce el contenido transferido porque el panel solo necesita el resumen calculado por el backend.

## Cuaderno de errores

`GET /cuaderno-errores`

- Requiere JWT, correo verificado y plan vigente.
- Acepta `area` y `estado` como filtros opcionales.
- Los estados son `PENDIENTE`, `REPASANDO` y `DOMINADO`.
- Agrupa por pregunta todas las respuestas incorrectas del estudiante.
- Entrega cantidad de fallos, último error, tema, subtema, respuesta elegida, respuesta correcta, explicación, nota y estado.

`PATCH /cuaderno-errores/:preguntaId`

```json
{
  "nota": "Revisar el orden de la proporción.",
  "estado": "REPASANDO"
}
```

La nota admite hasta 1600 caracteres. Solo pueden modificarse preguntas que realmente pertenezcan al cuaderno del estudiante. Si una pregunta marcada como dominada vuelve a fallarse, el backend la presenta nuevamente como `REPASANDO`.

## Alcance de la Etapa 5A

- Resumen de XP, avance de lecciones, respuestas y acierto global.
- Rendimiento por cada área ICFES.
- Resumen y filtros del cuaderno por área y estado.
- Revisión de la respuesta seleccionada, la correcta y la explicación.
- Notas personales y flujo pendiente/en repaso/dominado persistidos en la API.

## Etapa 5E: escritura aplazada segura

El progreso de lecciones y las ediciones del cuaderno pueden guardarse primero en Drift cuando la API no está disponible. Las políticas de agrupación, sincronización y conflictos están documentadas en [OFFLINE_SYNC.md](OFFLINE_SYNC.md).

El backend sigue siendo la fuente de verdad. Los intentos, resultados y XP no forman parte de esta cola.

## Etapa 5B: repaso adaptativo

`GET /repaso-adaptativo/perfil`

- Analiza hasta las 300 respuestas más recientes del estudiante.
- Entrega precisión reciente, nivel objetivo, rendimiento por área, tres áreas prioritarias y mezcla recomendada de dificultad.
- Con menos de ocho respuestas utiliza nivel medio; después ajusta el nivel entre básico, medio y avanzado.

`POST /repaso-adaptativo/generar?cantidad=15`

- Acepta entre 5 y 30 preguntas.
- Prioriza áreas, subtemas y preguntas con menor rendimiento.
- Evita repetir de inmediato preguntas respondidas correctamente.
- Mantiene unidos los grupos de preguntas que pertenecen a un mismo caso.
- Crea un intento protegido de dos horas con origen `ADAPTATIVO`.
- No entrega respuestas correctas ni explicaciones antes de calificar.

`POST /repaso-adaptativo/calificar`

Reutiliza el formato de respuestas temporizadas de las prácticas. El backend valida y consume el intento, calcula resultado, XP y revisión, y devuelve `perfilSiguiente` ya recalculado.

Flutter reutiliza el temporizador, el borrador local cifrado, la reanudación y la protección contra envíos duplicados de las sesiones de práctica.

### Alcance completado de la Etapa 5B

- Perfil adaptativo explicado al estudiante.
- Áreas prioritarias y mezcla recomendada de dificultad.
- Elección de cantidad y generación del intento real.
- Sesión completa, calificación, XP y revisión de respuestas.
- Actualización del perfil después de finalizar.
