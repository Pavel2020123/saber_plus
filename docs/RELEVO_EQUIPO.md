# Relevo del equipo — empezar aquí

Actualizado: 24 de septiembre de 2026. Encargo del propietario: los compañeros
pueden auditar y continuar las etapas acordadas mientras él no esté trabajando.
Esta guía es la ruta operativa; no certifica una auditoría completa del código.
El inventario detallado sigue en [ETAPAS_PENDIENTES.md](ETAPAS_PENDIENTES.md).

## 1. Antes de programar: comprender y auditar ambos repositorios

1. Leer `README.md`, [arquitectura](ARQUITECTURA_Y_ESTRUCTURA.md),
   [historial](HISTORIAL_ETAPAS.md), [pendientes](ETAPAS_PENDIENTES.md),
   [juegos acordados](SABI_Y_JUEGOS_APROBADOS.md),
   [perfiles/insignias](PERFILES_RANKINGS_INSIGNIAS.md) y el contrato de la etapa elegida.
   Leer cualquier `AGENTS.md` aplicable antes de usar asistentes de programación.
2. Abrir también `SaberPlus-Backend/README.md`, `backend/README.md`, `admin/README.md`,
   los scripts de `package.json`, esquema Prisma y migraciones. No basta con tener Flutter.
3. Recorrer un flujo completo: pantalla → controlador/proveedor → repositorio → API
   → autorización/servicio → Prisma → respuesta → caché/interfaz. Repetir para sesión,
   estudio, diagnóstico, juegos, perfil, instituciones, certificados y panel.
4. Inventariar cada módulo como: demo / implementado localmente / desplegado / probado
   en dispositivo. Buscar implementaciones y pruebas antes de recrear una función.
5. Ejecutar una línea base de pruebas. Registrar fallos previos antes de cambiarlos.
   Revisar aislamiento de cuentas/instituciones, permisos en servidor, reintentos,
   persistencia, datos privados, errores de red, accesibilidad y estados vacíos.
6. Crear `docs/AUDITORIA_RELEVO_YYYY-MM-DD.md`: commits revisados de ambos repositorios,
   módulos cubiertos, hallazgos con archivo/línea, gravedad, pasos de reproducción,
   pruebas ejecutadas y limitaciones. No escribir «todo funciona» sin evidencia.
7. Corregir riesgos críticos antes de ampliar funciones, en cambios pequeños con
   pruebas de regresión. No hacer una reescritura general ni actualizar todas las
   dependencias por gusto. Si cambia reglas de producto, consultar al propietario.

Arquitectura real: Flutter por funcionalidades y capas, inspirada en Clean Architecture
(no estricta); API monolítica modular NestJS/Prisma; panel HTML/CSS/JavaScript modular.
Supabase aloja PostgreSQL; Render ejecuta la API. Ni Flutter ni el panel reciben claves de base.

## 2. Descargar y conservar los dos proyectos

El propietario debe conceder acceso GitHub a **ambos repositorios privados**. No es
necesario hacerlos públicos ni compartir su cuenta, contraseña o token. Si aparece
«Repository not found», comprobar invitación/acceso y cuenta autenticada.

Ejemplo para un compañero: crear `C:\Proyectos` y abrir allí una terminal. Si ya
existen las carpetas, no volver a clonarlas encima; revisar `git status` primero.

```powershell
cd "C:\Proyectos"
git clone https://github.com/Pavel2020123/saber_plus.git
git clone https://github.com/Pavel2020123/SaberPlus-Backend.git
```

Abrir ambas carpetas en dos ventanas de VS Code, o usar **Archivo → Agregar carpeta
al área de trabajo**. Son dos repositorios: cada uno tiene su rama, commit y PR.
Mantener ambas copias actualizadas; no entregar cambios nuevos en `Icfes_Vida`.

| Proyecto | Ruta del propietario | Ruta de ejemplo del compañero |
|---|---|---|
| Flutter | `C:\Users\LENOVO 14ALC6\Desktop\SaberPLus\saber_plus` | `C:\Proyectos\saber_plus` |
| API y panel | `C:\Users\LENOVO 14ALC6\Desktop\SaberPlus-Backend` | `C:\Proyectos\SaberPlus-Backend` |

Las rutas dependen de dónde clone cada persona. No copiar el nombre de usuario del
propietario como si existiera en todos los computadores. Nunca compartir `.env`,
contraseñas PostgreSQL, claves de firma, tokens o cuentas reales en Git/chat.

