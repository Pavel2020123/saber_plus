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

## Certificados de logros

`GET /gamificacion/logros/:logroId/certificado`

- El servidor vuelve a comprobar que el logro pertenezca al estudiante y esté desbloqueado.
- Flutter acepta el archivo únicamente si contiene la firma de un PDF y no supera 20 MB.
- El nombre recibido se sanitiza y nunca se utiliza para construir rutas del dispositivo.
- Los archivos se guardan en el almacenamiento privado de la app, separados por usuario.
- Una descarga existente se reutiliza y se puede abrir nuevamente sin descargarla.
- Los logros bloqueados no muestran ninguna acción de certificado.
- El modo demostrativo no genera certificados personales falsos; la descarga requiere una cuenta real.

El certificado especial por completar el 100% de una materia requiere un nuevo contrato del backend y permanece pendiente dentro de las mejoras académicas posteriores.
