# SaberPlus — etapas pendientes y ruta vigente del equipo

## Estado vigente — validación local del 6 de octubre de 2026

**I2-5 abierto.** [Informe de esta ejecución](VALIDACION_LOCAL_I2_5_2026-10-06.md):
PostgreSQL competitivo completo 347/347, dirigido 12/12 y otros nueve modos
102 pruebas aprobadas; API/login/ranking Flutter real 6/6 y corrección 5/5.
Flutter global final 694 aprobadas/9 opt-in omitidas; backend Jest 1.258/1.258.
APK local separada compilada e instalada; falta completar comprobación física.
Panel predeterminado falla, serial 88/88; lint 567 errores/150 avisos;
audit 13 paquetes afectados, producción 1 critical. No declarar todo aprobado.
Trabajo autorizado en main, sin commit/push. B1/B2, P5/D3 y activación no se cierran.
El estado del 5 de octubre siguiente se conserva como antecedente histórico.

## Estado vigente tras recibir el trabajo de Luis — 5 de octubre de 2026

Ampliación acordada: [filtros territoriales y orientación por intereses](ORIENTACION_Y_TERRITORIO.md).
PR-I5-T: departamento/municipio en instituciones; PR-I6-T: ranking institucional
territorial; OV-1A/B/C/D: cuestionario orientativo, persistencia privada, resultados
y Sabi por profesión. Planificados, no implementados. I2-5 conserva prioridad;
OV-1 se programa antes de UI-F/beta, sin convertir afinidad en diagnóstico.

Git local confirma Flutter PR #3 integrado en `1921ba9` y backend PR #6
integrado en `66b5aa2`; PR-I1 ya estaba integrado por `5216383`.
El informe de Luis describe el momento anterior a esos merges: sus menciones
a PR abiertos y revisión para publicar son históricas, no tareas pendientes.

**Siguiente checkpoint: I2-5, validación integrada y cierre de PR-I2.**
I2-1/2/3 (API) e I2-4 (consulta Flutter) se conservan; no rehacerlos. El cierre
requiere PostgreSQL aislado, sesión y API reales locales, navegación, privacidad,
TOP/posición propia, estados vacíos/no disponibles, correcciones y ranking legacy.
La regresión PostgreSQL completa y la prueba física siguen pendientes.

Auditoría de recepción: build y 1.258 pruebas backend correctas; Flutter analyze
limpio y suite global 691 aprobadas/4 omitidas (requieren entorno real); panel
88 aprobadas. Son resultados anteriores a la corrección visual de esta entrega,
no evidencia E2E. Se corrigen filtros y errores del ranking para pantalla pequeña,
teclado y texto ampliado, con pruebas de regresión propias.

Validación posterior a la corrección: `flutter analyze --no-pub` sin incidencias;
91/91 pruebas dirigidas (ranking competitivo, ranking legacy, catálogo, interceptor
y Tira), incluidas tres regresiones nuevas de accesibilidad/teclado y reintento.
585 enlaces locales comprobados entre ambos repositorios, ninguno ausente;
`git diff --check` correcto. La suite global no se repitió tras este ajuste visual;
su resultado de recepción no se presenta como validación posterior del cambio.

I2-4 consulta rankings, **no activa partidas competitivas en Flutter**. El cableado
de admisión/presencia de los clientes de juego debe validarse y planificarse antes
de activar competición; no introducirlo silenciosamente en I2-5 ni inferir que
ya funciona por tener lector de rankings. Memoria/Batallas siguen NO_DISPONIBLE:
su integración competitiva es otro alcance, no un requisito oculto de PR-I2.

Se conservan las decisiones de Luis: Trivia cuenta el resultado definitivo para
la racha; Duelo empata por puntuación y sin fantasma solo otorga XP base; Tira
respeta la precedencia terminal/gracia/global, UNKNOWN no implica abandono y
gracias simultáneas cancelan sin XP ni penalización. No reabrir esas reglas.

B1/B2 productivos, Render/Supabase, P5/D3, migraciones remotas y flags siguen
pendientes y no se ejecutan en esta entrega. Después de cerrar I2-5: PR-I3 y
PR-I4/5/6/7 según dependencias. El resto del inventario inferior se conserva.
El relevo de Luis también reportó deuda histórica de lint backend (111 errores,
11 avisos) y dependencias (4 high, 3 moderate). No son recuentos vigentes ni se
declaran resueltos: repetir análisis no mutante y auditoría de dependencias antes
de producción, priorizando riesgo; no ejecutar `npm audit fix --force` a ciegas.
Para continuar usar [PROMPT_RELEVO](PROMPT_RELEVO.md). Esta sección prevalece
sobre las menciones históricas inferiores a publicar/cerrar I2-4.

## Histórico: PR-I2 / I2-4 antes de la fusión (5 de octubre de 2026)

Esta actualización prevalece sobre el estado histórico PR-I1 de abajo para este
checkpoint. Backend verificado en `9e9f2f9`, rama `feat/pr-i2-competitive-rankings`;
PR-I1 integrado/cerrado para esta ruta; Backend I2-1, I2-2 e I2-3 completados
en su rama según el contexto confirmado del propietario.
Flutter exclusivamente en `saber_plus_pr_i2`, rama
`feat/pr-i2-competitive-ranking-flutter`, base `6903816`. Ambos árboles estaban
limpios al iniciar. Backend y Flutter original no modificados.

I2-4 implementado y validado localmente. La revisión humana de código y pruebas
ya se realizó; la documentación quedó conciliada y queda la revisión final antes
de autorizar el cierre/publicación del propietario. **No desplegado y no declara
PR-I2 completo**. Durante la implementación de I2-4
se conservaron los seis archivos existentes y se añadieron cinco archivos de
pruebas/fixtures. Dependencias y configuración de análisis permanecen intactas.

### Arquitectura y experiencia

[Modelos](../lib/features/ranking/domain/competitive_ranking_models.dart),
[repositorio](../lib/features/ranking/data/competitive_ranking_repository.dart),
[providers](../lib/features/ranking/presentation/competitive_ranking_providers.dart)
y [pantalla](../lib/features/ranking/presentation/competitive_ranking_page.dart).
Acceso desde el ranking general, que conserva `/ranking`; nueva consulta
`GET /ranking/competitivo` solamente con juego y temporada, usando Dio/JWT
existentes. Parsing estricto, tres estados, TOP/posición propia del servidor,
errores HTTP seguros y estado Riverpod separado. Año sugerido con UTC−5 de Bogotá
y reloj local editable; no es autoridad sobre la temporada devengada. Seis juegos
integrados (Cima, Guardián, Rescate, Trivia, Duelo y Tira); Memoria/Batallas
no disponibles. Demo no inventa clasificaciones ni abre el cliente HTTP: pide
una cuenta de estudiante.

El botón «Ver ranking competitivo» de [RankingPage](../lib/features/ranking/presentation/ranking_page.dart)
abre una pantalla independiente y permite volver al ranking general conservando
su selección. Catálogo de ocho juegos, año editable 1..9999, TOP 50, bloque propio
incluso en posición 51, carga, reintento y actualización por gesto. Los resultados
anteriores no se muestran como el nuevo filtro durante una consulta pendiente.
SIN_PARTICIPANTES (total 0) y NO_DISPONIBLE (total null) tienen mensajes distintos.

El parser exige campos públicos exactos, enteros/rangos, orden y coherencia de
TOP/posición propia; rechaza datos privados, respuestas malformadas o de otro
juego/año. Nunca calcula XP, posiciones o alias. No envía usuarioId, institución,
limite, filtros legacy ni body. El provider remoto recibe el Dio existente y
su interceptor/session security; no duplica almacenamiento ni verificación JWT.
HTTP 400 indica entrada inválida, 401 sesión no válida, 403 acceso prohibido;
500/503 y fallos de red muestran mensaje seguro y reintento. No se muestran
bodies remotos, SQL, Prisma, UUID o detalles internos, ni se convierten fallos
en rankings vacíos. Error al actualizar por gesto queda observable en Riverpod
y finaliza el gesto sin una excepción asíncrona secundaria.

### Validación con Flutter 3.47.0 / Dart 3.13.0

SDK usado explícitamente: `C:\Users\luisk\Documents\flutter_3_47_0\bin`.
El propietario resolvió el bloqueo externo y confirmó pub get con lock obligatorio.
Aquí se verificaron versión local, package_config (las siete versiones coinciden
con el lock publicado) y ausencia de diferencias Git en pubspec.yaml,
pubspec.lock y analysis_options.yaml. `--no-pub` conserva esa resolución preparada.

```powershell
$sdk = 'C:\Users\luisk\Documents\flutter_3_47_0\bin'
& "$sdk\flutter.bat" analyze --no-pub
& "$sdk\flutter.bat" test --no-pub test/competitive_ranking_models_test.dart test/competitive_ranking_repository_test.dart test/competitive_ranking_providers_test.dart test/competitive_ranking_page_test.dart test/ranking_test.dart test/ranking_badge_catalog_test.dart test/auth_interceptor_test.dart --reporter expanded
git diff --check
git diff --exit-code -- pubspec.yaml pubspec.lock analysis_options.yaml
```

