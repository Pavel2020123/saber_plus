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

## Certificados de áreas y curso (integración local, 22 de septiembre)

El catálogo protegido `GET /gamificacion/certificados` devuelve cinco áreas
(`LECTURA_CRITICA`, `MATEMATICAS`, `CIENCIAS_NATURALES`,
`SOCIALES_CIUDADANAS`, `INGLES`) y `CURSO_COMPLETO`. Cada entrada indica
`id`, `titulo`, `completadas`, `total`, `disponible` y `unidad`.

La evidencia por área son **todos los subtemas publicados** bajo temas publicados,
con `ProgresoTema` del estudiante autenticado, `completado=true` y
`porcentaje>=100`. Un área vacía permanece cerrada. El curso requiere las cinco
áreas disponibles. La API recalcula al consultar y al descargar; no conserva
un derecho histórico cuando se agrega una nueva lección publicada.

`GET /gamificacion/certificados/:tipo/pdf` vuelve a validar la disponibilidad,
lee el nombre íntegro desde `Usuario.nombre` y renderiza el HTML de
`backend/src/gamificacion/templates/certificado.html` en PDF A4 horizontal.
Responde 404 para tipos distintos de los seis y 403 si está pendiente. La
respuesta PDF es privada y sin caché HTTP. El diseño incluye el logo y Sabi, con
una aclaración de que no es un diploma oficial del ICFES. La generación depende
de Chrome instalado en el backend; Render todavía no se ha verificado.

Flutter muestra seis tarjetas en `Logros y actividad`, valida la firma/tamaño del
PDF y guarda el archivo en almacenamiento privado separado por cuenta y por tipo.
Reconsulta el servidor al descargar para incorporar cambios de nombre/progreso.
La cuenta demostrativa no emite documentos personales. Los logros continúan como
insignias sin botones de certificado.

La ruta heredada `GET /gamificacion/logros/:logroId/certificado` devuelve 410
para señalar el retiro del PDF por logro. Los archivos antiguos que el alumno
descargó localmente no se eliminan. El nuevo flujo requiere despliegue y prueba
integrada antes de marcarlo listo para producción.
