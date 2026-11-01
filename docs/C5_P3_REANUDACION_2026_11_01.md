# C5-P3 — sesión local reanudada el 1 de noviembre de 2026

H3 y PDF P1/P2 conservan sus evidencias, no se reinician. App HEAD `a309438`, backend HEAD `fb5f18f`; cambios anteriores ajenos conservados en ambos worktrees. Sin push, merge a main ni despliegue.

## Servicios comprobados

- Docker Linux activo; PostgreSQL16 propio `saberplus-i2-local-9e3e556f26819ec2`, base tmpfs nueva con 78 migraciones.
- Runner existente `backend/tool/local_ranking_validation.mjs`, opciones/históricos activados solo en esta sesión sintética. Directorio temporal `saberplus-i2-local-I2r12y`.
- `npm run build` completo aprobado, incluida regeneración Prisma y compilación Nest. La API usa el backend actual de P2, no el proceso antiguo de la jornada anterior.
- API `http://127.0.0.1:43187`: login sintético HTTP 201. Panel `http://127.0.0.1:4173`: HTTP 200, conectado a esta API, no modo demo.
- Android `mn7tqwg6ozcy9d85` autorizado; reverse 43187→43187 comprobado. Se conservan app normal y `com.example.saber_plus.i2validation`; no se reinstaló por levantar servicios.
- Repetición nueva en copia limpia del commit `a309438`:14/14 Flutter PDF/descargas/errores aprobadas. No se repitieron como requisito las95 SQL/HTTP de P2; siguen siendo evidencia de la jornada anterior.

Credenciales únicamente en `flutter-private.json` de la sesión nueva, nunca en Git/chat. La configuración pública del APK ya apunta al mismo puerto local; no compilar con el archivo privado. Si había una sesión antigua en la app, debe iniciarse sesión de nuevo: JWT, cuentas y UUID anteriores no corresponden a esta base nueva.

El runner caduca a las dos horas o al terminar su proceso. No presentar este entorno como persistente ni esperar que contenga las cinco respuestas o la lección PDF revocada de la sesión anterior. El fixture de ranking incluido por el runner es sintético; no se acredita como partida jugada.

## Continuación

Sigue **P3-A: contrato de caché privada**, separado de PDF exportable, con manifiesto/versiones, aislamiento por cuenta y revalidación al reconectar. [Borrador backend](<../../../SaberPlus-Backend/backend/docs/C5_P3A_CONTRATO_CACHE_PRIVADA.md>). No se activa persistencia de imágenes privadas ni se inventa un plazo de conservación mientras esa decisión esté abierta.
