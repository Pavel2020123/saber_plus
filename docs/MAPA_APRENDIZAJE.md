# MA-2 — Mapa de aprendizaje

Actualizado: 27 de septiembre de 2026.

| Entrega | Estado | Alcance |
|---|---|---|
| MA-2A | Implementada/probada localmente | Grafo de subtemas, persistencia, consulta y edición ADMIN en API |
| MA-2B | Implementada/probada localmente | Editor del mapa en panel, demo y pruebas de UI/HTTP |
| MA-2C | Siguiente | Integración Flutter, navegación, evidencia y pruebas |
| Ensayo real | Pendiente, infraestructura pausada | Migración/despliegue autorizado y recorrido panel → API → app |

## Qué quedó hecho en MA-2A

Backend oficial `SaberPlus-Backend/backend/src/learning-map/`, migración
`backend/prisma/migrations/20260927120000_learning_map/migration.sql` y contrato
`backend/LEARNING_MAP.md`. En este repositorio móvil solo cambió documentación.

Relación orientativa entre subtemas de una misma área. Fracciones → proporciones →
regla de tres es ejemplo, no datos sembrados. Solo ADMIN puede editar; el alumno
autenticado consulta referencias publicadas. No hay bloqueos, XP ni calificaciones
derivadas del mapa. Leer/completar una lección no se convierte en dominio demostrado.

Previene duplicados, autorreferencias y ciclos incluso ante ediciones concurrentes.
Revisión de área obliga a recargar si otro editor cambió el mapa. Hasta ocho bases
directas por subtema y 5000 relaciones por área, límites técnicos iniciales.
Archivar un intermedio oculta su ruta sin inventar un atajo. Las consultas no
entregan respuestas, diagnósticos privados ni datos del editor.

Verificado: build backend, ESLint nuevo módulo, 845 pruebas Jest en 84 suites,
7 pruebas PostgreSQL temporal (incluyen HTTP, permisos, DTO, RLS y concurrencia).
No hubo migraciones en bases compartidas ni despliegue. No se ejecutaron pruebas
Flutter: no cambió código móvil. No afirmar que MA-2 completa ya se ve en celular.

## MA-2B — entrega local y recorrido para probar

En `SaberPlus-Backend/admin`, ejecutar `npm run demo` y entrar a la demostración.
Abrir «Mapa de aprendizaje», seleccionar área, tema y subtema destino. Buscar
una base publicada, agregarla y guardar. La selección usa paginación del catálogo;
permite quitar bases sin eliminar subtemas. Se muestra el recorrido guardado.
Para demostrar relaciones, publicar primero dos subtemas de la misma área desde
Contenido: los borradores no pueden recomendarse. No se sembraron vínculos ficticios.

Protecciones: confirmación al descartar, máximo ocho bases, revisión de área,
rechazo de ciclos y de vínculos entre áreas, bloqueo del reenvío tras conflicto o
resultado incierto, limpieza al cerrar sesión y descarte de respuestas tardías.
Demo solo en memoria, sin conexión a Supabase. El contrato real no cambió.

Validación: `npm run check` (22 módulos) y `npm test` (88 pruebas del panel).
Pruebas automatizadas DOM/HTTP; revisión visual manual y ensayo real pendientes.
No se ejecutaron migraciones, despliegues ni pruebas Flutter: no cambió código móvil.
Sigue **MA-2C**. P5/D3 y animaciones permanecen pausadas.

### Alcance original de MA-2B (referencia)

Leer contrato backend y reutilizar `admin/public/api.mjs`, selectores del catálogo y
patrones de editores. Agregar edición de bases dentro del flujo de subtema: seleccionar
previos de la misma área, mostrar relaciones actuales, guardar revisión, quitar bases
sin borrar contenido. No agregar un nuevo flujo obligatorio de revisión/publicación.
Ante 409, informar que cambió y ofrecer recargar; no sobrescribir ni reenviar a ciegas.
Proteger cambios sin guardar, limpiar sesión y evitar respuestas tardías.
Crear equivalente demo en memoria que valide ciclos/publicación y pruebas del panel.
No conectar a Supabase para probar la demo. Dejar MA-2C como siguiente al cerrar.

## Instrucción para MA-2C

Reutilizar estudio y evidencia académica. API GET por subtema ofrece bases directas
y recorrido ordenado. Mostrar orientación y navegación a lecciones, sin bloquear
el destino. Lista vacía no significa dominio; diferenciar carga/error/sin relaciones.
Recomendaciones personalizadas deben apoyarse en evidencia existente con su muestra,
no en un solo error o en el grafo. Sin evidencia, no etiquetar al alumno como débil.
Repositorio demo separado del remoto, no fallback silencioso. Probar cuentas,
contenido retirado, texto grande y navegación. Animaciones finales siguen pausadas.

Después de MA-2B/C sigue MA-3 repaso diferido; MA-1 reportes académicos permanece abierto.
