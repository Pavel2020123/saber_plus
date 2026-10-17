# PR-I5-C4 — Código institucional privado

## Checkpoint — 17 de octubre de 2026

**C4-C:10/10 guiones locales cubiertos con evidencia combinada Android y HTTP/SQL.**
No son diez pruebas exclusivamente manuales:2,6 y9 se completaron con19 controles
HTTP/SQL complementarios. Regresión Flutter global final893 aprobadas/13 opt-in omitidas; sigue
[revisión de entrega del cierre local consolidado](CIERRE_INSTITUCIONES_LOCAL.md),
no despliegue. C3C cerró10/10 locales, con sus límites en
[acta C3](PR_I5_C3_SOLICITUDES.md). OV-1 continúa independiente con el compañero.
Commits locales autorizados por el propietario el17. Publicación/revisión pendientes;
sin push/merge/despliegue automático. Notas cronológicas conservan decisiones anteriores.

## Alcance y decisiones

- Código específico para estudiantes, separado de `codigoUnico` docente y del grupo.
- Solo propietario PROFESOR vigente de institución APROBADA consulta/genera/renueva.
  Primer GET no crea código: devuelve null y revisión0. Código128 bits, formato
  SPI- más32 hexadecimales; renovación invalida el anterior, no caduca automáticamente.
- Alumno consulta institución antes de confirmar. Ingreso no necesita aprobación
  del propietario porque el código compartido autoriza acceso; respeta cupo/estado.
- Conservar rol ESTUDIANTE; no asignar grupos ni rol docente. Sin traslado automático.
- Una solicitud pendiente debe cancelarse explícitamente antes de entrar por código;
  no borrar ni decidir silenciosamente solicitudes C3. Mostrar guía para hacerlo.
- Compartir es decisión del propietario. Código no público, no aparece en directorio,
  perfil, URLs, preferencias, auditoría, logs ni analítica. El propietario puede renovarlo
  si alguien lo reenvía. Demo no debe simular ingreso real.

## Backend disponible para integrar

Ruta base `/instituciones/codigo-estudiantes`, JWT y correo verificado.

| Ruta | Datos / uso |
|---|---|
| GET `/propio` | Solo propietario; `{institucion:{id,nombre},codigo,revision,operacionId}`. |
| POST `/renovar` | `{id:UUIDv4,revision:enteroJSON}`; resultado `{codigo,revision,operacionId}`. |
| POST `/consultar` | `{codigo}`; devuelve `{institucion:{id,nombre},revision,yaVinculado}`; no une. |
| POST `/ingresar` | `{id:UUIDv4,codigo,institucionId:UUIDv4,revision:enteroJSON}`; devuelve `{institucion:{id,nombre},estado:'VINCULADO',yaVinculado}`. |

Detalle técnico y evidencia en repo backend: `backend/docs/PR_I5_C4_CODIGO.md`.
Migración nueva `20261016180000_student_institution_codes` solo aplicada en base
temporal propia,66 migraciones. No usar credenciales de sesiones antiguas.

UUID/body se conservan en reintento incierto. Renovación con revisión obsoleta no
sobrescribe. Recibo de ingreso reconcilia operación confirmada incluso después de
renovar código, sin nuevo cupo/auditoría; no repone vínculo retirado. Errores400
(formato/cupo),401/403 (acceso),404 (código no disponible),409 (conflicto/pendiente).
No equiparar un error de conexión con resultado negativo: consultar/reconciliar.

## Evidencia de C4-A

- Prisma válido, cliente generado y build Nest correcto.
-96/96 unitarias dirigidas C4+C3; C4 aporta59.
- Regresión backend119 suites/1.470 aprobadas.
-16/16 HTTP/PostgreSQL C4 y14/14 C3 posteriores aprobadas en base propia.
- Verificados rollback, último cupo concurrente, renovación simultánea y permisos
  RLS/revocados de tablas privadas. Sin dependencia nueva.
- Límite de consultas por IP añadido en main; no validado su429 con el entrypoint
  alternativo del harness. No es evidencia de rate limiting distribuido o producción.

