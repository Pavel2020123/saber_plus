# Auditoría de SaberPlus — 9 de septiembre de 2026

Cierre de verificaciones locales: **10 de septiembre de 2026**.

## Resultado y alcance

Se revisaron la aplicación Flutter, la API NestJS/Prisma y el panel editorial,
con correcciones locales de seguridad, concurrencia, persistencia y accesibilidad.
Esta entrega complementa D2-F; **no cierra D3 ni habilita producción**.
No se hicieron commits, despliegues ni escrituras en Supabase/Render.

La revisión combinó inventario de módulos/contratos, lectura de rutas críticas,
análisis estático, dependencias y pruebas automatizadas. No es una certificación
de seguridad, un pentest externo ni una afirmación de haber comprobado manualmente
cada línea y pantalla. Las pruebas con dobles no sustituyen una integración real.

Repositorios revisados:

- Flutter: `C:\Users\LENOVO 14ALC6\Desktop\SaberPLus\saber_plus`.
- API y panel: `C:\Users\LENOVO 14ALC6\Desktop\SaberPlus-Backend`.

Se preservaron los cambios previos de Guardián en el segundo repositorio:
`backend/prisma/schema.prisma`, `backend/src/app.module.ts`,
`backend/tool/probe_database.mjs`, su migración y `backend/src/guardian/`.
No se aplicó esa migración ni se incluyó como corrección nueva de la auditoría.

Para compartir las funcionalidades con personas no técnicas, usar
[FUNCIONALIDADES_PARA_EL_EQUIPO.md](FUNCIONALIDADES_PARA_EL_EQUIPO.md).

## Hallazgos corregidos

La prioridad expresa el impacto potencial; no significa que se haya constatado
un ataque o una pérdida de datos en usuarios reales.

| Prioridad | Hallazgo | Corrección local |
| --- | --- | --- |
| Alta | Una respuesta antigua de login/restauración/perfil podía competir con cerrar sesión o entrar a demo | Generación de sesión, comprobaciones tras esperas y serialización de escrituras en almacenamiento seguro |
| Alta | Solicitudes autenticadas podían conservar respuestas de otra sesión o aceptar destinos externos | Revisión de sesión por petición, restricción de origen y redirecciones desactivadas; comparación de esquema/host/puerto |
| Alta | Sincronizar una nota y editarla mientras viajaba podía borrar o bloquear la edición nueva | Confirmación/actualización condicional por revisión; instantánea de identidad; revisión nueva en cada edición |
| Alta | Tokens de recuperación/verificación se consumían sin comprobación atómica | Consumo condicional con vencimiento obligatorio y rechazo de reutilización concurrente |
| Alta | El cambio de contraseña inicial no exigía que siguiera pendiente | Condición explícita y actualización protegida en backend |
| Alta | La conversión implícita podía interpretar el texto `"false"` como verdadero | Booleanos JSON estrictos en DTO afectados, incluyendo opciones correctas y consentimiento institucional |
| Alta | Dependencias del backend tenían avisos de seguridad vigentes | Actualización compatible de dependencias y lockfile; revisión con `npm audit` |
| Media | Un fallo al guardar el identificador de instalación podía dejar solo su copia en memoria | Se cachea únicamente después de persistirlo; se mantiene una sola creación compartida entre solicitudes |
| Media | Repositorios institucionales devolvían futuros sin esperar dentro del `try` | `await` para que errores asíncronos pasen por el manejo previsto |
| Media | La navegación permitía rutas de la otra experiencia/rol | Política de rutas separada, con prioridad del cambio inicial de contraseña |
| Regresión de auditoría | Destruir/recrear el router al cambiar de sesión rompía callbacks de navegación aún activos | Router estable con refresco de redirecciones y prueba de identidad durante entrada/cambio de rol/salida |
| Media | Android no excluía expresamente datos privados del respaldo y transferencia automáticos | Desactivación de backup y reglas de exclusión para nube/transferencia |
| Funcional | El guard académico conservaba el bloqueo por vencimiento del antiguo plan de prueba | Acceso académico gratuito para cuentas válidas; no elimina autorización ni límites institucionales |
| UX | Nombres nuevos de temas/subtemas podían perderse al cambiar selección o salir | Confirmación de descarte y aviso de salida con cambios pendientes |
| UX | Textos del inicio podían desbordar con letra grande; contraste insuficiente en la tarjeta oscura | Distribución flexible y colores contrastados, conservando claro/oscuro |
| UX | Mensajes de error no se anunciaban como actualización accesible y botones de juegos carecían de etiqueta | Semántica de errores, tooltips y texto de cierre de sesión correcto para demo/real |
| Preventiva | Archivos locales de ambiente, claves o exportaciones podían añadirse accidentalmente | Exclusiones adicionales de Git, conservando ejemplos versionables |

