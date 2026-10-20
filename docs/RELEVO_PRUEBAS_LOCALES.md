# Relevo de pruebas locales — Docker, Android USB y juegos

**19 de octubre — continuar aquí, no en los guiones históricos:** [R4 reportes](MA1R_R4_VALIDACION_LOCAL.md),
12/12 humanos y45/45 HTTP/PostgreSQL aprobados; backend121/1567 tras fix de concurrencia, Flutter920/13 opt-in
omitidas, ADMIN109/build/análisis. Remate Android confirmado: R4 cerrada localmente,
integrada en main por PR app #6/API #9 (21757a1/eef0d40); CI backend del PR aprobado,
QA-1 Flutter remoto pendiente. Sigue preparación local C5.
No repetir12 ni juegos/instituciones por defecto. Sesiones
anteriores/bases automáticas limpiadas, remate en otra temporal; no asumir claves
válidas ni servicios activos. Comando
técnico independiente en backend: `npm run test:question-reports:postgres` (Docker
local, sin celular/URL externa). OV-1 separado; sin despliegue/migraciones remotas.

**Consolidación posterior completada:** [cierre técnico local](CIERRE_INSTITUCIONES_LOCAL.md)
con Flutter893/13 opt-in omitidas, backend119 suites/1.470, panel95/95 y TypeScript/
análisis correctos. Commits app6bab6be/API7ba93d7/lockbfce42e integrados a main por
PR app #5/API #8. CI backend PR/main aprobado; Flutter analyze/102 dirigidas aprobados.
Sin nuevos ensayos físicos/SQL. [Orden posterior](ESTADO_Y_ORDEN_2026_10_17.md):
MA-1R/R1–R3 locales; [acta app/panel](MA1R_R3_APP_PANEL.md), sigue R4;
OV-1 sigue con el compañero. Sin push automático ni
nuevos gestos Android obligatorios.
No usar los siguientes pasos de notas históricas para repetir ensayos. Observaciones
JPEG original y CI Linux/Node/npm fijados siguen abiertas, sin operación remota.

**Checkpoint vigente:** C4-C10/10 guiones integrados cubiertos, Android+19 HTTP/SQL
finales, no10 pruebas solo manuales. Permisos/códigos/replay/traslado finales aprobados,
snapshot sin cambios y código alternativo sintético retirado. Regresión global Flutter
final893 aprobadas/13 opt-in omitidas, análisis limpio; consolidación y commits ya creados.
No hay siguiente gesto Android obligatorio de C4 ahora. No repetir fixtures.
USB/API restaurados, institución APROBADA/límite original null. Sesión6fFUQb.
Código del archivo privado inicial ya era antiguo al cerrar. No asumir que la
contraseña, servicios o sesión siguen válidos al retomar.
Notas cronológicas inferiores conservan estados anteriores; no son el paso vigente.

**Histórico de guion7 (cerrado arriba):** propietario confirmó fallo de renovación y controles bloqueados.
**ReverseUSB43187 restaurado/API200**. Verificador `unchanged`: revisión1/misma
operación/auditoría1; intento offline no renovó. Sigue Consultar código vigente
y después mismo reintento. Baseline en tmp; no generar nueva operación ni contar
corte como ack perdido. Falta comprobar incremento único tras reintento humano.

**Último checkpoint del17:** en sesión6fFUQb, zero confirmó ingreso tras cancelar:
vínculo visible, sin grupo automático. Cotejo SQL solo lectura aprobado: ESTUDIANTE,
institución esperada, una solicitud CANCELADA/revisión1, un recibo/auditoría coincidente,
cero grupos/membresías docentes. C4-C:5/10 completos (1,3,4,5,8). Usuario confirmó
cupo agotado y consulta suspendida; ambos cotejos sin ingreso de absent. Cierre/reapertura con vínculo conservado y sin
entrada institucional por código; persistencia de guion10 aprobada parcialmente.
Usuario confirmó perfil público sin código privado ni copiar/generar/renovar:
guion3 completo. Absent confirmó rechazo de formato grupo y UUID de ejemplo.
**Restauración completada:** institución APROBADA, límite original null, ocupado1;
absent sin vínculo/recibos/auditoría. No quedan suspensión ni cupo reducido activos.
Usuario confirmó vista previa recuperada y fallo de red: reenvío bloqueado,
ambos botones de consulta habilitados. **ReverseUSB43187 restaurado**, API200;
SQL aprobó absent sin vínculo/recibos/auditoría. Sigue pulsar Consultar mi vínculo
antes de reintentar. Corte antes de POST, no ack perdido. Guion10 parcial.
No generar nuevos códigos ni solicitudes.

