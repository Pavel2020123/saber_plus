# COMMITS RECOMENDADOS

Guia preparada, **no ejecutada**. No hay autorizacion de commit: ejecutar estos bloques solamente cuando el propietario la conceda. No se hizo git add ni commit. Los mensajes y comandos se entregan para reproducir la separacion; no incluyen push.

Rutas reales comprobadas con Get-Location en ambos repositorios. HEAD Flutter: cf6e59d92142946416e4658ca9f9bed2b1704837; Backend: 52abde26a5f4f4e5b87e567ee8fdc69edca9abe4. Indices vacios al cierre.

Los bloques son secuenciales por repositorio: las ramas nuevas propuestas quedan apiladas sobre el commit anterior, no son PR independientes sobre main. No se cambiaron ramas durante esta ronda. Todos los cambios pendientes permanecen en el arbol actual y se seleccionan por archivo. Si el indice deja de estar vacio antes de un bloque, detenerse y revisar lo que otra persona preparo; no hacer unstage/reset automatico. No usar git add . ni git commit -a.

## 1. fix: sincronizar lockfile reproducible del backend

- Repositorio: SaberPlus Backend.
- Direccion local real: `C:\Users\luisk\Desktop\SaberPlus-Backend`.
- Rama actual comprobada: `fix/backend-lockfile-ci`.
- Rama recomendada: `fix/backend-lockfile-ci`. Ya existe; no recrearla.
- Tipo: `fix`.
- Estado: **LISTO PARA COMMIT LOCAL**, sujeto a autorizacion; no listo para deploy por ese hecho.

Archivos exactos que entrarian:

```text
backend/package-lock.json
```

Comandos PowerShell, solo tras autorizacion:

```powershell
Set-Location -LiteralPath "C:\Users\luisk\Desktop\SaberPlus-Backend"
Get-Location
git status
git branch --show-current
git diff --cached --name-only
git switch fix/backend-lockfile-ci
git add -- "backend/package-lock.json"
git diff --cached
git commit -m "fix: sincronizar lockfile reproducible del backend"
git status
git log -1 --oneline
```

## 2. fix(security): evitar datos privados en Tira y afloja

- Repositorio: SaberPlus Backend.
- Direccion local real: `C:\Users\luisk\Desktop\SaberPlus-Backend`.
- Rama actual comprobada: `fix/backend-lockfile-ci`.
- Rama recomendada: `security/pre-pr-i1`. No existe al cierre; crear una sola vez, despues del bloque 1.
- Tipo: `fix`.
- Estado: **LISTO PARA COMMIT LOCAL**, sujeto a autorizacion; no listo para deploy por ese hecho.

Archivos exactos que entrarian:

```text
backend/src/tira-afloja/tira-afloja.service.ts
backend/src/tira-afloja/tira-afloja.gateway.ts
backend/src/tira-afloja/tira-afloja.gateway.spec.ts
backend/src/tira-afloja/tira-afloja-privacy.spec.ts
```

Comandos PowerShell, solo tras autorizacion:

```powershell
Set-Location -LiteralPath "C:\Users\luisk\Desktop\SaberPlus-Backend"
Get-Location
git status
git branch --show-current
git diff --cached --name-only
git switch -c security/pre-pr-i1
git add -- "backend/src/tira-afloja/tira-afloja.service.ts" "backend/src/tira-afloja/tira-afloja.gateway.ts" "backend/src/tira-afloja/tira-afloja.gateway.spec.ts" "backend/src/tira-afloja/tira-afloja-privacy.spec.ts"
git diff --cached
git commit -m "fix(security): evitar datos privados en Tira y afloja"
git status
git log -1 --oneline
```

## 3. fix(auth): exigir cambio de contrasena inicial en servidor

- Repositorio: SaberPlus Backend.
- Direccion local real: `C:\Users\luisk\Desktop\SaberPlus-Backend`.
- Rama actual comprobada: `fix/backend-lockfile-ci`.
- Rama recomendada: `security/pre-pr-i1`. Reutilizar la rama creada en bloque 2; NO ejecutar switch -c otra vez.
- Tipo: `fix`.
- Estado: **LISTO PARA COMMIT LOCAL**, sujeto a autorizacion; no listo para deploy por ese hecho.

Archivos exactos que entrarian:

```text
backend/src/auth/initial-password-access.ts
backend/src/auth/initial-password-access.spec.ts
backend/src/auth/jwt.guard.ts
backend/src/auth/auth.controller.ts
backend/src/auth/auth.service.ts
backend/src/auth/auth-security.service.spec.ts
backend/src/tira-afloja/tira-afloja-ws-auth.service.ts
backend/src/tira-afloja/tira-afloja-ws-auth.service.spec.ts
```

Comandos PowerShell, solo tras autorizacion:

