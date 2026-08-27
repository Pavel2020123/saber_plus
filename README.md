# SaberPlus móvil

Aplicación Flutter para la experiencia móvil de SaberPlus. El proyecto se está construyendo por etapas a partir del informe técnico de migración.

## Ejecutar la etapa actual

```powershell
flutter pub get
flutter run
```

La aplicación inicia en modo demostración para poder revisar navegación y diseño sin enviar credenciales a un servidor.

El contrato auditado contra el backend existente está documentado en [docs/AUTH_CONTRACT.md](docs/AUTH_CONTRACT.md).

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

Consulta el avance y las siguientes entregas en [docs/ROADMAP_MOVIL.md](docs/ROADMAP_MOVIL.md).