**Actualización posterior de red:** usuario confirmó consulta de vínculo, reintento
y vínculo/sin grupo. SQL posterior: absent ESTUDIANTE, cero solicitudes, un recibo/
evento de ingreso, cero grupos/membresías docentes. No hay duplicados observados.
Sigue cerrar sesión y entrar con student sin vínculo: no debe heredar institución,
código ni intento. Guion9 parcial (faltan replay/traslado), guion10 parcial (cuentas/
texto). Controles de cupo para absent sin vínculo ya no aplican; no reejecutarlos.
No repetir preparación ni generar códigos sobre esta sesión ya utilizada.

**Reanudación posterior del17:** sesión actual `saberplus-i2-local-6fFUQb`,66
migraciones; API43187/panel4173 responden200 y enlace USB activo. APK del segundo
fix confirmada instalada (lastUpdateTime17 de octubre00:16:19), sin reinstalar.
Sesión mR98b6 ya retirada. Fixtures sintéticos reconstruidos: zero sin vínculo,
solicitud PENDIENTE y código nuevo; datos privados en `c4-return-private.json` de
la sesión actual. No se conserva el intento en memoria de la app anterior.
Sigue iniciar sesión nueva y reproducir rechazo→solicitudes→cancelar→volver→
reintentar; la recuperación de acciones ya fue aprobada en sesión anterior,
pero el ingreso posterior a cancelación aún no. No registrar preparación como prueba.

**17 de octubre — sesión acotada:** `saberplus-i2-local-mR98b6`,66 migraciones,
APK corregida ya instalada (confirmado paquete Android). Zero tiene solicitud
inicialmente PENDIENTE sintética y código nuevo; datos privados en
`c4-return-private.json` de esa sesión, no reutilizar los del16 ni sesiones caducadas.
Tras cancelar/volver, usuario confirmó actualización y Reintentar mismo ingreso:
comprobación puntual aprobada. No pulsó el reintento; guion8 sigue parcial.
Trabajo finalizado por hoy. Retomar servicios y reintento tras cancelación mañana;
si caduca base, reconstruir fixtures sin atribuir preparación como prueba humana.
Ver acta C4 para alcance y pendientes. No iniciar otros guiones en este cierre.

**Hallazgo posterior del17:** usuario confirmó bloqueo del botón de solicitudes
tras rechazo por pendiente. Segundo fix Flutter permite abrir solicitudes aun
cuando falta reconciliar ingreso, manteniendo bloqueo de reenvío y consulta al
retornar.93/93 dirigidas y analyze limpio. Nueva APK compilada e instalada por USB
(`Success`,17 de octubre); usuario confirmó recuperación de acciones al volver.
No confundir primera APK del16 con este segundo fix.

**16 de octubre:** C4-A/B implementados, resultados finales en [acta C4](PR_I5_C4_CODIGO.md).
Preparación C4-C completada: sesión temporal `saberplus-i2-local-gJ5KOg`,66 migraciones,
fixtures sintéticos y APK C4-B aislada instalada por USB (`Success`). Casos humanos2/10
completos (1 y4),2,3,5,6,7 y8 parciales. Ingreso visible confirmado y conservado al actualizar;
renovación rechaza código anterior y acepta consulta del nuevo. Faltan cotejos y escenarios
descritos en acta. `zero@example.invalid` canceló su solicitud; al volver reportó
ayuda confusa de pendiente. Fix Flutter validado46 C4+46 regresiones y analyze limpio;
sigue instalar APK corregida y repetir vuelta desde solicitudes canceladas sin ingreso
automático. No crear otra solicitud ni cerrar guion8 sin confirmación humana.
Detalle y límites de evidencia en acta C4.
No usar APK C3 para acreditar C4. La base temporal C4-A fue retirada tras16 HTTP/SQL y14 C3 posteriores;
no reutilizar credenciales. No repetir C3C10/10 ni juegos por prompts inferiores.
OV-1 sigue independiente, commits institucionales aún pendientes.

