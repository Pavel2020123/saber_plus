# JN-1 — Salto a la cima

## Estado: JN-1A demo, JN-1B backend y JN-1C cliente remoto implementados localmente

Entrega sin animaciones nuevas. JN-1B implementa contrato/API, persistencia de
intentos y calificación del servidor en el repositorio SaberPlus-Backend.
La migración no se aplicó a Supabase. JN-1C añade el cliente Flutter para esa API;
falta desplegar y hacer la prueba completa en teléfono contra staging autorizado.
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
de cuenta. Una partida activa no se reinicia cambiando el área; hay que terminarla
o abandonarla. Las cuentas reales usan exclusivamente la API; si no está disponible,
se muestra un error y recuperación, nunca una partida demo encubierta.

## Separación y seguridad

- Dominio `SummitProgress`: reglas puras, límites y cierre de la partida.
- Contrato `SummitRepository`: separar demo de la implementación remota.
- Repositorio demo con validación de intento, pregunta y opción, exclusión de envíos
  concurrentes e identificador de respuesta estable para reintentos.
- Proveedor restringido a estudiantes; cambio de identidad descarta repositorio
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
El usuario guardó Guardián, Cima y privacidad institucional en el commit conjunto
`b826967`. JN-1C no modifica el backend ni ejecuta migraciones.

## JN-1C — Flutter remoto

- Selección explícita de repositorio demo o remoto según la cuenta; docentes y
  sesiones cerradas no pueden abrir el juego. Cambios de XP no reinician el repositorio.
- Al entrar se recupera la partida activa del servidor; también se puede consultar
  la última guardada para confirmar un resultado final cuyo envío perdió conexión.
- Filtros de área, tema, subtema y dificultad. Tema/subtema vienen del catálogo;
  si no carga, se permite jugar por área sin inventar temas ni preguntas.
- Enunciado, opciones, contexto del caso e imágenes con aviso y reintento de carga.
- Antes de responder se guarda el UUID, intento, pregunta y opción en almacenamiento
  seguro por cuenta y URL de API. No se guarda el banco, soluciones ni credenciales.
- Un fallo de almacenamiento impide enviar. Un fallo de red conserva la opción y
  UUID; al reabrir se consulta el servidor sin reenviar automáticamente. Si ya se
  aceptó, se recupera el avance; si no, se ofrece reintentar exactamente el mismo envío.
- No hay calificación local ni cola de nuevas respuestas sin conexión.
- Recuperar/sincronizar disponible; abandono con confirmación y resultados distintos
  para victoria, preguntas agotadas, abandono y caducidad. Sincronizar no suma XP.
- Se rechazan versiones/reglas desconocidas y respuestas inconsistentes; una cuenta
  que cambió no puede continuar enviando desde su repositorio anterior.

La persistencia nativa cifrada y la presentación de imágenes reales aún requieren
ensayo en Android/iOS. Las pruebas locales usan almacenamiento y HTTP simulados;
no equivalen a conectar la app con Render/Supabase ni a una revisión visual en celular.

### Ensayo real cuando se retome infraestructura

1. Confirmar versión desplegada, migración aplicada y estudiante con correo verificado.
2. Publicar al menos 12 preguntas válidas para el filtro elegido, incluyendo imágenes/caso.
3. Entrar con cuenta real (DEMO_MODE=false), jugar y salir/regresar.
4. Cortar conexión al enviar, cerrar/reabrir la app, recuperar y comprobar que no duplica.
5. Verificar abandono, vencimiento, cuenta diferente, imágenes y banco insuficiente.
6. No marcar publicación completa hasta ese ensayo; P5 y D3 siguen pausadas.

## Siguientes entregas de este juego

- **Ensayo real de JN-1:** despliegue, migración y prueba en dispositivo cuando
  se autorice retomar infraestructura. El código cliente no cierra esta validación.
- **JN-2A — Rescate de estrellas:** reglas y demo local ya implementadas.
  Sigue JN-2B backend; ver [RESCATE_DE_ESTRELLAS.md](RESCATE_DE_ESTRELLAS.md).
- **Arte y animaciones al final:** Sabi/plataformas/caída/victoria, sin rehacer reglas
  ni determinar aciertos a partir de animaciones.

La persistencia demo en disco, recompensas y una revisión final detallada no están
incluidas ni deben darse por hechas. El servidor fija esos parámetros como versión 1;
su dificultad se revisará antes de publicar. Cambiar reglas requerirá versionarlas.

## Verificación

JN-1C: 19 pruebas nuevas (14 de contrato/repositorio y 5 de pantalla), más
regresión dirigida de demo, Guardián, Duelo fantasma y navegación. Se corrigió
el toque del test de Trivia Rush para centrar la tarjeta por encima de la barra
inferior; la repetición de las tres suites remotas/navegación pasó sus 52 pruebas.
Análisis Flutter sin avisos. No se ejecutó toda la suite del proyecto ni se generó APK.

```powershell
flutter analyze
flutter test test/summit_game_test.dart test/remote_summit_repository_test.dart test/summit_remote_page_test.dart test/guardian_test.dart test/widget_test.dart test/ghost_duel_test.dart
```

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
