import 'package:dio/dio.dart';
import 'package:drift/drift.dart';
import '../../../core/database/app_database.dart';
import '../../../core/network/auth_interceptor.dart';
import '../../../core/sync/safe_sync_models.dart';
import '../domain/study_evolution.dart';

String pomodoroSyncMessage(String? code) => switch (code) {
  'clock_future' =>
    'La fecha está en el futuro. Revisa el reloj y reintenta sin cambiar el bloque.',
  'expired' =>
    'El bloque tiene más de 90 días: se conserva localmente, pero ya no se puede subir.',
  'conflict' =>
    'El servidor detectó otra fecha para este ID o un bloque superpuesto. No cambies el ID para reenviarlo.',
  'invalid' => 'El bloque no cumple el formato de Pomodoro de 25 minutos.',
  'unconfirmed' =>
    'La confirmación no pudo validarse. Reintenta la misma solicitud; podría haberse guardado.',
  'session' =>
    'Inicia sesión con tu cuenta de estudiante verificada para continuar.',
  'unavailable' =>
    'La función no está disponible en el backend. La cola se conserva hasta desplegar P4-A.',
  'certificate' =>
    'La conexión no tiene un certificado válido. No se enviaron más bloques.',
  'network' => 'Pendiente de conexión o respuesta del servidor.',
  _ => 'Pendiente de envío.',
};

class PomodoroSyncWorker {
  PomodoroSyncWorker(
    this.db,
    this.dio, {
    required this.currentSession,
    DateTime Function()? now,
  }) : now = now ?? DateTime.now;
  final AppDatabase db;
  final Dio dio;
  final SyncSessionSnapshot? Function() currentSession;
  final DateTime Function() now;
  bool _disposed = false;
  Future<int>? _active;
  CancelToken? _cancel;
  void dispose() {
    _disposed = true;
    _cancel?.cancel();
  }

  bool _current(SyncSessionSnapshot session) {
    if (_disposed) return false;
    final actual = currentSession();
    return actual?.userId == session.userId &&
        actual?.revision == session.revision;
  }

  Future<int> synchronize() {
    if (_disposed) return Future.value(0);
    return _active ??= _run().whenComplete(() => _active = null);
  }

  Future<int> _run() async {
    final session = currentSession();
    if (session == null) return 0;
    final rows = await db.pendingPomodoros(session.userId);
    var confirmed = 0;
    for (final row in rows) {
      if (!_current(session)) break;
      String? invalid;
      DateTime? ended;
      try {
        ended = studyInstant(row.endedAtUtc);
        if (!RegExp(
          r'^pomodoro:(?:[0-9]{13,20}|[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12})$',
        ).hasMatch(row.eventId)) {
          invalid = 'invalid';
        }
        if (ended.isAfter(now())) invalid = 'clock_future';
        // Un envío incierto puede estar confirmado: el backend reconoce IDs
        // antiguos conocidos. Solo bloquear localmente los nunca enviados.
        if (row.attempts == 0 &&
            ended.isBefore(now().subtract(const Duration(days: 90)))) {
          invalid = 'expired';
        }
      } on FormatException {
        invalid = 'invalid';
      }
      if (invalid != null) {
        await _mark(row, 'blocked', invalid, increment: false);
        continue;
      }
      final cancel = CancelToken();
      _cancel = cancel;
      // Persistir el intento ANTES de enviar: si el proceso muere, no se tratará
      // como nunca enviado cuando venza la ventana de 90 días.
      final claimed = await db.updatePomodoroIfUnchanged(
        row,
        PomodoroSyncEntriesCompanion(attempts: Value(row.attempts + 1)),
      );
      if (claimed == 0 || !_current(session)) continue;
      final sent = row.copyWith(attempts: row.attempts + 1);
      try {
        final response = await dio.post<Map<String, dynamic>>(
          '/tiempo-estudio/me/pomodoros',
          data: {
            'version': 1,
            'eventos': [
              {
                'eventoId': row.eventId,
                'duracionSegundos': 1500,
                'finalizadoEn': row.endedAtUtc,
              },
            ],
          },
          options: Options(
            extra: {AuthInterceptor.sessionRevisionKey: session.revision},
          ),
          cancelToken: cancel,
        );
        if (!_current(session)) break;
        final body = studyMap(response.data);
        validateStudyPolicy(body['politica']);
        if (body['version'] != 1 ||
            body['confirmados'] is! List ||
            (body['confirmados'] as List).length != 1) {
          throw const FormatException();
        }
        final ack = studyMap((body['confirmados'] as List).single);
        if (ack['eventoId'] != row.eventId ||
            ack['duracionSegundos'] != 1500 ||
            ack['reutilizado'] is! bool ||
            studyInstant(ack['finalizadoEn']) != ended) {
          throw const FormatException();
        }
        confirmed += await db.updatePomodoroIfUnchanged(
          sent,
          const PomodoroSyncEntriesCompanion(
            status: Value('confirmed'),
            errorCode: Value(null),
          ),
        );
      } on DioException catch (error) {
        if (!_current(session) || error.type == DioExceptionType.cancel) break;
        final status = error.response?.statusCode;
        final code = error.type == DioExceptionType.badCertificate
            ? 'certificate'
            : switch (status) {
                400 => 'invalid',
                409 => 'conflict',
                401 || 403 => 'session',
                404 || 410 => 'unavailable',
                _ => 'network',
              };
        final blocked = ['invalid', 'conflict', 'certificate'].contains(code);
        await _mark(
          sent,
          blocked ? 'blocked' : 'pending',
          code,
          increment: false,
        );
        if (!blocked || code == 'certificate') break;
      } on Object {
        if (!_current(session)) break;
        await _mark(sent, 'blocked', 'unconfirmed', increment: false);
      }
    }
    return confirmed;
  }

  Future<void> _mark(
    PomodoroSyncEntry row,
    String status,
    String code, {
    bool increment = true,
  }) async {
    await db.updatePomodoroIfUnchanged(
      row,
      PomodoroSyncEntriesCompanion(
        status: Value(status),
        errorCode: Value(code),
        attempts: Value(row.attempts + (increment ? 1 : 0)),
      ),
    );
  }

  Future<void> retry(String eventId) async {
    final session = currentSession();
    if (session == null || !_current(session)) return;
    final row = await db.findPomodoro(session.userId, eventId);
    if (row == null || row.status != 'blocked' || !_current(session)) return;
    await db.updatePomodoroIfUnchanged(
      row,
      const PomodoroSyncEntriesCompanion(
        status: Value('pending'),
        errorCode: Value(null),
      ),
    );
    await synchronize();
  }

  Future<void> keepLocalOnly(String eventId) async {
    final session = currentSession();
    if (session == null || !_current(session)) return;
    final row = await db.findPomodoro(session.userId, eventId);
    if (row == null || row.status != 'blocked' || !_current(session)) return;
    // Conserva recibo y registro local, no altera IDs ni borra tiempo.
    await db.updatePomodoroIfUnchanged(
      row,
      const PomodoroSyncEntriesCompanion(status: Value('discarded')),
    );
  }
}