Los resultados superiores corresponden a C4-A. C4-B se implementó después,
con evidencia separada debajo. No se ejecutaron pruebas humanas C4.

## C4-B — implementación Flutter

Accesos:

- Propietario: Espacio del profesor → Código de estudiantes, solo si su membresía
  es PROPIETARIO y la institución está APROBADA. También se valida acceso al abrir
  la pantalla; los roles demo/ADMIN/docente lector no consultan el secreto.
- Alumno: Más → Mi institución y grupos → Unirme a una institución con código.
  Acceso solo con cuenta estudiantil real y sin institución. No sustituye formulario
  ni código temporal de grupo; demo no ofrece un ingreso simulado.

El propietario consulta sin generar automáticamente, confirma emisión/renovación,
y usa **Copiar para compartir** por gesto explícito. Esto copia al portapapeles
para enviarlo manualmente por un medio de confianza; no abre una hoja nativa ni
añade un paquete de compartir. Se advierte que el código puede reenviarse y debe
renovarse si se difunde. No se copia automáticamente al consultar/generar.

El alumno escribe/pega código, consulta nombre y confirma antes de enviar. Cambiar
texto invalida la vista previa. Solicitud pendiente se gestiona explícitamente desde
Consultar mis solicitudes, sin decidirla desde C4. Tras ingreso se refrescan perfil,
grupos y atajos de solicitudes; no se asigna grupo automáticamente.

Seguridad/recuperación de interfaz:

- Modelos/repositorio remoto validan UUID, tipo/revisión y concordancia de respuesta
  con operación/institución. Sin fallback demo, códigos en body POST, no URLs.
- Renovación o ingreso incierto bloquean otro envío hasta consultar estado. Si ya
  se guardó se reconcilia sin repetir; si no, se reutiliza UUID y snapshot original.
- Copiar queda bloqueado mientras no se confirme el código vigente. Al volver a
  primer plano, la pantalla del propietario vuelve a consultar cuando no está ocupada.
- Estado solo en memoria; no preferencias, nueva base local, logs ni analítica.
  Campo sin sugerencias, autocorrección ni aprendizaje personalizado del teclado.
- Cambiar de cuenta/rol/institución descarta secreto, borrador y resultados tardíos;
  las confirmaciones abiertas se retiran sin cerrar rutas ajenas. Doble pulsación
  bloqueada. Salir con código/intento requiere confirmar y advierte sobre resultado incierto.
- Listas desplazables, mensajes liveRegion y diálogos desplazables para texto grande.

Archivos principales:

- [Modelos y contrato](../lib/features/institutions/domain/student_institution_code.dart).
- [Repositorio remoto](../lib/features/institutions/data/student_institution_code_repository.dart).
- [Acceso por sesión y permisos](../lib/features/institutions/presentation/student_institution_code_page.dart).
- [Pantalla del propietario](../lib/features/institutions/presentation/institution_student_code_owner.dart).
- [Pantalla del alumno](../lib/features/institutions/presentation/institution_student_code_entry.dart).
- [Confirmaciones ligadas a pantalla/cuenta](../lib/features/institutions/presentation/institution_code_confirmation.dart).
- [Pruebas C4](../test/student_institution_code_test.dart).

Validación final completada:

- C4 añade42 pruebas de modelos/repositorio/widgets. Grupo dirigido C4+C3+atajos+
  grupos88 aprobadas; todas incluidas también en la regresión final.
- Regresión Flutter final:888 aprobadas y13 opt-in omitidas por requerir entornos/
  defines específicos. Estas omitidas no equivalen a ensayos reales aprobados.
- `flutter analyze --no-pub`: sin incidencias.
- Prueba de320×640 y texto200%: controles accesibles desplazando la lista y diálogos
  desplazables. Fallos iniciales del guion por buscar/pulsar antes de desplazar o
  reconstruir se corrigieron sin omitir pruebas; regresión final completa aprobada.
- Doble pulsación, copia por gesto/fallo del portapapeles, UUID estable, reintento,
  reconciliación, cambios de sesión/vínculo y cierre de confirmaciones cubiertos.
