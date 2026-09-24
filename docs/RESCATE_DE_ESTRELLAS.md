# JN-2 — Rescate de estrellas

Actualizado: 24 de septiembre de 2026.

## Estado: JN-2A/B/C implementadas localmente; pendiente ensayo real

JN-2B añade API `/rescate-estrellas`, reglas versión 1 (6 estrellas, grupos de 3,
10 preguntas), snapshots privados, calificación autoritativa, filtros, recuperación,
caducidad de 24 horas, abandono y reintentos sin duplicar estrellas. Una partida
activa por estudiante y juego, protegida con transacciones, índice parcial y RLS.
No concede XP ni altera evidencia académica. Contrato completo en el repositorio
oficial `SaberPlus-Backend/backend/STAR_RESCUE.md`.

La migración nueva solo se prueba en PostgreSQL desechable; no está en Supabase.
JN-2C incorpora el cliente remoto Flutter. Falta migración/despliegue y ensayo real
autorizado; no se conectó a Supabase/Render en esta entrega.

### JN-2C — Cliente remoto y recuperación segura

- Cuentas demo conservan el repositorio en memoria. Estudiantes reales usan
  `/rescate-estrellas`; profesores/sin sesión no acceden. No hay fallback demo.
- Al entrar, comprobar partida activa; si no existe, recuperar el último intento
  guardado para mostrar también un final cuya confirmación se perdió.
- Persistencia segura por URL de API y usuario: ID de intento y envío pendiente
  (pregunta, opción, UUID). Nunca guarda el banco, soluciones ni califica offline.
- Guardar antes de enviar; un fallo de almacenamiento impide el POST. Si se pierde
  la confirmación, sincronizar o reenviar exactamente la misma opción/UUID, sin
  permitir cambiarla a mitad del reintento. No se duplica una estrella.
- Filtros reales: área, tema, subtema y dificultad. Muestra contexto e imágenes
  con estados de carga/error y reintento; no carga direcciones ejecutables.
- Estado y contadores proceden del servidor y se validan: victoria, agotado,
  abandono y vencimiento. Un fallo de red nunca se convierte en respuesta incorrecta.
- Cambio de cuenta descarta el repositorio anterior; su registro local queda
  aislado para recuperar únicamente con la cuenta y servidor correspondientes.
- Botón «Recuperar / sincronizar partida» y abandono confirmado. Sin cambios de
  arte, sonidos, XP, diagnóstico ni animaciones.

Prueba manual pendiente: cuenta real contra API actualizada con al menos diez
preguntas publicadas válidas para los filtros. Abrir, responder, desconectar,
reabrir y sincronizar; confirmar mismo avance, abandono y vencimiento. Si no está
desplegada la API, se muestra un error y no se sustituye por ejemplos locales.

### Estado del cliente Flutter (JN-2A)

Disponible en **Practicar → Juegos individuales → Rescate de estrellas**.
La modalidad demo es solo para estudiantes de demostración: permanece en memoria
y no envía resultados reales. Las cuentas reales usan JN-2C, descrita arriba.

Sabi es el protagonista previsto; en esta entrega solo se nombran su misión y
las constelaciones, representadas con indicadores estáticos y etiquetas accesibles.
No se generaron personajes, animaciones ni sonidos nuevos. El arte queda al final.

## Reglas iniciales ajustables

El usuario aprobó liberar una estrella por acierto y reconstruir constelaciones
en grupos. Los siguientes números y la consecuencia del error son **hipótesis
para probar la demo**, ahora fijadas en la versión 1 del servidor JN-2B;
su equilibrio seguirá revisándose antes de publicación:

- Se comienza sin estrellas.
- Cada acierto libera una; cada grupo de 3 completa una constelación.
- Objetivo: 6 estrellas, equivalentes a 2 constelaciones.
- Máximo 10 preguntas; un error consume una pregunta, sin quitar estrellas.
- La sexta estrella termina inmediatamente con victoria, incluso en la pregunta 10.
- Si se agotan las preguntas, se muestra el rescate parcial, sin inventar victoria.
- No hay cronómetro, vidas, potenciadores, anuncios, premios ni XP.
- El resultado no modifica diagnóstico, rachas, logros ni historial académico.

## Flujo de prueba

1. Entrar como estudiante demo y abrir el juego desde Practicar.
2. Elegir un área y comenzar el rescate.
3. Elegir una opción, confirmar y observar la estrella liberada o el error.
4. Pulsar Siguiente pregunta; al completar 3 aciertos aparece una constelación completa.
5. Al ganar/agotar preguntas se muestra el resumen y se puede preparar otro rescate.
6. Salir y volver conserva la partida en memoria. Cerrar la app o cambiar de cuenta
   la descarta. El botón Abandonar pide confirmación y permite comenzar otra partida.

