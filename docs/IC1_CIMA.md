# IC-1A — Cliente competitivo de Salto a la cima

## Estado — 8 de octubre de 2026

Cliente implementado localmente, pendiente del ensayo app/API con una partida
competitiva real y liquidación única. No cierra IC-1 ni activa producción.
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

## Evidencia y siguiente paso

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

No se compiló ni instaló una nueva APK de esta entrega. Las pruebas físicas del
ensayo académico corresponden a la versión previa de la app, no a IC-1A.

Pruebas de contrato/repositorio/widgets añadidas: booleano estricto, flag OFF,
modalidad incorrecta, recuperación de creación sin acuse, modalidad estable en
respuestas, lecturas terminales repetidas, demo, selección, abandono, ranking y
pantalla pequeña con texto ampliado. Estas pruebas usan dobles HTTP; no equivalen
a una liquidación competitiva real.

El siguiente checkpoint es IC-1A2: preparar un entorno local aislado con doce
preguntas sintéticas distintas y el flag habilitado solo allí; ejecutar una
partida app/API, comprobar en el ledger una sola liquidación y su posición,
repetir recuperación/red/cierre sin duplicar XP y comprobar modo normal/flag OFF.
Reutilizar las herramientas de validación existentes, validar propiedad de los
recursos y no reutilizar la base de Supabase ni credenciales de producción.
No marcar IC-1A completa por pasar los tests con dobles. Después seguir con los
otros cinco clientes, cada uno con su contrato de presencia/cierre propio.

## Comandos de commit para el propietario

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
