# Ensayo académico local — 7 de octubre de 2026

Alcance autorizado después del recorrido de ranking: publicación editorial →
catálogo móvil → lectura/práctica → progreso. Es validación local, no cierre
productivo de D3/P5, no activación competitiva ni implementación de IC-1.
I2-5 conserva su acta y revisión final; no se repite su recorrido.


## Preparación y evidencia

- API aislada en 127.0.0.1:43187; 61 migraciones, cuentas ficticias del harness
  existente. Panel en 127.0.0.1:4173, modo API local, no demo en memoria.
- `tool/test_local_panel.mjs`: 2/2 aprobadas. Cliente HTTP real del panel:
  ADMIN publica tema/subtema/lección/pregunta, edición crea versión y archiva
  anterior, duplicado/revisión obsoleta rechazados, mapa y borrado seguro.
  No afirmar que estas escrituras se hicieron manualmente en navegador.
- `test/study_api_live_test.dart`: 1/1 aprobada con `zero@example.invalid`:
  catálogo de cinco áreas, progreso guardado/consultado al 100%, descarga de
  PDF de tema no vacío. No es certificado, no prueba visual de PDF ni cuenta
  del recorrido manual; student mantiene su progreso independiente.
- Catálogo real confirma Matemáticas → Ensayo (identificador aleatorio) →
  Sumas de ensayo: explicación «tres más tres es seis», una pregunta publicada.
  Segundo subtema Base orientativa de ensayo vacío, usado por el test del mapa.
- App debug de ensayo ya instalada, reverse USB restablecido. Sin recompilación.

## Resultados humanos confirmados

El propietario confirmó en Android que Sumas de ensayo muestra la explicación,
la respuesta 6 se califica como correcta y aparece «Explicación corregida de
ensayo», la versión publicada por el test editorial. Ese texto es un fixture,
no una explicación académica definitiva. También confirmó progreso al 100 %
al salir/volver al tema y tras cerrar sesión e iniciar nuevamente con student.
No hubo captura independiente; evidencia por observación del propietario.
El propietario también confirmó el indicador «por reforzar» tras responder
incorrectamente. Esto no valida por sí solo el diagnóstico completo de falencias.
El 8 de octubre, después de guardar manualmente una explicación desde el panel
e iniciar sesión en Android, el propietario confirmó que aparece el texto
actualizado y que el progreso se guarda al 100 %. Comprobación funcional por
observación del propietario, sin captura independiente. No se verificó en este
paso el historial de intentos ni la conservación de versiones de preguntas
respondidas; la edición realizada fue de la explicación de la lección.

## Reactivación — 8 de octubre de 2026

API y panel reactivados en los mismos puertos locales con una base temporal
nueva. Las 61 migraciones y las dos pruebas HTTP del panel completaron sin
errores; se recreó el contenido académico de ensayo. Los resultados humanos
anteriores conservan su valor, pero no implican que sus datos persistan en esta
nueva base desechable. Se completó la comprobación manual panel → Android:
explicación actualizada visible y progreso guardado al 100 %.

## Guion del recorrido (estado según resultados anteriores)

### Historial antes de editar la pregunta — 8 de octubre

El propietario confirmó que su respuesta aparece en el historial de Android.
Consulta de solo lectura en PostgreSQL local confirmó un intento incorrecto:
seleccionada 9, correcta 6, explicación «Explicación corregida de ensayo.»;
pregunta aún publicada. Esta es la referencia previa a la edición manual.
Después de recargar el registro y guardar manualmente, la consulta de solo
lectura confirmó una nueva pregunta publicada con «Versión nueva: 3 + 3 = 6
porque juntamos dos grupos de tres unidades.». La versión anterior quedó
archivada y el mismo intento conserva la explicación anterior, seleccionada 9,
correcta 6 y resultado incorrecto. No se reescribió ese historial en la base.
El propietario confirmó después que la app muestra la explicación actualizada.
La consulta posterior de solo lectura encontró dos intentos distintos: el nuevo
apunta a la versión publicada y su explicación nueva; el anterior sigue apuntando
a la versión archivada y conserva «Explicación corregida de ensayo.». Ambos
mantienen seleccionada 9, correcta 6 y resultado incorrecto. Queda validado este
caso de edición manual → práctica nueva sin reescritura del intento anterior,
con observación del propietario en Android y comprobación en PostgreSQL local.

El primer guardado manual devolvió EDITOR_STALE. La consulta posterior confirmó
que la explicación publicada sigue siendo la anterior: no se creó otra versión.
El servicio calcula la revisión sobre el registro completo, incluidos los
contadores de uso; responder después de abrir el editor puede invalidar esa
revisión sin una edición académica. Es una causa compatible con la secuencia,
no confirmada con el token del navegador. Tras conservar el texto y recargar
el registro, el siguiente guardado sí creó la nueva versión. La mejora de la
revisión editorial ante cambios de contadores sigue pendiente de evaluación;
no se cambió ese mecanismo durante el recorrido.

1. Student: login nuevo; catálogo Matemáticas, tema Ensayo, Sumas de ensayo.
2. Leer explicación y comprobar representación y ausencia de contenido ajeno.
3. Abrir pregunta, responder 3 + 3 = 6; verificar resultado/explicación y área.
4. Guardar progreso según controles de la app; salir/volver y volver a iniciar
   sesión, comprobar persistencia. No usar progreso de zero como prueba manual.
5. Comprobar un error y su clasificación temática sin asumir que una única
   respuesta demuestra una falencia estable. Preparar caso si no se puede repetir.
6. Ensayar guardado/edición manual desde navegador y actualización móvil,
   preservando versiones ya respondidas. No reescribir historial para simplificar.

Registrar resultados y defectos antes de ampliar a diagnóstico, simulacros,
certificados o repasos. No hay banco suficiente para diagnóstico de 15 preguntas:
no ejecutar esa prueba como si el único subtema fuera un curso completo.

## Entorno temporal y cierre

Resultado del caso académico acotado: publicación y actualización de lección,
práctica correcta/incorrecta, progreso al 100 % y versionado de pregunta con
historial conservado comprobados según la evidencia anterior. No equivale a
validar todas las áreas, diagnósticos, simulacros, certificados, repasos ni
producción. El ajuste de revisiones que incluyen contadores sigue como hallazgo.
La limpieza de esta sesión se registra al detenerla; no se da por realizada aquí.

El supervisor tiene límite de dos horas; credenciales solo en su archivo privado,
nunca en Git ni dentro del APK. Nueva sesión implica nuevo login. Al cerrar,
detener panel/API propios y retirar reverse USB. No borrar datos del usuario ni
recursos globales; registrar limpieza. El contenido ficticio no llega a producción.
