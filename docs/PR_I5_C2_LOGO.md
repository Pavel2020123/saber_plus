# PR-I5-C2 — Logo institucional

## Cierre del guion local C2C — 14 de octubre de 2026

**6/6 casos HTTP/PostgreSQL y 8/8 casos humanos Android aprobados en el alcance
registrado.** Preparación de fixtures C1:15/15; regresión Flutter final41/41,
análisis sin incidencias y APK de ensayo corregida compilada/instalada por USB.
Migración del logo aplicada solo en bases temporales propias (64 migraciones).
No acredita despliegue Supabase/Render ni validación iOS.

| Caso humano | Resultado |
|---|---|
| 1. Selección/cancelación/vista previa | Aprobado con imagen admitida; archivo de3,29MiB rechazado por tamaño. |
| 2. Guardado/consulta/reapertura | Logo cuadrado conservado, visible para estudiante; lectura SQL confirmada. |
| 3. Reemplazo | Presentación, nombre y ubicación conservados; un evento por actualización. |
| 4. Permisos | Docente lector y estudiante sin controles de edición/eliminación. |
| 5. Guardado incierto | Error conserva selección y bloquea; consulta recupera. SQL mostró guardado: no se acredita fallo previo al POST ni su causa exacta. |
| 6. Conflicto | Segunda sesión cambia revisión4→5; intento obsoleto no sobrescribe; consultar conserva selección y permite guardar revisión6. |
| 7. Eliminación | Cancelar no escribe; confirmar elimina bytes/URL, perfil y directorio sin foto, URL anterior404. |
| 8. Salida | Seguir editando conserva; Salir descarta. Reapertura sin selección, sin foto publicada ni botón Guardar. |

Caso8 confirmado por usuario y SQL: revisión7, logoUrlnull,0 filas de logo,
1 LOGO_ACTUALIZADO y1 LOGO_ELIMINADO; presentación de segunda sesión intacta.
Salir no añadió escrituras.

### Checkpoint del propietario

**Actualizado15 de octubre:** [C3A/B solicitudes implementadas; sigue C3C](PR_I5_C3_SOLICITUDES.md),
después C4 código institucional privado. Contrato/permisos y separación docente
registrados en acta C3. El compañero continúa
su propio trabajo OV-1; este cierre no le transfiere tareas.
No repetir el guion C2C aprobado salvo regresión concreta. Al retomar verificar
vigencia de sesión local/USB; recrear solo los fixtures necesarios si expiró.
Cambios actuales de instituciones aún sin commit; decisión de Sabi guardada
separadamente en bbf4023, rama docs/ov1-sabi-resultado.

### Observaciones que no se dan por resueltas

- La captura JPEG pequeña original no se volvió a confirmar; vista previa aprobada
  con otra imagen. No se atribuye a permisos ni se afirma corregido ese archivo.
- Lockfile reparado con npm11.11.0 y dry-run aceptado en Windows/Node24.11.1;
  CI Linux/Node24.14.1 pendiente de nueva ejecución.
- Rediseño ventana por ventana y recorrido general al primer uso planificados
  para UI-F; no se implementan como parte de estas pruebas.
- Se mantiene la diferencia entre este guion local aprobado y preparación para
  lanzamiento; las observaciones anteriores deben revisarse antes de publicar.

## Cronología del ensayo (estados intermedios históricos)

## Estado intermedio del 14 de octubre (superado por cierre superior)

**Última confirmación: caso7 aprobado.** Usuario confirma logo eliminado en
perfil reabierto, listado y ficha estudiantil. SQL revisión7/URLnull/0 filas de
logo/1 eliminación y URL anterior404 ya comprobados. **Solo falta caso8:**
propietario selecciona sin guardar, Atrás/Seguir editando conserva selección;
después Atrás/Salir descarta, reabrir sin foto publicada y SQL sin escritura.
Caso8 parcial confirmado: propietario selecciona sin guardar, Atrás → Seguir
editando mantiene editor y foto en vista previa. Siguiente: Atrás → Salir,
reabrir editor, comprobar selección descartada/ningún logo publicado y leer SQL.