- Enlaces locales de8 documentos Flutter y5 backend comprobados, sin destinos ausentes;
  diff sin errores de espacios en archivos seguidos (avisos LF/CRLF esperados).

El bloque C4-B terminó sin instalar APK ni ejecutar pruebas humanas. La preparación
posterior de C4-C se registra debajo; no atribuirle la APK anterior C3 ni convertir
pruebas automáticas en confirmaciones humanas.

### Preparación C4-C — 16 de octubre de 2026

- Sesión temporal propia `saberplus-i2-local-gJ5KOg`,66 migraciones; API43187 y
  panel4173 responden200. Las credenciales nuevas están solo en el archivo privado
  de la sesión; no usar las de sesiones retiradas ni incorporarlas a Git.
- Se reutilizó `prepare_student_requests_resume.cjs` como preparación sintética:
  instituciones con nombres C3, propietario, docente lector y alumno sin vínculo;
  una solicitud cancelada de ejemplo. Esto no repite ni acredita pruebas humanas C3.
  No se generó código C4 durante la preparación: primera emisión queda para el usuario.
- APK C4-B compilada e instalada por USB con resultado `Success`, paquete aislado
  `com.example.saber_plus.i2validation`; app normal y datos conservados. Primer envío
  falló por corte USB (`Broken pipe`); segundo envío terminó correctamente.
- Al terminar la preparación C4-C estaba en **0/10 humano**. Paso inicial previsto:
  abrir manualmente la app de ensayo, iniciar sesión con el propietario y consultar
  sin generar automáticamente. La apertura automática fue bloqueada por el entorno.

### Criterios originales de C4-B (cubiertos por implementación, no guion humano)

1. Modelos/contrato y repositorio remoto estricto, providers sensibles a identidad.
2. Pantalla del propietario para código, generación/renovación confirmada y
   copiar/compartir por gesto. Solo propietario; gestión docente antigua intacta.
3. Pantalla del alumno: código→vista previa→confirmación, separada de grupos.
4. UUID estable, consulta/reintento ante red y bloqueo de doble tap; snapshot invalida
   si cambia texto/cuenta. Datos privados no persistidos localmente.
5. Tras éxito actualizar perfil y atajos institucionales. Manejar solicitud pendiente,
   cupo, suspensión, ya vinculado y traslado denegado con mensajes entendibles.
6. Pruebas Flutter/analyze; solo después instalar APK y comenzar C4-C.

## C4-C — diez guiones integrados (10/10 cubiertos; evidencia mixta)

El cierre vigente está en la sección Cierre de cobertura del17, debajo. Las notas
cronológicas intermedias conservan sus contadores originales; no son el estado actual.

Confirmaciones del usuario,16 de octubre, sesión `saberplus-i2-local-gJ5KOg`:

- Guion1 completo: consulta inicial mostró que no había código; tras generación
  explícita confirmada apareció el código. No se registra el secreto en esta acta.
- Guion2 parcial: `teacher-reader@example.invalid` no muestra la opción de código
  al no ser propietario. Falta completar las demás comprobaciones de acceso;
  ocultar el botón no demuestra por sí solo autorización del backend.
- Guion3 parcial: aviso de copia y pegado funcional confirmados mediante consulta
  válida posterior. Falta comprobar ausencia del código en el directorio público.
- Guion4 completo: estudiante consultó y vio Institucion de ensayo C3 con botón
  para unirse, antes de confirmar el ingreso. Inicialmente pegó el código institucional
  en el campo de grupo (máximo12), que lo truncó; se identificaron los formularios
  sin modificar código ni acortar el secreto institucional.
- Guion5 parcial: ingreso confirmado muestra Institución vinculada y aviso sin
  grupo automático. Al volver y actualizar mantiene vínculo, conserva Unirme a un
  grupo y oculta Unirme a una institución con código. Falta cotejo de rol/SQL.
- Guion6 parcial: con `zero@example.invalid`, cambiar un carácter del código produjo
  No pudimos consultar ese código; pegar el original mostró la institución sin ingreso.
  Tras renovación, el código anterior también se rechazó. Faltan códigos de grupo/docente.
