# Instituciones — cierre técnico local y entrega

Actualizado:17 de octubre de2026. Alcance del propietario, separado de OV-1.
**Bloque local consolidado e integrado a main por PR app #5/backend #8.**
Merge app `e679c50`, backend `388bb18`. CI backend del PR y main aprobados;
Flutter analyze limpio y102 pruebas dirigidas aprobadas en la entrega posterior.
[Enlaces y evidencia actual](ESTADO_Y_ORDEN_2026_10_17.md). QA-1 Flutter remoto pendiente.
Las observaciones de CI de los párrafos históricos inferiores quedan resueltas
por esta comprobación; no se resuelve por ello JPEG original ni producción.
No equivale a producción, P5/D3 ni cierre de ranking institucional/ensayo social.

## Evidencia por entrega

| Entrega | Evidencia conservada | Acta |
|---|---|---|
| Directorio y territorio | Búsqueda, filtros, aprobación/estados y ensayo territorial local; no volver a ejecutar por instrucciones históricas. | [Directorio](PR_I5_DIRECTORIO.md), [territorio](PR_I5_T_TERRITORIO.md). |
| C1 — Presentación |15 HTTP/PostgreSQL,3 Flutter/API y10 pruebas humanas locales. | [Perfil](PR_I5_C_PERFIL.md). |
| C2 — Logo |6 HTTP/PostgreSQL y8 humanas; selección, persistencia, permisos, conflicto, borrador y eliminación. | [Logo y observaciones](PR_I5_C2_LOGO.md). |
| C3 — Solicitudes/avisos |14 HTTP/PostgreSQL y10 humanas locales; pendiente/cancelación/decisión/paginación/red/cuentas. | [Solicitudes](PR_I5_C3_SOLICITUDES.md). |
| C4 — Código privado |16 HTTP/SQL iniciales,19 complementarias finales y10 guiones integrados cubiertos con Android/API/SQL. **No son10 pruebas solo manuales.** | [Código y límites](PR_I5_C4_CODIGO.md). |

Los contadores de cada acta describen entregas distintas; no sumarlos como una
única suite ni convertir pruebas automáticas en confirmaciones humanas nuevas.

## Regresión final de consolidación

- Flutter:893 aprobadas/13 opt-in omitidas, `flutter test --no-pub`.
- Flutter: `flutter analyze --no-pub`, sin incidencias.93 dirigidas están incluidas
  en893, no son adicionales.
- Backend:119 suites/1.470 aprobadas, `npm test -- --runInBand`, repetida al consolidar.
- Panel:95/95, `npm test`; `npm run check`,23 módulos sintácticamente correctos.
- TypeScript: `node node_modules/typescript/bin/tsc --noEmit`, correcto.
- Migraciones C3/C4 aplicadas por harness solo en base temporal propia,66 migraciones.
  No se volvió a migrar ni desplegar ningún entorno remoto durante el cierre.

Regresión no es auditoría exhaustiva de todo el producto ni ensayo de carga/iOS.
Las13 omitidas siguen pendientes de sus entornos/defines, no están aprobadas.

## Condiciones preservadas y límites

- Solicitudes de estudiantes no crean profesores ni membresías docentes. Ingreso
  por código conserva ESTUDIANTE y no añade grupos ni permite traslados automáticos.
- Código estudiantil separado de grupo/docente; solo propietario vigente puede
  gestionarlo. Repetición y renovaciones auditadas/idempotentes en alcance probado.
- Sesión6fFUQb terminó las comprobaciones sin suspensión ni cupo reducido: APROBADA,
  límite original null, USB restaurado. Zero/absent vinculados y student sin vínculo.
  Es una sesión efímera: comprobar vigencia antes de usarla, no esperar datos permanentes.
- Código en archivo temporal inicial es anterior a renovación; contraseña solo de
  esa sesión. No copiar credenciales, códigos, tokens o archivos privados a Git/APK.
- Fallos humanos de red C3/C4 se provocaron antes del POST; no prueban acuse perdido
  después del commit. Reconciliación posterior a guardado tiene evidencia automática
  separada.429 del entrypoint principal no se validó con el harness alternativo.
- Logo: captura JPEG pequeña original pendiente de reproducción; otra imagen sí
  quedó aprobada. No afirmar causa ni corrección de aquel archivo.

## Dependencias y entorno: observación abierta

