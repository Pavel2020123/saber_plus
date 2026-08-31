# Contrato backend de Trivia Rush

La etapa 6G-A implementa el motor autoritativo en NestJS y PostgreSQL; la etapa 6G-B conecta el cliente Flutter. Todas las rutas requieren JWT, correo verificado y una cuenta de estudiante. Flutter anima el estado recibido, pero no calcula puntuación, combo, vencimiento ni respuestas correctas.

## Rutas

### Crear o recuperar un intento

`POST /trivia-rush/intentos`

```json
{
  "areas": ["MATEMATICAS", "LECTURA_CRITICA"],
  "duracionSegundos": 90
}
```

Solo se aceptan duraciones de 60, 90 o 120 segundos. Repetir la misma configuración recupera el intento vigente; intentar cambiarla mientras existe otro intento activo devuelve conflicto.

`GET /trivia-rush/intentos/activo` devuelve el intento recuperable o `null`.

`GET /trivia-rush/intentos/:id` sincroniza el estado y procesa un vencimiento antes de responder.

### Responder

`POST /trivia-rush/intentos/:id/respuestas`

```json
{
  "preguntaId": "pregunta-1",
  "respuestaId": "respuesta-b",
  "idempotencyKey": "550e8400-e29b-41d4-a716-446655440000"
}
```

La clave UUID identifica exactamente una operación. Repetir la misma solicitud devuelve el mismo resultado; reutilizarla con otro intento, pregunta o respuesta se rechaza. El tiempo de respuesta se obtiene entre `preguntaIniciaEn` y la recepción en el servidor, no desde un valor enviado por el teléfono.

Una evaluación final puede incluir `respuestaCorrectaId` y `explicacion`. El primer error protegido por `SEGUNDA_OPORTUNIDAD` devuelve `puedeReintentar: true` sin revelar ninguno de esos campos.

### Potenciadores

`POST /trivia-rush/intentos/:id/potenciadores`

```json
{
  "preguntaId": "pregunta-1",
  "potenciador": "TIEMPO_EXTRA",
  "concesionId": "4fa85f64-5717-4562-b3fc-2c963f66afa6",
  "idempotencyKey": "67e55044-10b1-426f-9247-bb680e5fe0c8"
}
```

| Flutter | Backend |
| --- | --- |
| `extraTime` | `TIEMPO_EXTRA` |
| `fiftyFifty` | `CINCUENTA_CINCUENTA` |
| `comboShield` | `ESCUDO_COMBO` |
| `skip` | `SALTAR` |
| `secondChance` | `SEGUNDA_OPORTUNIDAD` |

Cada activación consume una `ConcesionRecompensaJuego` disponible, vigente y perteneciente al usuario. Una concesión solo puede consumirse una vez. No existe una ruta móvil para fabricarla: una etapa comercial posterior la emitirá después de validar AdMob Server-Side Verification o el derecho aplicable.

No hay límite artificial de potenciadores: cien recompensas válidas pueden producir cien consumos. Sí se rechazan estados inútiles o duplicados, como activar dos escudos simultáneos o usar dos veces `CINCUENTA_CINCUENTA` sobre la misma pregunta.

### Cierre

- `POST /trivia-rush/intentos/:id/finalizar`: confirma un cierre decidido por el servidor; no permite terminar anticipadamente.
- `POST /trivia-rush/intentos/:id/abandonar`: abandona voluntariamente la ronda.

## Estado público

Cada respuesta contiene `servidorAhora` y un objeto `intento` con configuración, fechas, tiempo restante, marcador, progreso, potenciadores activos y solo la pregunta actual. La pregunta pública contiene identificadores, enunciado, contexto, imagen, dificultad, área, tema, subtema y opciones ordenadas.

Nunca contiene `esCorrecta`, la explicación ni la clave antes de responder. Al expirar, la revisión revela exclusivamente las preguntas que fueron respondidas o saltadas; no entrega las soluciones del resto del banco.

## Persistencia y reglas

La migración `20260831183000_add_trivia_rush_autoritativo` crea intentos, preguntas asignadas, envíos de respuesta, concesiones y consumos de potenciadores. Las transacciones usan bloqueos por intento para proteger el orden y los contadores ante solicitudes simultáneas.

Las reglas versión 1 conservan el puntaje actual: 100 puntos base y multiplicadores `x1`, `x2`, `x3` y `x4` desde combos 1, 3, 6 y 10. Cualquier potenciador marca la ronda como asistida. El diagnóstico final agrupa errores por tema y subtema.

El récord fantasma autoritativo no forma parte de este contrato; se construirá en una etapa separada usando únicamente intentos finalizados y no asistidos.