**15 de octubre: siguiente ensayo del propietario C3C — solicitudes estudiantiles.**
Ver [acta C3](PR_I5_C3_SOLICITUDES.md). Backend y pantallas implementados;
no hay confirmación humana C3 todavía. Validar sesión temporal nueva/65 migraciones,
preparar propietario/lector/alumnos ficticios y APK actual antes de pedir pruebas USB.
No usar contraseñas caducadas ni repetir juegos/C2C por prompts antiguos.
OV-1 continúa independiente. No hacer commit hasta nueva indicación del propietario.

**Actualización del14 de octubre:** C2C validada localmente (6/6 HTTP/SQL y8/8
humanos). Próximo trabajo del propietario: solicitudes estudiantiles/avisos/código
institucional. Leer cierre y observaciones en [acta C2](PR_I5_C2_LOGO.md).
Las instrucciones específicas C2C inferiores se conservan como guion histórico;
no repetirlo por defecto. El compañero mantiene su frente OV-1.

**Trabajo paralelo acordado:** propietario → instituciones (sigue C3C);
compañero → test vocacional OV-1 (comienza A, después B/C/D), sin esperar C2C.
Ver [responsables, ramas y entrega](TRABAJO_PARALELO.md). Este acuerdo sustituye
la secuencia estricta de OV-1 y el trabajo individual directo en main.

**Siguiente: PR-I5-C2C, logo institucional.** Código C2A/B implementado; migración
y ensayo SQL/HTTP/Android pendientes. [Guion](PR_I5_C2_LOGO.md): sesión nueva,
fixtures C1, seis casos reales y ocho comprobaciones en celular. C1 ya terminado.

**Ensayo anterior completado,12 de octubre: perfil PR-I5-C1C.** Preparación aprobada
con63 migraciones, API43187, 15 HTTP/PostgreSQL +3 Flutter/API reales y APK instalada.
Pruebas humanas 1–6 aprobadas (incluido límite500/guardado, SQL500/revisión12).
Pruebas 7 y 8 aprobadas: fallo/red/borrador y recuperación/consulta/guardado.
Reverse43187 restaurado. Prueba9 aprobada: conflicto/consulta/guardado recuperado,
SQL revisión15. Prueba10 aprobada: «Seguir editando» conserva y «Salir» descarta;
reapertura y SQL confirman publicado intacto/revisión15. **C1C local cerrada:**
10/10 humanas; siguiente C2, logo institucional. No acredita despliegue remoto.
Ver [acta del perfil](PR_I5_C_PERFIL.md). Harness admite rutas explícitas territorial
y perfil pendientes; restantes migraciones desde HEAD. La nota T5 inferior es histórica. La allowlist actual también admite la migración C2 del logo.

