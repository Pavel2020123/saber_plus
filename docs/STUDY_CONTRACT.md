# Contrato de contenido académico móvil

Contrato auditado contra el backend NestJS de `Pavel2020123/Icfes_Vida` para la Etapa 3C.

## Árbol académico

Las cinco áreas ICFES son valores estables de la aplicación. Al seleccionar una, Flutter consulta:

- `GET /simulacros/temas?area={AREA}` para obtener temas y subtemas.
- Cada subtema incluye nombre, cantidad de preguntas, contenido Markdown, video, imagen y actividad interactiva opcional de tipo `CLOZE`.
- `GET /simulacros/progreso` para recuperar el porcentaje general y el porcentaje por subtema.
- `POST /simulacros/progreso` con `subtemaId` y `porcentaje` para marcar explícitamente una lección como completada.

Flutter no modifica ni duplica el contenido académico: la API continúa siendo la fuente de verdad.

## Recursos

- El contenido textual se representa como Markdown seleccionable.
- Los enlaces y videos HTTP/HTTPS se abren con la aplicación disponible en el dispositivo.
- `GET /simulacros/temas/:temaId/pdf` se descarga con el token del estudiante, se guarda temporalmente y se abre con el lector PDF instalado.
- Las imágenes aceptan una URL absoluta, una ruta `/uploads` servida por la API o un nombre legado bajo `/imagenes`.

## Limitación detectada en imágenes legadas

El backend sirve `/uploads`, pero no sirve la carpeta `frontend/public/imagenes`. Para una instalación móvil real hay que mover esos archivos a almacenamiento accesible o configurar `CONTENT_BASE_URL` con el origen HTTPS que publique `/imagenes`. La app muestra un estado controlado si el recurso no existe.

## Alcance de la Etapa 3C

Esta etapa permite explorar y leer el contenido. Las preguntas que aparecen contabilizadas en cada subtema se resolverán en la Etapa 4, mediante los intentos protegidos de práctica y simulacro del backend.
