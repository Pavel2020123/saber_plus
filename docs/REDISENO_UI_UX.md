# SaberPlus — Rediseño UI/UX por pantallas

Estado: 27 de octubre de 2026. Prioridad: presentación al cliente.

## Acuerdo de trabajo

Revisar una pantalla o flujo a la vez: estado actual, propuesta visual,
aprobación de Pavel, implementación limitada y verificación. Conservar rutas,
reglas académicas, roles, datos, backend, mascotas e insignias. Una propuesta
visual no autoriza nuevas funcionalidades ni cambios de reglas de negocio.
OV-1 continúa separado, a cargo del compañero.

## Orden de trabajo

| Orden | Pantallas o flujo | Criterio principal |
| --- | --- | --- |
| 1 | Inicio del estudiante | Compacto, actividad principal clara, Sabi y calendario inferior. |
| 2 | Estudiar: áreas, temas y subtemas | Encontrar el contenido sin confundir niveles ni saturar listas. |
| 3 | Lección | Explicación, ejemplos, imágenes y acceso claro a práctica. |
| 4 | Preguntas, respuestas y resultado | Legibilidad, selección, retroalimentación y explicación de solución. |
| 5 | Juegos incluidos en la presentación | Catálogo coherente, configuración y estados de la partida existente. |
| 6 | Perfil y progreso del estudiante | Progreso académico y gamificación legibles, sin inventar logros o insignias. |
| 7 | Profesor e instituciones | Directorio, perfil institucional, grupos y seguimiento existente. |

Este orden organiza la revisión visual, no reemplaza ni cierra etapas técnicas.
Si una función falta o falla, documentarla y pedir decisión antes de ampliarla.

## Inicio: propuestas para aprobación

Archivo editable:
https://www.figma.com/design/Y7F814i48P609j5ZIjYtf0

- A compacta: tarjeta azul oscura y Sabi de acompañamiento.
- B juvenil: tarjeta azul clara, botón azul y Sabi con mayor protagonismo.
- Ambas mantienen cinco pestañas, Lucide aprobados, XP, plan semanal,
  diagnóstico y calendario inferior. El avance semanal se presenta una sola vez.
- Datos ficticios consistentes con la demo existente: Santiago, 1.240 XP,
  refuerzo de matemáticas, Regla de tres, 3 de 5 sesiones y 200 minutos.
- La fecha/hora del sistema dibujada en Figma es ilustrativa, no una fecha ICFES.
- Las pantallas son propuestas estáticas de 390 × 844; no son funcionalidades
  ya implementadas, capturas del celular ni prueba de responsividad.
- Pavel eligió B (juvenil). Solicitó reemplazar la mascota por el asset existente
  `assets/images/Sabi_Inicio_Refuerzo.png`; se actualizó únicamente la propuesta B
  en Figma, manteniendo proporción y sin editar el archivo original.
- La implementación de B en Flutter se realizó el 27 de octubre (detalle abajo).
  No confundir código implementado con una APK ya instalada.

Validación de Figma: cada pantalla contiene 108 descendientes, incluyendo
27 textos y 5 instancias de componentes; no se colocó una captura completa
como fondo. Sabi es el asset original y el resto de la UI es editable.
Tipografía Roboto verificada; Lucide importados del paquete instalado.
Se corrigió el grosor de importación a aproximadamente 2 px a tamaño 24 px.
Se inspeccionó la composición final sin recortes visibles en esta dimensión.

## Herramientas preparadas

- Plugin oficial `dart-flutter@dart-flutter`, versión 1.0.7: instalado y habilitado.
- MCP `saberplus-dart`: configurado con el ejecutable explícito
  `C:\flutter_sdk\bin\cache\dart-sdk\bin\dart.exe` y argumento `mcp-server`.
- El MCP incluido en el plugin que depende del PATH queda deshabilitado para
  evitar usar el SDK alternativo de Documents. Las skills oficiales permanecen
  habilitadas.
- Instalación/configuración verificada por CLI. El nuevo MCP todavía no aparece
  entre las herramientas invocables del chat actual; falta comprobar conexión
  en una sesión que recargue la configuración. No afirmar inspección en vivo.
- Figma: conexión autenticada y archivo creado; no se cambió el plan ni el asiento.
- `flutter-improve-design`: no instalada; pendiente resolver licencia/revisión
  de la fuente antes de incorporarla. No se ejecutó su auditoría completa.
- `flutter-custom-design-system`: no instalada; migración completa pospuesta.