**Reanudado por aviso del usuario:** Docker/Android USB disponibles; API y panel
anteriores cerrados. Nueva sesión propia con64 migraciones, preparación de
fixtures C1 HTTP/PostgreSQL15/15, API43187 y panel4173 HTTP200, reverseUSB restaurado.
APK cuadrada ya instalada, no se reinstaló. Nueva autenticación propietaria y
selección sin guardar son el siguiente gesto; después preparar cambio de revisión
desde otra sesión para caso6. Casos1–5 conservan su evidencia, sin repetición humana.
La instrucción de esperar aviso inferior corresponde a la pausa ya finalizada.
Caso6 preparado: usuario confirma imagen en vista previa sin guardar. Segunda
sesión propietaria autenticada actualiza presentación por API, revisión4→5 y
logo sin cambio. Celular mantiene su revisión anterior; no consultar aún.
Siguiente: Guardar logo, esperar409, comprobar selección y bloqueo de reenvío.
No se ha confirmado todavía conflicto humano ni recuperación de este caso.
Caso6 parcial confirmado por usuario: intento de guardar muestra aviso de cambio
no confirmado, selección conservada y Guardar deshabilitado. SQL de solo lectura
confirma presentación externa exacta/revisión5,0 filas de logo y0 LOGO_ACTUALIZADO:
sin sobrescritura por intento obsoleto. No se capturó código HTTP del celular.
Siguiente: Consultar versión actual conserva borrador, habilita Guardar y muestra
versión publicada; después confirmar guardado recuperado. Caso6 sigue abierto.
Usuario informa que ya pulsó Guardar antes del siguiente mensaje. SQL verifica
guardado recuperado revisión6, WEBP512×512/13924bytes,1 LOGO_ACTUALIZADO y
presentación externa conservada. Falta aclaración humana de consulta previa/
borrador conservado y acuse de éxito; no atribuir esos gestos solo al resultado SQL.

**C2C en curso: seis casos HTTP/PostgreSQL aprobados y casos humanos1–7
aprobados en el alcance detallado abajo. Falta un caso humano:8.**
Caso6 aprobado: usuario confirma consulta previa, foto conservada, botón Guardar
habilitado y guardado exitoso. SQL6/1 auditoría/WEBP512×512 ya comprobado, texto
externo preservado. Siguiente caso7: abrir eliminación y cancelar sin borrar.
Baseline actual: revisión6, logo13924bytes y1 LOGO_ACTUALIZADO.
Caso7 parcial aprobado: usuario cancela eliminación y confirma logo conservado.
SQL propio: revisión6/logo13924bytes intactos,1 LOGO_ACTUALIZADO y0 LOGO_ELIMINADO.
Siguiente: abrir Eliminar logo y confirmar; esperar mensaje, icono predeterminado
y retirada de opción Eliminar. Después comprobar perfil/directorio/SQL y URL vieja.
Usuario confirma eliminación explícita: mensaje Logo eliminado, icono
predeterminado y desaparición de Eliminar logo. SQL revisión7/URLnull/0 filas
de logo/1 LOGO_ELIMINADO. HTTP con estudiante: detalle200 con logoUrlnull y
URL anterior versión6 devuelve404. Falta comprobación humana de perfil reabierto
y listado/detalle estudiantil sin foto para cerrar caso7; caso8 sigue pendiente.
El usuario confirmó las tres comprobaciones de recuperación del caso5:
Consultar versión actual conserva selección, habilita Guardar y muestra el logo
publicado. Caso5 cerrado como recuperación de guardado incierto; SQL había
confirmado revisión9/3 auditorías/10770bytes, así que no acredita ausencia de
escritura ni causa exacta del acuse perdido. No se pidió reenviar el mismo logo.

Próximo paso: **caso8, salida con selección pendiente**, según última confirmación
al inicio de esta sección. La secuencia de caso7 siguiente es histórica.

Trabajo interrumpido por el usuario. **No arrancar servicios hasta que avise.**
Al volver comprobar Docker/USB/API/panel y sesión propia: puede haber expirado.
Si hace falta base nueva, preparar fixtures y credenciales nuevas; reponer solo
el estado necesario de logo/presentación, sin repetir casos humanos1–5 ni guion
SQL completo por el simple reinicio. APK corregida ya instalada; no reinstalar
salvo que cambie el código o se verifique otra necesidad. Ambas ramas son
feat/instituciones-c2c. Evidencias anteriores se conservan como cronología.
Quedan sin confirmar la causa de rechazo de la captura pequeña original y CI
Linux del lockfile reparado; no convertir esos límites en resultados aprobados.

