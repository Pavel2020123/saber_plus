# Checkpoint OV-1 — responsable: compañero

13 de octubre de 2026. **Asignado, sin evidencia nueva de implementación recibida.**
Siguiente: auditar orientación existente y preparar OV-1A según
[TRABAJO_PARALELO](TRABAJO_PARALELO.md). No esperar a C2C.

El compañero actualiza este archivo después de cada prueba/avance y el acta
OV1_ORIENTACION.md cuando la cree. Registrar fecha, HEAD y rama de ambos repos,
archivos/contratos, decisiones propuestas o aprobadas, resultados automáticos,
HTTP/SQL y humanos por separado, límites y siguiente paso exacto. Nunca secretos.
El propietario consolida el roadmap al recibir/integrar un bloque o acordar
un cambio de alcance. No editar el checkpoint de instituciones.
Crear este documento no acredita pruebas ni implementación OV-1.

---

## Avance 2026-10-14 — OV-1A

### Estado

**Propuesta preparada; pendiente de revisión y aprobación del propietario.**

No existe todavía implementación funcional nueva de OV-1 en Flutter ni Backend.

### Base de trabajo

Flutter:

- rama: `feat/orientacion-vocacional`
- HEAD inicial: `64ef962`
- base: `origin/main`

Backend:

- no modificado durante OV-1A;
- la copia local existente permanece preservada;
- no se creó todavía rama Backend para OV-1 porque esta entrega documental no requiere API, persistencia ni migraciones.

### Auditoría realizada

Se revisó la orientación existente de Flutter:

- `lib/features/profile/domain/career_orientation.dart`
- `lib/features/profile/presentation/career_orientation_providers.dart`
- `lib/features/profile/presentation/career_orientation_page.dart`
- `test/career_orientation_test.dart`

Conclusión:

La funcionalidad existente corresponde a **orientación académica basada en desempeño** y debe conservarse.

OV-1 será una orientación **por intereses declarados** y no sustituirá ni mezclará silenciosamente esos resultados.

La búsqueda dirigida en Backend no identificó una implementación existente de API o persistencia específica de cuestionario vocacional que deba reutilizarse en OV-1A.

### Artefacto creado

- `docs/OV1_ORIENTACION.md`

Contiene una propuesta inicial de:

- 30 preguntas;
- 6 familias de intereses;
- escala 0–4 más `No sé`;
- tratamiento diferenciado de `No sé`;
- cálculo normalizado por familia;
- cobertura de respuestas;
- tratamiento de intentos incompletos;
- empates sin desempate artificial;
- presentación explicable de resultados;
- ejemplos reproducibles;
- versión propuesta `ov1RulesVersion = 1`;
- decisiones que requieren aprobación del propietario.

### Límites conservados

OV-1 se mantiene como herramienta exploratoria.

No se implementó ni autorizó:

- diagnóstico psicológico;
- afirmación de validación científica;
- XP;
- ranking;
- certificados;
- recompensas según respuesta;
- publicidad segmentada;
- exposición automática a docentes o instituciones;
- recomendaciones deterministas de carrera.

### Pruebas ejecutadas en este avance

No se ejecutaron pruebas Flutter, Backend, HTTP, PostgreSQL ni Android.

Motivo: OV-1A en este punto es exclusivamente una propuesta documental y todavía no modifica código ejecutable.

Sí se ejecutó:

- `git diff --check`

Resultado:

- PASS, sin errores reportados.

No se reutilizan resultados históricos de otros checkpoints como evidencia de OV-1.

### Riesgos y decisiones pendientes

Requieren revisión del propietario antes de considerar OV-1A aprobado:

1. cantidad final de preguntas;
2. familias propuestas y nombres;
3. redacción de las preguntas;
4. escala 0–4;
5. tratamiento de `No sé`;
6. umbral global de respuestas;
7. cobertura mínima por familia;
8. cantidad de familias a mostrar;
9. tratamiento de empates en el límite del tercer lugar;
10. versión inicial de reglas;
11. revisión de contenido previa a publicación.

El CI conocido del Backend PR #7 continúa fuera del alcance de OV-1A y no se modificaron locks ni dependencias.

### Siguiente paso exacto

Revisar el diff documental completo de OV-1A y entregar la propuesta al propietario para decisión.

No iniciar OV-1B automáticamente antes de registrar cuáles reglas fueron aprobadas, modificadas o rechazadas.

---

## Decisión del propietario — 2026-10-14

El propietario comunicó la **aprobación completa y sin modificaciones** de las
11 decisiones propuestas en OV-1A.

Quedan aprobados para continuar la implementación:

1. 30 preguntas.
2. Seis familias de intereses y sus nombres.
3. Redacción propuesta de las 30 preguntas.
4. Escala de respuesta 0–4.
5. Tratamiento de `No sé` como ausencia de evidencia y no como valor 0.
6. Umbral global mínimo del 80 % de respuestas numéricas válidas.
7. Mínimo de 3/5 respuestas válidas por familia.
8. Presentación inicial de hasta tres familias principales.
9. Empates sin desempates artificiales; si el empate cruza el tercer lugar, se muestran todas las familias empatadas aunque excepcionalmente sean más de tres.
10. Versión inicial `ov1RulesVersion = 1`.
11. Revisión de contenido obligatoria antes de publicar recomendaciones.

Aclaración posterior del propietario, 2026-10-14: si un empate cruza el límite
del tercer lugar, se mostrarán todas las familias empatadas, aunque
excepcionalmente el resultado contenga más de tres familias.

Esta aprobación corresponde a **decisiones de producto**. No equivale a
aprobación de PR, merge, despliegue, validación científica ni revisión de
contenido especializada.

### Estado actualizado

OV-1A: **aprobado como definición de producto para continuar desarrollo**.

No existe todavía implementación funcional nueva de cuestionario, API o
persistencia OV-1.

### Siguiente paso exacto