## Proceso por pantalla después de elegir el diseño

1. Preparar la implementación solo de la pantalla y su integración visual con shell
   y calendario, conservando callbacks y estados actuales.
2. Comparar antes/después con los mismos datos y fuentes reales de la app.
3. Revisar 320, 360, 390 y 430 px, orientación horizontal y tablet; texto al
   100 %, 150 % y 200 %; modos claro y oscuro.
4. Revisar carga, error, nombre largo, diagnóstico pendiente y lección para
   continuar. Conservar el comportamiento del calendario compacto, desplegado
   y lateral con doble toque de restauración.
5. Ejecutar análisis y pruebas de accesibilidad, navegación y widgets pertinentes.
6. Instalar y revisar en Android cuando Pavel disponga del celular.
7. Registrar evidencia y avanzar a la siguiente pantalla cuando Pavel la apruebe.

No se requiere Docker para elaborar las propuestas. Las pruebas de integración
de datos reales se planifican aparte. No se hizo commit, push ni despliegue.

## Implementación de Inicio B — 27 de octubre de 2026

Se trasladó el contexto de diseño Figma `2:30` a los widgets existentes:
cabecera compacta, XP junto a Preferencias cuando hay espacio, tarjeta azul
clara con el nuevo asset Sabi, CTA ancho y accesos con iconos Lucide. El progreso
semanal aparece una sola vez. En tamaños estrechos o con texto grande la
cabecera y las tarjetas se apilan sin reducir artificialmente el tamaño del texto.

Los tokens visuales se limitan a Inicio en `widgets/home_design.dart`; no se
retocó el tema global ni se migró la app a controles personalizados.
La imagen usa `BoxFit.contain`: no se edita, deforma ni recorta el PNG original.
Se conserva el detalle académico completo que llega del repositorio, aunque
ocupe una línea adicional frente al texto abreviado de la maqueta.

Se conservan también la lección para continuar, el resultado y prioridad del
diagnóstico, carga/error, actualización y rutas. La maqueta resumía el
diagnóstico como un enlace; la app mantiene los datos útiles que ya mostraba.
El calendario inferior y la navegación existente no cambian de comportamiento.
No hay cambios funcionales del backend ni de OV-1.

### Electricidad decorativa en XP

`widgets/electric_xp_icon.dart` reutiliza `LucideIcons.zap`. Una máscara de color
recorre sus trazos con tres destellos pequeños; no sustituye el icono ni usa
CustomPainter, video, assets generados o dependencias adicionales.

- Pulso de 1,1 segundos, con aproximadamente 3,9 segundos de pausa entre ciclos.
- Una subida del XP recibido dispara otro pulso; no modifica ni concede XP.
- Se detiene cuando la app sale del primer plano o su TickerMode queda oculto.
- Movimiento reducido o navegación accesible: icono estático.
- La decoración no añade elementos al árbol semántico; el botón conserva su
  etiqueta de XP y destino a logros/insignias.
- Se libera el temporizador y el controlador al destruir el widget.

### Evidencia y pendientes

Pruebas nuevas: activo/pausa, movimiento reducido, navegación accesible,
segundo plano, TickerMode oculto, incremento de XP y liberación de recursos.
Inicio se prueba en 320, 360, 390, 430 y 768 px, con texto al 100 %, 150 % y
200 %. Se comprueba la ruta del asset original y ausencia de progreso duplicado.

Vistas previas generadas e inspeccionadas en claro y oscuro:
`build/dashboard-preview/light.png` y `build/dashboard-preview/dark.png`.
La vista previa usa fuentes Roboto del SDK y la fuente Lucide del paquete;
son renders de widgets, no capturas de Android. No incluyen el shell completo.

Pendiente instalar y revisar en celular: movimiento real del rayo, zona táctil,
fuente del dispositivo e integración visual con calendario y barra inferior.
Resultado final: 82/82 pruebas dirigidas aprobadas (Inicio, electricidad,
accesibilidad, navegación, Lucide, alcance de presentación y calendario).
`flutter analyze`: sin incidencias. `git diff --check`: sin errores de espacios.
Dos renders adicionales de Inicio en claro/oscuro aprobados e inspeccionados.
No se ejecutó la suite completa de todo el producto, no se instaló una APK
ni se realizaron cambios de backend, commit, push o despliegue en esta entrega.
Siguiente paso: revisar Inicio en Android con Pavel; después, Estudiar.
