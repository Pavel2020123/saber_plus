# Estabilización previa a PR-I1 — 29 de septiembre de 2026

Alcance autorizado: completar lock reproducible, corregir privacidad de Tira y obligación de contraseña inicial confirmada; delimitar dependencias/lint/ranking/institución. No PR-I1, upgrades, commits o infraestructura. Complementa la auditoría, no la sustituye.

## Tira: trazabilidad antes de modificar código

Hecho comprobado: `TiraAflojaService.obtener` consulta relaciones jugadorA/jugadorB con select `{id,nombre,fotoPerfil}` y devuelve `partida.yo`, `partida.rival`, `ganadorId`; devuelve además `eventos[].datos` JSON sin filtrar. Eventos EMPAREJADA, ABANDONO y FINALIZADA pueden contener jugadorBId/abandonoUsuarioId/ganadorId internos. Esto alcanza a cualquier estudiante autorizado emparejado como participante, no a terceros: obtenerLado rechaza ajenos. La identidad académica no tiene consentimiento público por el contrato actual de privacidad/perfiles.

HTTP exacto: POST `/tira-afloja/emparejamiento` (área opcional), GET `/tira-afloja/activa`, GET `/tira-afloja/:id` (desdeVersion opcional), POST `/:id/listo`, POST `/:id/respuestas` (ronda, preguntaId, respuestaId, idempotencyKey), POST `/:id/abandonar`. Todos delegan directa/indirectamente a obtener y retornan `{servidorAhora,partida,eventos}`. JwtGuard+EmailVerificadoGuard; servicio comprueba pertenencia.

Socket namespace `/tira-afloja`: handshake/recuperación y acciones `tira:emparejar`, `tira:sincronizar`, `tira:listo`, `tira:responder`, `tira:abandonar` emiten `tira:estado` con el mismo snapshot. `tira:presencia` emite `{usuarioId,conectado,servidorAhora}` en entrada/desconexión. `tira:actualizada` solo contiene partidaId/servidorAhora; `tira:conectado` partidaId/version/recuperada/servidorAhora. No se publica contenido privado por esos dos últimos eventos.

Flutter: `TugOnlinePlayer.fromJson` recibe id/nombre/fotoPerfil. `tug_online_page.dart` muestra nombres en preparación, marcador y resultado. avatarUrl se parsea pero esa UI no lo usa. `TugOnlineSnapshot.winner` compara ganadorId con me.id; `TugOnlineController` compara presencia.userId con rival.id. Esas comparaciones requieren consistencia dentro de la partida, no UUID de cuenta. Las peticiones de juego usan partidaId y IDs de pregunta/respuesta; esos identificadores de recursos sí son necesarios.

Pruebas previas: gateway prueba conexión/latido con autenticación simulada; reglas prueban cálculo; Flutter tug_online_test prueba parseo, matchmaking, estado, presencia y UI con jugadores ficticios. No había prueba de servicio que prohibiera identidad privada. `repro-seguridad.cjs` de auditoría documenta la fuga anterior y queda histórico; no es una regresión que deba seguir pasando tras el arreglo.

Parche mínimo previsto: conservar claves/tipos de DTO para el cliente actual, con id A/B (referencia de asiento, **no identidad pública de cuenta**), nombre Jugador A/B y fotoPerfil null. ganadorId/presencia usan la misma referencia A/B. No crear alias de perfil, consentimiento, HMAC público o migración. Los UUID de cuenta se conservan solo para autorización y persistencia interna. Sanear datos históricos al presentar por lista de campos permitidos y convertir referencias de participantes. No tocar otros juegos.

## Contraseña temporal: requisito confirmado antes del parche

Altas vigentes: POST `/institucion/me/estudiantes` y POST
`/institucion/me/estudiantes/importar-csv`, con ProfesorInstitucionGuard sobre
la autenticación de la clase; profesor/ADMIN con institución y autorización
del servicio sobre membresía/cupos/grupo. No es un endpoint público de creación
arbitraria. Las cuentas existentes agregadas o invitadas conservan su contraseña.

