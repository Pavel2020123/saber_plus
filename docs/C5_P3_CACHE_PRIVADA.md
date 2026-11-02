# C5-P3 — caché privada de lecciones (Android, validación local)

1/nov/2026. Continuación de [P3-A](C5_P3A_POLITICA_72H.md). Implementación incremental, separada de PDF, diagnóstico, práctica y juegos. No implica despliegue ni activación en producción.

## Alcance y acceso

En una lección, la acción de acceso privado abre `PrivateLessonPage`. Está disponible únicamente en Android, entorno `dev`, sin demo y con `--dart-define=PRIVATE_OFFLINE_ENABLED=true`. El backend exige además `EDITORIAL_PRIVATE_OFFLINE_LOCAL_ENABLED=true`, archivos editoriales activos y entorno test/development. Por defecto permanece apagado; no se habilita en producción con una variable aislada.

Se conserva una copia exacta del título, texto e imagen gestionada de una lección publicada. Las imágenes externas heredadas y contenidos que exceden los límites requieren consulta online. No se descargan respuestas, claves ni contenido de otros módulos. El lector usa texto y píxeles propios, sin caché global de imágenes ni URLs arbitrarias.

## Contrato de permisos y tiempo

`POST /recursos/editoriales/lecciones/:id/offline` recibe solo un nonce de intento. Propietario derivado del JWT, cuenta/correo/publicación y recursos comprobados por el servidor; nueva comprobación antes de responder. Manifiesto v1 con contexto, SHA-256 de la copia y de la imagen, validación UTC del servidor y vencimiento exactamente 72 horas después. No se toma un login o ping como renovación.

La duración efectiva del dispositivo se ancla al inicio de la solicitud con `SystemClock.elapsedRealtime()`: incluye suspensión y no consulta la hora calendario. Es conservadora ante latencia. Tanto Dart como Android rechazan retrocesos, discontinuidad de arranque y vencimiento exacto. Al reiniciar el dispositivo se exige conexión; no se reconstruye continuidad con la fecha manual. No se esperaron 72 horas reales para las pruebas de frontera.

Una lectura o error de conexión/503 no renueva el plazo. 401/403 bloquean la cuenta; 404/409/410 bloquean el contexto. La denegación retira el texto/píxeles antes de esperar la limpieza. Respuestas y escrituras tardías no pueden reabrir una sesión anterior. Una validación nueva y autorizada sí puede recuperar el acceso.

El lector retira contenido al pasar a segundo plano, al vencer y al cambiar permisos/cuenta. Al volver a primer plano o recibir notificación Android de red disponible, revalida antes de mostrarlo. Sin conexión, solo admite el paquete todavía válido. El arranque de sesión sin red no se amplió: si la autenticación existente no puede restaurarse, falla cerrado y pide conexión. No es una biblioteca offline con login independiente.

## Protección local

- AES-256-GCM con Android Keystore; claves no exportadas por la app, una por cuenta. No se promete respaldo hardware en todos los dispositivos ni protección frente a un sistema rooteado comprometido.
- Paquetes autenticados, AAD de cuenta/contexto, metadatos temporales cifrados y publicación mediante `AtomicFile`.
- Directorio privado `noBackupFilesDir/private_offline_v1`; sin JWT dentro del paquete. Los nombres hash no son la medida de confidencialidad: lo es el cifrado autenticado.
- Límite 4 MiB por paquete, imagen 2 MiB, texto 128 KiB, título 2 KiB; máximo global 32 paquetes/64 MiB. Si se llena, falla la escritura; no elimina PDFs ni hace una expulsión silenciosa.
- Logout/cambio de cuenta elimina la clave anterior y sus archivos. Si falla el borrado físico, la clave retirada impide descifrarlos. Fallos de limpieza no vuelven a habilitar lectura en memoria.
- Los PDF exportados continúan bajo su contrato separado: no se revocan ni se borran mediante esta caché.

## Pruebas y reproducción

Pruebas permanentes: `test/private_lesson_cache_test.dart`, `test/private_offline_access_policy_test.dart`, `integration_test/private_offline_vault_test.dart`, `test_driver/integration_test.dart` y `PrivateOfflineLeaseTest.kt`. El driver existe solo en el entrypoint de pruebas, no en `main.dart`.

Las pruebas HTTP y Android integradas solo utilizan PostgreSQL desechable propio y cuentas sintéticas. La configuración con contraseñas se genera en un directorio temporal y nunca se añade al repositorio. El caso HTTP del dispositivo requiere `P3_LOCAL_OWNED_TEST=true` y una API loopback exacta; sin configuración se omite explícitamente, no se cuenta como aprobado.

Resultados confirmados: **98/98 SQL/HTTP/PostgreSQL** (incluido navegador Chromium), **14/14 unidades backend**, **44/44 Flutter** (caché/política y regresión PDF/descargas), análisis Dart y ESLint dirigidos sin incidencias; `npx nest build` aprobado. El intento de regenerar Prisma con APIs abiertas encontró un bloqueo DLL de Windows: no hubo cambio de esquema ni se atribuye esa regeneración fallida a un build aprobado.

**Android USB: cinco escenarios aprobados**, no seis: el contador adicional del runner corresponde a `tearDownAll`. Validación HTTP real con JWT, imagen gestionada, fallo real de conexión a puerto local sin listener, lectura cifrada aún válida, revocación ADMIN por API y retirada del texto/paquete; inspección de ciphertext sin texto claro, alteración del archivo, copia a otro contexto, aislamiento de cuenta/contexto, rechazo de arranque ajeno/ancla futura, borrado por contexto/cuenta y nueva clave después del borrado. No se modificó la hora del celular ni se esperaron72h: las fronteras temporales y reinicio simulado se prueban con muestras controladas; no equivalen a un reinicio físico cronometrado.

La APK de integración contiene únicamente credenciales sintéticas temporales: no se distribuye ni se confunde con el APK normal. Al finalizar se recompila el entrypoint normal con configuración pública y se reinstala solo `com.example.saber_plus.i2validation`; la app normal permanece intacta. Quedan por registrar las unidades Kotlin y la reinstalación final.

## Límites de esta entrega

No se implementa el modelo de suspensión institucional propuesto en #14: se respetan las denegaciones reales del backend existente, sin inventar campos ni estados. Tampoco se cambian autenticación offline al arrancar, proveedor remoto de archivos, licencias, PDF exportados o arquitectura de otros lectores. Antes de producción faltan integración por PR, revisión de seguridad/operación y activación controlada correspondiente.
