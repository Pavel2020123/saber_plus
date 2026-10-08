# Relevo de pruebas locales — Docker, Android USB y juegos

Actualizado: 8 de octubre de 2026. Guía operativa para el propietario, compañeros
y sus chats. **El punto vivo de continuación está en
[ETAPAS_PENDIENTES — checkpoint](ETAPAS_PENDIENTES.md#checkpoint-de-relevo-de-pruebas)**.
Si avanzamos, actualizar ese bloque y el acta del juego; no empezar desde una
captura antigua ni una instrucción de chat que contradiga el repositorio actual.

## 1. Qué recibir y leer antes de trabajar

Se necesitan **ambos repositorios privados** y permisos de acceso. No hacerlos
públicos ni copiar contraseñas para compartirlos:

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
autorizó trabajar en main; coordinar que dos personas no editen el mismo módulo.
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

## 2. Checkpoint inicial y qué no repetir

Al crear esta guía, la siguiente entrega es **IC-1C: Rescate de estrellas**:
auditar e implementar su admisión/modalidad competitiva contra el contrato existente,
probar unitariamente y luego ejecutar recorrido Android/API/ledger. No se ha
iniciado ni acreditado su partida competitiva física en esta entrega.

| Juego | Evidencia actual | Continuación |
|---|---|---|
| Cima, IC-1A/A2 | [Acta](IC1_CIMA.md): victoria real local +100, OFF, recuperación, red/reintento, no duplicación y normal sin XP | No repetir salvo cambio relacionado/regresión concreta |
| Guardián, IC-1B1/B2 | [Acta](IC1_GUARDIAN.md): victoria +100, derrota con 3 aciertos +30, abandono −10, balance final120; normal sin evento, recuperación/red/ranking | No repetir salvo cambio relacionado; evidencia pertenece a aquella sesión |
| Rescate, IC-1C | Cliente normal remoto existente; integración/ensayo competitivo pendientes | [Base y contrato](RESCATE_DE_ESTRELLAS.md), backend `STAR_RESCUE.md`; crear acta IC1_RESCATE al empezar |
| Trivia, después de Rescate | Integración/ensayo competitivo móvil pendientes | [Contrato](TRIVIA_RUSH_BACKEND_CONTRACT.md); revisar presencia real, no copiar la de Tira |
| Duelo fantasma, después de Trivia | Integración/ensayo competitivo móvil pendientes | [Base](GHOST_DUEL.md), contrato compartido de Trivia; récord propio limpio, no rival humano ficticio |
| Tira y afloja, después de Duelo | Integración/ensayo competitivo móvil pendientes | [Contrato](TUG_OF_WAR_BACKEND_CONTRACT.md); dos participantes reales de prueba, Socket.IO, reloj y presencia |
| Memoria IC-2 / Batallas IC-3 | Competición NO_DISPONIBLE hasta implementar y validar | Seguir roadmap: contratos autoritativos/ledger, no inventar integración por ver el juego normal |

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

## 6. Guion por juego y evidencia después de CADA checkpoint

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
- Actualizar el bloque vivo del roadmap y enlace al acta. Si terminó un juego,
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
Dar al propietario ruta, archivos, hash y comandos `git push origin main` en
ambos repos. Push solo cuando se acuerde. No git add . ni incluir .env/temporales.
Mientras un checkpoint está a medias, es válido publicar documentación de progreso
autorizada para relevo, dejando claro que el juego **no está cerrado**.

Cierre del entorno mediante `control.json` propio con `{"action":"stop"}` y esperar
`Owned local ranking API and PostgreSQL removed.`; detener panel propio y retirar
solo reverse `43187`. Confirmar limpieza; si supervisor fue matado, no asumirla.
No `docker system prune`, no borrar repos/carpetas amplias. No cerrar el entorno
antes de guardar evidencia ni tocar el del compañero. El siguiente PC crea otro.

## 8. Prompt copiable para el compañero / otro chat

```text
Continúa SaberPlus desde el checkpoint vigente, no desde el historial del chat.
Tengo los dos repositorios (Flutter saber_plus y SaberPlus-Backend con backend/admin).
Verifica rutas, main, git status/HEAD y cambios recibidos. Preserva trabajo ajeno.
Lee AGENTS si existe, README de ambos, docs/ETAPAS_PENDIENTES (bloque Checkpoint
de relevo de pruebas), docs/RELEVO_PRUEBAS_LOCALES, PROMPT_RELEVO,
ARQUITECTURA_Y_ESTRUCTURA, acta del juego activo y sus contratos/código/tests.
Audita el flujo afectado y nuevos cambios antes de continuar. No rehagas motores.

Decide el siguiente paso desde el roadmap ACTUAL: inicialmente era IC-1C Rescate,
pero si ya avanzaron, respeta el último checkpoint. Cima y Guardián tienen pruebas
locales reales registradas: no repetir todo salvo regresión concreta. Memoria y
Batallas requieren IC-2/3; no están listas competitivamente por existir como juegos.

Usa Docker LOCAL Linux y el harness backend/tool/local_ranking_validation.mjs.
Prepara dependencias/compilación según manifests; no uses .env, Supabase ni Render.
El harness crea base propia, API loopback43187 y credenciales ficticias nuevas.
Confirma propiedad del contenedor/nonce. No copies sesión/contraseña/balances del
PC anterior. Unitarias no requieren contraseña; integración opt-in usa archivo
privado de esa sesión. Nunca imprimir secretos ni incluirlos en Git/APK.

Pídeme conectar Android por USB con cable de datos, depuración/instalar USB,
autorización y pantalla encendida/desbloqueada. Confirma adb device, reverse43187,
APK separada .i2validation y Success sin reemplazar la app habitual. Mantén
terminales/harness abiertos, recuerda plazo2h y nueva autenticación si recreas base.

Si el cliente competitivo pendiente aún no existe, implementa primero de forma
acotada con contrato vigente y tests; no intentar validar el juego normal como
competitivo. Prueba un checkpoint físico cada vez conmigo. Presencia/reloj/rivales
según juego, no copies protocolo de otro. XP solo desde verificador/ledger real;
fixtures de Trivia no son partidas verificadas. Si falta decisión/segundo rival,
pregúntame; no fabricar resultados. No cambies fórmulas, arte/sonidos ni anuncios.

Después de CADA checkpoint registra acción, resultado humano/HTTP/SQL por separado,
estado, límites y siguiente paso exacto en acta del juego y bloque vivo del roadmap.
Al finalizar actualiza README/relevo/prompt/índice/historial y espejo backend.
Registra pass/skip/fail y lo no probado; verifica enlaces/diff. No cierres toda
IC-1 ni producción. Un commit por juego autorizado tras pruebas/documentación;
revisa staged y da ruta/hash/comando push por repo. No push, deploy, reset ni
force-push automáticos. Si interrumpimos, deja checkpoint claro y cierre seguro
del entorno propio; mi compañero seguirá desde ese bloque y no tendrá este chat.
```