Preparar OV-1B: contrato y persistencia privada.

Antes de modificar Backend se debe partir del `origin/main` actualizado en una
rama/worktree propio de OV-1 y revisar arquitectura, sesión, modelos existentes
y archivos compartidos. No modificar `schema.prisma`, migraciones,
`app.module.ts`, dependencias ni locks sin coordinación previa.

## Actualización 2026-10-14 — siguiente OV-1C

OV-1A está definido y aprobado como decisión de producto en esta rama.
El contenido continúa pendiente de revisión antes de publicación.

OV-1B Backend quedó implementado y validado localmente en el repositorio
SaberPlus-Backend, rama `feat/orientacion-vocacional`, commit `01c4b02`.

Evidencia Backend de OV-1B: build PASS; Jest OV-1 31/31; PostgreSQL real 9/9;
cadena de 65 migraciones PASS; regresión global 1405/1405.

Siguiente entrega: OV-1C, experiencia móvil.

Debe incluir introducción, progreso, volver/corregir respuestas,
guardar/continuar y resultados explicables con familias y carreras para explorar.
El resultado académico existente permanece separado.

Regla específica aprobada de empates: normalmente se muestran hasta tres familias;
si un empate cruza el corte del tercer puesto, se conservan todas las familias
empatadas, por lo que excepcionalmente pueden mostrarse más de tres.

Sin XP, ranking, certificados, publicidad segmentada, publicación automática
a docentes/instituciones, pagos, juegos ni animaciones en OV-1C.

No se realizó push, merge ni despliegue.

## OV-1C — experiencia móvil local (2026-10-15)

En `feat/orientacion-vocacional`, sobre HEAD inicial `2463aea`, se implementó
localmente una experiencia vocacional privada separada de la orientación
académica. La nueva entrada **Explora tus intereses** y la ruta
`/student/more/profile/vocational-orientation` no sustituyen **Carreras y
universidades** ni `/student/more/profile/orientation`.

La app usa el Dio autenticado para consultar el cuestionario OV-1B, comenzar o
reanudar el intento, guardar cada selección y corrección, finalizar según la
respuesta del servidor, consultar historial y eliminar un intento propio. No
envía `usuarioId`, no calcula cobertura ni puntuaciones y no crea datos de
Backend para sesiones demo. La lectura estricta rechaza versiones, escalas,
respuestas o terminales incompatibles con el contrato. El resultado presenta
las familias principales en el orden recibido, conserva todos los empates que
cruzan el tercer puesto y muestra las demás familias del snapshot aparte.

Se guardan las respuestas al seleccionarlas. Si falla el guardado, la respuesta
confirmada por el servidor conserva el indicador de selección y la nueva
respuesta aparece solo como pendiente para reintentar; no se permite finalizar
mientras siga pendiente. Al reanudar se abre la primera pregunta sin respuesta
en el orden del cuestionario recibido; si todas tienen respuesta, se abre la
última para revisar o finalizar sin decidir cobertura en Flutter. Un rechazo
`COBERTURA_INSUFICIENTE` conserva el intento editable. El cambio de cuenta
limpia los datos privados visibles.

Validación local con Flutter 3.47.0 / Dart 3.13.0: pruebas OV-1C 16/16
aprobadas; regresión dirigida de `career_orientation_test.dart` y
`widget_test.dart` 37/37 aprobada; `flutter analyze --no-pub` de los nueve
archivos Dart de la implementación inicial sin incidencias y de los tres
archivos Dart corregidos en la revisión humana también sin incidencias. Se
aplicó `dart format` a los archivos afectados. La integración real local y la regresión global se validaron posteriormente y se registran en el cierre técnico de OV-1C. No hubo commit, push, merge
ni despliegue durante OV-1C.

Sigue pendiente una correspondencia editorial aprobada entre familias y
carreras concretas para proponer varias opciones técnicas, tecnológicas y
universitarias. Hasta esa revisión, la pantalla ofrece la consulta oficial de
programas SNIES separada del resultado vocacional. También sigue pendiente la
revisión de contenido exigida antes de publicar recomendaciones; OV-1D cubre
Sabi y la validación profunda de accesibilidad.

## Validación de cierre técnico OV-1C — 2026-10-15

Después de la implementación y revisión humana se ejecutaron las siguientes
validaciones locales:

- Pruebas específicas OV-1C: 16/16 PASS.
- Regresión dirigida de orientación académica y navegación: 37/37 PASS.
- Integración real Flutter/Dart -> HTTP OV-1B -> PostgreSQL 17 desechable:
  22/22 checks PASS.
- La integración real cubrió cuestionario, inicio, respuestas numéricas,
  `NO_SE`, reanudación, corrección, cobertura insuficiente, finalización,
  snapshot, empates, historial, repetición y eliminación.
- `flutter analyze --no-pub` global: 0 incidencias.
- Suite Flutter global: 818 PASS, 13 SKIP y 0 FAIL.
- Los 13 SKIP corresponden a pruebas opt-in que requieren variables o harness
  externos/locales específicos; no se atribuyen como pruebas ejecutadas.
- `git diff --check`: PASS.
- `pubspec.yaml`, `pubspec.lock` y `analysis_options.yaml`: sin cambios.
- Backend de referencia: limpio después de la integración.
- PostgreSQL de integración: desechable, local y eliminado al finalizar.
- No se utilizó Supabase, `postgres-local` ni una base remota.

No hubo staging, commit, push, merge ni deploy durante las validaciones.

Permanece pendiente la revisión editorial del contenido antes de publicación y
la correspondencia aprobada entre familias y carreras concretas. OV-1D cubre
Sabi y la validación profunda de accesibilidad.

## OV-1D1 — accesibilidad automatizada local (2026-10-15)

