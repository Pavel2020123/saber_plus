# MA-2 — Mapa de aprendizaje

Actualizado: 27 de septiembre de 2026.

| Entrega | Estado | Alcance |
|---|---|---|
| MA-2A | Implementada/probada localmente | Grafo de subtemas, persistencia, consulta y edición ADMIN en API |
| MA-2B | Siguiente | Editor del mapa en panel, demo y pruebas de UI/HTTP |
| MA-2C | Pendiente | Integración Flutter, navegación, evidencia y pruebas |
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

## Instrucción para MA-2B

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
