# Búsqueda académica móvil

La búsqueda está disponible desde las pantallas `Estudiar` y `Practicar`. Permite localizar contenido por área, tema, subtema o palabras incluidas en la teoría.

## Fuente de los resultados

El backend auditado no publica un endpoint general de búsqueda. La aplicación construye temporalmente el índice consultando el catálogo protegido de cada una de las cinco áreas mediante `GET /simulacros/temas?area=...`.

- La búsqueda no distingue mayúsculas, minúsculas ni tildes.
- Los resultados pueden filtrarse entre lecciones y preguntas.
- Una lección abre su recurso académico existente.
- Un resultado del banco muestra únicamente el subtema y la cantidad de preguntas publicadas.

El índice no se guarda como una copia permanente del banco. Al cerrar la pantalla se puede descartar y se reconstruye a partir del catálogo autorizado.

## Protección de preguntas

Las preguntas, opciones, explicaciones y respuestas correctas no forman parte del índice. Al elegir un resultado de tipo `Banco de preguntas`, Flutter abre la ruta de práctica por subtema y el backend crea un intento protegido mediante `GET /simulacros/preguntas/:subtemaId`.

De esta forma, la búsqueda ayuda a elegir qué practicar sin convertir el banco completo en datos públicos ni exponer respuestas antes de la calificación.

## Evolución pendiente

Si el catálogo crece lo suficiente para que consultar las cinco áreas resulte costoso, el backend deberá publicar un endpoint de búsqueda paginado y protegido. Ese contrato debería devolver metadatos de navegación, nunca respuestas correctas, y mantener las mismas reglas de plan vigente y correo verificado.
