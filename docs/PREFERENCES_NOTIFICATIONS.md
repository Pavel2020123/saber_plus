# Preferencias y notificaciones locales

Esta etapa incorpora preferencias persistentes del dispositivo y un recordatorio diario opcional para Android/iOS.

## Apariencia

- La app inicia en tema claro para usuarios nuevos.
- El estudiante puede elegir entre tema claro y oscuro desde `Más > Preferencias`.
- La elección se guarda localmente con `SharedPreferencesAsync` y se restaura al abrir la app.
- No se almacena información sensible en estas preferencias.

## Recordatorio diario

- Está desactivado por defecto.
- El permiso del sistema se solicita únicamente cuando el estudiante lo activa.
- Si el permiso se rechaza, la preferencia permanece desactivada.
- El estudiante elige la hora; el recordatorio se programa en la zona horaria del dispositivo.
- En Android se usa una alarma diaria inexacta. No se solicitan permisos de alarma exacta.
- Al desactivarlo se cancela la notificación programada.
- Android restaura la programación después de reiniciar el dispositivo o actualizar la app.

## Alcance actual

El backend auditado no ofrece un módulo de notificaciones para estudiantes. Por eso esta entrega no inventa endpoints ni registra tokens push. Anuncios remotos, mensajes institucionales y notificaciones enviadas por servidor quedan pendientes de un contrato backend futuro.

## Publicación

Antes de publicar se deben comprobar el texto de permisos y el comportamiento en dispositivos Android/iOS reales. Las notificaciones son una función opcional y no se solicitan durante el primer arranque.