12 de octubre de 2026. **C2A backend y C2B Flutter implementadas. C2C integrado
pendiente.** C1C terminó sus diez pruebas humanas; no repetirlas como pendientes.

## Comportamiento y contrato

Propietario: Perfil institucional → Cambiar logo → galería → vista previa →
Guardar logo. Seleccionar o cancelar no publica. Eliminar exige confirmación.
Salir con selección permite «Seguir editando» o «Salir». El logo aparece en el
perfil, listado y detalle del directorio. Otros usuarios solo lo consultan.
La presentación escrita conserva su editor. Fallo/conflicto conserva selección,
bloquea reenvío y exige consultar la versión actual. Reintento de descarga disponible.

- PNG/JPEG/WEBP estático, máximo3 MiB/16 MP. Servidor valida firma y decodifica,
  orienta según EXIF, recorta al centro512×512, convierte a WEBP sin metadatos.
  Máximo almacenado200 KiB. Recorte centrado, no ajuste manual con desplazamiento.
- Tabla `InstitucionLogo`, un archivo por institución. Listados solo llevan URL.
  Bytes, URL, `revisionPerfil` compartida con descripción y auditoría cambian en
  una transacción. Cambios concurrentes no se sobrescriben silenciosamente.
- POST `/instituciones/me/logo`: multipart `logo` + `revision` decimal.
  DELETE misma ruta: JSON `{revision}`. Respuesta `{logoUrl, revision}`.
- GET `/instituciones/directorio/:id/logo/:revision`: JWT, aprobación y URL vigente;
  WEBP, `private, no-store`, `nosniff`. Antiguo/eliminado/suspendido devuelve404.
- PATCH heredado `/instituciones/me` no escribe `logoUrl`; datos/bienvenida
  también exigen propietario. Solo se aceptan rutas propias al cargar desde Flutter.
- RLS y revocación PUBLIC/anon/authenticated en tabla nueva; acceso por backend.
  No se importan URLs externas ni se borran archivos legados. El propietario
  puede volver a subir su logo antiguo para utilizarlo en el nuevo perfil.

Migración `20261012180000_institution_logo`: **no aplicada en esta entrega**.
No depende del disco efímero de Render. Sin despliegue remoto.

## Evidencia y límites

Backend:73 pruebas logo/perfil/directorio +6 HTTP multipart/guardas aprobadas;
Prisma simulado, decodificación real. Build correcto. npm audit de producción:
cero vulnerabilidades reportadas. Flutter:34 regresiones perfil/directorio
y11 pruebas nuevas en `test/institution_logo_test.dart` aprobadas (45 en total).
APK Android debug arm64 compilada; identidad `.i2validation` y minSdk24
comprobadas con aapt. No instalada en este incremento. Aviso de compatibilidad
futura KGP del plugin existente flutter_timezone; no impidió compilar.
`flutter analyze` sin incidencias. No suite completa ni ensayo físico C2.
iOS: permiso de fotos configurado; build/prueba iOS pendiente. Si Android cierra
la app durante la galería, volver a seleccionar: no hay publicación ni recuperación
automática de archivos perdidos. Las selecciones son borradores de esta pantalla.

## Relevo exacto: C2C

### Checkpoint inicial del propietario (histórico)

**14 de octubre, continuación vigente:** ambos repos en `feat/instituciones-c2c`,
base Flutter64ef962/backend5cbc7e1. Docker local y Android USB autorizados.
Sesión temporal propia nueva, 64 migraciones aplicadas exclusivamente allí,
API loopback43187. Preparación C1 HTTP/PostgreSQL **15/15 aprobada** y C2
HTTP/PostgreSQL **6/6 aprobada**, sin omisiones. Persistencia, permisos, RLS,
concurrencia, suspensión/eliminación y rollback acreditados por el guion real.
Backend compilado. Lockfile corregido con npm11.11.0; `npm ci --dry-run`
aceptado en Windows/Node24.11.1, no acredita CI Linux/Node24.14.1.
Instalación APK C2 por USB confirmada: `adb install -r` devolvió `Success`.
Usuario confirma editor abierto con «Consultar versión actual» y «Seleccionar
imagen». Caso humano1 parcial aprobado: abrir selección y volver atrás no guarda
ningún logo, confirmado por el usuario. Siguiente: elegir imagen y comprobar
vista previa sin guardar. API health200 verificada en la continuación anterior.
Ningún guardado humano del logo confirmado todavía.

