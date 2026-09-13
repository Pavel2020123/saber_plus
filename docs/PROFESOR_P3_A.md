# Profesor P3-A — base de prioridades docentes

Actualización posterior: [P3-B](PROFESOR_P3_B.md) integra las pantallas y práctica;
la implementación local de P3 está completa y sigue P4. Este documento conserva
la entrega histórica P3-A y sus pruebas. Migración/despliegue real siguen pendientes.

Entrega local del 13 de septiembre de 2026. **P3-A implementada en backend;
P3-B (pantallas y práctica dirigida) sigue pendiente. P3 completa no está cerrada.**

## Qué se preparó

- Priorizar un tema completo o un subtema publicado para un grupo autorizado.
- Plazo de hasta 30 días, máximo diez prioridades activas por grupo.
- Meta: practicar cinco preguntas distintas, sin afirmar dominio académico.
- Snapshot de preguntas elegibles: lo añadido después no cambia la tarea.
- Creación idempotente, rechazo de duplicados activos y retiro sin borrar historial.
- Catálogo y reportes paginados; alumno solo ve lo propio, docente solo su alcance.
- Conteo desde asignación/ingreso hasta vencimiento/retiro; no cuenta repeticiones,
  respuestas previas ni futuras. Ingreso posterior al plazo: «No aplica».
- RLS y control del plan institucional existente; sin nuevas restricciones de
  pago para alumnos y sin cambios en límites comerciales.

No hay cambios visuales P3 en Flutter todavía. No se modificó Supabase ni se
desplegó Render. La migración se probó solo en PostgreSQL temporal aislado.

## Evidencia

Backend: 724 pruebas Jest en 71 suites; 11 pruebas en PostgreSQL desechable;
compilación y lint de esta entrega sin incidencias. Se verificaron consultas SQL,
concurrencia, ventanas en UTC, privacidad y retiro. HTTP con guards sustituidos
para contrato; falta login real y ensayo con teléfonos P5. La instancia temporal
se cerró y eliminó al terminar, sin tocar bases existentes.

No se volvió a ejecutar Flutter porque solo cambiaron estos documentos.

## Siguiente paso exacto: P3-B

1. Leer el contrato completo y las precauciones de migración en
   `C:\Users\LENOVO 14ALC6\Desktop\SaberPlus-Backend\backend\PROFESOR_P3_A.md`.
2. Integrar repositorios remoto/demo y proveedores cancelables ligados a sesión.
3. Profesor → grupos → selector por área/tema/subtema y plazo, listado, retiro
   confirmado y seguimiento paginado. Conservar UUID/cuerpo para reintentar.
4. Estudiante → prioridades propias, fechas, progreso y «No aplica»; acceso a
   práctica con el snapshot autorizado. Extender el inicio de práctica existente
   desde el backend, sin aceptar porcentajes ni claves del cliente. No abrir solo
   preguntas aleatorias de un tema cuyo catálogo pudo cambiar.
5. Pruebas de demo, permisos, pérdida de sesión/red, reintentos, retiro y tamaños
   pequeños/texto ampliado. No usar demo como respaldo de errores remotos.
6. Actualizar el roadmap sin marcar despliegue ni P5 como realizados.

Después siguen P4 (tiempo/evolución), P5 (integración real) y D3 (panel editorial).
Los 13 bloques consolidados de ETAPAS_PENDIENTES.md se mantienen.

## Commits y rutas

**Backend:** seguir los comandos de `backend/PROFESOR_P3_A.md`. El esquema tiene
también cambios anteriores de Guardián: usar `git add -p` y seleccionar solo P3-A.
No incluir `backend/src/app.module.ts`, `backend/tool/probe_database.mjs`, la
migración ni el código de Guardián por accidente. No ejecutar migraciones reales
sin revisar destino, respaldo y autorización.

**Flutter (documentación):**

```powershell
cd "C:\Users\LENOVO 14ALC6\Desktop\SaberPLus\saber_plus"
git add README.md docs/ETAPAS_PENDIENTES.md docs/ROADMAP_MOVIL.md docs/PROFESOR_P3_A.md
git commit -m "docs: registrar prioridades docentes P3-A y continuacion P3-B"
```
