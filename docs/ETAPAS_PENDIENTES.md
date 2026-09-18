# SaberPlus — trabajo pendiente tras verificación local 7F-C3-D2-F

Actualizado: 18 de septiembre de 2026. Listado para compartir con el equipo.

## Ampliación aprobada — Sabi, cuatro juegos y tres mejoras académicas

El usuario seleccionó **Salto a la cima, Rescate de estrellas, Taller de inventos
y Escudo del conocimiento**, con un protagonista compartido que está diseñando.
También seleccionó mapa de aprendizaje, repaso diferido y cobertura del banco.
Reglas acordadas y decisiones pendientes en [SABI_Y_JUEGOS_APROBADOS.md](SABI_Y_JUEGOS_APROBADOS.md).
Primera renovación elegida: **Duelo fantasma con Sabi**, captura con ambas manos y
celebración propia. [G-SABI-1A: guía de preproducción](SABI_DUELO_FANTASMA.md)
registrada; arte articulado, animación e integración todavía pendientes.
Son alcance nuevo planificado, todavía sin implementar ni calendario asignado;
se añaden al inventario de 13 bloques original, no se ocultan dentro de su recuento.
**P5 y la conexión real D3 están pausadas por decisión del usuario**, no terminadas.

Retiro de ePayco/Wompi implementado localmente en el backend: las rutas antiguas
responden 410 sin procesar pagos; se conserva el historial. Falta desplegarlo y
verificarlo en Render. Google Play Billing y D3 mantienen sus tareas pendientes.

Se añadió una [auditoría complementaria](AUDITORIA_PROYECTO_2026-09-09.md)
con correcciones locales y pruebas; no se desplegó ni se cerró D3. Se mantienen
los 13 bloques siguientes. El [resumen de funcionalidades](FUNCIONALIDADES_PARA_EL_EQUIPO.md)
distingue lo implementado de lo que todavía necesita contrato o verificación real.

**Implementado no equivale a desplegado ni probado en teléfonos.** Render ya
tuvo su despliegue inicial; no hay que repetir esa etapa desde cero. Sí quedan
actualizaciones, migraciones y verificaciones de módulos posteriores.

El roadmap principal conserva las etapas originales. Aquí se agrupan todos sus
pendientes en **13 bloques de trabajo**, incluyendo deuda de etapas anteriores:
12 de preparación del lanzamiento y uno de operación posterior (9A).
No son trece etapas originales nuevas. La comparación con el listado anterior
7F–9A está en [CONCILIACION_ROADMAP.md](CONCILIACION_ROADMAP.md).

## Punto de reanudación — leer primero al volver a trabajar

Orden actualizado: **primero completar el módulo del profesor (P1–P4-C y P5),
después retomar 7F-C3-D3**.
P1, P2 y **P3-A/P3-B (prioridades, pantallas y práctica dirigida)** tienen entregas
locales. **P4-A/P4-B preparan API, persistencia, sincronización y pantallas de
tiempo/evolución**. La implementación P4 es local; su despliegue y comprobación
real no están cerrados. **P4-C tiene implementación local de aprobación institucional**:
Flutter, API, migración y bandeja ADMIN. Faltan revisión visual, despliegue y ensayo
real. **Sigue preparar P5**, con los preparativos de commits, migraciones y despliegue
indicados abajo; no rehacer P4-C desde cero.
D3 sigue pendiente, no cancelada ni terminada.
Los 13 bloques se conservan como inventario; el cierre docente se detalla como
subetapas previas para no ocultar sus carencias dentro de una prueba integral.
Guías de entrega y pruebas: [PROFESOR_P1.md](PROFESOR_P1.md) y
[PROFESOR_P2.md](PROFESOR_P2.md), [PROFESOR_P3_A.md](PROFESOR_P3_A.md) y
[PROFESOR_P3_B.md](PROFESOR_P3_B.md), [PROFESOR_P4_A.md](PROFESOR_P4_A.md) y
[PROFESOR_P4_B.md](PROFESOR_P4_B.md), [PROFESOR_P4_C.md](PROFESOR_P4_C.md).

### Cierre del módulo profesor — antes de D3