`EstudianteService.crearEstudiante` y `EstudianteImportService` crean estudiantes institucionales con contraseña provista/temporal hasheada y `debeCambiarContrasena=true`; el alta/autorización de institución y grupo controla quién puede crearlos. Registro público crea contraseña elegida por titular; no marca cambio inicial. Las invitaciones/membresía de cuentas existentes no convierten automáticamente su contraseña en temporal. `Usuario` tiene flag persistido.

`AuthService.login` comprueba bcrypt y firma JWT; entrega flag en usuario, no como autoridad en claim JWT. `obtenerPerfil` también entrega flag. `cambiarContrasenaInicial` solo acepta flag true y consume el cambio mediante updateMany con hash anterior, cambia hash y pone false. Flutter UserSession, login/router/session_route_policy y ChangeInitialPasswordPage conocen y exigen ese estado. ADMIN api.mjs consulta perfil y rechaza flag distinto de false. Es evidencia de implementación vigente, no una frase histórica aislada.

Defecto: JwtGuard/AdminGuard verifican firma y rol actual pero no el flag; WebSocket tiene autenticación independiente. Un cliente directo puede ignorar ambos bloqueos UI.

Solución prevista: consultar estado en DB y bloquear acciones autenticadas con 403. Excepciones explícitas de método en servidor: GET `/auth/perfil` para restaurar sesión mínima y PATCH `/auth/cambiar-contrasena-inicial` para resolver obligación. PATCH perfil no es excepción. No existe logout backend: Flutter/ADMIN eliminan token localmente, no requieren permiso de API. Login/recuperación/verificación públicos siguen sujetos a sus propios contratos y no autorizan acceso protegido. ADMIN directo y handshake Socket deben bloquear también. No se introduce revocación general de sesiones en este parche.

## Resultados

Parche de privacidad aplicado exclusivamente al servicio/gateway Tira: elimina consultas de nombres/fotos, publica asientos A/B y etiquetas neutras, sanea eventos persistidos mediante allowlist, transforma presencia y ganador. Los IDs de partida/preguntas/opciones permanecen porque las acciones los necesitan; IDs internos de usuario permanecen en DB/servidor. Compatibilidad comprobada con el parser Flutter vigente; no se modificó su código productivo. Se añadió una prueba Flutter de ganador/presencia sin identidad privada. No crea una política de perfil público ni un alias rastreable entre partidas.

Parche de contraseña aplicado: helper de rechazo 403 con código INITIAL_PASSWORD_CHANGE_REQUIRED; JwtGuard consulta DB y admite solo metadata explícita del método GET perfil/PATCH cambio inicial; AdminGuard no admite excepción; autenticación de Socket también exige cambio completado. Perfil temporal entrega solo id/nombre/correo/rol/flag, necesarios para el contrato actual de sesión. No entrega XP, foto, descripción ni plan. Las dos excepciones siguen requiriendo JWT válido. El cambio de contraseña conserva la validación/CAS existente; la restricción se vuelve a evaluar desde DB, no desde claims proporcionados por cliente.

Limitaciones: esto no implementa revocación de tokens ni reautenticación continua de sockets abiertos; es la obligación inicial para cuentas creadas con ese flag, no un mecanismo nuevo de suspensión de sesiones. Los sockets anteriores al parche deben reconectarse al desplegar en una futura operación autorizada. No se ejecutó infraestructura real ni migración.

## A. Lockfile y reproducción

Antes de editar código se volvió a confirmar Node24.14.1/npm11.11.0, diff 25+/0- exclusivamente en backend/package-lock.json para el bloque del lock, y package.json idéntico a HEAD. `npm ci --include=dev --prefix backend` pasó (825 añadidos/826 auditados), build pasó y Jest confirmó847 pruebas/84 suites. Después se añadieron los parches de seguridad como bloques separados: no confundir el estado total del árbol con los archivos del commit del lock. Mensaje recomendado: `fix: sincronizar lockfile reproducible del backend`.

## D. Dependencias — matriz previa a cualquier upgrade

