import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_error.dart';
import '../../../auth/presentation/session_controller.dart';
import '../../../auth/domain/session.dart';
import '../domain/guardian_models.dart';
import 'demo_guardian_repository.dart';
import 'guardian_resume_store.dart';

final guardianRepositoryProvider = Provider<GuardianRepository?>((ref) {
  final account = ref.watch(
    sessionControllerProvider.select(
      (state) => (state.user?.id, state.user?.isDemo, state.user?.role),
    ),
  );
  if (account.$1 == null || account.$3 != AppRole.student) return null;
  if (account.$2 == true) return DemoGuardianRepository();
  final dio = ref.watch(dioProvider);
  final repository = RemoteGuardianRepository(
    dio,
    ref.watch(guardianResumeStoreProvider),
    scope: '${dio.options.baseUrl}\u0000${account.$1}',
  );
  ref.onDispose(repository.dispose);
  return repository;
});

class RemoteGuardianRepository implements GuardianRepository {
  RemoteGuardianRepository(this.dio, this.store, {required this.scope});
  final Dio dio;
  final GuardianResumeStore store;
  final String scope;
  bool _disposed = false;
  bool _busy = false;
  bool _restored = false;
  GuardianAttempt? _current;
  GuardianPendingAnswer? _pending;
  @override
  GuardianPendingAnswer? get pending => _pending;
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

  Future<GuardianAttempt?> _request(
    String path, {
    Map<String, dynamic>? data,
    String? expectedId,
    bool? expectedCompetitive,
  }) async {
    _check();
    try {
      final response = data == null
          ? await dio.get<Object?>(path)
          : await dio.post<Object?>(path, data: data);
      final body = response.data;
      _check();
      if (body == null || body == '') return null;
      if (body is! Map) {
        throw const FormatException('Respuesta de desafío inválida.');
      }
      final result = GuardianAttempt.fromJson(Map<String, dynamic>.from(body));
      if (expectedId != null && result.id != expectedId) {
        throw const FormatException('El servidor devolvió otro desafío.');
      }
      if (expectedCompetitive != null &&
          result.isCompetitive != expectedCompetitive) {
        throw const FormatException('El servidor devolvió otra modalidad.');
      }
      return result;
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        throw const ApiError(
          code: '404',
          message: 'El desafío no está disponible en el servidor.',
        );
      }
      throw ApiError.fromDioException(e);
    }
  }

  GuardianAttempt _required(GuardianAttempt? attempt) =>
      attempt ??
      (throw const FormatException('El servidor no devolvió el desafío.'));
  String _path(String id) => '/guardian/intentos/${Uri.encodeComponent(id)}';
  Future<GuardianAttempt> _accept(GuardianAttempt result) async {
    _check();
    if (_current?.id == result.id &&
        (_current!.isCompetitive != result.isCompetitive ||
            _current!.config.area != result.config.area ||
            _current!.config.difficulty != result.config.difficulty ||
            _current!.config.subtopicId != result.config.subtopicId ||
            result.review.length < _current!.review.length)) {
      throw const FormatException(
        'La modalidad o el estado del desafío cambió.',
      );
    }
    final pending = _pending;
    final keep =
        pending != null &&
        result.isActive &&
        result.id == pending.attemptId &&
        result.question?.id == pending.questionId;
    if (pending != null && result.id == pending.attemptId) {
      final confirmed = result.review.where(
        (r) => r.question.id == pending.questionId,
      );
      if (confirmed.any((r) => r.answerId != pending.answerId)) {
        throw const FormatException('El servidor confirmó otra respuesta.');
      }
    }
    await store.save(
      scope,
      GuardianResume(result.id, keep ? pending : null, result.isCompetitive),
    );
    _check();
    _pending = keep ? pending : null;
    return _current = result;
  }

  @override
  Future<GuardianAttempt?> active() => _exclusive(() async {
    final saved = await store.read(scope);
    _check();
    _pending = saved?.pending;
    var result = await _request('/guardian/intentos/activo');
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
      if (saved?.attemptId == result.id &&
          saved?.isCompetitive != null &&
          saved!.isCompetitive != result.isCompetitive) {
        throw const FormatException(
          'La modalidad guardada del desafío cambió.',
        );
      }
      await _accept(result);
    }
    _restored = true;
    return _current;
  });
  @override
  Future<GuardianAttempt> start(
    GuardianConfig config, {
    bool competitive = false,
  }) => _exclusive(() async {
    if (!_restored || _pending != null) {
      throw const ApiError(
        code: 'restore_required',
        message: 'Recupera primero tu partida o envío pendiente.',
      );
    }
    final result = _required(
      await _request(
        '/guardian/intentos',
        expectedCompetitive: competitive,
        data: {...config.toJson(), if (competitive) 'competitive': true},
      ),
    );
    if (result.config.area != config.area ||
        result.config.difficulty != config.difficulty ||
        result.config.subtopicId != config.subtopicId) {
      throw const FormatException('El servidor devolvió otros filtros.');
    }
    return _accept(result);
  });
  @override
  Future<GuardianAttempt> get(String id) => _exclusive(
    () async => _accept(_required(await _request(_path(id), expectedId: id))),
  );
  @override
  Future<GuardianAttempt> answer({
    required String id,
    required String questionId,
    required String answerId,
    required String idempotencyKey,
  }) => _exclusive(() async {
    if (!_restored ||
        _current?.id != id ||
        !_current!.isActive ||
        _current!.question?.id != questionId ||
        !_current!.question!.options.any((o) => o.id == answerId)) {
      throw const ApiError(
        code: 'restore_required',
        message: 'Sincroniza el desafío antes de responder.',
      );
    }
    final submission = GuardianPendingAnswer.fromJson({
      'attemptId': id,
      'questionId': questionId,
      'answerId': answerId,
      'idempotencyKey': idempotencyKey,
    });
    if (_pending != null &&
        (_pending!.attemptId != id ||
            _pending!.questionId != questionId ||
            _pending!.answerId != answerId ||
            _pending!.idempotencyKey != idempotencyKey)) {
      throw const ApiError(
        code: 'pending_answer',
        message: 'Confirma o sincroniza primero el envío pendiente.',
      );
    }
    await store.save(
      scope,
      GuardianResume(id, submission, _current!.isCompetitive),
    );
    _check();
    _pending = submission;
    final result = _required(
      await _request(
        '${_path(id)}/respuestas',
        expectedId: id,
        data: {
          'preguntaId': questionId,
          'respuestaId': answerId,
          'idempotencyKey': idempotencyKey,
        },
      ),
    );
    if (result.review.length < _current!.review.length ||
        !result.review.any(
          (r) => r.question.id == questionId && r.answerId == answerId,
        )) {
      throw const FormatException(
        'El servidor no confirmó el envío. Sincroniza el desafío.',
      );
    }
    return _accept(result);
  });
  @override
  Future<GuardianAttempt> abandon(String id) => _exclusive(() async {
    if (!_restored || _current?.id != id) {
      throw const ApiError(
        code: 'restore_required',
        message: 'Recupera el desafío primero.',
      );
    }
    return _accept(
      _required(
        await _request('${_path(id)}/abandonar', data: {}, expectedId: id),
      ),
    );
  });
}