- Guion7 parcial: propietario renovó explícitamente y confirmó que cambió el código.
  Alumno confirmó rechazo del anterior y consulta correcta del nuevo, sin unirse.
  Falta escenario de renovación incierta/reintento y cotejo de revisión/auditoría.
- Guion8 parcial: zero confirmó solicitud pendiente y acceso a Consultar mis
  solicitudes de ingreso. Canceló y consultó su estado CANCELADA. Al volver reportó
  texto de pendiente persistente y falta de actualización; pendiente repetir tras fix.
- Siguiente: repetir regreso desde solicitudes canceladas con APK corregida y
  verificar consulta de institución sin ingreso automático. No crear otra solicitud
  ni dar por aprobado el guion8 hasta confirmar en celular. Cupo/suspensión pendientes.

### Corrección al regresar de solicitudes — 16 de octubre

- Hallazgo Flutter: la ayuda sobre solicitud pendiente era incondicional y al volver
  no se consultaba automáticamente el vínculo ni se refrescaba la vista previa.
  No se constató que el backend mantuviera una solicitud cancelada como pendiente.
- `_requests` ahora consulta el vínculo real al retornar. Si no existe vínculo ni
  envío incierto y hay código válido, refresca la institución. Si hay envío incierto,
  conserva el mismo UUID/código/snapshot y habilita solo su reintento tras consulta.
  Una consulta fallida conserva bloqueo; vínculo confirmado retira formulario sin POST.
- Ayuda neutral: También puedes revisar o cancelar tus solicitudes de ingreso.
  Las restricciones reales siguen mostrándose cuando responde el servidor.
- Cuatro regresiones nuevas: refresco tras volver, mismo intento tras cancelación,
  fallo de red al regresar y aprobación reconciliada sin envío adicional.
-46/46 C4 y46/46 solicitudes/atajos/grupos aprobadas; analyze sin incidencias.
  No se repitió la regresión global888/13, que corresponde al bloque C4-B anterior.
  APK corregida y comprobación humana estaban pendientes al registrar esta corrección.
  Sin cambios backend funcionales, migraciones, commit ni despliegue.

### Reanudación acotada — 17 de octubre

- Sesión anterior retirada; sesión nueva propia `saberplus-i2-local-mR98b6`,66
  migraciones. No reutilizar contraseña ni código del16 de octubre.
- APK corregida confirmada instalada por información del paquete Android:
  `com.example.saber_plus.i2validation`, lastUpdateTime16 de octubre17:36:22.
  No fue necesario reinstalar; falta confirmación humana del comportamiento corregido.
- Preparación sintética con helpers `prepare_student_requests_resume.cjs` y
  `prepare_student_codes_return.cjs`: institución de ensayo C3, código nuevo emitido
  por API y solicitud PENDIENTE de `zero@example.invalid`, todavía sin vínculo.
  Esto no acredita generación/cancelación/ingreso humanos ni repite evidencia anterior.
  Credenciales/código solo en `c4-return-private.json` dentro de la sesión temporal.
- Prueba única a terminar: zero consulta el código, abre sus solicitudes, cancela
  la pendiente y vuelve con la flecha. Debe recuperar institución/acciones sin aviso
  obsoleto de pendiente ni ingresar automáticamente. No continuar otros guiones hoy.
  Resultado humano todavía pendiente; al confirmar, documentar punto exacto para mañana.

### Segundo hallazgo del17 — acceso a solicitudes tras ingreso rechazado

- Captura del usuario: tras confirmar ingreso con solicitud pendiente, servidor
  responde rechazo y solo queda habilitado Consultar mi vínculo; el acceso a
  solicitudes también quedaba bloqueado por `_mustConsult`. Guion8 no cerrado.
- Se reprodujo con prueba fallida antes del fix. Se retiró `_mustConsult` solo del
  acceso a solicitudes y de su guard; `_busy` sigue impidiendo doble navegación
  durante operaciones. El reenvío y edición del ingreso siguen protegidos.
