# 7F-C3-D1 — Revisión y publicación editorial

Implementado en `admin/` del repositorio oficial **SaberPlus-Backend**. No se
reintrodujeron carpetas Flutter web ni se modificó la página antigua Icfes_Vida.

## Qué se puede hacer

- Entrar con cuenta editorial ADMIN confirmada por la API.
- Navegar por áreas, temas y subtemas, en páginas de 20 registros.
- Ver estados editoriales y conteos; identificar clasificación heredada genérica.
- Crear temas y subtemas únicamente en borrador, con avisos de duplicados.
- Probar todo lo anterior en una demo local aislada y sin cuenta real.
- Seleccionar un subtema y redactar/guardar su lección como borrador.
- Previsualizar títulos, viñetas y texto sin ejecutar HTML ni cargar recursos externos.
- Guardar referencias opcionales HTTPS de imagen/video y abrirlas explícitamente.
- Corregir nombres de temas vacíos o subtemas todavía sin uso académico.
- Detectar conflictos de edición; conservar el texto local si el guardado falla.
- Advertir al abandonar el editor con cambios pendientes.
- Crear, consultar y editar preguntas en borrador por subtema, con 2–6 opciones
  de texto, una correcta, explicación general y explicaciones opcionales por opción.
- Crear casos compartidos por área y asociarlos con un orden explícito a preguntas.
- Bloquear preguntas repetidas, conflictos de revisión y órdenes ocupados en casos.

Hay botones de revisión y cambios de estado en la demo. Las nuevas escrituras
de estado reales están apagadas por defecto hasta C3-D2. No hay carga de archivos
de imágenes. Un borrador nuevo no aparece automáticamente en Flutter.

## Abrir la demostración

```powershell
cd "C:\Users\LENOVO 14ALC6\Desktop\SaberPlus-Backend\admin"
npm run demo
```

Abrir `http://127.0.0.1:4173` en el navegador y pulsar **Explorar demostración**.
Node 24 es suficiente, sin instalar dependencias. Detener con Ctrl+C. Los datos
son ficticios y se borran al reiniciar ese servidor, sin tocar Supabase.

Prueba **Matemáticas > Proporcionalidad > Porcentajes** para escribir una lección.
Guarda, cierra el editor y vuelve a seleccionar Porcentajes para comprobarla.
**Regla de tres directa** está publicado y se abre como solo lectura.
Para corregir un nombre de tema, selecciona **Álgebra** y pulsa el botón de
corrección antes de crear subtemas dentro de él.

Para **C3-C**, desde el editor de Porcentajes pulsa **Preguntas de este subtema**
y luego **Crear nuevo borrador**. Completa enunciado, opciones, correcta y
explicación. Guarda y vuelve a seleccionar la pregunta para editarla.
Para casos, pulsa **Casos del área** en la cabecera. Hay un caso demo de papelería;
también puedes crear otro antes de asociarlo a una pregunta.

Para **C3-D1**, abre cualquier registro guardado y pulsa **Revisar estado y
publicación**. Guarda primero los cambios locales. Revisa bloqueos y advertencias,
envía a revisión y confirma Publicar. El orden es tema → subtema → caso (si hay)
→ pregunta. Archivar no borra: primero retira los dependientes publicados.

## Alcance de C3-D1 y bloqueo de lanzamiento

- Revisión del contenido guardado con versión, dependencias, explicación,
  opciones, duplicados y orden de caso. Confirmación explícita de cambios.
- La API relee y valida bajo bloqueos. No se publica usando una revisión vieja;
  no hay reintentos automáticos ni cambios en cascada.
- Conserva la fecha de publicación al archivar o volver a borrador. Eso no
  permite editar como nuevo contenido que ya se usó.
- Derechos, exactitud, disponibilidad de recursos y accesibilidad requieren
  revisión humana. La vista previa no descarga imágenes ni verifica licencias.
- `EDITORIAL_PUBLICATION_ENABLED` permanece ausente/false en entornos reales:
  consulta habilitada, nuevas escrituras de estado bloqueadas. No activar hasta
  unificar las rutas antiguas en D2 y preparar el ensayo autorizado D3.
- El bloqueo solo afecta a las rutas nuevas de revisión; los endpoints heredados
  todavía deben unificarse. Interactivos CLOZE y clasificación/indexación del
  legado siguen en D2. **C3-D completa todavía no está terminada.**

## Reglas del editor de lecciones (C3-B)

- Solo se editan lecciones en BORRADOR, nunca publicadas, sin progreso ni
  actividades de plan, con clasificación específica y sin interactivo CLOZE.
- Se pueden redactar lecciones de borradores con preguntas, pero no renombrar
  esos subtemas. Los temas solo se renombran vacíos, en borrador y nunca publicados.
- No se mueven preguntas, áreas ni subtemas. No se modifican resultados históricos.
- El texto admite 30000 caracteres; cada referencia HTTPS, 2000. Vaciar una
  referencia la elimina. La vista previa es simplificada, no una réplica exacta
  del renderizado Markdown de Flutter. Imágenes/videos no se incrustan todavía.
- La revisión SHA-256 y los bloqueos evitan sobrescrituras entre estas rutas
  nuevas del editor. No constituyen historial o restauración. Las rutas heredadas
  de contenido/interactivos conservan su contrato; no usarlas simultáneamente
  para editar el mismo contenido. Unificación prevista en C3-D; historial en C6.
- No hay autoguardado: copiar texto pendiente antes de recargar. La sesión y el
  editor se limpian al cerrar sesión. No se guardan credenciales ni borradores
  en el almacenamiento del navegador.

