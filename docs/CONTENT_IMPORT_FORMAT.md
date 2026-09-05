# Importación masiva de contenido

La etapa 7F-C2-A incorpora una vista previa segura para revisar preguntas,
lecciones, casos e imágenes antes de escribir cualquier dato. La aplicación
Flutter no recibe archivos ni credenciales de Supabase: el futuro panel web
privado enviará el paquete a la API NestJS usando una sesión `ADMIN`.

## Formatos admitidos

- Un archivo `.xlsx` sin recursos gráficos.
- Un `.zip` de hasta 25 MB con exactamente un `.xlsx` y recursos `.png`,
  `.jpg`, `.jpeg` o `.webp`.
- Hasta 1.000 filas de contenido por hoja.
- Hojas reconocidas: `Preguntas`, `Lecciones` y `Casos`. Puede omitirse una
  hoja que no se vaya a importar, pero el libro debe incluir al menos una fila
  de contenido.

Ejemplo de paquete con imágenes:

```text
contenido_saberplus.zip
├── contenido.xlsx
└── recursos/
    ├── grafica_pregunta_001.png
    └── opcion_b_001.webp
```

Las celdas de imagen usan la ruta relativa exacta, por ejemplo
`recursos/grafica_pregunta_001.png`. No se aceptan enlaces web, archivos
cifrados, enlaces simbólicos, rutas que salgan del ZIP ni formatos distintos a
los enumerados.

## Hoja `Preguntas`

Los encabezados son:

```text
codigo
area
tema
subtema
dificultad
enunciado
explicacion_general
imagen_pregunta
texto_alternativo_imagen
caso_codigo
orden_en_caso
opcion_a
imagen_opcion_a
texto_alternativo_a
explicacion_a
opcion_b
imagen_opcion_b
texto_alternativo_b
explicacion_b
opcion_c
imagen_opcion_c
texto_alternativo_c
explicacion_c
opcion_d
imagen_opcion_d
texto_alternativo_d
explicacion_d
opcion_e
imagen_opcion_e
texto_alternativo_e
explicacion_e
opcion_f
imagen_opcion_f
texto_alternativo_f
explicacion_f
respuesta_correcta
fuente
tipo_autorizacion
referencia_autorizacion
```

Cada pregunta necesita un código único, área, tema, subtema, dificultad,
enunciado, al menos dos opciones consecutivas desde A, una respuesta correcta,
fuente y autorización. Una opción puede tener texto, imagen o ambos. Toda
imagen requiere texto alternativo.

Cuando varias preguntas comparten lectura, tabla o contexto, primero se define
el elemento en `Casos`; después se usa su `caso_codigo` y un `orden_en_caso`
positivo y no repetido.

## Hoja `Lecciones`

```text
codigo
area
tema
subtema
contenido_markdown
imagen
texto_alternativo_imagen
video_url
fuente
tipo_autorizacion
referencia_autorizacion
```

`video_url`, cuando se use, debe ser una URL HTTPS. El contenido admite
Markdown y no HTML ejecutable.

## Hoja `Casos`

```text
codigo
area
titulo
contexto
imagen
texto_alternativo_imagen
fuente
tipo_autorizacion
referencia_autorizacion
```

## Catálogos y autoría

- Áreas: los valores vigentes del enum `AreaIcfes` del backend.
- Dificultad: `BASICO`, `MEDIO` o `AVANZADO`.
- Tipo de autorización: `ORIGINAL`, `LICENCIA`, `DOMINIO_PUBLICO` o
  `AUTORIZACION_ESCRITA`.
- Si la autorización no es `ORIGINAL`, se exige su licencia, URL o referencia
  documental.

No deben publicarse preguntas ni imágenes copiadas de cuadernillos sin permiso.
Los PDF oficiales recibidos pueden orientar la estructura visual, pero no
convierten su contenido en material reutilizable.

## Contrato administrativo

```text
GET  /admin/importaciones-contenido/formato
POST /admin/importaciones-contenido/previsualizar
```

El `POST` usa `multipart/form-data` y el campo se llama `archivo`. La respuesta
incluye resumen, filas normalizadas, errores, advertencias, recursos sin uso y
coincidencias contra PostgreSQL. Si la misma pregunta ya está en borrador,
revisión o publicada, la fila se devuelve como error e incluye el identificador
y estado del registro existente. Durante esta etapa siempre devuelve
`soloPrevisualizacion: true` y no modifica Supabase.

La confirmación persistente, la revisión visual y la publicación se conectarán
desde el panel privado de 7F-C3. La carga definitiva de archivos a Supabase
Storage corresponde a 7F-C5; hasta entonces las rutas e imágenes solo se
validan en memoria.

## Controles aplicados

- Encabezados y valores obligatorios.
- Longitudes, códigos, áreas, dificultades y URLs.
- Opciones consecutivas y respuesta correcta válida.
- Integridad entre casos y preguntas, incluida la unicidad del orden.
- Existencia y firma real de imágenes.
- Texto alternativo obligatorio.
- Duplicados por código y por huella SHA-256 normalizada dentro del paquete.
- Bloqueo de preguntas ya registradas o publicadas en la base. La huella ignora
  diferencias de mayúsculas, espacios y orden de las opciones.
- Límites contra expansión excesiva de ZIP y rutas inseguras.
