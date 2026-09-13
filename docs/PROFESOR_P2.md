# Profesor P2 — ficha individual de evidencia

Entrega local del 12 de septiembre de 2026. Continúa P1; D3 sigue después de
P3, P4 y P5. No implica despliegue ni verificación con cuentas reales.

## Qué incorpora

Ruta de uso: **Profesor → Revisar seguimiento → Estudiantes → abrir estudiante
→ Ver temas y subtemas**. Disponible desde analítica detallada, según el plan.

- Ficha con nombre, grupos autorizados y ventana de fechas del informe.
- Filtro por las cinco áreas; desplegar área, tema y sus subtemas.
- Aciertos, errores, preguntas únicas, sesiones, días y última evidencia.
- Reutiliza reglas del diagnóstico del alumno: 5 preguntas por subtema,
  10 por tema, 2 sesiones y 2 días distintos; ventana de 90 días.
- Señala evidencia insuficiente, refuerzo, en proceso o fortaleza en lo evaluado.
  No inventa falencias en áreas sin respuestas ni concluye dominio de toda el área.
- Advierte si el informe es parcial o excluye repeticiones/contenido no utilizable.
- Demo explícita reutilizando estudiantes y evidencia de ejemplo; nunca se usa
  como respaldo de una petición real fallida.

## Seguridad y consistencia

- Nueva ruta protegida del backend. Ver `backend/PROFESOR_P2.md` en
  `C:\Users\LENOVO 14ALC6\Desktop\SaberPlus-Backend`.
- Profesor solo consulta sus alumnos asignados; responsables, su institución.
  Se verifica el plan detallado y se revalida la autorización antes de responder.
- Cliente valida identidad del estudiante solicitado, política, métricas y fechas.
- Peticiones cancelables y proveedor ligado a sesión/estudiante. Una respuesta
  anterior no sustituye datos de una nueva sesión. No se guarda la ficha en disco.
- Carga, acceso denegado, función no disponible, red y reintento son estados
  distintos de «no hay evidencia». No se muestran datos anteriores tras un error.
- El campo opcional `ultimaEvidencia` amplía el contrato compartido sin romper
  respuestas anteriores. La fecha se refiere a evidencia contabilizada, no al
  tiempo de uso o a la última repetición de una pregunta.

## Verificación

- Análisis Flutter sin incidencias.
- Suite completa Flutter: 445 pruebas aprobadas y 4 remotas omitidas.
- Suite completa backend: 691 pruebas aprobadas en 68 suites.
- Backend: 94 pruebas relacionadas aprobadas en 16 suites; compilación aprobada.
- Lint de los siete archivos TypeScript de esta entrega sin incidencias.

Pruebas en `test/teacher_student_evidence_test.dart`: ruta desde analítica,
filtro, validación de identidad/fechas, errores HTTP, cambio de sesión/cancelación,
rechazo de sesión estudiante, estados vacíos, reintento y texto al 200 % en 320 px.
Se vuelven a ejecutar las pruebas del diagnóstico compartido y las de P1.

```powershell
cd "C:\Users\LENOVO 14ALC6\Desktop\SaberPLus\saber_plus"
flutter analyze
flutter test test/teacher_student_evidence_test.dart test/learning_evidence_test.dart test/learning_evidence_page_test.dart test/teacher_detailed_analytics_test.dart test/teacher_p1_test.dart test/session_route_policy_test.dart
```

## Pendiente real y continuación

No se modificó Supabase, no hay migración nueva y no se desplegó en Render.
El servidor debe actualizarse para probar la ficha real; un 404 no prueba por sí
solo si falta la función o se retiró el acceso. Faltan teléfonos y ensayo integral
de autenticación, planes, grupos y datos reales en P5.

**Sigue P3:** temas priorizados por el profesor y seguimiento de cumplimiento.
Después P4 (tiempo/evolución), P5 (integración) y D3 (panel editorial real).

## Commits

Revisar lo preparado antes de confirmar; no incluir los cambios previos de Guardián.

```powershell
cd "C:\Users\LENOVO 14ALC6\Desktop\SaberPlus-Backend"
git add backend/PROFESOR_P2.md backend/src/institucion backend/src/diagnostico/learning-evidence.rules.ts backend/src/diagnostico/learning-evidence.rules.spec.ts
git commit -m "feat: agregar evidencia individual protegida para profesores P2"
```

```powershell
cd "C:\Users\LENOVO 14ALC6\Desktop\SaberPLus\saber_plus"
git add README.md docs lib test
git commit -m "feat: agregar ficha docente por temas y subtemas P2"
```