## 3. Preparación local y pruebas

Revisar versiones documentadas; backend fija Node `24.14.1` y npm `11.11.0`.
No cambiar el lockfile para resolver a ciegas un problema de entorno.

```powershell
cd "C:\Proyectos\saber_plus"
flutter doctor -v
flutter pub get
flutter analyze
flutter test
```

```powershell
cd "C:\Proyectos\SaberPlus-Backend\backend"
npm ci --include=dev
npm run build
npm test -- --runInBand
```

```powershell
cd "C:\Proyectos\SaberPlus-Backend\admin"
npm run check
npm test
npm run demo
```

La demo permite probar el panel sin Supabase; los cambios viven en memoria y se
pierden al reiniciar. No constituye una prueba del backend real. Para iniciar la
API local, leer su README, preparar únicamente una base local desechable y variables
locales no versionadas y después usar `npm run start:dev` desde `backend/`.
La configuración de staging se revisa en `docs/FLUTTER_STAGING_CONNECTION.md`;
no activar acceso real ni copiar credenciales del propietario para una prueba local.

Pruebas PostgreSQL: leer `backend/tool/test_editorial_postgres.mjs` y su documentación
antes de usar el runner aislado. No sustituir su conexión temporal por Supabase.
No ejecutar `prisma migrate reset`, `db push` o `migrate deploy` contra una base
compartida por iniciativa propia. Nuevos esquemas requieren migración revisada,
prueba en base temporal y coordinación del despliegue.

Última evidencia local de MA-1: 827 pruebas backend, 79 panel y 4 PostgreSQL de
cobertura. Son referencia histórica, no resultados del computador del compañero.
Esta entrega documental no vuelve a ejecutar las suites de la app.

## 4. Decisiones que no se deben cambiar accidentalmente

- Android e iOS se conservan. Lanzamiento comercial inicial solo Google Play.
- Contenido académico estudiantil gratuito; pago quita anuncios y añade cosméticos,
  no bloquea áreas, estadísticas, juegos o PDFs detrás de Premium.
- No reintegrar ePayco/Wompi, tutores, chat ni juegos nuevos no aprobados.
- JN-3 Taller de inventos está cancelado. Cima, Rescate y Escudo ya tienen motores
  locales/backend/clientes; auditar y completar integración, no rehacerlos.
- Seis certificados: cinco áreas y curso completo. Todas las lecciones publicadas
  del área completadas; área vacía no habilita certificado. Nombre registrado,
  no alias de ranking. No certificados por cada insignia o partida.
- Panel sencillo: área → tema → subtema → contenido/preguntas. Guardar pregunta
  la publica directamente cuando está autorizada y válida; no imponer una nueva
  bandeja de revisión. Conservar controles de duplicados, uso histórico y permisos.
- Top máximo 50 por juego. Todas las insignias ganadas visibles; colección anual
  permanente con el mismo arte y año dinámico. Catálogo gráfico ≠ premio ganado.
- P5/D3 y operaciones reales siguen pausados hasta coordinación con el propietario.
  Preparar código/pruebas locales no autoriza desplegar ni migrar datos compartidos.
- Animaciones profesionales y acabado azul se hacen al final, antes de beta/publicación.
- Publicidad/comodines se acuerdan en 8C–8D, no se insertan ahora en juegos.

## 5. Orden de continuación y fichas de trabajo

**Primero auditoría → MA-2 → MA-3 → PR-I1.** Completar el trabajo local de PR-I2–6
según dependencias; C5 es necesario antes de fotos reales. Los bloques editoriales,
seguridad, comerciales y despliegues se coordinan después, sin saltar sus requisitos.
P5 precede a D3; D3 no sustituye C4. PR-I7 necesita infraestructura autorizada.
UI-F precede a 8G; después entrega iOS, Google Play y mantenimiento.

Los identificadores no son un contador lineal: hay pendientes de cierre en etapas
ya implementadas. Las fichas siguientes incluyen todo el inventario de bloques
obligatorios; leer su detalle en ETAPAS_PENDIENTES, no usar solo el título.
Las carpetas indicadas son puntos existentes de entrada, no autorización para
reescribirlas enteras. Los nombres de archivos nuevos se decidirán tras la auditoría.

