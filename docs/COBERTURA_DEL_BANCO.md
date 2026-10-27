# MA-1 — Cobertura básica del banco

**19 de octubre, estado vigente:** cobertura y reportes MA-1R/R1–R4 cerrados
localmente e integrados en main por PR app #6/backend #9. El ensayo confirmó
que resolver un reporte reduce el conteo abierto sin cambiar preguntas ni XP.
[Acta R4](MA1R_R4_VALIDACION_LOCAL.md):12/12 humanos,45/45 HTTP/PostgreSQL y regresiones.
CI backend del PR aprobado; staging/despliegue y operación siguen pendientes.
[Orden restante](ESTADO_Y_ORDEN_2026_10_17.md): preparación local C5.

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
Revisión visual del flujo de reportes/cobertura con API local real confirmada en R4.
Falta ensayo del entorno desplegado P5/D3. No hubo migración en Supabase ni
cambios en anuncios/comodines.

## Cómo probar la demo

```powershell
cd "C:\Users\LENOVO 14ALC6\Desktop\SaberPlus-Backend\admin"
npm run demo
```

Entrar a la demostración y abrir Cobertura. Crear una pregunta desde Preguntas,
volver y actualizar para comprobar los conteos. La demo utiliza registros reales
en memoria (puede empezar en cero), no números ilustrativos del catálogo.
Los cambios de demo no llegan a Supabase y se pierden al reiniciar.

## Verificación original del24 de septiembre

- Backend: compilación aprobada; 827 pruebas Jest en 83 suites.
- PostgreSQL temporal aislado: 4 pruebas de cobertura aprobadas.
- Panel: 19 módulos comprobados y 79 pruebas aprobadas.
- ESLint de los nuevos archivos TypeScript aprobado.

Contrato y detalles: `backend/BANK_COVERAGE.md` en SaberPlus-Backend.
Antecedente del28 de septiembre (no siguiente actual): MA-2A/B/C y MA-3A/B/C locales listas; siguiente
entrega **PR-I1 — Reglas y contratos competitivos**. [MA-2](MAPA_APRENDIZAJE.md) orienta entre temas
sin bloquear contenido. MA-1 no queda cerrada por avanzar. P5/D3 y animaciones
siguen pausados; anuncios y recuperación mediante anuncios se definirán en 8C–8D.
