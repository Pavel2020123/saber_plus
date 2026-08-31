# Duelo fantasma

El duelo fantasma es un modo individual construido sobre Trivia Rush. No conecta estudiantes entre sí ni muestra datos de otras personas: el rival es la evolución temporal del mejor resultado anterior del mismo estudiante.

## Reglas implementadas

- Cada récord se separa por estudiante, conjunto de áreas y duración de 60, 90 o 120 segundos.
- La primera partida crea el fantasma y las siguientes muestran si el puntaje actual va delante, detrás o empatado en cada instante.
- El récord se decide por puntaje; en empate se comparan aciertos y mejor combo.
- Los potenciadores están desactivados y una partida asistida es rechazada por el repositorio.
- El récord actual se guarda localmente y no se utiliza en rankings públicos.
- Los datos dañados, de otra cuenta o de otra configuración se descartan de forma segura.

La implementación local permite probar todo el flujo sin inventar endpoints. Para sincronizar entre dispositivos o usar el resultado fuera del teléfono, el backend debe recalcular y firmar el intento.

## Audio opcional pendiente

Además de los sonidos generales de Trivia Rush, pueden agregarse:

- `ghost_overtake.mp3`: el estudiante toma la delantera, entre 0,3 y 0,7 segundos;
- `ghost_lost_lead.mp3`: el fantasma toma la delantera, tono suave y no alarmante;
- `ghost_victory.mp3`: nuevo récord, entre 1 y 2 segundos;
- `ghost_defeat.mp3`: cierre sin récord, entre 1 y 2 segundos.

Los cambios de ventaja deben tener un enfriamiento para no reproducir sonidos repetidamente. El estudiante podrá desactivar el audio de juegos desde Preferencias.
