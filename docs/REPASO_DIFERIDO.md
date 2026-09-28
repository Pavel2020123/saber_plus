# MA-3 — Repaso diferido

Estado: MA-3A/B/C implementadas localmente. **Sigue PR-I1**. La agenda ya aparece
en la app con cuenta real. Falta ensayo con dispositivo e infraestructura
autorizada; no se han desplegado migraciones ni cambios en Render/Supabase.

| Entrega | Estado | Alcance |
|---|---|---|
| MA-3A | Implementada localmente | Reglas deterministas, separación por cuenta y armado de agenda |
| MA-3B | Implementada/probada localmente | Contrato/API, persistencia local/remota y sincronización idempotente |
| MA-3C | Implementada/probada localmente | Agenda, flashcards y sincronización en primer plano |
| Ensayo real | Pendiente | Reconexión, reinstalación, cuentas y dispositivo con infraestructura autorizada |

## Política inicial v1

- Reutilizar flashcards; no construir otro catálogo ni sistema de notificaciones.
- Primera autoevaluación: próximo repaso en un día, recuerde o necesite practicar.
- Autoevaluaciones recordadas, cuando corresponde repasar: 1 → 3 → 7 → 14 → 30 días.
  Después permanece en 30 días. Es una política inicial configurable en una futura
  versión, no una afirmación de eficacia validada ni un diagnóstico académico.
- Si necesita practicar en el repaso pendiente, reiniciar en un día.
- Repetición anticipada: práctica libre, sin mover fecha/intervalo/revisión.
- Repaso tardío: avanzar un único paso desde la fecha efectiva del repaso. No
  generar aciertos ficticios por los intervalos que transcurrieron sin actividad.
- «Día» significa 24 horas transcurridas en UTC, no cambio de fecha del teléfono.
  La UI mostrará la hora local; cambiar zona horaria no mueve el vencimiento.
- Vence cuando `ahora >= fechaProgramada`. No hay penalización por retraso.
- No hay XP, certificados, racha, dominio ni nueva evidencia independiente por
  autoevaluar o repetir la misma tarjeta. `mastered` histórico no prueba dominio.
- Una tarjeta sin agenda no es vencida. No transformar contadores antiguos en
  intervalos aprendidos: no contienen el historial necesario para inferirlos.

## Implementación MA-3A

`lib/features/flashcards/domain/deferred_review.dart`: estado inmutable con
cuenta, tarjeta, paso, revisión, fecha del repaso y próximo vencimiento; política
pura con reloj explícito; armado de agenda pendiente/próxima ordenada por fecha.
Filtra otras cuentas y contenido ausente del catálogo. Rechaza filas duplicadas
ambiguas en vez de escoger silenciosamente un progreso ganador.

`test/deferred_review_test.dart`: intervalos, reinicio, límite, anticipados,
revisión vieja, retrasos, reloj atrasado, UTC, cuentas, retiradas y duplicados.
No cambia el comportamiento actual de las flashcards ni crea tablas todavía.
Verificación: 16 pruebas seleccionadas aprobadas (reglas, modelos y repositorio
de flashcards); `flutter analyze` sin problemas.

## MA-3B — contrato y sincronización, no improvisar

**Entrega local cerrada el 28 de septiembre.** Contrato detallado en el otro repo:
`backend/DEFERRED_REVIEW.md`. API GET agenda/POST evento autenticados, registro de
130 IDs congelados `library-v1`, recibos idempotentes, revisión optimista, reloj
PostgreSQL y transacción con lock por cuenta. Ninguna migración en Supabase.

Flutter: esquema Drift 10 (`DeferredReviewEntries`), repositorio
`lib/features/flashcards/data/deferred_review_repository.dart` y proveedor
`presentation/deferred_review_providers.dart`. Guardado atómico de predicción y
evento; confirmado separado; un evento en vuelo por tarjeta; reintentos conservan
UUID/cuerpo. Conflictos/retirados/inválidos no reintentan solos. Descarte explícito
de conflicto primero recarga el servidor. Respuestas tardías no confirman otra
sesión. Refrescar recupera confirmados tras reinstalar, nunca eventos perdidos
que no llegaron al servidor. No se importan contadores antiguos como retención.

Decisión temporal: offline solo predice. La fecha efectiva es la recepción en el
servidor; no confiar en fecha del teléfono ni acumular pasos durante desconexión.
La práctica temprana conocida no encola; el servidor vuelve a comprobar vencimiento.
Es autoevaluación, no comprobación independiente de dominio ni acierto evaluado.

Verificación: 45 pruebas Flutter seleccionadas (agenda, sincronización, migraciones
y Pomodoro), 10 Jest y 5 PostgreSQL temporal. UI/ensayo físico y staging pendientes.
Se reutiliza la base Drift y el patrón de sincronización existente; la cola tiene
su tabla propia para no mezclar DTOs ni alterar progreso/cuaderno/Pomodoro.

