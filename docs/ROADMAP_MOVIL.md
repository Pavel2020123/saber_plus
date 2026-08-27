# Roadmap móvil de SaberPlus

Este plan traduce el informe técnico a entregas pequeñas y verificables. El backend NestJS/PostgreSQL continúa siendo la fuente de verdad para permisos, calificación, XP, pagos e intentos.

## Estado actual

- [x] Lectura y clasificación del informe de 27 páginas.
- [x] Proyecto Flutter base, tema claro/oscuro y navegación por rol.
- [x] Configuración `dev`, `staging` y `prod` mediante `dart-define`.
- [x] Cliente HTTP y frontera de sesión preparados.
- [x] Prototipo navegable de estudiante y profesor con datos demostrativos.
- [x] Cliente móvil de autenticación, sesión segura y deep links personalizados.
- [ ] Contrato OpenAPI `/v1`, dominio de universal links y backend disponibles en este repositorio.

## Etapa 1 - Cimientos móviles

Objetivo: una aplicación ejecutable con arquitectura modular, navegación accesible y ambientes separados.

- Tema, componentes base y diseño adaptable.
- Riverpod, `go_router` y Dio. El almacenamiento seguro se conecta con la autenticación real de la etapa 2.
- Bienvenida, login demostrativo y shells por rol.
- Pruebas de arranque y navegación crítica.

## Etapa 2 - Identidad real

Requiere el contrato del backend y las decisiones ADR-001/ADR-004.

- [x] Registro y captura de consentimiento versionado en el cliente.
- [x] Verificación de correo mediante deep link personalizado.
- [x] Login con access token en memoria y refresh token cifrado.
- [x] Recuperación, cambio inicial y cierre de sesión.
- [x] Renovación coordinada y retry único ante `401`.
- [ ] Validación de integración contra el backend real.
- [ ] Universal Links/App Links HTTPS, revocación por dispositivo y perfil completo.

## Etapa 3 - Diagnóstico y aprendizaje

- Bootstrap móvil y convocatoria activa.
- Diagnóstico de las cinco áreas.
- Resultado por área y plan semanal.
- Árbol de áreas, temas, subtemas y lecciones.
- Recursos Markdown, imágenes, video y PDF.

## Etapa 4 - Práctica y simulacros

- Componente de pregunta, opciones y contexto compartido.
- Práctica por subtema y sesión aleatoria.
- Simulacro completo y personalizado.
- Temporizador, borrador local, reanudación e idempotencia.
- Resultados, explicación e historial.

## Etapa 5 - Progreso y modo sin conexión

- Cuaderno de errores y repaso adaptativo.
- Progreso, fórmulas, glosario y estrategia.
- Drift/SQLite, contenido descargable y gestión de espacio.
- Outbox de operaciones seguras y resolución de conflictos.
- Notificaciones y preferencias.

## Etapa 6 - Comunidad y gamificación

- XP, rachas, actividad, logros y certificados.
- Ranking con privacidad por defecto.
- Batallas asíncronas, bloqueo y reporte.
- Anuncios, referidos, soporte y calculadora de puntaje.

## Etapa 7 - Profesor e institución

- Resumen institucional, estudiantes y grupos.
- Analítica resumida y alertas de riesgo.
- Matrícula individual y anuncios institucionales.
- Importaciones y operaciones masivas permanecen en web/tablet.

## Etapa 8 - Comercio y publicación

- Compra aprobada para Apple/Google y derechos neutrales.
- Restauración, reembolso y cambio de cuenta.
- Accesibilidad, seguridad, rendimiento y observabilidad.
- Beta, fichas de tienda, privacidad y plan de rollback.

## Decisiones pendientes que no debe inventar Flutter

1. Contrato OpenAPI versionado y formato de errores.
2. Refresh rotation, sesiones y revocación de dispositivos.
3. Consentimiento y tratamiento de datos de menores.
4. Estrategia de compra compatible con cada tienda.
5. Política offline para intentos y contenido protegido.
