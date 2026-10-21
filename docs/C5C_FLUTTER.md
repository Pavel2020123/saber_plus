# C5-C1 — Lectura de imágenes editoriales en Flutter

## Checkpoint del 20 de octubre de 2026

**Implementación online y controles automáticos locales aprobados; ensayo Android pendiente.**
Rama `feat/c5-archivos-base` en los dos repositorios. No se hizo commit, push,
merge, despliegue ni SQL remoto. OV-1 del compañero no se modificó.
Contrato global: [C5 — archivos](C5_ARCHIVOS.md). Antecedente: [panel C5-B](C5B_PANEL.md).

C1 es una subdivisión de C5-C, no el cierre de toda C5. El siguiente paso
inmediato es la revisión física descrita debajo. Después continúan imágenes
en opciones, PDF/offline, autorización histórica y fotos/evidencias con contratos
propios; finalmente C5-D y proveedor persistente autorizado.

## Implementación

- `lib/core/media/editorial_image_reference.dart`: referencia relativa UUID4
  estricta `/recursos/editoriales/:id`. No acepta URLs externas, query, fragmento
  ni rutas ADMIN como referencias autenticadas.
- `remote_editorial_image_repository.dart`: usa el cliente Dio y la sesión
  existentes, sin redirecciones, respuesta WEBP y máximo2 MiB comprobado también
  mientras recibe el stream. Plazo total30 segundos y cierre del transporte al
  terminar o rechazar una descarga. No descarga contenido arbitrario con Bearer.
- `lib/core/widgets/academic_image.dart`: carga, error legible y reintento
  explícito, sin recortar ni estirar la imagen. Comprueba dimensiones hasta2560
  por2560 y una sola imagen estática antes de mostrarla.
- Las imágenes gestionadas se decodifican a `ui.Image` y usan `RawImage`:
  no se introducen en ImageCache global ni en disco. El proveedor autoDispose
  cancela solicitudes y libera la imagen; logout/cambio de cuenta invalida
  respuestas y evita mostrar los datos anteriores durante una recarga.
  La copia de render se libera cuando sale el widget.
- Los enlaces públicos anteriores conservan su ruta de recursos y nunca reciben
  los headers de sesión. HTTPS obligatorio fuera de desarrollo.
- Consumidores migrados: lección y Markdown, práctica/caso, diagnóstico, batallas,
  Guardián, Cima, Rescate y Tira y afloja. Trivia Rush y Fantasma ahora muestran
  imagen y contexto recibidos del contrato existente, sin duplicar la misma figura.
  No se cambiaron puntuaciones, respuestas, tiempos, XP ni reglas competitivas.

El estado de error avisa que no se debe contestar sin el contexto visual.
No promete recuperar imágenes históricas todavía: la ruta del backend sigue
exigiendo uso publicado, según B. Una pregunta archivada puede necesitar otro
contrato de autorización para su intento anterior; eso queda pendiente en C5-C.

## Validación automática realizada

- `flutter analyze --no-pub`: aprobado antes de la comprobación final.
- **30/30 controles nuevos** en `test/editorial_image_test.dart`: contrato,
  sesión, MIME/firma/límites, HTTP302/401/403/404/503, exceso durante streaming,
  cambio de sesión, proporción120×60, ausencia de ImageCache privado, reintento
  y retirada de la imagen al cerrar sesión. Son pruebas de repositorio/widget,
  no gestos de un Android físico.
- **3/3 pruebas Flutter VM ↔ HTTP ↔ PostgreSQL real** en
  `test/editorial_image_local_api_test.dart`: práctica entrega la referencia,
  descarga/decodificación WEBP120×60, recurso sin publicar404 y anónimo401
  (lectura publicada y decodificación forman el primer caso).
- **20/20 controles Node** del entorno local repetidos y aprobados.
- Regresión completa Flutter: **950 aprobadas/13 opt-in omitidas**, sin fallos.
  La nueva suite opt-in C1 se añadió durante ese recorrido y se comprobó después
  por separado3/3 con API real. Sin variable de sesión se verificó su omisión3/3.
- Comprobación final dirigida tras el ajuste que evita duplicar la imagen de
  contexto en Trivia: **32 aprobadas/3 opt-in omitidas** (30 C1 y2 Trivia).
- Análisis final sin incidencias. **APK debug compilada correctamente** con
  los cuatro defines públicos del comando inferior, sin credenciales de pruebas
  en la configuración de compilación final. No instalada ni validada en Android.
  Gradle avisa de compatibilidad futura de flutter_timezone/KGP; no bloqueó el
  build ni se actualizaron dependencias por este aviso.

La primera ejecución dirigida apuntó a un nombre de suite inexistente; los53
casos existentes pasaron, pero ese comando no se considera una regresión aprobada.
Se lanzó después la regresión completa. La primera prueba HTTP de C1 detectó el
HttpClient simulado por el widget binding; el ensayo opt-in ahora deliberadamente
no crea ese binding y sí accede a la API loopback real.
El control de exceso detectó que cancelar solo el stream de salida no bastaba
para cerrar la fuente HTTP de Dio; se corrigió cancelando el token propio de
cada descarga y se repitió la suite30/30.

