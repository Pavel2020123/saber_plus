# JN-2 — Rescate de estrellas

Actualizado: 19 de septiembre de 2026.

## Estado: JN-2A demo local implementada

Disponible en **Practicar → Juegos individuales → Rescate de estrellas**, solo
para estudiantes de demostración. No hay backend, persistencia en disco ni
integración de producción para este juego. No se tocó Render/Supabase.

Sabi es el protagonista previsto; en esta entrega solo se nombran su misión y
las constelaciones, representadas con indicadores estáticos y etiquetas accesibles.
No se generaron personajes, animaciones ni sonidos nuevos. El arte queda al final.

## Reglas iniciales ajustables

El usuario aprobó liberar una estrella por acierto y reconstruir constelaciones
en grupos. Los siguientes números y la consecuencia del error son **hipótesis
para probar la demo**, no requisitos definitivos aprobados ni reglas de servidor:

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
con la API de práctica. Las cuentas reales ven un aviso, nunca una demo encubierta.

## Organización y límites

- `StarRescueProgress`: reglas puras, sin dependencia de Flutter ni calificación remota.
- `StarRescueRepository`: contrato para partida, respuesta y abandono.
- `DemoStarRescueRepository`: copia en memoria, validación de pregunta/opción/intento,
  claves de envío y exclusión de operaciones simultáneas.
- El mismo envío no cuenta dos estrellas. Una clave con otra opción y una pregunta
  consumida con otra clave se rechazan. Los fallos de envío no quitan estrellas.
- La pantalla conserva la opción y clave pendientes para reintentar dentro de la vista.
  No hay cola persistente ni promesa de entrega tras cerrar la app en esta etapa.
- El proveedor usa identidad/rol/modo, no XP, para conservar o descartar el repositorio.
  Al cambiar de cuenta, los resultados asíncronos del repositorio anterior se descartan.
- Pantalla desplazable, diseño claro/oscuro, texto ampliado y estados descritos con
  etiquetas e iconos; la información no depende solo del color.

## Verificación

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

1. **JN-2B — Backend:** fijar reglas versionadas, preguntas publicadas por área/tema/
   subtema/dificultad sin relleno demo, intentos privados y copias del contenido,
   calificación del servidor, recuperación, caducidad, abandono e idempotencia.
   Probar permisos/concurrencia con PostgreSQL temporal, sin desplegar por defecto.
2. **JN-2C — Flutter remoto:** API, almacenamiento seguro del envío pendiente,
   filtros, imágenes/casos completos, recuperación y estados de conexión.
3. **Ensayo real:** despliegue autorizado, contenido suficiente y revisión en
   Android/iOS. Infraestructura P5/D3 continúa pausada.
4. **Arte y animaciones al final:** Sabi, burbujas, liberación, conexión de estrellas
   y celebraciones; decidir audios antes de solicitar nuevas descargas.

Después continúan JN-3 Inventos, JN-4 Escudo, MA-1 cobertura del banco,
MA-2 mapa de aprendizaje y MA-3 repaso diferido. Esta demo no cierra esas tareas.
