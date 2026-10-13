# SaberPlus — inicio de equipo y trabajo en paralelo

**Guía operativa, 13 de octubre de 2026.** Punto de entrada para quien clone los repositorios o retome la aplicación desde otro PC/chat. La fuente de decisiones es [TRABAJO_PARALELO.md](TRABAJO_PARALELO.md); los estados vivos están en los checkpoints de cada frente y en [ETAPAS_PENDIENTES.md](ETAPAS_PENDIENTES.md). Esta guía organiza el trabajo: **no declara módulos terminados ni autoriza despliegues**.

## 1. Reparto vigente: dos responsables, dos frentes

| Frente | Responsable | Trabajo inmediato | Checkpoint que edita |
| --- | --- | --- | --- |
| Instituciones | Propietario y su asistente | PR-I5-C2C: 6 casos HTTP/PostgreSQL y 8 humanos Android del logo; luego solicitudes estudiantiles, avisos y código institucional privado | [PR_I5_C2_LOGO.md — Checkpoint del propietario](PR_I5_C2_LOGO.md#checkpoint-del-propietario) y acta espejo backend |
| Orientación vocacional | Compañero y su asistente | OV-1A: auditar orientación actual y proponer preguntas, familias y reglas explicables para revisión; después OV-1B/C/D | [CHECKPOINT_OV1.md](CHECKPOINT_OV1.md), futura `OV1_ORIENTACION.md` y acta espejo backend |

**Ambos pueden trabajar Flutter y backend** dentro de su módulo; no dividir el equipo por tecnología. El compañero no continúa C2C ni juegos; el propietario no modifica OV-1 sin coordinarlo. Cima, Guardián, Rescate y territorio T5 ya tienen **validación local en su alcance**, no aprobación de producción. La siguiente etapa no se deduce de una nota histórica.

### Límites de la V1 actual

Se priorizan tres juegos competitivos verificados localmente: Cima, Guardián y Rescate. Trivia, Duelo, Tira, Memoria y Batallas **competitivos** quedan aplazados, sin borrar sus modos normales ni recursos. OV-1, perfiles, insignias, instituciones y demás funciones no se eliminan. La sustentación de noviembre no equivale a lanzamiento comercial.

## 2. Primera sesión en un PC nuevo

1. Confirmar quién es el responsable y leer **los dos** repositorios. Ambos aparecen públicos en GitHub al 13/10/2026; eso da lectura, no permisos de escritura. Solicitar acceso de colaborador para publicar ramas o coordinar un fork/PR con el propietario; **no compartir tokens, contraseñas ni archivos .env**.
2. Descargar los repos en **carpetas distintas**. No clonar encima de un directorio con trabajo previo.
3. Antes de editar: comprobar `git status --short`, rama actual, `git log -5 --oneline` y `git remote -v` (no divulgar la URL si contiene credenciales). Leer README, AGENTS aplicables, contratos y checkpoint del propio frente.
4. Solo con árbol de trabajo limpio, traer `main` por fast-forward y crear/seleccionar la **rama de su frente**. Si hay cambios sin guardar, divergencia o conflictos, detener la operación Git y consultar; no hacer `reset --hard`, `stash` indiscriminado ni force-push.
5. Antes de conectar pruebas reales, preparar herramientas según `pubspec.yaml` y `backend/package.json`. Las pruebas de PostgreSQL necesitan base local aislada y las físicas, teléfono Android con autorización del propietario. **No usar Supabase/Render ni credenciales de otro PC para sustituirlas**.

```powershell
# Ejecutar desde una carpeta de proyectos vacía
git clone https://github.com/Pavel2020123/saber_plus.git
git clone https://github.com/Pavel2020123/SaberPlus-Backend.git

# Repetir EN CADA repositorio afectado, después de verificar status limpio
git status --short
git branch --show-current
git log -5 --oneline
git switch main
git pull --ff-only origin main
# Solo si la rama aún no existe:
git switch -c feat/orientacion-vocacional
# El propietario usa feat/instituciones-c2c, no la rama del compañero
```

Si una rama ya existe, usar `git switch <rama>` en vez de `-c`. No ejecutar los comandos a ciegas: comprobar el directorio y los cambios previos. Usar el mismo nombre de rama en ambos repos cuando una entrega los afecte; no crear cambios vacíos solo por simetría.

## 3. Qué puede tocar cada equipo

| Frente | Puede trabajar | No debe modificar sin coordinación |
| --- | --- | --- |
| Instituciones | Directorio, solicitudes, perfil/logo, administración institucional, API, tests y actas PR-I5 | Cuestionario OV-1, reglas vocacionales, sus tests y checkpoint |
| OV-1 | Preguntas e intereses, reglas, persistencia privada, cuestionario Flutter, resultados, recursos Sabi de orientación, tests y actas OV-1 | Instituciones, solicitudes/códigos, rankings, XP o checkpoint C2C |

**Archivos de propiedad compartida:** `schema.prisma`, migraciones, `app.module.ts`, rutas/navegación, `pubspec.yaml`/`pubspec.lock`, `package.json`/`package-lock.json`, configuración e índices/roadmap general. **Avisar antes de editarlos**, acordar el responsable de integración, hacer diffs pequeños y probar el conjunto. Nunca modificar una migración aplicada ni copiar un lock completo de otra rama. Dos PR sin conflictos de Git pueden ser incompatibles a nivel API/BD.

**Documentación:** cada responsable actualiza su checkpoint **después de cada prueba/avance**, y su acta backend cuando corresponda. El propietario consolida `ETAPAS_PENDIENTES.md`, README, índice e historial al recibir/integrar una entrega, no ambos simultáneamente tras cada caso.

## 4. Rutina para desarrollar, probar y entregar

1. **Elegir un solo bloque pequeño.** Leer su contrato/código/tests; registrar decisión pendiente antes de implementar. No agregar alcance, rediseños ni correcciones ajenas por iniciativa propia.
2. **Crear y probar en la rama del frente.** Ejecutar pruebas dirigidas, regresiones necesarias y compilación/análisis según los manifests. Distinguir unitarias simuladas, integración real SQL/HTTP y confirmaciones humanas Android. No inventar aprobaciones ni reciclar resultados de sesiones anteriores.
3. **Actualizar el checkpoint propio.** Incluir fecha, ramas y HEAD de ambos repos, cambios, migraciones, pruebas aprobadas/fallidas/omitidas, evidencias, decisiones abiertas, límites y **siguiente acción exacta**. Nunca incluir contraseñas, sesiones JWT o datos reales de alumnos.
4. **Revisar el diff y guardar en commit acotado**, solo con autorización del responsable. `git add` de rutas explícitas; `git diff --cached`, `git diff --check` y pruebas relevantes. No mezclar cambios del compañero.
5. **Publicar la rama y abrir PR hacia `main`** tras autorización. Si la entrega afecta Flutter y API, enlazar **dos PR** y explicar versión de contrato, esquema/migraciones, orden de integración y pruebas de compatibilidad.
6. **Revisar juntos antes del merge.** No hacer push directo a `main`, merge, despliegues ni migraciones remotas por seguir esta guía. El propietario autoriza el merge. Después, la otra persona incorpora `origin/main` a su rama sin perder su trabajo y repite pruebas afectadas.

```powershell
git status --short
git diff --check
git diff --stat
# Elegir solo archivos propios, por ejemplo:
git add docs/CHECKPOINT_OV1.md
git diff --cached
git diff --cached --check
git commit -m "docs: registrar avance verificable OV-1A"
# Solo cuando el responsable autorice publicar:
git push -u origin HEAD
```

Una entrega **no está cerrada** solo porque compila. Debe tener criterios cumplidos, evidencia reproducible, permisos/privacidad verificados en su alcance, checkpoint y límites actualizados, y revisión de compatibilidad entre repositorios. Las pruebas físicas, iOS y producción **no se acreditan** con unitarias.

## 5. Plantilla mínima de checkpoint y relevo

```text
Fecha y responsable:
Frente / subetapa:
Flutter: rama / HEAD inicial / HEAD final:
Backend: rama / HEAD inicial / HEAD final:
Cambios realizados y archivos:
Migraciones nuevas (si aplica):
Pruebas: comando, entorno, PASS/FAIL/SKIP, evidencia automática/SQL/HTTP/humana:
Problemas / riesgos / datos aún no verificados:
Decisiones que requiere el propietario:
Estado: preparado / implementado / validado localmente / pendiente:
PR y commits publicados (si existen):
SIGUIENTE PASO EXACTO:
```

En una sesión interrumpida, registrar el último caso confirmado **antes** de cerrar servicios. El PC siguiente prepara nueva base local, credenciales ficticias y USB; no supone que las sesiones del otro equipo siguen vivas.

## 6. Integración y coordinación entre ambos

- Avisar antes de tocar esquema, locks, navegación, permisos, autenticación o documentos globales; reservar un responsable por cambio compartido.
- Cada PR de backend debe documentar si Flutter actual necesita nuevos endpoints, si hay migraciones y cómo se mantiene compatibilidad temporal. Revisar orden **API/BD y cliente** antes de fusionar o desplegar.
- En conflictos, revisar cada hunk con el otro responsable; no usar automáticamente «ours/theirs», ni reescribir ramas compartidas con force-push. Comprobar migraciones acumuladas en base local desechable.
- Integrar PR pequeños durante el desarrollo, no esperar hasta terminar OV-1D; hacer una revisión conjunta de estado y bloqueos al menos una vez por semana.
- La falta de permisos GitHub no autoriza compartir contraseñas; usar colaboración GitHub o fork/PR según lo acordado.

## 7. Qué viene después (propuesta, aún no autorizada)

| Ronda | Propietario | Compañero | Dependencias |
| --- | --- | --- | --- |
| Actual | PR-I5-C2C y resto de solicitudes/avisos/código institucional | OV-1A/B/C/D | Checkpoints propios y revisión de reglas OV-1A |
| Propuesta siguiente | Académico, profesor/panel, MA-1/2/3, C4/C6 y certificados | PR-I3 insignias anuales; después PR-I4 perfiles/búsqueda | P5/D3 **pausados sin autorización**; C5 antes de fotos generales; premios solo de juegos validados |
| Propuesta posterior | PR-I6/PR-I6-T ranking institucional | Pruebas PR-I4 y apoyo QA-1 | PR-I5 completo, PR-I3/4 compatibles, sin doble conteo histórico |
| Integración de ambos | PR-I7, seguridad, QA, UI-F/Sabi y preparación de sustentación | Misma integración según incidencias asignadas | Ensayos locales reales, privacidad y permisos; operaciones remotas autorizadas aparte |

Confirmar **cada nuevo reparto** con el propietario y actualizar TRABAJO_PARALELO/roadmap; esta tabla no asigna automáticamente trabajo futuro. Los juegos competitivos aplazados y lanzamiento comercial tienen planificación separada.

## 8. Enlaces para empezar sin este chat

- [Reparto, contrato y prompt OV-1](TRABAJO_PARALELO.md).
- [Checkpoint Instituciones](PR_I5_C2_LOGO.md#checkpoint-del-propietario) y [guía de pruebas C2C](RELEVO_PRUEBAS_LOCALES.md#8-prompt-del-propietario--instituciones).
- [Checkpoint OV-1](CHECKPOINT_OV1.md).
- [Roadmap vivo general](ETAPAS_PENDIENTES.md#ruta-vigente-del-equipo).
- [Alcance V1 noviembre](ALCANCE_V1_NOVIEMBRE_2026.md).
- [Auditoría documental del 13 de octubre](AUDITORIA_DOCUMENTAL_2026_10_13.md).
- Backend: [SaberPlus-Backend](https://github.com/Pavel2020123/SaberPlus-Backend), carpeta `backend/docs/`; mismo proyecto, repositorio diferente.
