# 7F-C2-B2 — Diagnóstico por temas y subtemas

## Entrega

Pantalla `Progreso > Ver diagnóstico por temas`, también accesible al terminar
el diagnóstico inicial. Consulta `GET /diagnostico-evidencia` con la sesión real.
Presenta área, tema, subtemas, preguntas distintas, aciertos, sesiones, días y
estado de evidencia. Las conclusiones provienen del backend; Flutter valida el
contrato y no inventa métricas cuando falla la consulta.

Regla inicial orientativa, no validación psicométrica:

- Últimos 90 días. Primera respuesta calificada por pregunta dentro de esa ventana.
- Mínimo 5 preguntas distintas por subtema, 10 por tema; en ambos casos al menos
  2 sesiones y 2 días diferentes (hora de Colombia).
- Con evidencia suficiente: menos de 60% → conviene reforzar, 60–menos de 80% →
  en proceso, desde 80% → fortaleza en lo evaluado.
- Sin mínimos suficientes o con historial truncado: evidencia insuficiente.
- Repetir preguntas sirve para practicar, pero no suma evidencia ni reemplaza
  la primera respuesta. La evolución requiere responder preguntas nuevas.
- Las conclusiones solo cubren lo evaluado, no todo el tema ni la materia.

No se usa XP o tiempo de lectura como prueba de conocimiento. La fuente es el
historial calificado existente de diagnóstico, práctica y simulacros. Los juegos
con historial propio no se incorporaron a este análisis. Contenido genérico,
archivado o sin clasificación coherente queda excluido. El historial no se borra.

La muestra inicial por área mantiene su contrato; ahora su cuaderno se titula
“Errores para revisar”, no se presenta como falencias confirmadas por una pregunta.
El plan semanal y el algoritmo del repaso existente no se recalibran con esta
entrega; esta pantalla es un informe explicable, no una modificación silenciosa
de todas las recomendaciones anteriores.

## Cómo probar

```powershell
cd "C:\Users\LENOVO 14ALC6\Desktop\SaberPLus\saber_plus"
flutter run
```

Entrar en demo como estudiante y abrir Progreso, “Ver diagnóstico por temas”.
Expandir Proporcionalidad: Regla de tres muestra refuerzo y Razones/proporciones
muestra fortaleza. Gramática contiene un único error y muestra evidencia
insuficiente. Todo se identifica explícitamente como demostración, sin persistir
ni mezclar esos ejemplos con resultados reales.

El modo real requiere desplegar el backend nuevo y contar con respuestas
calificadas propias. Mientras la ruta no exista, se muestra un mensaje de
indisponibilidad; no se sustituye por demo. Hay carga, error y reintento manual.
El informe no se guarda en disco; su proveedor depende de la sesión y cancela
la solicitud al descartarse. La pantalla usa el tema de la app, sin nuevos audios.

## Ruta verificada y commits

Verificación local: backend compilado y 285 pruebas aprobadas en 54 suites;
análisis de los 8 archivos/grupos Flutter
seleccionados sin observaciones. Las pruebas de modelo, repositorio, pantalla,
diagnóstico inicial y navegación (`widget_test.dart`) completaron 52 casos aprobados.
La primera suite Flutter completa dio 359 aprobados, 4 omitidos y dos fallos de
desplazamiento en pruebas. Ambos se corrigieron centrando el elemento antes de
pulsarlo; sus archivos completos se volvieron a ejecutar dentro de los 52 casos.
No se volvió a ejecutar toda la suite Flutter después de ese ajuste.

Las pruebas no sustituyen la validación visual en Android/iOS ni el flujo con
cuentas reales y banco publicado. El análisis global de archivos no modificados
mantiene las observaciones anteriores documentadas en etapas previas.

El 6 de septiembre de 2026, `Get-Location` y `git rev-parse --show-toplevel`
confirmaron la raíz móvil `C:\Users\LENOVO 14ALC6\Desktop\SaberPLus\saber_plus`.
`Desktop\saber_plus` directamente no existe en este equipo. VS Code puede mostrar
solo el nombre de la carpeta abierta. No escribir una barra antes del guion bajo.

Backend oficial (no la copia dentro de SaberPLus):

```powershell
cd "C:\Users\LENOVO 14ALC6\Desktop\SaberPlus-Backend"
git add backend/src/diagnostico backend/docs/LEARNING_EVIDENCE.md
git commit -m "feat: diagnosticar temas con evidencia acumulada"
```

Flutter:

```powershell
cd "C:\Users\LENOVO 14ALC6\Desktop\SaberPLus\saber_plus"
git add lib/features/learning_evidence lib/app/router.dart lib/features/progress/presentation/progress_page.dart lib/features/academic/presentation/diagnostic_overview_page.dart test/learning_evidence_test.dart test/learning_evidence_page_test.dart test/diagnostic_overview_test.dart test/widget_test.dart README.md docs/ROADMAP_MOVIL.md docs/ACADEMIC_CONTRACT.md docs/LEARNING_EVIDENCE.md
git commit -m "feat: mostrar diagnostico por temas con evidencia suficiente"
```

No se crearon commits ni se hizo push; tampoco se desplegó ni se migró Supabase
durante esta entrega. Los cambios anteriores pendientes de Guardián quedan separados.

Sigue **7F-C3: panel web privado de administración de contenido**. Continúan
pendientes 7F-C4 (sincronización/versionado), 7F-C5 (Storage), 7F-C6 (auditoría)
y la comprobación integral con teléfono de 7F-B3-B.