- Al regresar se conserva la consulta estricta del vínculo: sin red no se habilita
  reenvío, si ya se guardó se reconcilia sin POST y, si no hay vínculo, se conserva
  exactamente el mismo intento para reintentar. No se cancela automáticamente.
- Pruebas ajustadas para entrar directamente a solicitudes sin consulta manual
  previa; añadida reconciliación de ingreso guardado con respuesta incierta.
  Resultado:93/93 C4+solicitudes+atajos+grupos (47 C4), analyze limpio. Regresión
  global anterior no repetida. APK nueva compilada e instalada por USB (`Success`)
  el17 de octubre, paquete aislado verificado; confirmación humana registrada debajo.
  Sin cambios backend funcionales ni commit/push/despliegue.

### Cierre de la prueba puntual — 17 de octubre

- Usuario confirmó tras el segundo fix: al volver desde solicitudes la pantalla
  se actualiza y muestra Reintentar mismo ingreso. Queda aprobada esta comprobación
  humana de recuperación de acciones tras gestionar/cancelar la solicitud.
- Se conserva el intento anterior; mostrar Reintentar no equivale a haber ingresado.
  No se pulsó ni confirmó ese reintento durante este cierre, ni se verificó SQL nuevo.
- Se termina la sesión de trabajo por decisión del usuario, sin iniciar más guiones.
  Guion8 sigue parcial: faltan cupo/suspensión y cotejos; C4-C no está terminado.
- Próxima sesión: comprobar servicios/credenciales vigentes y retomar reintento tras
  cancelación, verificando vínculo único y sin grupo automático. Si caducó la base
  temporal, reconstruir solo fixtures sintéticos y distinguirlos de esta evidencia.
  No confiar en conservar la pantalla/intento al reiniciar la app: no se persiste
  el secreto localmente. Sin commit/push de instituciones hasta nueva indicación.

### Reanudación posterior del17 — servicios preparados

Sesión propia nueva `saberplus-i2-local-6fFUQb`,66 migraciones; API43187/panel4173
responden200, Android autorizado y reverseUSB activo. Segundo fix instalado,
confirmado por lastUpdateTime17 de octubre00:16:19. No fue necesario reinstalar.
Helpers de preparación reconstruyeron instituciones C3 y zero con solicitud PENDIENTE,
sin vínculo y código nuevo. Sesión mR98b6 retirada, no reutilizar sus credenciales.
Datos privados en `c4-return-private.json` de sesión actual. Preparación sintética,
no prueba humana ni ingreso nuevo. Sigue reproducir rechazo/cancelación/regreso
y confirmar reintento con el mismo payload en esta sesión. Guion8 sigue parcial.

### Ingreso después de cancelar confirmado — 17 de octubre

- En `saberplus-i2-local-6fFUQb`, usuario confirmó rechazo por solicitud pendiente
  con botón de solicitudes habilitado; tras cancelar y volver se actualizó. Pulsó
  Reintentar mismo ingreso y confirmó Institución vinculada y sin grupo automático.
- Cotejo posterior de solo lectura `verify_student_codes_return.cjs` aprobado:
  zero conserva rol ESTUDIANTE, vínculo a institución esperada, una solicitud CANCELADA
  revisión1, un recibo de ingreso y su evento de auditoría coincidente; cero grupos
  y cero membresías docentes. No se alteraron datos mediante esta verificación.
- Guion5 completo con evidencia humana y SQL de zero. Parte de cancelación/regreso/
  ingreso del guion8 aprobada; cupo/suspensión siguen pendientes y no cierran ese guion.
  SQL demuestra un único recibo; identidad del UUID entre rechazo y reintento está
  cubierta por pruebas de widget, no se deduce de un rechazo sin recibo guardado.
- Usuario confirmó después de cerrar completamente y reabrir app: conserva vínculo
  en Mi institución y grupos y no reaparece Unirme a una institución con código.
  Parte de persistencia/reapertura del guion10 aprobada; no cierra red/cuentas/texto.
- Usuario confirmó perfil público institucional sin código privado ni acciones
  de copiar/generar/renovar. Junto con copia y pegado anteriores, guion3 completo.
