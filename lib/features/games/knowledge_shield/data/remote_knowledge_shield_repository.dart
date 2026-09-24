import 'package:dio/dio.dart';

import '../../../../core/network/api_error.dart';
import '../../../academic/domain/academic_models.dart';
import '../../../practice/domain/practice_models.dart';
import '../domain/knowledge_shield_models.dart';
import 'knowledge_shield_resume_store.dart';

class RemoteKnowledgeShieldRepository implements KnowledgeShieldRepository {
  RemoteKnowledgeShieldRepository(this.dio, this.store, {required this.scope});
  final Dio dio;
  final KnowledgeShieldResumeStore store;
  final String scope;
  bool _disposed = false;
  bool _busy = false;
  bool _restored = false;
  KnowledgeShieldAttempt? _current;
  KnowledgeShieldPendingAnswer? _pending;
  @override
  bool get isDemo => false;
  @override
  KnowledgeShieldAttempt? get current => _current;
  @override
  KnowledgeShieldPendingAnswer? get pending => _pending;
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

  String _path(String id) =>
      '/escudo-conocimiento/intentos/${Uri.encodeComponent(id)}';
  Future<KnowledgeShieldAttempt?> _request(
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
      final result = KnowledgeShieldAttempt.fromJson(
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

  Future<KnowledgeShieldAttempt> _accept(KnowledgeShieldAttempt result) async {
    _check();
    final pending = _pending;
    final keep =
        pending != null &&
        !result.finished &&
        result.id == pending.attemptId &&
        result.question?.id == pending.questionId;
    await store.save(
      scope,
      KnowledgeShieldResume(result.id, keep ? pending : null),
    );
    _check();
    _pending = keep ? pending : null;
    return _current = result;
  }

  @override
  Future<KnowledgeShieldAttempt?> restore() => _exclusive(() async {
    final saved = await store.read(scope);
    _check();
    _pending = saved?.pending;
    // Prefer a newer active attempt (e.g. a start whose acknowledgment was lost).
    KnowledgeShieldAttempt? result = await _request(
      '/escudo-conocimiento/intentos/activo',
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
  Future<KnowledgeShieldAttempt> start(
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
      '/escudo-conocimiento/intentos',
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
  Future<KnowledgeShieldAttempt> answer({
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
        KnowledgeShieldPendingAnswer(
          attemptId: attemptId,
          questionId: questionId,
          answerId: answerId,
          requestKey: requestKey,
        );
    // Persistence must succeed before any POST; failures never become local grading.
    await store.save(scope, KnowledgeShieldResume(attemptId, submission));
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
        (result.status != 'EXPIRADO' &&
            result.progress.answered == _current!.progress.answered) ||
        result.area != _current!.area) {
      throw const FormatException(
        'El servidor no confirmó el envío. Sincroniza la partida.',
      );
    }
    return _accept(result);
  });
  @override
  Future<KnowledgeShieldAttempt> abandon(String attemptId) =>
      _exclusive(() async {
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
