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

### Estados visuales de la racha

- `actual > 0` y `activoHoy = true`: la llama está activa, crece al entrar y mantiene un movimiento suave.
- `actual > 0` y `activoHoy = false`: la llama se muestra congelada y sin movimiento; el estudiante todavía debe realizar una actividad hoy.
- `actual = 0`: la llama se muestra apagada y sin movimiento.

El color activo cambia por hitos: naranja de 1 a 9 días, dorado de 10 a 19, rojo de 20 a 29, violeta de 30 a 39, azul de 40 a 49 y cian legendario desde 50 días.

La pérdida real sigue siendo responsabilidad del backend. Para aplicar el día de gracia acordado, el servidor debe conservar `actual > 0` durante el día congelado y devolver `actual = 0` al superar el siguiente límite del día académico sin actividad. Flutter representa esos estados, pero no adelanta fechas ni concede días.

Las cuentas demostrativas muestran controles para sumar diez días y alternar entre activa, congelada y perdida. Esos controles solo modifican la vista previa en memoria y nunca aparecen en una cuenta real ni llaman a la API.

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
