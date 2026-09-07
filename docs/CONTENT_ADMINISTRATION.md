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

No es posible pasar directamente de borrador a publicado. El editor vigente
solo modifica borradores nunca publicados y sin uso académico, con restricciones
adicionales según el recurso. No devuelve contenido utilizado a borrador para
reescribirlo silenciosamente; versionado de correcciones queda en C6.

La migración conserva el contenido previo como archivado. De ese modo, ningún
material antiguo se publica automáticamente sin una revisión de autoría,
calidad y permisos.

## Validaciones de publicación

- Un subtema solo se publica si su tema ya está publicado.
- Una pregunta requiere enunciado, al menos dos opciones no vacías y
  exactamente una respuesta correcta.
- El tema y el subtema de una pregunta deben estar publicados.
- Si la pregunta usa un caso compartido, ese caso también debe estar publicado.
- Antes de crear o publicar se calcula una huella normalizada. El editor de
  borradores bloquea coincidencias incluso archivadas; la revisión de publicación
  comprueba coincidencias no archivadas. No asumir que archivar permite duplicar
  desde el editor; las correcciones/versiones necesitan su flujo explícito.
- Los intentos ya iniciados pueden terminar con su versión anterior, pero el
  contenido archivado no entra en diagnósticos, prácticas, simulacros, repasos,
  planes de estudio ni juegos nuevos.
- Desde D2-A no hay borrado físico editorial por HTTP; se usa archivo bajo revisión.

## Rutas de estado vigentes desde C3-D1/D2-A

Todas requieren una sesión con rol `ADMIN`:

```text
GET   /admin/editor/revision/:tipo/:id
PATCH /admin/editor/revision/:tipo/:id
```

Cuerpo de la solicitud:

```json
{
  "revision": "<SHA-256 de 64 caracteres devuelto por GET>",
  "destino": "EN_REVISION",
  "confirmado": true
}
```

Tipos: `temas`, `subtemas`, `preguntas`, `casos`. Usar una revisión actual para
cada cambio. Para retirar sin destruir datos se usa destino `ARCHIVADO`.
Las antiguas rutas `.../:id/estado` de C1 devuelven 410 en D2-A; no reenviar su
cuerpo automáticamente. La escritura nueva sigue bloqueada por defecto mediante
`EDITORIAL_PUBLICATION_ENABLED` hasta cerrar D2 y preparar D3.

## Prueba manual prevista

La prueba funcional crea contenido propio de ejemplo en `saberplus-dev`, lo
envía a revisión en orden tema, subtema, caso opcional y pregunta, lo publica y
comprueba que la app pueda obtenerlo. Después se archiva la pregunta y se
verifica que no vuelva a seleccionarse en una actividad nueva.

La migración se aplica solo mediante el procedimiento controlado de
`SUPABASE_DEPLOYMENT.md`. Nunca se usa `prisma db push` en staging.

## Importación segura disponible en 7F-C2-A

El backend ya puede recibir un Excel o ZIP desde una sesión administrativa,
validarlo completamente en memoria y devolver una vista previa sin modificar
la base de datos:

```text
GET  /admin/importaciones-contenido/formato
POST /admin/importaciones-contenido/previsualizar
```

La segunda ruta usa `multipart/form-data` con un campo `archivo`. Revisa la
estructura del libro, casos compartidos, opciones, imágenes, accesibilidad,
autoría y duplicados contra todo el banco activo. Las coincidencias publicadas
son errores y no pueden confirmarse como una importación nueva. El contrato
completo está en `docs/CONTENT_IMPORT_FORMAT.md`.

La importación Excel/ZIP queda disponible como herramienta masiva opcional. El
método principal será el panel privado, para que el equipo pueda mantener el
contenido sin preparar archivos manualmente.

## Estado del panel y próximas entregas de 7F-C

- **7F-C2-B1/B2, implementadas:** clasificación obligatoria y diagnóstico por
  evidencia acumulada. Su prueba integral real sigue en 7F-B3-B.
- **7F-C3-A, implementada:** acceso ADMIN, navegación del catálogo y creación
  de temas/subtemas en borrador, con demostración local. Revisión visual pendiente.
- **7F-C3-B, implementada:** editor de lecciones en borrador, vista previa de
  texto y ajustes de nombres sin uso académico. Revisión de concurrencia,
  referencias HTTPS y demo local; despliegue y prueba ADMIN real pendientes.
- **7F-C3-C, implementada:** preguntas por subtema, opciones de texto, explicación,
  casos por área, imágenes referenciadas y control de duplicados. Demo local;
  sin publicación ni carga de archivos. Imágenes en opciones requieren ampliación
  de modelo/contrato/Flutter en C5. Rutas heredadas e indexación del legado en C3-D.
- **7F-C3-D:** revisión/publicación y prueba editorial de extremo a extremo.
  - **D1 implementada:** revisión del registro guardado, controles, confirmación
    y estados en demo; nuevas escrituras reales desactivadas por defecto.
  - **D2 parcial:** D2-A retira escrituras heredadas y unifica bloqueo por área.
    Faltan indexación/clasificación, revisión de interactivos, PostgreSQL y despliegue.
  - **D3 pendiente:** despliegue y ensayo editorial real con cuenta ADMIN.
  Apertura, requisitos y commits en [ADMIN_PANEL.md](ADMIN_PANEL.md).
- **7F-C4:** versión global del catálogo y sincronización Flutter/Drift.
- **7F-C5:** archivos e imágenes en Supabase Storage, con metadatos y texto
  alternativo.
- **7F-C6:** historial de cambios, responsables y restauración de versiones.

Los cuadernillos oficiales o escaneados sirven únicamente como referencia de
estructura mientras no exista autorización escrita o una licencia compatible.
El banco publicado debe utilizar preguntas, textos, diagramas e imágenes
originales o expresamente autorizados.