| Subetapa | Alcance y criterio de cierre | Estado |
| --- | --- | --- |
| P1 | Corregir cálculo del avance publicado sin borrar historial, textos, ausencia de resultados y accesos rápidos. Verificar tamaños pequeños/texto ampliado. | Implementación local; ver pruebas y límites en PROFESOR_P1.md. |
| P2 | Ficha del estudiante y desglose área → tema → subtema con aciertos, errores, cantidad de evidencia y fecha. Reutiliza reglas del diagnóstico y autorización por grupo/plan, sin exponer respuestas. | Implementación local; falta ensayo real P5. Ver PROFESOR_P2.md. |
| P3-A | Persistencia y API de prioridades docentes: selección publicada, plazo/retiro, cinco preguntas únicas, idempotencia, permisos, reportes y migración. No confundir práctica con dominio. | Implementación local: 724 pruebas Jest y 11 PostgreSQL temporal; falta migración/despliegue real. Ver PROFESOR_P3_A.md. |
| P3-B | Profesor selecciona desde sus grupos; alumno ve prioridad y practica el snapshot autorizado; docente consulta cumplimiento. Repositorios remoto/demo, sesión, reintentos, estados y accesibilidad. | Implementación local con pruebas Flutter/backend/PostgreSQL. Ver PROFESOR_P3_B.md. Pendientes migración P3-A, despliegue y ensayo real P5. |
| P4-A | Persistencia privada y API de Pomodoros idempotentes; resumen propio/docente 7/30/90 días, historial confirmado, fuentes separadas, permisos y muestra parcial. | Implementación backend local con pruebas; migración/despliegue pendientes. Ver PROFESOR_P4_A.md. |
| P4-B | Cola de Pomodoro por cuenta, confirmaciones/reintentos, resumen remoto y evolución accesible desde la ficha docente. Conserva datos locales y distingue pendiente/demo/sin registros. | Implementación Flutter local; ver PROFESOR_P4_B.md. SQLite v9 conserva el historial; no sube evaluaciones ni importa el historial antiguo. Falta ensayo real P5. |
| P4-C | Solicitud de institución por profesor, verificación de evidencia mínima y aprobación/rechazo por ADMIN desde el panel web. Pendiente no equivale a institución activa. | Implementación local con pruebas. Pendientes revisión visual, migración/despliegue y ensayo real P5. Sin adjuntos documentales; coordinar archivos privados con C5. Ver PROFESOR_P4_C.md. |
| P5 | Ensayo profesor → solicitud/aprobación → grupo → estudiante, roles y aislamiento, sesión vencida, reintentos y reconexión. Cuentas y contenido de ensayo autorizados; despliegue y pruebas en dispositivos. | Pendiente después de P4-C; coordinar con bloques 6 y 7. |

No se cambian los límites comerciales ni se agregan tutores/chat. No rehacer
instituciones, grupos, invitaciones, analítica básica, alertas o exportaciones ya
implementadas. P2–P4 requieren extender sus contratos, no solo crear pantallas.
Se puede avanzar con pruebas controladas antes de D3, pero cualquier comprobación
que necesite publicación/configuración real debe quedar abierta hasta realizarla.

### P4-C — Verificación de nuevas instituciones (antes de P5)

**Motivo original:** `POST /instituciones` creaba una institución activa y asignaba
propiedad al profesor sin aprobación de SaberPlus; P4-C retira esa ruta con 410.
La verificación del correo
personal no acredita que represente al colegio. No basta ocultar el botón en
Flutter: el backend debe bloquear el acceso institucional hasta aprobarlo.

1. El profesor conserva su cuenta individual y solicita la institución con
   nombre, ubicación/contacto institucional, correo de trabajo y referencia
   pública verificable cuando exista. Buscar coincidencias antes de solicitar:
   si la institución ya existe, ofrecer invitación/vinculación, no duplicarla.
2. Evidencia mínima y proporcional: primero correo institucional y fuente
   pública; si no bastan, carta/autorización del establecimiento como adjunto
   opcional. No solicitar documentos de identidad ni datos de estudiantes para
   este trámite. Ofrecer contacto de soporte para resolver dudas, pero no usar
   una llamada o WhatsApp como único registro de aprobación.
3. Crear estados `PENDIENTE`, `REQUIERE_INFORMACION`, `APROBADA`, `RECHAZADA`
   y `SUSPENDIDA`, con fecha, motivo interno, actor ADMIN y seguimiento para el
   solicitante. El rechazo no borra la cuenta del profesor; permitir corrección
   o nueva solicitud controlada. Evitar decisiones duplicadas/concurrentes.
4. Mientras no esté aprobada, no activar códigos de grupo, invitaciones,
   importación de estudiantes, analíticas ni privilegios institucionales.
   Centralizar esta comprobación en el backend y probar cada ruta protegida;
   no confiar en el estado que muestre la app.
5. Añadir al panel web ADMIN una bandeja de solicitudes con filtros, detalle de
   evidencias, solicitud de información, aprobación y rechazo motivado. Solo
   ADMIN de SaberPlus revisa; el propietario de la solicitud no puede aprobarse.
   La app solo presenta formulario y estado, no herramientas de moderación.
6. Si se habilitan adjuntos, guardarlos en almacenamiento privado con acceso
   limitado a solicitante y revisores, tipos/tamaños permitidos, trazabilidad y
   plazo de conservación definido; nunca en URL pública ni dentro del APK.
7. Revisar instituciones creadas antes de introducir estados: no marcarlas todas
   como verificadas sin revisión ni cortar grupos existentes de forma sorpresiva.
   Migración, plan de transición, notificaciones y pruebas de regresión.
8. Probar duplicados, suplantación, acceso por rol, rechazo, corrección,
   suspensión, errores de red y una aprobación completa desde el panel. La parte
   institucional del panel deberá conectarse a staging para P5; D3 sigue siendo
   el ensayo editorial real y no queda terminado por esta conexión parcial.

