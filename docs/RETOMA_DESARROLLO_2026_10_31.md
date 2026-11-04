# Retoma después de la presentación

**Continuación posterior de la jornada:** [pruebas automatizadas H3 en Android USB](H3_PRUEBAS_USB_2026_10_31.md). Se verificaron originales, cambio de cuenta, revocación y recuperación; corregidos Reintentar y etiquetas con letra grande. El estado inicial descrito abajo se conserva como antecedente, no como instrucción de repetir las pruebas. Aceptación humana, integración Git, ESLint y despliegue siguen separados.

31 de octubre de 2026. Revisión documental y dirigida de código; no implica despliegue ni cierre de pruebas pendientes.

El propietario confirmó que la presentación salió bien. La prioridad temporal del 26-28/oct se conserva como antecedente; no ordena repetir la sustentación. La reanudación técnica propuesta es **conciliar cambios locales → completar deuda acotada ESLint y C5-H3 → diseño LIC-0 de propuesta #14 → implementación por entregas → ensayo integrado P5/staging**. No se inició automáticamente ninguna de esas implementaciones.

## Estado que no debemos perder

- C5-C2 cerrada localmente; H1/H2 históricas cerradas en su alcance backend. No reiniciar estos bloques.
- H3 sigue abierta: último checkpoint humano 1/4; continuar H3-2 cuenta/sesión, H3-3 revocación, H3-4 fallo/recuperación después de preparar una sesión temporal vigente. Las cifras automáticas de las actas no se repitieron en esta auditoría.
- Última acta ESLint: 229 errores y 116 advertencias, 135 suites/1786 pruebas históricas. Recontar al retomar; no presentar esas cifras como una ejecución nueva.
- Profesor/instituciones/prioridades ya tienen implementación local; P5, D3 y despliegues siguen abiertos. No reconstruir estas funciones para vender licencias.
- Cambios recientes de presentación, carpetas de práctica, actividades inglesas y diagnóstico permanecen locales; conciliar worktrees antes de integrar. OV-1 tiene responsable y entrega propia, no certificada por un checkpoint antiguo.
- Competencias/afirmaciones/evidencias y analítica descriptiva siguen pendientes en app/API; el prototipo de cuadernillos no es implementación Flutter.
- Cuadernillos tiene proyecto independiente y tres salidas probadas por el propietario con carga manual. No es el PDF/offline de C5 ni un banco importado a la app.

## Propuesta #14: viable, no implementada

[PR backend #14](https://github.com/Pavel2020123/SaberPlus-Backend/pull/14) fusionado, solo documentación; no instala licencias. Informe de lectura y viabilidad en [backend de desarrollo](<../../../SaberPlus-Backend/backend/docs/RETOMA_Y_VIABILIDAD_LICENCIAS_2026_10_31.md>).

Hallazgos: hay importador CSV, bcrypt, cambio obligatorio de contraseña inicial, cupos y transacción Serializable. Deben ampliarse, no rehacerse. El modelo actual vuelve a GRATIS cuando vence el plan institucional; #14 pide suspender acceso educativo de cuentas gestionadas, conservar progreso y permitir gestión docente limitada. Se necesitan asignaciones de licencia separadas de cuenta/vínculo, identificador institucional compatible con login actual por correo, contratos y renovación parcial. El panel docente web comparte API/identidad y no debe recibir permisos ADMIN. La eliminación completa sí forma parte de las secciones 12-14, con alcance institucional, confirmación, revocación y retención; no es un borrado indiscriminado.

Ruta sugerida: LIC-0 decisiones/contratos; LIC-1 backend de cupos/vigencia; LIC-2 CSV/credenciales; LIC-3 web y Flutter; LIC-4 bajas/supresión. Billing, becas y competencias en entregas independientes. Primera acción al regresar: conciliar código/ramas y evidencias existentes; no ejecutar directamente migraciones.

## Pagos y Prisma

Decisión confirmada: Wompi/ePayco no se usan en la app. Android prevé Google Play Billing, aún pendiente. Una pasarela web futura se elige aparte. Backend ya tiene servicios antiguos retirados y rutas 410; se aclararon comentarios del esquema, no se borraron tablas ni migraciones históricas. `PagoOrden` mantiene relaciones con cupones/referidos y requiere auditoría de datos/retención antes de retiro físico. No convertir ese legado en una implementación de Play por renombrarlo.

## Entorno y seguridad de la continuación

Flutter inicia esta revisión en HEAD `edf40cb`, rama anterior `fix/c5-c2-cierre-local`, con cambios propios sin commit. Rama documental actual `docs/retoma-licencias-20261031`; se conservó todo lo existente.

Backend con avances C5/H3: `C:/Users/LENOVO 14ALC6/Desktop/SaberPlus-Backend`, HEAD inicial `b67f067`, rama de revisión `chore/retoma-pagos-licencias-20261031`. La copia `Desktop/SaberPLus/SaberPlus-Backend` está en otro HEAD (`5e55b79`); no asumir sincronización. `ov1-backend-audit` figura prunable: revisar antes de usar. No se hizo pull, merge, push, commit, deploy, migración ni lectura de secretos. No se arrancaron Docker/servicios ni se tocó la USB/celular en esta revisión.

Esta revisión cubre documentos guía y código relacionado, no todas las actas históricas ni una auditoría de seguridad completa. Conserva los resultados históricos como tales.

Comprobación nueva: backend 3 suites/13 pruebas dirigidas aprobadas (pagos retirados, plan institucional, guard actual). Prisma válido con configuración ficticia local tras un primer intento sin DIRECT_URL; ninguna conexión/migración. Comparación de esquema sin comentarios confirma estructura idéntica. 322 enlaces Markdown revisados sin destinos faltantes y diff --check sin errores de espacios. No se ejecutaron suites globales, recuento ESLint ni pruebas Android en este turno.
