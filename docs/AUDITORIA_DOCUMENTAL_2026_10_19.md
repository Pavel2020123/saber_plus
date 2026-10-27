# Actualización documental e integración del19 de octubre de2026

Revisión documental final:20 de octubre. Las integraciones funcionales descritas
ocurrieron el19; main volvió a comprobarse el20 antes de publicar esta actualización.

## Estado comprobado

- Instituciones T/C1–C4: integradas previamente por PR app #5/API #8
  (`e679c50`/`388bb18`), con cierre local y límites en
  [acta institucional](CIERRE_INSTITUCIONES_LOCAL.md).
- Reportes MA-1R/R1–R4: integrados por [app PR #6](https://github.com/Pavel2020123/saber_plus/pull/6)
  (`21757a1`) y [backend PR #9](https://github.com/Pavel2020123/SaberPlus-Backend/pull/9)
  (`eef0d40`). [Acta R4](MA1R_R4_VALIDACION_LOCAL.md):12/12 humanos,
  45/45 HTTP/PostgreSQL y regresiones documentadas.
- Backend: [CI del PR](https://github.com/Pavel2020123/SaberPlus-Backend/actions/runs/39321480923)
  y [CI de main funcional](https://github.com/Pavel2020123/SaberPlus-Backend/actions/runs/39321700998)
  aprobados. La integración documental posterior no cambia código funcional.
- QA-1 Flutter remoto sigue pendiente. Las pruebas locales anteriores no se
  presentan como nuevas pruebas físicas ni como un workflow remoto.
- OV-1 permanece en el frente del compañero; su rama no se integró ni se auditó
  funcionalmente en esta tarea. No se modificó CHECKPOINT_OV1.

## Qué se corrigió

Se revisó el inventario de185 Markdown existentes entre ambos repositorios:
130 de Flutter y55 de backend/panel. La búsqueda general localizó referencias
de estado, secuencia, Git y enlaces; la revisión semántica se concentró en las
guías activas, fichas afectadas y prompts. No es una auditoría nueva de todo el código.

1. README, roadmap, inventario, índices, historial y relevos reconocen la
   integración de instituciones y reportes y remiten a sus PR/evidencias.
2. Se retiraron instrucciones activas de repetir R4 o implementar reportes desde cero.
   Las actas fechadas conservan lo que se verificó en cada entrega.
3. Se sincronizaron cobertura, funcionalidades, alcance de noviembre, directorio,
   arquitectura y siguientes pasos de mapa/repaso/Sabi con el estado vigente.
4. El prompt de pruebas del propietario ahora parte del cierre R4 y del siguiente
   bloque recomendado C5; el compañero mantiene su prompt independiente OV-1.
5. La guía de Render corrige la ruta del backend, el trabajo mediante rama/PR y
   la distinción entre logo C2 en PostgreSQL y almacenamiento general C5.
6. La revisión automática de enlaces abarca los Markdown versionados de ambos
   repositorios. Valida destinos locales de enlaces inline; no certifica anclas,
   URLs externas, referencias sin enlace ni la vigencia de proveedores externos.

Verificación final del20:187 Markdown versionados, incluidos los dos documentos
de auditoría nuevos;1.044 destinos de enlaces locales comprobados y0 inexistentes.
Diff documental sin errores de whitespace en ambos repositorios.

## Orden restante

La fuente única del inventario es [ETAPAS_PENDIENTES](ETAPAS_PENDIENTES.md#ruta-vigente-del-equipo).
La [vista ordenada](ESTADO_Y_ORDEN_2026_10_17.md) conserva todos los bloques:

1. C5: preparación local de archivos generales, permisos, límites y metadatos.
2. Académico/profesor/panel: P5/D3 con autorización, C4/C6 editorial, ensayos MA-2/3,
   contratos y seis certificados; contenido durante el desarrollo.
3. Insignias anuales y perfiles PR-I3/4, TOP50 y todas las ganadas por juego/año.
4. Ranking institucional/territorial y ensayo social PR-I6/6-T/7.
5. Identidad/seguridad, monetización acordada, contenido y privacidad.
6. UI-F/Sabi: ventanas, azul S+, accesibilidad, bienvenida, animación y audio.
7. QA-1/DOC-1, entorno operativo, beta integral e iOS según disponibilidad.
8. Publicación autorizada y operación.

OV-1 avanza en paralelo. Seguridad, pruebas y documentación acompañan cada bloque.
UX1 Ocultar/Deshacer permanece propuesta separada pendiente de contrato/implementación;
las competiciones aplazadas conservan sus motores normales. No se agregan funciones nuevas.

## Uso por compañeros y sustentación

Con cambios propios guardados, actualizar main de ambos repositorios con
`git switch main` y `git pull --ff-only origin main`; si Git rechaza por cambios o
divergencia, revisar antes de continuar, sin reset ni force-push.
En la app, `flutter pub get` y `flutter run` permiten abrir la demo por defecto.
Los flujos reales requieren backend/base de ensayo activos y URLs/configuración
correctas. La integración en main no inicia servicios, crea cuentas ni aplica
migraciones remotas. Para pruebas físicas usar el [procedimiento local](RELEVO_PRUEBAS_LOCALES.md)
con una sesión vigente; no copiar secretos por Git ni reutilizar sesiones caducadas.

La actualización documental se entrega en `docs/cierre-ma1r-main-20261019`, mediante
PR por repositorio. No se cambiaron código funcional, dependencias, migraciones ni
reglas de negocio; no se operó Supabase/Render ni se desplegó.
