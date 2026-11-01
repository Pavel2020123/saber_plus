# C5 PDF/offline — continuación después de H3

**Continuación posterior de la jornada:** [P2 integrado y Android USB verificados](C5_PDF_OFFLINE_P2.md):95/95 HTTP/PostgreSQL y14/14 Flutter. Sigue contrato de caché privada P3-A; no repetir P2 por los pendientes iniciales de abajo. Sin despliegue.

31/oct/2026. H3 verificada localmente y guardada en commit `10c965f` de `fix/c5-h3-usb-cierre`. No implica merge a main, push o despliegue. Se aislaron cambios de presentación preexistentes: permanecen en el worktree, sin descartarlos ni incluirlos por accidente.

## Validación del commit aislado

Copia limpia del commit: 74/74 pruebas Flutter (editorial_image, progress_retry, student_navigation_accessibility, daily_mistake_review y widget_test), sin cambios de presentación ajenos. Análisis dirigido de los cinco archivos de producción y tres tests: sin incidencias. Estos 74 casos no son los 77 del worktree de presentación ni se suman a ellos como pruebas distintas.

Al aislar H3 se aplicó el mismo bloque síncrono de setState a recarga de historial y repaso diario, que también asignaban futuros en callbacks de estado. Hot reload confirmado después de reconectar DTD. La APK física de la jornada anterior y las capturas corresponden al worktree con presentación; no se atribuyen al commit aislado como un build Android nuevo.

## Separación aprobada por el propietario

- PDF exportable: copia descargada o impresa, aviso de que no se actualiza ni se retira a distancia.
- Contenido privado offline de la app: almacenamiento distinto; debe revalidar permisos al reconectar. No declarar esa caché implementada por guardar un PDF.

P1 backend implementa inclusión de imágenes editoriales publicadas en el generador de temas existente, permiso real antes/después, conversión WEBP→PNG y fallo explícito si no puede incluir una imagen gestionada. [Contrato, límites y evidencias backend](<../../../SaberPlus-Backend/backend/docs/C5_PDF_OFFLINE_P1.md>).

Secuencia: **P1 generador local → P2 HTTP/PostgreSQL y descarga Android → P3 caché privada y reconexión**. Después quedan proveedor persistente, fotos/evidencias y cierre operativo C5-D. Este PDF de lecciones pertenece a la app; no es el generador independiente de cuadernillos.

Sin migraciones remotas, producción ni activación de cargas. Falta integración mediante PR; los commits locales no equivalen a publicación.
