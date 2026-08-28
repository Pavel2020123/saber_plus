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

El repaso adaptativo que propone una nueva sesión a partir del perfil del estudiante se implementará en la Etapa 5B.
