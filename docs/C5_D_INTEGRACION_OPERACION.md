# C5-D — integración y operación de archivos editoriales

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

Pendiente de respuesta: confirmar Supabase Storage privado como proveedor de implementación o indicar el proveedor elegido. La elección afecta el adaptador, protocolo y ensayo integrado; no sustituirla por una implementación distinta sin confirmación.

Autorización de este objetivo: implementación y pruebas locales; no despliegues, migraciones remotas, gastos, contratación, buckets en cuentas reales, push o merge a main. Las fotos de perfil y evidencias institucionales requieren reglas propias y siguen fuera de este alcance editorial: este objetivo no cierra por sí solo todo C5 global.

Regresión previa al adaptador:13 suites/192 pruebas backend editoriales aprobadas, ninguna omitida. [Auditoría y contratos existentes](<../../../SaberPlus-Backend/backend/docs/C5_D_AUDITORIA_INICIAL.md>). No son pruebas de Supabase ni de persistencia remota.

El objetivo permanece activo, no completado. No hay pruebas nuevas del proveedor ni credenciales remotas verificadas en esta auditoría.
