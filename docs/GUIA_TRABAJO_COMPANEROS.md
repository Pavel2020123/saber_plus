# SaberPlus — guía de trabajo para compañeros

Actualizado: 22 de septiembre de 2026. Leer antes de modificar código.

## 1. Acuerdo del equipo

El propietario continúa con la lógica/backend de los juegos y coordina la integración.
Los compañeros pueden **revisar el diseño de certificados y reparar audios** en
ramas distintas.
El contenido académico lo cargarán después el propietario y un compañero desde el
panel ADMIN. Las pruebas en celulares se harán entre los tres.

No trabajar ni subir cambios directamente en `main`. Cada entrega se revisa en un
Pull Request (PR) y **el propietario decide cuándo incorporarla**. No desplegar,
aplicar migraciones ni usar credenciales de producción por cuenta propia.

Esta guía distingue trabajo local integrado de pruebas y despliegues pendientes.
P5/D3 siguen pausadas; los juegos nuevos avanzan primero en funcionalidad.
Las animaciones de Sabi quedan al final; esta asignación no reabre ese trabajo.

## 2. Repositorios y lectura inicial

- Flutter: <https://github.com/Pavel2020123/saber_plus>.
- Backend oficial y panel: <https://github.com/Pavel2020123/SaberPlus-Backend>.
  El servidor actual es NestJS/Prisma; el panel está en `admin/` y la API en `backend/`.
- `Icfes_Vida` es una referencia histórica, **no el repositorio donde entregar
  cambios nuevos de SaberPlus**. No modificarlo para estas tareas.

El propietario debe publicar primero esta guía y los commits que quiera compartir.
Si un repositorio es privado, debe dar acceso a las cuentas GitHub de los compañeros;
no compartir contraseñas, tokens ni archivos `.env`.

Leer en Flutter: `README.md`, esta guía, `docs/ETAPAS_PENDIENTES.md`,
`docs/GAMIFICATION_CONTRACT.md`, `docs/RESCATE_DE_ESTRELLAS.md` y
`docs/SABI_Y_JUEGOS_APROBADOS.md`. Verificar si existe `AGENTS.md` y seguirlo.

### Primera descarga y rama propia

Abrir una terminal en una carpeta de trabajo elegida por cada compañero:

```powershell
git clone https://github.com/Pavel2020123/saber_plus.git
cd saber_plus
git switch -c feat/audios-juegos
flutter pub get
flutter analyze
flutter run
```

Usar la cuenta de demostración para pruebas locales. No solicitar acceso real solo
para probar efectos. Si ya se tiene un clon, no volver a clonarlo encima:

```powershell
git status --short
# Continuar solamente si no hay cambios propios sin guardar.
git switch main
git pull --ff-only origin main
git switch -c feat/audios-juegos
```

Para certificados usar `feat/certificados-curso`. Para trabajar en el servidor,
clonar `SaberPlus-Backend.git` por separado y crear esa rama también allí.
Las ramas y los commits de ambos repositorios son independientes: mencionar los
dos PR si una entrega cambia API y Flutter. Cada PC puede usar rutas diferentes.

## 3. Certificados: solo seis tipos

**Nueva decisión del propietario:** cinco certificados por área y uno final por
terminar las cinco. No crear un PDF por cada logro, racha, juego o subtema.
Los logros pueden seguir existiendo como insignias, sin emitir certificados.

| Certificado | Área interna | Cuándo se habilita |
| --- | --- | --- |
| Lectura crítica | `LECTURA_CRITICA` | Área completada, confirmada por servidor |
| Matemáticas | `MATEMATICAS` | Área completada, confirmada por servidor |
| Ciencias naturales | `CIENCIAS_NATURALES` | Área completada, confirmada por servidor |
| Sociales y ciudadanas | `SOCIALES_CIUDADANAS` | Área completada, confirmada por servidor |
| Inglés | `INGLES` | Área completada, confirmada por servidor |
| Curso completo de SaberPlus | Las cinco anteriores | Las cinco áreas completadas |

“Ciencias ciudadanas” se corresponde con **Sociales y ciudadanas** en el catálogo.
Son seis tipos, no seis PDFs de por vida: se puede volver a descargar uno obtenido.

### Implementación local del 22 de septiembre

El propietario integró una plantilla HTML única con el logo S+ y la imagen de Sabi
celebrando. El backend convierte esa plantilla en PDF A4 horizontal y consulta
`Usuario.nombre` de la sesión autenticada. El catálogo contiene exactamente los
seis tipos de la tabla. La app muestra su avance y permite descargarlos.