**Gestión de cuentas:** las rutas ADMIN existentes permiten listar, cambiar rol
y eliminar usuarios; también hay una creación desde `lead` anterior. No equivalen
a una pantalla completa y segura de administración. Añadir una sección web ADMIN
para búsqueda, invitación/alta excepcional, suspensión/reactivación y revisión
de cuentas, con permisos, confirmaciones y auditoría. Separar la eliminación de
cuenta/datos del simple bloqueo de acceso y revisar dependencias antes de borrar.
No llevar esta sección a la app del estudiante/profesor. Coordinarla con el bloque
7 de identidad/seguridad y el ensayo real D3, sin asumir que ya está implementada.

### Próximo trabajo: preparar y ejecutar P5, antes de D3

1. Revisar los commits de ambos repositorios. Al 17 de septiembre, Pomodoro ya
   está en HEAD. Sigue pendiente el modelo `IntentoGuardian`, aunque la relación
   de Usuario ya está guardada: resolver ese trabajo previo por separado antes
   del push/despliegue. No confundir build del árbol local con checkout completo.
2. Confirmar URL exacta de Render y entorno de ensayo `saberplus-dev`, permisos y
   respaldo. Revisar/aplicar con autorización las migraciones pendientes P3-A/P4-A/P4-C
   y desplegar la versión correspondiente; no repetir el despliegue inicial.
3. Revisar visualmente P4-C y preparar cuentas reales autorizadas de ADMIN, profesor
   y estudiante, contenido de ensayo y una solicitud institucional revisada.
   Antes de migrar P4-C, comunicar la transición de 30 días para instituciones
   existentes y organizar revisión manual; no quedan automáticamente verificadas.
   No compartir contraseñas por chat.
4. Probar profesor → aprobación → grupo → prioridad → práctica del estudiante
   → cumplimiento/evidencia
   y tiempo/evolución. Comprobar separación de fuentes, días sin registros y
   conservación de datos tras cerrar/reabrir la app.
5. Comprobar permisos por rol, grupo/institución y plan, sesión vencida/cambio de
   cuenta, desconexión/reconexión y reintento idempotente de Pomodoro. Verificar
   interfaz en Android y registrar la comprobación iOS o su limitación de entorno.
6. Registrar resultados, corregir fallos y cerrar P5 solo con evidencia real.
   Después retomar D3 y sus controles editoriales D2 aún pendientes. C4 continúa
   siendo la sincronización del catálogo con Flutter, no una consecuencia
   automática de conectar el panel.

No se requieren audios nuevos para P4-B/P5. No se ejecutaron migraciones ni
despliegues reales durante la integración Flutter.

### Repositorios y contexto que se deben conservar

- App Flutter Android/iOS: `C:\Users\LENOVO 14ALC6\Desktop\SaberPLus\saber_plus`.
- Backend oficial: `C:\Users\LENOVO 14ALC6\Desktop\SaberPlus-Backend`;
  API en `backend/` y panel editorial web en `admin/`.
- Repositorio remoto del backend: `https://github.com/Pavel2020123/SaberPlus-Backend`.
  No trabajar sobre la antigua web Icfes_Vida ni sobre otra copia del backend.
- Flujo previsto: **panel administrativo → API en Render → PostgreSQL en
  Supabase**. El panel y Flutter no reciben contraseñas de base de datos.
- Render ya tuvo un despliegue exitoso. Eso no confirma que incluya los últimos
  cambios locales de auditoría, editor o retiro de pagos heredados.
- La demo editorial es aislada: sus cambios no llegan a Supabase y se pierden
  al reiniciar. No confundir una prueba en demo con D3 completada.
- No reiniciar etapas implementadas. Revisar el estado actual de ambos repositorios
  y preservar cualquier cambio del usuario antes de modificar archivos.

### Información que se debe pedir al retomar D3 (después de P1–P5)

1. URL actual y exacta del servicio Render; no deducirla del nombre del servicio.
2. Confirmar si existe una cuenta **ADMIN de SaberPlus**, no de profesor.
   No pedir su contraseña por chat; si falta, preparar su creación autorizada.
3. Confirmar si se pudo entrar a la demo y eliminar un tema/subtema en borrador
   vacío. Si no, hacer la comprobación visual pendiente antes del ensayo real.
4. Confirmar el entorno Supabase de ensayo (`saberplus-dev`, según lo acordado)
   y el origen desde el que se abrirá el panel. No solicitar ni copiar secretos
   en este documento, Git o la aplicación.

### Instrucción lista para copiar en una nueva sesión

> Lee `docs/ETAPAS_PENDIENTES.md` completo y `docs/PROFESOR_P4_C.md`. Retoma primero
> el módulo del profesor: P1, P2, P3-A/P3-B y P4-A/P4-B tienen entregas locales;
> P4-C también tiene entrega local (solicitud/aprobación de instituciones).
> Sigue preparar P5: revisión visual pendiente, commits coherentes (incluido el
> trabajo previo de Guardián), migraciones, despliegue autorizado y cuentas de ensayo.
> Verifica el estado actual antes de programar. D3, conectar el panel al backend
> real, se hace después y no debe perderse. No rehagas funciones existentes ni
> asumas que lo local está desplegado. Conserva mis cambios, no pidas contraseñas
> y confirma el entorno y la autorización para cualquier operación real. Al
> terminar actualiza este documento con lo probado, lo pendiente, la siguiente
> etapa y los comandos de commit con sus rutas. No hagas commits ni despliegues
> automáticamente.