### MA-1 — Cerrar cobertura (base ya implementada)

Revisar pestaña Cobertura en navegador y conteos reales. Implementar el flujo de
reportes académicos antes de contarlos; distinguir pendientes/resueltos y permisos.
No usar reportes de batallas ni mostrar cero cuando no existe el dato. Probar
subtemas vacíos, padres archivados y paginación. Rutas: `admin/public/bank-coverage.mjs`,
`backend/src/admin/bank-coverage.service.ts`; guía `docs/COBERTURA_DEL_BANCO.md`.
Commit sugerido al cerrar ese alcance: `feat: completar reportes y cobertura academica`.

### MA-2 — Mapa de aprendizaje (siguiente)

Relacionar conocimientos previos por tema/subtema: fracciones → proporciones →
regla de tres. Permitir edición autorizada en panel, evitar ciclos/autorreferencias
y manejar contenido retirado. Mostrar al estudiante una orientación comprensible,
no un bloqueo ni un diagnóstico inventado por un solo error. Reutilizar evidencia
existente y distinguir falta de datos de debilidad. Definir primero contrato y reglas
de recomendación, después API, demo, cliente y pruebas. Revisar `lib/features/study`,
`academic`, `learning_evidence`, `backend/src/plan-estudio`, `diagnostico`, `admin`.
Cerrar con pruebas de grafo, permisos, contenido vacío y navegación sin restricciones.
Commit: `feat: agregar mapa de aprendizaje sin bloquear contenido`.

### MA-3 — Repaso diferido

Programar comprobaciones días después reutilizando flashcards, cuaderno de errores
y repasos. Definir intervalos antes de implementarlos; persistir por cuenta y
sincronizar reintentos sin duplicados. Repetir la misma pregunta no es nueva evidencia
independiente de dominio. Mostrar vencidos, próximos y estado sin conexión; no crear
otro sistema paralelo de notificaciones. Revisar `lib/features/flashcards`, `practice`,
`learning_evidence`, `backend/src/cuaderno-errores`. Probar cambio de día/cuenta,
reinstalación, respuestas repetidas y conflictos. Commit: `feat: agregar repaso diferido sincronizado`.

### PR-I1 — Reglas y contratos competitivos

Leer PERFILES_RANKINGS_INSIGNIAS completo. Confirmar XP elegible por juego, empates,
ayudas, ámbito y cierre anual; el año calendario America/Bogota es propuesta por
confirmar, no hecho consumado. Separar identidad pública de datos privados. Diseñar
contratos versionados y migraciones sin romper el ranking actual. No adivinar decisiones
comerciales/competitivas. Rutas: `lib/features/ranking`, `profile`, `gamification`,
`backend/src/ranking`, `gamificacion`, `backend/prisma`.
Commit de reglas: `docs: definir contratos de rankings y temporadas`.

### PR-I2 — Rankings por juego

Top 50 y posición propia incluso fuera del top, XP verificable concedido una sola
vez por servidor y desempate documentado. No copiar XP global a cada juego ni
clasificar partidas demo/asistidas como competitivas. Activar un ranking solo cuando
su motor aporte evidencia segura. Probar fraude, reenvíos y empates. Mismas rutas
PR-I1 más motores de juegos. Commit: `feat: agregar rankings verificables por juego`.

### PR-I3 — Insignias por temporada

Reutilizar las 40 imágenes integradas, completar familias faltantes sin inventar
premios. Puestos 1–5 individuales; intervalos 6–10, 11–20, 21–30, 31–40, 41–50.
Separar posición provisional actual de premio anual confirmado. Guardar snapshot
permanente de juego, ámbito, año, puesto y reglas; cierre idempotente. Una insignia
2026 sigue al ganar 2027. Probar cambio de año, reintento y correcciones auditadas.
Rutas: `assets`, `lib/features/gamification`, `ranking`, `backend/src/ranking`,
`backend/prisma`. Commit: `feat: conservar insignias anuales por juego`.

### PR-I4 — Mejorar perfil y búsqueda de estudiantes