Se ejecutó dart format de ese mismo SDK sobre los cinco Dart de implementación,
cuatro suites nuevas y el fixture. Pruebas finales: **81/81**, siete archivos,
exit 0, 14 s indicados por el reporter, sin omitidos reportados.
Análisis final de todo el proyecto: **sin issues, exit 0, 51,5 s**.
`git diff --check` correcto; diez enlaces locales de esta sección comprobados.
pubspec.yaml, pubspec.lock y analysis_options.yaml sin diferencias frente a HEAD.
[Modelos](../test/competitive_ranking_models_test.dart): estados, límites,
privacidad, enteros, TOP/propio, anomalías y límite anual de Bogotá.
[Repositorio](../test/competitive_ranking_repository_test.dart): GET/query/body,
JWT del interceptor real, logout, estados 200, errores 400/401/403/500/503 y
respuesta de otro filtro. Transporte simulado, sin acceso a backend remoto.
[Providers](../test/competitive_ranking_providers_test.dart): carga, filtros,
respuesta antigua tardía, error/reintento, independencia legacy, Dio existente y demo.
[Widgets](../test/competitive_ranking_page_test.dart): TOP/puesto 51, filtros/carga,
estados, errores/reintento/gesto, año inválido y navegación ida/vuelta a ranking general.
[Fixture ficticio](../test/helpers/competitive_ranking_fixture.dart).
Se conservaron y ejecutaron ranking_test, ranking_badge_catalog_test y
auth_interceptor_test sin cambios, incluyendo los assets existentes del catálogo;
no se crean ni conceden insignias.

Incidencias intermedias conservadas: primer análisis exit 1, dos avisos de llaves
en pruebas nuevas, corregidos. Primera batería **79/80**, un fallo al construir
un fixture negativo (lista tipada no aceptaba null antes del parser); se cambió
su construcción a lista Object? y se mantuvo la aserción de rechazo.
Prueba aislada adicional de actualización por gesto **0/1**, reprodujo excepción
asíncrona en onRefresh; corrección acotada en pantalla y regresión incluida en
el 81/81 final. Logs locales en TEMP: sp-i2-4-tests-347-1.log,
sp-i2-4-refresh-regression-before.log, sp-i2-4-tests-347-final.log y
sp-i2-4-analyze-347-final.log.

### Antecedente SDK resuelto (no es bloqueo vigente)

La preparación anterior con Flutter **3.44.9 / Dart 3.12.2** fijaba clock 1.1.2,
intl 0.20.2, matcher 0.12.19, meta 1.18.0, stack_trace 1.12.1,
test_api 0.7.11 y vector_math 2.2.0. El lock publicado usa respectivamente
1.1.3, 0.20.3, 0.12.20, 1.19.0, 1.12.2, 0.7.12 y 2.4.2.
`flutter pub get --offline` resolvió esas siete diferencias; no se añadió una
dependencia. `flutter pub get --offline --enforce-lockfile` terminó exit 1:
`Unable to satisfy pubspec.yaml using pubspec.lock`. Las versiones fijadas se
comprobaron en los pubspec del SDK flutter/flutter_test/flutter_localizations.
Se restituyó únicamente el lock generado en esta copia a su contenido de HEAD.
El propietario instaló después Flutter 3.47.0 de forma aislada, sin modificar
dependencias; las validaciones vigentes son las de la sección anterior.

Análisis inicial antes de implementar: `flutter analyze --no-pub`, sin issues,
65,1 s, con resolución local del SDK; no prueba compatibilidad del lock publicado.
Se formatearon los cinco archivos Dart afectados; entonces no había pruebas
focalizadas ni certificación funcional, completadas en esta continuación.
Análisis del avance: primera ejecución exit 1 con 12 avisos nuevos (casts,
llaves y resultado refresh); corregidos. Segunda ejecución exit 0, sin issues,
28,3 s, usando la resolución local previa y `--no-pub`. Esto no elimina el
bloqueo de compatibilidad del lock en aquel momento. `git diff --check` y cuatro
enlaces nuevos eran correctos. No se había ejecutado `flutter test`.

### Continuidad y límites

Conciliación documental realizada. Siguiente acción: revisión final de I2-4 antes de
autorizar commit/publicación del propietario. I2-5 es el siguiente checkpoint
una vez aprobado I2-4; **no iniciarlo automáticamente**. Para I2-5, probar esta
navegación y el contrato contra Backend
I2-3 en un entorno local autorizado, con sesión real, correcciones/balances,
posición fuera del TOP, errores de acceso y regresión global. Las pruebas de
cliente usan transporte/repositorios simulados, no certifican una conexión
extremo a extremo, uso en teléfono ni capacidad productiva. No se ejecutó la
suite Flutter global; se validó el alcance afectado. El año sugerido depende
del reloj del dispositivo y siempre puede corregirse manualmente.
B1/B2 (roles/RLS reales, migraciones remotas, HMAC, capacidad y operación
productiva) siguen fuera de alcance. No hay despliegue ni flags activados.