## 1. 7F-C3-D2 — Legado y unificación editorial

- Ajuste D2-F implementado localmente: eliminación confirmada de temas/subtemas
  en borrador vacío, nunca publicados ni usados. No borra contenido ni hijos.
  No es una papelera; restauración/auditoría siguen pendientes en C6.
- **D2-A implementada localmente:** 15 escrituras administrativas antiguas
  retiradas con HTTP 410, carga demo HTTP retirada y bloqueo común por área.
  El panel conserva sus rutas vigentes. Falta desplegar y verificar en entorno real;
  no reutilizar métodos internos heredados como vía alternativa.
- **D2-B implementada localmente:** API ADMIN de indexación de huellas nulas
  por lotes, vista previa/revisión/confirmación y reportes paginados de duplicados.
  No modifica contenido, fechas, clasificación ni publicación. SQL/rollback local
  probado en D2-F; falta operarla en el entorno objetivo con respaldo/autorización.
  Escrituras apagadas por defecto.
  El editor conserva el bloqueo si supera 2000 candidatos sin indexar.
- Revisar duplicados y clasificaciones genéricas como Banco General sin
  atribuirles temas inventados ni cambiar resultados históricos.
- **D2-C implementada localmente:** API de reclasificación con destino/revisión/
  confirmación para preguntas sin uso registrado, dentro de su área. Conserva
  contenido/estado y bloquea publicadas, respuestas, juegos e intentos JSON.
  Faltan verificación visual y operación autorizada. D2-F verifica consultas y
  concurrencia en PostgreSQL temporal. Preguntas usadas requieren versiones en C6.
- **D2-D implementada localmente:** API especializada CLOZE, guardado/retiro
  protegido, validación común y revisión de texto/opciones/clave antes de publicar.
  Compatible con Flutter; solo borradores nunca publicados y sin uso. No se
  activó publicación ni se modificó contenido real.
- **D2-E implementada localmente:** panel con formularios CLOZE, indexación,
  coincidencias paginadas y reclasificación con selectores tema/subtema. Demo
  aislada y 54 pruebas de lógica/HTTP aprobadas; falta prueba visual en navegador.
- **D2-F verificación local implementada:** PostgreSQL desechable, SQL versionado,
  consultas y concurrencia reales, rollback y protección de uso histórico. No se
  utiliza Supabase ni la base local habitual. Revisión visual y operación autorizada
  del legado siguen pendientes. No activar `EDITORIAL_PUBLICATION_ENABLED` antes
  de completar estos controles y preparar D3.

## 2. 7F-C3-D3 — Conectar el panel al backend y ensayo editorial real

**Estado: pendiente de conexión y verificación real.** El objetivo es trabajar
desde el panel con una cuenta ADMIN y guardar contenido de ensayo en la base
correcta, sin usar la demo. La sincronización del catálogo con Flutter es C4;
conectar el panel por sí solo no garantiza que lo nuevo aparezca ya en la app.

### Orden de ejecución

1. Revisar las guías y configuración existentes en ambos repositorios, el commit
   desplegado en Render y su estado de salud. Identificar cambios y migraciones
   faltantes, sin aplicarlos a ciegas ni reiniciar el despliegue desde cero.
2. Confirmar la base de ensayo, respaldo y permisos antes de cualquier migración
   u operación sobre datos. Completar los controles D2 aplicables y preparar el
   despliegue de cambios pendientes con autorización del usuario.
3. Configurar el panel para usar la URL real de la API en lugar de la demo,
   siguiendo su configuración existente. Autorizar únicamente su origen concreto
   por CORS y verificar HTTPS. No resolver permisos con un comodín indiscriminado.
4. Iniciar sesión con ADMIN y comprobar que profesor/estudiante no pueden acceder
   a las funciones editoriales. Verificar caducidad y cierre de sesión.
5. Seleccionar un área del catálogo y crear tema, subtema, lección, caso y pregunta
   de ensayo propios/autorizados. Verificar las cinco áreas existentes; no asumir
   que el panel ya tiene creación de áreas ni crear duplicados para probar.
6. Guardar borradores, recargar, cerrar sesión y volver a entrar: comprobar que
   los registros siguen en el catálogo remoto. Contrastar su persistencia en la
   base confirmada sin exponer credenciales ni datos de otros usuarios.
7. Probar duplicados, clasificación área/tema/subtema, fallos de red, conflictos
   entre editores y borrado de un borrador vacío. No eliminar contenido utilizado
   ni reenviar automáticamente una escritura de resultado incierto.
8. Solo después de los controles previos y con autorización, habilitar las
   banderas editoriales necesarias, revisar y publicar contenido de ensayo en
   orden. Verificar archivado sin alterar historial; no activar operaciones de
   legado innecesarias para este ensayo.
