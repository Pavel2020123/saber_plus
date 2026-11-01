# H3: reanudación local del 31 de octubre

**Actualización posterior:** [pruebas automatizadas Android USB y correcciones](H3_PRUEBAS_USB_2026_10_31.md). Los pendientes de preparación descritos abajo son antecedentes: se ejecutaron aislamiento/cambio de cuenta, revocación y recuperación de conexión. No se atribuyen como aprobaciones humanas nuevas.

Preparación solicitada por el propietario. No acredita guiones humanos nuevos ni despliegue. Se conservan cambios locales y ramas de retoma; no se usaron bases remotas.

## Comprobaciones repetidas

- Docker Linux disponible y Android autorizado por ADB.
- Primer intento SQL/HTTP falló por sintaxis preexistente en `tira-afloja.service.ts`: un segundo `?` en el ternario del detalle de logging. Corrección mínima elimina ese token sin retirar los demás cambios del archivo.
- Repetición completa `npm run test:editorial-files:postgres`: **92/92 aprobadas**, 78 migraciones en PostgreSQL temporal propio. El runner eliminó sus recursos temporales al terminar. Chromium verificó revocación/respuesta perdida/recibo recuperado. Capturas inspeccionadas en backend `.tmp/c5b-qa/run-k7Y0wQ/h3-revocacion-1280.png` y `h3-revocacion-390.png`.
- Flutter dirigido: **39/39 aprobadas**, `editorial_image_test.dart` y `academic_image_viewer_test.dart`. Un primer comando apuntó además a un archivo inexistente; no se contó como ejecución aprobada. La selección corregida terminó sin fallos.

## Sesión humana nueva

Runner existente `local_ranking_validation.mjs`, con opt-in local de opciones/históricos. Sesión temporal `saberplus-i2-local-Xrltv3`; API loopback 43187, panel ADMIN loopback 4173; ADB reverse 43187 confirmado. 78 migraciones locales. La ruta `/health` no existe en esta API; se comprobó disponibilidad con login sintético HTTP 201, no con un health ficticio. Panel HTTP 200.

12 preguntas sintéticas guardadas/recargadas, tema `Opciones C2-D - ensayo faff7c51`, subtema `Opciones con imágenes`, figuras azul horizontal/naranja vertical. No se crearon respuestas, progreso o aprobaciones humanas por script.

Configuración pública de APK: `flutter-app.json` dentro de la sesión temporal; jamás compilar con `flutter-private.json`. La contraseña solo permanece en ese archivo privado de la sesión, no en documentación/chat/Git. Correos de ensayo `student@example.invalid` y `zero@example.invalid`, misma credencial temporal del runner. El panel usa `admin@example.invalid` únicamente en el entorno sintético.

La sesión caduca aproximadamente dos horas después del inicio del runner; verificar procesos/contenedor/API antes de continuar. No reutilizarla en otra jornada ni presentar el entorno como persistente/productivo.

## Próximo paso humano

Tras instalar y verificar identificador `com.example.saber_plus.i2validation` y etiqueta `SaberPlus Pruebas`, entrar como estudiante y responder una pregunta sintética incorrectamente para generar historial propio real. La sesión anterior ya no existe; no se fabrica su historial. Después preparar el cambio de versión con `prepare_editorial_history_local.mjs`, que exige esa respuesta, y continuar H3-2 con la otra cuenta. H3 conserva su antecedente 1/4; preparar no aprueba H3-2/3/4.

No se borró/desinstaló la app normal, no se hizo merge/push ni se cambió ninguna regla comercial. Estado de APK/instalación se agrega cuando termine, no se presume por iniciar Gradle.

## APK e instalación comprobadas

### Continuación humana: imágenes confirmadas

El propietario confirmó cinco preguntas de práctica y las imágenes visibles al abrir el cuaderno. Se ejecutó el preparador H3 en la sesión propia: 12 originales archivadas y 12 versiones nuevas sin figuras. Primer intento devolvió AssertionError en history-invariant; se inspeccionaron los conjuntos completos sin imprimir datos privados: XP 0, cinco respuestas, diez referencias de imagen y cero filas de CuadernoError, idénticos al baseline. La repetición idempotente pasó y confirmó acceso original del propietario y 404 para la otra cuenta. No se atribuye una causa no comprobada a la primera alerta. La pantalla llamada cuaderno por el propietario no se toma como prueba de filas en CuadernoError: el baseline SQL tiene cero, mientras el historial tiene cinco. Pendiente verificación Android después de edición y H3-2; no se marca aprobado por el resultado de API.

Build debug finalizado, Gradle 197,7 s. `aapt` confirmó paquete `com.example.saber_plus.i2validation` y etiqueta `SaberPlus Pruebas`; solo entonces ADB `install -r` terminó **Success**. No se instaló sobre `com.example.saber_plus`. API comprobada de nuevo por login sintético 201 y reverse USB renovado. Advertencia de compatibilidad futura Kotlin/`flutter_timezone` conservada, sin actualización de dependencias. Esperando apertura por el propietario y respuesta de ensayo; instalación no equivale a H3-2 aprobado.