Regla acordada: se completan **todas las lecciones (subtemas) publicadas del área**.
Un área sin lecciones publicadas permanece bloqueada. El curso se habilita cuando
las cinco áreas están completas. Borradores, contenido archivado y preguntas
sueltas no cuentan. `ProgresoTema.completado` y `porcentaje >= 100` son la evidencia
del servidor. El progreso de lectura se marca por la ruta académica existente.

La disponibilidad se recalcula con el catálogo actual. Si se publica una lección
nueva, hay que completarla para volver a emitir el certificado. El PDF privado
ya descargado no se borra. Al reemitir, se usa el nombre actualizado del perfil.
Los logros siguen como insignias; la ruta antigua de PDF por logro responde 410.

Ubicaciones:

- Backend: `backend/src/gamificacion/templates/certificado.html`,
  `certificado-html.service.ts` y `certificados-curso.service.ts`.
- API protegida: `GET /gamificacion/certificados` y
  `GET /gamificacion/certificados/:tipo/pdf`.
- App: `lib/features/gamification/presentation/course_certificates_section.dart`.
- Vista previa local con datos inventados:
  `cd backend; npm run build; node tool/preview_course_certificate.cjs`.
  Las muestras en `backend/output/pdf/` llevan marca de demostración y no se suben.

Los compañeros pueden **revisar el diseño, accesibilidad y textos**, y probar
los seis tipos con cuentas de ensayo después del despliegue. Hacer cambios solo
en rama propia y PR. No emitir certificados manualmente ni modificar reglas de
desbloqueo sin acordarlo con el propietario. Queda pendiente la prueba integrada
con base real y el navegador del servicio de Render.


## 4. Audios: reparar los existentes antes de añadir más

**Reporte del propietario:** en su celular solo funciona Tira y afloja; no escucha
los demás juegos. Debe investigarse y corregirse. Que exista una llamada en el código
o pase un test simulado NO demuestra que el dispositivo reproduzca audio.
No se ha confirmado todavía una causa única ni realizado una escucha en este equipo.

### Inventario actual

Los siguientes 13 archivos existen en `assets/audio/` y están declarados individualmente
en `pubspec.yaml`. La tabla indica intención/conexiones de código, no audio verificado.

| Archivo | Uso que deben probar |
| --- | --- |
| `answer_streak_success.mp3` | Racha de respuestas correctas en práctica; no confundir con racha de días |
| `trivia_correct.mp3` | Acierto confirmado en Trivia Rush/Duelo fantasma; reutilizado por Guardián |
| `trivia_wrong.mp3` | Error/tiempo agotado en Trivia Rush; reutilizado por Guardián |
| `trivia_countdown.mp3` | Aviso de cuenta regresiva de Trivia Rush |
| `trivia_finish.mp3` | Fin de Trivia Rush; también final neutral en otros flujos |
| `memory_flip.mp3` | Voltear una tarjeta en Memoria |
| `memory_match.mp3` | Encontrar una pareja en Memoria |
| `match_found.mp3` | Emparejamiento/inicio en Tira y afloja |
| `match_countdown.mp3` | Definido en `GameSound`, pero no se encontraron llamadas a `GameSound.matchCountdown` en `lib/`; verificar y conectar solo si hay un evento adecuado |
| `match_victory.mp3` | Victoria en Tira y afloja, Memoria, récord de Fantasma y Guardián |
| `match_defeat.mp3` | Derrota en Tira y afloja/Guardián y récord no superado de Fantasma |
| `tug_pull.mp3` | Tirón de cuerda; preservar el funcionamiento reportado |
| `tug_rope_strain.mp3` | Tensión de cuerda; preservar el funcionamiento reportado |

### Archivos de entrada

- `lib/core/feedback/game_audio_feedback.dart`: enum, servicio y reproductores.
- `lib/core/feedback/answer_streak_feedback.dart`: efecto de racha de aciertos.
- `lib/core/preferences/`: preferencias independientes de sonido de juegos y racha.
- `lib/features/games/trivia_rush/presentation/trivia_rush_page.dart`:
  incluye eventos usados por Duelo fantasma.
- `lib/features/games/memory_match/presentation/memory_match_page.dart`.
- `lib/features/games/guardian/presentation/guardian_page.dart`.
- `lib/features/games/tug_of_war/presentation/`: demo y flujo en línea.
- `lib/features/practice/presentation/practice_session_page.dart`: racha de aciertos.
- `test/game_audio_feedback_test.dart`, `test/answer_streak_feedback_test.dart`.