Caso humano1 detectó fallo: al elegir foto se mostraba «No se puede mostrar esta
imagen». Archivo de galería inspeccionado solo para diagnóstico en memoria:
JPEG válido,1080×2400,880190 bytes; sharp decodifica. Causa exacta del fallo de
Image.memory en Android no acreditada por logs. Corrección cliente: validar y
decodificar antes de aceptar selección, miniatura PNG <=512px para previsualizar,
mantener original para servidor y rechazar entradas inválidas sin habilitar Guardar.
14 tests dirigidos del logo aprobados, regresión logo/perfil/directorio39/39,
análisis sin incidencias. Primer intento de regresión incluyó una ruta de test
inexistente; se corrigió el comando y la ejecución final39/39 pasó.
APK corregida compilada e instalada (`Success`), API health200. **Pendiente
confirmación humana de la misma foto tras actualización; caso1 aún no cerrado.**

Reanudación del14 de octubre tras cerrar VS Code: sesión anterior terminada.
Supervisor local nuevo con64 migraciones; preparación C1 HTTP/SQL15/15 aprobada
para recrear cuentas e institución (no se repitió C1 humano ni el guion C2).
API43187 y panel4173 iniciados, reverseUSB restaurado. Credenciales nuevas solo
en archivo temporal privado. Próximo paso: autenticar propietario en sesión nueva
y comprobar la misma foto en vista previa, sin guardar.
Segundo reinicio del14 por cierre accidental de VS Code: API/panel previos
inactivos, Docker y teléfono disponibles. Nueva sesión propia con64 migraciones,
fixtures C1 recreados15/15, API43187/panel4173 HTTP200 y reverseUSB restaurado.
Se requiere login con las nuevas credenciales temporales; sigue pendiente
confirmar la misma foto en la APK corregida. No repetir instalación ni C2 SQL.
Usuario reporta rechazo local al seleccionar captura/fotos. Inspección de tamaños
de caché: primera captura JPEG880190 bytes; otra2800629; última3445476 bytes,
superior al máximo3145728 (3 MiB). Este último rechazo es correcto por tamaño,
pero el mensaje genérico atribuía permisos. Cliente ahora distingue tamaño,
formato, resolución y animación;15 tests del logo/analyze aprobados. Esta última
mejora del mensaje aún no instalada. Persisten pendientes de confirmar vista
previa con selección admitida y causa del rechazo de la captura pequeña.
**Caso humano1 aprobado con otra imagen admitida:** usuario confirma cancelar
sin publicación y vista previa visible tras seleccionar una imagen menor.
Esto no acredita resuelto el rechazo de la captura pequeña original.
Precisión del usuario el14: la explicación extensa corresponde a un recorrido
general al primer uso de la app, a implementar al final en UI-F. Se retira guía
extensa del editor; conserva una indicación breve de formato/tamaño/resolución y
recorte. Mensajes específicos de rechazo conservados, pendientes de instalar.
Recorrido futuro omitible/repetible y adaptado al rol, planificado en el roadmap.
**Pendientes: siete casos humanos Android.** Sigue caso2: guardar selección,
consulta estudiantil/directorio y cierre/reapertura. No repetir C1 humano.
Caso2 parcial aprobado: usuario confirma «Logo institucional guardado» e imagen
en Logo publicado. Consulta SQL de solo lectura en sesión propia confirma
revisión5, WEBP512×512 de25166 bytes y un único LOGO_ACTUALIZADO para la institución.
Siguiente: salir del editor y volver a abrir perfil/editor para comprobar logo
conservado; después consulta desde estudiante/directorio. Caso2 aún en curso.
Usuario confirma reapertura por navegación desde panel/perfil: misma imagen
conservada en Logo publicado. Sigue cierre manual de la app/reapertura y después
consulta estudiantil/directorio. No atribuir todavía persistencia tras cierre
de proceso ni confirmación humana de la ficha estudiantil.
Usuario detecta imagen presentada como franja horizontal en perfil. Reproducción
widget: ListView imponía800×80 al logo previsto80×80; archivo SQL seguía512×512.
Corrección en InstitutionLogo: Align con factores1 libera ancho impuesto y
conserva tamaño propio también dentro de ListTile. Primer ajuste sin factores
falló en directorio; corregido. Regresión final logo/perfil/directorio41/41 y
análisis sin incidencias. Confirmación humana del cuadro en APK nueva pendiente.
Nueva reanudación del14: servicios anteriores inactivos. Base propia nueva64
migraciones, fixtures C1 recreados15/15, API43187/panel4173 y USB restaurados.
La base nueva no conserva el logo de la sesión temporal anterior; repetir solo
selección/guardado para comprobar corrección visual y continuar caso2.
APK de corrección cuadrada compilada, paquete.i2validation comprobado conaapt
e instalación USB `Success`. Mensajes de tamaño y nota breve también incluidos.
API y panel HTTP200; falta confirmar visualmente cuadro tras guardar en sesión nueva.
Usuario confirma corrección en celular: logo cuadrado en Perfil institucional,
sin franja horizontal tras guardar en sesión nueva. SQL de solo lectura confirma
revisión5, WEBP512×512/25166 bytes y una auditoría LOGO_ACTUALIZADO. Caso2 sigue
parcial: próximo cierre manual de app/reapertura y después consulta estudiantil.
Usuario confirma cierre manual/reapertura de app: logo guardado conservado.
Consulta HTTP con estudiante real del fixture: detalle de institución200 y
descarga WEBP200. No acredita aún su visualización humana en directorio.
Siguiente: login student@example.invalid, buscar «Institución de ensayo Perfil C1»
y comprobar logo cuadrado en listado/detalle para completar caso2.
Usuario confirma cuenta estudiantil: institución/foto/ubicación visibles y estado
de presentación vacía coherente con fixture C1. Caso2 aprobado: guardado publicado,
SQL, navegación, cierre/reapertura y consulta estudiantil. Caso3 preparado por API
propietaria local: presentación «Texto de ensayo C2: el logo cambia y este texto
debe conservarse.», revisión7, logo anterior preservado. Primer texto de fixture
tenía un acento mal codificado por la terminal; se corrigió por API al texto ASCII.
Siguiente: entrar como propietario, verificar texto, reemplazar logo por otra
imagen y comprobar conservación de presentación/nombre/ubicación. Seis casos
humanos aún pendientes (3–8); no cambiar el alcance por las preparaciones.
Caso3 aprobado: usuario confirma logo reemplazado y presentación/nombre
conservados. SQL propio verifica texto exacto, revisión8, departamento91/
municipio91001 intactos, WEBP512×512/13924 bytes y2 LOGO_ACTUALIZADO totales
(un evento por guardado). Siguiente caso4: docente lector
teacher-reader@example.invalid y estudiante sin edición/eliminación de logo.
Cinco casos humanos pendientes (4–8); no afirmar permisos físicos aún probados.
Caso4 parcial: usuario aclara que los botones Cambiar logo/editar no aparecen
en la cuenta teacher-reader@example.invalid. Sigue comprobación física con
student@example.invalid: ficha pública consultable y sin botones de edición
o eliminación. No cerrar caso4 hasta esa confirmación.
Caso4 aprobado: usuario confirma student@example.invalid con logo nuevo visible
y sin botones de edición/eliminación; docente lector ya confirmado. Cuatro
casos humanos pendientes (5–8). Siguiente caso5: propietario selecciona otra
imagen sin guardar; después retirar solo reverseUSB43187 para provocar fallo
de conexión, comprobar borrador/bloqueo, restaurar y consultar antes de reenviar.
Caso5 preparado: usuario confirma nueva imagen seleccionada sin guardar.
Al intentar retirar reverseUSB, adb no detecta ningún dispositivo y devuelve
device not found; no se confirmó retirada mediante comando. API mantiene
health200 desde PC. Siguiente: reconectar teléfono conservando la selección,
verificar autorización y retirar solo reverse43187 antes de pedir Guardar.
No se confirmó error de guardado, borrador ni bloqueo todavía.
USB reaparece autorizado (transport4); reverse --list vacío. Retirada explícita
devuelve listener not found porque el mapeo43187 ya desapareció con desconexión.
Estado offline esperado preparado sin apagar API; siguiente Guardar logo y
confirmar error/selección/bloqueo. No se inventa retirada exitosa del comando.
Caso5 parcial confirmado por usuario: error, vista previa conservada, Guardar
deshabilitado e indicación de consultar. Reverse43187 restaurado, APIhealth200.
SQL posterior muestra revisión9, WEBP10770bytes y3 LOGO_ACTUALIZADO totales;
hay actualización respecto de revisión8/2 auditorías de caso3. No afirmar intento
sin escritura ni causa exacta del acuse fallido. Primera aserción de estado intacto
falló; consulta siguiente corrigió campo de orden inexistente y reveló el estado.
Siguiente: consultar versión actual, comprobar borrador y habilitación de Guardar,
comparar logo publicado; no reenviar aún. Caso5 no cerrado hasta recuperación.
Sin despliegue remoto.
Los estados «no aplicada/no ejecutado» inferiores describen la entrega del12.

