# Auditoría de navegación y experiencia de uso — 9 de septiembre de 2026

## Alcance y límites

Revisión de los cambios de navegación, acceso, inicio del estudiante, menú «Más» y controles de salida de los juegos. Incluye inspección del código y pruebas automatizadas de widgets; no constituye una certificación de accesibilidad de todas las pantallas.

Se conserva el fondo blanco del modo claro, las preferencias existentes de apariencia y las animaciones de juegos. No se cambió la identidad visual ni se añadieron sonidos o servicios externos.

La comprobación visual del panel editorial en un navegador real sigue pendiente: la herramienta de navegador no encontró ningún navegador disponible. Las pruebas de widgets de Flutter tampoco sustituyen una prueba manual con TalkBack/VoiceOver, teclado y dispositivos reales.

## Correcciones realizadas

| Hallazgo | Corrección | Comprobación |
| --- | --- | --- |
| Un estudiante podía navegar a pantallas de profesor; la protección inversa sí existía. | Política de redirección en ambas direcciones, incluidos enlaces a rutas anidadas. Se conserva el acceso administrativo existente. | Pruebas unitarias para estudiantes, profesores y administradores. |
| La prioridad del cambio inicial de contraseña se mezclaba con los saltos desde rutas públicas y de carga. | Regla explícita: restauración de sesión, autenticación y cambio obligatorio preceden a la navegación por rol. | Pruebas de redirección, rutas públicas y ausencia de bucles en los casos cubiertos. |
| La política de navegación estaba mezclada con la lista extensa de pantallas. | Extracción a `lib/app/session_route_policy.dart`, una función sin dependencias de widgets. Se conserva un router estable y se refrescan sus redirecciones al cambiar la sesión. | Pruebas unitarias de la política y regresión de ciclo de vida en `widget_test.dart`. |
| La tarjeta de actividad principal usaba colores fijos que no se adaptaban correctamente al tema oscuro. | Se usan los pares `primary`/`onPrimary` del tema, incluido el botón; se elimina el degradado fijo de esa tarjeta. | Contraste de al menos 4,5:1 en los textos con color explícito de la tarjeta, tanto en claro como en oscuro. No se extrapola a toda la app. |
| Las métricas en dos columnas y el encabezado de actividad podían perder espacio con letras grandes. | Las métricas se apilan según el ancho disponible y la escala del texto; el encabezado puede ajustarse a varias líneas. | Inicio a 320 px y texto al 200 %, en ambos temas, con desplazamiento por el contenido y sin excepciones de desbordamiento. |
| Los errores de acceso eran visibles, pero no estaban marcados como anuncios para tecnologías de asistencia. | `AuthErrorBanner` incorpora una región semántica viva. | Prueba del mensaje y del indicador `isLiveRegion`. La locución real depende del lector de pantalla. |
| La contraseña visible podía mantener las sugerencias del teclado. | Se deshabilitan autocorrección y sugerencias, incluso al mostrar temporalmente la contraseña. Se conserva el autocompletado de contraseñas. | Prueba del campo antes y después de alternar su visibilidad. |
| El menú decía «Cerrar demostración» también para una cuenta real. | El texto depende del estado de la sesión: «Cerrar demostración» o «Cerrar sesión». | Inspección del selector de sesión; los cambios de sesión se verifican por separado en la auditoría de datos. |
| El icono de salida de los juegos no explicaba su propósito. | Tooltip «Abandonar partida» en Trivia Rush/Duelo fantasma, Memoria académica y Tira y afloja. Se conserva la confirmación de abandono. | Pruebas de widgets que encuentran el control por su tooltip. |

La protección de rutas mejora la experiencia y evita accesos accidentales, pero **no reemplaza los permisos del backend**. Las llamadas a la API deben seguir verificando identidad, rol y propiedad de los datos.

## Pruebas ejecutadas

Desde la raíz de Flutter:

```powershell
flutter test test/session_route_policy_test.dart test/ux_accessibility_regression_test.dart test/ghost_trivia_visuals_test.dart test/memory_match_test.dart test/tug_of_war_test.dart --reporter expanded
```

Resultado del 9 de septiembre de 2026: **46 pruebas aprobadas, 0 fallidas**. La selección también comprueba comportamientos existentes de juegos: pausa del movimiento decorativo del fantasma, reducción de movimiento, tablero de memoria y confirmación de salida/pausa de Tira y afloja.

El formato de los 13 archivos Dart de este alcance se verificó con `dart format --output=none --set-exit-if-changed`: **0 archivos pendientes de formato**. Los resultados del análisis estático, la suite completa y las compilaciones se registran en el informe general, no se infieren de estas pruebas parciales.

En la comprobación general posterior apareció una regresión del ajuste de
limpieza: al reconstruir el proveedor por un cambio de sesión, se destruía el
router mientras el callback de login todavía lo usaba. Se corrigió manteniendo
su identidad y notificando cambios con `refreshListenable`; se libera al destruir
el proveedor, no con cada login/logout. La prueba nueva comprueba entrada demo,
cambio a profesor, cierre y misma instancia de router. La verificación global
final se registra en el informe principal.

## Verificaciones pendientes antes de publicar

- Recorrido manual de todas las pantallas principales con TalkBack y VoiceOver: orden de lectura, nombre de controles, anuncios de resultados y manejo del foco.
- Dispositivos Android e iOS reales, distintos tamaños de pantalla, teclado abierto, texto grande y modo oscuro. El ensayo automatizado a 320 px cubre el inicio, no todo el catálogo de pantallas.
- Revisión visual real del panel editorial: navegación por teclado, foco, confirmaciones de eliminación, mensajes de error y pérdida de conexión durante operaciones.
- Medir fluidez, batería y audio de juegos/racha en equipos de gama baja. Las pruebas de animación comprueban comportamiento, no el rendimiento real ni la percepción visual.
- Pruebas de navegación con cuentas reales y enlaces entrantes después de conectar el entorno de D3. No se realizó conexión ni despliegue remoto en esta revisión.

## Estado de la etapa

Correcciones y regresiones automatizadas de este alcance completadas. La auditoría visual manual y la validación multiplataforma permanecen abiertas; **D3 (panel con backend real) no se adelanta ni se marca como terminada**.
