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
