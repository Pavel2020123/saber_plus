# 7F-B3-A — Flutter conectado al servidor de staging

## Entrega terminada

- Perfil compartido `config/staging.json`: API y recursos HTTPS de Render,
  `APP_ENV=staging` y `DEMO_MODE=false`. Solo contiene configuración pública.
- Dos opciones de ejecución en VS Code: demostración local y staging real.
- En el ingreso de staging aparece **Comprobar conexión**. Consulta la salud de
  la API, el acceso a PostgreSQL reportado por el servidor y el rechazo de un
  perfil sin token. No usa el cliente autenticado ni modifica la sesión local.
- La comprobación se cancela al cerrar la ventana. No reintenta automáticamente
  ni sigue redirecciones; tampoco muestra respuestas privadas o trazas recibidas.
- Staging y producción rechazan modo demo, URLs con credenciales, consultas o
  fragmentos, y esquemas distintos de HTTPS. Desarrollo admite HTTP/HTTPS. Un
  `APP_ENV` mal escrito genera un error en lugar de caer silenciosamente en dev.

## Ejecutar en Android o iOS

Desde la carpeta Flutter:

```powershell
cd "C:\Users\LENOVO 14ALC6\Desktop\SaberPLus\saber_plus"
flutter run --dart-define-from-file=config/staging.json
```

También puedes elegir **SaberPlus — staging real (Render)** en Ejecutar y depurar
de VS Code. Selecciona un dispositivo Android; para iOS se necesita un equipo
macOS con las herramientas correspondientes. No se añaden plataformas desktop.

Detén la ejecución anterior antes de cambiar de perfil. Los `dart-define` son
valores de compilación: hot reload no cambia de servidor.

1. Entra a la pantalla de ingreso.
2. Comprueba que diga **STAGING · servidor de pruebas, sin datos demo**.
3. Pulsa **Comprobar conexión**. Si Render estaba suspendido, el primer paso
   puede tardar hasta un minuto. Puedes cancelar o volver a comprobar manualmente.
4. Cierra la comprobación e inicia sesión con una cuenta de ensayo existente y
   verificada. Introduce sus credenciales únicamente en el formulario de la app.

No cambies las credenciales de Supabase ni las variables de Render para usar
este perfil. Si el dominio del servicio cambia, actualiza las dos URLs públicas
del JSON y vuelve a compilar. `CONTENT_BASE_URL` no sube imágenes por sí solo:
los archivos deben existir en una ubicación accesible para la API.

Para volver a la demostración:

```powershell
flutter run --dart-define=APP_ENV=dev --dart-define=DEMO_MODE=true
```

## Prueba automatizada contra el servidor (solo lectura)

```powershell
flutter test --no-pub test/staging_connection_live_test.dart --dart-define-from-file=config/staging.json --dart-define=RUN_STAGING_SMOKE=true
```

Esta prueba es optativa; una ejecución normal de `flutter test` la omite.
Usa el perfil compilado de Flutter y hace exclusivamente estas solicitudes:

| Solicitud | Resultado exigido |
| --- | --- |
| `GET /health/live` | HTTP 200, servicio `saberplus-api`, estado `OK` |
| `GET /health/ready` | Lo anterior más `database: UP` |
| `GET /auth/perfil`, sin token | HTTP 401 |

La comprobación contra `https://saberplus-api-staging.onrender.com` pasó durante
esta entrega. No se crearon usuarios, preguntas, intentos ni registros de
progreso. No se aplicaron migraciones ni se redesplegó Render.

**Esto no equivale a verificar el esquema completo ni todos los módulos.**
`/health/ready` ejecuta una consulta básica, no comprueba las migraciones. En
particular, el módulo guardián sigue necesitando su despliegue y migración.

No uses `tool/verify_auth_api.ps1` como alternativa de solo lectura: ese script
anterior registra cuentas, cambia contraseñas y consulta la base directamente.
Aquí no se ha ejecutado.

## 7F-B3-B — Validación integral aún pendiente

La conexión pública quedó probada. Para cerrar la integración completa falta:

- Cuenta de ensayo verificada de estudiante y de profesor, sin datos personales
  reales de alumnos. No guardar contraseñas/tokens en Git, JSON ni `dart-define`.
- Inicio y cierre de sesión, restauración y navegación real desde un teléfono.
- Convocatoria y contenido académico autorizado publicados por área/tema/subtema.
- Prueba de diagnóstico, práctica, progreso y recursos con esas cuentas.
- Revisión de migraciones pendientes y despliegue de los módulos nuevos.
- Recuperación de conexión en teléfono y prueba de dos clientes en multijugador.

Mientras se prepara ese contenido, la siguiente etapa de desarrollo es
**7F-C2-B: catálogo administrable por áreas, temas y subtemas**, seguida del
panel privado 7F-C3. En esta entrega no se cargó contenido en la base.

## Commit de esta entrega (solo Flutter)

Verificación local: **55 pruebas aprobadas** de configuración, comprobación,
sesión, cabeceras y navegación; **una prueba adicional contra staging real
aprobada** con el perfil compilado. El análisis de los siete archivos Dart
modificados/nuevos no reportó problemas. No se ejecutó una compilación iOS ni
una prueba manual en teléfono en esta entrega.

```powershell
git add .vscode/launch.json config/staging.json lib/core/config/environment.dart lib/core/network/staging_connection_probe.dart lib/features/auth/presentation/login_page.dart lib/features/auth/presentation/staging_connection_sheet.dart test/environment_test.dart test/staging_connection_probe_test.dart test/staging_connection_live_test.dart README.md docs/ROADMAP_MOVIL.md docs/FLUTTER_STAGING_CONNECTION.md
git commit -m "feat: configurar y verificar conexion Flutter staging"
```

Los cambios pendientes del guardián en el repositorio backend pertenecen a la
entrega anterior; esta etapa no los modifica ni los confirma automáticamente.