### A1 — Diagnóstico y reparación

1. Reproducir cada evento en un teléfono y registrar dispositivo, sistema, modo
   demo/real, preferencia de sonido, resultado esperado/observado y pasos exactos.
2. Probar primero el archivo aislado y luego el evento dentro del juego. Se puede
   crear una pantalla de prueba **solo debug**, sin habilitar botones de prueba en release.
3. Comprobar volumen multimedia, preferencias, ruta/nombre del asset, empaquetado
   y formato. Un archivo agregado requiere reconstruir la app, no solo hot reload.
   `AssetSource` usa `audio/archivo.mp3`, porque el archivo está bajo `assets/`.
4. Revisar cuándo se llama `play`, modo de reproducción, ciclo de vida del reproductor,
   pausa/reanudación y efectos que se interrumpen por usar el mismo reproductor.
   El servicio actual comparte `primaryPlayer` para los efectos salvo los de cuerda;
   comprobarlo como hipótesis, no asumir que ya es la causa.
5. El servicio captura errores para no interrumpir partidas. Añadir diagnósticos de
   desarrollo seguros si hacen falta: no eliminar esa protección ni registrar tokens,
   nombres o respuestas personales. No afirmar “funciona” solo porque no se ve un error.
6. Corregir y repetir pruebas con sonido activado y desactivado; no forzar volumen,
   ignorar preferencias ni modificar reglas, puntuación, tiempos o recompensas.

Un resultado confirmado debe producir como máximo su efecto correspondiente.
No disparar sonidos desde `build()`, en cada fotograma, tras cada reconstrucción o
de nuevo al recuperar/reintentar un resultado ya procesado. En el último acierto,
evitar que dos efectos compitan: dar prioridad a la celebración final o secuenciarlos.
No crear un reproductor por pregunta ni dejar bucles sonando al salir del juego.

### A2 — Propuestas para juegos nuevos

Son **nombres/efectos propuestos**, no archivos existentes ni descargas ya hechas.
Reutilizar efectos actuales si encajan; añadir sonidos cortos, de volumen consistente,
sin voces obligatorias, sobresaltos ni música permanente por defecto.

| Juego | Archivos propuestos y evento |
| --- | --- |
| Salto a la cima | `summit_step_up.mp3`: subir; `summit_step_down.mp3`: bajar; `summit_victory.mp3`: alcanzar la cima. En error en la base, no simular una caída inexistente. |
| Rescate de estrellas | `star_release.mp3`: liberar una estrella; `constellation_complete.mp3`: completar grupo; `star_rescue_finish.mp3`: cierre. Un error no reproduce pérdida de estrella. |
| Taller de inventos | `invention_piece.mp3`: colocar pieza confirmada; `invention_complete.mp3`: terminar el invento. Preparar assets; conectar cuando exista el juego. |
| Escudo del conocimiento | `shield_repair.mp3`: recuperar escudo; `shield_hit.mp3`: impacto confirmado; `shield_round_complete.mp3`: terminar ronda. Conectar cuando existan reglas/eventos. |
| Fantasma, opcional | `ghost_capture.mp3` / `ghost_escape.mp3`: resultado final, no por cada movimiento. Coordinar con arte posterior. |
| Guardián, opcional | `guardian_hit.mp3` / `guardian_defeated.mp3`: daño y victoria confirmados. No inventar disparos ni cambiar mecánicas para justificar un audio. |

Comenzar por **A1**. En A2 coordinar cada archivo compartido: el propietario está
modificando los juegos nuevos. No programar Inventos/Escudo dentro de la tarea de sonido.
Actualizar enum, referencias, `pubspec.yaml` y pruebas al agregar un asset;
conservar origen y evidencia en `docs/licenses/AUDIO_LICENSES.md`, hoy pendiente.
La afirmación de que los audios son libres de regalías no sustituye ese registro.

**Criterios de entrega:** matriz de eventos/dispositivos con escuchas reales,
preferencias respetadas, sin repetición por reconstrucción/reintento, sin regresión
de cuerda, sin alterar partidas; pruebas automatizadas del servicio/eventos y registro
de archivos añadidos/reemplazados. No sustituir archivos silenciosamente ni subir
duplicados de gran tamaño sin necesidad.

## 5. Contenido y panel ADMIN: tarea posterior compartida

El propietario y un compañero cargarán contenido desde el panel, no editando listas
de preguntas dentro de Flutter. El flujo esperado es:

**5 áreas → crear tema → crear subtema → lección/preguntas → revisión → publicación.**