9. Registrar evidencia y resultados, actualizar el estado de D3 y dejar
   identificada la siguiente tarea C4. Si falta navegador, cuenta o acceso real,
   anotar el bloqueo: las pruebas locales no cierran esta etapa.

### Criterios para darla por terminada

- [ ] Panel conectado a la API correcta, fuera de modo demo.
- [ ] ADMIN entra; roles no autorizados quedan bloqueados por el servidor.
- [ ] Contenido de ensayo guardado en Supabase y recuperado tras recargar/reingresar.
- [ ] Revisión, publicación y archivado comprobados con controles D2 satisfechos.
- [ ] Duplicados, errores de red, conflictos y borrado permitido comprobados.
- [ ] Prueba visual real y accesibilidad básica registradas.
- [ ] Commit desplegado, configuración no secreta y resultados documentados;
      pendientes claramente separados de lo verificado.

### Alcance original que se conserva

- Preparar una cuenta ADMIN autorizada y contenido de ensayo propio/autorizado.
- Desplegar las rutas editoriales y autorizar el origen del panel por CORS.
- Probar en navegador real: crear tema, subtema, lección, caso y pregunta;
  revisar, publicar en orden y archivar sin afectar historial.
- Validar errores, duplicados, recursos, caducidad de sesión, dos editores y
  pérdida de conexión. Comprobar permisos de ADMIN frente a profesor/estudiante.
- Revisar accesibilidad del panel y despliegue HTTPS si se compartirá públicamente.

## 3. 7F-C4 — Catálogo versionado y sincronización Flutter/Drift

- Publicar un contrato versionado para detectar altas, cambios y retiradas.
- Actualizar catálogo y lecciones en la app sin recompilar por cada cambio.
- Invalidar/renovar cachés y descargas, conservar progreso y resolver conflictos.
- Asegurar que borradores o contenido archivado no aparezcan en actividades nuevas.
- Probar actualizaciones con conectividad intermitente y contenido previamente descargado.

## 4. 7F-C5 — Imágenes y archivos persistentes

- Supabase Storage con permisos, límites, tipos de archivo y referencias estables.
- Carga desde el panel, metadatos, texto alternativo, derechos y recursos faltantes.
- Ampliar el modelo Respuesta, contrato y Flutter para **imágenes dentro de opciones**.
- Mantener imágenes de enunciados/casos y recursos de lecciones/PDF disponibles
  tras reinicios o despliegues; validar acceso y descarga sin exponer secretos.
- Comprobar compatibilidad con las descargas offline y el catálogo versionado.
- Conservar fuente, titular, licencia y evidencia de autorización del contenido
  (preguntas, casos y lotes), además de los derechos de sus archivos adjuntos.

## 5. 7F-C6 — Auditoría, versiones y recuperación editorial

- Registrar quién cambió qué, cuándo y con qué resultado.
- Consultar versiones anteriores y restaurar de forma controlada.
- Corregir contenido que ya se utilizó sin reescribir resultados de alumnos.
- Definir y probar respaldo/recuperación para las operaciones editoriales.

## 6. 7F-B3-B y 6F-P — Integración móvil, despliegues y Guardián

- Revisar y aplicar las migraciones pendientes con respaldo y ambiente confirmado,
  incluida Guardián; desplegar los módulos nuevos en el backend oficial.
- Preparar cuentas verificadas de ensayo de estudiante y profesor, convocatoria
  y banco autorizado/publicado. Cargar contenido revisado, no datos personales reales.
- En teléfonos, verificar sesión, diagnóstico, práctica, progreso, recursos,
  certificados, instituciones y roles usando la API real.
- Probar juegos, recuperación tras cierre/pérdida de red y dos dispositivos en
  multijugador; validar reloj, reconexión, ranking y recompensas confirmadas.
- Revisar animaciones, sonido, reducción de movimiento y rendimiento en Android/iOS.
  Los motores y animaciones ya implementados no se cuentan como juegos por rehacer.

## 7. Cierre de identidad, contratos y seguridad

- Backend de **una única sesión/dispositivo activo**, revocación y comprobación
  en cada solicitud protegida; el cliente ya tiene parte de esta frontera.
- Refresh tokens, rotación, expiración y cierre/revocación centralizados.
- Restringir en el servidor las rutas permitidas mientras siga pendiente el
  cambio inicial de contraseña; no depender únicamente de la redirección móvil.
- Persistir sesiones en PostgreSQL vinculadas a un identificador aleatorio de
  instalación; cerrar remotamente/todas las sesiones y revocar por reemplazo,
  cambio o recuperación de contraseña y eliminación de cuenta. Auditar lo mínimo.
- Implementar eliminación de cuenta/datos y definir conservación, anonimización
  o eliminación por categoría, con revisión de las obligaciones aplicables.
- Verificar límites de solicitudes y defensa contra intentos repetidos de acceso;
  no dar por suficiente una protección existente sin ensayarla en staging.
- OpenAPI versionado y errores uniformes para app, panel y backend.
- Universal Links/App Links HTTPS con dominio y flujos reales de correo,
  verificación y recuperación comprobados.
- Configurar/probar SMTP y conservar enlaces personalizados como respaldo.
- Consentimiento versionado y tratamiento de la audiencia real, incluidos
  adolescentes; revisar privacidad y permisos antes de incorporar SDK comerciales.