La pantalla **Explora tus intereses** ahora identifica semánticamente el progreso
«Pregunta X de 30», las seis respuestas como acciones con estado confirmado o
sin confirmar, y la respuesta aún pendiente como aviso separado. Los errores
de carga, guardado, cobertura e historial usan regiones dinámicas anunciables.
Las familias principales tienen encabezados semánticos; abrir y eliminar un
intento del historial usan etiquetas comprensibles sin leer UUID. Los botones
locales relevantes mantienen objetivos táctiles de al menos 48 píxeles lógicos.
No se añadieron animaciones ni se cambió el tema global.

Validación dirigida con Flutter 3.47.0: seis pruebas nuevas OV-1D1 aprobadas
en viewport lógico 320 × 640 y texto al 200 %, incluyendo tema claro/oscuro,
introducción, cuestionario, respuesta confirmada y pendiente, errores,
cobertura, resultado, empate, historial, semántica, privacidad al cambiar de
cuenta y targets. OV-1C: 16/16 PASS; orientación académica y navegación:
37/37 PASS; análisis dirigido de los dos archivos Dart afectados: sin
incidencias; `git diff --check`: PASS. Estos resultados son locales y
automatizados, no una prueba humana ni una validación científica.

**OV-1D no está cerrado.** Quedan pendientes las 12 ilustraciones profesionales
de Sabi, su aprobación y revisión visual, prueba humana Android, evaluación en
iOS y revisión editorial del contenido antes de publicación. OV-1D1 no añadió
arte ni reutilizó las insignias o el prototipo de Duelo fantasma.

## OV-1D2A — tres prototipos aprobados visualmente

La revisión humana aprobó Medicina, Sistemas/software y Ambiental/agro tras
tres iteraciones visuales. La arquitectura aprobada usa
`assets/characters/sabi/reference/sabi_front.png` como base canónica e
inmutable: Sabi no se redibuja. Ropa, accesorios y confeti son capas nativas;
el confeti es estático y no utiliza animación. Las previews están en
`build/sabi-vocational-preview/`.

Las otras nueve profesiones corresponden a OV-1D2B, cuyo estado se registra abajo.
Estas tres ilustraciones tampoco están conectadas a resultados o familias;
D3 realizará esa integración. Siguen pendientes la prueba humana Android,
la comprobación iOS y la revisión editorial previa a publicación. La
aprobación visual no constituye validación científica.

## OV-1D2B — catálogo de 12 variantes aprobado visualmente

La revisión humana aprobó las nueve variantes adicionales de OV-1D2B.
Medicina, Sistemas/software y Ambiental/agro conservan su aprobación D2A;
el catálogo completo de exactamente 12 variantes queda aprobado visualmente:

| Variante nueva | Diferenciación visual |
| --- | --- |
| Enfermería | Uniforme clínico corto turquesa y tablero de cuidados. |
| Psicología | Cardigan lavanda, cuaderno y dos burbujas de conversación sin texto. |
| Derecho | Traje oscuro abierto y libro jurídico con balanza gráfica. |
| Ingeniería industrial | Chaleco naranja con bandas y diagrama de procesos. |
| Ingeniería civil | Chaleco amarillo con bolsillos técnicos y plano de puente. |
| Administración | Chaqueta azul verdosa y tablero de planificación con tarjetas. |
| Contaduría | Chaleco granate, calculadora y registro cuadriculado. |
| Educación/licenciaturas | Cardigan ocre, libro abierto y pizarra con formas. |
| Diseño/comunicación visual | Chaqueta violeta con bolsillo, tableta gráfica y lápiz. |

Todas son composiciones nativas sobre el PNG canónico intacto, con confeti
estático. No hay animación, dependencias nuevas ni PNG profesionales de
producción. Cada variante expone una sola imagen semántica en español.
Las previews individuales y las hojas rotuladas de 12 y de 6 piezas se
generan únicamente con `CAPTURE_SABI_OV1D2=true` bajo
`build/sabi-vocational-preview/`; no se añaden a Git. Los rótulos de revisión
usan la fuente Roboto incluida en el SDK Flutter, fuera del arte individual.

Las 12 ilustraciones aún no están conectadas a familias, resultados ni
historial. OV-1D3 realizará esa integración. Siguen pendientes la prueba humana
Android, iOS y la revisión editorial antes de publicación. La aprobación
artística no equivale a validación científica.

## OV-1D3A — auditoría del flujo y galería exploratoria local

**APROBADO VISUALMENTE Y TÉCNICAMENTE para este alcance local**, pendiente de
revisión final previa al staging. La revisión humana aprobó las ocho vistas
de la página real: galería cerrada/abierta, otra profesión seleccionada,
320 × 640 y su contexto, texto al 200 % y su contexto, y dark mode. El scroll
necesario con texto al 200 % es aceptable y no se reduce la escala del texto.

Preflight: rama `feat/orientacion-vocacional`, HEAD
`2cfc35234531ba1d151a27bfbbb8b81b6a5f34e6`, igual a su remoto propio (0/0).
`origin/main` permanece en `21e39e6c0a67c235ae4dc71d74666399246bb9a9`,
con divergencia autorizada 7/1. El worktree inicial estaba limpio.

### Flujo auditado y clasificación

| Archivo real | Responsabilidad observada |
| --- | --- |
| `lib/features/profile/presentation/academic_profile_page.dart` | Entrada «Explora tus intereses», separada de orientación académica. Solo lectura. |
| `lib/app/router.dart` | Ruta existente `/student/more/profile/vocational-orientation`. Solo lectura, sin rutas nuevas. |
| `lib/features/profile/presentation/vocational_orientation_page.dart` | Introducción, preguntas, progreso, pendiente/confirmada, reintentos, cobertura, resultado, empates, historial y apertura/borrado de intentos. El detalle completado reutiliza el resultado; el activo reabre el cuestionario. |
| `lib/features/profile/presentation/vocational_orientation_providers.dart` | Repositorio autenticado, bloqueo demo y apertura de consulta oficial. Solo lectura. |
| `lib/features/profile/domain/vocational_orientation.dart` | Parser de las 30 preguntas, respuestas, cobertura y snapshot; conserva scores y todas las familias principales del servidor. Solo lectura. |
| `lib/features/profile/domain/vocational_orientation_repository.dart` y `lib/features/profile/data/remote_vocational_orientation_repository.dart` | Contrato y llamadas existentes para carga, guardado, finalización, historial y borrado. Solo lectura. |
| `lib/features/profile/presentation/sabi_profession_illustration.dart` | Catálogo aprobado. Antes de D3A solo lo usaban sus pruebas, sin Sabi en el flujo vocacional. |
| `test/vocational_orientation_test.dart`, `test/vocational_orientation_accessibility_test.dart`, `test/sabi_vocational_prototypes_test.dart` | Contratos, flujo, privacidad, accesibilidad y catálogo visual existentes. |

