# 7F-C3-A — Acceso privado y catálogo editorial

Implementado en `admin/` del repositorio oficial **SaberPlus-Backend**. No se
reintrodujeron carpetas Flutter web ni se modificó la página antigua Icfes_Vida.

## Qué se puede hacer

- Entrar con cuenta editorial ADMIN confirmada por la API.
- Navegar por áreas, temas y subtemas, en páginas de 20 registros.
- Ver estados editoriales y conteos; identificar clasificación heredada genérica.
- Crear temas y subtemas únicamente en borrador, con avisos de duplicados.
- Probar todo lo anterior en una demo local aislada y sin cuenta real.

No hay todavía editor de lecciones/preguntas, carga de imágenes ni botones de
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

Para la conexión real, seguir `admin/README.md` en el backend: cuenta ADMIN,
API con las rutas nuevas y origen del panel autorizado por CORS. La contraseña
y el JWT se usan para autenticar, nunca se copian a archivos de la app. No se
necesitan credenciales de PostgreSQL ni claves de Supabase en el panel.

El acceso permanece en memoria de la pestaña y se pierde al recargar. Cerrar
sesión local no equivale a revocar un token en el backend; eso conserva su etapa.

## Verificación y límites

`npm run check` y `npm test` se ejecutan dentro de `SaberPlus-Backend/admin`.
Las pruebas comprueban API/servidor local, seguridad básica y contrato del catálogo.
Resultado local: 14 pruebas aprobadas y sintaxis de los módulos validada.
La conexión de la herramienta de navegador falló antes de abrir una página:
la revisión visual y las pruebas con cuenta ADMIN real quedan pendientes.
No se verificó la distribución visual automáticamente ni se afirmó un flujo
completo contra staging. No hubo despliegues, migraciones ni cambios en Supabase.

## Etapas que siguen

1. **7F-C3-B:** editor de lecciones por subtema, vista previa y ajustes de nombres.
2. **7F-C3-C:** editor de preguntas y casos, opciones, explicaciones y referencias a imágenes.
3. **7F-C3-D:** revisión/publicación en el panel, clasificación del legado y prueba editorial completa.
4. **7F-C4:** versionado del catálogo y sincronización Flutter/Drift.
5. **7F-C5:** almacenamiento persistente de imágenes y archivos en Supabase Storage.
6. **7F-C6:** auditoría e historial/restauración de versiones.

Siguen pendientes las validaciones integrales 7F-B3-B y los despliegues anteriores,
incluido Guardián. Esta división detalla 7F-C3, no reemplaza las demás etapas.

## Commits

Backend/panel:

```powershell
cd "C:\Users\LENOVO 14ALC6\Desktop\SaberPlus-Backend"
git add admin .github/workflows/backend-ci.yml README.md
git commit -m "feat: crear panel editorial con acceso y catalogo privado"
```

Flutter, solo seguimiento documental:

```powershell
cd "C:\Users\LENOVO 14ALC6\Desktop\SaberPLus\saber_plus"
git add README.md docs/ROADMAP_MOVIL.md docs/CONTENT_ADMINISTRATION.md docs/ADMIN_PANEL.md
git commit -m "docs: registrar panel editorial y etapas 7F-C3"
```

Los cambios anteriores de Guardián en `backend/prisma`, `backend/src/app.module.ts`,
`backend/src/guardian` y `backend/tool/probe_database.mjs` no se incluyen en estos
comandos. No se crean commits ni se hace push automáticamente.
