# JN-1 — Salto a la cima

## Estado: JN-1A funcional en demostración local

Entrega sin animaciones nuevas. No es todavía una integración de producción:
falta contrato/API, persistencia y validación real. No se utiliza la API de práctica
para simular partidas reales ni se conceden XP, logros, racha o evidencia diagnóstica.

## Reglas iniciales de prueba

El usuario confirmó subir al acertar y bajar **un escalón** al fallar, sin mostrar
explicaciones durante la partida. Para probar esa mecánica se adoptan parámetros
ajustables, todavía pendientes de evaluación de dificultad con el usuario:

- Comienzo en la base (0), meta en el escalón 5.
- Acierto: +1. Error: -1, con mínimo 0; nunca altura negativa.
- Hasta 12 preguntas. Llegar a 5 termina inmediatamente con victoria.
- Si se agotan las preguntas, se muestra el resultado sin inventar una victoria.
- Sin cronómetro, potenciadores, anuncios ni recompensas en esta entrega.
- Tras responder se muestra solamente el movimiento y el botón de continuar.
- Resumen de aciertos, errores, escalón final y punto más alto; no declara falencias.

## Cómo probar

Entrar como **estudiante de demostración** y abrir:
**Practicar → Juegos individuales → Salto a la cima**.

Seleccionar un área, iniciar, elegir una opción y confirmar. Acertar permite subir;
fallar en un escalón superior baja uno; fallar en la base consume una pregunta pero
mantiene el cero. La interfaz usa indicadores estáticos hasta la etapa final de arte.

Se reutiliza `DemoPracticeRepository`: sus ejemplos pueden repetirse, y se avisa
en pantalla. No son un banco real de doce preguntas distintas. No se envían sus
resultados ni su XP simulado a la sesión, al historial o al backend.

La partida queda en memoria al salir y regresar. Se pierde al cerrar la app o cambiar
de cuenta. Una partida activa no se reinicia cambiando el área; hay que terminarla.
Las cuentas reales ven un aviso de disponibilidad, no un juego demo encubierto.

## Separación y seguridad

- Dominio `SummitProgress`: reglas puras, límites y cierre de la partida.
- Contrato `SummitRepository`: separar demo de la futura implementación remota.
- Repositorio demo con validación de intento, pregunta y opción, exclusión de envíos
  concurrentes e identificador de respuesta estable para reintentos.
- Proveedor restringido a estudiante demo; cambio de identidad descarta repositorio
  y estado visual. Cambiar solamente el XP de la misma cuenta no reinicia la partida.
- Botones bloqueados durante envíos; fallos no causan descenso ni cambian selección
  pendiente. No se recalifica automáticamente al reconstruir la pantalla.

## Siguientes entregas de este juego

- **JN-1B — Backend:** intentos privados, selección publicada por área/tema/subtema,
  preguntas suficientes sin repetir, snapshots sin revelar respuestas futuras,
  calificación autoritativa, idempotencia, recuperación/cierre y pruebas de aislamiento.
- **JN-1C — Flutter remoto:** conectar el contrato, persistencia/recuperación,
  estados de red, imágenes y casos completos, preguntas filtradas y prueba real cuando
  se autorice retomar infraestructura. No habilitar producción con fallback demo.
- **Arte y animaciones al final:** Sabi/plataformas/caída/victoria, sin rehacer reglas
  ni determinar aciertos a partir de animaciones.

La persistencia demo en disco, recompensas y una revisión final detallada no están
incluidas ni deben darse por hechas. Los parámetros de prueba se revisarán antes
de fijar una versión de reglas en servidor.

## Verificación

Entrega local verificada: `flutter analyze` sin avisos y **59 pruebas aprobadas**
en Salto a la cima (13 nuevas), Guardián, navegación de la app y Duelo fantasma.
No se ejecutó la suite completa ni se generó un APK nuevo.

```powershell
flutter analyze
flutter test test/summit_game_test.dart
flutter test test/summit_game_test.dart test/guardian_test.dart test/widget_test.dart test/ghost_duel_test.dart
```

Pruebas de reglas, límite/piso/victoria, duplicados/concurrencia, cuentas, reintentos,
feedback sin explicación y pantalla pequeña/texto ampliado. La validación en
teléfono sigue siendo parte de la revisión del usuario; no se tocó Render/Supabase.
