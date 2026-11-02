# C5-D — integración y operación de archivos editoriales

## Actualización vigente · 2/nov/2026

El texto de auditoría que sigue describe la base del 1/nov, no el estado final. El adaptador Supabase privado ya está implementado y se ensayó con Storage oficial ejecutado localmente: los logs anteriores registran 99/99 casos integrados y cinco escenarios Android. Hay recuperación de bytes con identidad/hash exactos, respaldo local, auditoría paginada de metadatos y limpieza restringida a retirados sin revocación. No se añadieron endpoints públicos ni se activó producción.

Se retomaron API y panel con una base temporal nueva el 2/nov: login sintético HTTP201, panel HTTP200, USB autorizada y reverse43187. La batería repetida incluyendo copia local → Supabase pasó 99/99; regresión editorial 242/242 y CLI7/7. La reinstalación del APK normal de pruebas terminó con `Success` y se lanzó sin modificar la app principal. El espacio disponible ya no es el bloqueo de 1,4GB registrado abajo. Los cinco escenarios Android sobre Supabase corresponden al 1/nov y no se atribuyen al reinicio del 2/nov.

La política privada de 72 horas y los PDF exportados siguen separados. [Operación, límites e instrucciones de recuperación](<../../../SaberPlus-Backend/backend/docs/C5_D_OPERACION_LOCAL.md>). El inventario se basa en PostgreSQL, no lista objetos huérfanos del bucket, y no los elimina. Implementación y evidencia locales consolidadas en backend `5c2d58e` y `fbdbb6d`; [entrega preparada para revisión por PR](<../../../SaberPlus-Backend/backend/docs/C5_D_ENTREGA_PR.md>). Esto cierra el objetivo local editorial, no producción ni C5 global. No se hizo push, merge ni despliegue.

1/nov/2026. Objetivo activo solicitado por el propietario después del cierre local de [C5-P3](C5_P3_CACHE_PRIVADA.md). Este documento no acredita implementación, pruebas ni activación del proveedor persistente.

## Auditoría inicial confirmada

- Backend `EditorialFileStore` ya abstrae put/read/remove. El único adaptador implementado es `LocalEditorialFileStore`, cuya raíz se resuelve a `.tmp/editorial-files` desde el directorio de ejecución. No acredita persistencia en un despliegue.
- `ArchivoEditorial` y los recibos/idempotencia permanecen en PostgreSQL; permisos, publicación y revocación se comprueban en el servicio. No exponer el proveedor directamente al cliente ni modificar referencias estables para incorporar credenciales.
- La documentación de C5-A/B prevé Supabase Storage, pero aún exige elegir/configurar el proveedor. No se ha encontrado un adaptador Supabase, bucket ni configuración de ese proveedor en el código editorial inspeccionado. No se inspeccionaron secretos ni cuentas remotas.
- La política privada72h y los PDF exportables conservan contratos separados. No repetir H3/PDF/P3 como desarrollo nuevo ni atribuir sus resultados anteriores al futuro proveedor.
- Ramas nuevas `feat/c5-d-storage-operations` en ambos repositorios, desde la entrega P3. Cambios ajenos de presentación/otras tareas conservados.

## Secuencia de trabajo del objetivo

1. Confirmar proveedor: Supabase Storage está previsto, no se asume una contratación o configuración remota.
2. Implementar el adaptador y configuración segura dentro de la abstracción existente, sin reconstruir los consumidores. Pruebas locales de persistencia, límites, fallos, idempotencia, concurrencia y permisos.
3. Definir y probar recuperación/conciliación, respaldos y limpieza conservadora con inventario y modo de diagnóstico. No eliminar archivos o datos reales por aproximación.
4. Repetir el recorrido integrado panel → publicación → app → PDF → caché privada/revocación sobre el proveedor de ensayo, con fixtures propios. Android USB si está disponible. Registrar pruebas omitidas o límites sin declararlos aprobados.
5. Documentar configuración, operación, reversión y requisitos de autorización para despliegue. Aislar commits y preparar la entrega para PR, sin push ni crear cambios remotos por esta solicitud.

## Fronteras y decisiones

Proveedor confirmado por el propietario el1/nov/2026: **Supabase Storage privado**, con implementación y pruebas locales. La confirmación resuelve la dependencia anterior, pero no autoriza buckets remotos, gastos, credenciales reales ni despliegue. Se retoma el objetivo completo, no se considera terminado por resolver esta elección.

Autorización de este objetivo: implementación y pruebas locales; no despliegues, migraciones remotas, gastos, contratación, buckets en cuentas reales, push o merge a main. Las fotos de perfil y evidencias institucionales requieren reglas propias y siguen fuera de este alcance editorial: este objetivo no cierra por sí solo todo C5 global.

Regresión previa al adaptador:13 suites/192 pruebas backend editoriales aprobadas, ninguna omitida. [Auditoría y contratos existentes](<../../../SaberPlus-Backend/backend/docs/C5_D_AUDITORIA_INICIAL.md>). No son pruebas de Supabase ni de persistencia remota.

La elección del proveedor ya está resuelta. [Adaptador Supabase en desarrollo y evidencia local](<../../../SaberPlus-Backend/backend/docs/C5_D_SUPABASE_STORAGE.md>): regresión14 suites/222 pruebas y30 casos dirigidos del adaptador con un doble de API. No equivalen a Supabase real ni a un ensayo Android sobre ese proveedor.

El objetivo no está completado. Para el siguiente ensayo real desechable se solicitó liberar espacio en C:, que quedó cerca de1,4GB tras descargar la imagen oficial. No se borraron archivos personales ni PDFs, no se accedió a credenciales remotas y todavía faltan recuperación/operación y el flujo integrado sobre el nuevo proveedor.
