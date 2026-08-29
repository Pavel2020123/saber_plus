# Favoritos académicos

Esta entrega permite que cada estudiante guarde lecciones desde su encabezado y las abra posteriormente desde `Más > Mis favoritos`.

## Alcance actual

- Los favoritos se separan por identificador de estudiante.
- Se conservan en Drift/SQLite aunque la aplicación se cierre y funcionan sin conexión.
- Cada registro guarda la identidad y los datos mínimos de navegación de la lección: área, tema, subtema y títulos visibles.
- La operación de agregar o quitar se resuelve localmente y no modifica el contenido académico del backend.

La tabla local usa un tipo de contenido además de su identificador. En esta primera parte solamente se habilitan lecciones; esa estructura permite incorporar después preguntas, fórmulas o entradas del glosario sin mezclar sus identidades.

## Límite conocido

El backend auditado no publica un recurso de favoritos. Por esa razón, los elementos guardados no se sincronizan entre dispositivos ni se restauran al instalar la aplicación en otro teléfono. Flutter no debe simular esa sincronización ni escribir directamente en PostgreSQL o Supabase.

Cuando exista un contrato de API, el repositorio podrá sincronizar la tabla local mediante la cola segura ya disponible, manteniendo SQLite como caché para el modo sin conexión.
