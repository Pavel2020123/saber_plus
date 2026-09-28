# SaberPlus — funcionalidades y estado para el equipo

Actualizado: 28 de septiembre de 2026. Resumen documental, no auditoría integral
nueva del código. Orden y estados detallados en [ETAPAS_PENDIENTES.md](ETAPAS_PENDIENTES.md).

## Qué estamos construyendo

SaberPlus es una aplicación de preparación académica para Saber 11, hecha en
Flutter para Android e iOS. Combina estudio organizado, práctica, seguimiento,
juegos y acompañamiento institucional. La publicación comercial inicial será
en Google Play; iOS se mantiene como entrega técnica del proyecto.

Hay tres componentes propios:

| Componente | Responsabilidad | Carpeta |
| --- | --- | --- |
| App Flutter | Experiencia del estudiante y profesor; persistencia local | `saber_plus/lib` |
| API NestJS + Prisma | Autenticación, permisos, calificación y persistencia remota | `SaberPlus-Backend/backend` |
| Panel editorial | Administración de temas, lecciones, preguntas y publicación | `SaberPlus-Backend/admin` |

La API utiliza PostgreSQL; el entorno de desarrollo en nube se preparó en
Supabase. La app no contiene contraseñas de PostgreSQL ni accede directamente
a sus tablas. El panel tampoco: ambos consumen la API.

**Cómo leer este documento:** una función implementada en código no implica
que ya esté desplegada o validada con teléfonos y cuentas reales. La demo es
un entorno de ejemplos; no debe confundirse con progreso académico real.

## 1. Cuentas y navegación

- Registro e inicio de sesión de estudiantes y profesores.
- Verificación de correo, solicitud de recuperación y nueva contraseña.
- Cambio obligatorio de contraseña inicial cuando el servidor lo exige.
- Restauración y cierre de sesión; almacenamiento seguro del token.
- Menús separados para estudiante y profesor; la autorización definitiva
  pertenece al backend, no a ocultar botones.
- Modo demostrativo identificado, sin mezclar sus resultados con cuentas reales.
- Identificador aleatorio de instalación, sin IMEI ni identificadores publicitarios.

Pendiente: sesión única autoritativa en el servidor, refresh/rotación y
revocación centralizada; eliminación de cuenta/datos y verificación final de
correo/enlaces HTTPS. Las protecciones locales no sustituyen esos contratos.

## 2. Inicio y organización académica

- Inicio del estudiante con accesos rápidos, actividad, progreso y XP.
- Cinco áreas: Lectura Crítica, Matemáticas, Sociales y Ciudadanas,
  Ciencias Naturales e Inglés.
- Estructura **área → tema → subtema** que también clasifica las preguntas.
- Lecciones con texto Markdown y referencias a imágenes, videos y PDF.
- Actividad de completar espacios (CLOZE), con opciones y autocorrección.
- Seguimiento del avance y enlace a la práctica relacionada.
- Mapa orientativo de bases por subtema: API, panel y Flutter MA-2A/B/C locales.
  No bloquea contenido ni convierte lectura en dominio; ensayo real pendiente.

CLOZE ayuda a estudiar; su autocorrección no es una calificación diagnóstica
independiente ni concede por sí sola una evidencia de dominio.

## 3. Diagnóstico y evidencia de aprendizaje

- Diagnóstico inicial y resultados por área.
- Identificación de errores para revisar y orientación del estudio posterior.
- Informe por tema/subtema con aciertos, preguntas distintas, sesiones y días.
- Estados explicables: evidencia insuficiente, conviene reforzar, en proceso
  y fortaleza en lo evaluado.
- Regla inicial: ventana de 90 días; al menos 5 preguntas distintas por
  subtema o 10 por tema, en 2 sesiones y 2 días. Con muestra suficiente, los
  cortes orientativos son 60 % y 80 %. No es un modelo psicométrico validado.
- Repetir la misma pregunta no se cuenta como nueva evidencia de conocimiento.

Por ejemplo, fallar una sola pregunta de regla de tres no permite afirmar que
el estudiante desconoce todo el tema. El informe distingue ese error aislado
de un patrón respaldado por suficientes respuestas. No usa XP ni minutos de
lectura como prueba de conocimiento. Ver [LEARNING_EVIDENCE.md](LEARNING_EVIDENCE.md).

