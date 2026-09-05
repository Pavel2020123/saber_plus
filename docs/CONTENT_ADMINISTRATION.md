# Administración y publicación de contenido

SaberPlus usará un panel web privado para que el equipo administre temas,
lecciones, casos, preguntas y recursos. Flutter consume únicamente contenido
publicado por la API NestJS; nunca escribe directamente en Supabase.

## Flujo editorial

Cada tema, subtema, caso y pregunta tiene uno de estos estados:

1. `BORRADOR`: se puede editar y no aparece en la app.
2. `EN_REVISION`: espera comprobación académica y visual.
3. `PUBLICADO`: puede ser seleccionado en actividades nuevas.
4. `ARCHIVADO`: deja de ofrecerse sin borrar intentos ni estadísticas previas.

No es posible pasar directamente de borrador a publicado. Cuando se modifica
el contenido de un subtema, un interactivo, un caso o la asociación de una
pregunta con un caso, el elemento vuelve a borrador y debe revisarse otra vez.

La migración conserva el contenido previo como archivado. De ese modo, ningún
material antiguo se publica automáticamente sin una revisión de autoría,
calidad y permisos.

## Validaciones de publicación

- Un subtema solo se publica si su tema ya está publicado.
- Una pregunta requiere enunciado, al menos dos opciones no vacías y
  exactamente una respuesta correcta.
- El tema y el subtema de una pregunta deben estar publicados.
- Si la pregunta usa un caso compartido, ese caso también debe estar publicado.
- Los intentos ya iniciados pueden terminar con su versión anterior, pero el
  contenido archivado no entra en diagnósticos, prácticas, simulacros, repasos,
  planes de estudio ni juegos nuevos.
- Solo puede borrarse físicamente un elemento nuevo en borrador y sin actividad
  asociada. El contenido usado se archiva.

## Rutas administrativas disponibles en 7F-C1

Todas requieren una sesión con rol `ADMIN`:

```text
PATCH /admin/temas/:id/estado
PATCH /admin/subtemas/:id/estado
PATCH /admin/casos-preguntas/:id/estado
PATCH /admin/preguntas/:id/estado
```

Cuerpo de la solicitud:

```json
{
  "estadoContenido": "EN_REVISION"
}
```

Para publicar se repite la ruta con `PUBLICADO` después de la revisión. Para
retirar sin destruir datos se usa `ARCHIVADO`.

## Prueba manual prevista

La prueba funcional crea contenido propio de ejemplo en `saberplus-dev`, lo
envía a revisión en orden tema, subtema, caso opcional y pregunta, lo publica y
comprueba que la app pueda obtenerlo. Después se archiva la pregunta y se
verifica que no vuelva a seleccionarse en una actividad nueva.

La migración se aplica solo mediante el procedimiento controlado de
`SUPABASE_DEPLOYMENT.md`. Nunca se usa `prisma db push` en staging.

## Próximas entregas de 7F-C

- **7F-C2:** plantilla Excel y paquete ZIP con previsualización, validaciones y
  detección de duplicados.
- **7F-C3:** panel web privado para editar, revisar y publicar.
- **7F-C4:** versión global del catálogo y sincronización Flutter/Drift.
- **7F-C5:** archivos e imágenes en Supabase Storage, con metadatos y texto
  alternativo.
- **7F-C6:** historial de cambios, responsables y restauración de versiones.

Los cuadernillos oficiales o escaneados sirven únicamente como referencia de
estructura mientras no exista autorización escrita o una licencia compatible.
El banco publicado debe utilizar preguntas, textos, diagramas e imágenes
originales o expresamente autorizados.