Actualizado: 12 de octubre de 2026. Guía operativa para el propietario, compañeros
y sus chats. **El punto vivo de continuación está en
[ETAPAS_PENDIENTES — checkpoint](ETAPAS_PENDIENTES.md#checkpoint-de-relevo-de-pruebas)**.
Si avanzamos, actualizar ese bloque y el acta del juego; no empezar desde una
captura antigua ni una instrucción de chat que contradiga el repositorio actual.

**Checkpoint del 11 de octubre: PR-I5-T5 cerrado localmente.** Docker/USB,
62 migraciones, guion territorial HTTP/PostgreSQL, panel y recorrido Android
aprobados en el alcance del acta. Siguiente: perfil institucional y solicitudes
PR-I5. Verificar servicios al retomar, no asumirlos activos. El harness admite solo
la migración territorial pendiente por ruta explícita; previas vienen de HEAD.
Consultar [acta territorial](PR_I5_T_TERRITORIO.md). Las secciones de juegos
inferiores son antecedentes y procedimientos, no orden para repetirlos.

## 1. Qué recibir y leer antes de trabajar

Se necesitan ambos repositorios, públicos según API GitHub el 13 de octubre.
Coordinar permisos de escritura; no cambiar visibilidad ni compartir credenciales:

- Flutter: `https://github.com/Pavel2020123/saber_plus.git`.
- Backend y panel: `https://github.com/Pavel2020123/SaberPlus-Backend.git`.

Rutas del propietario, adaptar en el PC del compañero:

```powershell
cd "C:\Users\LENOVO 14ALC6\Desktop\SaberPLus\saber_plus"
git status --short
git branch --show-current
git log -5 --oneline
```

Repetir en `C:\Users\LENOVO 14ALC6\Desktop\SaberPlus-Backend`.
Con trabajo limpio y propietario coordinado: `git pull --ff-only origin main` en
cada repo. Si hay cambios locales, **parar y revisar diff**, no borrarlos ni hacer
stash/reset a ciegas. Si divergen las ramas, no forzar el pull. El propietario
acordó ramas por frente para trabajo paralelo; no editar el mismo módulo sin coordinar.
Antes de clonar elegir carpetas vacías; no clonar encima de un proyecto existente.

Lectura inicial:

1. AGENTS.md si existe; README de ambos repositorios y checkpoint del roadmap.
2. [Arquitectura y estructura](ARQUITECTURA_Y_ESTRUCTURA.md),
   [relevo general](RELEVO_EQUIPO.md), [prompt general](PROMPT_RELEVO.md).
3. Acta del juego activo, contrato Flutter/backend, modelos, repositorios,
   controlador/servicio, permisos, reglas, reconciliador, tests y migraciones
   afectados. Auditar UI → API → Prisma → ledger → ranking antes de editar.
4. Backend: `backend/docs/README.md`, `backend/docs/PR_I2_RANKINGS.md`,
   `backend/tool/LOCAL_RANKING_VALIDATION.md`, `admin/README.md` y manifests.

Auditar cambios recibidos y sus regresiones; no afirmar auditoría completa de
todo el código por leer los README. No reescribir motores ni cambiar reglas.
HEAD conocidos de esta entrega: Flutter `c36c0cc`, backend `1774476`;
son referencias históricas, **no destinos para checkout/reset**. Nuevos commits
pueden avanzar; verificar su disponibilidad remota antes de pedir al compañero
que continúe. Un commit local no aparece en otro PC hasta hacer push/pull.

## 2. Antecedentes: checkpoint inicial y qué no repetir

Antecedente **IC-1C: Rescate de estrellas** (no es la etapa actual): cliente competitivo integrado y
tests dirigidos/HTTP/SQL aprobados en el alcance de [su acta](IC1_RESCATE.md).
Recorrido Android/API/ledger local aprobado el10 de octubre, incluidos dos
abandonos distintos100→90→80. Guardado autorizado; push manual/cierre operativo
separados, no repetir batería.

| Juego | Evidencia actual | Continuación |
|---|---|---|
| Cima, IC-1A/A2 | [Acta](IC1_CIMA.md): victoria real local +100, OFF, recuperación, red/reintento, no duplicación y normal sin XP | No repetir salvo cambio relacionado/regresión concreta |
| Guardián, IC-1B1/B2 | [Acta](IC1_GUARDIAN.md): victoria +100, derrota con 3 aciertos +30, abandono −10, balance final120; normal sin evento, recuperación/red/ranking | No repetir salvo cambio relacionado; evidencia pertenece a aquella sesión |
| Rescate, IC-1C | 62 tests Flutter/32 backend; Android/API/SQL aprobados: victoria100 única, recuperación/red/reintento, normal sin evento, agotamiento2 estrellas/+20, abandono−10 por intento y contraste100→90→80. Supervisor12 tests/CI y runtime | [Acta](IC1_RESCATE.md); guardado autorizado el10 de octubre. Instituciones posterior ya tiene cierre local; I2-5/QA-1 operativo separado. No repetir batería |
| Trivia | Competición aplazada fuera del bloque inicial V1 | [Contrato](TRIVIA_RUSH_BACKEND_CONTRACT.md); conservar modo normal |
| Duelo fantasma | Competición aplazada fuera del bloque inicial V1 | [Base](GHOST_DUEL.md); conservar modo normal |
| Tira y afloja | Competición aplazada fuera del bloque inicial V1 | [Contrato](TUG_OF_WAR_BACKEND_CONTRACT.md); al retomarlo probar dos participantes reales |
| Memoria IC-2 / Batallas IC-3 | Competición aplazada; NO_DISPONIBLE hasta implementar y validar | Conservar código; no confundir juego normal con competición integrada |

**Después de Rescate: instituciones**, no otro juego. Leer
[alcance acordado](ALCANCE_V1_NOVIEMBRE_2026.md): OV-1, perfiles, insignias,
territorio y demás funcionalidades permanecen. Esta guía conserva procedimientos
de pruebas de juegos aplazados para cuando se autorice retomarlos.

Los balances y IDs históricos no se copian a la base nueva. Los 61 participantes
de Trivia sembrados por el harness son **fixtures sintéticos**, no partidas
competitivas verificadas. Ningún juego queda validado solo por ver esos rankings.
No repetir por defecto las 347 pruebas SQL del compañero; hacerlo si el cambio
afecta contratos/esquema/concurrencia y dejar constancia de por qué.

## 3. Preparar Docker y la API propia

- Docker Desktop abierto, motor Linux/WSL2 funcionando, contexto **local**.
- Espacio/RAM suficientes para herramientas y APK; comprobarlos, no garantizar
  que una cifra fija alcance. No descargar imágenes ni hacer prune indiscriminado.
- Node/npm según `backend/package.json` (hoy Node24.14.1/npm11.11.0); Flutter según
  proyecto/CI/lock. Registrar versiones reales. No actualizar dependencias por gusto.

En `SaberPlus-Backend\backend`:

```powershell
node --version
npm --version
docker context show
docker info --format "{{.OSType}}"
docker image inspect postgres:16
```

Si falta la imagen y hay recursos, descargar `docker pull postgres:16`.
Preparar dependencias reproducibles y compilación; verificar salida de cada paso:

```powershell
npm ci --include=dev
npm run build
node tool/local_ranking_validation.mjs
```

Mantener esa terminal abierta. El harness crea **su PostgreSQL desechable propio**,
aplica migraciones allí y levanta API `http://127.0.0.1:43187`. No sustituirlo por
`npm start` con un .env desconocido ni ejecutar `prisma migrate deploy` contra
Supabase/local del propietario. No cargar .env/.env.staging.local. El supervisor
imprime `local-ranking-ready` y la ruta temporal, no la contraseña.

Guardar esa **ruta nueva** en otra terminal como `$testSessionDirectory`.
No reutilizar nuestra ruta antigua, nonce, contenedor ni sesiones de ejecución.
Hay límite de **dos horas**; si expira o Docker se detiene, el estado de la base
puede perderse. Las actas no desaparecen: empezar nueva sesión y revalidar solo
la preparación/punto interrumpido, identificando que es otra base.

El harness inicia admisión competitiva OFF, crea 12 preguntas sintéticas
Matemáticas/BASICO, tema `Cima - ensayo local IC-1A2`, subtema `Sumas para el ascenso`.
Sirven para Cima, Guardián y selecciones compatibles, pero **no garantizan** el banco
ni filtros/requisitos de todos los juegos. Leer contrato: Rescate necesita 10
preguntas válidas. No bajar el mínimo por tener pocos fixtures; adaptar únicamente
la siembra de prueba y probarla si un juego necesita otro banco.

Panel opcional, en terminal aparte desde `SaberPlus-Backend\admin`:

```powershell
$env:ADMIN_HOST="127.0.0.1"
$env:ADMIN_PORT="4173"
$env:API_BASE_URL="http://127.0.0.1:43187"
node server.mjs
```

No usar `npm start` aquí: su script carga .env.local si existe. El panel con API
propia no es la demo en memoria. Mantener también esa terminal abierta.

## 4. Contraseña: solo integración y cuentas ficticias

Las pruebas unitarias/repositorio/widget **no necesitan una contraseña real**.
Solo la integración HTTP y el login físico usan la credencial efímera generada
en `$testSessionDirectory\flutter-private.json`, campo `AUTH_E2E_PASSWORD`.
Usuario estudiante `student@example.invalid`; ADMIN `admin@example.invalid`.
Abrir el archivo privado localmente para introducir el login manual; no pegarlo
en chat, logs, README, screenshots, commits ni APK. Los tokens/contraseña cambian
con cada nueva base; cerrar sesión/reautenticarse si aparece 401, no desactivar guards.

En Flutter, con dependencias preparadas (`flutter pub get`), integración opt-in:

```powershell
flutter test --no-pub --reporter expanded "--dart-define-from-file=$testSessionDirectory/flutter-private.json" test/auth_api_live_test.dart test/competitive_ranking_local_api_test.dart
```

Registrar cantidad real de pass/skip/fail. No marcar integración aprobada si quedó
omitida porque faltaba el define. No usar ese archivo para `flutter build`.
Panel HTTP opcional, desde backend:

```powershell
$env:SABERPLUS_LOCAL_SESSION=$testSessionDirectory
node --test tool/test_local_panel.mjs
```

Ese test modifica únicamente fixtures propios. No acredita navegador ni un juego.

## 5. Android por USB: preparar e instalar sin pisar la app habitual

1. Cable **de datos** fiable; teléfono conectado durante todo el ensayo.
2. Activar Opciones de desarrollador, depuración USB y, si el fabricante lo exige,
   Instalar vía USB. Aceptar autorización de ese PC y aviso de instalación.
3. Mantener pantalla encendida/desbloqueada mientras se instala y se interactúa;
   usar temporalmente «Permanecer activo al cargar» si está disponible. Para casos
   de suspensión/cierre, seguir el guion específico y después desbloquear.
4. Confirmar `adb devices` con estado `device` y `flutter devices`; `unauthorized`
   requiere autorización, no desactivar seguridad del servidor. Con varios equipos,
   elegir serial y usar `adb -s SERIAL` en cada comando. Adaptar ruta de adb del SDK.
5. `adb -s SERIAL reverse tcp:43187 tcp:43187`. El teléfono usa loopback a través
   de USB, **no localhost del PC por Wi-Fi**. `reverse --list` debe mostrar el puerto.

APK de prueba separada: `com.example.saber_plus.i2validation`; normal:
`com.example.saber_plus`. No borrar la app/data para solucionar una prueba de
persistencia ni instalar una APK normal encima de ella. Para ARM64, desde
Flutter `android\`, usando JDK de Android Studio instalado en ese equipo:

```powershell
# Configurar JAVA_HOME con la ruta real de su JDK; no copiar una ruta inexistente.
$testDefines=@("APP_ENV=dev","DEMO_MODE=false","API_BASE_URL=http://127.0.0.1:43187","CONTENT_BASE_URL=http://127.0.0.1:43187") | ForEach-Object { [Convert]::ToBase64String([Text.Encoding]::UTF8.GetBytes($_)) }
$encodedTestDefines=$testDefines -join ","
.\gradlew.bat -q "-PsaberplusValidationApk=true" "-Ptarget-platform=android-arm64" "-Ptarget=lib/main.dart" "-Pdart-defines=$encodedTestDefines" assembleDebug
```

Comprobar ABI con `adb -s SERIAL shell getprop ro.product.cpu.abi`; adaptar target
si no es ARM64. Verificar con `aapt dump badging` el paquete separado antes de
instalar `build\app\outputs\apk\debug\app-debug.apk` desde la raíz Flutter.
No usar una copia Flutter antigua cuyo paquete no se haya comprobado. No basta
poner una variable ORG_GRADLE_PROJECT: el ensayo acreditado usó propiedad explícita.

```powershell
adb -s SERIAL install --no-streaming --no-incremental -r "RUTA_FLUTTER\build\app\outputs\apk\debug\app-debug.apk"
```

Esperar **Success**, abrir la app y login manual. «device», «Performing install» o
APK compilada no significan instalada. Ante bloqueo, revisar pantalla/cable antes
de reinstalar; detener únicamente clientes propios, no matar procesos ajenos.
No usar `flutter run` sin verificar configuración/paquete de esta sesión.

## 6. Referencia histórica de pruebas de juegos — no ejecutar para C2C/OV-1: Guion por juego y evidencia después de CADA checkpoint

Antes de probar, escribir en el acta qué caso se hará, estado/flag esperado y base
propia. Usar las reglas vigentes del servidor, no cantidades inferidas de capturas.

1. Unitarias/contrato/widgets dirigidos; cuenta/rol/cambio de sesión, modalidad
   explícita, rechazo OFF, no fallback, filtros, persistencia y mismo UUID.
2. En teléfono, admisión OFF: mensaje correcto, sin intento nuevo. Leer SQL/API.
3. ON **solo en el harness propio**: `control.json` con `{"action":"solo-on"}`;
   esperar ACK `local-solo-admission`, `enabled:true`. No activar flags remotos.
4. Iniciar, comprobar ID/modalidad y preguntas. Filtros: Básica, no Media, para
   nuestra siembra. Recuperar tras cerrar/reabrir conserva ID, sin duplicación.
5. Red: retirar SOLO `adb -s SERIAL reverse --remove tcp:43187`, enviar; conservar
   selección/UUID, cero progreso inventado. Restaurar reverse y reintentar. Leer
   SQL para confirmar una respuesta. No acreditar pérdida de acuse posterior al
   guardado si solo se desconectó antes del POST. Caso posterior requiere prueba aparte.
6. Apagar nuevas admisiones mediante `solo-off` y ACK; intento admitido sigue
   bajo su contrato. Terminar, esperar reconciliación y comprobar evento único.
7. Ranking del juego/temporada, actualización/reapertura sin duplicar XP.
8. Modo normal no crea evento competitivo ni modifica balance. Demo tampoco.
9. Derrota/agotamiento y abandono según contrato y fórmula; saldo mínimo/corrección
   si el caso los requiere. No asumir que toda derrota da 0: Guardián da 10/acierto.
10. Casos específicos: tiempos/presencia/reconexión/final simultáneo de Trivia/Tira,
    récord fantasma limpio, dos rivales para Tira; no trasplantar latidos entre juegos.
    Una cuenta única o CPU **no valida** multijugador. Preparar fixture de segundo
    estudiante con autenticación local si falta; no usar personas reales ni alterar
    61 balances sintéticos esperando que puedan iniciar sesión.
11. Pruebas dirigidas backend, `flutter analyze --no-pub`, suite Flutter final
    proporcionada al cambio. No ocultar skips/errores; lint backend no usar --fix
    para diagnosticar. Decidir regresión SQL adicional por riesgo y entorno seguro.

SQL **de solo lectura**, contenedor local con etiqueta
`saberplus-competitive-disposable-v1` y nonce de la sesión verificados; usar las
tablas/campos reales del juego. Leer intentos, resultados, eventos por sourceId,
balance y ranking. No imprimir URL, POSTGRES_PASSWORD, owner.json ni DATABASE_URL.
No alterar balances por SQL para fabricar la evidencia que debía producir la partida.

Después de CADA caso, antes de pedir el siguiente paso al humano:

- Acta por juego en Flutter `docs/IC1_<JUEGO>.md`; resumen espejo backend
  `backend/docs/IC1_<JUEGO>.md` si afecta API. Distinguir «preparado», «usuario
  confirmó», «SQL confirmó», «falló», «pendiente» y «no aplica».
- Anotar fecha, versiones/HEAD, comando sin secretos, resultado/cantidad,
  selección/datos sintéticos, ID de intento/evento propio cuando sea útil,
  saldo antes/después, limitación y **exacto siguiente gesto/checkpoint**.
- Actualizar el checkpoint propio del frente. El propietario consolida el roadmap
  al entregar/integrar el bloque; no editarlo simultáneamente. Si terminó un juego,
  actualizar README, índice, relevo/prompt e historial de ambos repositorios.
- No prometer corrección sin implementarla/probarla. No afirmar toda IC-1 cerrada
  porque aprobaron Cima/Guardián. Mantener explícitos P5/D3 productivos pendientes.

Plantilla mínima para continuar incluso si se interrumpe el chat:

```text
Checkpoint: [ID y nombre]
Estado: preparado / aprobado / falló / pendiente / no aplica
Base/sesión: propia, nonce/fecha (sin URL ni credenciales)
Entorno y HEAD: [versiones/commits]
Acción/comando: [sin secretos]
Esperado y observado: [separar confirmación humana, HTTP y SQL]
Evidencia: [intento/evento/cantidad/balance si aplica]
Límite: [qué NO prueba]
Siguiente: [gesto exacto o archivo/caso que falta]
Si la sesión expiró: [preparación mínima a repetir, no todo el juego]
```

## 7. Cierre, commits y entrega al siguiente compañero

El relevo no se limita a juegos: después seguir **las demás etapas del roadmap**,
no ejecutar todo de golpe. Cada módulo necesita su acta y preparación propia:
mapa MA-2 panel→API→app; repaso MA-3 persistencia/reconexión; insignias/perfiles/
instituciones permisos y privacidad; certificados seis tipos, áreas vacías/
incompletas y nombres largos; identidad/sesión revocación; académico recuperación/
versiones/tiempos. P5/D3, SMTP, Billing/AdMob y producción requieren configuración
y autoridad adicionales: una API Docker no los acredita. iOS necesita su ensayo
macOS/Xcode/dispositivo, no se da por probado en un Android USB.

Un commit por juego **en cada repositorio afectado**, al cerrar pruebas y acta;
documentación de soporte puede tener commit separado. Estado intermedio no se
marca final para hacer un commit. No esperar a fin de sesión para registrar evidencia.

En cada repo: `git status --short`, `git diff`; `git add` de archivos explícitos,
`git diff --cached --check`, `git diff --cached`, commit con descripción real.
Mensajes sugeridos: `feat: integrar y validar Rescate competitivo` (Flutter) y
`docs: registrar validacion competitiva de Rescate` (backend si solo hubo docs);
si cambió código backend, describirlo en el mensaje, no decir solo docs.
Dar al propietario ruta, archivos, hash y comandos de push de la rama del frente en
ambos repos. Push solo cuando se acuerde. No git add . ni incluir .env/temporales.
Mientras un checkpoint está a medias, es válido publicar documentación de progreso
autorizada para relevo, dejando claro que el juego **no está cerrado**.

Cierre del entorno mediante `control.json` propio con `{"action":"stop"}` y esperar
`Owned local ranking API and PostgreSQL removed.`; detener panel propio y retirar
solo reverse `43187`. Confirmar limpieza; si supervisor fue matado, no asumirla.
No `docker system prune`, no borrar repos/carpetas amplias. No cerrar el entorno
antes de guardar evidencia ni tocar el del compañero. El siguiente PC crea otro.

## 8. Prompt vigente del propietario — después de instituciones y reportes

El compañero de OV-1 usa el prompt de TRABAJO_PARALELO.md, no este.

```text
Soy el propietario. Instituciones T/C1-C4 y reportes MA-1R/R1–R4 tienen cierre
local y están integrados en main. Lee CIERRE_INSTITUCIONES_LOCAL.md,
ESTADO_Y_ORDEN_2026_10_17.md, ETAPAS_PENDIENTES.md y los AGENTS aplicables.
Verifica ambos repositorios, status/rama/HEAD; no fuerces pull ni descartes cambios.
Instituciones: PR app #5/API #8 (e679c50/388bb18). Reportes: PR app #6/API #9
(21757a1/eef0d40), CI backend aprobado. Verifica el HEAD actual y crea una rama
para el siguiente bloque desde main actualizado, preservando cambios locales.
No hagas push/merge adicional ni despliegue sin autorización.
No repitas C2/C3/C4 ni reportes R1–R4 por las instrucciones históricas.
Mi compañero continúa OV-1: no edites su módulo ni CHECKPOINT_OV1.md.
Lee las actas MA1R_R4_VALIDACION_LOCAL.md de ambos repositorios:12/12 humanos,
45/45 HTTP/PostgreSQL,121 suites/1567 backend,920 Flutter/13 opt-in omitidas,
109 ADMIN y build/análisis aprobados. SQL solo en bases temporales.
El siguiente bloque recomendado es C5: auditar los recursos/fotos/archivos existentes,
definir permisos, límites, metadatos y persistencia; no reconstruir el logo C2.
Antes de implementar, confirmar el alcance de C5 con el propietario. Proveedor,
credenciales y operaciones remotas requieren autorización; no inventar carga real.
UX1 Ocultar/Deshacer sigue propuesta separada. P5/D3 y QA-1 conservan sus pendientes.
Coordina schema/migraciones/app.module/navegación/locks antes de tocar archivos
compartidos. Documentar cada resultado real del nuevo bloque en su acta.
No necesitas servicios para auditar documentos/contratos; avisar antes de ejecutar
la integración con DB o pedir el celular para el recorrido físico.
Cuando toque un ensayo real usa base local desechable y cuentas ficticias;
verifica servicios, USB de datos/depuración/pantalla desbloqueada y APK aislada.
No reutilices secretos/sesiones viejas ni operes Supabase/Render por este prompt.
Registra pruebas automáticas, HTTP/SQL y gestos humanos por separado.
Consolida roadmap al entregar el bloque, conserva actas históricas y entrega
rutas, resultados, límites, pendientes y comandos Git solo según autorización.
```
