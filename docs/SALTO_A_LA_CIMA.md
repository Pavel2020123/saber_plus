# JN-1 — Salto a la cima

## Estado: JN-1A demo y JN-1B backend local verificado

Entrega sin animaciones nuevas. JN-1B implementa contrato/API, persistencia de
intentos y calificación del servidor en el repositorio SaberPlus-Backend.
La migración no se aplicó a Supabase y Flutter aún no consume esa API (JN-1C).
No es todavía una integración de producción. No se utiliza la API de práctica
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

## JN-1B — Backend completado localmente

- API `/salto-cima/intentos`: iniciar, recuperar activa/por ID, responder y abandonar.
- Reglas versión 1: cinco escalones y doce preguntas, sin XP ni historial académico.
- Doce preguntas publicadas distintas por ID, filtros de área/tema/subtema/dificultad
  y copia privada para que editar el banco no cambie una partida iniciada.
- Solo estudiantes verificados y sus propias partidas. No expone soluciones ni
  preguntas futuras. Incluye contexto e imágenes de la pregunta y del caso.
- Una activa por cuenta, transacciones, respuestas idempotentes y cierre a las 24 h.
- Migración preparada con RLS; permisos directos revocados para roles públicos.
- Ocho pruebas Jest nuevas y 16 pruebas con PostgreSQL temporal aprobadas.
  Suite completa del backend: 77 suites / 790 pruebas aprobadas durante la entrega.
  Compilación verificada; no se conectó a bases reales ni se desplegó.

Contrato y comandos: `SaberPlus-Backend/backend/SUMMIT_CHALLENGE.md`.
La demo puede repetir ejemplos; el servidor **no** rellena un banco insuficiente.
En el backend se conservaron cambios anteriores sin commit de Guardián y privacidad
institucional; hay archivos compartidos y deben separarse al preparar commits.

## Siguientes entregas de este juego

- **JN-1C — Flutter remoto:** conectar el contrato, persistencia/recuperación,
  estados de red, imágenes y casos completos, preguntas filtradas y prueba real cuando
  se autorice retomar infraestructura. No habilitar producción con fallback demo.
- **Arte y animaciones al final:** Sabi/plataformas/caída/victoria, sin rehacer reglas
  ni determinar aciertos a partir de animaciones.

La persistencia demo en disco, recompensas y una revisión final detallada no están
incluidas ni deben darse por hechas. El servidor fija esos parámetros como versión 1;
su dificultad se revisará antes de publicar. Cambiar reglas requerirá versionarlas.

## Verificación

Verificación de JN-1A (entrega anterior): `flutter analyze` sin avisos y **59 pruebas aprobadas**
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