Mejorar el perfil con cabecera sobria, avatar/foto, alias, @usuario y experiencia.
**Agregar todas las insignias ganadas por temporadas**, agrupadas por año/juego:
no limitar a tres, no reemplazar años anteriores, no presentar el catálogo entero
como propio. Toque en insignia abre puesto exacto, juego, ámbito y año; accesible
sin hover. Buscar personas por identidad pública y abrir su perfil desde rankings.
Privacidad por elección: no publicar automáticamente correos, nombre del certificado,
falencias, puntajes privados o institución. Manejar perfil privado/no disponible;
definir bloqueo/reporte antes del lanzamiento social. No agregar feed/chat/seguidores.
Depende de PR-I1–3 y C5 para fotos. Rutas: `lib/features/profile`, `search`, `ranking`,
`backend/src/auth`, `ranking`. Probar privacidad tanto en API como UI, paginación,
nombres duplicados y texto grande. Commit: `feat: mejorar perfiles con insignias por temporada`.

### PR-I5 — Perfil institucional, búsqueda e ingresos

Directorio de instituciones aprobadas/activas por nombre, ubicación y tipo. Logo,
descripción e identidad editables solo por propietario actual. Solicitud estudiantil
con pendiente/aceptada/rechazada/cancelada y aviso privado; aprobación transaccional
con capacidad y membresía. Código institucional privado para ingreso rápido,
controlado por propietario, revocable y protegido; no confundirlo con códigos de
grupo existentes ni cambiar sus permisos silenciosamente. Reutilizar aprobación
P4-C. Profesor puede tener foto, no ranking de jugador. No exponer listas de alumnos.
Rutas: `lib/features/institutions`, `backend/src/institucion`, `admin/public`.
Commit: `feat: agregar directorio y solicitudes institucionales`.

### PR-I6 — Ranking institucional

Sumar solo aportes elegibles ganados mientras el alumno pertenecía a la institución.
Salir o cambiar no traslada XP histórico ni lo duplica. Mostrar período y participantes;
definir mínimo de muestra para promedio complementario. Solo agregados públicos.
Rutas: ranking/institutions e institucion del backend. Probar traslados y reintentos.
Commit: `feat: agregar ranking institucional con aportes historicos`.

### PR-I7 — Ensayo competitivo y social

Con despliegue autorizado, probar dos cuentas/dispositivos, fotos, privacidad,
solicitudes, empates, ayudas excluidas, cierre anual y coexistencia 2026/2027.
No alterar reloj/base de producción para simular años. Registrar commits desplegados
y evidencia; pruebas locales no cierran esta ficha. Commit: `test: verificar perfiles rankings y temporadas`.

### P5 — Cierre docente real (pausado)

Verificar P1–P4-C existentes, no rehacerlos: profesor solicita institución, ADMIN
aprueba, crea grupo, vincula alumno, asigna prioridad, alumno practica y docente
consulta avance/tiempo. Probar suspensión, permisos cruzados, reconexión y cuentas.
Faltan URL vigente, cuentas autorizadas, entorno/respaldo y permiso del propietario.
Leer `docs/PROFESOR_P4_C.md` y bloque P5 del inventario. No deducir credenciales.
Commit de evidencia: `test: documentar ensayo integral del modulo docente`.

### D2 y D3 — Legado y panel real (D3 pausado)

D2: revisar visualmente herramientas ya implementadas de duplicados, huellas,
reclasificación y CLOZE; operar legado solo con autorización/respaldo y sin cambiar
resultados históricos. D3: conectar panel a la API correcta con ADMIN, CORS concreto,
HTTPS y caducidad; crear contenido autorizado y comprobar persistencia tras reingreso.
Guardar válido publica directamente: no recuperar la revisión editorial antigua.
Probar conflictos, duplicados y borrado solo permitido. No activar banderas de escritura
a ciegas. Rutas: `admin`, `backend/src/admin`; leer `docs/ADMIN_PANEL.md`.
Commits: `fix: cerrar controles editoriales pendientes` y
`test: verificar panel conectado al backend real` según trabajo real.

### 7F-C4 — Catálogo y sincronización

Contrato versionado para altas/cambios/retiradas, actualización de Flutter sin
recompilar, invalidación de caché y conservación de progreso. No mostrar borradores
en nuevas actividades ni sobrescribir intentos históricos. Probar offline/reconexión.
Revisar `lib/features/academic`, `study`, `lib/core`, API académica y `docs/OFFLINE_SYNC.md`.
Commit: `feat: sincronizar catalogo academico versionado`.

### 7F-C5 — Archivos persistentes (dependencia de fotos)

