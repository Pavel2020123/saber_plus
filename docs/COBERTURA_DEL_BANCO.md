# MA-1 — Cobertura básica del banco

**17 de octubre, continuación propuesta:** tras el cierre institucional local,
completar reportes académicos MA-1R, sin rehacer conteos/pestaña existentes.
Ver [R1–R4 y decisiones pendientes](ESTADO_Y_ORDEN_2026_10_17.md).
R1/flujo autorizados y [R2 backend local implementada](MA1R_REPORTES_PREGUNTAS.md),
121 suites/1.560 aprobadas. [R3 app/panel local](MA1R_R3_APP_PANEL.md),18 de octubre:
32 dirigidas Flutter/109 ADMIN aprobadas. Sigue R4 integración real; no se cierra MA-1.

Entrega local: 24 de septiembre de 2026. Cambios funcionales en el repositorio
SaberPlus-Backend; en Flutter solo se actualiza la documentación.

El administrador tiene una pestaña **Cobertura**, con filtro por las cinco áreas,
paginación por subtema y recarga. Muestra total almacenado, preguntas disponibles,
no disponibles, cantidades por dificultad, niveles faltantes y preguntas disponibles
sin explicación general. También incluye subtemas vacíos.

Disponibilidad exige pregunta, tema, subtema y contexto opcional publicados.
No cambia el editor simple ni agrega aprobación editorial. No modifica contenido,
XP, diagnósticos ni partidas. Los totales no garantizan suficiencia para cada juego.

**MA-1R/R2 local:** ya hay persistencia/rutas de reportes en backend, no desplegadas.
Panel legacy conserva false/null; el consumidor R3 ya pide reportesVersion=1 y
valida abiertos/preguntas distintas. Solo un400 al opt-in permite reconsulta legacy,
no una falla DB/red. La bandeja Reportes permite revisar sin publicar/retirar contenido.
Sin ese parámetro no se inventa cero ni se consulta el modelo nuevo.
También faltan revisión visual y ensayo con servicio real. No hubo despliegue,
migración en Supabase ni cambios en anuncios/comodines.

## Cómo probar la demo

```powershell
cd "C:\Users\LENOVO 14ALC6\Desktop\SaberPlus-Backend\admin"
npm run demo
```

Entrar a la demostración y abrir Cobertura. Crear una pregunta desde Preguntas,
volver y actualizar para comprobar los conteos. La demo utiliza registros reales
en memoria (puede empezar en cero), no números ilustrativos del catálogo.
Los cambios de demo no llegan a Supabase y se pierden al reiniciar.

## Verificación

- Backend: compilación aprobada; 827 pruebas Jest en 83 suites.
- PostgreSQL temporal aislado: 4 pruebas de cobertura aprobadas.
- Panel: 19 módulos comprobados y 79 pruebas aprobadas.
- ESLint de los nuevos archivos TypeScript aprobado.

Contrato y detalles: `backend/BANK_COVERAGE.md` en SaberPlus-Backend.
Antecedente del28 de septiembre (no siguiente actual): MA-2A/B/C y MA-3A/B/C locales listas; siguiente
entrega **PR-I1 — Reglas y contratos competitivos**. [MA-2](MAPA_APRENDIZAJE.md) orienta entre temas
sin bloquear contenido. MA-1 no queda cerrada por avanzar. P5/D3 y animaciones
siguen pausados; anuncios y recuperación mediante anuncios se definirán en 8C–8D.