Las instrucciones siguientes documentan el alcance aplicado y los límites que
debe respetar MA-3C. Revisar política de versiones antes de editar las 130 tarjetas.

1. Revisar `FlashcardRepository`, Drift, cola de sincronización existente y
   backend `cuaderno-errores`. Definir IDs estables/versiones de contenido:
   los IDs actuales derivados del texto no bastan para tratar una edición como
   la misma tarjeta sin decidir su migración. No guardar respuestas correctas
   ni datos de otro alumno en un endpoint público.
2. API autenticada deriva usuario de sesión. Estado único por cuenta y tarjeta;
   política versionada y revisión optimista. Persistir evento idempotente con
   ID único por cuenta y huella del cuerpo: repetición idéntica devuelve resultado
   anterior; mismo ID con otro cuerpo se rechaza. La revisión local por sí sola
   NO implementa esa garantía de red ni sustituye la transacción del servidor.
3. Reloj servidor autoritativo para vencimientos. Definir cómo reconciliar fechas
   de práctica offline sin confiar en un reloj manipulable; no usar simplemente
   el reloj del teléfono para aceptar saltos. No reenviar conflictos a ciegas.
4. Migración Drift + cola durable atómica: guardar revisión local y evento juntos.
   Mostrar pendiente de sincronizar/error/conflicto; separar demo y cuenta real.
   Guardar contenido mínimo, aislar cuentas y limpiar vistas en logout.
5. Tras reinstalar, reconstruir agenda desde servidor. No prometer recuperación
   de eventos que nunca salieron del dispositivo. Contenido retirado no debe
   generar tareas navegables ni una cadena perpetua de reintentos.
6. Probar idempotencia, concurrencia, permisos, reconexión, fechas, conflicto y
   recuperación. PostgreSQL temporal autorizado por runner, no Supabase/Render
   mientras P5/D3 permanezcan pausadas.

## MA-3C — UI y práctica

Entrega local: Progreso → Flashcards → Repasos pendientes y próximos. Muestra
vencidos, próximos, nuevas tarjetas y respuestas sin confirmar/bloqueadas. Las
fechas son locales; el reloj de pantalla actualiza vencimientos cada minuto.
Las próximas no abren un repaso anticipado; la práctica libre sigue disponible
por separado y no modifica esta agenda. Una sesión programada contiene una tarjeta.

La demo informa que necesita cuenta real, sin encolar ni consultar el backend.
Cada respuesta se guarda primero en la cola durable. Se intenta sincronizar al
responder, manualmente en la agenda y con el ciclo existente de estudio en primer
plano (cada minuto); no se agrega otro temporizador de red ni notificaciones.
Pendiente no significa confirmado: ante desconexión se conserva la respuesta.
Conflictos, retirados e inválidos requieren confirmación antes de descartarse.
Cambio de cuenta/configuración invalida resultados visuales tardíos.

Archivos: `presentation/deferred_review_page.dart`, `deferred_review_providers.dart`,
`flashcard_session_page.dart` y `study_time/presentation/study_evolution_providers.dart`.
Ruta: `/student/progress/flashcards/agenda`; sesión con parámetro `repaso` validado
contra el catálogo. Los textos dicen autoevaluación, no dominio acreditado.

El cuaderno de errores y el repaso diario tienen accesos desde la agenda. Sus
preguntas NO reciben intervalos nuevos ni generan evidencia independiente por
repetirse. Programar evaluaciones corregidas requeriría otro contrato explícito.

Pruebas de interfaz: ocho casos cubren grupos, texto grande, demo, error de red,
sesión de una tarjeta, ID inexistente, ruta, descarte confirmado y vencimiento.
Ensayo físico, reconexión/reinstalación real y accesibilidad manual siguen pendientes.

Verificación MA-3C: `flutter analyze` sin problemas; 54 pruebas seleccionadas
aprobadas (`deferred_review_page_test`, `flashcard_page_test`, `flashcard_models_test`,
`deferred_review_sync_test` y `widget_test`); `git diff --check` limpio.

## Reanudación y commits

Flutter: `C:\Users\LENOVO 14ALC6\Desktop\SaberPLus\saber_plus`.
Backend: `C:\Users\LENOVO 14ALC6\Desktop\SaberPlus-Backend` (necesario para MA-3B).
Trabajar en rama; revisar `git status` y no incluir secretos ni cambios ajenos.
Mensaje MA-3A: `feat: definir reglas de repaso diferido`.
Mensaje MA-3C: `feat: integrar agenda de repasos y flashcards`.
MA-3 está implementada localmente; no marcar el ensayo real como terminado.
Después sigue PR-I1. UI final azul, animaciones, anuncios y P5/D3 no se adelantan.
