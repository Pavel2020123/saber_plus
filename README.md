# SaberPlus móvil

Aplicación Flutter para la experiencia móvil de SaberPlus. El proyecto se está construyendo por etapas a partir del informe técnico de migración.

## Ejecutar la etapa actual

```powershell
flutter pub get
flutter run
```

La aplicación inicia en modo demostración para poder revisar navegación y diseño sin enviar credenciales a un servidor.

El contrato auditado contra el backend existente está documentado en [docs/AUTH_CONTRACT.md](docs/AUTH_CONTRACT.md).
El contrato de convocatoria, diagnóstico y plan semanal está en [docs/ACADEMIC_CONTRACT.md](docs/ACADEMIC_CONTRACT.md).

## Configuración por ambiente

```powershell
flutter run --dart-define=APP_ENV=dev --dart-define=API_BASE_URL=http://10.0.2.2:3000 --dart-define=DEMO_MODE=true
```

- `APP_ENV`: `dev`, `staging` o `prod`.
- `API_BASE_URL`: raíz del backend NestJS, sin `/v1`.
- `DEMO_MODE`: habilita los accesos demostrativos mientras se conecta autenticación real.

## Calidad

```powershell
flutter analyze
flutter test
```

## Validación real de autenticación

Con el backend, PostgreSQL y sus migraciones ejecutándose, se puede validar el flujo completo y el repositorio Dart de Flutter:

```powershell
.\tool\verify_auth_api.ps1 `
  -ApiBaseUrl http://127.0.0.1:3000 `
  -DatabaseUrl "postgresql://usuario:clave@127.0.0.1:5432/base?schema=public"
```

El script crea una cuenta E2E única. Debe ejecutarse solamente contra una base de desarrollo o pruebas, ya que consulta los tokens de verificación y recuperación directamente en PostgreSQL.

Consulta el avance y las siguientes entregas en [docs/ROADMAP_MOVIL.md](docs/ROADMAP_MOVIL.md).
