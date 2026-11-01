# H3: pruebas automatizadas en Android USB — 31/oct/2026

Acta de la ejecución solicitada por el propietario, posterior a la preparación de [H3](H3_REANUDACION_2026_10_31.md). Exclusivamente API/PostgreSQL temporales propios y cuentas sintéticas. No es despliegue ni certificación de toda la aplicación.

## Alcance y resultados observados

| Comprobación | Evidencia y resultado |
| --- | --- |
| Conservación tras editar/archivar | Android Cuaderno actualizado conserva las figuras y explicación originales, aunque las 12 preguntas actuales son versiones nuevas sin imágenes. |
| Logout y aislamiento | Logout retira contenido privado. Segunda cuenta con cero errores, sin figuras de la primera. Al regresar al propietario reaparecen sus cinco errores e imágenes originales. |
| Revocación ADMIN | Operación mediante API ADMIN y recibo coincidente. Al actualizar Android desaparece la figura azul revocada; permanecen la figura naranja, texto y explicación. Consultar de nuevo no recupera píxeles denegados. |
| Fallo y recuperación | Se retira solo el reverse USB de la API: aparece error de conexión sin imágenes antiguas. Tras restaurarlo, Reintentar recupera cinco errores. No se alteró Wi-Fi ni datos móviles. |
| Letra grande | Escala Android 1,3: se detectó colisión de etiquetas inferiores y se corrigió mostrando solo la etiqueta seleccionada; se conservan nombres accesibles. Captura posterior inspeccionada. Escala original 1,0 restaurada. |
| Integridad | Comparación final: XP 0→0, respuestas 5→5, referencias históricas de imagen 10→10, filas CuadernoError 0→0. El cuaderno mostrado se deriva del historial: no son cinco filas SQL de CuadernoError. |

La navegación y capturas son automatizadas sobre un teléfono físico; **no se convierten en cuatro aprobaciones humanas**. El antecedente humano sigue siendo 1/4. Se completó la cobertura local automatizada de estos escenarios; validación de aceptación humana, publicación y otros bloques C5/P5/D3 siguen separados.

## Defectos corregidos

- `progress_page.dart`: `_reloadNotebook` devolvía un Future desde el callback de `setState`. Flutter rechazaba Reintentar con una aserción. Ahora usa un bloque síncrono; hot reload aplicado, recuperación por botón repetida y consulta de errores de ejecución sin incidencias nuevas.
- `student_shell.dart`: barra estudiantil adapta etiquetas a letra ampliada. No cambia destinos, permisos ni reglas de negocio. Tres pruebas de escala 1,0/1,3/2,0.
- Backend: token `?` duplicado preexistente en ternario de logging de tira y afloja bloqueaba el ensayo integrado. Corrección mínima, sin retirar cambios locales ajenos.

## Evidencias

## Verificación final de entrega

- `npm run test:editorial-files:postgres`: **92/92**, 78 migraciones exclusivamente temporales; incluyó Chromium y recuperación del recibo ADMIN. Recursos de esa suite retirados por su runner.
- Regresión Flutter conjunta: **77/77**, cero fallos, 85 s: `progress_retry_test`, `student_navigation_accessibility_test`, `editorial_image_test`, `academic_image_viewer_test` y `widget_test`.
- Análisis de los dos archivos Dart modificados y sus dos pruebas nuevas: **sin incidencias**. `git diff --check` correcto, solo avisos de normalización LF/CRLF de archivos ya modificados.
- La prueba nueva de Reintentar requirió ajustar la sincronización del cambio de pestaña antes de emitir el error simulado; también se corrigió un import inicialmente mal situado. Los intentos fallidos no se cuentan como aprobados. El comando conjunto final pasó completo.
- APK debug final compilada en 105,8 s. `aapt` verificó paquete `.i2validation` y etiqueta SaberPlus Pruebas; ADB `install -r`: **Success**. Tras reinstalar se repitió desconexión → mensaje → restauración → botón Reintentar → cinco errores. No depende del hot reload.
- Android: abrir figura naranja, ampliarla dos veces y cerrar el visor comprobados después de reinstalar. Capturas `h3-viewer-final.png` y `h3-viewer-zoom.png` inspeccionadas; proporción conservada.
- Consulta de errores de ejecución tras el hot reload y los reintentos: **sin errores nuevos**. La revisión SQL final tras reinstalar/consultar sigue sin cambios en XP/historial/referencias.

## Capturas

Capturas reales en [evidence/h3-20261031](evidence/h3-20261031/):

- `h3-owner-images-return.png`: originales al volver al propietario.
- `h3-logout.png` y `h3-zero-notebook.png`: salida y cuenta vacía.
- `h3-revoked.png` y `h3-revoked-retry.png`: imagen revocada no disponible.
- `h3-network-failure.png` y `h3-retry-fixed.png`: desconexión y recuperación con el botón corregido.
- `h3-large-text.png`: defecto anterior, **no resultado aprobado**.
- `h3-large-fixed.png`: navegación posterior a la corrección.

Un intento inicial de automatizar el acceso enfocó el campo incorrecto por el movimiento del teclado. Se retiró la captura de formulario afectada y se rotó inmediatamente la credencial sintética de las cinco cuentas temporales. No hubo cuentas reales ni credenciales productivas. Los accesos siguientes verificaron foco y campo de contraseña antes de escribir.

## Límites y continuidad

La variante instalada es `com.example.saber_plus.i2validation`, etiqueta SaberPlus Pruebas. No se desinstaló ni sustituyó la app normal. La API depende del runner temporal de dos horas, no de un servicio persistente: para otra jornada preparar sesión nueva, no reutilizar credenciales/fixtures caducados.

Sin commit, push, merge, migración remota, producción ni cambios de política comercial. Se preservan worktrees con cambios anteriores. ESLint global, licencias #14/LIC-0, Billing y entrega de producción no quedan aprobados por este ensayo.