13 de octubre: C2A/B implementadas; migración C2 no aplicada, seis casos reales
HTTP/PostgreSQL y ocho humanos Android pendientes. Siguiente: sesión local nueva
y guion inferior. No hubo nuevas pruebas por esta revisión documental.
El propietario registra aquí cada caso; compañero en CHECKPOINT_OV1.md.
Consolidar el roadmap al entregar/integrar el bloque.

Tener ambos repositorios actualizados. Backend:
`C:\Users\LENOVO 14ALC6\Desktop\SaberPlus-Backend\backend`.
Flutter: `C:\Users\LENOVO 14ALC6\Desktop\SaberPLus\saber_plus`.
Verificar Git y servicios; no asumir que sigue activa una sesión anterior.

1. Docker local Linux disponible, `npm run build`; abrir **sesión nueva** con
   `node tool/local_ranking_validation.mjs`. Admite explícitamente migración logo.
   Si43187 está ocupado, identificar supervisor propio antes de detenerlo.
2. En otra terminal, `$env:SABERPLUS_LOCAL_SESSION` = ruta temporal emitida.
   Ejecutar una vez `node --test tool/test_institution_profile_local.cjs` en esa
   sesión fresca: prepara propietario/lector/estudiante y `profile-fixtures.json`.
3. `node --test tool/test_institution_logo_local.cjs`: seis casos de privacidad,
   persistencia/descarga, permisos/archivo falso, concurrencia, suspensión/eliminación
   y rollback real. Guion preparado y sintaxis comprobada; **no ejecutado aún**.
