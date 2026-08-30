# Contrato móvil de práctica y preguntas aleatorias

Este documento registra el contrato auditado contra el backend NestJS de `Icfes_Vida` para las Etapas 4A y 4B. Flutter consume la API existente; no replica la calificación ni contiene respuestas correctas antes de finalizar.

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

## Preguntas aleatorias

`GET /simulacros/generar-personalizado`

Parámetros:

- `areas`: uno o varios valores ICFES separados por coma.
- `cantidad`: entre 1 y 100; la app ofrece 5, 10 o 20.
- `dificultad`: opcional; `BASICO`, `MEDIO` o `AVANZADO`.

El backend crea un intento con origen `PERSONALIZADO`. Puede entregar más preguntas que la cantidad solicitada cuando necesita conservar completo un caso compartido.

`POST /simulacros/calificar-personalizado`

```json
{
  "intentoId": "uuid",
  "respuestas": [
    {
      "preguntaId": "uuid",
      "respuestaId": "uuid",
      "tiempoRespuestaSegundos": 18
    }
  ]
}
```

No se envía un área única porque el backend calcula el desglose según las preguntas del intento. La respuesta reutiliza el resumen y detalle de revisión de la práctica por subtema.

## Borrador local y reanudación

Como la API no permite consultar un intento abierto, Flutter guarda en almacenamiento cifrado del dispositivo:

- el `intentoId` y las preguntas públicas recibidas;
- las opciones seleccionadas;
- el tiempo acumulado por pregunta y la posición actual;
- el inicio y vencimiento local del intento.

El borrador se separa por usuario y modalidad. Se actualiza al responder, cambiar de pregunta y periódicamente. La app usa un margen de seguridad y considera vencido el intento después de 115 minutos, cinco minutos antes del límite del backend.

Las respuestas correctas y explicaciones protegidas no forman parte del borrador. Al calificar correctamente, vencer o descartar un intento, la copia local se elimina.

## Protección frente a envíos duplicados

La app bloquea el botón mientras califica y exige confirmación antes de cerrar el intento. El endpoint actual consume el intento pero no es idempotente y tampoco permite consultar un resultado mediante `intentoId`.

Si la conexión se pierde durante la calificación, Flutter deja el envío como “por confirmar”, elimina su borrador reanudable y no lo repite automáticamente. Para recuperar ese resultado se requiere que el backend acepte una clave idempotente o exponga una consulta de resultado por intento.

## Alcance de la Etapa 4A

- Práctica real iniciada desde una lección.
- Navegación entre preguntas y obligación de responderlas todas.
- Registro de tiempo por pregunta y temporizador visible.
- Calificación protegida con origen `PRACTICA`.
- Resultado, XP, respuesta seleccionada, respuesta correcta y explicación.
- Modo demostrativo local para revisar el flujo sin servidor.

## Alcance de la Etapa 4B

- Sesión aleatoria configurable por áreas, cantidad y dificultad.
- Calificación mixta mediante el endpoint personalizado.
- Guardado automático cifrado para práctica por subtema y aleatoria.
- Reanudación de respuestas, posición, duración y tiempos por pregunta.
- Vencimiento, descarte manual y sustitución confirmada de intentos.

## Alcance de la Etapa 4C

### Simulacro completo por área

`GET /simulacros/generar?area=MATEMATICAS`

- Genera normalmente 25 preguntas de una sola área.
- Crea un intento protegido con origen `SIMULACRO` y vencimiento de dos horas.
- Conserva juntas las preguntas que pertenecen al mismo caso.
- No entrega respuestas correctas ni explicaciones antes de calificar.

La calificación usa `POST /simulacros/calificar` con el área elegida, todas las respuestas y `origen: SIMULACRO`. Flutter reutiliza el temporizador, borrador cifrado, reanudación, protección de envío y revisión de las etapas anteriores.

### Historial

`GET /simulacros/historial`

- Devuelve hasta los 20 resultados más recientes.
- Cada resultado contiene área, total, respuestas correctas, porcentaje, XP y fecha.

`GET /simulacros/historial-respuestas`

- Acepta filtros opcionales `area`, `resultado=correctas|incorrectas` y `limite` de 1 a 100.
- Devuelve el resumen global del filtro y cada respuesta con origen, tiempo, tema, subtema, opción seleccionada, opción correcta y explicación.

El historial es de solo lectura. La aplicación no reconstruye ni modifica resultados calculados por el backend.

El contrato propuesto para el banco autorizado por año, sus evidencias de derechos y las jornadas protegidas se documenta por separado en `HISTORICAL_SIMULATIONS.md`.

### Repaso de errores del día

Flutter consulta el historial con `resultado=incorrectas&limite=100`, filtra por la fecha local actual y conserva el fallo más reciente de cada pregunta. La revisión usa únicamente respuestas ya calificadas y no reconstruye preguntas protegidas ni crea nuevos resultados. El progreso visual de lectura pertenece a la sesión de pantalla y el refuerzo posterior se genera mediante el flujo de repaso adaptativo.