Carga autorizada, almacenamiento persistente, tipo/tamaño, metadatos, licencias y
texto alternativo; imágenes también dentro de opciones de respuesta. Diferenciar
recursos públicos de evidencia institucional privada, normalizar fotos y retirar
metadatos sensibles. Probar reinicio/despliegue y acceso de otra cuenta. Reutilizar
carga institucional existente; no guardar archivos permanentes en disco efímero
de Render. Rutas: admin, módulos académicos/institución, Prisma y cliente de recursos.
Commit: `feat: agregar archivos persistentes con permisos`.

### 7F-C6 — Versiones y recuperación editorial

Historial de actor/cambio/fecha, restauración controlada y correcciones sin modificar
la pregunta que ya fue respondida en un intento. Respaldo y restauración ensayados.
No convertir eliminar borrador vacío en borrado en cascada. Rutas: admin, Prisma,
servicios académicos. Commit: `feat: agregar versiones y auditoria editorial`.

### 7F-B3-B / 6F-P — Integración móvil y juegos reales

Inventariar migraciones/commits de Guardián, Cima, Rescate, Escudo y otros juegos;
desplegar solo con autorización. Probar sesión, contenido, diagnóstico, progreso,
recuperación, reloj y dos dispositivos en multijugador. No rehacer motores por
falta de despliegue. Auditar audios: el propietario reportó que solo escuchaba
Tira y afloja; llamadas en código no prueban reproducción. Ver GUIA_TRABAJO_COMPANEROS
y GAMES_PRODUCTION_CHECKLIST. Commit: `fix: completar integracion real de juegos`.

### Identidad, contratos y seguridad (bloque 7)

Auditar/completar sesión única, revocación, refresh y rotación, cambio inicial de
contraseña protegido en servidor, recuperación y eliminación de cuenta/datos.
SMTP/enlaces reales, límites de solicitudes, errores uniformes/OpenAPI versionado,
consentimiento y privacidad de adolescentes. Panel ADMIN de cuentas con búsqueda,
alta excepcional/invitación y suspensión auditadas; suspender no equivale a borrar.
Rutas: auth, config, common, mail, admin y Flutter auth/core. Dividir en entregas
pequeñas probadas por rol. Ejemplo: `fix: reforzar revocacion y aislamiento de sesiones`.

### Contratos académicos remotos (bloque 8)

Recuperar intentos/resultados sin duplicar calificación/XP. Contrarreloj autoritativo,
omisiones diferenciadas y entrega parcial; historial AM/PM, pruebas históricas
autorizadas y reglas de integridad sin castigos automáticos inventados. Sincronizar
favoritos, difíciles, flashcards, objetivo y tiempo; evaluar qué reanudación se puede
transferir, resolver conflictos offline y limpiar datos al cambiar cuenta. No
almacenar claves protegidas permanentemente. Revisar módulos correspondientes de
`lib/features`, simulacro/diagnostico y contratos en docs. Separar commits por función,
por ejemplo `feat: sincronizar favoritos por cuenta`.

### Certificados (bloque 9)

Los seis ya están integrados localmente. Desplegar/probar HTML→PDF y descarga en
dispositivo, nombres largos, logo y Sabi, área incompleta/vacía y final de cinco.
Discutir conservación del derecho cuando se publican nuevas lecciones, no cambiar
reglas sin acuerdo. Revisar módulos de gamificación y plantilla existente.
Commit: `fix: verificar emision de los seis certificados`.

### 8A–8B — Billing y derechos comerciales

Google Play Billing, validación de servidor, renovación, restauración, vencimiento,
reembolso y cambio de cuenta. Precios acordados son hipótesis/configuración comercial:
9.900 mensual, 49.900 seis meses (promoción 39.900), 69.900 anual; confirmar producto
y modalidad con propietario, mostrar precios de Play. No bloquear estudio gratuito.
Conectar límites institucionales vigentes con derechos, sin rehacer analíticas.
No activar cobros reales iOS ni Wompi/ePayco. Rutas pagos/anuncios y cliente existente.
Commit: `feat: integrar derechos verificados de Google Play`.

### 8C–8D — Anuncios, racha y comodines

