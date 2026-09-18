# P4-C — Solicitud y aprobación de instituciones

Entrega local: 17 de septiembre de 2026. **No está desplegada.**

## Qué cambia

- Profesor solicita aprobación con datos institucionales y explicación de su vínculo.
- Puede buscar coincidencias y pedir invitación si el colegio ya existe.
- Solicitud pendiente no crea colegio, propietario, grupos ni acceso a estadísticas.
- ADMIN revisa desde el botón **Instituciones** del panel web: aprobar, rechazar,
  pedir información, suspender o reactivar, con respuesta pública al solicitante
  y notas privadas de revisión.
- Profesor consulta estado/motivo, corrige cuando procede y actualiza tras aprobarse.
- Transacciones y versiones evitan decisiones repetidas o concurrentes; se conserva
  un historial privado. Suspender no borra estudiantes ni su historial académico.
- Instituciones existentes quedan en revisión con transición de 30 días desde la
  migración. Aviso en dashboard y fecha en verificación; no se aprueban automáticamente.
- El nombre verificado y la baja institucional requieren intervención del equipo;
  no se permite renombrar libremente para hacerse pasar por otro colegio ni borrar
  el historial de aprobación con una eliminación en cascada.

Los datos aportados se verifican **manualmente**: no basta tener correo personal
confirmado ni marcar una casilla. No se incluyen documentos adjuntos todavía; se
coordinarán con almacenamiento privado 7F-C5 si hacen falta. No hay tutores, nuevos
audios, aprobación por pago ni cambios de precios.

## Cómo probar localmente

App: entrar como profesor demo → **Consultar verificación institucional** o
**Solicitar institución** → completar formulario y declaración → enviar → pendiente.
No debe aparecer propietario ni código de institución como resultado de enviarlo.

Panel: en el repo backend, `admin`, ejecutar `npm run demo`; abrir la dirección
mostrada, explorar demo → **Instituciones** → colegio ficticio → revisar y guardar
decisión. Demo web y demo móvil son independientes y nunca envían datos a Supabase.

Pruebas Flutter: `flutter analyze`, `flutter test` y
`flutter test test/institution_approval_test.dart test/teacher_institution_test.dart`.
Backend: guía `backend/INSTITUTION_APPROVAL.md`, pruebas Jest y PostgreSQL temporal.
Panel: pruebas de API/demo y de limpieza/seguridad del DOM. **Revisión visual de
navegador pendiente:** no había navegador conectado y el manejador de ventanas no
pudo conectarse. No afirmar prueba en Android/iOS real ni en Render.

## Siguiente: preparación y ensayo P5

Verificación local final: **502 pruebas Flutter aprobadas y 4 remotas omitidas**,
análisis sin avisos; **782 pruebas Jest, 11 PostgreSQL temporal y 65 del panel**
aprobadas. Compilación backend y sintaxis del panel verificadas. Estas cifras
corresponden al árbol local, incluidos los cambios previos conservados de Guardián.

1. Guardar P4-C sin mezclar otros cambios. Resolver primero la dependencia previa
   de Guardián antes de publicar: el schema de HEAD referencia `IntentoGuardian`,
   pero su modelo/migración seguían locales. No borrar esos cambios.
2. Confirmar entorno, respaldo, URL, cuenta ADMIN y cuentas de ensayo; revisar
   migraciones pendientes y avisar a instituciones existentes sobre transición.
3. Migrar/desplegar con autorización. Probar panel real → aprobación → profesor
   → grupos → alumno → prioridades → evidencia/tiempo, y suspensión/aislamiento.
4. Cerrar P5 con evidencia. Después retomar **7F-C3-D3**, la integración editorial
   real. La conexión institucional parcial no da por terminada D3.

## Commits (no ejecutados)

Flutter:

```powershell
cd "C:\Users\LENOVO 14ALC6\Desktop\SaberPLus\saber_plus"
git add README.md docs/ROADMAP_MOVIL.md docs/ETAPAS_PENDIENTES.md docs/PROFESOR_P4_C.md lib/app/router.dart lib/features/dashboard/presentation/teacher_dashboard_page.dart lib/features/institutions/data/institution_approval_repository.dart lib/features/institutions/domain/teacher_institution_models.dart lib/features/institutions/presentation/institution_approval_page.dart test/institution_approval_test.dart test/teacher_institution_test.dart
git diff --cached --stat
git commit -m "feat: solicitar aprobacion institucional desde Flutter"
```

Backend/panel:

```powershell
cd "C:\Users\LENOVO 14ALC6\Desktop\SaberPlus-Backend"
git add admin backend/src/institucion backend/src/anuncios backend/src/admin/admin.controller.ts backend/prisma/migrations/20260917130000_institution_approval backend/test/institution-approval-postgres.test.cjs backend/tool/test_editorial_postgres.mjs backend/INSTITUTION_APPROVAL.md
git add -p backend/prisma/schema.prisma
git diff --cached --stat
git diff --cached -- backend/prisma/schema.prisma
git commit -m "feat: aprobar instituciones desde el panel admin"
```

En el diff actual del schema: **y, y, y, n**. Aceptar los campos de `Institucion`,
la relación de `Usuario` y enum/modelo `SolicitudAltaInstitucion`; no incluir el
bloque previo `IntentoGuardian` en este commit. Si cambian los fragmentos, guiarse
por los nombres, no por la secuencia. No incluir `app.module.ts`, `src/guardian`,
su migración ni `probe_database.mjs` dentro de P4-C. **No hacer push/despliegue aún
si Guardián sigue incompleto en Git**; revisar y guardar ese trabajo separado y
comprobar compilación desde un checkout coherente antes del despliegue P5.