Los ejemplos provienen exclusivamente de `DemoPracticeRepository` y pueden repetirse
en contenido. Se advierte expresamente en pantalla: no es un banco real ni se conecta
con la API de práctica. Las cuentas reales usan el repositorio remoto, nunca una demo encubierta.

## Organización y límites

- `StarRescueProgress`: reglas puras, sin dependencia de Flutter ni calificación remota.
- `StarRescueRepository`: contrato para partida, respuesta y abandono.
- `DemoStarRescueRepository`: copia en memoria, validación de pregunta/opción/intento,
  claves de envío y exclusión de operaciones simultáneas.
- El mismo envío no cuenta dos estrellas. Una clave con otra opción y una pregunta
  consumida con otra clave se rechazan. Los fallos de envío no quitan estrellas.
- En demo la pantalla conserva la opción y clave para reintentar dentro de la vista.
  JN-2C añade persistencia segura del envío remoto, sin envío automático en segundo plano.
- El proveedor usa identidad/rol/modo, no XP, para conservar o descartar el repositorio.
  Al cambiar de cuenta, los resultados asíncronos del repositorio anterior se descartan.
- Pantalla desplazable, diseño claro/oscuro, texto ampliado y estados descritos con
  etiquetas e iconos; la información no depende solo del color.

## Verificación

JN-2C: `flutter analyze` sin avisos y **106 pruebas seleccionadas aprobadas**:
demo/remoto de Rescate, navegación general y regresión de Cima. Incluyen 23 pruebas
nuevas de repositorio remoto/UI: confirmación perdida, persistencia antes de POST,
aislamiento, vencimiento, contrato inválido, API ausente, filtros, imágenes y
pantalla pequeña con texto ampliado. No sustituye el ensayo real ni una ejecución
de toda la suite. Comando:

```powershell
flutter test test/star_rescue_test.dart test/remote_star_rescue_repository_test.dart test/star_rescue_remote_page_test.dart test/widget_test.dart test/remote_summit_repository_test.dart test/summit_remote_page_test.dart test/summit_game_test.dart
```

JN-2B (23 de septiembre): build del backend correcto, ESLint del módulo sin
avisos, 811 pruebas Jest/80 suites y 20 pruebas con PostgreSQL temporal aprobadas.
Incluyen RLS, concurrencia, reintentos, snapshots, filtros, rescate parcial y
recuperación desde otra instancia. No se cambió código Flutter ni se hizo ensayo
en teléfonos para esta entrega; la comprobación JN-2A siguiente es histórica.

`flutter analyze` sin avisos y **83 pruebas seleccionadas aprobadas** el 19 de
septiembre: incluye **18 nuevas** (17 del juego y una de navegación), junto con
la regresión de Salto a la cima y las pantallas existentes.

Pruebas de reglas, victoria/límite, idempotencia, concurrencia, abandono, cambio de
cuenta, reintento tras confirmación perdida, regreso a la pantalla y tamaño reducido.
También se incluye acceso desde la navegación real de la app en `widget_test.dart`.

```powershell
flutter analyze
flutter test test/star_rescue_test.dart test/widget_test.dart test/summit_game_test.dart test/remote_summit_repository_test.dart test/summit_remote_page_test.dart
```

Las pruebas de widgets no sustituyen la revisión del usuario en teléfono. No se ha
generado un APK ni ejecutado toda la suite del proyecto para esta entrega.

## Próximas entregas

1. **JN-2B — Backend:** implementación local preparada con reglas versionadas,
   preguntas publicadas, snapshots privados, recuperación, caducidad y abandono.
   Pruebas de permisos/concurrencia en PostgreSQL temporal, sin despliegue real.
2. **JN-2C — Flutter remoto:** implementado localmente con API, almacenamiento
   seguro del envío pendiente, filtros, imágenes/casos y recuperación.
3. **Ensayo real:** despliegue autorizado, contenido suficiente y revisión en
   Android/iOS. Infraestructura P5/D3 continúa pausada.
4. **Arte y animaciones al final:** Sabi, burbujas, liberación, conexión de estrellas
   y celebraciones; decidir audios antes de solicitar nuevas descargas.

Después continúan JN-4 Escudo, MA-1 cobertura del banco,
MA-2 mapa de aprendizaje y MA-3 repaso diferido. Esta demo no cierra esas tareas.
