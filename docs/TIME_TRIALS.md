# Pruebas contrarreloj

La etapa 6D-D agrega retos de velocidad sin copiar respuestas correctas ni reglas de calificación dentro de Flutter.

## Experiencia móvil

- Formatos de 5 preguntas en 5 minutos, 10 en 10 y 20 en 20.
- Selección de una o varias áreas y dificultad opcional.
- Cuenta regresiva visible que cambia de color al acercarse a cero.
- Un único borrador cifrado por estudiante, con respuestas, tiempos y vencimiento absoluto.
- Reanudación con el tiempo restante real: cerrar o minimizar la app no reinicia el reloj.
- Envío automático al llegar a cero cuando todas las preguntas están respondidas.
- Bloqueo del intento vencido cuando faltan respuestas, sin seleccionar opciones en nombre del estudiante.

El modo demostrativo utiliza el banco académico local. Una cuenta real reutiliza temporalmente los endpoints personalizados existentes:

- `GET /simulacros/generar-personalizado`
- `POST /simulacros/calificar-personalizado`

Las respuestas correctas y explicaciones solo llegan después de una calificación confirmada.

## Limitación conocida del backend actual

El endpoint personalizado exige responder exactamente todas las preguntas asignadas. Por eso Flutter no puede enviar un intento incompleto al agotarse el tiempo: hacerlo requeriría inventar una `respuestaId`, lo que dañaría el historial académico.

Para cerrar esta limitación, el backend deberá ofrecer un contrato contrarreloj autoritativo. Propuesta:

### Iniciar

`POST /simulacros/contrarreloj/iniciar`

```json
{
  "areas": ["MATEMATICAS", "INGLES"],
  "cantidad": 10,
  "dificultad": "MEDIO",
  "duracionSegundos": 600
}
```

La respuesta debe incluir `intentoId`, `iniciadoEn`, `venceEn` y las preguntas públicas. El servidor debe conservar el vencimiento como fuente de verdad.

### Calificar

`POST /simulacros/contrarreloj/calificar`

```json
{
  "intentoId": "uuid",
  "respuestas": [
    {
      "preguntaId": "uuid",
      "respuestaId": "uuid",
      "tiempoRespuestaSegundos": 42
    }
  ]
}
```

Este endpoint debe aceptar respuestas parciales después del vencimiento, marcar las omitidas como `SIN_RESPUESTA`, ser idempotente y devolverlas separadas de las respuestas incorrectas en el resumen. También debe rechazar respuestas recibidas después de `venceEn` y permitir consultar el resultado mediante `intentoId` si la conexión se pierde.

Hasta que ese contrato exista, los retos completos sí se califican mediante la API actual y los incompletos terminan localmente con un mensaje explícito.
