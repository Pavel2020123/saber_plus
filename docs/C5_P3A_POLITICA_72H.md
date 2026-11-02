# C5-P3-A — política de acceso privado de 72 horas

**Continuación:** [implementación C5-P3 y validación integrada](C5_P3_CACHE_PRIVADA.md). El estado sin caché descrito abajo corresponde a la base P3-A, no a la implementación posterior.

1/nov/2026. Decisión explícita del propietario:72 horas desde validación exitosa con backend; al vencer, revalidar; revocación/suspensión confirmada bloquea inmediatamente. PDF exportados excluidos. Reloj manual no puede extender el plazo y contenido local debe protegerse.

## Implementación acotada de esta entrega

`lib/core/media/private_offline_access_policy.dart`: motor puro de permisos, **todavía sin conectar a la caché/servidor/UI**. No persiste imágenes ni texto privado en disco y no habilita acceso offline nuevo.

- Cuenta y contexto exactos; límite72h, denegación en el instante del vencimiento.
- Ancla monotónica al inicio de la solicitud, conservadora ante respuestas lentas; no usa el reloj calendario. Adaptador nativo real pendiente.
- Nonce aleatorio256bits por validación; rechaza concesión antigua/repetida, de otra cuenta/contexto o de más de72h.
- Revocación/suspensión borran permisos en memoria antes de cualquier operación asíncrona; invalidan respuestas tardías. Logout/cambio de cuenta tampoco conservan derechos.
- Reinicio de política/proceso sin estado protegido, cambio de arranque o retroceso monotónico exigen revalidación. No se reconstruye tiempo seguro con fecha manual.
- La consulta de una copia y los reintentos fallidos no renuevan el plazo.

Backend añade `private-offline-policy.ts`, constructor puro del formato temporal72h: **no es endpoint ni verificador de permisos**. Debe llamarse tras validación real de propietario/contexto/recursos en P3-B.

## Seguridad pendiente antes de activar

Manifiesto autorizado por backend, integración de suspensión/revocación real, reloj monotónico nativo con continuidad de arranque, persistencia cifrada/autenticada y claves de plataforma, lectura/visores invalidables y pruebas Android. No modificar el `no-store` actual ni permitir fallback offline ante denegación confirmada. No ampliar el modelo de cuentas suspendidas de la propuesta #14 por aproximación.

[Contrato backend actualizado y fuentes oficiales](<../../../SaberPlus-Backend/backend/docs/C5_P3A_CONTRATO_CACHE_PRIVADA.md>). No se declara terminada la caché privada ni protección cifrada por haber probado el motor de decisiones. Los PDF actuales y sus repositorios no cambian.

## Validación de esta base

29/29 Flutter:15 casos nuevos de política más14 de regresión PDF/descargas. Análisis de motor/tests sin incidencias. Backend17/17 (6 política temporal,11 PDF), ESLint dirigido y `npx nest build` aprobados. Hot reload confirmado en SaberPlus Pruebas; no acredita escenarios Android de caché, cifrado, reinicio o reloj nativo que aún no existen. No se esperaron72 horas reales: los casos de vencimiento usan muestras monotónicas controladas.

Se agregó nonce por intento y seguimiento de la última muestra observada para que ni una concesión vieja ni un retroceso monotónico puedan renovar/extender derechos. El motor no contiene un serializador de concesiones a disco; no restaura datos sin protección.
