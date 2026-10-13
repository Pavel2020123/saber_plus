# PR-I5-C — Perfil institucional

## Ensayo C1C completado localmente — 12 de octubre de 2026

Preparación automática aprobada: Docker local Linux, imagen PostgreSQL16 existente,
sesión nueva del supervisor, **63 migraciones aplicadas** en su base temporal
incluida `20261011200000_institution_public_profile`. Compilación backend correcta.
API en `http://127.0.0.1:43187`. No se inició panel administrativo en este ensayo.
No se migró ni desplegó Supabase/Render.

- `backend/tool/test_institution_profile_local.cjs`: **15/15 HTTP/PostgreSQL
  reales** aprobadas. Verifica contrato/privacidad, JWT, cuenta eliminada/correo,
  propietario vs administrador/estudiante/ajeno, publicación, reconexión,
  DTO y límite500, dos guardados concurrentes (un200/un409/una auditoría),
  rollback real al fallar auditoría, cambio de rol, suspensión y limpieza.
- `test/institution_profile_local_api_test.dart`: **3/3 Flutter/API reales**
  aprobadas: propietario publica/estudiante lee, docente solo lectura y conflicto.
  Prueba opt-in con credencial temporal; restaura presentación al terminar.
- APK `.i2validation` compilada, identidad comprobada, instalada por USB con
  **Success**, reverse43187 y lanzamiento confirmados. Instalación no acredita UX.
- Las cuentas ficticias `teacher@example.invalid` (propietario),
  `teacher-reader@example.invalid` (administrador de solo lectura) y
  `student@example.invalid` pertenecen a ESTA sesión. Contraseña privada en
  `flutter-private.json`, campo `AUTH_E2E_PASSWORD`. No guardarla en Git.
- `flutter analyze`: sin incidencias; sintaxis de scripts Node y diff sin errores.
- Institución sembrada: **Institución de ensayo Perfil C1**, Amazonas/Leticia,
  aprobada, presentación inicialmente vacía. No ejecutar el test SQL dos veces
  contra la misma sesión: exige cuenta de ensayo inicialmente sin institución.

**Prueba 1 aprobada en Android por confirmación del usuario:** propietario abre
la institución correcta y ve descripción editable y botón de guardado.
**Prueba 2 aprobada en Android por confirmación del usuario:** docente lector
ve solo lectura, no puede escribir y no dispone de botón de guardar.
**Prueba 3 aprobada en Android por confirmación del usuario:** propietario guarda,
sale de edición y estudiante ve el texto actualizado en «Sobre la institución».
**Prueba 4 aprobada por confirmación del usuario:** cierre/reapertura manual,
la ficha conserva el texto actualizado. **Prueba 5 aprobada:** propietario guarda
vacío y ve el estado vacío; estudiante confirma presentación retirada del directorio
y mensaje «Esta institución todavía no ha añadido una presentación pública».
**Prueba 6 aprobada:** usuario confirma500/500, bloqueo de texto adicional y
guardado sin error. Lectura SQL posterior confirma500 caracteres/revisión12.
**Prueba 7 aprobada:** usuario confirma error sin conexión, borrador conservado
y botón Guardar deshabilitado. **Prueba 8 aprobada:** usuario confirma consulta
exitosa, borrador conservado, publicado anterior visible y Guardar habilitado;
guardado exitoso cierra editor y muestra borrador recuperado como presentación.
Verificación SQL: descripción escrita por usuario «borrar de sin conexión»,
revisión13. Difiere de la frase sugerida; se conserva el texto realmente escrito.
**Prueba 9 aprobada:** usuario confirma conflicto, borrador conservado y Guardar
bloqueado; consulta muestra versión externa, conserva borrador y habilita Guardar.
Guardado posterior cierra editor y publica el borrador. SQL confirma texto real
«borrador ficticio», revisión15. **Prueba10 aprobada:** «Seguir editando» conserva
borrador; «Salir» lo descarta. Reapertura muestra publicado anterior y SQL confirma
«borrador ficticio»/revisión15 sin modificación. **10/10 pruebas humanas aprobadas.**
C2A/B ya implementadas; sigue [C2C, ensayo del logo](PR_I5_C2_LOGO.md).
No implica despliegue o validación remota.