- **A, seguro ahora:** galería opcional en la introducción, después de las
  acciones de comenzar/continuar e historial. Aporta una exploración visual
  general antes del cuestionario, sin crear un intento ni interrumpirlo.
- **B, requiere decisión editorial:** representar familias/top/empates o
  resultados históricos con una profesión, o proponer carreras derivadas de
  scores. No existe mapping aprobado y estas integraciones quedan bloqueadas.
- **C, no recomendado:** alterar scoring, cobertura, persistencia, XP,
  diagnóstico, predicciones o sharing automático; mezclar el resultado con
  orientación académica. Los props durante las preguntas tampoco aportan una
  función necesaria al cuestionario actual.

### Integración implementada

`lib/features/profile/presentation/sabi_profession_gallery.dart` presenta las
12 variantes en el orden fijo del enum. Es un componente neutral, sin entradas
de usuario, familia, score o resultado. Arranca cerrado, avisa que sus ejemplos
son independientes de las respuestas y permite recorrerlos con controles
locales de al menos 48 píxeles lógicos. No guarda la selección ni hace llamadas.
No aparece en cuestionario, resultado, errores ni historial.

Los nombres visibles residen en `SabiProfession.displayName`; se reutilizan
también en las hojas de revisión, sin duplicar el catálogo ni los painters.
El widget de ilustración conserva su etiqueta única en español y ahora marca
explícitamente su límite semántico para que no se fusione con los controles
de la galería. El PNG canónico y los dibujos aprobados permanecen intactos.

Validación local dirigida con Flutter 3.47.0: formato sin cambios y analyze
de los seis Dart afectados sin incidencias; catálogo 27 PASS / 0 FAIL /
1 SKIP (captura opt-in); flujo vocacional 18 PASS / 0 FAIL / 0 SKIP;
accesibilidad 6 PASS / 0 FAIL / 0 SKIP; galería 4 PASS / 0 FAIL / 1 SKIP
(captura D3A opt-in). La galería se comprobó en
320 × 640 y 640 × 320, texto al 200 %, claro y oscuro. `git diff --check`:
PASS. No se ejecutó la suite global ni prueba manual en dispositivo.

Las dos pruebas de integración D3A usan un repositorio en memoria: durante
la exploración verifican que no se inicia/finaliza un intento ni se guardan
respuestas; también conservan el objeto de resultado histórico y sus cuatro
familias principales empatadas. Cubren la UI y su interacción con ese doble
de prueba, no persistencia real, HTTP, Backend ni PostgreSQL. La inspección
del componente confirma que no importa ni llama repositorios.

`CAPTURE_SABI_OV1D3A` solo habilita un test con datos sintéticos locales y
escrituras limitadas a ocho nombres bajo `build/sabi-vocational-d3a/`.
Roboto y MaterialIcons se cargan desde el SDK exclusivamente para evidencia
del runner; no se incorporan assets ni dependencias de producción. Las
capturas siguen ignoradas/no rastreadas y no se regeneraron en este cierre.

No existe asociación familia → profesión ni recomendación determinista.
OV-1D3 no está completo. Android humano, iOS y revisión editorial siguen
pendientes; las ilustraciones comunican ejemplos y no validación científica.

### Checklist Android humana pendiente

Todos los puntos siguientes están **sin ejecutar**. Usar una cuenta y un
entorno de prueba autorizados y registrar dispositivo, versión Android,
build de la app y evidencias; preparar casos de empate/cobertura suficientes
sin alterar datos productivos.

- [ ] Abrir «Explora tus intereses» desde el perfil; comprobar inicio y avisos.
- [ ] Abrir/cerrar la galería y recorrer los 12 ámbitos; comprobar independencia respecto de las respuestas y que no crea intentos.
- [ ] Responder las 30 preguntas, incluyendo «No sé», y comprobar el progreso.
- [ ] Comprobar respuesta pendiente, confirmación del servidor, error de guardado y reintento sin perder la última respuesta confirmada.
- [ ] Corregir una respuesta y navegar anterior/siguiente.
- [ ] Salir y reanudar el intento con las respuestas confirmadas.
- [ ] Probar cobertura insuficiente y completar/corregir antes de finalizar.
- [ ] Verificar resultado y empate reproducible, sin desempates ni profesiones asignadas.
- [ ] Abrir historial y detalle de intentos activos/completados; comprobar paginación si hay datos suficientes.
- [ ] Cancelar y confirmar el borrado de un intento; comprobar su desaparición.
- [ ] Cambiar de cuenta y comprobar que no quedan respuestas, resultados ni historial de la anterior.
- [ ] Comprobar textos, imágenes y controles en claro/oscuro, texto grande, pantalla pequeña y orientación horizontal.
- [ ] Confirmar legibilidad, scroll, ausencia de overflow y objetivos táctiles de al menos 48 píxeles lógicos.
- [ ] Con TalkBack, recorrer progreso, opciones, pendiente/confirmada, avisos, familias e historial; en la galería, comprobar una imagen anunciada por vez y controles comprensibles.
- [ ] Registrar incidencias reales; no declarar Android completado hasta revisar las evidencias. iOS y revisión editorial se validan por separado.

