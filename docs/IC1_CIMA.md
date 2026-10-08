# IC-1A — Cliente competitivo de Salto a la cima

## Estado — 8 de octubre de 2026

IC-1A e IC-1A2 validadas en el ensayo local Android/API/PostgreSQL del 8 de
octubre: partida competitiva real, liquidación única y práctica normal sin XP.
No cierra los otros cinco clientes de IC-1 ni activa producción. El cliente
[IC-1B Guardián](IC1_GUARDIAN.md) también está validado en su alcance local;
siguiente IC-1C, Rescate de estrellas, reutilizando su contrato existente.
La revisión funcional de I2-5 y el ensayo académico están documentados en
[el acta Android](I2_5_RECORRIDO_ANDROID.md) y
[el ensayo académico](ENSAYO_ACADEMICO_LOCAL.md).

Se reutilizan motor, repositorio, recuperación cifrada y endpoints existentes.
No hay migraciones, dependencias nuevas, cambios de fórmulas ni animaciones.

## Comportamiento

- Estudiante real: interruptor «Competir en el ranking», apagado inicialmente.
  El modo normal conserva el payload anterior; al elegir competir se envía solo
  `competitive: true` además de los filtros académicos existentes.
- El campo booleano `competitive` del servidor confirma la modalidad. Una
  respuesta con modalidad distinta de la solicitada se rechaza; no hay cambio
  automático a práctica normal ni XP local. Una API antigua sin ese campo solo
  se interpreta como normal, nunca como admisión competitiva.
- La modalidad no cambia durante el mismo intento. La recuperación obtiene el
  estado real del servidor; respuestas y abandono conservan los mismos endpoints
  y las claves idempotentes anteriores. Un cambio de modalidad en la respuesta
  no elimina el envío pendiente ni reemplaza el estado ya confirmado.
- Con `COMPETITIVE_SOLO_ENABLED` apagado, el servidor rechaza la admisión. La
  interfaz explica el rechazo y permite que el usuario elija explícitamente
  practicar sin XP. La app no configura ese flag.
- La demo no ofrece el interruptor y rechaza solicitudes competitivas.
- El resumen competitivo enlaza al ranking de Cima, solicitando lectura fresca
  de la temporada sugerida. No inventa XP ni confirma que la liquidación haya
  terminado; el usuario puede cambiar año/actualizar con el lector existente.
- Abandonar requiere confirmación y advierte que las reglas competitivas se
  aplican en el servidor. Salir de la pantalla no envía abandono.

Cima no usa el protocolo de presencia de Trivia/Tira: conserva su contrato de
recuperación y vencimiento a las 24 horas. No añadir latidos ni una penalización
por suspensión de la app a este juego.

## Archivos principales

- `lib/features/games/summit/domain/summit_models.dart`: modalidad confirmada.
- `lib/features/games/summit/data/remote_summit_repository.dart`: admisión y
  comprobación de modalidad antes de aceptar/persistir respuestas.
- `lib/features/games/summit/data/demo_summit_repository.dart`: demo sin competición.
- `lib/features/games/summit/presentation/summit_page.dart`: selección, recuperación,
  rechazo y navegación al ranking; sin contabilidad de XP en Flutter.
- `lib/features/ranking/presentation/competitive_ranking_page.dart`: juego inicial
  opcional, conservando Trivia como valor predeterminado de la navegación previa.

## Evidencia de preparación — antes del ensayo físico

Resultados finales del 8 de octubre:

- `flutter analyze --no-pub`: sin incidencias.
- `flutter test --no-pub --reporter expanded`: 707 aprobadas, 9 opt-in omitidas,
  sin fallos en la ejecución final (3 min 24 s aproximadamente).
- Ranking dirigido antes del cambio: Flutter 66/66 y backend 43/43, dos suites.
- 13 nuevas pruebas de Cima (contrato, repositorio, demo y widgets), incluidas
  en la suite global. Sin repetir la regresión PostgreSQL del compañero.
- Primera ejecución global: 706 aprobadas, 9 omitidas y 1 fallo del nuevo test
  de pantalla pequeña por pulsar un centro fuera de pantalla/usar un elemento
  aún no construido por la lista. Se corrigió el guion del test para desplazarse
  al interruptor y al botón reales; no se retiró la aserción ni el caso. La
  ejecución final global anterior corresponde a la corrección completa.
- Formato de archivos Dart afectados y `git diff --check` correctos.
- 306 enlaces locales de los documentos de entrada/entrega comprobados, 0 ausentes.

En ese checkpoint de preparación todavía no se había compilado ni instalado una
APK de IC-1A. El ensayo posterior IC-1A2, registrado más abajo, sí la instaló y
validó. Las pruebas académicas anteriores corresponden a la versión previa.

Pruebas de contrato/repositorio/widgets añadidas: booleano estricto, flag OFF,
modalidad incorrecta, recuperación de creación sin acuse, modalidad estable en
respuestas, lecturas terminales repetidas, demo, selección, abandono, ranking y
pantalla pequeña con texto ampliado. Estas pruebas usan dobles HTTP; no equivalen
a una liquidación competitiva real.

