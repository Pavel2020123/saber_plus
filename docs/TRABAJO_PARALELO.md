# Trabajo paralelo: instituciones y orientación vocacional

Acuerdo del 12 de octubre de 2026. Dos frentes simultáneos, no dos aplicaciones.
Este reparto actualiza la antigua secuencia que hacía esperar OV-1 hasta cerrar
instituciones. No cambia las reglas de producto ni declara etapas terminadas.

## Responsables y siguiente paso

| Equipo | Responsabilidad | Por dónde empezar |
|---|---|---|
| Propietario y su asistente | Instituciones integradas; MA-1R/R1–R3 locales | [Reportes](MA1R_REPORTES_PREGUNTAS.md): R1 autorizada, R2 backend121 suites/1.560 y build; R3:32 dirigidas Flutter/109 ADMIN aprobadas. SQL no aplicado; sigue R4 PostgreSQL/Nest/Android. Rama feat/ma1r-reportes-preguntas desde base documental, pendiente de integrar por PR. No modificar OV-1. |
| Compañero y su asistente | OV-1: test de intereses vocacionales, Flutter y backend necesarios | En curso según el propietario; sin entrega nueva verificada aquí. Seguir su checkpoint para A contenido/reglas → B persistencia → C cliente → D validación, no reiniciar trabajo ya documentado en su rama. |

El compañero no tiene que esperar a que termine C2C. El propietario no asume
que OV-1 avanzó hasta recibir cambios y evidencia. Cada frente conserva su acta.

## Alcance del compañero: OV-1

Leer [contrato de orientación](ORIENTACION_Y_TERRITORIO.md), sección OV-1.

1. **OV-1A:** propuesta de cuestionario y puntuación explicable. Las 24–30
   preguntas son una propuesta, no contenido ya aprobado. Registrar decisiones
   pendientes y solicitar revisión del contenido antes de publicar.
2. **OV-1B:** contrato y persistencia privada; autorización por cuenta,
   reanudación, versiones e historial, retención y eliminación explícitas.
3. **OV-1C:** introducción, progreso, corrección de respuestas, guardar/continuar
   y resultados con familias afines y carreras para explorar.
4. **OV-1D:** Sabi estático, accesibilidad y pruebas. Documentar empates,
   respuestas incompletas, permisos, desconexión/reanudación y texto grande.

Reutilizar el módulo existente sin confundir rendimiento académico con intereses.
No diagnosticar ni afirmar que el cuestionario es científicamente validado.
Sin XP, ranking, certificado, segmentación publicitaria ni publicación automática
de resultados a docentes o instituciones. No añadir pagos, juegos ni animaciones.
No inventar ilustraciones disponibles ni fuentes consultadas: comprobar assets
y verificar fuentes oficiales cuando se prepare el catálogo de carreras.

## Primera sesión del compañero: instrucciones concretas

1. Confirmar acceso de lectura y permisos de colaboración en los dos repositorios y comprobar que esta documentación ya
   está publicada. Un archivo guardado o un commit local no llega al otro PC.
   El propietario confirma los hashes publicados de ambos repos antes de empezar.
2. Revisar `git status --short`, `git branch --show-current`, `git remote -v`
   y `git log -5 --oneline` en cada repo. No compartir la salida de remotos si
   contuviera tokens. Confirmar rutas locales; no copiar las del propietario a ciegas.
3. Con worktree limpio, actualizar main y crear/seleccionar la rama OV-1 según
   instrucciones inferiores. Si falta acceso o hay divergencia, detener solo
   la operación Git y pedir ayuda; no volver público el repo ni forzar el pull.
4. Leer AGENTS aplicables, arquitectura, este reparto y el contrato OV-1.
   Inspeccionar primero estos archivos existentes de Flutter:
   - `lib/features/profile/domain/career_orientation.dart`.
   - `lib/features/profile/presentation/career_orientation_providers.dart`.
   - `lib/features/profile/presentation/career_orientation_page.dart`.
   - `test/career_orientation_test.dart`.
   El proveedor actual usa desempeño académico; no reemplazarlo silenciosamente
   por resultados de intereses. Localizar navegación, sesión y repositorios antes
   de conectar el módulo nuevo. En backend buscar contratos/modelos relacionados;
   no asumir que ya existen endpoints de cuestionario ni crearlos duplicados.
5. Crear `docs/OV1_ORIENTACION.md` y, cuando afecte API,
   `backend/docs/OV1_ORIENTACION.md` en el otro repo. Anotar HEAD inicial de ambos,
   archivos revisados, estado encontrado y decisiones pendientes sin secretos.