Las exclusiones de Git no retiran secretos que ya estuvieran en commits antiguos
ni sustituyen rotación y revisión del historial. No se imprimieron credenciales
en la revisión ni se editaron archivos de configuración secreta.

### Persistencia y compatibilidad

La base local Drift cambia de **versión 7 a 8** para añadir una revisión de
operación pendiente. Se conserva la cola existente y el resto de tablas;
el código generado forma parte de la entrega. No requiere ejecutar Prisma ni SQL
en Supabase: la migración corresponde únicamente a SQLite en cada instalación.

La revisión de la cola evita perder una edición local por una respuesta anterior.
No implementa por sí sola resolución de conflictos entre varios dispositivos
ni el catálogo remoto versionado de C4. Tampoco convierte respuestas, compras o
calificaciones en escrituras offline reintentables.

Android excluye ahora el estado privado de backup/transferencia automáticos.
**Los datos que solo existen localmente no se recuperan después de desinstalar
o cambiar de teléfono.** No se borraron datos existentes. La sincronización
remota pendiente debe resolverse antes de prometer recuperación completa.
SQLite permanece en almacenamiento privado, no se convirtió en una base cifrada.
La separación por usuario no protege por sí sola un dispositivo comprometido.
Se cubrieron nube y transferencia por separado porque `allowBackup=false`
por sí solo no cubre todos los dispositivos Android 12+.
[Referencia oficial de Android](https://developer.android.com/identity/data/autobackup).

### Dependencias

Se actualizaron Multer a 2.3.0, Nodemailer a 9.1.1, `js-yaml` a 4.3.2,
`fast-uri` a 3.1.7 y dependencias transitivas del árbol de herramientas.
Se conservó NestJS 11 y Prisma 5, sin aplicar un `audit fix --force` ni cambiar
versiones mayores de forma indiscriminada. El lockfile y la instalación local
fueron actualizados juntos.

Motivos verificables: denegación de servicio de
[Multer](https://github.com/advisories/GHSA-wc9g-mqfw-jrwm), omisión de restricciones
de contenido en una API heredada de
[Nodemailer](https://github.com/advisories/GHSA-8m3c-c648-2xjj), consumo excesivo de CPU en
[js-yaml](https://github.com/advisories/GHSA-2883-xcg3-v3hh) y análisis de direcciones en
[fast-uri](https://github.com/advisories/GHSA-f65p-4m7j-42xc).
La presencia en el árbol no demuestra explotabilidad en todas las rutas de SaberPlus.

No se modificaron las versiones Flutter/Drift/SQLite fijadas por compatibilidad
con Windows y las rutas con espacios. Una actualización mayor requiere su propia
prueba Android/iOS. El entorno local Node 24.11.1/npm 11.6.2 difiere del objetivo
Node 24.14.1/npm 11.11.0 del backend: repetir CI con las versiones fijadas.

## Calidad y organización

Se conservó la organización por funcionalidades (`domain`, `data`, `presentation`),
Riverpod, repositorios y módulos NestJS. Se extrajeron políticas pequeñas para
rutas, origen HTTP y validación de booleanos, con regresiones específicas.
No se movieron cientos de archivos ni se rehízo la arquitectura durante una
corrección de seguridad; los cambios conservan responsabilidades reconocibles.

Mejoras futuras de mantenibilidad: reducir gradualmente controladores/editoriales
grandes, publicar OpenAPI, uniformar errores y cerrar deuda de lint heredada.
Estos trabajos deben preservar pruebas de permisos, clasificación e historial;
un cambio cosmético masivo no demuestra por sí mismo mayor seguridad.

## Verificaciones

Resultados comprobados en esta revisión local:

| Comprobación | Resultado |
| --- | --- |
| Panel: `npm test` | 61 aprobadas, 0 fallos |
| Panel: `npm run check` | Sintaxis válida en 14 módulos |
| Flutter: rutas, accesibilidad y juegos focalizados | 46 aprobadas |
| Flutter: datos, sesión, red y migraciones focalizados | 61 aprobadas |
| Backend: `npm audit` | 0 vulnerabilidades reportadas el 9 de septiembre de 2026 |
| Backend: coherencia del lockfile (`npm ci --dry-run --ignore-scripts --include=dev`) | Aprobada; advertencia por versión local de Node distinta de la fijada |
| Flutter: `flutter analyze --no-pub` | Sin errores, advertencias ni avisos |
| Flutter: recorrido de pantallas tras corregir ciclo de vida del router | 33 aprobadas |
| Flutter: formato de los 33 archivos Dart modificados/nuevos | Sin cambios de formato pendientes |
| Flutter: suite completa con concurrencia 2 | 422 aprobadas, 4 remotas omitidas, 0 fallos |
| Backend: Jest | 66 suites / 671 pruebas aprobadas |
| Backend: `npm run build` | Prisma Client generado y Nest compilado |
| Backend: PostgreSQL editorial aislado | 12 aprobadas sobre SQL de 40 migraciones versionadas; instancia temporal cerrada y eliminada |
| Backend: guardas del ejecutor PostgreSQL | 11 aprobadas |
| Backend: regresiones tras tipar mocks | 46 pruebas académicas y 20 de booleanos aprobadas |
| Backend: ESLint completo, sin `--fix` | 43 errores y 11 advertencias preexistentes en Guardián/`app.module.ts`; archivos corregidos sin errores propios pendientes |
| Android: compilación debug | APK generado el 9 de septiembre; firma y recursos compilados verificados el 10 |
| Navegador real del panel | Pendiente: la habilidad de navegador informa que no hay navegador disponible |
| iOS / dispositivos reales / staging | No ejecutados en esta auditoría |

Detalles por área: [datos](AUDITORIA_DATOS_2026-09-09.md),
[UX](AUDITORIA_UX_2026-09-09.md) y `backend/AUDITORIA_BACKEND_2026-09-09.md`
en el repositorio de la API. Cero avisos en `npm audit` no significa ausencia
de vulnerabilidades desconocidas, errores de autorización o configuración.

Las cifras de pruebas focalizadas son subconjuntos de las suites generales;
no deben sumarse para presentar un total mayor. Las pruebas remotas de login,
diagnóstico y estudio requieren `AUTH_E2E_*`; el smoke de staging exige activación
explícita. Se mantienen omitidas para no utilizar cuentas ni servicios reales
durante esta revisión. No son pruebas aprobadas de integración remota.

Las 671 pruebas y la compilación del backend corresponden al árbol local con
los cambios previos de Guardián presentes. No se afirma haber reconstruido un
checkout limpio del futuro commit aislado de esta auditoría; repetir CI al
integrar los commits definitivos.

### APK comprobado

- Ruta: `build/app/outputs/flutter-apk/app-debug.apk` del repositorio Flutter.
- Generado: 9 de septiembre, 19:55:21 (hora de Colombia); tamaño 210.743.728 bytes.
- `apksigner verify --verbose`: firma APK v2 válida, un firmante.
- `aapt2 dump xmltree`: confirma `allowBackup=false`, `fullBackupContent=false`
  y las 18 exclusiones de `data_extraction_rules.xml` dentro del APK.
- SHA-256: `55ba2de6a6baef93ba0eabc60b7ebb653763f67fdda54e040c775251910de1d8`.

El paquete conserva `com.example.saber_plus` y la configuración debug que permite
HTTP para desarrollo. No se instaló en teléfonos ni se distribuyó. No es el AAB
de publicación ni una verificación del manifiesto de una compilación release.
La construcción usó dos trabajadores de Gradle para limitar el uso de memoria,
sin cambiar la configuración permanente del proyecto.

Advertencias de herramientas: `flutter_timezone` aún aplica Kotlin Gradle Plugin;
Flutter avisa que una versión futura exigirá Kotlin integrado. Java también avisa
de acceso nativo restringido usado por Gradle/apksigner. No impidieron generar o
verificar este APK; revisar compatibilidad antes de actualizar Flutter/Java.

Para repetir la validación local de Flutter en equipos con poca memoria:

```powershell
flutter analyze --no-pub
flutter test --no-pub --concurrency=2 --reporter expanded
flutter build apk --debug --no-pub
```

Ejecutar la compilación después de las pruebas. El APK debug usa la configuración
demostrativa predeterminada; no es un paquete firmado para publicar en Google Play.

## Riesgos y trabajo que sigue pendiente

1. **Identidad de servidor:** sesión única real, refresh/rotación y revocación
   centralizada. Invalidar una sesión en Flutter no revoca automáticamente
   un JWT que alguien ya obtuvo. La recuperación de contraseña debe integrarse
   con ese cierre centralizado.
   `JwtGuard` tampoco restringe por sí mismo todas las rutas cuando está pendiente
   el cambio inicial de contraseña; la redirección de Flutter no sustituye esa
   política de servidor. Definir las rutas mínimas permitidas y probar el bloqueo.
2. **Pagos heredados:** retirar/aislar ePayco del backend móvil y completar
   derechos neutrales al proveedor y Google Play Billing. No se activaron pagos
   ni se cambiaron productos comerciales en esta revisión.
3. **Editorial D2/D3:** revisión visual, ensayo con ADMIN, concurrencia de editores,
   fallos de red y permisos en la instancia objetivo; operación del legado solo
   con respaldo y autorización. No habilitar publicación solo por aprobar mocks.
4. **Contenido C4–C6:** catálogo versionado, sincronización, archivos/imágenes
   persistentes y versiones/auditoría/restauración editorial. Las imágenes de
   opciones no están resueltas por aceptar una URL en un enunciado.
5. **Integridad académica:** cierre autoritativo contrarreloj, recuperación de
   resultados idempotente, banco histórico autorizado y contrato de conflictos
   del cuaderno. Conservar fuentes y calidad de contenido/diagnóstico.
6. **Privacidad:** eliminación de cuenta/datos, retención, consentimiento y
   audiencia adolescente; soporte y políticas reales antes de añadir SDK.
7. **Monetización:** AdMob/SSV y Billing aún no están listos; recompensas verificadas,
   restauración/reembolsos, control de frecuencia y pruebas con cuentas de licencia.
8. **Publicación:** `applicationId` aún de ejemplo y firma Android release de debug;
   elegir identificadores y custodiar claves como tarea de lanzamiento, no
   generar otra identidad de app sin acordarla. Compilar y probar iOS en macOS/Xcode.
9. **Operación:** pruebas de carga, dos dispositivos, restauración de respaldos,
   observabilidad, revisión de logs/secretos y separación dev/producción.

El listado completo conserva **13 bloques**, no 13 etapas originales nuevas:
[ETAPAS_PENDIENTES.md](ETAPAS_PENDIENTES.md). Esta auditoría no los marca como
terminados ni vuelve a contar los juegos o pantallas que ya existen.

## Guardar los cambios

Revisar primero `git status` y el diff preparado. Estos comandos separan la
auditoría de los archivos de Guardián que ya estaban pendientes en el backend.
No incluyen push ni despliegue.

Flutter:

```powershell
cd "C:\Users\LENOVO 14ALC6\Desktop\SaberPLus\saber_plus"
git status --short
git add .gitignore README.md android/app/src/main lib test docs
git diff --cached --stat
git commit -m "fix: reforzar seguridad persistencia y accesibilidad movil"
```

Backend y panel (misma raíz Git):

```powershell
cd "C:\Users\LENOVO 14ALC6\Desktop\SaberPlus-Backend"
git status --short
git add .gitignore admin backend/package.json backend/package-lock.json backend/AUDITORIA_BACKEND_2026-09-09.md
git add backend/src/admin backend/src/anuncios backend/src/auth backend/src/batallas backend/src/common backend/src/cupones backend/src/institucion backend/src/soporte backend/src/ventas
git add backend/src/diagnostico/learning-evidence.service.spec.ts
git diff --cached --stat
git commit -m "fix: auditar seguridad del backend y proteger el panel editorial"
```

Si ya había otros archivos preparados, `git commit` también los incluirá:
comprobar la lista antes de confirmar. No añadir `.env` ni exportaciones de datos.