El checkpoint previsto inicialmente era IC-1A2: preparar un entorno local aislado con doce
preguntas sintéticas distintas y el flag habilitado solo allí; ejecutar una
partida app/API, comprobar en el ledger una sola liquidación y su posición,
repetir recuperación/red/cierre sin duplicar XP y comprobar modo normal/flag OFF.
Reutilizar las herramientas de validación existentes, validar propiedad de los
recursos y no reutilizar la base de Supabase ni credenciales de producción.
No marcar IC-1A completa por pasar los tests con dobles. Después seguir con los
otros cinco clientes, cada uno con su contrato de presencia/cierre propio.

## Antecedente de preparación del ensayo IC-1A2 — 8 de octubre

Este apartado conserva intentos previos al cambio de cable. El ensayo posterior
registrado abajo prevalece: instalación y recorrido de Cima completados localmente.

- Servicios restaurados en loopback: API `43187`, panel `4173`; enlace USB
  al Android de ensayo. Dos pruebas HTTP del panel aprobadas en la nueva sesión.
- Banco sintético separado de Matemáticas: `Cima - ensayo local IC-1A2`,
  subtema `Sumas para el ascenso`, doce preguntas publicadas, dos opciones y una
  correcta por pregunta. Se creó exclusivamente en el contenedor temporal con
  propiedad verificada. No se concedió XP de Cima ni se tocaron datos remotos.
- Compilación debug separada opt-in mediante la propiedad Gradle
  `-PsaberplusValidationApk=true`: el paquete debe ser
  `com.example.saber_plus.i2validation`. Sin esa propiedad, la app habitual
  mantiene su identificador. La propiedad no modifica la variante release.
- Defines no secretos: `APP_ENV=dev`, `DEMO_MODE=false`, API y contenido en
  `http://127.0.0.1:43187`. No incluir el archivo privado de login en la APK.
- Admisión competitiva local aún apagada. Primero verificar su rechazo en el
  celular; luego habilitarla solo en el proceso aislado para la partida real.
- Compilación arm64 con propiedad Gradle explícita terminada: aapt confirmó
  `com.example.saber_plus.i2validation`, APK de 308115302 bytes. Dos intentos
  streamed de instalación fallaron sin causa detallada. El envío no-streaming
  y una consulta de shell quedaron bloqueados; se detuvieron solo esos clientes
  propios y se reinició ADB. Después no se detectó el dispositivo. El propietario
  confirmó «Instalar vía USB» activado. Instalación sin completar, pendiente de
  restablecer la conexión física; no se desinstaló la app habitual ni la de prueba.
  Después de reconectar, una consulta al modelo respondió; al repetir el envío
  no-streaming volvió a quedar pendiente junto con otra consulta del modelo.
  Se detuvieron solo esos clientes de instalación/consulta. No registrar éxito
  de instalación a partir de «device» ni de haber iniciado el envío.
  Tras cambiar el cable, el envío no-streaming en PTY terminó: 308115302 bytes
  copiados en 10.732 segundos, `adb install -r` respondió `Success` (8 de octubre).
  APK nueva instalada en el paquete de pruebas; recorrido físico todavía pendiente.
- Propietario confirma en Android el rechazo «El servidor todavía no admite
  partidas competitivas» al intentar competir en Cima: comprobación OFF aprobada.
  No se creó una partida ni se confirma todavía una concesión de XP.
- Harness local ampliado con doce preguntas sintéticas y control IPC explícito
  `solo-on` / `solo-off`, sin endpoints de prueba ni cambios en el bootstrap
  productivo. Ocho tests del control aprobados y sintaxis de scripts correcta.
  La sesión anterior se cerró con limpieza confirmada; nueva sesión lista con
  61 migraciones. Control `solo-on` confirmado por IPC (`enabled: true`),
  API/panel en loopback y reverse USB verificados. Es necesario repetir login
  ficticio. La partida y su liquidación siguen pendientes de ensayo.
- Propietario confirma primera pregunta `2 + 1` tras admisión ON. SQL de la
  base temporal verifica un único intento del estudiante: `ACTIVO`,
  `competitiveRulesVersion=1`, versión 1, cero respuestas, sin liquidación;
  cero eventos de Cima. Recuperación y resultado todavía pendientes.
- Propietario confirma cierre desde recientes y recuperación de la misma
  partida. SQL posterior conserva el mismo ID de intento, `ACTIVO`, versión 1,
  cero respuestas y cero eventos: sin intento duplicado ni abandono al cerrar.
  Resultado, pérdida de red/reintento y liquidación todavía pendientes.
- Sin reverse USB, propietario selecciona `3` para `2 + 1` y confirma que
  aparece el aviso de revisar la conexión. SQL previo a reconectar: mismo
  intento `ACTIVO`, versión 1, cero respuestas y cero eventos de Cima. Se
  restaura el reverse `43187`; reintento y aceptación única aún pendientes.