## 4. Práctica, simulacros y resultados

- Práctica por subtema, aleatoria y repaso adaptativo.
- Selección de áreas/dificultad según el modo y contrato disponibles.
- Preguntas de opción múltiple, casos compartidos y explicaciones después de
  la calificación, con revisión de las respuestas.
- Simulacros personalizados y por área, historial y comparación de resultados.
- Formato de preparación de 150 preguntas en dos jornadas de 75, AM y PM.
- Borradores de intentos y reanudación cuando el intento sigue vigente.
- Contador y registro local de salidas de la app durante AM/PM, sin reprobar
  automáticamente al alumno por llamadas o avisos del sistema.
- Pantallas de contrarreloj y simulacros históricos con sus límites documentados.

Pendientes: cierre temporal autoritativo del contrarreloj, recuperación
idempotente completa de entrega/resultados, historial unificado, contrato
propio de ediciones históricas y eventos de integridad. El modo AM/PM reutiliza
actualmente el intento personalizado; no es un cuadernillo oficial del ICFES.
Un banco histórico necesita material propio o autorizado, no copiar PDF sin permiso.

## 5. Repaso y organización personal

- Cuaderno de errores, notas y estado de revisión.
- Repaso de errores del día y sugerencias adaptativas.
- Favoritos de estudio y preguntas marcadas como difíciles.
- Búsqueda local del contenido académico disponible.
- Flashcards con práctica y seguimiento local.
- Agenda MA-3A/B/C de flashcards vencidas/próximas, cola durable, API y reintentos
  por cuenta. Autoevaluación separada de práctica libre y de evidencia de dominio.
- «Continúa donde quedaste» para retomar actividades compatibles.
- Biblioteca empaquetada: fórmulas, glosario y estrategias de examen, con filtros.
- Contador de fecha del examen y planificación del temario por área.

No todas estas preferencias/progresos se sincronizan entre dispositivos.
Favoritos, preguntas difíciles y contadores de práctica libre conservan estado
local. La agenda de repaso sí tiene contrato/sincronización localmente implementados;
falta ensayo real. No migrar contadores antiguos como retención acreditada.
La biblioteca empaquetada no se actualiza automáticamente desde el panel.

## 6. Hábitos y bienestar

- Pomodoro opcional de 25 minutos en estudio/práctica, con pausa y reinicio.
- Acumulado local y resumen remoto de tiempo/evolución con fuentes separadas.
  P4-A/B implementa API y cola idempotente de nuevos Pomodoros completados;
  no importa el historial antiguo ni duplica tiempos de evaluaciones del servidor.
- Sugerencia de descanso tras 50 minutos en primer plano dentro de una sesión
  de estudio normal, con pausa voluntaria de tres minutos. No mide concentración
  mental ni interrumpe un simulacro cronometrado.
- Recordatorio diario opcional, horario y permiso de notificaciones solicitado
  cuando el usuario lo activa.
- Preferencias de sonido/vibración y apariencia clara, oscura o del sistema.

El Pomodoro no sobrevive actualmente a cerrar por completo la app y no emite
sonido al finalizar. No hay todavía notificaciones push académicas del backend.

## 7. Juegos

| Juego | Cómo funciona | Límite importante |
| --- | --- | --- |
| Trivia Rush | Preguntas con tiempo, puntos y combos | Las partidas reales dependen de confirmaciones del servidor |
| Duelo fantasma | Compite contra la evolución de un récord personal, con personaje animado | No es otro estudiante conectado; la primera partida crea la referencia |
| Memoria | Encuentra parejas de fórmulas y conceptos | Reutiliza la biblioteca; revisar calidad del contenido antes del lanzamiento |
| Tira y afloja | Las respuestas desplazan la cuerda; incluye experiencia individual y en línea | En línea requiere probar dos dispositivos, latencia y reconexión |
| Batallas asíncronas | Desafíos entre estudiantes sin exigir que jueguen simultáneamente | Entregas, vencimientos, bloqueo de rivales y permisos se validan en backend |
| Desafío del guardián | Alcanzar seis aciertos antes de tres errores, hasta ocho preguntas | Motor local; falta verificar despliegue y ensayo real |
| Salto a la cima | Aciertos suben un escalón y errores bajan uno | Demo, backend y cliente remoto locales; falta ensayo real |
| Rescate de estrellas | Aciertos liberan estrellas y completan constelaciones | Demo, backend y cliente remoto locales; falta ensayo real |

