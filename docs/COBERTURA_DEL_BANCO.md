# MA-1 — Cobertura básica del banco

Entrega local: 24 de septiembre de 2026. Cambios funcionales en el repositorio
SaberPlus-Backend; en Flutter solo se actualiza la documentación.

El administrador tiene una pestaña **Cobertura**, con filtro por las cinco áreas,
paginación por subtema y recarga. Muestra total almacenado, preguntas disponibles,
no disponibles, cantidades por dificultad, niveles faltantes y preguntas disponibles
sin explicación general. También incluye subtemas vacíos.

Disponibilidad exige pregunta, tema, subtema y contexto opcional publicados.
No cambia el editor simple ni agrega aprobación editorial. No modifica contenido,
XP, diagnósticos ni partidas. Los totales no garantizan suficiencia para cada juego.

**Pendiente de MA-1:** reportes académicos de preguntas. No existe ese flujo en el
backend; el panel indica que no están disponibles, en vez de presentar un cero falso.
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
Siguiente entrega funcional: **MA-2 — Mapa de aprendizaje**, orientación entre temas
sin bloquear contenido. MA-3 repaso diferido sigue después. P5/D3 y animaciones
siguen pausados; anuncios y recuperación mediante anuncios se definirán en 8C–8D.