```powershell
Set-Location -LiteralPath "C:\Users\luisk\Desktop\SaberPlus-Backend"
Get-Location
git status
git branch --show-current
git diff --cached --name-only
git switch security/pre-pr-i1
git add -- "backend/src/auth/initial-password-access.ts" "backend/src/auth/initial-password-access.spec.ts" "backend/src/auth/jwt.guard.ts" "backend/src/auth/auth.controller.ts" "backend/src/auth/auth.service.ts" "backend/src/auth/auth-security.service.spec.ts" "backend/src/tira-afloja/tira-afloja-ws-auth.service.ts" "backend/src/tira-afloja/tira-afloja-ws-auth.service.spec.ts"
git diff --cached
git commit -m "fix(auth): exigir cambio de contrasena inicial en servidor"
git status
git log -1 --oneline
```

## 4. docs: conciliar estado local de mapa repaso y editor

- Repositorio: SaberPlus Backend.
- Direccion local real: `C:\Users\luisk\Desktop\SaberPlus-Backend`.
- Rama actual comprobada: `fix/backend-lockfile-ci`.
- Rama recomendada: `docs/auditoria-relevo-2026-09-28`. No existe en Backend al cierre (la homonima de Flutter pertenece a otro repo). Crear despues de bloques 1-3.
- Tipo: `docs`.
- Estado: **LISTO PARA COMMIT LOCAL**, sujeto a autorizacion; no listo para deploy por ese hecho.

Archivos exactos que entrarian:

```text
README.md
admin/README.md
backend/README.md
backend/LEARNING_MAP.md
backend/DEFERRED_REVIEW.md
```

Comandos PowerShell, solo tras autorizacion:

```powershell
Set-Location -LiteralPath "C:\Users\luisk\Desktop\SaberPlus-Backend"
Get-Location
git status
git branch --show-current
git diff --cached --name-only
git switch -c docs/auditoria-relevo-2026-09-28
git add -- "README.md" "admin/README.md" "backend/README.md" "backend/LEARNING_MAP.md" "backend/DEFERRED_REVIEW.md"
git diff --cached
git commit -m "docs: conciliar estado local de mapa repaso y editor"
git status
git log -1 --oneline
```

## 5. docs: conservar auditoria y documentar estabilizacion previa a PR-I1

- Repositorio: Flutter SaberPlus.
- Direccion local real: `C:\Users\luisk\Desktop\saber_plus`.
- Rama actual comprobada: `docs/auditoria-relevo-2026-09-28`.
- Rama recomendada: `docs/auditoria-relevo-2026-09-28`. Ya existe y es adecuada para documentacion; no crear otra.
- Tipo: `docs`.
- Estado: **LISTO PARA COMMIT LOCAL**, sujeto a autorizacion; no listo para deploy por ese hecho.

Archivos exactos que entrarian:

```text
docs/AUDITORIA_RELEVO_2026-09-28.md
docs/COMMITS_ESTABILIZACION_2026-09-29.md
docs/ESTABILIZACION_PRE_PR_I1_2026-09-29.md
docs/PERFILES_RANKINGS_INSIGNIAS.md
docs/auditoria-relevo-2026-09-28/audit-produccion.json
docs/auditoria-relevo-2026-09-28/cambios.md
docs/auditoria-relevo-2026-09-28/datos.md
docs/auditoria-relevo-2026-09-28/documentacion.json
docs/auditoria-relevo-2026-09-28/documentacion.md
docs/auditoria-relevo-2026-09-28/ejecucion-resumen.json
docs/auditoria-relevo-2026-09-28/endpoints.json
docs/auditoria-relevo-2026-09-28/endpoints.md
docs/auditoria-relevo-2026-09-28/funcionalidades.md
docs/auditoria-relevo-2026-09-28/generar-inventario.cjs
docs/auditoria-relevo-2026-09-28/inventario.json
docs/auditoria-relevo-2026-09-28/inventario.md
docs/auditoria-relevo-2026-09-28/juegos-y-decisiones.md
docs/auditoria-relevo-2026-09-28/lint-resumen.json
docs/auditoria-relevo-2026-09-28/marcadores-deuda.json
docs/auditoria-relevo-2026-09-28/repro-seguridad.cjs
docs/auditoria-relevo-2026-09-28/secretos-metadatos.json
docs/auditoria-relevo-2026-09-28/verificaciones.md
```

Comandos PowerShell, solo tras autorizacion:

```powershell
Set-Location -LiteralPath "C:\Users\luisk\Desktop\saber_plus"
Get-Location
git status
git branch --show-current
git diff --cached --name-only
git switch docs/auditoria-relevo-2026-09-28
git add -- "docs/AUDITORIA_RELEVO_2026-09-28.md" "docs/COMMITS_ESTABILIZACION_2026-09-29.md" "docs/ESTABILIZACION_PRE_PR_I1_2026-09-29.md" "docs/PERFILES_RANKINGS_INSIGNIAS.md" "docs/auditoria-relevo-2026-09-28/audit-produccion.json" "docs/auditoria-relevo-2026-09-28/cambios.md" "docs/auditoria-relevo-2026-09-28/datos.md" "docs/auditoria-relevo-2026-09-28/documentacion.json" "docs/auditoria-relevo-2026-09-28/documentacion.md" "docs/auditoria-relevo-2026-09-28/ejecucion-resumen.json" "docs/auditoria-relevo-2026-09-28/endpoints.json" "docs/auditoria-relevo-2026-09-28/endpoints.md" "docs/auditoria-relevo-2026-09-28/funcionalidades.md" "docs/auditoria-relevo-2026-09-28/generar-inventario.cjs" "docs/auditoria-relevo-2026-09-28/inventario.json" "docs/auditoria-relevo-2026-09-28/inventario.md" "docs/auditoria-relevo-2026-09-28/juegos-y-decisiones.md" "docs/auditoria-relevo-2026-09-28/lint-resumen.json" "docs/auditoria-relevo-2026-09-28/marcadores-deuda.json" "docs/auditoria-relevo-2026-09-28/repro-seguridad.cjs" "docs/auditoria-relevo-2026-09-28/secretos-metadatos.json" "docs/auditoria-relevo-2026-09-28/verificaciones.md"
git diff --cached
git commit -m "docs: conservar auditoria y documentar estabilizacion previa a PR-I1"
git status
git log -1 --oneline
```

## 6. test: validar Tira sin identidad privada del rival

- Repositorio: Flutter SaberPlus.
- Direccion local real: `C:\Users\luisk\Desktop\saber_plus`.
- Rama actual comprobada: `docs/auditoria-relevo-2026-09-28`.
- Rama recomendada: `test/tira-privacy`. No existe al cierre. Crear despues del bloque 5; prueba independiente del cliente vigente.
- Tipo: `test`.
- Estado: **LISTO PARA COMMIT LOCAL**, sujeto a autorizacion; no listo para deploy por ese hecho.

Archivos exactos que entrarian:

```text
test/tug_online_test.dart
```

Comandos PowerShell, solo tras autorizacion:

```powershell
Set-Location -LiteralPath "C:\Users\luisk\Desktop\saber_plus"
Get-Location
git status
git branch --show-current
git diff --cached --name-only
git switch -c test/tira-privacy
git add -- "test/tug_online_test.dart"
git diff --cached
git commit -m "test: validar Tira sin identidad privada del rival"
git status
git log -1 --oneline
```

## Archivos fuera de los commits

pubspec.lock y pubspec.yaml son cambios ajenos preservados; no entran en ningun git add anterior. Los bloques del backend no mezclan lock, privacidad, autenticacion y documentacion. No hay upgrade de dependencias, modelo nuevo, ranking, migraciones o PR-I1 que guardar.

No existe hash nuevo ni estado posterior al commit porque no se ejecuto. Al autorizarlo, registrar hash corto, mensaje, archivos incluidos y excluidos, y estado restante. Las ramas propuestas no se deben volver a crear si el propietario ya ejecuto el bloque: comprobar git branch --list antes de repetir esta guia.

## Lista exacta acumulada de archivos modificados/nuevos

Incluye la auditoria aceptada anterior aun sin commit y esta estabilizacion. Solo esta ronda: nuevo documento de estabilizacion y esta guia, adenda a auditoria, un test Flutter y los 12 archivos backend de privacidad/auth listados en bloques2/3.

### Flutter

```text
docs/AUDITORIA_RELEVO_2026-09-28.md
docs/COMMITS_ESTABILIZACION_2026-09-29.md
docs/ESTABILIZACION_PRE_PR_I1_2026-09-29.md
docs/PERFILES_RANKINGS_INSIGNIAS.md
docs/auditoria-relevo-2026-09-28/audit-produccion.json
docs/auditoria-relevo-2026-09-28/cambios.md
docs/auditoria-relevo-2026-09-28/datos.md
docs/auditoria-relevo-2026-09-28/documentacion.json
docs/auditoria-relevo-2026-09-28/documentacion.md
docs/auditoria-relevo-2026-09-28/ejecucion-resumen.json
docs/auditoria-relevo-2026-09-28/endpoints.json
docs/auditoria-relevo-2026-09-28/endpoints.md
docs/auditoria-relevo-2026-09-28/funcionalidades.md
docs/auditoria-relevo-2026-09-28/generar-inventario.cjs
docs/auditoria-relevo-2026-09-28/inventario.json
docs/auditoria-relevo-2026-09-28/inventario.md
docs/auditoria-relevo-2026-09-28/juegos-y-decisiones.md
docs/auditoria-relevo-2026-09-28/lint-resumen.json
docs/auditoria-relevo-2026-09-28/marcadores-deuda.json
docs/auditoria-relevo-2026-09-28/repro-seguridad.cjs
docs/auditoria-relevo-2026-09-28/secretos-metadatos.json
docs/auditoria-relevo-2026-09-28/verificaciones.md
pubspec.lock
pubspec.yaml
test/tug_online_test.dart
```

