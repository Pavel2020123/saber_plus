# Actividades tipo cuadernillo — Inglés

## Alcance

Cinco formatos de familiarización: asociación de vocabulario, avisos, conversaciones,
textos con espacios y comprensión lectora. Mantienen instrucciones, ejemplo resuelto,
numeración y orden de opciones. No constituyen una reproducción certificada del examen.
La distribución responde al ancho disponible: asociación en dos columnas cuando cabe,
o banco seguido de descripciones cuando la pantalla o la letra grande lo requieren.

Las preguntas convencionales, el CLOZE anterior y las lecciones permanecen separados.
El diagnóstico inicial ahora puede seleccionar ítems de actividades publicadas de
Inglés, conservando su formato. La entrega desde la lección sigue siendo práctica:
no modifica el resultado diagnóstico, simulacros, juegos, ranking ni certificados.

### Integración con diagnóstico inicial

Se mantienen 15 preguntas, tres por área. Para Inglés se priorizan ítems de distintos
subtemas publicados; si faltan ítems se completa con el banco convencional disponible.
No hay que duplicar manualmente el contenido del panel. Solo se usan actividades
y padres publicados. Las sesiones ya iniciadas o completadas no se reinician.

La migración aditiva `20261029010000_diagnostic_booklet` incorpora `Pregunta.cuadernillo`.
El servidor crea proyecciones internas inmutables por actividad, versión e ítem al
seleccionarlos. Permanecen en BORRADOR y fuera del editor convencional y sus selectores
publicados; el diagnóstico las admite explícitamente desde la fuente publicada.
Así cada respuesta conserva su relación con Pregunta/Subtema e HistorialRespuesta,
sin publicar copias independientes para otros modos de juego. Las claves correctas
solo quedan en Respuesta; el JSON público conserva instrucciones, ejemplo, imágenes,
opciones y un ítem evaluable. Los otros huecos de un texto se muestran sin interacción.

Flutter usa BookletExercise dentro del diagnóstico y guarda la selección con el
mismo borrador y envío del resto de preguntas. La calificación es del servidor.
Si la fuente cambia de versión o se despublica durante un intento, se rechaza su
reanudación/entrega con un mensaje; no se cambia la clave ni se reinicia al estudiante.
El historial diagnóstico cuenta como evidencia por subtema mientras la versión fuente
esté publicada; se mantienen los mínimos de evidencia, sin declarar una falencia con
una sola respuesta. Una entrega de práctica en la lección no crea esa evidencia.

Validación local: prueba HTTP opt-in `backend/tool/test_diagnostic_booklet_local.mjs
--run-local` en el worktree `ov1-backend-audit`, con cuenta temporal propia, sin borrar
diagnósticos reales. El cambio requiere backend migrado y app actualizada; no implica
despliegue ni migración remotos.

## Crear contenido

1. En el panel real, seleccionar Inglés, tema y subtema.
2. Abrir **Actividades tipo cuadernillo** y **Nueva actividad**.
3. Elegir formato; completar título, instrucciones y fuente/permiso.
4. El ejemplo resuelto tiene campos propios: no incluir su respuesta en el banco elegible.
5. Asociación: una palabra por línea, en orden A–G; agregar todas las descripciones.
   El banco no se recorta a seis ni se baraja. Cada ítem tiene número original,
   descripción, letra correcta y explicación.
6. Otros formatos: cada ítem tiene sus propias opciones, una por línea. Conservar tres
   o cuatro según el original; no inventar una cuarta opción. En avisos se escribe el
   mensaje en la descripción; en conversaciones, la intervención correspondiente.
7. Lectura: colocar el texto común completo y después sus preguntas.
8. Huecos: colocar en el texto marcadores `{{95}}`, `{{96}}`, etc. Cada número debe
   aparecer exactamente una vez y tener un ítem con sus opciones y explicación.
9. Publicar y guardar. Los padres deben estar publicados: guardar primero su lección.

La fuente del material y sus derechos deben comprobarse por separado. No se cargan
automáticamente las capturas o textos de los cuadernillos. El editor permite imágenes
del contexto, de cada ítem y de cada opción, con los mismos metadatos y permisos del
cargador editorial. Las preguntas convencionales conservan sus imágenes.

### Fotos y contenido que se repite

Seleccionar archivo → completar autoría/permiso → Subir y usar imagen → Guardar actividad.
No guardar mientras haya selecciones o cargas pendientes. Las fotos tienen vista previa
y se pueden ampliar en Flutter sin seleccionar una respuesta.

La foto o lectura común va una sola vez arriba de la actividad, y sus preguntas debajo.
En asociación, el banco de palabras y sus fotos también se comparten entre todos los ítems.
Para reutilizar una imagen entre actividades, copiar la referencia visible debajo del
selector y pegarla en el enlace del nuevo contexto: no hace falta subir el archivo otra vez.