6. Primera entrega: OV-1A con preguntas propuestas, familias, escala, tratamiento
   de «No sé»/incompletos/empates, ejemplos de cálculo y versión de reglas.
   Los umbrales y reglas no definidos se presentan al propietario para acordarlos;
   no convertir una suposición en una decisión aprobada. Puede preparar contratos
   y pruebas locales mientras se revisa; no publicar recomendaciones sin revisión.
7. Continuar B/C/D por bloques pequeños, con acta y pruebas propias. No levantar
   servicios para redactar OV-1A. No ejecutar pruebas del logo o todo el roadmap
   por seguir el prompt general: esas son responsabilidad del otro frente.

## Criterios para aceptar una entrega OV-1

| Bloque | Evidencia mínima |
|---|---|
| A | Preguntas propias y reglas versionadas, ejemplos reproducibles, decisiones aprobadas o pendientes identificadas; no afirmar validación psicológica. |
| B | Contrato documentado y pruebas de aislamiento entre dos cuentas, autenticación, validación, reanudación, repetición/versiones e historial. Persistencia/migraciones comprobadas en PostgreSQL local antes de declarar integración cerrada. |
| C | Cuestionario navegable, respuestas corregibles, progreso guardado, errores/red y cambio de sesión sin filtrar datos; resultados explicables y regresión del módulo académico existente. |
| D | Empates/incompletos, accesibilidad y texto grande; prueba humana Android separada de unitarias, recursos Sabi disponibles y fuentes verificadas. iOS y revisión de contenido pendientes se declaran, no se inventan. |

Comandos iniciales verificables: `flutter test test/career_orientation_test.dart`
en Flutter; añadir los tests nuevos del módulo y `flutter analyze`. En `backend/`,
`npm run build` y `npm test -- --runInBand <ruta-del-test-existente-o-nuevo>`
(sustituir el marcador por un archivo real). Leer manifests y requisitos antes
de ejecutarlos. `npm run lint` incluye `--fix`: no usarlo como auditoría sin cambios.
Documentar comandos y conteos reales; no copiar los resultados históricos de C2.
Estas comprobaciones dirigidas no equivalen a una auditoría de todo el proyecto.

## Límites de edición

- El propietario mantiene instituciones y sus contratos/tests/panel.
- El compañero mantiene orientación y sus contratos/tests/pantallas.
- No editar módulos del otro frente sin coordinar un cambio concreto.
- Archivos compartidos: `pubspec.yaml`, locks, navegación, `app.module.ts`,
  `schema.prisma`, configuración y documentación general. Avisar antes de tocarlos,
  mantener diffs pequeños y registrar cambios en la entrega. No rehacer arquitectura.
- Cada cambio de esquema lleva su migración nueva identificable. No editar ni
  borrar migraciones del otro frente o migraciones ya aplicadas. Verificar el
  esquema y orden combinado al integrar; Git sin conflictos no garantiza compatibilidad.

## Ramas e integración

Para trabajar simultáneamente se acuerdan ramas por frente en cada repo afectado:

- Propietario: `feat/instituciones-c2c` (y ramas pequeñas posteriores por entrega).
- Compañero: `feat/orientacion-vocacional`.
- `main`: base compartida, recibe cambios revisados. La regla anterior de editar
  directamente main corresponde al trabajo individual y queda sustituida aquí.

Se necesitan ambos repositorios. Ambos son públicos, verificado mediante API
GitHub el 13 de octubre de 2026; no se cambió su visibilidad. Clonar no otorga
permisos para push: coordinar acceso de colaborador sin compartir credenciales. Rutas del propietario:

```text
Flutter: C:\Users\LENOVO 14ALC6\Desktop\SaberPLus\saber_plus
Backend: C:\Users\LENOVO 14ALC6\Desktop\SaberPlus-Backend
```

En cada repo, con trabajo limpio y coordinado, actualizar main y crear la rama
del frente. No ejecutar si hay cambios sin guardar; revisar primero. Ejemplo
para el compañero (adaptar ruta en su PC):

```powershell
git status --short
git switch main
git pull --ff-only origin main
git switch -c feat/orientacion-vocacional
```

Si la rama ya existe, seleccionarla en lugar de recrearla. Para entregar:
`git add` de archivos precisos, `git diff --cached`, pruebas y commit del bloque;
después `git push -u origin feat/orientacion-vocacional` cuando el responsable
quiera publicarlo. Abrir un PR por repo afectado, enlazando ambos PR si dependen
entre sí. El propietario revisa antes de integrar. No hacer push directo a main,
force-push, reset ni merges automáticos por seguir este documento.

