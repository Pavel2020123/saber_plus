# Simulacro de 150 preguntas AM/PM

La Etapa 6D-A incorpora un formato completo dividido en dos jornadas independientes:

- jornada AM de 75 preguntas;
- jornada PM de 75 preguntas;
- presencia de Lectura Crítica, Matemáticas, Ciencias Naturales, Sociales y Ciudadanas e Inglés;
- total esperado de 150 preguntas;
- intento, temporizador, respuestas y borrador cifrado separados para cada jornada.

## Flujo móvil

El estudiante entra por `Practicar > Simulacro 150 · AM/PM` y elige la jornada. Cada bloque reutiliza las protecciones existentes:

- las respuestas correctas y explicaciones no llegan antes de calificar;
- todas las preguntas deben responderse antes del envío;
- el intento puede reanudarse desde el mismo dispositivo mientras siga vigente;
- el envío se bloquea mientras se califica y no se repite automáticamente si su resultado queda incierto;
- el tiempo confirmado se suma al registro personal de estudio.

Los borradores usan identificadores diferentes (`official:am` y `official:pm`), por lo que una jornada nunca sobrescribe la otra.

## Contrato utilizado actualmente

Mientras el backend publica un contrato específico para este formato, Flutter reutiliza el intento personalizado protegido:

```text
GET /simulacros/generar-personalizado
  ?areas=LECTURA_CRITICA,MATEMATICAS,CIENCIAS_NATURALES,SOCIALES_CIUDADANAS,INGLES
  &cantidad=75

POST /simulacros/calificar-personalizado
```

La app valida que la respuesta contenga exactamente 75 preguntas y las cinco áreas. Si el banco no puede cumplir ambas condiciones, muestra un error y no presenta el intento como una jornada completa.

El endpoint actual vence los intentos en dos horas; Flutter conserva su margen de seguridad de cinco minutos. Si el formato definitivo necesita otra duración o una distribución fija por área, el backend deberá incluirlas en un contrato versionado y continuar siendo la fuente de verdad.

## Contenido y derechos

Este modo utiliza el banco académico autorizado de SaberPlus. No descarga, copia ni se presenta como un cuadernillo oficial del ICFES. El banco de pruebas de años anteriores se implementará por separado únicamente con contenido propio, autorizado o legalmente reutilizable.

## Modo demostración

La demostración genera 75 identificadores únicos por jornada, reparte preguntas entre las cinco áreas y permite validar todo el recorrido sin servidor. Estos datos no se mezclan con una cuenta real ni se publican como contenido académico definitivo.