## 8. Contratos académicos pendientes de etapas anteriores

- Recuperación idempotente de intentos respaldada por API, sin duplicar respuestas.
- Recuperar resultados tras perder conexión al entregar, sin duplicar calificación
  ni XP. Probar reintentos y caducidad de sesión en la cola offline existente.
- Contrarreloj autoritativo: cierre al vencer y calificación de preguntas omitidas.
- Guardar inicio/vencimiento en servidor, no reiniciar al reabrir la app, admitir
  la entrega parcial según el plazo y separar SIN_RESPUESTA de respuesta incorrecta.
  Rechazar respuestas tardías y permitir consultar el resultado por intento.
- Banco histórico: cargar pruebas propias/autorizadas y publicar su contrato.
- Ediciones y jornadas con titular/licencia/referencia, estados disponible,
  próximamente y restringido; validar el formato acordado de 75 AM + 75 PM,
  150 preguntas y cinco áreas, sin entregar claves antes de la calificación.
- Historial unificado de jornadas AM/PM, ediciones históricas y contrarreloj.
- Incluir prácticas/simulacros por área, correctas, incorrectas, omitidas, duración
  y desglose por materia; extender comparaciones sin rehacer su interfaz existente.
- Integridad AM/PM: recibir y validar en backend eventos de salida de la app.
  Definir tolerancias para llamadas, avisos y accesibilidad; no aplicar reprobación
  automática sin una política institucional explícita.
- Sincronización de favoritos y preguntas difíciles entre instalaciones/cambios
  de dispositivo, respetando la sesión única. Hoy la persistencia es local.
- Sincronizar progreso de flashcards, objetivo personal del examen y tiempo
  estudiado. Sus funciones locales no se rehacen; falta el contrato remoto.
- Evaluar qué estado de «Continúa donde quedaste» conviene sincronizar; no asumir
  que todo intento protegido puede copiarse libremente entre dispositivos.
- Cerrar política offline de intentos/contenido protegido y precondiciones de
  edición del cuaderno de errores para resolver conflictos sin sobrescrituras silenciosas.
- Verificar aislamiento/limpieza de descargas al cambiar de cuenta y evitar
  almacenar permanentemente bancos de claves de respuesta. Distinguir recursos
  públicos descargables de datos privados y resultados autorizados del alumno.

## 9. Certificado por completar una materia

- El certificado de logros ya existe; falta el contrato específico de completar
  el 100 % de una materia, comprobado por el servidor.
- Integrarlo con la colección del perfil, descarga y reglas de emisión.
- Confirmar nombres/plantillas definitivos con el equipo; no reemplazar los
  actuales automáticamente. Pendiente identificado en GAMIFICATION_CONTRACT.md.

## 10. Etapas 8C–8D — Publicidad y recompensas reales

- Configurar e integrar AdMob: identificadores de prueba/producción, ubicaciones,
  consentimiento y límites de frecuencia. No interrumpir concentración/evaluaciones.
- Anuncios recompensados voluntarios con verificación del servidor (SSV),
  concesiones de un solo uso y protección frente a repeticiones/tráfico inválido.
- Contrato real de racha: congelamiento/gracia, vencimiento y recuperación
  del día anterior dentro de su ventana, sin confiar en el reloj local.
- Potenciadores individuales bajo demanda sin tope comercial diario, sujetos a
  disponibilidad y validación; plan sin anuncios solicita la misma recompensa sin video.
- No usar falencias, puntajes o institución para segmentar anuncios.
- No usar respuestas ni carreras para personalización publicitaria. Habilitar
  reporte de anuncios inapropiados y manejar falta de inventario/errores sin
  bloquear estudio ni provocar cargas repetitivas.
- Banners solo fuera de concentración; intersticiales en pausas naturales, con
  límites locales/remotos. Evaluar la hipótesis de 2–3 cada 30 minutos y mayor
  frecuencia para profesores gratuitos sin convertirla en obligación ni spam.
  Retirar publicidad al confirmar el derecho sin anuncios.
- Vincular cada concesión a usuario, recompensa, vencimiento y uso único;
  auditar emisión/consumo. El callback de Flutter no basta para concederla.
- Cada video voluntario concede un potenciador; no recuperar varios días de
  racha acumulados. Mantener partidas asistidas fuera de récords competitivos y
  no alterar diagnóstico, XP académico ni simulacros oficiales.
- Aprovechar el consumo autoritativo de concesiones ya implementado en juegos;
  faltan emisión real, SSV y comprobación integral, no rehacer todos los motores.

## 11. Etapas 8A–8B — Derechos comerciales, Billing y plan sin anuncios

- Configurar productos/ofertas: 9.900 COP mensual, 49.900 semestral,
  promoción 39.900 y 69.900 anual, conforme al modelo acordado.
- Compra y validación del servidor, derechos, renovación, vencimiento,
  restauración, reembolso y cambio de cuenta.
- Retirar anuncios y entregar insignia/cosméticos, sin bloquear contenido
  académico gratuito ni confundir cosméticos con logros académicos.
