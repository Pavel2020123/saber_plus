# IC-1C — Rescate competitivo

Entrega local del 9–10 de octubre de 2026. Cliente y recorrido funcional
Android/API/SQL aprobados en el alcance descrito. Cierre local IC-1C; no acredita
producción ni toda IC-1. El cierre del entorno y los commits se registran aparte.

## Comportamiento implementado

- Selector «Competir en el ranking», solo para estudiante real. La demo rechaza
  solicitudes competitivas; el modo normal conserva su funcionamiento.
- Creación con `competitive: true` y filtros existentes. La API confirma la
  modalidad; una respuesta normal/legada no acepta una solicitud competitiva.
- Modalidad persistida junto a identificadores y UUID en almacenamiento seguro
  separado por API/cuenta. Compatible con registros antiguos sin ese campo.
- Recuperación conserva modalidad, opción y UUID pendientes. Se rechazan cambios
  de modalidad, regresiones de contadores y confirmaciones de otra opción.
- Al guardar falla antes del POST si no hay persistencia; no calcula estrellas
  ni XP offline. Las cuentas reales mantienen confirmación del servidor.
- Rechazo de admisión OFF con explicación y elección manual del modo normal.
- Abandono confirmado informa de las reglas competitivas del servidor.
- Final competitivo permite abrir el ranking de Rescate y actualizar su consulta.
  La pantalla no calcula/concede XP ni promete liquidación inmediata.

Reglas conservadas: seis estrellas, dos constelaciones de tres, diez preguntas,
sin cronómetro; vigencia de 24 horas. Backend existente calcula
`10 × estrellas + 10 × constelaciones + 20 por victoria`; victoria completa100.
Abandono competitivo −10 según política existente. Sin cambios de fórmulas,
migraciones, reglas de otros juegos, audios o animaciones.

## Validación automática

- 62 tests dirigidos Flutter aprobados: 40 previos y 22 nuevos (17 repositorio,
  5 pantalla). Modo estricto/OFF, almacenamiento, recuperación, reintento, final,
  ranking, confirmación de abandono y pantalla pequeña/texto grande.
- Backend: 32 tests, tres suites (`star-rescue` y `competitive.solo.spec.ts`).
- Flutter analyze final aprobado. Suite global: 754 aprobadas, 10 opt-in omitidas,
  cero fallos; ejecución de 6 min 4 s. Las omitidas no acreditan ensayos reales.
- APK debug separada `com.example.saber_plus.i2validation` compilada y paquete
  verificado con aapt; instalada por USB con **Success** y abierta. Reverse43187
  confirmado y API health200. Instalación no acredita el recorrido humano.
- `test/star_rescue_local_api_test.dart`: opt-in con harness loopback y cuenta
  ficticia **zero**, diferente de la usada para el teléfono. Dos ejecuciones:
  modo normal y competitivo, 1/1 aprobada en cada una. Usa repositorio Flutter,
  HTTP/Auth/AppModule/PostgreSQL reales; almacenamiento en memoria dentro del
  test. No acredita el plugin seguro ni interacción humana en Android.
- Las preguntas son las doce sumas sintéticas del harness; no contenido del curso.
  La prueba verifica banco esperado, seis aciertos, recreación del repositorio
  tras la primera respuesta, recuperación del final, reenvío idempotente terminal
  y lectura/relectura del ranking. No simula un fallo real de red en esta prueba.

Consulta SQL de la base temporal propia verificó:

| Intento | Modalidad / resultado | Evento competitivo |
|---|---|---|
| `3db0a027-5c65-453b-9a4a-ac6e37184f5f` | Normal / VICTORIA | Ninguno |
| `d2bac1d6-c9ff-427a-aa09-f788eb964fec` | Competitiva / VICTORIA | Único, +100; saldo100 |

Reenvío no duplicó el evento. La cuenta del teléfono (`student@example.invalid`)
tenía cero intentos de Rescate al verificarlo; el ranking puede mostrar la cuenta
zero de ensayo. Estos IDs/saldos son históricos y no se copian en otro PC.
Control SOLO ON solo durante el ensayo propio, devuelto a **OFF con ACK**.