`backend/package-lock.json` ya tenía cambios al comenzar este cierre: dos registros
opcionales emnapi y metadatos peer, sin cambio en package.json. Se conserva el diff;
no se descarta ni mezcla silenciosamente con funcionalidad institucional.

`npm ci --dry-run --include=dev --ignore-scripts --no-audit --no-fund` terminó0 en
Windows con Node24.11.1/npm11.6.2. Hubo EBADENGINE: el proyecto fija Node24.14.1 y
packageManager npm11.11.0. Este dry-run no instala/reinstala ni ejecuta scripts,
no es prueba Linux/CI y no demuestra instalación con las versiones fijadas.
Revisar CI en esa plataforma/versión antes de integrar/publicar. No bajar las
versiones del proyecto ni desactivar controles para ocultar el aviso.

## Antecedente: commits locales autorizados — 17 de octubre, antes del PR

La entrega se preparó en `feat/instituciones-c2c`. Commits creados con autorización
del propietario: app `6bab6be`, backend `7ba93d7` y lockfile `bfce42e`.
En esta auditoría documental HEAD coincide con las referencias locales origin
de esa rama en ambos clones. No se consultó GitHub para confirmar PR, CI o merge;
no se hizo push, merge ni despliegue durante la auditoría.

| Repo y ruta PowerShell | Mensaje del commit creado | Alcance |
|---|---|---|
| Flutter: `C:\Users\LENOVO 14ALC6\Desktop\SaberPLus\saber_plus` | `feat: completar solicitudes y codigo institucional estudiantil` | Cambios institucionales C2/C3/C4, permisos/menús, pruebas y actas/roadmap/relevo actualizados. |
| Backend: `C:\Users\LENOVO 14ALC6\Desktop\SaberPlus-Backend` | `feat: completar ingreso estudiantil seguro a instituciones` | Endpoints C3/C4, DTO/servicios/pruebas, registro de módulo/limitador, schema y sus dos migraciones, helpers locales y documentación. |
| Backend, commit separado bfce42e | `chore: normalizar lockfile de dependencias opcionales` | Solo package-lock.json; no autorizar cambios de dependencias ni afirmar CI aprobado. |

No usar `git add .`, `commit -a` ni restaurar archivos por limpiar el árbol. Revisar
`git diff`, `git diff --cached` y cada ruta; no incluir OV-1 ni archivos de sesión.
Schema/módulo contienen C3 y C4 juntos: el commit backend debe ser coherente, no
separarlos con selección arbitraria de hunks. Entrega: un commit funcional
coordinado por repo más lockfile separado. Consultar hashes con
`git log -3 --oneline` en cada repo; los mensajes de la tabla identifican esta entrega.

## Cuándo repetiremos pruebas fuera del PC

1. **Durante desarrollo:** seguir unitarias/regresión local y pruebas físicas del
   cambio. No posponer errores conocidos hasta el lanzamiento.
2. **Staging, con autorización de P5 y después D3:** entorno real de ensayo con
   configuración de producción, migraciones, archivos persistentes/C5, CORS,
   sesiones/cuentas/roles y panel→API→app. Usar cuentas/contenido ficticios autorizados,
   respaldo y plan de recuperación. Despliegues requieren permiso separado.
3. **UI-F:** recorrido ventana por ventana, azul S+, componentes/estados,
   accesibilidad y bienvenida, tras funciones/integraciones y antes de beta/capturas.
4. **8F/8G, recta final:** seguridad/rendimiento, regresión y recorridos críticos en
   beta/staging, varios dispositivos y red/cierres/cuentas. No repetir a mano cada
   prueba unitaria; automatización y escenarios críticos cumplen funciones distintas.
5. **Producción autorizada:** comprobación breve y controlada después del despliegue.
   No ensayos destructivos, carga ni datos ficticios masivos en producción sin permiso.

Siguiente del propietario: guardar/publicar por separado la documentación pendiente
y consultar el siguiente bloque vigente, C5; MA-1R ya está integrado según el
[orden del 17](ESTADO_Y_ORDEN_2026_10_17.md) y el [roadmap](ETAPAS_PENDIENTES.md#ruta-vigente-del-equipo).
P5/D3 continúan pausadas; OV-1 sigue con el compañero. No abrir automáticamente
rankings, insignias, monetización, diseño final o servicios remotos por este cierre.