- En cuenta absent sin vínculo confirmó rechazo de `GRP-12345678` con aviso de
  formato SPI y de UUID de ejemplo, sin institución visible. Son pruebas de formato,
  no se utilizaron secretos de un grupo/docente real ni se verificó HTTP adicional.
- Balance4/10 completos (1,3,4,5). Sigue cuenta sin vínculo `absent@example.invalid`:
  rechazar código de grupo y formato docente en la entrada institucional (guion6).
  Sin nueva regresión global, commit/push ni despliegue.

### Preparación de cupo agotado — sesión6fFUQb

Helper `control_student_code_limits.cjs full` ejecutado solo sobre base propia:
Institucion de ensayo C3 APROBADA, límite1 y un estudiante vinculado (zero).
Absent sigue ESTUDIANTE sin vínculo, sin solicitud pendiente, recibos ni auditoría
de ingreso. Valores previos guardados en `c4-limits-backup.json` de sesión temporal.
El límite temporal estuvo activo durante el caso de cupo; ya se recuperó el límite
original al preparar suspensión. No generar códigos nuevos.
Acciones `suspend`/`restore` recuperan límite original de backup; verificador
`verify-denied` es solo lectura. No aplica a institución real ni altera roles.

Usuario confirmó mensaje de cupo agotado. Cotejo `verify-denied` posterior aprobó
absent sin vínculo, cero recibos y cero auditorías de ingreso; ocupado1/límite1 y
estado APROBADA. Caso de cupo del guion8 aprobado, sin consumo adicional.
Luego `suspend` recuperó límite original null y dejó SUSPENDIDA solo la institución
de ensayo. Usuario confirmó desde pantalla limpia que código vigente no se pudo
consultar. `verify-denied` posterior aprobó absent sin vínculo/recibos/auditoría.
Se ejecutó `restore` y cotejo final: **APROBADA, límite original null recuperado**,
ocupado1, absent aún sin ingreso. No quedan cupo reducido ni suspensión temporal.
Guion8 completo: pendiente/cancelación/ingreso (evidencia anterior), cupo agotado
y consulta suspendida (humano/SQL); no se ejecutó POST de ingreso durante suspensión
desde celular porque no ofrecía vista previa. Ese rechazo POST tiene evidencia
automática C4-A separada, no convertirlo en acción humana.
Balance5/10 completos (1,3,4,5,8). Sigue consultar nuevamente el código tras restaurar,
sin confirmar ingreso, para observar recuperación de la vista previa.

Usuario confirmó recuperación de vista previa tras restaurar APROBADA/límite null.
Siguiente guion10, sesión6fFUQb: absent con vista previa válida. Se retiró solamente
`adb reverse tcp:43187`, API en PC sigue lista200; Docker/Wi-Fi intactos.
**Enlace USB API temporalmente retirado: restaurar antes de consultas de recuperación**.
Sigue pulsar ingreso/confirmar, observar error y bloqueo del reenvío; después restaurar
reverse y consultar vínculo antes de reintentar. Fallo preparado antes del POST,
no simula respuesta perdida después de guardar. Resultado humano pendiente.

Usuario confirmó tras pulsar ingreso con el corte activo: reintento/edición
bloqueados y botones Consultar mi vínculo / Consultar mis solicitudes de ingreso
habilitados. Se restauró reverseUSB43187 y API200. `verify-denied` aprobó absent
sin vínculo, recibos ni auditorías; institución APROBADA/límite null/ocupado1.
**Enlace restablecido**. Sigue consulta humana del vínculo antes de reintentar;
guion10 sigue parcial, sin afirmar reintento aprobado todavía.

