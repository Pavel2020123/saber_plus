# Contrato móvil de gamificación

La Etapa 6A consume la gamificación calculada por el backend NestJS. Flutter no concede XP, no decide cuándo se desbloquea un logro y no calcula la racha a partir de datos locales.

## Resumen protegido

`GET /gamificacion/resumen`

Requiere el access token del estudiante y devuelve:

- `racha.actual`, `racha.mejor`, `racha.activoHoy` y `racha.ultimaActividad`;
- `actividad`, con fecha y cantidad de acciones académicas por día;
- `resumen`, con logros desbloqueados, total de logros y preguntas respondidas;
- `logros`, con identificador, categoría, meta, progreso, porcentaje y estado de desbloqueo.

El backend considera como actividad las respuestas, los simulacros y el progreso de temas. El día académico y la continuidad de la racha se calculan en `America/Bogota`.

## XP

El XP total procede de `GET /auth/perfil`. Después de una calificación, la app actualiza el perfil para mostrar el valor confirmado por el servidor. En modo demostrativo se usa un valor local aislado que nunca se envía a producción.

## Experiencia móvil

- La tarjeta de XP del inicio abre `Logros y actividad`.
- La pantalla muestra racha actual, mejor racha, XP, actividad de los últimos siete días y progreso de los logros.
- El contenido puede actualizarse con gesto de recarga o con el botón del encabezado.
- Los errores de red no se sustituyen por datos falsos cuando existe una sesión real.

## Siguiente subetapa

El backend ya expone `GET /gamificacion/logros/:logroId/certificado` y valida que el logro esté desbloqueado. La descarga y apertura segura de esos PDF se implementará en la Etapa 6B junto con la experiencia completa de certificados.