## OV-1D3B — resultados explicativos y ámbitos editoriales para demo (2026-10-19)

**Implementado, validado automáticamente en local y aprobado visualmente por el
propietario en capturas y Android físico para este alcance de demo.
OV-1D3 no está cerrado.** Base de esta entrega:
`feat/orientacion-vocacional`, HEAD `b463f50e6fc7bcd7823e36b567c450e9fc651953`.
El árbol estaba limpio tras la restauración de `pubspec.lock` realizada por el
propietario; esta entrega no modifica dependencias.

### Aprobación y alcance

El propietario aprobó expresamente la tabla editorial de seis familias a ámbitos
profesionales para esta demo. Sustituye el bloqueo por falta de aprobación de
mapping registrado históricamente en D3A, exclusivamente para estos ejemplos;
no aprueba recomendaciones científicas ni elimina la revisión especializada
previa a publicación. La tabla exacta está centralizada en
`vocationalRelatedProfessions`, en
`lib/features/profile/presentation/vocational_result_overview.dart`.

El resumen conserva las familias `principales` y su orden del servidor, sin
numerarlas ni volver a calcular el corte. Los empates que cruzan el corte siguen
completos. Para Sabi se consultan los puntajes del snapshot entre esas familias;
si comparten el máximo, se explicita la igualdad y se pueden recorrer ejemplos
de todas ellas sin declarar una ganadora. El orden del catálogo es editorial,
no una preferencia profesional. Los ámbitos repetidos se muestran una sola vez
por selector, conservando todas sus relaciones con las familias correspondientes.

La pantalla presenta interpretación, ejemplos Sabi, exploración desplegable de
ámbitos relacionados, índices de las seis familias y detalle desplegable de
respuestas. Usa `VocationalFamilyResult.score` del servidor: índice normalizado
0..100, sin porcentajes ni probabilidades. Las barras son solo representación;
la etiqueta semántica incluye familia, puntaje y cobertura. Conserva respuestas
válidas, cobertura por familia, actividades del snapshot, consulta oficial,
repetición, historial, privacidad y límites. No cambia scoring, reglas, modelos,
HTTP, persistencia ni navegación. Reutiliza el catálogo Sabi sin modificarlo.

### Evidencia automatizada y visual local

Flutter 3.47.0 / Dart 3.13.0, comandos explícitos con el SDK aislado:

| Suite dirigida | PASS | FAIL | SKIP |
| --- | ---: | ---: | ---: |
| `vocational_orientation_test.dart` | 18 | 0 | 0 |
| `vocational_orientation_accessibility_test.dart` | 6 | 0 | 0 |
| `sabi_profession_gallery_test.dart` | 4 | 0 | 1 |
| `sabi_vocational_prototypes_test.dart` | 27 | 0 | 1 |
| `vocational_result_test.dart` | 9 | 0 | 1 |
| `career_orientation_test.dart` y `widget_test.dart` | 37 | 0 | 0 |
| **Total, ejecución conjunta final** | **101** | **0** | **3** |

Los tres SKIP son capturas opt-in. La prueba de capturas D3B se ejecutó aparte
con `CAPTURE_SABI_OV1D3B=true`: 1 PASS, 0 FAIL, 0 SKIP. Generó ocho PNG en
`build/sabi-vocational-d3b/`: `result_normal`, `result_sabi`, `result_related`,
`result_tie`, `result_small`, `result_text_200`, `result_dark`, `result_scores`.
Son capturas de la página real con snapshots y repositorio sintéticos locales,
no datos privados ni una nueva validación HTTP/Backend/Android. Están ignoradas
por Git. Se reutilizaron las fuentes del SDK solo en el harness de pruebas.

`dart format`: aplicado a los cinco Dart afectados; comprobación posterior sin
cambios. `flutter analyze --no-pub` dirigido: sin incidencias. `git diff --check`:
PASS. Las pruebas cubren tabla editorial exacta, tres principales, empates de
máximo y corte, seis índices del servidor, relaciones múltiples, detalle,
semántica de imagen y puntajes, targets, 320 × 640, texto al 200 %, claro/oscuro,
historial, cuestionario, finalización y ausencia de escrituras al explorar.

Fallos intermedios conservados como diagnóstico: cinco pruebas nuevas fallaron
por liberar demasiado tarde su handle semántico; se corrigió con `try/finally`.
La primera regresión conjunta tuvo cuatro fallos: una expectativa antigua
prohibía incluso el aviso «No miden aptitud» y tres agotaban el recorrido de
scroll de la pantalla anterior. Se actualizó la expectativa al aviso explícito
y el recorrido al tamaño real del contenido, conservando las aserciones. El
análisis detectó siete avisos de llaves en el test nuevo, corregidos antes de
la ejecución final. No hubo fallos pendientes en las validaciones finales.

El PNG canónico mantiene hash `de1e006ebb4e7fec4bd1ec771b3f29c6f28075d4`.
Sin cambios en `pubspec.yaml`, `pubspec.lock`, `analysis_options.yaml`, router,
assets, Backend, instituciones ni competición. Sin commit, push, merge, rebase
ni deploy.

### Revisión humana posterior aprobada

El propietario revisó y aprobó las ocho capturas D3B enumeradas arriba. Además,
la nueva UI se instaló mediante Flutter y se ejecutó en un Samsung SM A556E
físico, conectado por USB con `adb reverse` a `http://127.0.0.1:43187`, con
Backend local real y PostgreSQL temporal activos. Se abrió desde el historial
un intento real previamente completado y persistido.

En ese resultado se comprobaron visualmente el encabezado, las familias
principales reales, las respuestas válidas, «Un ámbito que puedes explorar»,
Sabi relacionado, los controles anterior/siguiente y varios ejemplos, el aviso
«No es una recomendación de carrera», los ámbitos relacionados, los seis índices
del servidor y sus barras, el scroll y la navegación inferior, sin overflow
visible ni recortes graves.