4. Instalar APK `.i2validation`, reverse43187, Android por USB desbloqueado,
   depuración e instalación habilitadas. Usar los cuatro defines públicos de C1;
   nunca incorporar `flutter-private.json` al APK. Credenciales ficticias en ese
   archivo de SU sesión; no imprimir contraseñas ni guardarlas en Git.
5. Ocho pruebas humanas; documentar cada confirmación en esta acta:
   1. Cancelar galería no cambia nada; seleccionar imagen y comprobar vista previa.
   2. Guardar, ver como estudiante/directorio y cerrar/reabrir conserva el logo.
   3. Reemplazar logo conserva presentación y resto del perfil.
   4. Docente lector/estudiante no pueden cambiar ni eliminar.
   5. Error de red conserva selección y bloquea; consulta recupera guardado.
   6. Segunda sesión cambia versión; conflicto no sobrescribe, consultar/comparar/guardar.
   7. Cancelar eliminación conserva; confirmar elimina en perfil y directorio.
   8. Salir con selección: seguir editando conserva, salir descarta sin publicar.

Cerrar C2 solo con evidencia SQL/HTTP y Android. Después siguen solicitudes
estudiantiles/avisos de PR-I5. Supabase/Render siguen separados del ensayo local.

## Entrega y publicación

Commit autorizado por el propietario: código C2 y documentación de relevo.
Consultar `git log -1 --oneline` en cada repositorio para obtener su hash.
Mensajes: Flutter: `feat: agregar editor de logo institucional`.
Backend: `feat: validar y persistir logos institucionales`.
El propietario realiza el push. El commit no acredita cierre de C2C.
