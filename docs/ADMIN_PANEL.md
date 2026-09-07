# 7F-C3-B — Editor de lecciones y nombres académicos

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

No hay todavía editor de preguntas/casos, carga de imágenes ni botones de
publicación. Un borrador nuevo no aparece automáticamente en Flutter: deberá
revisarse y publicarse cuando terminemos el flujo editorial.

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

## Reglas de esta entrega

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

Para la conexión real, seguir `admin/README.md` en el backend: cuenta ADMIN,
API con las rutas nuevas y origen del panel autorizado por CORS. La contraseña
y el JWT se usan para autenticar, nunca se copian a archivos de la app. No se
necesitan credenciales de PostgreSQL ni claves de Supabase en el panel.

El acceso permanece en memoria de la pestaña y se pierde al recargar. Cerrar
sesión local no equivale a revocar un token en el backend; eso conserva su etapa.

## Verificación y límites

`npm run check` y `npm test` se ejecutan dentro de `SaberPlus-Backend/admin`.
Las pruebas comprueban API/servidor local, seguridad básica y contrato del catálogo.
Resultado local del panel: 23 pruebas aprobadas y sintaxis validada. Incluyen
dobles DOM para lógica del editor, no una prueba visual de navegador. En backend
se añadieron pruebas de permisos declarados, DTO, bloqueos, revisiones, nombres,
solo lectura y URLs; catálogo/editor: 44 pruebas aprobadas. Suite completa del
backend: 312 pruebas en 55 suites. Compilación y lint de archivos cambiados correctos.
Revisión visual, CORS y prueba con cuenta ADMIN real quedan pendientes.
No hubo despliegues, migraciones ni cambios en Supabase. No hacen falta nuevas
migraciones para C3-B; sí desplegar sus nuevas rutas para usar el editor real.

## Etapas que siguen

1. **7F-C3-C:** editor de preguntas y casos, opciones, explicaciones y referencias a imágenes.
2. **7F-C3-D:** revisión/publicación en el panel, clasificación del legado y prueba editorial completa.
3. **7F-C4:** versionado del catálogo y sincronización Flutter/Drift.
4. **7F-C5:** almacenamiento persistente de imágenes y archivos en Supabase Storage.
5. **7F-C6:** auditoría e historial/restauración de versiones.

Siguen pendientes las validaciones integrales 7F-B3-B y los despliegues anteriores,
incluido Guardián. Esta división detalla 7F-C3, no reemplaza las demás etapas.

## Commits

Backend/panel:

```powershell
cd "C:\Users\LENOVO 14ALC6\Desktop\SaberPlus-Backend"
git add admin README.md backend/src/admin/admin.module.ts backend/src/admin/lesson-editor.controller.ts backend/src/admin/lesson-editor.service.ts backend/src/admin/lesson-editor.service.spec.ts
git commit -m "feat: agregar editor seguro de lecciones en borrador"
```

Flutter, solo seguimiento documental:

```powershell
cd "C:\Users\LENOVO 14ALC6\Desktop\SaberPLus\saber_plus"
git add README.md docs/ROADMAP_MOVIL.md docs/CONTENT_ADMINISTRATION.md docs/ADMIN_PANEL.md
git commit -m "docs: completar etapa 7F-C3-B de lecciones"
```

Los cambios anteriores de Guardián en `backend/prisma`, `backend/src/app.module.ts`,
`backend/src/guardian` y `backend/tool/probe_database.mjs` no se incluyen en estos
comandos. No se crean commits ni se hace push automáticamente.
