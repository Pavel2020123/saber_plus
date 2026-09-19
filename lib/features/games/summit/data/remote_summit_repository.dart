import 'package:dio/dio.dart';

import '../../../../core/network/api_error.dart';
import '../../../academic/domain/academic_models.dart';
import '../../../practice/domain/practice_models.dart';
import '../domain/summit_models.dart';
import 'summit_resume_store.dart';

class RemoteSummitRepository implements SummitRepository {
  RemoteSummitRepository(this.dio, this.store, {required this.scope});
  final Dio dio;
  final SummitResumeStore store;
  final String scope;
  bool _disposed = false;
  bool _busy = false;
  bool _restored = false;
  SummitAttempt? _current;
  SummitPendingAnswer? _pending;
  @override
  bool get isDemo => false;
  @override
  SummitAttempt? get current => _current;
  @override
  SummitPendingAnswer? get pending => _pending;
  void dispose() {
    _disposed = true;
    _current = null;
    _pending = null;
  }

  void _check() {
    if (_disposed) {
      throw const ApiError(
        code: 'session_changed',
        message: 'La cuenta cambió. Vuelve a abrir el juego.',
      );
    }
  }

  Future<T> _exclusive<T>(Future<T> Function() action) async {
    _check();
    if (_busy) {
      throw const ApiError(
        code: 'busy',
        message: 'Espera a que termine la operación.',
      );
    }
    _busy = true;
    try {
      return await action();
    } finally {
      _busy = false;
    }
  }

  String _path(String id) => '/salto-cima/intentos/${Uri.encodeComponent(id)}';
  Future<SummitAttempt?> _request(
    String path, {
    Map<String, dynamic>? data,
    bool nullable = false,
    String? expectedId,
  }) async {
    _check();
    try {
      final response = data == null
          ? await dio.get<Object?>(path)
          : await dio.post<Object?>(path, data: data);
      _check();
      if (nullable && (response.data == null || response.data == '')) {
        return null;
      }
      if (response.data is! Map) {
        throw const FormatException('Respuesta del servidor inválida.');
      }
      final result = SummitAttempt.fromJson(
        Map<String, dynamic>.from(response.data as Map),
      );
      if (expectedId != null && result.id != expectedId) {
        throw const FormatException('El servidor devolvió otra partida.');
      }
      return result;
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        throw const ApiError(
          code: '404',
          message:
              'La partida o esta función no está disponible en el servidor.',
        );
      }
      throw ApiError.fromDioException(e);
    }
  }

  Future<SummitAttempt> _accept(SummitAttempt result) async {
    _check();
    final pending = _pending;
    final keep =
        pending != null &&
        !result.finished &&
        result.id == pending.attemptId &&
        result.question?.id == pending.questionId;
    await store.save(scope, SummitResume(result.id, keep ? pending : null));
    _check();
    _pending = keep ? pending : null;
    return _current = result;
  }

  @override
  Future<SummitAttempt?> restore() => _exclusive(() async {
    final saved = await store.read(scope);
    _check();
    _pending = saved?.pending;
    // Prefer a newer active attempt (e.g. a start whose acknowledgment was lost).
    SummitAttempt? result = await _request(
      '/salto-cima/intentos/activo',
      nullable: true,
    );
    if (result == null && saved != null) {
      try {
        result = await _request(
          _path(saved.attemptId),
          expectedId: saved.attemptId,
        );
      } on ApiError catch (e) {
        if (e.code != '404') rethrow;
      }
    }
    if (result == null) {
      await store.save(scope, null);
      _check();
      _current = null;
      _pending = null;
    } else {
      await _accept(result);
    }
    _restored = true;
    return _current;
  });
  @override
  Future<SummitAttempt> start(
    AcademicArea area, {
    String? themeId,
    String? subtopicId,
    PracticeDifficulty? difficulty,
  }) => _exclusive(() async {
    if (!_restored || _pending != null) {
      throw const ApiError(
        code: 'restore_required',
        message: 'Recupera primero tu partida o envío pendiente.',
      );
    }
    final result = (await _request(
      '/salto-cima/intentos',
      data: {
        'area': area.backendValue,
        'temaId': ?themeId,
        'subtemaId': ?subtopicId,
        if (difficulty != null) 'dificultad': difficulty.backendValue,
      },
    ))!;
    return _accept(result);
  });
  @override
  Future<SummitAttempt> answer({
    required String attemptId,
    required String questionId,
    required String answerId,
    required String requestKey,
  }) => _exclusive(() async {
    if (!_restored ||
        _current?.id != attemptId ||
        _current!.finished ||
        _current!.question?.id != questionId ||
        !_current!.question!.options.any((o) => o.id == answerId)) {
      throw const ApiError(
        code: 'restore_required',
        message: 'Sincroniza la partida antes de responder.',
      );
    }
    if (!RegExp(
      r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-4[0-9a-fA-F]{3}-[89abAB][0-9a-fA-F]{3}-[0-9a-fA-F]{12}$',
    ).hasMatch(requestKey)) {
      throw const FormatException('Clave de envío inválida.');
    }
    final pending = _pending;
    if (pending != null &&
        (pending.attemptId != attemptId ||
            pending.questionId != questionId ||
            pending.answerId != answerId ||
            pending.requestKey != requestKey)) {
      throw const ApiError(
        code: 'pending_answer',
        message: 'Confirma o sincroniza primero el envío pendiente.',
      );
    }
    final submission =
        pending ??
        SummitPendingAnswer(
          attemptId: attemptId,
          questionId: questionId,
          answerId: answerId,
          requestKey: requestKey,
        );
    // Persistence must succeed before any POST; failures never become local grading.
    await store.save(scope, SummitResume(attemptId, submission));
    _check();
    _pending = submission;
    final result = (await _request(
      '${_path(attemptId)}/respuestas',
      expectedId: attemptId,
      data: {
        'preguntaId': questionId,
        'respuestaId': answerId,
        'idempotencyKey': requestKey,
      },
    ))!;
    if ((!result.finished && result.question?.id == questionId) ||
        result.progress.answered < _current!.progress.answered ||
        result.area != _current!.area) {
      throw const FormatException(
        'El servidor no confirmó el envío. Sincroniza la partida.',
      );
    }
    return _accept(result);
  });
  @override
  Future<SummitAttempt> abandon(String attemptId) => _exclusive(() async {
    if (!_restored || _current?.id != attemptId) {
      throw const ApiError(
        code: 'restore_required',
        message: 'Recupera la partida primero.',
      );
    }
    return _accept(
      (await _request(
        '${_path(attemptId)}/abandonar',
        data: {},
        expectedId: attemptId,
      ))!,
    );
  });
}