El recorrido real cuestionario → finalización → resultado → historial,
reapertura del resultado y cierre/reapertura desde el icono se había comprobado
inmediatamente antes de D3B en el mismo Android y Backend local. La revisión
física posterior a D3B fue visual sobre el resultado persistido y su navegación;
no fue otro recorrido completo de 30 preguntas ni un nuevo E2E automatizado
real contra Backend.

Esta aprobación no acredita iOS, producción, validación científica ni revisión
editorial especializada completa. TalkBack completo, orientación horizontal y
pérdida de red no se comprobaron en esta revisión y permanecen pendientes.
OV-1D3 completo continúa abierto.

## OV-1D3C — preparación de cierre técnico y validación Android

26 de octubre de 2026. **Preparación técnica automatizada completada en local;
OV-1D3 y OV-1D permanecen abiertos a validación humana/externa.**
Flutter: `feat/orientacion-vocacional`, HEAD inicial y final
`7409129fad1fe386f3a4fa7e2429f686a4934243`, igual al remoto propio observado.
Backend, solo inspección Git: misma rama, HEAD
`7a97a9dae25cabca8015459a1d82cbfb422cfbad`. Ambos árboles estaban limpios.
No se levantaron Backend, PostgreSQL ni el runner de demo.

### Auditoría e inventario antes de modificar

Se inspeccionaron las actas OV-1, TRABAJO_PARALELO, la página y sus métodos
`_load`, `_save`, `_finish`, `_openHistory`, `_moreHistory`, `_openAttempt`,
`_delete`; providers, contrato/modelos/repositorio remoto, ApiClient y
AuthInterceptor; overview, galería, ilustración y sus pruebas OV-1/Sabi.
La orientación académica y el prototipo Sabi de juegos no se mezclan con OV-1.

A = cobertura automática existente; B = parcial; C = sin cobertura pero
automatizable; D = requiere comprobación humana real. La tabla siguiente resume
el inventario de los 37 puntos. Existe además evidencia local no versionada de
la ejecución D3C; no forma parte de los archivos disponibles en el repositorio.

| Clasificación inicial | Puntos y evidencia | Resultado D3C |
| --- | --- | --- |
| A | Introducción, inicio/reanudación, confirmación, fallo de guardado/reintento, última confirmada, carga/reintento, cobertura insuficiente, finalización, resultados/empates/seis índices, historial/completados/eliminación, demo, texto 200 %, pantalla pequeña, temas, semántica, UUID no visibles, targets, scroll, autoridad Backend y payloads. Pruebas existentes conservadas. | Se volvieron a ejecutar, sin duplicar su cobertura exacta. |
| B | Puntos 4/5: petición realmente pendiente y bloqueo; 9: errores y recuperación; 18: activo abierto desde historial; 20: respuesta tardía tras cambiar cuenta; 24: landscape del flujo completo; 35: Dio y timeouts de las operaciones. | Once pruebas nuevas: nueve en orientación y dos de rotación; cobertura automática A para los casos definidos. |
| C | No se identificó un punto completamente descubierto: los huecos eran parciales B. | No se añadió funcionalidad ni un motor nuevo. |
| D | Dispositivo Android/TalkBack, foco/gestos reales, rotación y pérdida de red reales; iOS/editorial/piloto. | Sin ejecución humana nueva en D3C. |

No se demostró un defecto de runtime que requiriera modificarlo. Solo cambiaron
los dos archivos de pruebas y estas dos actas. Se conservaron reglas,
autoridad servidor, scoring, HTTP, persistencia, navegación y arte Sabi.

### Automático ejecutado

SDK utilizado: Flutter 3.47.0 y Dart correspondiente al mismo SDK.
Comandos sin rutas personales, ejecutados desde la raíz del repositorio:

```text
flutter.bat test --no-pub test/vocational_orientation_test.dart test/vocational_orientation_accessibility_test.dart test/vocational_result_test.dart test/sabi_profession_gallery_test.dart test/sabi_vocational_prototypes_test.dart --reporter expanded
dart.bat format test/vocational_orientation_test.dart test/vocational_orientation_accessibility_test.dart
flutter.bat analyze --no-pub test/vocational_orientation_test.dart test/vocational_orientation_accessibility_test.dart
flutter.bat test --no-pub --reporter expanded
git diff --check
```

| Suite dirigida | PASS | FAIL | SKIP |
| --- | ---: | ---: | ---: |
| `vocational_orientation_test.dart` | 27 | 0 | 0 |
| `vocational_orientation_accessibility_test.dart` | 8 | 0 | 0 |
| `vocational_result_test.dart` | 9 | 0 | 1 |
| `sabi_profession_gallery_test.dart` | 4 | 0 | 1 |
| `sabi_vocational_prototypes_test.dart` | 27 | 0 | 1 |
| **Dirigidas, ~11 s** | **75** | **0** | **3** |
| **Global, ~110 s** | **877** | **0** | **16** |

Los tres SKIP dirigidos son capturas opt-in, no ejecutadas. Los 16 SKIP globales
incluyen esos tres y trece pruebas que requieren variables/harness explícitos
(AUTH_E2E, ranking local I2-5, instituciones C1, staging y Rescate local).
No acreditan integración real ni se cuentan como PASS. No se regeneraron
capturas. Analyze final: sin incidencias (~7,4 s). Formato aplicado a los dos
Dart; diff check PASS. Los conteos globales y dirigidos son ejecuciones separadas,
no deben sumarse como pruebas únicas.