Ocho juegos vigentes. Taller de inventos cancelado y Escudo del conocimiento retirado;
no reintroducirlos. Renovación profesional con Sabi aplazada al acabado final.

Existen animaciones, efectos de audio y controles de movimiento reducido.
Las partidas asistidas no deben convertirse en récords competitivos limpios.
No se dan por probados todos los modos en Android/iOS reales por tener tests.

## 8. Rachas, XP, logros y certificados

- XP, logros desbloqueados y actividad académica confirmada por backend.
- Racha actual/mejor y visualización de actividad reciente.
- Llama animada, crecimiento al entrar e hitos de color: naranja, dorado,
  rojo, violeta, azul y cian desde 50 días.
- Controles de adelantar días/estado reservados a la demostración.
- Seis certificados: cinco áreas y curso completo, plantilla HTML→PDF con nombre
  registrado. Todas las lecciones publicadas del área completadas; área vacía
  no habilita PDF. Final exige las cinco áreas. Implementación local y descarga privada.
- Catálogo de 90 insignias (ocho juegos e instituciones), no premios ganados.
  Rankings por juego y asignación anual permanente permanecen pendientes PR-I1–7.

Pendiente: ensayo real de los seis certificados y contrato
real de gracia/congelamiento/recuperación de racha. La apariencia de hielo no
equivale a una recuperación concedida por el servidor. Los certificados no
se presentan como acreditaciones oficiales del ICFES.

## 9. Perfil y orientación

- Perfil académico con fortalezas, áreas por reforzar y objetivo personal.
- Actividad semanal, comparativo mensual y evolución de resultados disponibles.
- Proyección orientativa de puntaje, exploración de carreras/universidades y
  comparación informativa con referencias nacionales.
- Catálogo de becas y oportunidades con fuente, fecha de revisión y enlaces oficiales.
- Calculadora local de puntaje a partir de resultados de las cinco áreas.

Las fortalezas del perfil resumen resultados por área; son distintas del informe
de evidencia por tema/subtema y no aplican sus mínimos de muestra.

Estas herramientas no garantizan puntaje, admisión, becas ni Distinción Andrés
Bello. Las becas no se conceden desde SaberPlus. La actualización remota/versionada
de catálogos y revisión de vigencia todavía forman parte de la preparación.

## 10. Profesores, grupos e instituciones

- Una persona crea una cuenta de profesor y solicita aprobación para una nueva
  institución o vinculación a una existente; no hay contraseña institucional compartida.
- Propietario, administradores y profesores con permisos diferenciados.
- Gestión de miembros, invitaciones, grupos y códigos de vinculación.
- El estudiante acepta vincularse y compartir el seguimiento previsto.
- Analítica básica y, según el derecho institucional, detalle por estudiante,
  alertas, prioridades académicas y exportación CSV/PDF.
- Alcance limitado a la institución/grupos autorizados por el servidor.
- Límites implementados: plan gratis de 1 grupo/40 estudiantes; ampliado de
  5 grupos/200 estudiantes. Su activación comercial sigue pendiente de Billing.

**P4-C implementada localmente:** solicitud y estado en app, revisión de evidencia
mínima y aprobación/rechazo por ADMIN en panel; acceso institucional bloqueado
hasta aprobarse. Alta directa antigua retirada. P1–P4 incluyen prioridades,
seguimiento y tiempo/evolución; falta despliegue/ensayo P5, pausado. Gestión general
de cuentas es un pendiente del panel ADMIN, no de la app estudiantil.

Los profesores supervisan a sus estudiantes; no se ofrecen tutores contratados
ni chat de asesoría personal. Los derechos comerciales no se autoconceden desde Flutter.

## 11. Comunidad y soporte

- Ranking con alias para limitar exposición de identidad.
- Anuncios/comunicados académicos, diferentes de publicidad AdMob.
- Código personal de referidos y resumen disponible.
- Contacto de soporte configurado por el backend y apertura segura del canal.
- Bloqueo/reporte de rivales en los flujos que lo contemplan.

Antes de publicar hay que configurar el contacto real de soporte y revisar
las políticas de privacidad/retención y moderación.

## 12. Descargas y sincronización

