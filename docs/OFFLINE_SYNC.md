# Sincronización segura sin conexión

Alcance implementado en la Etapa 5E para Android y iOS.

## Lista permitida

La cola local acepta exclusivamente operaciones que el backend procesa mediante `upsert` y que se pueden repetir sin crear intentos ni recompensas:

- Progreso de una lección: `POST /simulacros/progreso`.
- Nota y estado de una pregunta del cuaderno: `PATCH /cuaderno-errores/:preguntaId`.

Las respuestas, calificaciones, creación o consumo de intentos, XP, pagos, certificados y operaciones administrativas nunca se aplazan. Estas acciones continúan necesitando conexión y una respuesta confirmada del backend.

## Persistencia y envío

Drift guarda la cola por usuario. Cada combinación de usuario, tipo y entidad tiene una sola operación pendiente:

- Cambios repetidos de una lección se agrupan conservando el porcentaje mayor.
- Cambios repetidos de una pregunta conservan la nota y el estado de la edición local más reciente.

La app intenta sincronizar inmediatamente, al entrar a la experiencia del estudiante, al volver del segundo plano y cuando el usuario pulsa **Más > Sincronización > Sincronizar ahora**.

## Resolución de conflictos

- **Progreso:** antes de enviar, Flutter consulta el progreso remoto y conserva el mayor porcentaje entre el servidor y la cola. Un dato local atrasado no reduce el avance remoto.
- **Cuaderno:** el backend actual no publica una versión editable ni admite una precondición de actualización. Por eso la última edición local pendiente reemplaza nota y estado al sincronizar.
- **Problema temporal:** falta de red, tiempo de espera, `408`, `429`, errores `5xx` y sesión temporalmente no autorizada conservan la operación como pendiente.
- **Rechazo permanente:** validaciones y otros errores `4xx` marcan la operación para revisión. El estudiante puede reintentarla o descartarla con confirmación.

La pantalla de sincronización muestra solo la cola de la cuenta activa. Cerrar sesión no mezcla operaciones entre estudiantes.

## Migración local

El esquema Drift pasa de la versión 1 a la 2 creando la tabla de operaciones pendientes. Los PDF y sus metadatos guardados en la etapa anterior se conservan durante la actualización.

## Límite del contrato actual

Para detectar y combinar ediciones concurrentes del cuaderno entre dos dispositivos sin una regla de “última edición local”, el backend deberá exponer `fechaActualizacion` o una versión y aceptar actualizaciones condicionales. Flutter no inventa ese contrato.
