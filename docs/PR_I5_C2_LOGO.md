# PR-I5-C2 — Logo institucional

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

### Checkpoint del propietario

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
