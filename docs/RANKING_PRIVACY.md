# Ranking con privacidad por defecto

La etapa 6G-D ofrece un ranking motivacional sin convertir los resultados académicos en información pública. Está disponible desde `Más > Ranking` para estudiantes demostrativos y cuentas reales.

## Información visible

Cada entrada contiene exclusivamente:

- posición;
- alias seudónimo;
- XP del período.

La cuenta activa se identifica como `Tú`. No se entregan a Flutter UUID de otras cuentas, nombres, apellidos, correos, institución, grado, puntajes de simulacro, diagnósticos, materias débiles ni cantidad de evaluaciones.

Los alias tienen el formato `Estudiante Cóndor 184527`. El backend los deriva mediante HMAC usando el identificador interno, el alcance y un secreto estable. Las seis cifras reducen colisiones al crecer la comunidad. Esto permite ordenar de forma consistente sin publicar el identificador original y evita relacionar directamente el alias global con el institucional.

En producción debe configurarse `RANKING_ALIAS_SECRET` con un secreto largo y estable. Si no existe, el backend utiliza `JWT_SECRET`; el valor de desarrollo es solo un respaldo para pruebas locales.

## Alcances y períodos

- `GLOBAL`: estudiantes de SaberPlus, siempre con alias.
- `INSTITUCION`: únicamente cuando la cuenta pertenece a una institución y también con alias. La respuesta dice `Mi institución`, no publica su nombre.
- `SEMANA` y `MES`: XP confirmado recientemente en simulacros y batallas.
- `TOTAL`: XP total confirmado de la cuenta.

Los empates de XP comparten posición. Los participantes sin XP en el período no aparecen. La posición propia se devuelve aunque esté fuera del límite visible de 50 entradas.

## Defensa en Flutter

Flutter valida `privacidad.identidadesProtegidas: true` y acepta solo los campos `posicion`, `alias`, `xp` y `esUsuarioActual` por entrada. Si el backend enviara accidentalmente un identificador u otro dato, la aplicación rechaza la respuesta completa en vez de mostrarla.

La pantalla incluye filtros por alcance y período, actualización manual, gesto de recarga, posición personal y una explicación visible de privacidad. No se incluyen perfiles públicos ni navegación hacia otra cuenta.