Las pruebas nuevas usan `Completer` para mantener el guardado sin resolver y
verificar el bloqueo, sin esperas reales; comprueban respuesta tardía tras cambio
de cuenta, timeout al consultar el intento, finalización fallida con respuestas
intactas, paginación sin saltar página tras fallo, apertura activa y error/reintento
de apertura/borrado. Tres interceptores Dio prueban connectionError,
connectionTimeout y receiveTimeout en las ocho operaciones, sin red real.
Dos widget tests rotan 320×640 a 640×320 con texto 200 %, claro/oscuro,
conservan respuesta/progreso y recorren resultado, puntajes, historial y galería
con controles utilizables y sin excepciones de overflow. No equivalen a TalkBack
ni a rotación física. El repositorio en memoria no demuestra persistencia real.

Fallos intermedios: primera ejecución ampliada, 25 PASS / 2 FAIL / 0 SKIP.
Ambos fallos eran búsquedas del harness (encabezado del historial fuera del
viewport construido y clave inexistente del botón de historial en resultado).
Se corrigieron las búsquedas, manteniendo las aserciones; reintento: 35 PASS /
0 FAIL / 0 SKIP en las dos suites afectadas. Analyze inicial señaló cinco avisos
de llaves en el doble de prueba; se corrigieron exclusivamente con
`dart.bat fix --apply --code=curly_braces_in_flow_control_structures test/vocational_orientation_test.dart`.
La suite global validó después el código final formateado. Logs locales en
`build/ov1-d3c-{first-tests,retry-tests,directed,analyze,global}.log`, ignorados.

### Humano ejecutado y pendiente

**Ninguna prueba humana nueva ejecutada en D3C.** Se conserva la aprobación
histórica D3B de capturas/Android para la demo; no acredita los casos nuevos.
Checklist pendiente en Samsung físico con cuenta/entorno de prueba autorizados:

- [ ] Entrar en «Explora tus intereses» e iniciar/continuar con TalkBack.
- [ ] Escuchar «Pregunta X de 30», recorrer opciones y «Respuesta confirmada».
- [ ] Observar pendiente si el entorno lo permite; comprobar bloqueo, aviso,
  error/reintento y conservación de la última confirmada.
- [ ] Comprobar pérdida de red y recuperación reales sin falsa confirmación.
- [ ] Finalizar y recorrer familias, índices, cobertura, explicaciones y Sabi.
- [ ] Abrir historial, abrir un intento y eliminar un intento de prueba.
- [ ] Recorrer galería y anterior/siguiente; comprobar imagen anunciada una vez.
- [ ] Confirmar ausencia de UUID anunciados y orden lógico de foco/gestos.
- [ ] Rotar físicamente durante cuestionario/resultado/historial y comprobar
  texto grande, scroll, controles y conservación del estado.

Pendiente externo: iOS real en entorno Apple; revisión editorial especializada;
piloto previo a publicación. No se atribuyen validación científica, producción,
publicación ni cierre global OV-1. La integración real Flutter/Backend/PostgreSQL
se reserva al checkpoint posterior autorizado. No se modificaron dependencias,
configuración, router, assets, Backend, instituciones ni competición. Sin git add,
commit, push, merge, rebase, deploy ni acceso a base remota.


## OV-1D3D — validación humana Android y PostgreSQL local real

Acta documental del 27 de octubre de 2026, basada en la evidencia de ejecución
aportada por el propietario para la sesión D3D. Esta edición no repite pruebas
ni inicia servicios. Rama `feat/orientacion-vocacional`, HEAD base
`7409129fad1fe386f3a4fa7e2429f686a4934243`.
Las secciones D3C anteriores conservan su estado histórico: sus pendientes
Android y de integración local se actualizan mediante la evidencia D3D siguiente,
sin atribuir pruebas humanas a la ejecución automatizada D3C.

### Evidencia automatizada y PostgreSQL real

D3C conserva sus resultados: dirigidas **75 PASS / 0 FAIL / 3 SKIP**;
global **877 PASS / 0 FAIL / 16 SKIP**; analyze limpio, formato y diff check
sin errores funcionales. Los avisos LF/CRLF no son fallos. Sus pruebas de
Completer, bloqueo, confirmación/pendiente, retry, cambio de cuenta, errores Dio
en ocho operaciones, paginación, rotación simulada, texto 200 %, temas,
semántica, privacidad, targets y Sabi no equivalen por sí mismas a prueba física.

D3D utilizó PostgreSQL 17 en Docker temporal, aislado y limitado a loopback.
No utilizó `postgres-local`, Supabase, Render, bases remotas ni producción.
Desde el backend local se ejecutaron:

```text
npx prisma migrate deploy
node --test --test-concurrency=1 test/orientacion-vocacional-postgres.test.cjs
```

Se encontraron/aplicaron **65 migraciones**, incluida
`20261014120000_vocational_orientation_v1`. Suite: **9 tests / 9 PASS /
0 FAIL / 0 SKIP; exit 0**. Cobertura real documentada:

- Aislamiento: B no puede leer, editar, finalizar ni eliminar A, ni verlo en historial;
  JWT reales teacher/admin no obtienen acceso mediante claim de estudiante.
- Inicios simultáneos producen un único intento persistido; `NO_SE` persiste;
  snapshot conserva su contenido tras retry/reinicio y el historial completado es inmutable.
- Cobertura rechaza 23 respuestas o familia deficiente; corregir permite finalizar
  con 24 cuando se cumple el mínimo; save/finalize concurrentes no alteran el snapshot final.
- DB rechaza preguntas desconocidas, valores inválidos y cambios de identidad;
  HTTP excluye puntajes, versión y propietario enviados por cliente.
- RLS habilitado y roles públicos sin acceso a las tablas privadas, en esta DB local.

Esto no verifica roles ni RLS productivos. Los fixtures competitivos del harness
no son evidencia OV-1 ni partidas reales.

### Prueba humana Android real

Samsung SM-A556E, Android 16/API 36; Flutter 3.47.0 y Dart del mismo SDK;
build debug local. `APP_ENV=dev`, `DEMO_MODE=false`, API y contenido en
`http://127.0.0.1:43187`, mediante `adb reverse tcp:43187 tcp:43187` hacia
NestJS real y PostgreSQL temporal. Se utilizó una cuenta sintética local,
sin registrar contraseñas en esta documentación.