- Conectar los derechos de profesor con su plan, reemplazando la activación
  administrativa provisional. Revisar límites/costos del plan institucional.
- No integrar Wompi/ePayco en móvil. Mantener la frontera de iOS sin cobros reales.
- Derechos neutrales al proveedor con cuenta, producto, transacción, fechas y
  estados gratuito, pendiente, activo/sin anuncios, gracia, suspendido, vencido y
  reembolsado/revocado. Solo el servidor puede activarlos.
- Confirmar identificadores y modalidad: suscripción renovable o pase fijo.
  Validar comprobantes con Google Play Developer API y procesar notificaciones
  del servidor sobre compras/cambios, con idempotencia y recuperación de eventos.
- Probar cancelación y acceso hasta su vencimiento cuando corresponda, suspensión,
  gracia, revocación, reinstalación y asociación entre cuenta Google y SaberPlus.
- Pantalla «Administrar plan», precios devueltos por Play y pruebas con cuentas
  de licencia. Los precios anteriores son el acuerdo comercial, no valores que
  deban ignorar los productos/ofertas reales de la tienda.
- Los límites institucionales ya implementados (gratis: 1 grupo/40 alumnos;
  plan ampliado: 5 grupos/200 alumnos) se verifican y conectan al derecho comercial;
  no se vuelven a construir analíticas, prioridades ni exportaciones existentes.

## 12. Etapas 8E–8I y cierre 7J — Producción, calidad y publicación

- Entorno de producción separado del desarrollo, secretos, dominio/configuración,
  respaldo inicial, recuperación comprobada, observabilidad y plan de reversión.
- Revisar vulnerabilidades de dependencias y advertencias técnicas pendientes;
  probar seguridad, accesibilidad, carga, consumo y rendimiento.
- Resolver los avisos de lint preservados de Guardián y revisar la migración de
  `flutter_timezone` a Kotlin integrado antes de actualizar Flutter; el APK debug
  actual compila, pero no constituye la verificación de release ni de iOS.
- Banco académico suficiente y autorizado; revisión de fórmulas/glosario,
  fechas de examen y vigencia de fuentes de becas, universidades y datos nacionales.
- Completar origen, autor, licencia y fechas de los audios ya integrados; no se
  necesitan sonidos nuevos para la entrega actual. Escucharlos en teléfonos reales.
- Compilar y probar Android e iOS; firma y paquete Android, pruebas internas/beta,
  ficha de tienda, capturas, privacidad, audiencia y declaraciones de SDK/datos.
- Verificar compras/anuncios de prueba, cuentas limpias y configuración sin demo
  antes del lanzamiento comercial en Google Play.

### Contenido y operación editorial (cierre 7J)

- Cargar las cinco áreas, temas/subtemas, lecciones, Markdown, actividades,
  imágenes, videos y PDF autorizados. Revisar exactitud, ortografía, ambigüedad,
  dificultad y explicaciones; el editor admite cuatro opciones dentro de su rango
  actual de 2–6, no hay que rehacerlo por esa diferencia con el listado antiguo.
- Banco piloto: al menos 30 preguntas variadas por área; objetivo inicial de
  producción: 100 o más por área, sujeto a revisión académica y cobertura.
  Revisar las 80 fórmulas y 50 términos de memoria, no solo su cantidad.
- Actualización versionada de becas, programas, universidades y referencias
  nacionales, con fuente y fecha de revisión. No confundir el catálogo informativo
  existente con una actualización remota o automática ya implementada.
- Configurar y probar el número real de soporte WhatsApp; retirar contactos y
  contenido ficticios de producción. La cuenta de soporte la aporta el equipo.

### 8E — Privacidad, documentación y licencias

- Publicar privacidad, términos y procedimiento de eliminación en HTTPS:
  datos recogidos, finalidad, destinatarios y plazos de conservación.
- Inventario de SDK/proveedores y declaraciones de datos/anuncios/audiencia real,
  incluidos usuarios de 15–17 años; revisar requisitos vigentes al implementarlo.
- Revisar avisos de resultados orientativos/no oficiales para proyección,
  comparación nacional, carreras y becas. No se ofrecen tutores ni asesoría personal.
- Conservar evidencia de licencias de preguntas, imágenes, cuadernillos, PDF y
  audios; registrar modificaciones y verificar permisos comerciales/distribución.
  La declaración «libre de regalías» por sí sola no cierra esta comprobación.

### 8F — Seguridad, rendimiento y observabilidad

- Auditar roles, aislamiento entre instituciones, acceso de profesores a sus
  grupos, exportaciones, respuestas correctas, archivos y rutas de descarga.
- Revisar límites de solicitudes de login, juegos, invitaciones y recompensas;
  secretos distintos por ambiente, incluido el de alias, sin filtrarlos a Git/APK/logs.
- Logs sin datos sensibles, captura de errores Flutter/NestJS, latencia,
  disponibilidad y alertas; ensayar respuesta a incidentes y restauración.