Integrar bloques pequeños, no esperar al final de OV-1. Tras cada integración,
el otro equipo incorpora main a su rama coordinadamente y ejecuta regresiones.
Un PR de API y otro Flutter deben declarar compatibilidad y orden de integración.

Para incorporar avances nuevos, primero guardar el propio trabajo y verificar
status limpio. Desde la rama del frente: `git fetch origin` y, coordinadamente,
`git merge origin/main`. Si hay conflictos, revisar cada archivo con el otro
responsable; no aceptar todo «ours/theirs» ni reemplazar locks a ciegas. Volver
a generar locks con la herramienta correspondiente si es necesario y ejecutar
las pruebas afectadas. No reescribir una rama ya compartida con force-push.

Ejemplos de mensajes: `docs: definir cuestionario y reglas de orientacion OV-1A`,
`feat: agregar persistencia privada de orientacion OV-1B` y
`feat: agregar cuestionario vocacional OV-1C`. Usar cada uno solo para el alcance
realmente completado. En la entrega indicar ruta del repo y archivos exactos para
`git add`; no copiar comandos que incluyan archivos inexistentes o cambios ajenos.

## Pruebas y documentación de cada entrega

### Un checkpoint por frente

- Instituciones: el propietario mantiene las actas C2/C3/C4 y el
  [cierre consolidado](CIERRE_INSTITUCIONES_LOCAL.md). Ya no queda una prueba C2C
  obligatoria; cualquier corrección nueva se documenta en su acta concreta.
- OV-1: el compañero actualiza [CHECKPOINT_OV1](CHECKPOINT_OV1.md) después de cada
  prueba/avance y su acta detallada cuando exista.
- Roadmap general: solo el propietario consolida al recibir un bloque, integrar
  un PR o acordar un cambio de alcance. No se edita simultáneamente tras cada caso.
- Backend: cada responsable mantiene su acta específica; el propietario consolida
  índices generales. Registrar resultados locales sin convertirlos en despliegue.

Esta regla sustituye instrucciones antiguas de actualizar el roadmap después de
cada prueba; conserva el registro inmediato en el checkpoint del propio frente.

Cada PC usa su propia base local desechable y sus propias cuentas ficticias.
Docker se necesita para pruebas reales PostgreSQL; el teléfono USB para Android,
no para redactar reglas ni ejecutar todas las pruebas unitarias. No compartir
credenciales ni usar Supabase/Render para sustituir el entorno local.

Cada equipo entrega: archivos, contratos/migraciones, pruebas ejecutadas y
resultados, límites, pendientes, hash/PR de ambos repositorios y siguiente paso.
El compañero mantiene `docs/OV1_ORIENTACION.md` y un acta equivalente en backend
cuando comience la implementación. No existen por quedar nombradas aquí.
Nosotros mantenemos [cierre institucional](CIERRE_INSTITUCIONES_LOCAL.md). El propietario consolida roadmap,
README e historial al integrar para evitar dos ediciones simultáneas de la ruta.

## Prompt para el compañero

```text
Tu frente es OV-1, orientación vocacional de SaberPlus. Instituciones ya tiene
cierre local; su integración y próximos bloques corresponden al propietario.
No repitas C2C ni cambies módulos ajenos. Retoma tu checkpoint y rama vigente;
las instrucciones de primera sesión no obligan a reiniciar avances con evidencia.
Sigue la sección «Primera sesión del compañero» y los criterios de entrega de
TRABAJO_PARALELO.md. Confirma que recibiste la documentación publicada; no asumas
que los últimos cambios del propietario ya están en GitHub.
Lee docs/TRABAJO_PARALELO.md, ORIENTACION_Y_TERRITORIO.md (OV-1), arquitectura,
roadmap y AGENTS aplicables de ambos repositorios. Verifica status/rama/HEAD;
no descartes cambios ni asumas rutas del PC anterior. Trabaja en la rama
feat/orientacion-vocacional en cada repo afectado, no directamente en main.
Audita la orientación existente; comienza por OV-1A y documenta contenido,
reglas y decisiones pendientes antes de avanzar B/C/D. Preserva privacidad y
separa intereses del desempeño académico; no añadas XP ni certificados.
Coordina schema.prisma, dependencias, navegación y configuración compartida.
Prueba cada bloque y actualiza tu acta, indicando qué no probaste. Entrega rutas,
archivos, mensaje de commit, hashes/PR y comandos de push de tu rama. No hagas
push, merge, despliegue ni cambios remotos sin petición expresa del responsable.
```