- Drift/SQLite almacena cachés, descargas y estado local por usuario.
- Archivos privados de certificados y recursos con validaciones y nombres seguros.
- Lectura de contenido previamente descargado en los modos compatibles.
- Cola explícita para progreso de lección y notas/estado del cuaderno.
- Vista de pendientes, sincronización manual y manejo de rechazos/conflictos.
- Respuestas, pagos, calificaciones, XP y escrituras administrativas no se
  envían ciegamente después desde una cola offline.

Pendiente: catálogo versionado completo, actualización de archivos persistentes,
conflictos remotos del cuaderno y sincronización de todas las herramientas personales.
La protección de backups automáticos no es un servicio de respaldo personal:
datos solo locales pueden perderse al desinstalar; no prometer recuperación remota
de aquello que todavía no tiene un contrato de sincronización.

## 13. Panel de administración de contenido

- Acceso exclusivo ADMIN y demo local separada de la base real.
- Cinco áreas y catálogo paginado de temas/subtemas.
- Crear y corregir nombres de borradores bajo restricciones de uso.
- Editar texto de lecciones y referencias HTTPS; vista previa sin ejecutar HTML.
- Editor de preguntas, opciones/correcta, dificultad y explicación.
- Casos/contextos compartidos con orden y clasificación coherentes.
- Editor CLOZE con espacios, opciones, respuesta correcta y validaciones.
- Detección de duplicados por huella normalizada, sin importar orden de opciones.
- Herramientas de indexación por lotes del banco antiguo y coincidencias paginadas.
- Reclasificación revisada de preguntas nunca usadas, sin alterar resultados históricos.
- Guardar contenido/pregunta válido publica directamente con autorización;
  no hay bandeja de revisión obligatoria. Archivado sin cascadas.
- Editor de lecciones por bloques, cobertura por subtema y editor del mapa de bases.
  Reportes académicos en cobertura aún pendientes MA-1.
- Eliminación confirmada de temas/subtemas vacíos nunca publicados ni usados.
- Protección contra ediciones simultáneas mediante revisión y bloqueos del servidor.

No es un detector semántico/OCR de toda pregunta parecida. El panel aún no ofrece
subida persistente de imágenes a Supabase Storage, imágenes dentro de opciones,
papelera/restauración o historial completo de versiones. Hay una API de vista previa
Excel/ZIP, pero no un importador masivo que guarde todo: el camino elegido es la web.

El ensayo editorial real D3 está pendiente. No se habilitaron publicación,
indexación ni reclasificación sobre Supabase durante la auditoría.

## 14. Modelo comercial y lanzamiento

El acuerdo es mantener gratis todo lo académico del estudiante, financiado
por anuncios. Pagar elimina publicidad y añade cosméticos; no compra una mejor nota.
Precios propuestos: 9.900 COP mensual, 49.900 por seis meses (promoción 39.900)
y 69.900 anual, sujetos a configurar productos/ofertas reales en Play.

Los videos voluntarios podrían conceder potenciadores o recuperar el día anterior
dentro de una ventana válida. No hay un tope comercial de tres potenciadores:
la concesión dependerá de disponibilidad y verificación, no de tocar un botón.

**Todavía pendientes:** SDK/configuración real AdMob, verificación de recompensas,
Google Play Billing y derechos/renovaciones/reembolsos. No hay monetización lista
para producción por tener una política de anuncios en el código. Wompi/ePayco no
forman parte del cobro móvil acordado. Su implementación se retiró localmente el
12 de septiembre: las rutas antiguas responden 410 sin procesar pagos. Falta
desplegar ese retiro en Render; las tablas históricas se conservan.

## Qué sigue

**PR-I1: reglas y contratos competitivos.** Después PR-I2–6 por dependencias,
con C5 antes de fotos reales. MA-2/3 locales no se rehacen. P5/D3 siguen pausadas.
No desaparecen MA-1 reportes, C4/C5/C6, identidad/seguridad, contratos académicos,
ensayos de certificados/juegos, monetización, acabado azul/animaciones y publicación.

El listado íntegro sigue en [ETAPAS_PENDIENTES.md](ETAPAS_PENDIENTES.md).
Los resultados y límites de esta revisión están en [AUDITORIA_PROYECTO_2026-09-09.md](AUDITORIA_PROYECTO_2026-09-09.md).
