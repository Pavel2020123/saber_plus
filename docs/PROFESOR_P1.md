# Profesor P1 — métricas, textos y navegación

Entrega local del 12 de septiembre de 2026. Forma parte del cierre docente
P1–P5, autorizado antes de D3. No equivale a la entrega completa del profesor.

## Cambios

- Analítica básica, detallada y alertas: denominador del avance limitado a
  subtemas publicados cuyo tema también esté publicado. El numerador usa la
  misma condición y solo completados. Se reutiliza el filtro editorial común.
- La consulta de progreso histórico permanece intacta para calcular actividad:
  archivar una lección no borra su registro ni simula que no se estudió.
  Un catálogo vacío mantiene un avance de 0, sin divisiones inválidas.
- Los campos numéricos de puntaje conservan compatibilidad con el contrato.
  App y exportaciones muestran «Sin datos»/«Sin resultados» cuando no hay
  simulacros; un resultado real de cero continúa mostrándose como cero.
- Se aclara qué mide la actividad remota. No se afirma que quien no sincronizó
  haya dejado de estudiar. El avance básico es acumulado; resultados/actividad
  básica usan la ventana de 30 días; el resumen detallado es acumulado.
- Inicio del profesor con accesos rápidos a seguimiento, grupos y equipo
  (este último según el rol). Usa las rutas y autorización existentes.
- Tarjetas de métricas con altura flexible y una o dos columnas según espacio
  y tamaño de texto. Pestañas detalladas desplazables y nombre del plan adaptable.
- Retirado el texto que anunciaba la administración docente como etapa futura.

## Verificación

Comprobaciones locales de esta entrega:

- 27 pruebas docentes Flutter aprobadas (incluidas 8 nuevas de P1).
- Suite completa Flutter: 430 pruebas aprobadas y 4 remotas omitidas.
- 53 pruebas institucionales backend aprobadas en 12 suites.
- Suite completa backend: 677 pruebas aprobadas en 66 suites.
- `flutter analyze` sin incidencias.
- Compilación del backend aprobada; lint de los 10 archivos TypeScript
  modificados/añadidos sin incidencias. No equivale a lint global de Guardián.

Las pruebas docentes Flutter cubren repositorios, pantallas y navegación.
`test/teacher_p1_test.dart` añade pantallas de 320 px con texto al 200 %, accesos
rápidos y diferencia entre cero real y ausencia de resultados.

El backend añade `progreso-publicado.spec.ts`: revisa filtros de numerador y
denominador en los tres servicios, actividad histórica y catálogo vacío. Las
pruebas usan dobles de Prisma: no son una prueba contra PostgreSQL real.
Los tests de reportes comprueban ausencia de resultados frente a cero en CSV.

## Límites y continuación

- Sin migración nueva, cambios de secretos, escrituras en Supabase ni despliegue
  a Render. Los cambios de Guardián ya presentes en el backend se conservan.
- El avance describe el catálogo publicado actual, no un currículo congelado:
  publicar o archivar contenido sí puede cambiarlo. Versionado permanece en C4/C6.
- El backend debe actualizarse antes de validar estos cálculos desde la app real.
- Faltan comprobaciones visuales en teléfono y pruebas integrales con cuentas
  reales (P5); las pruebas de widgets no sustituyen esa revisión.
- Sigue P2: seguimiento individual por área, tema y subtema, con evidencia
  suficiente y permisos. P3: prioridades del profesor; P4: tiempo/evolución;
  P5: integración y permisos. Después D3. Consultar ETAPAS_PENDIENTES.md.

## Comandos locales de comprobación

Flutter:

```powershell
cd "C:\Users\LENOVO 14ALC6\Desktop\SaberPLus\saber_plus"
flutter analyze
flutter test test/teacher_institution_test.dart test/teacher_basic_analytics_test.dart test/teacher_detailed_analytics_test.dart test/teacher_p1_test.dart
```

Backend (no migran ni escriben en la base):

```powershell
cd "C:\Users\LENOVO 14ALC6\Desktop\SaberPlus-Backend\backend"
npm test -- --runInBand --silent institucion
npm run build
```

## Commits de esta entrega

No se crean automáticamente. Revisar `git diff --cached` antes de confirmar
si ya había otros archivos preparados. El backend solo incluye `institucion/`:
no agregar por accidente los cambios preexistentes de Guardián.

```powershell
cd "C:\Users\LENOVO 14ALC6\Desktop\SaberPlus-Backend"
git add backend/src/institucion
git commit -m "fix: corregir metricas publicadas del profesor P1"
```

```powershell
cd "C:\Users\LENOVO 14ALC6\Desktop\SaberPLus\saber_plus"
git add README.md docs/ETAPAS_PENDIENTES.md docs/ROADMAP_MOVIL.md docs/TEACHER_FREE_PLAN.md docs/PROFESOR_P1.md lib/features/dashboard/presentation/teacher_dashboard_page.dart lib/features/institutions/presentation/teacher_basic_analytics_page.dart lib/features/institutions/presentation/teacher_detailed_analytics_page.dart lib/features/institutions/presentation/teacher_metrics_layout.dart test/teacher_p1_test.dart
git commit -m "feat: mejorar seguimiento y navegacion docente P1"
```
