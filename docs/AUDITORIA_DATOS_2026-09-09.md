# Auditoría focalizada: sesión, red y persistencia móvil

Fecha: 9 de septiembre de 2026. Complementa el informe general; no certifica seguridad absoluta ni sustituye las pruebas de staging y de dispositivos reales.

## Hallazgos corregidos

| Prioridad | Riesgo comprobado | Corrección |
| --- | --- | --- |
| Alta | Un login, restauración o actualización de perfil tardía podía reabrir una cuenta después de salir o sustituir la demostración. | Generación de sesión, comprobaciones después de cada espera y descarte después de dispose. Las escrituras del almacén seguro se ejecutan en orden; logout borra después de una escritura nativa ya iniciada. |
| Alta | Una solicitud iniciada por A podía tomar el token de B antes de que arrancara el primer interceptor o mientras se leía el identificador del dispositivo. | `SessionDio.fetch` captura la revisión sincrónicamente. El interceptor cancela solicitudes/respuestas de revisiones anteriores; conserva una revisión explícita enviada por la cola. |
| Alta | El cliente de API podía enviar datos o credenciales a una URL absoluta ajena o seguir una redirección. | Comprobación de esquema, host y puerto, rechazo de credenciales embebidas y redirecciones deshabilitadas, tanto en el cliente público como en el autenticado. |
| Alta | Confirmar o rechazar una operación en vuelo podía borrar o bloquear una edición local posterior. | Borrado y actualización condicionales de SQLite (comparar y modificar): identidad, revisión, contenido y estado deben seguir coincidiendo. Una edición nueva permanece pendiente. |
| Alta | La sincronización de la cola de A podía continuar con la sesión B. | Instantánea de usuario/revisión antes de consultar SQLite y validación antes y después de la red. Sin sesión, con otra cuenta o tras cancelación, se conserva la cola para su dueño. |
| Media | Descartar y recrear el mismo texto mientras llegaba una respuesta antigua podía confirmar equivocadamente la nueva fila (caso ABA). | Cada edición genera una revisión aleatoria de 128 bits; no depende de la precisión en segundos de las fechas de SQLite. |
| Media | Tras fallar la persistencia del identificador del dispositivo, el valor quedaba únicamente en memoria y no se reintentaba guardarlo. | Solo se cachea tras una escritura correcta; se mantienen la exclusión de solicitudes simultáneas y las pruebas sin plugins. |
| Baja | Retornos de Futures dentro de bloques try dificultaban el flujo de errores y producían advertencias del analizador. | Esperas explícitas en repositorios institucionales, conservando sus contratos y pruebas. |

## Migración local

El esquema Drift pasa de **7 a 8** y añade únicamente `pending_operations.revision`, con valor inicial vacío para las filas existentes. Las ediciones nuevas asignan una revisión distinta. Se preservan payload, estado, intentos, errores y fechas anteriores; no se borra la base ni se cambian dependencias.

La creación nueva y la actualización desde v1 crean la tabla con la columna actual. Las versiones v2 a v7 añaden la columna a la tabla existente. Se incluyó el archivo generado correspondiente, `app_database.g.dart`.

Esta es una migración de SQLite del dispositivo, **no una migración de Supabase**. No se ejecutaron comandos contra bases remotas ni se modificaron credenciales.

## Verificación realizada

Resultado final: **61 pruebas aprobadas, 0 fallidas**, en estos ocho archivos:

- `test/safe_sync_repository_test.dart`: confirmación/rechazo tardío, edición concurrente, ABA, máximo de progreso, independencia de cuentas, cancelación y reintento.
- `test/auth_interceptor_test.dart`: origen público/privado, redirecciones, limpieza de Authorization, respuestas antiguas, inicio A→B antes de interceptores, espera del dispositivo y revisión explícita.
- `test/session_controller_test.dart`: login/logout, restauración/demo, refresh tardío, orden de escrituras, dispose y errores del almacén.
- `test/device_session_security_test.dart`: identidad, concurrencia, errores y eventos de conflicto.
- `test/app_database_migration_test.dart`: v1 y cada versión v2…v7→v8 en archivos temporales aislados, preservación y comparación condicional tras migrar.
- `test/remote_auth_repository_test.dart`.
- `test/teacher_institution_test.dart`.
- `test/institution_groups_test.dart`.

Comando reproducible desde la raíz Flutter:

```powershell
flutter test --no-pub --reporter expanded test/safe_sync_repository_test.dart test/auth_interceptor_test.dart test/session_controller_test.dart test/device_session_security_test.dart test/app_database_migration_test.dart test/remote_auth_repository_test.dart test/teacher_institution_test.dart test/institution_groups_test.dart
```

También se aplicó `dart format` a los archivos de este ámbito y `git diff --check` terminó sin errores. El análisis y las pruebas globales se registran por separado en el informe principal.

## Límites y pendientes

- La protección local no implementa por sí sola la revocación del JWT ni la sesión única autoritativa en el servidor. Se necesitan contratos y pruebas reales de reemplazo/revocación, incluida recuperación de contraseña.
- Si Keychain/Keystore rechaza borrar una credencial, se invalida la memoria y logout muestra una advertencia, pero no se puede garantizar el borrado físico hasta que responda el sistema. La revocación remota sigue siendo importante.
- Un servidor puede haber aplicado una escritura antes de perderse la conexión o cambiar la sesión. Se conserva la operación; solo se reenvían los dos tipos idempotentes existentes: progreso y cambios del cuaderno. Esto no habilita reintentos automáticos de respuestas de examen, compras o premios.
- La cola no sincroniza todas las herramientas locales de la app. Favoritos, marcas, tiempo y otros datos requieren sus contratos de sincronización si deben recuperarse en otro equipo.
- SQLite no se convirtió en una base cifrada en esta auditoría. La separación por usuario y el almacenamiento privado no equivalen a cifrado contra un dispositivo comprometido.
- `SessionDio` utiliza el adaptador nativo conservando las descargas de Dio, acorde con Android/iOS. Si se retoma una compilación Flutter Web, deberá añadirse una variante de cliente para navegador; no es una plataforma de publicación de este proyecto.
- No se hicieron llamadas reales de autenticación ni pruebas remotas, y D3 continúa pendiente.