## Repetir la prueba HTTP en otra sesión

Leer [guía del equipo](RELEVO_PRUEBAS_LOCALES.md); crear base propia, usar el
archivo privado únicamente para `flutter test`. No imprimirlo ni incluirlo en APK.
Desde Flutter, con `$testSessionDirectory` de la sesión vigente:

```powershell
flutter test --no-pub --reporter expanded "--dart-define-from-file=$testSessionDirectory/flutter-private.json" test/star_rescue_local_api_test.dart
```

Después del control `solo-on` propio y su ACK, repetir con
`--dart-define=RESCUE_LOCAL_COMPETITIVE=true`. Volver a `solo-off` con ACK.
La prueba usa cuenta zero y crea partidas reales de ensayo; cada nueva victoria
competitiva añade100 y compara el saldo anterior. No ejecutarla por defecto en
la suite global, contra otra API o mientras otra persona usa esa cuenta.

## Recorrido físico IC-1C2 — historial del 9 de octubre

Tras aprobar OFF, admisión local habilitada con control propio `solo-on` y ACK
`enabled:true`. Usuario confirma primera pregunta «11+1» en Android. SQL:
intento `a6ec3648-24ee-47d0-91f8-e59b2b68b9ab`, ACTIVO, MATEMATICAS/BASICO,
competitiveRulesVersion1, cero respuestas y sin evento XP al comenzar.
Después se aprobaron recuperación, corte/reintento y continuidad con OFF.
Victoria/ranking/reapertura, modo normal y agotamiento parcial aprobados. Última
lectura SQL: 5 intentos físicos y 4 eventos (+100,+20,−10,−10), saldo100.
Falta contrastar visualmente el saldo tras ambos abandonos. No implica producción.

| Caso | Estado |
|---|---|
| Selector competitivo y rechazo con OFF, sin nueva partida | Confirmado por el usuario en Android; SQL posterior acredita 0 intentos de Rescate para student. API health200. |
| Admisión ON y comienzo | Confirmado en Android («11+1»); SQL ACTIVO competitivo v1, 0 respuestas y sin evento XP. |
| Recuperación tras cerrar/reabrir | Usuario confirma recuperación de «11+1»; SQL conserva el mismo intento ACTIVO competitivo, 0 respuestas, ningún intento nuevo ni evento XP. |
| Corte USB reverse antes del POST y error | Usuario confirma «No pudimos conectar con SaberPlus» tras intentar enviar 12 para «11+1». SQL conserva el mismo intento ACTIVO, 0 respuestas y ningún evento XP. |
| Reintento tras restablecer enlace | Usuario confirma «Liberaste una estrella». SQL: mismo intento ACTIVO competitivo, exactamente 1 respuesta guardada, sin evento XP; no hubo avance duplicado. Igualdad de UUID cubierta por tests dirigidos, no extraída del almacenamiento físico. |
| OFF de nuevas admisiones conservando intento aceptado | Aprobado: solo-off con ACK enabled:false; usuario confirma segunda estrella. SQL conserva mismo intento ACTIVO competitivo v1 con 2 respuestas y sin evento XP. |
| Victoria y evento único100 | Usuario indica finalización; SQL confirma VICTORIA, 6 respuestas, competitivo v1 y liquidación confirmada. Exactamente 1 evento del intento, delta+100, saldo Rescate100. |
| Ranking de Rescate | Usuario confirma su posición con 100 XP y otra cuenta con 100 XP (zero, ensayo automático). SQL posterior mantiene exactamente 1 evento +100 del intento físico. |
| Reapertura del resultado sin duplicación | Aprobado: usuario confirma victoria recuperada y ranking100 tras cerrar/reabrir. SQL posterior: mismo intento VICTORIA con 6 respuestas, liquidado, exactamente 1 evento +100/saldo100; no se duplicaron intentos ni XP. |
| Normal sin evento competitivo | Aprobado: usuario confirma finalización en Android; SQL intento 9322a923-cece-46a8-b840-fe3dc76e497c VICTORIA, 6 respuestas, MATEMATICAS/sin filtro de dificultad, competitiveRulesVersion y competitiveSettledAt nulos. Sin evento propio; conserva único evento previo +100/saldo100. |
| Agotamiento parcial | Aprobado con variante elegida por usuario: 2 aciertos/8 errores, 10 respuestas, 2 estrellas/0 constelaciones. SQL intento 0f5c72cd-6dca-49b2-9fb6-831be4310bf2 AGOTADO competitivo v1 liquidado, exactamente 1 evento +20/saldo120. Guion original 3 aciertos/+40 no ejecutado; no repetir solo por esa diferencia. |
| Abandono con política correspondiente | SQL aprobado con 2 intentos separados ABANDONADO competitivos v1, 0 respuestas. ed4cbb92-08d4-4c25-9ad5-6dad41bcfd48: único evento −10/saldo110; 11bb64f0-7e1c-4b20-846d-916970aacb27: único evento −10/saldo100. Usuario indica dos abandonos pero cree ver solo −10; pendiente reabrir ranking y confirmar saldo100 visible. No afirmar causa visual sin verificar. |