### Backend

```text
README.md
admin/README.md
backend/DEFERRED_REVIEW.md
backend/LEARNING_MAP.md
backend/README.md
backend/package-lock.json
backend/src/auth/auth-security.service.spec.ts
backend/src/auth/auth.controller.ts
backend/src/auth/auth.service.ts
backend/src/auth/initial-password-access.spec.ts
backend/src/auth/initial-password-access.ts
backend/src/auth/jwt.guard.ts
backend/src/tira-afloja/tira-afloja-privacy.spec.ts
backend/src/tira-afloja/tira-afloja-ws-auth.service.spec.ts
backend/src/tira-afloja/tira-afloja-ws-auth.service.ts
backend/src/tira-afloja/tira-afloja.gateway.spec.ts
backend/src/tira-afloja/tira-afloja.gateway.ts
backend/src/tira-afloja/tira-afloja.service.ts
```

## Actualización posterior — 2026-09-30

Esta adenda registra el estado posterior comunicado por el propietario tras la estabilización. El contenido anterior conserva los hallazgos, resultados, limitaciones y propuestas históricos del 28/29 de septiembre; sus referencias a correcciones locales, upgrades pendientes o commits aún no realizados no describen el estado posterior aquí documentado. No se repitieron las pruebas como parte de esta actualización exclusivamente documental.

### Backend: estabilización fusionada

PR #4 fusionado a `main`, merge commit `fb27225`. El trabajo quedó registrado en los siguientes commits:

| Commit | Mensaje |
|---|---|
| `741c28e` | fix: sincronizar lockfile reproducible del backend |
| `6e2e01b` | fix(security): evitar datos privados en Tira y afloja |
| `f26a948` | fix(auth): exigir cambio de contrasena inicial en servidor |
| `ebaeed3` | docs: conciliar estado local de mapa repaso y editor |
| `125e895` | fix(security): actualizar dependencias parcheables del backend |
| `e329f39` | fix(security): actualizar Nodemailer |
| `1a06b4f` | fix(security): actualizar Puppeteer |

Estado final validado de la estabilización:

- Node **24.14.1** y npm **11.11.0**.
- `npm ci --include=dev`: **OK**.
- `npm run build`: **OK**.
- **89 suites / 878 tests: OK**.
- `npm audit --omit=dev`: **0 vulnerabilidades**.
- **6 certificados PDF** generados con Chrome real y cierre correcto del navegador.

Versiones finales relevantes:

| Dependencia | Estado final |
|---|---|
| Engine.IO | 6.6.11 |
| Multer | 2.4.0 |
| Nodemailer | 10.0.12 |
| Puppeteer | 25.12.0 |
| Puppeteer Core | 25.12.0 |
| @puppeteer/browsers | 3.2.3 |
| extract-zip | Eliminado de la cadena de producción |

### Flutter

- Rama actual: `fix/pre-pr-i1-stabilization-flutter`.
- Commit ya realizado: `35d0f4e test: validar Tira sin identidad privada del rival`.
- `flutter test --no-pub test/tug_online_test.dart`: **7/7 OK**.

### Evidencia histórica y alcance vigente

- `docs/auditoria-relevo-2026-09-28/` es evidencia histórica y se conserva intacta.
- `docs/auditoria-relevo-2026-09-28/audit-produccion.json` registra el snapshot antiguo de **7 vulnerabilidades** y **no representa el estado actual posterior al PR #4**. No se regenera ni se reemplaza ese snapshot.
- **PR-I1 sigue sin implementarse.** La estabilización fusionada no equivale a su implementación.
- **`pubspec.yaml` y `pubspec.lock` siguen fuera del alcance y no deben tocarse.** Sus cambios locales preexistentes se preservan.

### Lectura actual de la guía de commits

Los nombres de ramas y los comandos de creación/cambio de rama de los bloques anteriores son **históricos/propuestos**, no instrucciones vigentes para repetir el trabajo. El trabajo real del backend terminó con los siete commits anteriores, integrados en `main` mediante PR #4 (`fb27225`); la prueba Flutter quedó en `35d0f4e`, en `fix/pre-pr-i1-stabilization-flutter`. No se deben recrear las ramas propuestas ni repetir esos commits por seguir esta guía histórica. Las afirmaciones anteriores de «listo para commit» o de ausencia de hashes corresponden al cierre del 29 de septiembre, no al estado actualizado. Esta conciliación documental no ejecuta commits, push ni merge.
