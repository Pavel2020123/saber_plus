# MA-1R-UX1 — Ocultar de mi lista y Deshacer

**18 de octubre de2026. Propuesta del propietario durante R4; pendiente de
implementación.** No cambia las pruebas/contratos actuales ni cierra R4.
[Inventario único](ETAPAS_PENDIENTES.md#ruta-vigente-del-equipo).
Espejo: `backend/docs/MA1R_UX1_OCULTAR_DESHACER.md` en SaberPlus-Backend.

## Experiencia solicitada

- Una X por elemento permite quitarlo de la lista personal para evitar acumulación.
- Aparece una barra inferior tipo Snackbar: **«Reporte ocultado · Deshacer»**,
  con progreso de **cinco segundos**.
- Deshacer durante esa ventana vuelve a mostrar el mismo reporte; no crea otro.
- Al terminar la ventana deja de verse en la lista normal. Se propone una vista
  **Ocultos** para recuperarlo después, evitando pérdida irreversible por un toque.

## Interpretación segura propuesta

La X significa **Ocultar de mi lista**, no borrar la incidencia de ADMIN ni
cancelar una investigación. El nombre visible/accesible debe explicar esa acción;
no usar «Eliminado definitivamente» si lo que se oculta es su presentación.
Un reporte pendiente oculto puede seguir siendo atendido por ADMIN.

Se conservan ID, contenido original, estado, autor autorizado, recibos, auditoría,
deduplicación, cuotas y agregados de cobertura. Deshacer o restaurar no reenvía,
reabre ni altera un reporte. Ocultarlo no permite volver a reportarlo como nuevo.
La baja de cuenta y la política de retención son procesos distintos, todavía sujetos
a los acuerdos de privacidad. Esta X no los sustituye.

## Alcance y orden propuestos

1. Terminar R4 con la interfaz actual; no introducir esta función durante el ensayo.
2. Entrega **MA-1R-UX1** posterior a R4: acordar contrato y añadir visibilidad
   personal persistente, idealmente por cuenta en backend para conservarla al
   cambiar dispositivo/reiniciar. No decidir schema/migración por este documento.
3. Probar X/Deshacer, expiración, restaurar, red/cierre/fondo, cuenta y permisos.
4. En UI-F, unificar apariencia, animación discreta, accesibilidad y barra de tiempo.
   La función debe existir y estar probada antes de beta, no solo dibujada.

La extensión a avisos u otros listados se evalúa por módulo y por acción reversible.
No aplicar automáticamente a cuentas, instituciones/vínculos/solicitudes, preguntas
publicadas, XP, certificados, insignias históricas o auditorías. No se elimina ni
reorganiza ninguna de esas funcionalidades como parte de esta propuesta.

## Decisiones y criterios para la implementación futura

- Definir filtros Normal/Ocultos, restauración posterior y tratamiento de un
  reporte oculto cuyo estado cambie. No asumir que ya existen notificaciones.
- Acordar cuándo confirmar ocultación en servidor y qué ocurre si se pulsa
  Deshacer durante una petición o se pierde la respuesta. No dar éxito ficticio;
  usar idempotencia/revisión cuando corresponda y no perder el elemento por fallo.
- Aislar acciones y temporizadores por cuenta/ID. Un resultado tardío de otra
  sesión no modifica la lista actual. Cubrir varios elementos ocultados seguidos.
- Cinco segundos es el comportamiento solicitado de la barra, no eliminación
  irreversible de datos. Definir fondo/reanudación y fin del plazo; restaurar
  desde Ocultos debe seguir disponible fuera de esos cinco segundos.
- Controles accesibles por tacto/teclado/lector y texto grande. La X debe tener
  nombre «Ocultar reporte de mi lista»; Deshacer no puede depender solo del color.
- Probar que ninguna acción cambia estado ADMIN, recibos, cuotas, cobertura,
  XP o banco; acceso solo a visibilidad de la cuenta propia.

No se implementaron botones, Snackbar, endpoints, tablas ni migraciones por esta
propuesta. No hubo pruebas funcionales nuevas ni cambios de servicios/Git remotos.