- Carga de login, simulacros, Trivia Rush, Socket.IO, ranking y exportaciones;
  memoria, batería, datos y tamaño APK/AAB. Lectores de pantalla, texto ampliado,
  contraste, navegación y todas las animaciones con reducción de movimiento.

### 8G — Pruebas integrales y beta

- Suites Flutter/backend, análisis y compilaciones; E2E contra staging.
- Matriz Android (versiones, teléfono pequeño y tableta), red lenta, modo avión,
  cierres/reapertura, almacenamiento lleno, cuenta cambiada, sesión reemplazada
  y token vencido. Notificaciones/permisos, audio/vibración y los tres modos de tema.
- Compras/anuncios de prueba, racha/potenciadores, multijugador/reconexión/abandono,
  códigos de grupo, invitaciones y exportaciones; sin demo ni usuarios ficticios
  en producción. Prueba interna/cerrada, compañeros probadores y corrección de fallos.

### 8H — Entrega técnica iOS, sin publicación comercial

- Compilar en macOS/Xcode, confirmar Bundle ID y permisos realmente necesarios.
- Probar Keychain, Drift/SQLite, notificaciones, PDF/offline, enlaces, audio,
  animaciones y reducción de movimiento en iOS.
- Conservar compras neutrales/simuladas sin activar StoreKit ni publicidad real
  iOS en esta entrega. Mantener iOS es obligatorio; publicarlo en App Store no.

### 8I — Google Play

- Confirmar nombre/applicationId, firma protegida, AAB y versiones; icono, splash,
  capturas, gráfico promocional, descripciones y categoría Educación.
- Declaraciones de contenido/datos/anuncios, privacidad, instrucciones y cuenta
  de revisión si hace falta, países, disponibilidad y productos/precios.
- Verificar los requisitos concretos de pruebas de la cuenta en Play Console,
  corregir advertencias, preparar lanzamiento gradual y reversión documentada.
  Conservar el código/artefactos recuperables y prever una versión correctiva;
  no asumir que la tienda permite instalar un número de versión inferior.

## 13. Etapa 9A — Mantenimiento posterior al lanzamiento

Es operación continua, no una etapa que debamos «terminar» antes de publicar.
Antes del lanzamiento sí se asignan responsables, frecuencia y procedimientos.

- Supervisar API/base, errores Flutter/backend, compras, renovaciones y reembolsos.
- Vigilar tráfico publicitario inválido, ajustar frecuencia según experiencia y
  abandono, revisar costos de Supabase/hosting y preparar capacidad.
- Respaldos automáticos, restauraciones periódicas, rotación de secretos y
  respuesta a incidentes, reportes, bloqueos y contenido inapropiado.
- Mantener preguntas/explicaciones, becas/convocatorias, referencias ICFES,
  programas/enlaces SNIES y licencias/cuadernillos vigentes.
- Actualizar dependencias Flutter/NestJS, revisar cambios de políticas y preparar
  nuevas versiones con un ciclo de revisión y entrega.
- Métricas agregadas de actividad, estudio, retención, uso de simulacros,
  anuncios por usuario y conversión al plan sin anuncios. No enviar respuestas,
  falencias ni puntajes a plataformas publicitarias.

## Mejoras opcionales recuperadas del listado anterior

Registradas para que no se pierdan, **no bloquean la primera publicación** ni
autorizan desarrollarlas todas ahora. Se priorizan después con el equipo.

- Push desde backend (las notificaciones locales ya existen).
- Sincronización remota del Pomodoro y preferencias menores.
- Sonido/vibración al terminar Pomodoro: actualmente no los reproduce; requiere
  una decisión separada del feedback de rachas (ver POMODORO.md).
- Búsqueda académica paginada en backend y filtro diario de errores en servidor;
  no rehacer las pantallas y funciones de búsqueda/repaso existentes.
- Más cosméticos, certificados, juegos, torneos/temporadas y modos de Tira y afloja.
- Importación masiva confirmada desde panel web/tableta: existe la API de vista
  previa Excel/ZIP sin escrituras; **no equivale a un importador que guarde lotes**.
  El camino principal elegido sigue siendo la carga por página, no exigir Excel.
- Actualización automática de oportunidades oficiales desde fuentes verificadas;
  la revisión editorial/versionada inicial sí forma parte del cierre 7J.
- Publicación comercial en App Store y StoreKit completo, solo con nueva decisión.

## Fuera del lanzamiento inicial / no son etapas pendientes obligatorias

- Publicación comercial en App Store y cobros StoreKit: solo si se autorizan después.
- Tutores y chat de asesoría: descartados del modelo.
- Más juegos no acordados: no se agregan al camino actual. Los cuatro seleccionados
  en SABI_Y_JUEGOS_APROBADOS.md sí son alcance aprobado, pendiente de programación.
- Rediseño visual general del panel: no es prioridad; debe ser funcional y accesible.

Referencias: ROADMAP_MOVIL.md, ADMIN_PANEL.md, BUSINESS_MODEL.md,
FLUTTER_STAGING_CONNECTION.md, GAME_POLISH_GUARDIAN.md,
GAMES_PRODUCTION_CHECKLIST.md, GAMIFICATION_CONTRACT.md y OFFLINE_SYNC.md.
