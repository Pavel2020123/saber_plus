# SaberPlus móvil

Aplicación Flutter para la experiencia móvil de SaberPlus. El proyecto se está construyendo por etapas a partir del informe técnico de migración.

## Ejecutar la etapa actual

```powershell
flutter pub get
flutter run
```

La aplicación inicia en modo demostración para poder revisar navegación y diseño sin enviar credenciales a un servidor.

La interfaz inicia con fondo blanco y permite que el estudiante elija modo claro, oscuro o automático según el dispositivo desde `Más > Preferencias`.

El contrato auditado contra el backend existente está documentado en [docs/AUTH_CONTRACT.md](docs/AUTH_CONTRACT.md).
El contrato de convocatoria, diagnóstico y plan semanal está en [docs/ACADEMIC_CONTRACT.md](docs/ACADEMIC_CONTRACT.md).
El contrato del árbol de contenido y sus recursos está en [docs/STUDY_CONTRACT.md](docs/STUDY_CONTRACT.md).
El contrato de práctica protegida por subtema está en [docs/PRACTICE_CONTRACT.md](docs/PRACTICE_CONTRACT.md).
El contrato del panel de progreso y cuaderno de errores está en [docs/PROGRESS_CONTRACT.md](docs/PROGRESS_CONTRACT.md).
La fuente y actualización de fórmulas, glosario y estrategia están en [docs/REFERENCE_LIBRARY.md](docs/REFERENCE_LIBRARY.md).
La persistencia y gestión de contenido descargado están en [docs/OFFLINE_CONTENT.md](docs/OFFLINE_CONTENT.md).
La cola de operaciones seguras y sus conflictos está en [docs/OFFLINE_SYNC.md](docs/OFFLINE_SYNC.md).
Las preferencias persistentes y el recordatorio diario local están documentados en [docs/PREFERENCES_NOTIFICATIONS.md](docs/PREFERENCES_NOTIFICATIONS.md).
El contrato de XP, rachas, actividad y logros está en [docs/GAMIFICATION_CONTRACT.md](docs/GAMIFICATION_CONTRACT.md).
El alcance y la persistencia local de favoritos están en [docs/FAVORITES.md](docs/FAVORITES.md).
La búsqueda académica y la protección del banco de preguntas están documentadas en [docs/ACADEMIC_SEARCH.md](docs/ACADEMIC_SEARCH.md).
Las transiciones y su comportamiento de accesibilidad están en [docs/MOTION.md](docs/MOTION.md).
La reanudación local de la última lección está documentada en [docs/CONTINUE_LEARNING.md](docs/CONTINUE_LEARNING.md).
El temporizador Pomodoro compartido está documentado en [docs/POMODORO.md](docs/POMODORO.md).
Las flashcards académicas y su progreso local están documentados en [docs/FLASHCARDS.md](docs/FLASHCARDS.md).
El contador global de días para el examen está documentado en [docs/EXAM_COUNTDOWN.md](docs/EXAM_COUNTDOWN.md).
El feedback visual y háptico de rachas de aciertos está documentado en [docs/ANSWER_STREAK_FEEDBACK.md](docs/ANSWER_STREAK_FEEDBACK.md).
Las marcas locales y protegidas de preguntas difíciles están documentadas en [docs/DIFFICULT_QUESTIONS.md](docs/DIFFICULT_QUESTIONS.md).
El repaso de las respuestas falladas durante el día está documentado en [docs/DAILY_MISTAKE_REVIEW.md](docs/DAILY_MISTAKE_REVIEW.md).
El registro local del tiempo total estudiado está documentado en [docs/STUDY_TIME.md](docs/STUDY_TIME.md).

## Configuración por ambiente

```powershell
flutter run --dart-define=APP_ENV=dev --dart-define=API_BASE_URL=http://10.0.2.2:3000 --dart-define=CONTENT_BASE_URL=http://10.0.2.2:3001 --dart-define=DEMO_MODE=true
```

- `APP_ENV`: `dev`, `staging` o `prod`.
- `API_BASE_URL`: raíz del backend NestJS, sin `/v1`.
- `CONTENT_BASE_URL`: origen opcional que publica las imágenes legadas bajo `/imagenes`; si se omite, usa el origen de la API.
- `DEMO_MODE`: habilita los accesos demostrativos mientras se conecta autenticación real.

## Calidad

```powershell
flutter analyze
flutter test
```

## Validación real de autenticación

Con el backend, PostgreSQL y sus migraciones ejecutándose, se puede validar el flujo completo y el repositorio Dart de Flutter:

```powershell
.\tool\verify_auth_api.ps1 `
  -ApiBaseUrl http://127.0.0.1:3000 `
  -DatabaseUrl "postgresql://usuario:clave@127.0.0.1:5432/base?schema=public"
```

El script crea una cuenta E2E única. Debe ejecutarse solamente contra una base de desarrollo o pruebas, ya que consulta los tokens de verificación y recuperación directamente en PostgreSQL.

Consulta el avance y las siguientes entregas en [docs/ROADMAP_MOVIL.md](docs/ROADMAP_MOVIL.md).