- Flujo normal: login, entrada «Explora tus intereses», introducción, inicio,
  guardado y cambio de respuesta; salir/reingresar reanuda el mismo intento.
  Sin overflow funcional observado.
- Conectividad real: se retiró el bridge con `adb reverse --remove tcp:43187`.
  La respuesta anterior siguió confirmada; la nueva quedó «Pendiente de guardar»,
  con error y «Reintentar guardado». No hubo falsa confirmación y navegación/
  finalización quedaron bloqueadas cuando correspondía. Al restaurar el bridge,
  retry confirmó la nueva respuesta, comprobada al volver a la pregunta.
- Cobertura insuficiente: el backend rechazó finalizar con pocas respuestas con
  «Aún faltan respuestas numéricas suficientes. Puedes volver, completar o
  corregir y finalizar de nuevo.». No hubo falso resultado; el intento siguió
  editable y conservó la respuesta confirmada.
- Finalización válida: **27 respuestas válidas de 30**. Principales, en orden:
  Negocios, organización y emprendimiento; Salud y ciencias de la vida;
  Tecnología e ingeniería.

| Familia | Índice observado | Cobertura |
| --- | ---: | ---: |
| Tecnología e ingeniería | 70/100 | 5/5 |
| Salud y ciencias de la vida | 75/100 | 4/5 |
| Sociedad, derecho y comunicación | 55/100 | 5/5 |
| Negocios, organización y emprendimiento | 80/100 | 5/5 |
| Educación, humanidades e idiomas | 45/100 | 5/5 |
| Creatividad, diseño y entorno | 50/100 | 3/5 |

Se verificaron encabezado, seis familias, índices 0..100 y advertencias:
intereses declarados, no probabilidad, diagnóstico, aptitud, predicción de éxito
ni admisión, ni decisión profesional definitiva. Sabi aparece bajo «Un ámbito
que puedes explorar», con «No es una recomendación de carrera» y controles
anterior/siguiente funcionales. Sin XP, ranking, recompensas o certificados,
ni overflow funcional observado. Este caso no prueba empate en el corte del
tercer lugar: esa regla conserva respaldo automatizado.

Historial: el completado aparece, abre y conserva el resultado final; eliminación
real con confirmación explícita y actualización del historial. También se creó/
reanudó un intento activo desde historial.

Rotación física portrait → landscape → portrait: scroll, opciones, controles
Anterior/Siguiente/Ver resultado y avance entre preguntas utilizables; respuesta
confirmada conservada, sin overflow funcional observado. Con `font_scale=2.0`
se comprobaron encabezado, enunciado, opciones, controles, scroll, confirmación
y navegación. **La barra inferior se vio muy comprimida, pero siguió utilizable
y accesible.** Se restauró `font_scale=1.0`.

TalkBack real: anuncia Pregunta X de 30 y enunciado, recorre opciones por separado,
distingue selección, permite cambiarla con doble toque y confirmar; controles
accesibles y sin UUID internos. Con pérdida real del bridge anuncia pendiente y
error, permite retry, conserva la respuesta anterior y mantiene foco utilizable;
restaurar conexión confirma la nueva respuesta. Resultado completo, principales,
seis familias/puntajes y advertencias recorribles; Sabi se anuncia como una sola
imagen, controles accesibles y sin nombres internos de assets. Historial,
apertura del completado y diálogo Cancelar/Eliminar accesibles.

### D3D-F1 — fecha local del historial

La prueba física detectó que el historial podía mostrar el día UTC:
`2026-10-27T04:05:00Z` corresponde a `2026-10-26 23:05:00 -05:00` en Colombia.
El fix existente en `lib/features/profile/domain/vocational_orientation.dart`
cambia únicamente `DateTime.parse(_string(value))` por
`DateTime.parse(_string(value)).toLocal()`. Conserva el instante y presenta en
zona local `startedAt`, `updatedAt` y `completedAt` del intento y del resultado.

Regresiones en `test/vocational_orientation_test.dart`, grupo
`OV-1D3D-F1 local API dates`: conversión UTC a local (`isUtc == false`), mismo
instante y microsegundos, equivalencia UTC/-05:00, rechazo de diferencia de
un microsegundo, intento activo sin finalización fabricada y texto/Semantics
locales del historial. Validación final F1 aportada: **29/29 PASS, exit 0**;
analyze de dominio y test **0 issues**; diff check **exit 0**.
No se modificó el fix en esta edición documental. Esta evidencia no afirma una
revalidación física posterior del límite UTC/local: el cierre específico del
defecto requiere repetir ese caso en Android o evidencia controlada equivalente.
La suite global D3C no se presenta como una ejecución posterior a F1.

### Limpieza y límites del cierre

Según la evidencia de cierre del laboratorio: API 43187 sin escucha, ADB reverse
vacío, `font_scale=1.0`, flutter run y harness terminados, contenedores temporales
D3D y del harness eliminados. Se preservaron sin tocar
`saberplus-ov1b-suite-postgres`, `saberplus-ov1b-postgres-test` y `postgres-local`.
Backend quedó limpio. Esta edición no ejecutó ninguna limpieza adicional.

Queda registrada la validación Android y PostgreSQL local descrita, sin declarar
cierre global de OV-1D3, OV-1D ni OV-1 para producción. Siguen pendientes:

- iOS físico/entorno Apple real; no se infiere desde Android.
- Revisión editorial especializada del cuestionario, obligatoria antes de publicar.
- Piloto con usuarios, obligatorio antes de publicar.

Los índices expresan intereses declarados: no son probabilidad, aptitud ni
diagnóstico; no predicen éxito, no garantizan admisión y no sustituyen
orientación profesional. Sin staging, commit, push, merge/rebase ni deploy.