### Antecedentes de preparación (resueltos; no son pendientes actuales)
Prueba 9 preparada: usuario confirma borrador en el editor (versión13). Una
segunda sesión del propietario, autenticada vía API local, guardó «Presentación
actualizada desde otro dispositivo», HTTP200/revisión14. Usuario confirma aviso
de guardado no confirmado/versión cambiada, borrador conservado y Guardar
deshabilitado. Lectura SQL posterior confirma revisión14 y presentación externa
sin sobrescritura. Consulta y guardado recuperado posteriormente confirmados.
El texto externo contiene un `?` en lugar
de la vocal acentuada por la codificación del envío de ensayo, no por el editor.
Prueba 7 preparada: usuario confirma borrador «Borrador de prueba sin conexión».
Se retiró solo reverse USB43187; API del PC sigue HTTP200. Falta pulsar guardar
y confirmar error, conservación del borrador y reenvío bloqueado hasta consulta.
Prueba 7 parcial: usuario confirma aviso «No se pudo confirmar el guardado».
Falta confirmar texto pendiente conservado y botón Guardar deshabilitado.
Reverse43187 sigue retirado para terminar esta comprobación; no cerrar pantalla.
Prueba 6 preparada: usuario abrió descripción como propietario; texto ASCII de
más de500 caracteres enviado por USB con comando completado. Falta confirmar
contador500/500, rechazo de caracteres adicionales y guardado; no marcar aprobada aún.
Primer envío USB: usuario observó198/500, no prueba del límite. Se completó
otro envío en cinco bloques pequeños; pendiente nueva lectura humana del contador.
Usuario confirmó después500/500 y que no permite escribir más. Límite visual
aprobado; falta guardar ese texto y confirmar éxito para cerrar prueba 6.
El comando automático de cierre/reapertura USB fue rechazado por política antes
de ejecutarse; el usuario realizó cierre y reapertura manual y confirmó el resultado.

Durante prueba 3 el usuario confirmó «Presentación pública guardada», pero
reportó que permanecía en modo escritura. Se corrigió el flujo: cargar perfil
muestra texto; «Editar presentación» abre campos; éxito cierra teclado/formulario
y vuelve a lectura. Error/conflicto conserva editor y borrador. Corrección física
y consulta desde estudiante confirmadas; prueba 3 cerrada localmente.
Las pruebas 1/2 se realizaron con el editor anterior; el nuevo acceso requiere
pulsar «Editar presentación» como propietario. Docente sigue sin acción de edición.
Regresión del ajuste: ocho pruebas del editor aprobadas (incluyen vista inicial,
cierre de teclado/formulario tras éxito y edición explícita), formato aplicado y
análisis Flutter sin incidencias. APK recompilada e instalada por USB (Success),
reverse restaurado y app abierta. **Corrección física confirmada por el usuario:**
guardar deja texto visible y termina edición. Consulta desde estudiante también
confirmada: texto actualizado visible en ficha pública autenticada.

1. **APROBADA:** propietario abre y puede editar (confirmación humana).
2. **APROBADA:** docente lector solo consulta (confirmación humana).
3. **APROBADA:** guardar presentación y consultarla como estudiante (confirmación humana).
4. **APROBADA:** cerrar/reabrir app conserva texto (confirmación humana).
5. **APROBADA:** vaciar presentación elimina texto público (confirmación humana).
6. **APROBADA:** límite500 y guardado exitoso (confirmación humana + SQL500/revisión12).
7. **APROBADA:** error sin conexión, borrador conservado y reenvío bloqueado (confirmación humana).
8. **APROBADA:** recuperar conexión, consultar y guardar borrador (confirmación humana).
9. **APROBADA:** conflicto sin sobrescritura, borrador conservado, consulta y guardado recuperado (confirmación humana + SQL revisión14→15).
10. **APROBADA:** «Seguir editando» conserva borrador y «Salir» descarta sin publicar (confirmación humana + SQL revisión15 intacta).

Actualizar checkpoint tras cada confirmación. Si expira el supervisor (dos horas),
crear sesión nueva, no reutilizar credenciales ni asumir datos conservados.
Relevo: iniciar supervisor, test SQL anterior, Flutter opt-in y USB; leer primero
checkpoint para repetir únicamente preparación/punto pendiente. Servicios activos
solo comprobados durante este turno. C1 todavía no se cierra; sin commit/push.

Comandos de pruebas, con `$testSessionDirectory` apuntando a SU sesión temporal:

```powershell
# Desde SaberPlus-Backend\backend
$env:SABERPLUS_LOCAL_SESSION=$testSessionDirectory
node --test tool/test_institution_profile_local.cjs
# Desde saber_plus; este archivo privado es para test, nunca flutter build.
flutter test "--dart-define-from-file=$testSessionDirectory/flutter-private.json" test/institution_profile_local_api_test.dart
```