Para opciones independientes, escribir primero sus textos, uno por línea, y pulsar
**Actualizar fotos de opciones A, B, C…**. Al cambiar textos u orden con fotos asociadas,
se exige confirmar la conservación por posición y revisar el resultado; no se reasignan
silenciosamente. Las cargas pendientes deben resolverse antes de reconfigurar opciones.

El servidor detecta actividades equivalentes dentro del mismo subtema, ignorando cambios
de título, fuente y números. No es detección semántica de todos los ejercicios de un PDF.
Un contexto igual con preguntas diferentes sigue siendo válido; practicar otra vez una
actividad guardada no crea una copia nueva.

La migración aditiva `20261028150000_booklet_images` añade la relación con los archivos.
El alumno solo accede por una actividad y padres publicados. No se retira un archivo
mientras siga vinculado. Los recursos de pruebas se retiraron y no se borró contenido del usuario.

## Usar en Flutter

Estudiar → Inglés → tema → lección → última tarjeta de lectura → **Actividad tipo cuadernillo**.
Se selecciona una respuesta por ítem y se entrega la actividad completa. El servidor
devuelve aciertos, respuesta correcta y explicación después de entregar.

El borrador se conserva localmente por usuario, actividad y versión. Una modificación
editorial no reutiliza silenciosamente el borrador de otra versión. Se requiere conexión
para cargar y corregir; no es un modo completamente offline ni sincronización entre celulares.

## Persistencia y seguridad

El backend utiliza la tabla independiente `ActividadCuadernillo` (relación restrictiva
con Subtema). La migración es aditiva: no convierte ni elimina preguntas existentes.
El editor exige ADMIN y bandera de publicación; el alumno requiere sesión válida.
Los GET del alumno omiten claves y explicaciones. La corrección valida opciones,
actividad publicada, padres publicados y versión vigente. No otorga XP.

Rutas: `GET/PUT /admin/cuadernillo`, `GET /cuadernillo`,
`POST /cuadernillo/:id/corregir`. Las listas usan `subtemaId`.
El servidor no conserva intentos o calificaciones de estas actividades; conserva el contenido.

## Entorno y entrega local

API/panel activos se ejecutan desde el worktree `Desktop/ov1-backend-audit`, no desde
el checkout `Desktop/SaberPlus-Backend`. Los cambios de backend están en ese worktree;
no se consideran integrados a main ni desplegados. Flutter está en `Desktop/SaberPLus/saber_plus`.
No publicar en Render/Supabase ni aplicar esta migración a otra base sin revisión.

Se respaldó PostgreSQL y los archivos editoriales locales antes de aplicar la migración
al Docker de presentación. La prueba HTTP usa registros propios temporales y los retira
al finalizar, sin borrar contenido editorial existente.

## Verificación reproducible

Flutter: `flutter test test/booklet_activity_test.dart test/booklet_exercise_test.dart`.
Vista local: `flutter test tool/booklet_visual_test.dart --update-goldens` (Windows,
fuente Segoe UI instalada; genera `.tmp/booklet-matching-reference.png`).
Previews: `lib/features/practice/presentation/booklet_previews.dart`.

Backend: `npx jest --runInBand --runTestsByPath src/booklet/booklet-content.spec.ts`.
Integración local: `node tool/test_booklet_local.mjs --run-local` desde backend del
worktree de presentación, con API y Docker activos. Usa exclusivamente localhost y
los accesos locales ignorados por Git. No ejecutar contra servicios externos.
Panel: `npm test` y `npm run check` desde admin.

La revisión humana de fidelidad y legibilidad en el celular sigue siendo necesaria.

## Resultado de esta entrega local

- Flutter: 66 pruebas dirigidas y de navegación aprobadas; incluye los cinco formatos
  a 320, 390 y 800 px y texto ampliado. Análisis global sin incidencias.
- Backend: 72 pruebas de contrato/editor/lecciones aprobadas, compilación TypeScript
  y lint del módulo sin errores.
- Panel: 138 pruebas aprobadas y sintaxis de 29 módulos correcta.
- Prueba HTTP con PostgreSQL local: cinco formatos, permisos, claves ocultas,
  corrección, publicación/retiro, conflictos, booleanos estrictos e IDs inválidos.
  Los fixtures se eliminaron por sus IDs; el banco editorial se conservó.
- Referencia visual de asociación generada y revisada; no equivale a validación
  humana de todos los ejercicios reales en un dispositivo.
- APK debug local compilado e instalado sin desinstalar ni borrar datos; recarga
  de Flutter comprobada. No es una entrega de tienda ni un despliegue remoto.
