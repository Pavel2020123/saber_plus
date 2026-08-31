# Roadmap móvil de SaberPlus

Este plan traduce el informe técnico a entregas pequeñas y verificables. El backend NestJS/PostgreSQL continúa siendo la fuente de verdad para permisos, calificación, XP, pagos e intentos.

## Estado actual

- [x] Lectura y clasificación del informe de 27 páginas.
- [x] Proyecto Flutter base, tema claro/oscuro y navegación por rol.
- [x] Configuración `dev`, `staging` y `prod` mediante `dart-define`.
- [x] Cliente HTTP y frontera de sesión preparados.
- [x] Prototipo navegable de estudiante y profesor con datos demostrativos.
- [x] Cliente móvil de autenticación adaptado al contrato real y deep links personalizados.
- [x] Contrato de autenticación auditado contra `Pavel2020123/Icfes_Vida`.
- [ ] URL HTTPS desplegada, OpenAPI y dominio de universal links.

## Etapa 1 - Cimientos móviles

Objetivo: una aplicación ejecutable con arquitectura modular, navegación accesible y ambientes separados.

- Tema, componentes base y diseño adaptable.
- Riverpod, `go_router` y Dio. El almacenamiento seguro se conecta con la autenticación real de la etapa 2.
- Bienvenida, login demostrativo y shells por rol.
- Pruebas de arranque y navegación crítica.

## Etapa 2 - Identidad real

El cliente ya está adaptado al contrato actual del backend NestJS.

- [x] Registro con los campos actualmente admitidos por el backend.
- [x] Verificación de correo mediante deep link personalizado.
- [x] Login, perfil y restauración local con access token cifrado.
- [x] Recuperación, cambio inicial y cierre de sesión local.
- [x] DTO, roles, contraseña y errores alineados con la API existente.
- [x] Prueba de extremo a extremo contra una instancia ejecutándose.
- [ ] Consentimiento versionado, refresh token, Universal Links/App Links HTTPS y revocación por dispositivo.

## Etapa 3 - Diagnóstico y aprendizaje

- [x] Inicio académico móvil con convocatoria activa, XP y plan semanal real.
- [x] Estados, inicio y resumen del diagnóstico conectados con el backend.
- [x] Sesión móvil de las 15 preguntas, borrador local y finalización.
- [x] Resultado por área y área prioritaria disponibles en la app.
- [x] Falencias por tema y subtema consultadas desde el cuaderno de errores.
- [x] Árbol de áreas, temas, subtemas y lecciones.
- [x] Recursos Markdown, imágenes, video, actividad interactiva y PDF autenticado.

## Etapa 4 - Práctica y simulacros

- [x] Componente móvil de pregunta, opciones y contexto de caso.
- [x] Práctica por subtema con intento protegido y registro de tiempos.
- [x] Sesión aleatoria personalizada por áreas, cantidad y dificultad.
- [x] Simulacro completo por área con borrador y revisión.
- [x] Temporizador visible y bloqueo de envíos duplicados en la app.
- [x] Borrador local cifrado y reanudación de intentos vigentes.
- [ ] Recuperación idempotente respaldada por API.
- [x] Resultado inmediato y revisión con explicación.
- [x] Historial de resultados y respuestas con filtros.

## Etapa 5 - Progreso y modo sin conexión

- [x] Panel de progreso académico y rendimiento por área.
- [x] Cuaderno de errores con filtros, notas y estados de repaso.
- [x] Repaso adaptativo con perfil, sesión protegida y recalibración.
- [x] Fórmulas, glosario y estrategia disponibles sin conexión.
- [x] Drift/SQLite, contenido descargable y gestión de espacio.
- [x] Outbox de operaciones seguras y resolución de conflictos.
- [x] Recordatorio diario local, permiso bajo demanda y preferencias persistentes.
- [x] Elección del estudiante entre tema claro y oscuro; el valor inicial continúa siendo claro.

## Etapa 6 - Comunidad y gamificación