## Entorno local y reproducción

Se reutiliza `backend/tool/local_ranking_validation.mjs`, que crea una base
Docker local propia y desechable y una API completa en `127.0.0.1:43187`.
Su allowlist incorpora explícitamente las dos migraciones nuevas C5-A/B;
se aplicaron69 migraciones únicamente a esa base temporal. La bandera de
archivos se activa solo dentro del proceso local de pruebas. No lee `.env`.
El panel real usa `http://127.0.0.1:4173` y esa API, no el modo DEMO.

Nuevo preparador `backend/tool/prepare_editorial_images_local.mjs`:
verifica ruta temporal, marcador, URL loopback, contexto Docker local y etiqueta
del contenedor. Crea por las APIs reales del panel un rectángulo sintético,
una lección y una pregunta publicadas; deja otra imagen sin asociar.
No copia contenido académico real ni asigna XP. Un manifiesto con el nonce
evita duplicar los datos al repetirlo en la misma sesión.

Desde `SaberPlus-Backend/backend`, después de levantar el ejecutor:

```powershell
# Usar exactamente el directorio que informó el ejecutor de ESTA sesión.
$env:SABERPLUS_LOCAL_SESSION = 'DIRECTORIO_TEMPORAL_PROPIO'
node tool/prepare_editorial_images_local.mjs
```

Desde `saber_plus`, con la misma variable de entorno:

```powershell
flutter test test/editorial_image_local_api_test.dart --no-pub
```

Sin variable local, los3 casos se omiten expresamente. Nunca introducir una URL
remota o una contraseña como argumento. La suite usa una cuenta ficticia
separada (`absent@example.invalid`), no la del alumno del ensayo humano.
El manifiesto `editorial-images-fixture.json` y las credenciales están solo en
el directorio temporal, fuera de Git. La sesión tiene límite de dos horas:
si finaliza, levantar otra y preparar nuevamente el fixture, sin reutilizar claves.

Para compilar una APK local, usar solo configuración pública, no incluir
`AUTH_E2E_PASSWORD` ni todo el archivo privado de pruebas en los defines:

```powershell
flutter build apk --debug --no-pub --dart-define=APP_ENV=dev --dart-define=DEMO_MODE=false --dart-define=API_BASE_URL=http://127.0.0.1:43187 --dart-define=CONTENT_BASE_URL=http://127.0.0.1:43187
```

Es APK de ensayo local, no una versión lista para tienda. Con celular por USB,
se necesita `adb reverse tcp:43187 tcp:43187` para acceder a loopback del PC.
Instalar después de avisar al propietario; no confundir la instalación con la
confirmación humana de los cinco casos.

## Cinco comprobaciones Android pendientes

1. Entrar con el alumno ficticio de la sesión; Estudiar → Matemáticas →
   tema «Imágenes C5 - ensayo …» → «Rectángulos y proporciones».
   Ver el rectángulo horizontal2:1 y el texto, sin recorte ni estiramiento.
2. Practicar ese subtema: ver la misma figura y responder «2 veces».
   Confirmar feedback y explicación normales; no cambiar reglas ni premiar fixtures.
3. Abrir de nuevo la pantalla sin conexión al PC/API: aviso visible, sin figura
   de otra pantalla; restaurar conexión y pulsar Reintentar imagen.
   No exigir reiniciar la app. Registrar exactamente cómo se cortó y restauró.
4. Cerrar sesión: no debe quedar la imagen privada visible. Entrar en demo
   no debe habilitar la descarga privada. Volver a la cuenta de ensayo recupera
   la figura desde la API, sin reutilizar un token anterior.
5. Salir/volver y reabrir la lección con API activa: proporción conservada,
   controles legibles con texto grande y sin desbordes. Esto no valida un
   reinicio/despliegue remoto ni almacenamiento productivo.

Estado humano actual: **0/5**, no realizados en esta entrega.
Los juegos migrados tienen regresión automatizada, pero este guion acotado no
los certifica uno a uno en Android. Ampliar su recorrido en integración C5-D.

## Pendientes de C5

- Imágenes en opciones: modelo Respuesta, relaciones, DTO/panel, snapshots y todos
  los consumidores sin revelar la correcta ni romper intentos guardados.
- PDF/offline, derechos/retención del archivo descargado y autorización de imágenes
  en intentos históricos. No guardar bytes privados globalmente por este bloque.
- Fotos de perfil y evidencias institucionales privadas, con límites y permisos
  propios; nunca reutilizar una imagen editorial publicada para evidencia privada.
- Biblioteca, limpieza/huérfanos, cuotas, respaldos, proveedor persistente y operación.
- Conciliar archivos compartidos con OV-1 antes de PR/merge. CI remoto y despliegue
  permanecen pendientes. Mantener separados implementación, automático y humano.