Los estados «migración no aplicada» y «APK no instalada» inferiores documentan
únicamente C1A/C1B del día11, anteriores a este ensayo.

Checkpoint: 11 de octubre de 2026. **C1A y código C1B implementados; C1 no está cerrada.**
T5 territorial permanece cerrado localmente. Este bloque no cambia XP, juegos,
certificados, aprobación ADMIN ni códigos de ingreso.

## C1A: contrato y lectura pública

- Backend: `descripcionPublica` opcional, independiente de `mensajeBienvenida`.
  No se copian textos antiguos, contactos ni códigos a la presentación pública.
- `GET /instituciones/me/perfil`: membresía docente de institución aprobada,
  nombre, descripción, revisión y permiso de edición del propietario actual.
- `PATCH /instituciones/me/perfil`: solo propietario; cuerpo `{revision,
  descripcion}`. Texto plano hasta 500 caracteres; vacío elimina la descripción.
  Campos extra, nombre y ubicación no se aceptan. Requiere sesión/correo según
  las políticas existentes. Cambio y auditoría comparten transacción.
- Revisión optimista: 409 cuando la versión cambia; no sobrescribir/reintentar
  ciegamente. La respuesta exitosa contiene descripción y nueva revisión.
- Detalle autenticado del directorio añade `descripcion` nullable; listado
  paginado conserva su contrato. Instituciones no aprobadas siguen ocultas.
- Flutter interpreta el campo opcional (compatible con respuesta anterior),
  muestra texto literal y un estado vacío, nunca el mensaje de bienvenida.

## C1B implementada: editor Flutter

Acceso desde panel docente vinculado a institución APROBADA: «Perfil institucional».
El permiso devuelto por la API determina edición o solo lectura. Nombre/ubicación
no se modifican aquí. Repositorio remoto y demo explícita, guardado con revisión,
invalidación de ficha tras éxito y nueva instancia del editor al cambiar sesión.
Se conserva borrador ante error/conflicto y se bloquea reenvío hasta consultar
versión actual. Esa consulta conserva texto pendiente y muestra el texto publicado
para compararlo. Salir con cambios requiere confirmación. Vaciar borra presentación.

Validación C1B: 33 casos distintos de editor/repositorio/ficha/directorio aprobados
(32 en ejecución conjunta y editor ampliado, 7/7), más 16 de regresión docente.
Total: 49 casos distintos dirigidos aprobados. `flutter analyze` sin incidencias,
formato aplicado y `git diff --check` correcto. No se ejecutó suite completa.
No se ha aplicado migración ni instalado APK de este incremento. Los resultados
de C1A inferiores son históricos, no una ejecución nueva del backend.

## Guion C1C original — completado localmente el 12 de octubre

Los puntos 1–3 del plan original siguiente están implementados; continuar 4–5.

1. Repositorio Flutter de lectura/guardado, demo explícita y estado por sesión.
2. Formulario desde panel docente: propietario edita; otros docentes solo leen.
   Nombre y ubicación verificados no editables desde este formulario.
3. Conservar borrador frente a error/409. Si no se confirma la escritura,
   consultar versión actual antes de reenviar. No actualizar otra sesión con
   respuestas tardías. Advertir antes de descartar texto al recargar/salir.
4. Pruebas HTTP de guardas, repositorio/widget y PostgreSQL real desechable
   (concurrencia y rollback); luego ensayo Android guardado/directorio/reinicio.
5. Cerrar C1 únicamente después de completar y documentar estos pasos.

Después: **C2 logo** (carga, validación real, almacenamiento, recorte y permiso
del propietario; revisar también rutas antiguas de logo), seguido de solicitudes
estudiantiles/avisos. No sustituir códigos de grupo silenciosamente.

## Evidencia y límites de C1A

- Backend `npm run build`: correcto, genera Prisma Client y compila Nest.
- Jest perfil + directorio: **45 aprobadas** (mocks; no acreditan PostgreSQL real).
- Flutter perfil público + directorio: **21 aprobadas**; formato aplicado.
- `flutter analyze`: sin incidencias. No se ejecutó la suite completa en este incremento.
- Migración nueva `20261011200000_institution_public_profile` **no ejecutada**.
  Aplicarla primero en una base de pruebas autorizada antes de arrancar API nueva:
  las consultas nuevas requieren sus columnas. No se tocó Supabase/Render.
- No se instaló APK, no hubo prueba física ni cierre completo de PR-I5.
- No se cambió todavía el permiso de las rutas heredadas de logo/bienvenida.
- Sin commit/push en este incremento; conservar los cambios de ambos repos.
