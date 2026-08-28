# Contrato móvil de práctica por subtema

Este documento registra el contrato auditado contra el backend NestJS de `Icfes_Vida` para la Etapa 4A. Flutter consume la API existente; no replica la calificación ni contiene respuestas correctas antes de finalizar.

## Abrir un intento

`GET /simulacros/preguntas/:subtemaId`

- Requiere JWT, correo verificado y plan vigente.
- Crea un `intentoId` asociado al usuario, al área y al origen `PRACTICA`.
- El intento expira en dos horas.
- Entrega hasta cinco preguntas, salvo que deba conservar completo un grupo perteneciente al mismo caso.
- Cada pregunta incluye enunciado, imagen opcional, dificultad, caso opcional, opciones públicas y ubicación académica.
- No entrega `esCorrecta`, respuesta correcta ni explicación protegida.

Cada apertura crea un intento nuevo. Actualmente el backend no ofrece un endpoint para recuperar las preguntas de un intento abierto.

## Calificar

`POST /simulacros/calificar`

```json
{
  "intentoId": "uuid",
  "area": "MATEMATICAS",
  "origen": "PRACTICA",
  "respuestas": [
    {
      "preguntaId": "uuid",
      "respuestaId": "uuid",
      "tiempoRespuestaSegundos": 18
    }
  ]
}
```

El backend valida que:

- el intento pertenezca al usuario y coincida con área y origen;
- no esté vencido ni consumido;
- no existan preguntas repetidas;
- se respondan exactamente todas las preguntas asignadas;
- cada opción pertenezca a su pregunta.

La respuesta contiene totales, porcentaje, XP y el detalle de revisión. Solo en ese detalle aparecen la respuesta correcta, el estado de cada opción y las explicaciones.

Después de una calificación exitosa, Flutter actualiza el progreso del subtema con `POST /simulacros/progreso`. Esta actualización es secundaria: si falla, el resultado válido se conserva y nunca se vuelve a calificar por ese motivo.

## Protección frente a envíos duplicados

La app bloquea el botón mientras califica y exige confirmación antes de cerrar el intento. El endpoint actual consume el intento pero no es idempotente y tampoco permite consultar un resultado mediante `intentoId`.

Si la conexión se pierde durante la calificación, Flutter deja el envío como “por confirmar” y no lo repite automáticamente. Para soportar recuperación segura en una siguiente parte se requiere que el backend acepte una clave idempotente o exponga una consulta de resultado por intento.

## Alcance de la Etapa 4A

- Práctica real iniciada desde una lección.
- Navegación entre preguntas y obligación de responderlas todas.
- Registro de tiempo por pregunta y temporizador visible.
- Calificación protegida con origen `PRACTICA`.
- Resultado, XP, respuesta seleccionada, respuesta correcta y explicación.
- Modo demostrativo local para revisar el flujo sin servidor.

La sesión aleatoria, el simulacro completo, la persistencia/reanudación y la recuperación idempotente quedan para las siguientes partes de la Etapa 4.