- Propietario pulsa reintentar y confirma avance a la siguiente pregunta. SQL:
  un único intento `ACTIVO`, una sola respuesta `esCorrecta=true`, modalidad
  competitiva 1, sin liquidación ni eventos de Cima. No confundir esta pérdida
  de conexión previa a recibir el POST con pérdida de acuse tras guardarlo.
  Se apaga la admisión local para comprobar recuperación y finalización de la
  partida aceptada sin habilitar nuevos intentos competitivos.
- Con admisión OFF, propietario confirma victoria tras continuar la partida.
  SQL verifica el mismo único intento `VICTORIA`, cinco respuestas/cinco
  aciertos, `competitiveRulesVersion=1`, liquidación finalizada. Ledger:
  un único evento de Cima; balance `SUMMIT`, temporada 2026, 100 XP. La
  lectura física del ranking y la persistencia sin duplicación al volver al
  resultado siguen pendientes. Esta concesión procede de la partida real;
  no del evento/balances sintéticos de Trivia.
- Propietario confirma ranking físico de Salto a la cima 2026: posición 1,
  100 XP, consistente con el evento/balance real. Pendiente comprobar nuevas
  lecturas/cierre sin nueva concesión y flujo normal sin XP.
- Propietario confirma cierre/reapertura y nuevas lecturas del ranking con
  100 XP y posición 1 conservados. SQL posterior: un solo intento, un solo
  evento de Cima, suma aplicada 100 y balance 2026 de 100; sin nueva concesión.
  Falta comprobar partida normal sin XP y cierre documental del ensayo.
- Propietario confirma victoria normal sin sumar XP. SQL final: dos intentos,
  ambos `VICTORIA` con cinco aciertos; uno competitivo/liquidado y otro con
  `competitiveRulesVersion` nulo, sin liquidación. Permanece un único evento
  SUMMIT, suma aplicada 100, balance 2026 de 100. Flujo normal OFF aprobado.

### Conclusión y límites de IC-1A2

Ensayo local aprobado: rechazo OFF, admisión ON, recuperación después de cerrar,
desconexión previa al POST y reintento con una sola respuesta, finalización del
intento aceptado tras apagar admisión, una liquidación autoritativa de 100 XP,
ranking físico 1/100, nuevas lecturas sin duplicación y práctica normal sin XP.
No se probó pérdida de acuse después de guardar el POST ni se repitió toda la
regresión SQL histórica. No certifica iOS, producción, otros juegos, todas las
combinaciones de filtros ni animaciones/audio. Esos límites no se sustituyen
por las pruebas con dobles. La sesión temporal se cierra al terminar y la
evidencia no contiene contraseñas; conservar solo el APK de pruebas y los informes.
  El recorrido físico
  y la liquidación siguen sin confirmar; esta preparación no cierra IC-1A2.
- La primera compilación con `flutter build apk` y la variable de entorno
  `ORG_GRADLE_PROJECT_saberplusValidationApk` produjo el identificador habitual
  según aapt: no se instaló. Se usa la propiedad explícita de Gradle y se
  inspecciona el artefacto antes de instalar; no asumir que la variable funciona.

## Comandos de commit para el propietario (entrega IC-1A)

No se ejecutaron commit/push. Revisar el contenido staged antes de confirmar;
los documentos del ensayo y de I2-5 incluyen el trabajo previo todavía local.
`android/app/build.gradle.kts` no tiene diferencia de contenido y no se incluye.

Flutter:

```powershell
cd "C:\Users\LENOVO 14ALC6\Desktop\SaberPLus\saber_plus"
git add README.md docs/IC1_CIMA.md docs/I2_5_RECORRIDO_ANDROID.md docs/ENSAYO_ACADEMICO_LOCAL.md
git add docs/ETAPAS_PENDIENTES.md docs/HISTORIAL_ETAPAS.md docs/INDICE_DOCUMENTACION.md docs/PROMPT_RELEVO.md docs/RELEVO_EQUIPO.md docs/SALTO_A_LA_CIMA.md
git add lib/features/games/summit lib/features/ranking/presentation/competitive_ranking_page.dart
git add test/remote_summit_repository_test.dart test/summit_remote_page_test.dart test/summit_game_test.dart
git diff --cached --stat
git diff --cached
git commit -m "feat: preparar cliente competitivo de Cima"
```

Backend (solo documentación, sin migraciones):

```powershell
cd "C:\Users\LENOVO 14ALC6\Desktop\SaberPlus-Backend"
git add README.md backend/README.md backend/docs/README.md backend/docs/PR_I2_RANKINGS.md
git add backend/docs/IC1_CIMA.md backend/docs/I2_5_SEGUIMIENTO_2026_10_07.md
git diff --cached --stat
git diff --cached
git commit -m "docs: registrar validacion local y continuidad de Cima"
```
