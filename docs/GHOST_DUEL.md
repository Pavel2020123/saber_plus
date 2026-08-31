# Duelo fantasma

El duelo fantasma es un modo individual construido sobre Trivia Rush. No conecta estudiantes entre sí ni muestra datos de otras personas: el rival es la evolución temporal del mejor resultado anterior del mismo estudiante.

## Reglas implementadas

- Cada récord se separa por estudiante, conjunto de áreas y duración de 60, 90 o 120 segundos.
- La primera partida crea el fantasma y las siguientes muestran si el puntaje actual va delante, detrás o empatado en cada instante.
- El récord se decide por puntaje; en empate se comparan aciertos y mejor combo.
- Los potenciadores están desactivados y una partida asistida es rechazada por el repositorio.
- En demostración el récord se guarda localmente; una cuenta real consulta el mejor intento confirmado por el backend.
- El servidor reconstruye los checkpoints desde las respuestas finales y sus marcas de tiempo, sin aceptar puntajes enviados por el teléfono.
- Solo compiten intentos finalizados o expirados, sin potenciadores, con la misma versión de reglas, áreas y duración.
- El récord queda sincronizado entre dispositivos y no se utiliza en rankings públicos.
- Los datos dañados, de otra cuenta o de otra configuración se descartan de forma segura.

La ruta autenticada `GET /trivia-rush/fantasma` devuelve el mejor intento limpio del propio estudiante. Al cerrar un duelo, Flutter vuelve a consultarla para distinguir entre primer récord, nuevo récord o récord conservado. El cliente nunca publica checkpoints ni solicita reemplazar directamente el récord.

## Audio opcional pendiente

Además de los sonidos generales de Trivia Rush, pueden agregarse:

- `ghost_overtake.mp3`: el estudiante toma la delantera, entre 0,3 y 0,7 segundos;
- `ghost_lost_lead.mp3`: el fantasma toma la delantera, tono suave y no alarmante;
- `ghost_victory.mp3`: nuevo récord, entre 1 y 2 segundos;
- `ghost_defeat.mp3`: cierre sin récord, entre 1 y 2 segundos.

Los cambios de ventaja deben tener un enfriamiento para no reproducir sonidos repetidamente. El estudiante podrá desactivar el audio de juegos desde Preferencias.
