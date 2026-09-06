# 7F-C2-B1 — Base del catálogo académico

Entrega de backend, sin cambios de pantallas Flutter. Organiza el futuro panel
privado mediante `Área > Tema > Subtema`; las preguntas pertenecen a un subtema
y la lección se guarda en ese mismo subtema.

## Terminado localmente

- Cinco áreas ICFES estables y consultas administrativas paginadas de temas y
  subtemas, con estados, conteos y señalización del `Banco General` heredado.
- Creación en borrador, nombres normalizados y detección de duplicados dentro
  del mismo ámbito, incluso si el registro está archivado.
- Clasificación específica obligatoria en preguntas, lecciones e interactivos.
- La carga rápida ya no crea `Banco General`; exige un subtema del área elegida.
- Validación al publicar y en la vista previa opcional Excel/ZIP.
- Conservación del contenido previo, sin reclasificarlo ni borrar historial.

Contrato detallado: `backend/docs/ACADEMIC_CATALOG.md` del repositorio oficial
`SaberPlus-Backend`. Solo el rol editorial ADMIN puede usarlo. Todavía no hay
un formulario web nuevo ni cambios visibles en la app.

## Siguientes entregas

1. **7F-C2-B2:** diagnóstico por resultados acumulados y evidencia suficiente;
   no etiquetar una falencia por una sola respuesta incorrecta.
2. **7F-C3:** panel web con formularios, edición de nombres, revisión del legado,
   imágenes, vista previa, duplicados y publicación.
3. **7F-C4:** versión del catálogo y sincronización con Flutter/Drift.
4. **7F-C5:** recursos en Supabase Storage.
5. **7F-C6:** auditoría, historial y restauración.

La comprobación integral desde teléfono **7F-B3-B** sigue pendiente, así como
el despliegue y pruebas reales de Guardián. No se realizaron escrituras en
Supabase, migraciones ni despliegues durante 7F-C2-B1. No se necesitan audios.

Verificación local: 52 suites y 258 pruebas del backend aprobadas;
`npm run build` completado. Las pruebas de esta entrega no usan la base real;
la concurrencia y el flujo con cuentas ADMIN se comprobarán en staging.

## Commits separados

Backend, solo los cambios de catálogo de esta entrega:

```powershell
cd "C:\Users\LENOVO 14ALC6\Desktop\SaberPlus-Backend"
git add backend/src/admin backend/docs/ACADEMIC_CATALOG.md
git commit -m "feat: organizar catalogo academico por area tema y subtema"
```

Flutter, seguimiento de etapas:

```powershell
cd "C:\Users\LENOVO 14ALC6\Desktop\SaberPLus\saber_plus"
git add README.md docs/ROADMAP_MOVIL.md docs/ACADEMIC_CATALOG.md
git commit -m "docs: registrar etapa 7F-C2-B1 y siguientes entregas"
```

Los cambios previos de Guardián en Prisma, `app.module.ts`, `src/guardian` y
`tool/probe_database.mjs` no forman parte de estos comandos. Revisar `git status`
antes del commit. Esta entrega no crea commits ni hace push automáticamente.