Primero acordar ubicaciones con propietario. Voluntarios recompensados con SSV,
concesiones de uso único/expiración y consumo autoritativo. Recuperación de racha y
ayudas por juego deben tener reglas explícitas; no prometer volver a cualquier
pregunta sin verificar motor. Sin tope comercial diario de potenciadores, pero con
disponibilidad, antifraude y límites técnicos; sin anuncios, misma recompensa sin
video según derecho confirmado. Partidas asistidas fuera del ranking competitivo.
Nunca segmentar por falencias ni interrumpir evaluación. Probar falta de inventario
y callback repetido. Revisar GAMIFICATION_CONTRACT y BUSINESS_MODEL.
Commit: `feat: integrar recompensas publicitarias verificadas`.

### Cierre 7J — Contenido y operación editorial

Cargar contenido autorizado desde panel por área/tema/subtema, explicación y
respuesta correcta. Banco piloto de referencia 30 preguntas por área y objetivo
inicial 100+, sin confundir cantidad con cobertura/calidad. Revisar fórmulas,
glosario, becas/universidades/datos oficiales con fuentes/fecha y soporte real.
No importar cuadernillos sin permiso ni datos reales para una demo. Coordinar con
autores de contenido. Commit documental: `docs: registrar revision del banco academico`.

### 8E — Privacidad y licencias

Inventario de datos/SDK, términos, privacidad y eliminación en HTTPS; audiencia
real incluye menores de 18. Evidencia de derechos de preguntas, imágenes y audios;
«libre de regalías» no sustituye licencia. Revisar requisitos vigentes al ejecutar
esta etapa; advertir que proyecciones/becas no son garantías oficiales.
Commit: `docs: completar privacidad y licencias de lanzamiento`.

### 8F — Seguridad, rendimiento y operación

Entorno producción separado, secretos, respaldos/restauración, logs sin datos
sensibles, alertas y reversión. Auditar roles, archivos, claves de respuestas,
dependencias, carga, Socket.IO, exportaciones, batería y tamaño. Revisar deuda
técnica documentada, no asumir que build debug valida release/iOS. Corregir y
probar cada hallazgo. Commit por corrección, por ejemplo `fix: proteger acceso a recursos privados`.

### UI-F — Azul y animaciones finales (antes de beta)

Primero aprobar muestras de inicio/perfil/pregunta con propietario. Sistema visual
compartido azul S+, botones/tarjetas/espaciado/tipografía consistentes, claro/oscuro/
sistema. No saturar fondos ni alterar lógica. Integrar Sabi y animaciones profesionales
al final, con reducción de movimiento. Fantasma persigue récord; victoria atrapa y
celebra con fantasma, derrota lo deja escapar. Guardián/Tira y afloja según guías,
sin convertir prototipos en arte aprobado. Rutas `lib/app/theme.dart`, componentes
compartidos y features. Probar texto grande, contraste y teléfono pequeño.
Commit: `feat: unificar diseno azul y accesibilidad de SaberPlus`.

### 8G — Integral y beta

E2E con staging autorizado, Android de distintos tamaños, red lenta/offline, cierre,
sesión reemplazada, cambio de cuenta, compras/anuncios de prueba, PDF, audios,
multijugador y permisos. Registrar incidencias, corregir y repetir. Sin demo ni
contenido ficticio en release. Commit: `test: documentar validacion integral y beta`.

### 8H — Entrega iOS

Compilar/probar en macOS/Xcode, Keychain, SQLite, enlaces, notificaciones, PDF,
audio y animaciones. Conservar plataforma; no prometer pruebas iOS desde Windows.
Sin publicación comercial ni cobros reales iOS autorizados en este alcance.
Commit: `fix: preparar y verificar entrega tecnica iOS`.

### 8I — Google Play

Firma protegida, applicationId/versiones/AAB, ficha/capturas posteriores a UI-F,
datos/anuncios/audiencia, acceso de revisión y precios. Consultar requisitos actuales
de la cuenta de Play; pruebas y lanzamiento gradual con permiso del propietario.
No subir keystore/contraseñas. Commit: `chore: preparar lanzamiento de SaberPlus en Google Play`.

### 9A — Mantenimiento

Asignar responsables antes de publicar: errores, costos, respaldos, seguridad,
tráfico publicitario, compras, contenidos/licencias, dependencias y métricas agregadas
sin enviar falencias a publicidad. Es operación continua, no bloqueo eterno del
lanzamiento. Commit: `docs: definir operacion y mantenimiento de SaberPlus`.

Opcionales fuera de la ruta inmediata: push remoto, automatización de oportunidades,
importación masiva con guardado y expansión de juegos/cosméticos. Ver el inventario;
no añadirlos por iniciativa propia ni resucitar Taller de inventos.