Usuario confirmó después de restaurar USB: Consultar mi vínculo habilitó Reintentar
mismo ingreso; lo pulsó y confirmó institución vinculada/sin grupo automático.
`verify_student_codes_return.cjs absent@example.invalid` solo lectura aprobó:
ESTUDIANTE, vínculo esperado, cero solicitudes, un recibo y un único evento de
ingreso coincidente, cero grupos/membresías docentes. Recuperación de red aprobada
con límite de corte previo al POST; no acredita respuesta perdida tras commit.
Guion9 parcial por unicidad observada, sin replay HTTP ni traslado aún; guion10
parcial por cambio de cuentas/texto grande pendientes. Sigue cerrar sesión de absent,
entrar con student sin vínculo y comprobar que no hereda institución/código/intento.
No repetir helpers de cupo: requieren absent sin vínculo y ya no aplica ese supuesto.

Usuario confirmó cambio de absent a student: Mi institución y grupos muestra sin
institución vinculada y entrada de código vacía. Aislamiento de datos visibles e
intento entre esas cuentas aprobado; no representa prueba humana de respuesta
tardía cruzando cuentas (esa existe en widgets). Sigue guion10 texto grande:
consulta y diálogo de confirmación, cancelar sin ingresar. Mantener student sin vínculo.

Usuario confirmó después con texto del dispositivo ampliado: consulta, diálogo y
botones legibles/accesibles, desplazamiento y Volver sin confirmar ingreso. No se
midió factor exacto en Android (200% corresponde a widgets previos). Guion10 completo
con límites ya descritos: corte antes de POST, no respuesta perdida tras guardado;
aislamiento visible, no respuesta tardía manual entre cuentas. Balance6/10 (1,3,4,5,8,10).
Sigue propietario: consultar código vigente sin renovar aún, preparar fallo de red
durante renovación para guion7. Puede restaurarse tamaño de texto habitual.

Guion7 preparado, sesión6fFUQb: usuario ve código vigente como propietario.
`verify_student_code_rotation.cjs baseline` guardó solo metadatos en tmp propio:
revisión1, un evento de renovación. No se leyó ni imprimió el secreto para este cotejo.
Se retiró reverseUSB43187, sin detener API/Docker. **Enlace retirado temporalmente**.
Sigue Renovar→Confirmar, observar estado incierto; luego restaurar enlace y consultar
código vigente antes del mismo reintento. Corte antes de POST, no respuesta perdida
tras guardado. No hay renovación confirmada en esta parte todavía.

Usuario confirmó fallo de renovación y controles bloqueados. ReverseUSB43187
restaurado/API200. `verify_student_code_rotation.cjs unchanged` aprobó revisión1,
misma operación y auditoría1: intento sin red no renovó. Sigue Consultar código
vigente desde la misma pantalla; debe habilitar reintento de la operación conservada.
Guion7 parcial hasta reintento confirmado y cotejo incremento único; no crear otro UUID.

Usuario confirmó que Consultar código vigente habilitó Reintentar misma renovación;
lo pulsó una vez y confirmó éxito. `verify_student_code_rotation.cjs renewed` aprobó
revisión2 y auditoría2 frente a baseline1/1: exactamente una renovación nueva,
sin duplicación. Guion7 completo con corte previo a POST; no representa respuesta
perdida después del commit (reconciliación posterior a guardado cubierta en widgets
y C4-A, no como nueva acción humana). Balance7/10 completos, restan2/6/9.
El campo STUDENT_INSTITUTION_CODE del archivo temporal inicial quedó obsoleto;
contraseña sigue vigente. No actualizarlo silenciosamente ni reutilizarlo como código
actual: conservar para prueba de rechazo antiguo. Sigue GET humano de vigente
para comprobar estabilidad, sin otra renovación ni exposición del secreto.

### Cierre de cobertura del17 — 19 comprobaciones HTTP/SQL complementarias

Usuario confirmó GET posterior manteniendo el mismo código. Se ejecutó
`verify_student_code_guards.cjs` en sesión6fFUQb:19/19 aprobadas. No son acciones
humanas nuevas. Se compararon perfiles, recibos, auditoría, grupos, membresías
y revisión/operación del código antes/después: sin cambios.

