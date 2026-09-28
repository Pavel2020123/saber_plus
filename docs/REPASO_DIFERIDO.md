# MA-3 — Repaso diferido

Estado: MA-3A implementada localmente. **Sigue MA-3B**. No afirmar que la agenda
ya aparece en la app o se sincroniza: esta entrega es el núcleo de reglas probado.

| Entrega | Estado | Alcance |
|---|---|---|
| MA-3A | Implementada localmente | Reglas deterministas, separación por cuenta y armado de agenda |
| MA-3B | Siguiente | Contrato/API, persistencia local/remota y sincronización idempotente |
| MA-3C | Pendiente | Integración en flashcards/repasos y pantalla de pendientes/próximos |
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

Reutilizar pantalla de flashcards con modo «Repasos pendientes», próximos y
práctica libre diferenciados. No cambiar reglas silenciosamente al pulsar
«Lo recuerdo». Mostrar carga/error/vacío/sin conexión. No presentar la
autoevaluación como acierto corregido automáticamente.

Reutilizar cuaderno de errores cuando el contrato permita una comprobación real;
no tratar una pregunta repetida como una muestra independiente de dominio.
Probar texto grande, navegación, cambio de cuenta y vuelta al día siguiente.

## Reanudación y commits

Flutter: `C:\Users\LENOVO 14ALC6\Desktop\SaberPLus\saber_plus`.
Backend: `C:\Users\LENOVO 14ALC6\Desktop\SaberPlus-Backend` (necesario para MA-3B).
Trabajar en rama; revisar `git status` y no incluir secretos ni cambios ajenos.
Mensaje MA-3A: `feat: definir reglas de repaso diferido`.
No marcar toda MA-3 terminada hasta cerrar B/C y distinguir el ensayo real.
Después sigue PR-I1. UI final azul, animaciones, anuncios y P5/D3 no se adelantan.