## 6. Cómo hacer cambios sin pisarse

Elegir una etapa y responsable, anunciar archivos previstos y crear una rama por
entrega en cada repo afectado. No trabajar directamente en main. Antes de actualizar:

```powershell
cd "C:\Proyectos\saber_plus"
git status --short
git switch main
git pull --ff-only origin main
git switch -c feat/ma2-mapa-aprendizaje
```

Repetir desde `C:\Proyectos\SaberPlus-Backend` si la entrega lo necesita. **Si hay
cambios locales, detenerse antes de switch/pull**, identificarlos y conservarlos en
su rama/commit; no resetearlos ni descartarlos. Si `--ff-only` falla, revisar divergencia
con el equipo, no usar force push. Coordinar especialmente `schema.prisma`, rutas,
bootstrap, dependencias y migraciones. No editar migraciones ya aplicadas.

Secuencia por entrega: contrato/reglas → servidor autorizado → demo y repositorio
remoto → pantalla → pruebas → documentación. Una UI no concede XP, permisos o premios.
Usar transacciones/idempotencia cuando haya reintentos; no ocultar errores con datos demo.
No hacer `git add .` sin revisar; elegir rutas y mirar lo que realmente se publicará.

Ejemplo **real para publicar solo esta guía** desde la máquina del propietario:

```powershell
cd "C:\Users\LENOVO 14ALC6\Desktop\SaberPLus\saber_plus"
git add README.md docs/RELEVO_EQUIPO.md docs/GUIA_TRABAJO_COMPANEROS.md docs/ETAPAS_PENDIENTES.md
git diff --cached --stat
git diff --cached
git commit -m "docs: agregar guia de relevo y ruta de etapas para el equipo"
```

Para futuras etapas, reemplazar la selección por **los archivos que realmente
cambió esa etapa**. Ejemplo de una corrección limitada a cobertura, no orden de
crear un commit vacío ni incluir trabajo ajeno:

```powershell
cd "C:\Proyectos\SaberPlus-Backend"
git status --short
git add admin/public/bank-coverage.mjs admin/test/bank-coverage.test.mjs
git diff --cached
git commit -m "fix: corregir vista de cobertura del banco"
git push -u origin HEAD
```

`git add` prepara, `git commit` guarda localmente, `git push` publica la rama; ninguno
de los dos primeros sube por sí solo a GitHub. Crear PR hacia main con resumen,
pruebas, screenshots si aplica y pendientes. Una segunda persona revisa e integra
según acuerdo del propietario. No fusionar automáticamente ni desplegar por crear PR.
Si toca ambos repositorios: dos commits/PR enlazados, indicar compatibilidad y orden
de integración/despliegue. No dejar Flutter exigiendo una API no disponible sin manejo.

## 7. Cierre obligatorio de cada entrega

Actualizar README, HISTORIAL_ETAPAS, ETAPAS_PENDIENTES y contrato específico si cambió
su estado. Cambiar todas las referencias de «siguiente» para que no se contradigan.
Cada informe al equipo debe incluir:

```text
Etapa y alcance completado:
Repositorios/ramas/commits y PR relacionados:
Archivos modificados y para qué:
Pruebas ejecutadas y resultado (incluidos fallos previos):
Verificación visual/dispositivo realizada o pendiente:
Migraciones nuevas y permisos necesarios (no aplicadas si no se autorizó):
Qué sigue sin desplegar o no está terminado:
Siguiente etapa:
Comandos exactos de cd, git add y git commit para CADA repositorio:
```

## 8. Mensaje para retomar con otro asistente

> Lee docs/RELEVO_EQUIPO.md y sus referencias, revisa el estado Git de Flutter y
> SaberPlus-Backend y audita antes de modificar. El propietario delegó continuación
> local al equipo. Sigue MA-2 después de documentar la línea base; no rehagas MA-1
> básica ni los juegos existentes. P5/D3 y despliegues están pausados. Respeta top50,
> todas las insignias anuales, seis certificados y estudio gratuito; animaciones al
> final. Trabaja una entrega acotada, añade pruebas, actualiza etapas y entrega rutas
> y mensajes de commit de ambos repositorios. No expongas secretos ni hagas operaciones
> sobre bases compartidas, commits/push o despliegues sin petición explícita.