No se cambió ninguna versión. Verificación con package-lock y `npm ls --omit=dev` confirma que los siete paquetes están en producción (dev=false). Cuatro high reflejan una misma cadena vulnerable, no cuatro entradas independientes explotables desde la API. Las correcciones candidatas se consultaron con `npm view`; no se instalaron ni se afirman validadas por los tests de esta ronda.

| Paquete | Severidad | Vulnerabilidad | Directa/transitiva | Dependencia padre | Versión actual | Versión corregida/candidata mínima | Breaking change | Código SaberPlus afectado | Explotabilidad real | Recomendación |
|---|---|---|---|---|---|---|---|---|---|---|
| multer | moderate | GHSA-3pph-fpjx-jg34: ficheros huérfanos al abortar diskStorage | Directa; también por Nest | package.json + platform-express; override $multer deduplica | 2.3.0 | 2.4.0 parche publicado | Minor; no major requerido, compatibilidad aún por probar | institucion/logo-upload.config.ts y POST /institucion/me/logo | Ruta vulnerable usada. Guards previos reducen a cuenta con permisos de logo; no se reprodujo DoS ni se afirma acceso anónimo. Importaciones memoryStorage no usan esta ruta diskStorage | **Corregir ahora como siguiente bloque autorizado**: actualización menor aislada; probar upload válido/abortado/límites/limpieza |
| @nestjs/platform-express | moderate | Mismo aviso transitivo de Multer | Directa | package.json | 11.1.28 | No necesita actualizar Nest para este aviso si override resuelve Multer2.4.0 | Ninguno requerido en Nest | FileInterceptor de logos/CSV/contenido | Mismo punto de entrada; no segunda vulnerabilidad independiente | **Actualización segura independiente**, conjunta al bloque Multer; comprobar deduplicación y audit resultante |
| extract-zip | high | GHSA-jmr9-qjv8-65gv y GHSA-7pqw-9j4j-h8q3: symlink/traversal/escritura exterior | Transitiva | @puppeteer/browsers | 2.0.1 | No parche publicado en esta librería; retirar la dependencia mediante rama Puppeteer25 | No reemplazo drop-in demostrado | Instalación/descarga de navegador en @puppeteer/browsers/fileUtil; no lector editorial XLSX/ZIP | No ruta de API que entregue ZIP del usuario a extract-zip. Riesgo en extracción de binario descargado si origen/archivo comprometido; no afirmar riesgo cero de supply chain | **No explotable por uploads de usuarios en uso revisado; vigilar** y migrar árbol de navegador separadamente |
| @puppeteer/browsers | high | Arrastra extract-zip | Transitiva | puppeteer y puppeteer-core | 2.13.2 | 3.0.2 ya no declara extract-zip; candidata ligada a Puppeteer25.0.2 | Major2→3; no override directo sobre Puppeteer24 | Instalador/caché navegador; certificado usa launch | Misma condición de instalación; render PDF no extrae ZIP suministrado por alumno | **Requiere migración/evaluación** del conjunto, no override aislado |
| puppeteer-core | high | Arrastra browsers/extract-zip | Transitiva | puppeteer | 24.43.1 | 25.0.2 candidato mínimo disponible consultado; acompaña browsers3.0.2 | Major24→25 | Control de navegador para certificados | Certificado usa HTML propio escapado y PNG data; no archive path de usuario | **Requiere migración/evaluación** conjunta con puppeteer, pruebas PDF reales |
| puppeteer | high | Cadena browsers/core/extract-zip | Directa fijada | package.json | 24.43.1 | 25.0.2 es primer25 disponible consultado y elimina esa cadena; audit propone25.12.0 | Major; Node>=22.12 satisfecho por24.14.1, pero no demuestra compatibilidad runtime | gamificacion/certificado-html.service.ts, launch headless/PDF | Mismo riesgo de extracción de instalación; no ejecución arbitraria demostrada desde certificado | **Requiere migración/evaluación**; validar importación CJS/ESM, navegador, interceptación, render visual, timeout/cierre antes de elegir versión final |
| nodemailer | moderate | GHSA-6vj9-mwq6-2f5v: cache DNS comparte servername entre transports SMTPS | Directa | package.json | 9.1.1 | 10.0.2 parche mínimo publicado; audit propone10.0.12 | Major9→10, engines>=20 compatible; API/tipos/correo por verificar | mail/mail.service.ts, un transport con SMTP de entorno | No transports por tenant ni servername aportado por usuario en código actual; falta precondición de transports con mismo host/distinto SNI. No se inspeccionó SMTP real | **No explotable en configuración de código revisada; vigilar**; actualización independiente con validación TLS/SMTP y tipos |

