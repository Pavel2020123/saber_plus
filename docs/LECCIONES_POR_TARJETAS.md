# Lecciones por tarjetas — 27 de octubre de 2026

Decisión de Pavel para la presentación: reducir el desplazamiento de la lección
y mostrar una lectura guiada, sin modificar contenido, calificación ni reglas
de publicación del panel.

## Comportamiento

- El Markdown que ya genera el panel se divide por encabezados en tarjetas.
  Los encabezados dentro de código cercado no crean tarjetas. Texto sin títulos
  sigue disponible como una sola tarjeta. No se reescribe la base de datos.
- Cada tarjeta muestra título y texto. Los prefijos editoriales `Ejemplo:`,
  `Consejo:`, `Resumen:` y `Lectura:` no se muestran al estudiante.
- Flechas anterior/siguiente y gesto horizontal, con transición lateral y
  desvanecimiento. El indicador `1 / N` aparece dentro de la tarjeta con cifras
  tabulares; la etiqueta completa se conserva para lectores de pantalla.
  El texto largo conserva
  desplazamiento normal; no se recorta para imponer una altura fija.
- Al llegar a la última tarjeta se muestran los recursos adicionales, el
  ejercicio de completar espacios si existe y las acciones originales de
  completar lección y practicar. Navegar no marca la lección como completada.
- Bienvenida con Sabi y X; cantidad de preguntas también ocultable. Se pueden
  cerrar sin un botón para repetir la bienvenida. Por petición posterior de
  Pavel, no se muestran “Mostrar ayuda” ni “Bases recomendadas” en la lección.
  El mapa conserva sus datos y lógica existentes, pero no se monta ni se
  consulta desde esta pantalla.
- El tema/subtema de la práctica se puede ocultar y restaurar. Esta preferencia
  dura la pantalla de práctica y no altera pregunta, cronómetro, reporte o envío.

## Persistencia y límites

La posición de lectura y los avisos cerrados se guardan en SharedPreferences,
con clave por cuenta y subtema. No se envían al servidor ni acreditan aprendizaje.
Un cambio del contenido reinicia la posición, conservando los avisos cerrados.
Un error de preferencias no impide leer. Al reinstalar o borrar los datos de
la app, estas preferencias locales se pierden; el contenido del servidor no.
No se garantiza sincronización de estas preferencias entre dispositivos.

## Verificación

Pruebas dedicadas: separación y preservación de Markdown, navegación reversible,
acciones solo al final, reapertura, aislamiento entre cuentas, cambio editorial,
ausencia de accesos para repetir bienvenida/mapa y contexto de práctica ocultable.
Comprobar también ancho de 320 px con fuente 200% y temas claro/oscuro.
Los resultados ejecutados y la comprobación humana se informan por separado;
este documento no acredita una revisión Android que aún no se haya realizado.

Verificación ejecutada el 27/oct: `flutter analyze --no-pub` sin problemas;
40/40 pruebas en `lesson_card_reader_test.dart`, `learning_map_test.dart`,
`practice_session_page_test.dart` y `study_evolution_test.dart`. Incluyen 9
pruebas dedicadas al cambio. Revisión visual humana del APK pendiente.

## Pomodoro recogible y gestos — ajuste posterior del 27/oct

Al iniciar o continuar el Pomodoro se recoge el panel hacia la izquierda y
permanece el reloj. Tocarlo abre/cierra controles sin pausar ni reiniciar.
Para pausar o reiniciar se abre el panel y se utiliza su control explícito.
El aro y el marcador representan el tiempo realmente consumido de los 25
minutos; no son un giro decorativo ni un indicador de carga indeterminado.
La finalización abre el panel. Los cambios de cuenta mantienen el reinicio del
controlador existente. No se cambia duración, registro de tiempo ni backend.

El panel y las tarjetas respetan reducir movimiento. Para esa preferencia se
omite el contenedor de tamaño animado del Pomodoro, evitando un fallo de layout
detectado por pruebas. Se conservan botones accesibles además del gesto táctil.
El deslizamiento horizontal no reemplaza el desplazamiento vertical de textos
largos ni marca la lección completada. Las flechas siguen disponibles.

Refinamiento visual posterior: transición de tarjetas de 420 ms con entrada
retardada y salida suavizada. El Pomodoro usa un único reloj anclado arriba a
la izquierda, fuera de los paneles animados, evitando duplicación y centrado
durante la apertura. Apertura/cierre de 420 ms con curva suave. Pruebas comprueban
que la posición del reloj no cambia durante ni después de recogerlo. En esta
revisión, 13/13 pruebas dirigidas aprobadas y análisis MCP sin errores.

Validación final de este ajuste: 50/50 pruebas en lector, Pomodoro/controlador/sync,
mapa y práctica; además 1/1 recorrido de widgets lección/práctica aprobado.
Análisis MCP sin errores. Se verificó que la ausencia del almacenamiento nativo
no bloquea la navegación. La revisión visual humana Android se acredita aparte.