**Estado histórico — 30 de septiembre de 2026 (superado como ruta activa):** [PR-I1, sección 12: diseño `xpRulesVersion = 1` aprobado y precisiones resueltas](PR_I1_AUDITORIA_FORMULAS.md#12-diseño-numérico-aprobado--xprulesversion--1). Half-up; Q=10..30 inmutable en Trivia/Duelo; R por disponibilidad activa; acción/presencia explícitas; Tira por abandono usa Qpartida; penalización atómica con saldos/secuencia auditables. En aquella auditoría no quedaban ambigüedades de producto identificadas; 12.7 enumeraba requisitos técnicos antes de habilitar juegos. **En esa fecha, implementación, commit, push y PR-I2 no estaban autorizados y PR-I1 seguía abierto.** Los recuentos de 84 pruebas backend y 69 Flutter corresponden a la auditoría inicial, no a V1 implementada. [Plan maestro original](PLAN_MAESTRO_COMPETITIVO.md) conservado; el estado actual PR-I1/PR-I2 es el de la sección I2-4 superior.

Antecedente de este listado: actualización del 28 de septiembre de 2026, tras MA-3C.
Ruta PR-I1/PR-I2 conciliada al 5 de octubre de 2026 en este documento.

**Ruta operativa del relevo:** [RELEVO_EQUIPO.md](RELEVO_EQUIPO.md).
Para PR-I1/PR-I2, prevalece el estado actual de este documento sobre las
instrucciones históricas de relevo: PR-I1 integrado; I2-4 pendiente de cierre/publicación.
MA-3A/B/C (reglas, persistencia, sincronización y agenda) implementadas localmente.
Siguiente: **revisión final/cierre de I2-4; después I2-5 con autorización**;
ensayo real de MA-3 pendiente.
Ver [REPASO_DIFERIDO.md](REPASO_DIFERIDO.md); no confundir implementación con despliegue.
MA-2C Flutter implementada/probada localmente; ensayo real pendiente.
MA-2B (editor del panel) implementada y probada localmente; no repetirla.
MA-2A (reglas/backend) implementada localmente: [detalle](MAPA_APRENDIZAJE.md).
P5/D3 y operaciones reales permanecen pausadas; las secciones de preparación
histórica siguientes no autorizan retomarlas sin coordinación con el propietario.

Historial completo y decisiones posteriores: [HISTORIAL_ETAPAS.md](HISTORIAL_ETAPAS.md).
**JN-4 Escudo retirado de app/backend el 27 de septiembre**; no es etapa pendiente.
Ver [insignias y juegos vigentes](INSIGNIAS_Y_JUEGOS_VIGENTES.md).
PR-I3A ya integra el catálogo visual de 90 insignias, con top 50 como límite;
no concede premios reales. El panel tiene editor por bloques y guardado/publicación
directa, sin revisión editorial obligatoria. Las referencias a revisión de abajo
describen el flujo histórico y los controles de seguridad, no un paso adicional
que deba volver a imponerse al administrador. D3 verifica el flujo simplificado.

## Ruta vigente del equipo

Esta tabla es el punto único para decidir **qué sigue**, no un reemplazo de las
fichas detalladas inferiores y de RELEVO_EQUIPO. Un estado local no acredita
despliegue, pruebas en teléfono ni producción. No hay un número simple de etapas:
los 13 bloques históricos contienen subentregas y cierres, y PR-I amplía ese plan.

| Etapa/bloque | Estado y trabajo que falta | Dependencia / cuándo retomarlo |
|---|---|---|
| MA-1 — Cobertura | Base local; faltan reportes académicos de preguntas, revisión visual y ensayo real. No confundirlos con reportes de jugadores. | Entrega acotada coordinada; no pierde su pendiente al avanzar a PR-I. |
| MA-2A/B/C — Mapa | API, panel y Flutter locales. Falta recorrido real panel → API → app. | Infraestructura autorizada, junto a D3/C4. |
| MA-3A/B/C — Repaso diferido | Reglas, persistencia, API, agenda y flashcards locales. Falta ensayo físico/reconexión/reinstalación. | Infraestructura autorizada. No repetir implementación. |
| **PR-I1 — Antecedente integrado/cerrado para esta ruta** | Infraestructura e integración competitiva local de seis juegos, según el estado documental confirmado. No es la siguiente etapa activa. | Despliegue/activación y requisitos operativos B1/B2 siguen separados y pendientes; no reabrir salvo defecto concreto demostrado. |
| **PR-I2 — Ranking por juego** | Backend I2-1/I2-2/I2-3 y Flutter I2-4 fusionados (`66b5aa2` / `1921ba9`). Recepción con suite Flutter global correcta; correcciones visuales locales posteriores. | Sigue I2-5: E2E local real, regresión PostgreSQL completa y teléfono pendientes. PR-I2 no cerrado ni desplegado. No implica admisión competitiva de los clientes de juegos. |
| PR-I3 — Insignias anuales | PR-I3A gráfico ya tiene 90 imágenes. Faltan concesión real, cierre idempotente, historial permanente y correcciones auditadas. | PR-I1/2. Todas las ganadas, sin límite de tres; años anteriores permanecen. |
| PR-I4 — Perfil/personas | Perfil sobrio, identidad pública y búsqueda; todas las insignias por juego/año, detalle al tocar, visibilidad y protección de datos. | PR-I1–3; C5 antes de fotos reales. Avatar existente mientras tanto, sin fingir carga persistente. |
| PR-I5 — Instituciones | Directorio aprobado, perfil/logo del propietario, solicitudes estudiantiles/avisos y código institucional privado. Profesor con foto, no jugador. | Reutilizar P4-C y grupos; PR-I1 y C5 para archivos. No sustituir código de grupo silenciosamente. |
| PR-I6 — Ranking institucional | Aportes mientras se pertenece a institución, sin traslado/doble conteo del XP histórico; agregados públicos. | PR-I1/2/5 y reglas confirmadas. |
| PR-I7 — Ensayo social | Dos cuentas/dispositivos, privacidad, fotos, solicitudes, ayudas/empates y cierre anual conservando años anteriores. | Despliegue autorizado; coordinar con P5/D3, sin alterar reloj de producción. |
| PR-I5-T / PR-I6-T — Territorio | Catálogo DIVIPOLA, departamento/municipio en directorio y ranking institucional; posición por ámbito sin cambiar XP ni premios nacionales. | Extensiones de PR-I5/6, no reemplazos; definir sede e histórico antes de implementar. Ver ORIENTACION_Y_TERRITORIO. |
| OV-1A/B/C/D — Orientación por intereses | Cuestionario propio revisado, resultado privado y explicable, carreras para explorar y Sabi por profesión. Complementa orientación académica, no test psicológico validado. | Tras bloque competitivo/social y antes de UI-F/beta; fuentes oficiales, privacidad y revisión de contenido. |
| P1–P4-C / P5 — Profesor | P1–P4-C locales; P5 es despliegue y ensayo real docente, aprobación institucional, roles, grupos, prioridades y tiempo. | **P5 pausada**. Pedir URL/cuentas/entorno autorizado, nunca contraseñas. Antes de D3. |
| 7F-C3-D2 — Legado | Herramientas locales; faltan revisión visual y operación de legado autorizada con respaldo. | No borrar ni reclasificar contenido usado; preparar D3. |
| 7F-C3-D3 — Panel real | Conectar ADMIN a backend vigente y confirmar publicación/persistencia real. | **Pausada**, después de P5 y controles D2. Demo no cierra esta etapa. |
| 7F-C4 — Catálogo | Versionado, altas/cambios/retiradas, caché y actualización en app preservando progreso/intentos. | Contrato editorial; D3 por sí sola no lo resuelve. |
| 7F-C5 — Archivos | Storage persistente, permisos, tamaño/tipo, metadatos/licencias y fotos; evidencia institucional privada separada. | Puede prepararse localmente antes de PR-I4/5; servicio real requiere autorización. |
| 7F-C6 — Versiones | Auditoría de cambios, versiones y restauración sin reescribir preguntas ya respondidas. | Contratos editoriales y ensayo de recuperación. |
| 7F-B3-B / 6F-P — Integración | Validar módulos móviles/juegos vigentes, Guardián/Cima/Rescate y multijugador real; diagnosticar audios en teléfono. | Migraciones/despliegue autorizado; no rehacer motores por estar sin desplegar. |
| Bloque 7 — Identidad/seguridad | Auditar/completar sesión única, revocación/refresh, cuentas ADMIN, eliminación, SMTP/enlaces, contratos y privacidad. | Reutilizar lo existente; separar correcciones por flujo y probar permisos. |
| Bloque 8 — Contratos académicos | Recuperación de intentos, contrarreloj/omisiones, AM/PM e historial, banco autorizado, sincronizaciones personales y límites offline. | Revisar contratos antes de crear endpoints. MA-3 y Pomodoro P4 ya tienen sincronización local implementada. |
| Bloque 9 — Certificados | Seis tipos y HTML/PDF locales. Falta despliegue/prueba real, nombres largos y áreas incompletas/vacías. | Todas las lecciones publicadas del área; final por las cinco. No añadir PDF por logro. |
| 8A–8B — Billing | Productos y derechos verificados, restauración/renovación/reembolso, plan sin anuncios y límites institucionales. | Decisiones comerciales/productos y configuración autorizada. Nada de Wompi/ePayco. |
| 8C–8D — Anuncios/comodines | Ubicaciones a acordar, AdMob/SSV, racha y concesiones de un uso; antifraude y ausencia de inventario. | No insertar anuncios ahora. Beneficios sin video para derecho sin anuncios confirmado. |
| 7J — Contenido | Carga autorizada desde ADMIN, cobertura/calidad, fuentes oficiales, soporte y licencias. | Equipo de contenido; piloto y cierre antes de publicar. No exigir Excel. |
| 8E — Privacidad/licencias | Políticas públicas, datos/SDK/audiencia real y evidencia de derechos. | Antes de activar servicios comerciales y publicar. |
| 8F — Producción/seguridad | Entornos, respaldo/restauración, observabilidad, seguridad, carga y rendimiento. | Operaciones reales solo coordinadas; pruebas locales continúan en cada entrega. |
| UI-F / Sabi — Acabado final | Sistema azul S+, botones/componentes y claro/oscuro; animaciones profesionales aprobadas, accesibilidad. | Después de funciones e integraciones, **antes de 8G y capturas de tienda**. No rediseñar ADMIN. |
| 8G — Integral/beta | E2E, celulares, red/cierres/cuentas, compras/anuncios de prueba, PDF/audio y regresiones. | Funciones integradas, UI-F y staging autorizado. |
| 8H — iOS | Compilar/probar en macOS/Xcode y dispositivo; conservar compatibilidad. | No publicar App Store ni activar cobros reales iOS en este alcance. |
| 8I — Google Play | Firma/AAB, ficha, declaraciones, revisión y lanzamiento gradual. | Beta, privacidad y autorización; comprobar requisitos de la cuenta al ejecutar. |
| 9A — Mantenimiento | Responsables, soporte, monitoreo, contenido, costos, seguridad y actualizaciones. | Preparar operación antes de publicar; ejecución continua después. |

**Secuencia inmediata:** conservar cambios → entregar correcciones locales de I2-4
→ preparar entorno aislado y validar I2-5 → PR-I3 → PR-I4/5/6 por dependencias.
Los merges I2-3/I2-4 ya ocurrieron. PR-I1 es antecedente integrado,
no punto de reinicio. Adelantar C5 si se necesitan fotos;
no saltar permisos ni simular que la infraestructura funciona. P5 → D3 se retoman
solo al autorizarse; ensayos MA-2/3, certificados, juegos y PR-I7 siguen abiertos
hasta tener evidencia real. MA-1, seguridad y contratos se planifican sin perderlos.

**Cancelados:** JN-3 Taller y JN-4 Escudo. **No añadidos:** chat/tutores, feed,
seguidores, más juegos o certificados. Las ideas opcionales no son nuevas tareas.
Para arrancar con otro chat, usar [PROMPT_RELEVO.md](PROMPT_RELEVO.md).

## Trabajo paralelo del equipo

Ampliación planificada: **PR-I1–PR-I7 — perfiles, top 50 por juego, insignias y
directorio/solicitudes de estudiantes a instituciones**. Incluye búsqueda de personas,
visita a perfiles y todas las insignias vigentes por juego, sin límite de tres.
Las insignias anuales obtenidas se acumulan y permanecen visibles: mismo diseño
con año dinámico, conservando 2026 al obtener 2027 y temporadas posteriores.
Alcance, diferencias con
lo existente, reglas propuestas, dependencias y prompts identificados en
[PERFILES_RANKINGS_INSIGNIAS.md](PERFILES_RANKINGS_INSIGNIAS.md).
Son siete entregas adicionales, con PR-I1 integrado, Backend I2-1/I2-2/I2-3
completados, Flutter I2-4 local validado y PR-I3A visual implementada; los demás
pendientes conservan su estado. No se cuentan como parte de los 13 bloques
históricos ni sustituyen P5/D3. JN-2B/C ya tienen backend y cliente locales.
JN-4 se retiró del alcance.
MA-1 cobertura básica
implementada localmente; reportes académicos pendientes. MA-2A backend local listo;
MA-2B panel, MA-2C Flutter y MA-3A/B/C locales listos; sigue el cierre de I2-4
y posteriormente I2-5, con autorización.

Guía para compañeros: [GUIA_TRABAJO_COMPANEROS.md](GUIA_TRABAJO_COMPANEROS.md).
Certificados: **cinco por área y uno final por las cinco**, integrados localmente
con nombre registrado y validación de finalización del servidor. Falta despliegue
y prueba conjunta con base real.
Audios: investigar el reporte de que solo se escucha Tira y afloja; las llamadas
existentes no prueban reproducción real. Reparar primero y luego agregar efectos
coordinados a juegos nuevos. Contenido desde ADMIN más adelante; pruebas entre los tres.
Cada compañero trabaja en su rama/PR; el propietario revisa e incorpora. Este reparto
no cambia la revisión final de I2-4 y la continuidad autorizada hacia I2-5,
ni reabre animaciones/P5/D3.

## Ampliación vigente — Sabi, dos juegos nuevos y tres mejoras académicas

El alcance vigente incluye **Salto a la cima y Rescate de estrellas**,
con protagonista compartido. Escudo fue retirado; Taller de inventos sigue cancelado.
También seleccionó mapa de aprendizaje, repaso diferido y cobertura del banco.
Reglas acordadas y decisiones pendientes en [SABI_Y_JUEGOS_APROBADOS.md](SABI_Y_JUEGOS_APROBADOS.md).
**Nuevo orden: funcionalidad primero, animaciones al final.** JN-1A tiene
[Salto a la cima en demo local](SALTO_A_LA_CIMA.md); JN-1B backend está implementado
y probado localmente, sin despliegue. JN-1C cliente Flutter remoto implementado;
la prueba real queda pendiente de infraestructura. JN-2A
[Rescate de estrellas](RESCATE_DE_ESTRELLAS.md) tiene reglas/demo implementadas.
JN-2B tiene backend/migración locales y JN-2C cliente remoto con recuperación,
sin despliegue ni ensayo real. JN-4 Escudo ya no es un juego activo ni pendiente.
MA-1 [cobertura básica](COBERTURA_DEL_BANCO.md) implementada localmente; reportes
académicos, revisión visual y ensayo real pendientes. MA-2A backend implementado
localmente; MA-2B/C y MA-3A/B/C listas localmente; la ruta competitiva actual
es cierre de I2-4 y después I2-5 con autorización.
G-SABI-1B se conserva como prototipo pausado,
sin aprobación artística; las celebraciones y renovación visual no se hacen ahora.
Son alcance adicional, no implementado en producción;
se añaden al inventario de 13 bloques original, no se ocultan dentro de su recuento.
**P5 y la conexión real D3 están pausadas por decisión del usuario**, no terminadas.

Retiro de ePayco/Wompi implementado localmente en el backend: las rutas antiguas
responden 410 sin procesar pagos; se conserva el historial. Falta desplegarlo y
verificarlo en Render. Google Play Billing y D3 mantienen sus tareas pendientes.

Se añadió una [auditoría complementaria](AUDITORIA_PROYECTO_2026-09-09.md)
con correcciones locales y pruebas; no se desplegó ni se cerró D3. Se mantienen
los 13 bloques siguientes. El [resumen de funcionalidades](FUNCIONALIDADES_PARA_EL_EQUIPO.md)
distingue lo implementado de lo que todavía necesita contrato o verificación real.

**Implementado no equivale a desplegado ni probado en teléfonos.** Render ya
tuvo su despliegue inicial; no hay que repetir esa etapa desde cero. Sí quedan
actualizaciones, migraciones y verificaciones de módulos posteriores.

El roadmap principal conserva las etapas originales. Aquí se agrupan todos sus
pendientes en **13 bloques de trabajo**, incluyendo deuda de etapas anteriores:
12 de preparación del lanzamiento y uno de operación posterior (9A).
No son trece etapas originales nuevas. La comparación con el listado anterior
7F–9A está en [CONCILIACION_ROADMAP.md](CONCILIACION_ROADMAP.md).

## Punto de reanudación — leer primero al volver a trabajar

Orden vigente: **preservar cambios → correcciones locales I2-4 → preparar y
validar I2-5 en entorno aislado**. PR-I1 y PR-I2 hasta I2-4 están fusionados.
No reiniciar PR-I1 ni volver a pedir el merge de los PR #3/#6. No sustituir
el entorno aislado por una base real ni desplegar automáticamente.
MA-2A/B/C y MA-3A/B/C están implementadas localmente; no rehacerlas.
Cuando se autorice retomar infraestructura, completar P5 antes de 7F-C3-D3.
P1, P2 y **P3-A/P3-B (prioridades, pantallas y práctica dirigida)** tienen entregas
locales. **P4-A/P4-B preparan API, persistencia, sincronización y pantallas de
tiempo/evolución**. La implementación P4 es local; su despliegue y comprobación
real no están cerrados. **P4-C tiene implementación local de aprobación institucional**:
Flutter, API, migración y bandeja ADMIN. Faltan revisión visual, despliegue y ensayo
real. **P5 permanece pausada**, con los preparativos de commits, migraciones y despliegue
indicados abajo; no rehacer P4-C desde cero.
D3 sigue pendiente, no cancelada ni terminada.
Los 13 bloques se conservan como inventario; el cierre docente se detalla como
subetapas previas para no ocultar sus carencias dentro de una prueba integral.
Guías de entrega y pruebas: [PROFESOR_P1.md](PROFESOR_P1.md) y
[PROFESOR_P2.md](PROFESOR_P2.md), [PROFESOR_P3_A.md](PROFESOR_P3_A.md) y
[PROFESOR_P3_B.md](PROFESOR_P3_B.md), [PROFESOR_P4_A.md](PROFESOR_P4_A.md) y
[PROFESOR_P4_B.md](PROFESOR_P4_B.md), [PROFESOR_P4_C.md](PROFESOR_P4_C.md).

### Cierre del módulo profesor — antes de D3

| Subetapa | Alcance y criterio de cierre | Estado |
| --- | --- | --- |
| P1 | Corregir cálculo del avance publicado sin borrar historial, textos, ausencia de resultados y accesos rápidos. Verificar tamaños pequeños/texto ampliado. | Implementación local; ver pruebas y límites en PROFESOR_P1.md. |
| P2 | Ficha del estudiante y desglose área → tema → subtema con aciertos, errores, cantidad de evidencia y fecha. Reutiliza reglas del diagnóstico y autorización por grupo/plan, sin exponer respuestas. | Implementación local; falta ensayo real P5. Ver PROFESOR_P2.md. |
| P3-A | Persistencia y API de prioridades docentes: selección publicada, plazo/retiro, cinco preguntas únicas, idempotencia, permisos, reportes y migración. No confundir práctica con dominio. | Implementación local: 724 pruebas Jest y 11 PostgreSQL temporal; falta migración/despliegue real. Ver PROFESOR_P3_A.md. |
| P3-B | Profesor selecciona desde sus grupos; alumno ve prioridad y practica el snapshot autorizado; docente consulta cumplimiento. Repositorios remoto/demo, sesión, reintentos, estados y accesibilidad. | Implementación local con pruebas Flutter/backend/PostgreSQL. Ver PROFESOR_P3_B.md. Pendientes migración P3-A, despliegue y ensayo real P5. |
| P4-A | Persistencia privada y API de Pomodoros idempotentes; resumen propio/docente 7/30/90 días, historial confirmado, fuentes separadas, permisos y muestra parcial. | Implementación backend local con pruebas; migración/despliegue pendientes. Ver PROFESOR_P4_A.md. |
| P4-B | Cola de Pomodoro por cuenta, confirmaciones/reintentos, resumen remoto y evolución accesible desde la ficha docente. Conserva datos locales y distingue pendiente/demo/sin registros. | Implementación Flutter local; ver PROFESOR_P4_B.md. SQLite v9 conserva el historial; no sube evaluaciones ni importa el historial antiguo. Falta ensayo real P5. |
| P4-C | Solicitud de institución por profesor, verificación de evidencia mínima y aprobación/rechazo por ADMIN desde el panel web. Pendiente no equivale a institución activa. | Implementación local con pruebas. Pendientes revisión visual, migración/despliegue y ensayo real P5. Sin adjuntos documentales; coordinar archivos privados con C5. Ver PROFESOR_P4_C.md. |
| P5 | Ensayo profesor → solicitud/aprobación → grupo → estudiante, roles y aislamiento, sesión vencida, reintentos y reconexión. Cuentas y contenido de ensayo autorizados; despliegue y pruebas en dispositivos. | Pendiente después de P4-C; coordinar con bloques 6 y 7. |

No se cambian los límites comerciales ni se agregan tutores/chat. No rehacer
instituciones, grupos, invitaciones, analítica básica, alertas o exportaciones ya
implementadas. P2–P4 requieren extender sus contratos, no solo crear pantallas.
Se puede avanzar con pruebas controladas antes de D3, pero cualquier comprobación
que necesite publicación/configuración real debe quedar abierta hasta realizarla.

### P4-C — Verificación de nuevas instituciones (antes de P5)

**Motivo original:** `POST /instituciones` creaba una institución activa y asignaba
propiedad al profesor sin aprobación de SaberPlus; P4-C retira esa ruta con 410.
La verificación del correo
personal no acredita que represente al colegio. No basta ocultar el botón en
Flutter: el backend debe bloquear el acceso institucional hasta aprobarlo.

1. El profesor conserva su cuenta individual y solicita la institución con
   nombre, ubicación/contacto institucional, correo de trabajo y referencia
   pública verificable cuando exista. Buscar coincidencias antes de solicitar:
   si la institución ya existe, ofrecer invitación/vinculación, no duplicarla.
2. Evidencia mínima y proporcional: primero correo institucional y fuente
   pública; si no bastan, carta/autorización del establecimiento como adjunto
   opcional. No solicitar documentos de identidad ni datos de estudiantes para
   este trámite. Ofrecer contacto de soporte para resolver dudas, pero no usar
   una llamada o WhatsApp como único registro de aprobación.
3. Crear estados `PENDIENTE`, `REQUIERE_INFORMACION`, `APROBADA`, `RECHAZADA`
   y `SUSPENDIDA`, con fecha, motivo interno, actor ADMIN y seguimiento para el
   solicitante. El rechazo no borra la cuenta del profesor; permitir corrección
   o nueva solicitud controlada. Evitar decisiones duplicadas/concurrentes.
4. Mientras no esté aprobada, no activar códigos de grupo, invitaciones,
   importación de estudiantes, analíticas ni privilegios institucionales.
   Centralizar esta comprobación en el backend y probar cada ruta protegida;
   no confiar en el estado que muestre la app.
5. Añadir al panel web ADMIN una bandeja de solicitudes con filtros, detalle de
   evidencias, solicitud de información, aprobación y rechazo motivado. Solo
   ADMIN de SaberPlus revisa; el propietario de la solicitud no puede aprobarse.
   La app solo presenta formulario y estado, no herramientas de moderación.
6. Si se habilitan adjuntos, guardarlos en almacenamiento privado con acceso
   limitado a solicitante y revisores, tipos/tamaños permitidos, trazabilidad y
   plazo de conservación definido; nunca en URL pública ni dentro del APK.
7. Revisar instituciones creadas antes de introducir estados: no marcarlas todas
   como verificadas sin revisión ni cortar grupos existentes de forma sorpresiva.
   Migración, plan de transición, notificaciones y pruebas de regresión.
8. Probar duplicados, suplantación, acceso por rol, rechazo, corrección,
   suspensión, errores de red y una aprobación completa desde el panel. La parte
   institucional del panel deberá conectarse a staging para P5; D3 sigue siendo
   el ensayo editorial real y no queda terminado por esta conexión parcial.

**Gestión de cuentas:** las rutas ADMIN existentes permiten listar, cambiar rol
y eliminar usuarios; también hay una creación desde `lead` anterior. No equivalen
a una pantalla completa y segura de administración. Añadir una sección web ADMIN
para búsqueda, invitación/alta excepcional, suspensión/reactivación y revisión
de cuentas, con permisos, confirmaciones y auditoría. Separar la eliminación de
cuenta/datos del simple bloqueo de acceso y revisar dependencias antes de borrar.
No llevar esta sección a la app del estudiante/profesor. Coordinarla con el bloque
7 de identidad/seguridad y el ensayo real D3, sin asumir que ya está implementada.

### Preparación de P5 cuando se autorice retomarla, antes de D3

1. Revisar los commits actuales de ambos repositorios y lo realmente desplegado.
   La advertencia sobre un modelo Guardián sin commit era del 17 de septiembre,
   no un diagnóstico vigente: verificarlo, no recrearlo a ciegas. No confundir
   build del árbol local con un checkout completo y reproducible.
2. Confirmar URL exacta de Render y entorno de ensayo `saberplus-dev`, permisos y
   respaldo. Revisar/aplicar con autorización las migraciones pendientes P3-A/P4-A/P4-C
   y desplegar la versión correspondiente; no repetir el despliegue inicial.
3. Revisar visualmente P4-C y preparar cuentas reales autorizadas de ADMIN, profesor
   y estudiante, contenido de ensayo y una solicitud institucional revisada.
   Antes de migrar P4-C, comunicar la transición de 30 días para instituciones
   existentes y organizar revisión manual; no quedan automáticamente verificadas.
   No compartir contraseñas por chat.
4. Probar profesor → aprobación → grupo → prioridad → práctica del estudiante
   → cumplimiento/evidencia
   y tiempo/evolución. Comprobar separación de fuentes, días sin registros y
   conservación de datos tras cerrar/reabrir la app.
5. Comprobar permisos por rol, grupo/institución y plan, sesión vencida/cambio de
   cuenta, desconexión/reconexión y reintento idempotente de Pomodoro. Verificar
   interfaz en Android y registrar la comprobación iOS o su limitación de entorno.
6. Registrar resultados, corregir fallos y cerrar P5 solo con evidencia real.
   Después retomar D3 y sus controles editoriales D2 aún pendientes. C4 continúa
   siendo la sincronización del catálogo con Flutter, no una consecuencia
   automática de conectar el panel.

No se requieren audios nuevos para P4-B/P5. No se ejecutaron migraciones ni
despliegues reales durante la integración Flutter.

### Repositorios y contexto que se deben conservar

- App Flutter Android/iOS: `C:\Users\LENOVO 14ALC6\Desktop\SaberPLus\saber_plus`.
- Backend oficial: `C:\Users\LENOVO 14ALC6\Desktop\SaberPlus-Backend`;
  API en `backend/` y panel editorial web en `admin/`.
- Repositorio remoto del backend: `https://github.com/Pavel2020123/SaberPlus-Backend`.
  No trabajar sobre la antigua web Icfes_Vida ni sobre otra copia del backend.
- Flujo previsto: **panel administrativo → API en Render → PostgreSQL en
  Supabase**. El panel y Flutter no reciben contraseñas de base de datos.
- Render ya tuvo un despliegue exitoso. Eso no confirma que incluya los últimos
  cambios locales de auditoría, editor o retiro de pagos heredados.
- La demo editorial es aislada: sus cambios no llegan a Supabase y se pierden
  al reiniciar. No confundir una prueba en demo con D3 completada.
- No reiniciar etapas implementadas. Revisar el estado actual de ambos repositorios
  y preservar cualquier cambio del usuario antes de modificar archivos.

### Información que se debe pedir al retomar D3 (después de P1–P5)

1. URL actual y exacta del servicio Render; no deducirla del nombre del servicio.
2. Confirmar si existe una cuenta **ADMIN de SaberPlus**, no de profesor.
   No pedir su contraseña por chat; si falta, preparar su creación autorizada.
3. Confirmar si se pudo entrar a la demo y eliminar un tema/subtema en borrador
   vacío. Si no, hacer la comprobación visual pendiente antes del ensayo real.
4. Confirmar el entorno Supabase de ensayo (`saberplus-dev`, según lo acordado)
   y el origen desde el que se abrirá el panel. No solicitar ni copiar secretos
   en este documento, Git o la aplicación.

### Instrucción lista para copiar en una nueva sesión

> Lee primero el estado vigente I2-4 y la ruta de `docs/ETAPAS_PENDIENTES.md`;
> consulta `docs/RELEVO_EQUIPO.md`, arquitectura e inventario como referencias,
> distinguiendo sus antecedentes históricos. Confirma rama, HEAD y cambios existentes.
> PR-I1 ya está integrado; Backend I2-1/I2-2/I2-3 completados y Flutter I2-4
> implementado/validado localmente, con revisión humana de código y pruebas realizada.
> Los PR #3/#6 ya están fusionados. Sigue preparar I2-5 en entorno local aislado.
> PR-I2 no se declara completo ni desplegado; faltan E2E real contra Backend,
> PostgreSQL completo y teléfono. La suite Flutter global pasó en recepción.
> MA-2A/B/C y MA-3A/B/C ya están implementadas localmente. MA-1
> básica y los juegos nuevos ya tienen implementación local. P5/D3 siguen pausados
> hasta autorización. No confundas implementación con despliegue. Actualiza etapas,
> pruebas y limitaciones según el alcance autorizado; conserva los cambios existentes.
> No pidas secretos ni hagas commits, despliegues o migraciones reales automáticamente.

## 1. 7F-C3-D2 — Legado y unificación editorial

- Ajuste D2-F implementado localmente: eliminación confirmada de temas/subtemas
  en borrador vacío, nunca publicados ni usados. No borra contenido ni hijos.
  No es una papelera; restauración/auditoría siguen pendientes en C6.
- **D2-A implementada localmente:** 15 escrituras administrativas antiguas
  retiradas con HTTP 410, carga demo HTTP retirada y bloqueo común por área.
  El panel conserva sus rutas vigentes. Falta desplegar y verificar en entorno real;
  no reutilizar métodos internos heredados como vía alternativa.
- **D2-B implementada localmente:** API ADMIN de indexación de huellas nulas
  por lotes, vista previa/revisión/confirmación y reportes paginados de duplicados.
  No modifica contenido, fechas, clasificación ni publicación. SQL/rollback local
  probado en D2-F; falta operarla en el entorno objetivo con respaldo/autorización.
  Escrituras apagadas por defecto.
  El editor conserva el bloqueo si supera 2000 candidatos sin indexar.
- Revisar duplicados y clasificaciones genéricas como Banco General sin
  atribuirles temas inventados ni cambiar resultados históricos.
- **D2-C implementada localmente:** API de reclasificación con destino/revisión/
  confirmación para preguntas sin uso registrado, dentro de su área. Conserva
  contenido/estado y bloquea publicadas, respuestas, juegos e intentos JSON.
  Faltan verificación visual y operación autorizada. D2-F verifica consultas y
  concurrencia en PostgreSQL temporal. Preguntas usadas requieren versiones en C6.
- **D2-D implementada localmente:** API especializada CLOZE, guardado/retiro
  protegido, validación común y revisión de texto/opciones/clave antes de publicar.
  Compatible con Flutter; solo borradores nunca publicados y sin uso. No se
  activó publicación ni se modificó contenido real.
- **D2-E implementada localmente:** panel con formularios CLOZE, indexación,
  coincidencias paginadas y reclasificación con selectores tema/subtema. Demo
  aislada y 54 pruebas de lógica/HTTP aprobadas; falta prueba visual en navegador.
- **D2-F verificación local implementada:** PostgreSQL desechable, SQL versionado,
  consultas y concurrencia reales, rollback y protección de uso histórico. No se
  utiliza Supabase ni la base local habitual. Revisión visual y operación autorizada
  del legado siguen pendientes. No activar `EDITORIAL_PUBLICATION_ENABLED` antes
  de completar estos controles y preparar D3.

## 2. 7F-C3-D3 — Conectar el panel al backend y ensayo editorial real

**Estado: pendiente de conexión y verificación real.** El objetivo es trabajar
desde el panel con una cuenta ADMIN y guardar contenido de ensayo en la base
correcta, sin usar la demo. La sincronización del catálogo con Flutter es C4;
conectar el panel por sí solo no garantiza que lo nuevo aparezca ya en la app.

### Orden de ejecución

1. Revisar las guías y configuración existentes en ambos repositorios, el commit
   desplegado en Render y su estado de salud. Identificar cambios y migraciones
   faltantes, sin aplicarlos a ciegas ni reiniciar el despliegue desde cero.
2. Confirmar la base de ensayo, respaldo y permisos antes de cualquier migración
   u operación sobre datos. Completar los controles D2 aplicables y preparar el
   despliegue de cambios pendientes con autorización del usuario.
3. Configurar el panel para usar la URL real de la API en lugar de la demo,
   siguiendo su configuración existente. Autorizar únicamente su origen concreto
   por CORS y verificar HTTPS. No resolver permisos con un comodín indiscriminado.
4. Iniciar sesión con ADMIN y comprobar que profesor/estudiante no pueden acceder
   a las funciones editoriales. Verificar caducidad y cierre de sesión.
5. Seleccionar un área del catálogo y crear tema, subtema, lección, caso y pregunta
   de ensayo propios/autorizados. Verificar las cinco áreas existentes; no asumir
   que el panel ya tiene creación de áreas ni crear duplicados para probar.
6. Guardar borradores, recargar, cerrar sesión y volver a entrar: comprobar que
   los registros siguen en el catálogo remoto. Contrastar su persistencia en la
   base confirmada sin exponer credenciales ni datos de otros usuarios.
7. Probar duplicados, clasificación área/tema/subtema, fallos de red, conflictos
   entre editores y borrado de un borrador vacío. No eliminar contenido utilizado
   ni reenviar automáticamente una escritura de resultado incierto.
8. Solo después de los controles previos y con autorización, habilitar las
   banderas editoriales necesarias, revisar y publicar contenido de ensayo en
   orden. Verificar archivado sin alterar historial; no activar operaciones de
   legado innecesarias para este ensayo.
9. Registrar evidencia y resultados, actualizar el estado de D3 y dejar
   identificada la siguiente tarea C4. Si falta navegador, cuenta o acceso real,
   anotar el bloqueo: las pruebas locales no cierran esta etapa.

### Criterios para darla por terminada

- [ ] Panel conectado a la API correcta, fuera de modo demo.
- [ ] ADMIN entra; roles no autorizados quedan bloqueados por el servidor.
- [ ] Contenido de ensayo guardado en Supabase y recuperado tras recargar/reingresar.
- [ ] Revisión, publicación y archivado comprobados con controles D2 satisfechos.
- [ ] Duplicados, errores de red, conflictos y borrado permitido comprobados.
- [ ] Prueba visual real y accesibilidad básica registradas.
- [ ] Commit desplegado, configuración no secreta y resultados documentados;
      pendientes claramente separados de lo verificado.

### Alcance original que se conserva

- Preparar una cuenta ADMIN autorizada y contenido de ensayo propio/autorizado.
- Desplegar las rutas editoriales y autorizar el origen del panel por CORS.
- Probar en navegador real: crear tema, subtema, lección, caso y pregunta;
  revisar, publicar en orden y archivar sin afectar historial.
- Validar errores, duplicados, recursos, caducidad de sesión, dos editores y
  pérdida de conexión. Comprobar permisos de ADMIN frente a profesor/estudiante.
- Revisar accesibilidad del panel y despliegue HTTPS si se compartirá públicamente.

## 3. 7F-C4 — Catálogo versionado y sincronización Flutter/Drift

- Publicar un contrato versionado para detectar altas, cambios y retiradas.
- Actualizar catálogo y lecciones en la app sin recompilar por cada cambio.
- Invalidar/renovar cachés y descargas, conservar progreso y resolver conflictos.
- Asegurar que borradores o contenido archivado no aparezcan en actividades nuevas.
- Probar actualizaciones con conectividad intermitente y contenido previamente descargado.

## 4. 7F-C5 — Imágenes y archivos persistentes

- Supabase Storage con permisos, límites, tipos de archivo y referencias estables.
- Carga desde el panel, metadatos, texto alternativo, derechos y recursos faltantes.
- Ampliar el modelo Respuesta, contrato y Flutter para **imágenes dentro de opciones**.
- Mantener imágenes de enunciados/casos y recursos de lecciones/PDF disponibles
  tras reinicios o despliegues; validar acceso y descarga sin exponer secretos.
- Comprobar compatibilidad con las descargas offline y el catálogo versionado.
- Conservar fuente, titular, licencia y evidencia de autorización del contenido
  (preguntas, casos y lotes), además de los derechos de sus archivos adjuntos.

## 5. 7F-C6 — Auditoría, versiones y recuperación editorial

- Registrar quién cambió qué, cuándo y con qué resultado.
- Consultar versiones anteriores y restaurar de forma controlada.
- Corregir contenido que ya se utilizó sin reescribir resultados de alumnos.
- Definir y probar respaldo/recuperación para las operaciones editoriales.

## 6. 7F-B3-B y 6F-P — Integración móvil, despliegues y Guardián

- Revisar y aplicar las migraciones pendientes con respaldo y ambiente confirmado,
  incluida Guardián; desplegar los módulos nuevos en el backend oficial.
- Preparar cuentas verificadas de ensayo de estudiante y profesor, convocatoria
  y banco autorizado/publicado. Cargar contenido revisado, no datos personales reales.
- En teléfonos, verificar sesión, diagnóstico, práctica, progreso, recursos,
  certificados, instituciones y roles usando la API real.
- Probar juegos, recuperación tras cierre/pérdida de red y dos dispositivos en
  multijugador; validar reloj, reconexión, ranking y recompensas confirmadas.
- Revisar animaciones, sonido, reducción de movimiento y rendimiento en Android/iOS.
  Los motores y animaciones ya implementados no se cuentan como juegos por rehacer.

## 7. Cierre de identidad, contratos y seguridad

- Backend de **una única sesión/dispositivo activo**, revocación y comprobación
  en cada solicitud protegida; el cliente ya tiene parte de esta frontera.
- Refresh tokens, rotación, expiración y cierre/revocación centralizados.
- Restringir en el servidor las rutas permitidas mientras siga pendiente el
  cambio inicial de contraseña; no depender únicamente de la redirección móvil.
- Persistir sesiones en PostgreSQL vinculadas a un identificador aleatorio de
  instalación; cerrar remotamente/todas las sesiones y revocar por reemplazo,
  cambio o recuperación de contraseña y eliminación de cuenta. Auditar lo mínimo.
- Implementar eliminación de cuenta/datos y definir conservación, anonimización
  o eliminación por categoría, con revisión de las obligaciones aplicables.
- Verificar límites de solicitudes y defensa contra intentos repetidos de acceso;
  no dar por suficiente una protección existente sin ensayarla en staging.
- OpenAPI versionado y errores uniformes para app, panel y backend.
- Universal Links/App Links HTTPS con dominio y flujos reales de correo,
  verificación y recuperación comprobados.
- Configurar/probar SMTP y conservar enlaces personalizados como respaldo.
- Consentimiento versionado y tratamiento de la audiencia real, incluidos
  adolescentes; revisar privacidad y permisos antes de incorporar SDK comerciales.

## 8. Contratos académicos pendientes de etapas anteriores

- Recuperación idempotente de intentos respaldada por API, sin duplicar respuestas.
- Recuperar resultados tras perder conexión al entregar, sin duplicar calificación
  ni XP. Probar reintentos y caducidad de sesión en la cola offline existente.
- Contrarreloj autoritativo: cierre al vencer y calificación de preguntas omitidas.
- Guardar inicio/vencimiento en servidor, no reiniciar al reabrir la app, admitir
  la entrega parcial según el plazo y separar SIN_RESPUESTA de respuesta incorrecta.
  Rechazar respuestas tardías y permitir consultar el resultado por intento.
- Banco histórico: cargar pruebas propias/autorizadas y publicar su contrato.
- Ediciones y jornadas con titular/licencia/referencia, estados disponible,
  próximamente y restringido; validar el formato acordado de 75 AM + 75 PM,
  150 preguntas y cinco áreas, sin entregar claves antes de la calificación.
- Historial unificado de jornadas AM/PM, ediciones históricas y contrarreloj.
- Incluir prácticas/simulacros por área, correctas, incorrectas, omitidas, duración
  y desglose por materia; extender comparaciones sin rehacer su interfaz existente.
- Integridad AM/PM: recibir y validar en backend eventos de salida de la app.
  Definir tolerancias para llamadas, avisos y accesibilidad; no aplicar reprobación
  automática sin una política institucional explícita.
- Sincronización de favoritos y preguntas difíciles entre instalaciones/cambios
  de dispositivo, respetando la sesión única. Hoy la persistencia es local.
- La agenda de flashcards ya tiene contrato y sincronización local MA-3A/B/C;
  falta ensayo real. Los contadores de práctica libre no se importan a esa agenda.
  Revisar por separado su eventual sincronización y la del objetivo personal.
  Pomodoro/tiempo-evolución ya tienen API y cola P4-A/B; no rehacerlas ni subir
  otra vez los tiempos de evaluaciones. Falta ensayo real y conciliar límites
  del acumulado histórico local con el resumen del servidor.
- Evaluar qué estado de «Continúa donde quedaste» conviene sincronizar; no asumir
  que todo intento protegido puede copiarse libremente entre dispositivos.
- Cerrar política offline de intentos/contenido protegido y precondiciones de
  edición del cuaderno de errores para resolver conflictos sin sobrescrituras silenciosas.
- Verificar aislamiento/limpieza de descargas al cambiar de cuenta y evitar
  almacenar permanentemente bancos de claves de respuesta. Distinguir recursos
  públicos descargables de datos privados y resultados autorizados del alumno.

## 9. Seis certificados: cinco áreas y curso completo

- Nueva decisión: un certificado por Lectura crítica, Matemáticas, Ciencias naturales,
  Sociales y ciudadanas e Inglés, más uno final por completar las cinco áreas.
- Implementado localmente el 22 de septiembre: una plantilla HTML reutilizable con
  logo, Sabi, nombre dinámico desde `Usuario.nombre`, área/curso y fecha. PDF A4 horizontal.
- El servidor exige completar todas las lecciones publicadas del área. Un área vacía
  no habilita certificado. El final requiere las cinco áreas, no cinco descargas.
- La colección Flutter ofrece las seis tarjetas. Se retiraron sus botones por logro;
  la ruta heredada devuelve 410. Los PDFs personales previos no se borran.
- Pendiente: desplegar y probar Render con Chrome, base real, nombres extensos y
  los seis estados en celulares. Acordar después política de historial/versiones si
  se necesita conservar un derecho de emisión tras publicar nuevas lecciones.

## 10. Etapas 8C–8D — Publicidad y recompensas reales

- Configurar e integrar AdMob: identificadores de prueba/producción, ubicaciones,
  consentimiento y límites de frecuencia. No interrumpir concentración/evaluaciones.
- Anuncios recompensados voluntarios con verificación del servidor (SSV),
  concesiones de un solo uso y protección frente a repeticiones/tráfico inválido.
- Contrato real de racha: congelamiento/gracia, vencimiento y recuperación
  del día anterior dentro de su ventana, sin confiar en el reloj local.
- Potenciadores individuales bajo demanda sin tope comercial diario, sujetos a
  disponibilidad y validación; plan sin anuncios solicita la misma recompensa sin video.
- No usar falencias, puntajes o institución para segmentar anuncios.
- No usar respuestas ni carreras para personalización publicitaria. Habilitar
  reporte de anuncios inapropiados y manejar falta de inventario/errores sin
  bloquear estudio ni provocar cargas repetitivas.
- Banners solo fuera de concentración; intersticiales en pausas naturales, con
  límites locales/remotos. Evaluar la hipótesis de 2–3 cada 30 minutos y mayor
  frecuencia para profesores gratuitos sin convertirla en obligación ni spam.
  Retirar publicidad al confirmar el derecho sin anuncios.
- Vincular cada concesión a usuario, recompensa, vencimiento y uso único;
  auditar emisión/consumo. El callback de Flutter no basta para concederla.
- Cada video voluntario concede un potenciador; no recuperar varios días de
  racha acumulados. Mantener partidas asistidas fuera de récords competitivos y
  no alterar diagnóstico, XP académico ni simulacros oficiales.
- Aprovechar el consumo autoritativo de concesiones ya implementado en juegos;
  faltan emisión real, SSV y comprobación integral, no rehacer todos los motores.

## 11. Etapas 8A–8B — Derechos comerciales, Billing y plan sin anuncios

- Configurar productos/ofertas: 9.900 COP mensual, 49.900 semestral,
  promoción 39.900 y 69.900 anual, conforme al modelo acordado.
- Compra y validación del servidor, derechos, renovación, vencimiento,
  restauración, reembolso y cambio de cuenta.
- Retirar anuncios y entregar insignia/cosméticos, sin bloquear contenido
  académico gratuito ni confundir cosméticos con logros académicos.
- Conectar los derechos de profesor con su plan, reemplazando la activación
  administrativa provisional. Revisar límites/costos del plan institucional.
- No integrar Wompi/ePayco en móvil. Mantener la frontera de iOS sin cobros reales.
- Derechos neutrales al proveedor con cuenta, producto, transacción, fechas y
  estados gratuito, pendiente, activo/sin anuncios, gracia, suspendido, vencido y
  reembolsado/revocado. Solo el servidor puede activarlos.
- Confirmar identificadores y modalidad: suscripción renovable o pase fijo.
  Validar comprobantes con Google Play Developer API y procesar notificaciones
  del servidor sobre compras/cambios, con idempotencia y recuperación de eventos.
- Probar cancelación y acceso hasta su vencimiento cuando corresponda, suspensión,
  gracia, revocación, reinstalación y asociación entre cuenta Google y SaberPlus.
- Pantalla «Administrar plan», precios devueltos por Play y pruebas con cuentas
  de licencia. Los precios anteriores son el acuerdo comercial, no valores que
  deban ignorar los productos/ofertas reales de la tienda.
- Los límites institucionales ya implementados (gratis: 1 grupo/40 alumnos;
  plan ampliado: 5 grupos/200 alumnos) se verifican y conectan al derecho comercial;
  no se vuelven a construir analíticas, prioridades ni exportaciones existentes.

## 12. Etapas 8E–8I y cierre 7J — Producción, calidad y publicación

- Entorno de producción separado del desarrollo, secretos, dominio/configuración,
  respaldo inicial, recuperación comprobada, observabilidad y plan de reversión.
- Revisar vulnerabilidades de dependencias y advertencias técnicas pendientes;
  probar seguridad, accesibilidad, carga, consumo y rendimiento.
- Resolver los avisos de lint preservados de Guardián y revisar la migración de
  `flutter_timezone` a Kotlin integrado antes de actualizar Flutter; el APK debug
  actual compila, pero no constituye la verificación de release ni de iOS.
- Banco académico suficiente y autorizado; revisión de fórmulas/glosario,
  fechas de examen y vigencia de fuentes de becas, universidades y datos nacionales.
- Completar origen, autor, licencia y fechas de los audios ya integrados; no se
  necesitan sonidos nuevos para la entrega actual. Escucharlos en teléfonos reales.
- Compilar y probar Android e iOS; firma y paquete Android, pruebas internas/beta,
  ficha de tienda, capturas, privacidad, audiencia y declaraciones de SDK/datos.
- Verificar compras/anuncios de prueba, cuentas limpias y configuración sin demo
  antes del lanzamiento comercial en Google Play.

### Contenido y operación editorial (cierre 7J)

- Cargar las cinco áreas, temas/subtemas, lecciones, Markdown, actividades,
  imágenes, videos y PDF autorizados. Revisar exactitud, ortografía, ambigüedad,
  dificultad y explicaciones; el editor admite cuatro opciones dentro de su rango
  actual de 2–6, no hay que rehacerlo por esa diferencia con el listado antiguo.
- Banco piloto: al menos 30 preguntas variadas por área; objetivo inicial de
  producción: 100 o más por área, sujeto a revisión académica y cobertura.
  Revisar las 80 fórmulas y 50 términos de memoria, no solo su cantidad.
- Actualización versionada de becas, programas, universidades y referencias
  nacionales, con fuente y fecha de revisión. No confundir el catálogo informativo
  existente con una actualización remota o automática ya implementada.
- Configurar y probar el número real de soporte WhatsApp; retirar contactos y
  contenido ficticios de producción. La cuenta de soporte la aporta el equipo.

### 8E — Privacidad, documentación y licencias

- Publicar privacidad, términos y procedimiento de eliminación en HTTPS:
  datos recogidos, finalidad, destinatarios y plazos de conservación.
- Inventario de SDK/proveedores y declaraciones de datos/anuncios/audiencia real,
  incluidos usuarios de 15–17 años; revisar requisitos vigentes al implementarlo.
- Revisar avisos de resultados orientativos/no oficiales para proyección,
  comparación nacional, carreras y becas. No se ofrecen tutores ni asesoría personal.
- Conservar evidencia de licencias de preguntas, imágenes, cuadernillos, PDF y
  audios; registrar modificaciones y verificar permisos comerciales/distribución.
  La declaración «libre de regalías» por sí sola no cierra esta comprobación.

### 8F — Seguridad, rendimiento y observabilidad

- Auditar roles, aislamiento entre instituciones, acceso de profesores a sus
  grupos, exportaciones, respuestas correctas, archivos y rutas de descarga.
- Revisar límites de solicitudes de login, juegos, invitaciones y recompensas;
  secretos distintos por ambiente, incluido el de alias, sin filtrarlos a Git/APK/logs.
- Logs sin datos sensibles, captura de errores Flutter/NestJS, latencia,
  disponibilidad y alertas; ensayar respuesta a incidentes y restauración.
- Carga de login, simulacros, Trivia Rush, Socket.IO, ranking y exportaciones;
  memoria, batería, datos y tamaño APK/AAB. Lectores de pantalla, texto ampliado,
  contraste, navegación y todas las animaciones con reducción de movimiento.

### UI-F — Diseño final de la app (antes de 8G)

Pendiente, aprobado por el usuario. Forma parte del cierre del bloque 12, no es
un rediseño del panel ADMIN ni una etapa opcional posterior a la publicación.

- Adoptar una identidad azul basada en el logo S+ de SaberPlus; aprobar primero
  una muestra de inicio, perfil y pregunta antes de extenderla a toda la app.
- Definir colores, tipografía, espaciados, bordes, elevación e iconos como estilos
  compartidos; evitar colores y botones diferentes definidos pantalla por pantalla.
- Rediseñar botones, tarjetas, formularios, navegación y estados de carga, error,
  vacío, selección y deshabilitado. Mejorar jerarquía y legibilidad sin recargar.
- Conservar los modos claro, oscuro y del sistema: azul como identidad, no como
  fondo saturado obligatorio de todas las pantallas. Revisar contraste y foco.
- Aplicar el sistema visual a estudiante y profesor, perfiles, rankings, estudio,
  juegos y ajustes, respetando lo ya implementado y sin modificar reglas académicas.
- Integrar el arte final de Sabi y las animaciones acordadas dentro de esta fase
  de acabado; mantener reducción de movimiento y no distraer durante preguntas.
- Verificar controles táctiles, texto ampliado, lectores de pantalla, pantallas
  pequeñas y adaptación Android/iOS; ajustar pruebas de widgets afectadas.

Orden: funciones e integraciones → UI-F y acabado de animaciones → 8G pruebas
integrales/beta → comprobación final iOS y capturas/publicación Google Play.
Las pruebas unitarias, de seguridad y de cada entrega continúan durante el
desarrollo; no se posponen hasta UI-F. Cerrar esta etapa con revisión visual del
usuario en celular y componentes consistentes, antes de producir capturas finales.

### 8G — Pruebas integrales y beta

- Suites Flutter/backend, análisis y compilaciones; E2E contra staging.
- Matriz Android (versiones, teléfono pequeño y tableta), red lenta, modo avión,
  cierres/reapertura, almacenamiento lleno, cuenta cambiada, sesión reemplazada
  y token vencido. Notificaciones/permisos, audio/vibración y los tres modos de tema.
- Compras/anuncios de prueba, racha/potenciadores, multijugador/reconexión/abandono,
  códigos de grupo, invitaciones y exportaciones; sin demo ni usuarios ficticios
  en producción. Prueba interna/cerrada, compañeros probadores y corrección de fallos.

### 8H — Entrega técnica iOS, sin publicación comercial

- Compilar en macOS/Xcode, confirmar Bundle ID y permisos realmente necesarios.
- Probar Keychain, Drift/SQLite, notificaciones, PDF/offline, enlaces, audio,
  animaciones y reducción de movimiento en iOS.
- Conservar compras neutrales/simuladas sin activar StoreKit ni publicidad real
  iOS en esta entrega. Mantener iOS es obligatorio; publicarlo en App Store no.

### 8I — Google Play

- Confirmar nombre/applicationId, firma protegida, AAB y versiones; icono, splash,
  capturas, gráfico promocional, descripciones y categoría Educación.
- Declaraciones de contenido/datos/anuncios, privacidad, instrucciones y cuenta
  de revisión si hace falta, países, disponibilidad y productos/precios.
- Verificar los requisitos concretos de pruebas de la cuenta en Play Console,
  corregir advertencias, preparar lanzamiento gradual y reversión documentada.
  Conservar el código/artefactos recuperables y prever una versión correctiva;
  no asumir que la tienda permite instalar un número de versión inferior.

## 13. Etapa 9A — Mantenimiento posterior al lanzamiento

Es operación continua, no una etapa que debamos «terminar» antes de publicar.
Antes del lanzamiento sí se asignan responsables, frecuencia y procedimientos.

- Supervisar API/base, errores Flutter/backend, compras, renovaciones y reembolsos.
- Vigilar tráfico publicitario inválido, ajustar frecuencia según experiencia y
  abandono, revisar costos de Supabase/hosting y preparar capacidad.
- Respaldos automáticos, restauraciones periódicas, rotación de secretos y
  respuesta a incidentes, reportes, bloqueos y contenido inapropiado.
- Mantener preguntas/explicaciones, becas/convocatorias, referencias ICFES,
  programas/enlaces SNIES y licencias/cuadernillos vigentes.
- Actualizar dependencias Flutter/NestJS, revisar cambios de políticas y preparar
  nuevas versiones con un ciclo de revisión y entrega.
- Métricas agregadas de actividad, estudio, retención, uso de simulacros,
  anuncios por usuario y conversión al plan sin anuncios. No enviar respuestas,
  falencias ni puntajes a plataformas publicitarias.

## Mejoras opcionales recuperadas del listado anterior

Registradas para que no se pierdan, **no bloquean la primera publicación** ni
autorizan desarrollarlas todas ahora. Se priorizan después con el equipo.

- Push desde backend (las notificaciones locales ya existen).
- Preferencias menores y recuperación del temporizador activo de Pomodoro.
  La cola remota de bloques completados ya está implementada en P4-A/B.
- Sonido/vibración al terminar Pomodoro: actualmente no los reproduce; requiere
  una decisión separada del feedback de rachas (ver POMODORO.md).
- Búsqueda académica paginada en backend y filtro diario de errores en servidor;
  no rehacer las pantallas y funciones de búsqueda/repaso existentes.
- Más cosméticos, juegos, torneos y modos de Tira y afloja, solo con nuevo acuerdo.
  Las temporadas anuales PR-I no son opcionales; ampliar los seis certificados
  no está autorizado por el alcance vigente.
- Importación masiva confirmada desde panel web/tableta: existe la API de vista
  previa Excel/ZIP sin escrituras; **no equivale a un importador que guarde lotes**.
  El camino principal elegido sigue siendo la carga por página, no exigir Excel.
- Actualización automática de oportunidades oficiales desde fuentes verificadas;
  la revisión editorial/versionada inicial sí forma parte del cierre 7J.
- Publicación comercial en App Store y StoreKit completo, solo con nueva decisión.

## Fuera del lanzamiento inicial / no son etapas pendientes obligatorias

- Publicación comercial en App Store y cobros StoreKit: solo si se autorizan después.
- Tutores y chat de asesoría: descartados del modelo.
- Más juegos no acordados: no se agregan al camino actual. Cima y Rescate mantienen
  sus pendientes de integración real. Taller y Escudo están cancelados.
- Rediseño visual general del panel: no es prioridad; debe ser funcional y accesible.

Referencias: ROADMAP_MOVIL.md, ADMIN_PANEL.md, BUSINESS_MODEL.md,
FLUTTER_STAGING_CONNECTION.md, GAME_POLISH_GUARDIAN.md,
GAMES_PRODUCTION_CHECKLIST.md, GAMIFICATION_CONTRACT.md y OFFLINE_SYNC.md.