Verificar selección del área, clasificación de cada pregunta, opciones/correcta,
explicación, imágenes, duplicados y recuperación tras guardar. Solo contenido
publicado debe aparecer en actividades nuevas de la app una vez conectada la API.

Referencias: `docs/ADMIN_PANEL.md`, `SaberPlus-Backend/admin/` y
`backend/src/admin/academic-catalog.service.ts` / `editorial-review.service.ts`.
Ya hay catálogo, creación editorial y trabajo de borradores. **La conexión real D3
y sus pruebas no se dan por terminadas** por ver un formulario local funcionando.

Sobre equivocarse y eliminar: la implementación actual permite borrar ciertos
**borradores vacíos, nunca publicados ni utilizados**. No es eliminación irrestricta
de temas/subtemas con hijos o historial. Si hay contenido o uso, evaluar corrección,
reclasificación permitida, archivo o versionado; no quitar protecciones ni hacer
borrado en cascada para “arreglarlo”. Mover entre áreas no se presume implementado.
Probar explícitamente esos casos entre los tres antes de cargar miles de preguntas.

## 6. Reglas para no pisarse cambios

| Responsable | Alcance principal | Coordinar antes de tocar |
| --- | --- | --- |
| Compañero de certificados | Revisar plantilla ya integrada, accesibilidad y pruebas en celulares; proponer mejoras en PR | Gamificación, perfil y política de finalización |
| Compañero de audios | Servicio de sonido, eventos, assets, licencias y pruebas | `pubspec.yaml`, preferencias y pantallas de juegos en desarrollo |
| Propietario | Lógica/backend de juegos y revisión/integración | Cambios compartidos de ambos compañeros |
| Los tres | Pruebas de celular e incidencias | Publicación, cuentas reales y datos de ensayo |

No modificar autenticación, pagos, rachas, XP, datos académicos ni despliegues como
“arreglo adicional” de certificados/audio. Si hace falta, documentar y acordar una
tarea separada. No hacer cambios masivos de formato ni actualizar dependencias sin motivo.

### Guardar y entregar una rama

```powershell
git status --short
git diff
# Añadir únicamente los archivos de la tarea (ejemplo de audio):
git add lib/core/feedback/game_audio_feedback.dart test/game_audio_feedback_test.dart
# Añadir por su ruta los demás archivos que realmente se modificaron.
git diff --cached
git commit -m "fix: corregir reproduccion de audios de juegos"
git push -u origin feat/audios-juegos
```

Para certificados: mensaje sugerido `feat: crear plantilla de certificados por area y curso`
y subir la rama `feat/certificados-curso`. No usar `git add .` sin revisar, `push --force`,
`reset --hard`, ni subir `.env`, contraseñas, compilaciones o bases de datos.

En GitHub abrir un **Pull Request hacia `main`**, asignarlo al propietario y NO
fusionarlo ustedes. Incluir objetivo, archivos tocados, comandos/resultados de pruebas,
capturas/PDF de muestra o video de sonido, limitaciones y posibles cambios de contrato.
Si hay conflicto en archivos compartidos, avisar; no aceptar todo “ours/theirs” a ciegas.

Comprobaciones Flutter mínimas, más las pruebas de cada juego modificado:

```powershell
flutter analyze
flutter test test/game_audio_feedback_test.dart test/answer_streak_feedback_test.dart test/remote_gamification_repository_test.dart
```

Para un cambio de servidor: desde `SaberPlus-Backend/backend`, compilar con
`npm run build` y ejecutar las pruebas pertinentes. No ejecutar migraciones reales
ni scripts que lean credenciales de staging/producción para probar una plantilla.
El propietario revisa los PR, coordina compatibilidad y realiza la integración.

## 7. Pruebas conjuntas y entrega final

- En cada teléfono registrar versión de app, modelo y Android/iOS.
- Certificados: nombre corto/largo, tildes, seis estados, descarga y separación de cuentas.
- Audio: cada evento, preferencias apagadas, segundo plano/regreso, salir de partida,
  repeticiones rápidas y reconexión. Probar con/sin auriculares si hay diferencias.
- Juegos: no cambiar resultado ni avanzar dos veces por el sonido.
- Panel: crear/revisar/publicar, corregir errores de clasificación y borrado protegido.
- Enviar incidencias con pasos y resultado observado; no marcar algo “listo” sin probarlo.

Una entrega puede estar lista localmente y seguir pendiente de dispositivo, servidor
o despliegue. Indicarlo expresamente; no prometer que todo funciona por compilar.