El enlace reverse43187 se retiró para comprobar el error y se restableció
después de la confirmación humana y SQL. Reintento aceptado una sola vez;
siguiente: reabrir ranking de Rescate y confirmar saldo100 tras 2 abandonos
distintos; SQL acredita −10 por cada uno, sin descuentos duplicados por intento.
Al solicitar SOLO OFF, el harness terminó con «Unexpected end of JSON input» y
confirmó «Owned local ranking API and PostgreSQL removed». No hubo ACK OFF.
La lectura SQL anterior al cierre acredita ambos descuentos; el contraste visual
final queda pendiente, pues la base efímera ya no está disponible. No recrear
saldos ni IDs anteriores como si fueran nueva evidencia. Panel4173 es proceso
separado; comprobarlo/cerrarlo antes de reiniciar otra sesión.
El error no acredita pérdida de acuse tras persistir.

También pendientes: pérdida real del acuse después de persistir, TTL24h físico,
audios, iOS, producción y el cierre operativo de I2-5/QA-1. Cada prueba debe
actualizar esta acta, su espejo backend y el checkpoint del roadmap.
Al cerrar el juego, commit por repositorio y **continuar con instituciones**.

## Corrección del supervisor y nuevo ensayo focalizado

9 de octubre, después del cierre de la sesión anterior. El supervisor hacía
`JSON.parse` directamente al leer control.json; un guardado incompleto terminaba
el proceso y su limpieza eliminaba la base temporal. Se extrajo un lector que
ignora JSON vacío/parcial o comandos inválidos, sin cambiar admisión. Errores
reales de disco/permisos siguen propagándose. Sin cambios en API productiva.

- 12 pruebas Node aprobadas: 4 de archivo y 8 IPC; incluidas en Backend CI.
- Ensayo runtime: archivo parcial produjo aviso, API siguió health200 y la
  siguiente orden completa solo-on obtuvo ACK enabled:true sin reiniciar.
- Flutter analyze nuevamente limpio; 62 tests dirigidos nuevamente aprobados.
  La global 754/10 corresponde a la ejecución anterior; no se repitió después
  de añadir el selector de cuenta al test opt-in.
- Sesión nueva propia, 61 migraciones, API43187, USB reverse restablecido. No
  se copiaron saldo120/IDs anteriores. Los registros anteriores son históricos.
- Preparación automática explícita con RESCUE_LOCAL_EMAIL=student@example.invalid:
  test HTTP Flutter 1/1 aprobado, victoria real e7976df5-80f2-46ed-a062-64e94ec9660c,
  6 aciertos, evento único +100/saldo100 confirmado por SQL. No es victoria humana.