Fuentes primarias consultadas: [aviso Multer](https://github.com/expressjs/multer/security/advisories/GHSA-3pph-fpjx-jg34), [aviso Nodemailer](https://github.com/nodemailer/nodemailer/security/advisories/GHSA-6vj9-mwq6-2f5v), [extract-zip, symlinks](https://github.com/advisories/GHSA-jmr9-qjv8-65gv), [extract-zip, entradas repetidas](https://github.com/advisories/GHSA-7pqw-9j4j-h8q3), [release Puppeteer25.0.2](https://github.com/puppeteer/puppeteer/releases/tag/puppeteer-v25.0.2), metadatos npm de las versiones enumeradas y audit-produccion.json de la auditoría. Los avisos definen afectación; la explotabilidad de SaberPlus es inferencia del recorrido del código, no prueba ofensiva.

No es correcto llamar «actualización mínima segura validada» a25.0.2 o10.0.2: eliminan la dependencia/afectación concreta según metadatos/aviso, pero aún requieren pruebas de compatibilidad y audit completo de su árbol. No se ejecutó audit fix, force, overrides nuevos ni upgrades para lograr cero. Las suites verdes validan **el árbol actual**, no estos candidatos. Esta matriz se presenta antes de cualquier cambio de versiones, como solicitó el propietario.

## E. Lint anterior: clasificación, sin campaña de limpieza

Fuente exacta: `docs/auditoria-relevo-2026-09-28/lint-resumen.json`. Se conservaron111 errores/11 warnings de la línea base. Todos son preexistentes a esta estabilización; los archivos con deuda no se modificaron. Los módulos tocados por seguridad tienen lint dirigido limpio después de tipar sus pruebas.

| Regla | Cantidad | Archivos/módulos | Preexistente | Riesgo funcional | Recomendación |
|---|---|---|---|---|---|
| prettier/prettier | 68 errores | certificado-html.service19; certificados-curso.service18; su spec28; gamificacion.controller2/module1 | Sí | Formato; no defecto funcional inferido | Diferir; no autofix general |
| no-unnecessary-type-assertion | 22 errores | certificado-html2; certificados-curso1; guardian.service3; guardian.service.spec16 | Sí | Asserts/casts ocultan supuestos; 6 en productivo merecen contexto, no son por sí solos exploit | Revisar al tocar flujo; ver observaciones inferiores |
| no-unsafe-assignment | 9 errores | certificados-curso.spec1; guardian.controller.spec5; guardian.service.spec3 | Sí | Tipado de mocks/respuestas puede debilitar pruebas; no localizados en runtime | Tipar dobles cuando se modifiquen esas pruebas |
| no-unsafe-member-access | 5 errores | guardian.controller.spec1; guardian.service.spec4 | Sí | Tests podrían inspeccionar shape incorrecto sin aviso compilador | Igual; no refactor de Guardian en esta ronda |
| no-unsafe-return | 3 errores | guardian.service.spec3 | Sí | Mock retorna any; riesgo de cobertura engañosa | Tipar retorno del doble en entrega correspondiente |
| require-await | 4 errores | guardian.service.spec4 | Sí | async sin await de mocks; no prueba de promesa abandonada | Diferir; preservar semántica async de doble |
| no-unsafe-argument | 11 warnings | guardian.rules.spec4; guardian.service.spec7 | Sí | Entradas any de prueba, no evidencia de entrada insegura productiva | Tipar fixtures al modificar |

No hay no-floating-promises ni unused/variable incorrecta reportados en esta línea base. No se deduce ausencia global de problemas de promesas del lint. Revisión acotada de las6 aserciones productivas: HTML mapping/selector de plantilla propia; pregunta correcta en Guardian precedida por selección de preguntas válidas; serialización JSON de snapshots y narrowing de consultas. No se reprodujo defecto funcional adicional que justifique tocar certificados/Guardian ahora. Un selector ausente o snapshot inválido merece test cuando cambie ese flujo; no retirar guards/casts a ciegas para bajar el contador.

## F. Ranking 50/100 — decisión, sin modificación

`ConsultarRankingDto.limite`: entero3..100, default50. `RankingService` hace `entradas.slice(0, limite)`:100 es capacidad real de respuesta, no página, XP ni posición máxima permitida de cuenta. Flutter RemoteRankingRepository siempre envía50; RankingPage muestra esas entradas y miPosicion por separado. ADMIN no consume /ranking; sus límites100 de herramientas editoriales no son ranking.

En el cliente Flutter normal no aparece una lista51–100. Un cliente directo puede pedir100 y recibir esas entradas; no hay clamp50 en servicio. La posición propia puede ser51,100 o mayor en `miPosicion` aunque solo se pidan50, y la UI la muestra: eso está permitido por el acuerdo. En empates el corte es por cantidad de entradas, no por puestos distintos; no se cambió esa regla.

Acuerdo top50: `PERFILES_RANKINGS_INSIGNIAS.md` (decisión vigente, cancela top100), `INSIGNIAS_Y_JUEGOS_VIGENTES.md` y ruta de equipo. **NECESITA DECISIÓN DEL PROPIETARIO:** aplicar máximo50 también al contrato actual, conservando miPosicion sin límite, o mantener la capacidad100 del contrato legacy hasta un contrato nuevo. No se eligió ni implementó ninguna opción.

## G. Institución X → Y — simulación conceptual

Premisas: alumnoA estudiante,500 XP elegibles (por ejemplo ResultadoSimulacro) ganados mientras pertenece a X, luego Usuario.institucionId cambia a Y. `RankingService.obtenerRanking` carga candidatos con `rol=ESTUDIANTE` y `institucionId=solicitante.institucionId` **actual**; TOTAL lee xpTotal de esos usuarios. SEMANA/MES hace groupBy de ResultadoSimulacro/BatallaParticipante por los IDs candidatos y fecha mínima7/30 días. Esos registros no guardan institución del aporte.

| Vista | Antes (X) | Después (Y) |
|---|---|---|
| TOTAL | A aparece con500 en lista de estudiantes de X | A desaparece de X y aparece con500 en Y; no se borra XP de cuenta |
| SEMANA | Incluye los500 si sus eventos están dentro de últimos7 días | También siguen a Y **solo mientras entren en la ventana**; si ya vencieron, no se suman |
| MES | Incluye los500 si eventos dentro de últimos30 días | Mismo traslado de pertenencia con su ventana30 días |
| GLOBAL |500 según cada período | Cambio de institución no cambia candidatos globales ni fuente XP |

Esto es ranking de **alumnos del ámbito**, no un ranking persistido de colegios con saldo transferido. No existe cierre histórico que pueda conservar la lista anterior. No todos los500 de xpTotal tienen que estar en SEMANA/MES: además de fechas, esas vistas usan registros fuente concretos. La consulta causa el efecto retroactivo, no una operación que mueva filas de resultados.

| Alternativa | Datos | Privacidad | Cambio de institución | Migración | Ranking histórico | Complejidad | Compatibilidad |
|---|---|---|---|---|---|---|---|
| A. Historia sigue institución actual | Modelo actual basta | No revelar antigua membresía; el cambio de lista puede ser observable por miembros | Todo XP elegible visible en destino y deja origen | Ninguna por atribución | Recalcula pasado con miembros actuales; necesita explicar esa semántica | Baja | Mantiene contrato vigente |
| B. Atribución en institución al obtener XP | Requiere referencia temporal por aporte y política para sin institución | Guardar historial sensible de membresía; publicar agregados, acceso individual explícito | Nuevos aportes a destino; anteriores quedan origen | No inferir institución pasada a partir del campo actual; decidir corte y backfill verificable | Puede preservar resultados por institución de origen | Mayor: transacciones/correcciones/historial | Cambia significado de ranking; contrato/versionado necesarios |
| C. General actual + competitivo futuro histórico | Conservar actual para general; nuevos aportes competitivos con atribución temporal | Separar audiencias y evitar exponer lista histórica de alumnos | General sigue cuenta; competitivo queda donde se obtuvo | Arranque futuro sin inventar aportes antiguos; política corte necesaria | Histórico competitivo disponible desde corte; general sigue dinámico | Mayor por coexistencia y explicación | Conserva clientes legacy; nueva vista debe rotularse claramente |

Razón concreta para C: ya existe XP general sin institución histórica y la propuesta competitiva aún no existe; evita fingir una migración histórica demostrable. **No se recomienda como decisión tomada**: A/B/C quedan para el propietario en PR-I1. No se modificó schema, ranking, XP, temporadas ni insignias.

## H. Pruebas y límites de esta ronda

- Antes de parches: npm ci/build y847/84 pasan con versiones exactas solicitadas.
- Después: build pasa; **861 pruebas/86 suites** pasan,14 pruebas nuevas backend. Incluyen servicios con dobles de Prisma, HTTP Nest/supertest y conexiones Socket.IO loopback. No son pruebas de SQL/migraciones.
- Privacidad: ambos lados, tercero rechazado, eventos históricos, matchmaking, listo/respuesta, abandono/ganador y presencia conexión/desconexión. El motor de reglas original conserva sus tests.
- Contraseña: claim viejo falso no evade DB true; GET perfil permitido pero PATCH bloqueado; cambio permitido con JWT y acceso después; sin token401; ADMIN directo bloqueado; Socket bloqueado; perfil mínimo sin foto/XP. Pruebas originales de CAS/cambio único se mantienen. La prueba de plan vencido ahora configura contraseña ya cambiada para seguir comprobando su regla original, y otra comprueba el perfil temporal mínimo.
- Flutter:30 pruebas dirigidas (tug_online, session_route_policy, remote_auth_repository) pasan, incluyendo1 nueva de compatibilidad A/B. La línea base anterior631+4 omitidas no se presenta como ejecución completa nueva.
- ADMIN no cambió: línea base88 anterior, sin nuevo ensayo visual. APK/Java y PostgreSQL continúan con sus limitaciones anteriores; no se intentó sortearlas.
- Hubo errores de compilación en el primer fixture nuevo (tipos de estado y Array.at incompatible con target del proyecto); se corrigieron en el fixture, sin cambiar tsconfig o esconder pruebas. Luego se corrigieron tipos de mocks para no introducir deuda lint.

Las versiones propuestas de dependencias **no están probadas**, pues no se aplicaron. El riesgo SMTP real, DoS de uploads y extracción de navegador requiere ensayos aislados en el bloque que se autorice; esta entrega no afirma exploit en producción ni riesgo cero.

Tras el ajuste final de tipos de los fixtures:52 pruebas dirigidas/8 suites
aprobadas y lint del alcance tocado0 errores/0 warnings. `git diff --check`
pasa en ambos repositorios. No hubo nuevas modificaciones productivas después
del build/suite completa861. El hash del pubspec.lock ajeno sigue siendo
2CB0D83AEB4D55AED93870E5F3F4930B78C225317A5EF35E2A13C16D4D2714A4.

## I. Archivos y Git

La [guía de commits](COMMITS_ESTABILIZACION_2026-09-29.md) enumera todos los
archivos acumulados y los seis bloques separables: lock backend, privacidad
Tira backend, autenticación backend, notas históricas backend, documentación
Flutter y prueba Flutter. Incluye rutas verificadas con Get-Location, ramas
existentes/propuestas y comandos exactos con git add por archivo y revisión
de staging antes de commit. No se ejecutó staging, commit o cambio de rama.

## J. Auditoría preservada

Solo se añadió una nota inicial y adenda de resultados a la auditoría aceptada.
No se regeneró su inventario, no se reescribieron hallazgos históricos ni se
presentó el script antiguo de reproducción como regresión verde del parche.
Hipótesis de explotación remota siguen delimitadas; ranking50/100, alternativa
institucional y upgrades esperan decisiones del propietario. No PR-I1.

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