- [x] XP confirmado por perfil, rachas, actividad y progreso de logros.
- [x] Descarga y apertura segura de certificados de logros desbloqueados.
- [x] Favoritos de lecciones por estudiante, persistentes en el dispositivo y disponibles sin conexión.
- [ ] Sincronización de favoritos entre dispositivos cuando el backend publique el contrato correspondiente.
- [x] Búsqueda académica de lecciones y prácticas por área, tema, subtema o concepto.
- [x] Acceso seguro al banco por subtema, sin descargar preguntas ni respuestas fuera de un intento.
- [x] Transiciones breves y consistentes entre pantallas, con reducción de movimiento accesible.
- [x] “Continúa donde quedaste” con acceso en un clic a la última lección del estudiante.
- [x] Pomodoro opcional de 25 minutos compartido entre estudio y práctica.
- [x] Flashcards de fórmulas y glosario con sesiones filtrables y progreso local por estudiante.
- [x] Contador de días para el examen visible en toda la experiencia del estudiante y minimizable.
- [x] Feedback visual animado, sonido y vibración corta al lograr tres o más aciertos consecutivos, configurables y comprobables por el estudiante.
- [x] Llama diaria activa, congelada o apagada, con niveles de color cada diez días y vista previa segura en modo demostración.
- [x] Preguntas difíciles por estudiante, disponibles sin conexión y sin almacenar el contenido protegido del banco.
- [ ] Sincronización de preguntas difíciles entre dispositivos cuando el backend publique el contrato correspondiente.
- [x] Repaso de errores del día con explicaciones, progreso temporal y acceso al repaso inteligente.
- [x] Modo oscuro automático que sigue la configuración del dispositivo, sin cambiar el inicio claro por defecto.
- [x] Tiempo total estudiado por estudiante con Pomodoros y evaluaciones confirmadas, disponible por día, semana y actividad.
- [x] Simulacro de 150 preguntas dividido en jornadas AM/PM, con cinco áreas, borradores independientes y banco protegido.
- [x] Cliente de integridad: identidad aleatoria por instalación, reacción a sesión reemplazada y registro cifrado de salidas durante AM/PM.
- [ ] Backend de sesión única: revocación del dispositivo anterior y validación de sesión activa en cada solicitud protegida.
- [x] Sugerencia de descanso saludable tras 50 minutos activos, con pausa opcional de tres minutos.
- [x] Cliente del banco por año: catálogo filtrable, trazabilidad de derechos y jornadas protegidas AM/PM.
- [ ] Carga de cuadernillos propios o autorizados y publicación del contrato histórico en el backend.
- [x] Pruebas contrarreloj con formatos de 5, 10 y 20 preguntas, reloj estricto, reanudación cifrada y cierre seguro.
- [ ] Calificación de preguntas omitidas al vencer, pendiente del contrato contrarreloj autoritativo en el backend.
- [x] Comparación de simulacros por materia con evolución cronológica y diferencias sobre resultados confirmados.
- [ ] Historial unificado de jornadas AM/PM, ediciones históricas y contrarreloj, pendiente del backend.
- [x] Countdown de temario por materia con fecha oficial, avance por subtema, prioridades y ritmo semanal sugerido.
- [x] Perfil académico central con identidad, XP, avance, aciertos, racha, tiempo estudiado y accesos al detalle.
- [x] Materias fuertes y por reforzar con objetivo personal de examen persistente por estudiante.
- [x] Resumen semanal de tiempo y acciones, con comparativo mensual local de tiempo, sesiones y días activos.
- [x] Puntaje proyectado orientativo con ponderación por materia, rango, confianza y advertencia metodológica.
- [x] Afinidades de carrera y acceso seguro a las consultas oficiales de programas e instituciones del SNIES.
- [x] Catálogo de becas, gratuidad y fondos con fuentes oficiales, fecha de verificación y límites de elegibilidad.
- [x] Comparación orientativa con promedios globales oficiales del ICFES separados por calendario, año y fecha de verificación.
- Ranking con privacidad por defecto.
- Batallas asíncronas, bloqueo y reporte.
- Anuncios, referidos, soporte y calculadora de puntaje.

## Etapa 7 - Profesor e institución

- Cuenta personal de profesor capaz de crear o solicitar ingreso a una institución; no habrá credenciales compartidas de institución.
- Propietario, administradores y profesores con invitaciones, permisos auditables y transferencia de propiedad.
- Grupos vinculados mediante códigos temporales y aceptación explícita del estudiante.
- Profesor gratuito con un grupo, hasta 40 estudiantes, analítica básica y publicidad moderada.
- Profesor con plan sin anuncios: hasta cinco grupos y 200 estudiantes, analítica detallada, alertas, prioridades y exportaciones.
- No se ofrecerán tutores, chat de asesoría ni explicaciones personales de preguntas.
- Importaciones y operaciones masivas permanecen en web/tablet.

## Etapa 8 - Comercio y publicación

- Contenido académico completo y permanente para el estudiante gratuito, financiado con publicidad moderada.
- AdMob con banners fuera de pantallas de concentración, intersticiales en pausas naturales y controles locales/remotos de frecuencia.
- Anuncios recompensados voluntarios para recuperar el día anterior de una racha y obtener potenciadores ilimitados bajo demanda para juegos individuales.
- Plan individual sin anuncios y con cosméticos: 9.900 COP mensual, 49.900 COP semestral, promoción de 39.900 COP y 69.900 COP anual.
- Google Play Billing para compras móviles; Wompi permanece únicamente en la página web y fuera del alcance de Flutter.
- Derechos de acceso neutrales en el backend, sin depender del proveedor de pago.
- Restauración, reembolso y cambio de cuenta.
- Publicación comercial inicial solo en Google Play; iOS continúa compilable y probado, sin publicación inicial ni cobros reales.
- Frontera preparada para StoreKit si posteriormente se decide publicar en App Store.
- Accesibilidad, seguridad, rendimiento y observabilidad.
- Beta, fichas de tienda, privacidad y plan de rollback.

## Decisiones comerciales confirmadas

- La aplicación móvil no implementará Wompi ni ePayco; Android usará Google Play Billing.
- Todas las funciones académicas del estudiante seguirán disponibles en el plan gratuito con anuncios.
- El pago individual retira anuncios y entrega cosméticos; no compra ventajas académicas.
- Los precios individuales serán iguales para estudiantes y profesores.
- La publicación inicial será únicamente en Google Play, aunque el proyecto conservará soporte técnico para iOS.

## Decisión de infraestructura

- Supabase podrá utilizarse como alojamiento administrado de PostgreSQL al preparar los ambientes desplegados.
- El backend NestJS seguirá concentrando permisos, autenticación, calificación, XP y reglas de negocio; Flutter no se conectará directamente a las tablas.
- Drift/SQLite seguirá siendo el almacenamiento local del dispositivo para descargas y modo sin conexión. No reemplaza la base PostgreSQL alojada en la nube.

## Decisiones pendientes que no debe inventar Flutter

1. Contrato OpenAPI versionado y formato uniforme de errores.
2. Refresh rotation, sesiones y revocación de dispositivos.
3. Consentimiento versionado y tratamiento de datos de menores en el backend.
4. Identificadores de productos, ofertas y reglas de restauración definitivas en Google Play Console.
5. Política offline para intentos y contenido protegido.