## Reglas de preguntas y casos (C3-C)

- Preguntas: solo se editan borradores nunca publicados y sin uso académico
  (historial, cuaderno de errores, preguntas/respuestas de partidas, etc.).
  Casos: solo se editan borradores nunca publicados y sin preguntas asociadas.
- Las preguntas mantienen su subtema; los casos mantienen su área. Un caso no
  archivado puede asociarse a preguntas de diferentes subtemas de la misma área.
- El orden dentro del caso debe estar libre; pregunta independiente no lleva orden.
- Límites: enunciado/explicación general 12000 caracteres, opción/explicación de
  opción 4000, título de caso 200, contexto 20000 y URL HTTPS 2000. También aplica
  el límite global del cuerpo JSON en backend. Explicación general obligatoria.
- Se referencian imágenes del enunciado y caso; **no hay imágenes dentro de
  opciones** todavía. Requieren ampliar Respuesta, el contrato y Flutter en C5.
- Listas y selector de casos paginados de 20 en 20. Los listados no incluyen
  respuestas correctas; el detalle ADMIN y su vista previa sí las muestran.
- Duplicados: huella v1 de área, texto, opciones y referencia de imagen normalizados,
  sin importar el orden de opciones. Se incluyen registros archivados y legado
  sin huella, con un máximo de 2000 candidatos; por encima se bloquea hasta indexar.
  No es detección semántica/OCR ni compara el contexto del caso. La coincidencia
  muestra el ID existente para revisión; no implica que todo parecido sea detectado.
- Revisión SHA-256 y bloqueos por área/filas para estas rutas nuevas. Las rutas
  heredadas conservan su contrato y no comparten todos los bloqueos: no alternar
  ambas vías para editar concurrentemente. Unificación/backfill en C3-D antes de
  probar edición concurrente sobre el banco real. No hay historial/restauración aún.
- Guardar no publica. No hubo cambios en contenido real, cuentas, Render ni Supabase.

Para la conexión real, seguir `admin/README.md` en el backend: cuenta ADMIN,
API con las rutas nuevas y origen del panel autorizado por CORS. La contraseña
y el JWT se usan para autenticar, nunca se copian a archivos de la app. No se
necesitan credenciales de PostgreSQL ni claves de Supabase en el panel.

El acceso permanece en memoria de la pestaña y se pierde al recargar. Cerrar
sesión local no equivale a revocar un token en el backend; eso conserva su etapa.

## Verificación y límites

`npm run check` y `npm test` se ejecutan dentro de `SaberPlus-Backend/admin`.
Las pruebas comprueban API/servidor local, seguridad básica y contrato del catálogo.
Resultado local del panel: 37 pruebas aprobadas y sintaxis validada. Incluyen
dobles DOM para lógica del editor, no una prueba visual de navegador. En backend
se añadieron 19 pruebas de revisión/estados además de las del editor anterior:
gate, permisos, DTO, bloqueos, revisiones, duplicados y archivo. Compilación y lint
de archivos cambiados correctos. Las pruebas usan Prisma simulado, no comprueban
concurrencia real en PostgreSQL.
Suite completa del backend: **359 pruebas aprobadas en 57 suites**.
Revisión visual, CORS y prueba con cuenta ADMIN real quedan pendientes.
No hubo despliegues, migraciones ni cambios en Supabase. No hacen falta nuevas
migraciones para C3-D1. No se activó el cambio de estados en entornos reales.

## Etapas que siguen

1. **7F-C3-D2:** clasificación/indexación del legado, unificación de rutas y revisión especializada.
2. **7F-C3-D3:** ensayo editorial real.
3. **7F-C4:** versionado del catálogo y sincronización Flutter/Drift.
4. **7F-C5:** almacenamiento persistente de imágenes/archivos en Supabase Storage
   y ampliación para imágenes dentro de opciones.
5. **7F-C6:** auditoría e historial/restauración de versiones.

Todos los demás pendientes están consolidados en
[ETAPAS_PENDIENTES.md](ETAPAS_PENDIENTES.md), incluidos contratos antiguos,
certificado por materia, juegos en staging, seguridad, anuncios y publicación.

Siguen pendientes las validaciones integrales 7F-B3-B y los despliegues anteriores,
incluido Guardián. Esta división detalla 7F-C3, no reemplaza las demás etapas.

## Commits

Backend/panel:

```powershell
cd "C:\Users\LENOVO 14ALC6\Desktop\SaberPlus-Backend"
git add admin README.md backend/.env.example backend/src/admin/admin.module.ts backend/src/admin/editorial-review.controller.ts backend/src/admin/editorial-review.service.ts backend/src/admin/editorial-review.service.spec.ts
git commit -m "feat: agregar revision editorial y publicacion controlada"
```

Flutter, solo seguimiento documental:

```powershell
cd "C:\Users\LENOVO 14ALC6\Desktop\SaberPLus\saber_plus"
git add README.md docs/ROADMAP_MOVIL.md docs/CONTENT_ADMINISTRATION.md docs/ADMIN_PANEL.md docs/ETAPAS_PENDIENTES.md
git commit -m "docs: registrar C3-D1 y consolidar etapas pendientes"
```

Los cambios anteriores de Guardián en `backend/prisma`, `backend/src/app.module.ts`,
`backend/src/guardian` y `backend/tool/probe_database.mjs` no se incluyen en estos
comandos. No se crean commits ni se hace push automáticamente.