- Siguiente físico: iniciar sesión NUEVA, confirmar ranking100; crear/abandonar
  dos intentos competitivos diferentes sin responder, comprobar 100→90→80 en
  pantalla y SQL. No repetir toda la batería anterior. Admisión local ON.
- No cerrar Rescate/crear commits finales antes de confirmar ese contraste
  visual. Después instituciones PR-I5/P4-C/PR-I5-T; no otro juego.

## Reinicio del 10 de octubre — checkpoint activo

El usuario informa fin del límite de sesión; API/panel sin listener al retomar.
Se levantaron nueva API temporal propia y panel, ambos HTTP200, 61 migraciones,
Android conectado/autorizado, reverse43187 restablecido. SOLO ON con ACK.
Credenciales nuevas privadas; no intentar usar JWT/clave de otra sesión.

Preparación automática nueva mediante test Flutter opt-in student: 1/1 aprobado.
SQL confirma intento f41e7c58-6731-480e-80d0-331a04b8874b VICTORIA, competitivo v1,
6 estrellas, único evento+100/saldo100. No se copiaron los saldos anteriores.
Siguiente: login nuevo, confirmar ranking100, dos abandonos diferentes y observar
100→90→80 en pantalla/SQL. App de prueba instalada; no hace falta recompilarla.
API temporal dura2h desde este arranque; panel es proceso separado. No afirmar
limpieza de directorios antiguos sin comprobarla; no se borraron en este reinicio.

Diagnóstico posterior: usuario informa ranking100 después del primer abandono.
SQL confirma intento 6547f9e8-a774-48fe-a755-aca249d98bbf ABANDONADO competitivo
v1 liquidado, 0 respuestas, evento único−10/saldo90. No se perdió el descuento.
Código verificado: reconciliador cada30s; pantalla ranking consulta al cargar o
al refrescar manualmente, sin sondeo automático. Puede conservar una lectura100
obtenida antes de la liquidación. No se verificó el instante exacto de esa lectura
ni se modificó código de ranking en este diagnóstico. Siguiente: volver al ranking
Rescate y pulsar «Actualizar ranking competitivo», comprobar90 antes del segundo
abandono. Si sigue100, inspeccionar selección/juego/temporada y respuesta HTTP.

## Cierre funcional local — 10 de octubre

Usuario confirmó90 tras actualizar y80 después del segundo abandono. SQL
confirma nuevo intento 000db488-a45b-4bdd-b8ef-bffa08ce1819 ABANDONADO/v1 liquidado,
0 respuestas, único evento−10/saldo80. Sesión10: exactamente 3 intentos y3 eventos
(victoria automática+100 y dos abandonos humanos−10 cada uno), saldo100→90→80.
No hubo pérdida de descuento ni duplicación. El desfase observado se resolvió
con actualización manual tras liquidación; no se implementó sondeo automático.
SOLO OFF confirmado con ACK enabled:false después del contraste; API/panel siguen
activos por ahora, cierre operativo separado. No eliminar datos de pruebas hasta
guardar evidencia; la sesión y sus credenciales siguen siendo temporales.

IC-1C aprobado localmente: admisión OFF/ON, recuperación, corte antes del POST/
reintento, continuidad con OFF, victoria/100 único, ranking/reapertura sin duplicar,
normal sin evento, agotamiento2 estrellas/+20 y abandono/−10 por intento.
No se acreditan pérdida real de acuse tras persistir, TTL24h físico, audios/iOS,
producción ni mejoras automáticas de refresco. No repetir la batería aprobada.
Guardado autorizado por el propietario el10 de octubre, un commit por repo:
Flutter `feat: integrar y validar Rescate competitivo`; backend
`fix: estabilizar entorno local y validar Rescate competitivo`. Incluyen código,
tests y documentación afectados. No incluir credenciales/archivos temporales.
Consultar `git log -1` en cada repo para hash, no insertar un hash propio circular
en el mismo commit. Push manual a cargo del propietario. Siguiente: **instituciones**.