| Guion completado | Evidencia final |
|---|---|
|2 — Permisos | Lector oculto en Android (anterior); HTTP anónimo401, lector/ADMIN/alumno403 en GET privado y renovación, sin secreto en respuesta. |
|6 — Códigos separados | Rechazos humanos anteriores; HTTP400 para formato GRP válido y código docente real del fixture,404 para código estudiantil anterior y201 para vigente. No se creó un grupo real para este paso. |
|9 — Repetición/identidad/traslado | Replay guardado después de rotación y nuevo UUID de alumno ya vinculado no duplican; UUID ajeno/código cambiado/snapshot alterado409; código válido de otra institución rechaza consulta e ingreso409. |

Para traslado se creó solo un código sintético temporal en la institución alternativa
APROBADA y se eliminó exactamente esa fila propia al finalizar. No se generó ingreso,
se cambió usuario ni se dejó un código adicional. No acredita emisión humana de ese
código. Los perfiles student/zero/absent y sus dos recibos quedaron intactos.

**Balance10/10 guiones integrados cubiertos**, con límites explícitos: solo local,
Android de ensayo y base temporal66 migraciones; no iOS/carga/producción. Fallos
humanos de red son previos al POST, no pérdida de respuesta después de guardar.
Respuestas tardías entre cuentas y factor200% exacto corresponden a widgets, no
pruebas humanas medidas. Rate limiting429 del entrypoint principal no se acreditó.

No quedan suspensión/cupo reducido ni corteUSB activos. Código vigente revisión2;
archivo privado inicial conserva código anterior y contraseña actual. Siguiente:
consolidación de instituciones antes
de decidir commits coordinados; no hacer push/merge/despliegue ni tocar OV-1.

Regresión final posterior a ambos fixes: `flutter test --no-pub`893 aprobadas,
13 opt-in omitidas; `flutter analyze --no-pub` sin incidencias. Omitidas no equivalen
a nuevas pruebas reales aprobadas.93 dirigidas están incluidas en esas893, no se
suman como pruebas distintas. Backend1470/119 y16 C4+14 C3 corresponden al bloque
previo; hoy se añadieron19 HTTP/SQL finales, no se repitió Jest global backend.

Consolidación documental del cierre C4:16 documentos de entrada/acta/roadmap/relevo
de ambos repos comprobados,499 enlaces locales sin destinos ausentes. Sintaxis
de cinco helpers C4 correcta y diff de ambos repos sin errores de espacios.
Las notas fechadas inferiores/intermedias se conservan como historia, no ordenan
repetir guiones. No se creó commit, push, merge ni despliegue. Cierre institucional
general/selección de commits sigue separado del cierre de cobertura C4.

Consolidación posterior completada: Jest backend119 suites/1.470 aprobadas repetidas,
panel95/95 y sintaxis23 módulos, TypeScript sin emisión correcto. [Cierre local y
propuesta Git](CIERRE_INSTITUCIONES_LOCAL.md). Observaciones abiertas: JPEG original
no reproducido y CI Linux/Node24.14.1/npm11.11.0 pendiente; dry-run Windows24.11.1/
npm11.6.2 terminó0 con EBADENGINE, no instalación real. No resolverlo bajando engines.
Sin commit/push/merge/despliegue; siguiente revisión y autorización de entrega Git.

1. Propietario consulta sin generar por GET; primera emisión explícita.
2. Otras cuentas no pueden ver ni administrar código privado.
3. Copiar/compartir por gesto sin publicar el código en directorio.
4. Alumno consulta código válido y ve institución, aún sin vínculo.
5. Confirma ingreso, conserva rol, sin grupos y con perfil actualizado.
6. Código incorrecto/antiguo/grupo/docente no vincula ni expone datos.
7. Renovación invalida anterior; reintento incierto no renueva dos veces.
8. Cupo agotado/suspensión impiden ingreso; solicitud pendiente requiere cancelar.
9. Repetición/otra cuenta/otra institución no duplican ni trasladan vínculos.
10. Red, consulta/reintento, reapertura/cambio de cuenta y texto ampliado.

Cada guion puede tener varios pasos. Registrar resultados humanos y API/SQL por
separado, no convertir16 automáticas en10 humanas. Después cierre integrado local
de instituciones y commits coordinados; ranking institucional, producción y P5/D3
siguen como bloques separados.
