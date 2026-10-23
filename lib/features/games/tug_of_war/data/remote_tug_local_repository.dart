import 'package:dio/dio.dart';

import '../../../../core/network/api_error.dart';
import '../../trivia_rush/data/remote_trivia_rush_repository.dart';
import '../../trivia_rush/domain/trivia_rush_models.dart';
import '../domain/tug_local_repository.dart';

class RemoteTugLocalRepository implements TugLocalRepository {
  RemoteTugLocalRepository(this._dio);

  final Dio _dio;
  final _answerOperations = <(String, String), (String, String)>{};
  final _timeoutKeys = <(String, String), String>{};

  String _path(String attemptId) =>
      '/tira-local/intentos/${Uri.encodeComponent(attemptId)}';

  Future<Map<String, dynamic>> _post(
    String path, [
    Map<String, dynamic>? data,
  ]) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(path, data: data);
      final body = response.data;
      final value = body?['data'] is Map
          ? Map<String, dynamic>.from(body!['data'] as Map)
          : body;
      if (value == null ||
          (value['intento'] as Map?)?['modalidad'] != 'TUG_LOCAL') {
        throw const FormatException('Estado de Tira local inválido.');
      }
      return value;
    } on DioException catch (error) {
      throw ApiError.fromDioException(error);
    }
  }

  TriviaRushSession _session(Map<String, dynamic> body) {
    final state = TriviaRushServerState.fromJson(body);
    return TriviaRushSession(
      attemptId: state.attemptId,
      questions: [?state.currentQuestion],
      serverState: state,
    );
  }

  TugLocalRound _round(Map<String, dynamic> body) {
    final round = (body['intento'] as Map)['rondaLocal'] as Map;
    final remaining = round['tiempoRestanteMs'] as int;
    final version = round['version'] as int;
    if (remaining < 0 || remaining > 10000 || version < 0) {
      throw const FormatException('Reloj de Tira local inválido.');
    }
    return TugLocalRound(
      session: _session(body),
      version: version,
      paused: round['pausada'] as bool,
      remainingMilliseconds: remaining,
      receivedAt: DateTime.now(),
    );
  }

  @override
  Future<TriviaRushSession> start(TriviaRushConfig config) async => _session(
    await _post('/tira-local/intentos', {
      'areas': config.areas.map((area) => area.backendValue).toList(),
    }),
  );

  @override
  Future<TugLocalRound> beginRound(String attemptId, String questionId) async =>
      _round(
        await _post('${_path(attemptId)}/ronda', {'preguntaId': questionId}),
      );

  @override
  Future<TugLocalRound> setPaused({
    required String attemptId,
    required String questionId,
    required int version,
    required bool paused,
  }) async => _round(
    await _post('${_path(attemptId)}/pausa', {
      'preguntaId': questionId,
      'version': version,
      'pausada': paused,
    }),
  );

  @override
  Future<TriviaRushSession> expireRound(
    String attemptId,
    String questionId,
  ) async {
    final body = await _post('${_path(attemptId)}/sin-respuesta', {
      'preguntaId': questionId,
      'idempotencyKey': _timeoutKeys.putIfAbsent((
        attemptId,
        questionId,
      ), createTriviaIdempotencyKey),
    });
    if ((body['sinRespuesta'] as Map?)?['preguntaId'] != questionId) {
      throw const ApiError(
        code: 'tug_local_expired',
        message: 'El duelo local caducó. Inicia otra partida.',
      );
    }
    return _session(body);
  }

  @override
  Future<TriviaRushAnswerEvaluation> answer({
    required String attemptId,
    required String questionId,
    required String answerId,
    required int responseTimeSeconds,
  }) async {
    final operation = _answerOperations.putIfAbsent((
      attemptId,
      questionId,
    ), () => (answerId, createTriviaIdempotencyKey()));
    if (operation.$1 != answerId) {
      throw const ApiError(
        code: 'tug_answer_pending',
        message: 'Confirma la respuesta pendiente antes de continuar.',
      );
    }
    final body = await _post('${_path(attemptId)}/respuestas', {
      'preguntaId': questionId,
      'respuestaId': answerId,
      'idempotencyKey': operation.$2,
    });
    final evaluation = body['evaluacion'] as Map;
    return TriviaRushAnswerEvaluation(
      questionId: evaluation['preguntaId'] as String,
      isCorrect: evaluation['esCorrecta'] == true,
      correctAnswerId: evaluation['respuestaCorrectaId'] as String?,
      explanation: evaluation['explicacion'] as String?,
      serverState: TriviaRushServerState.fromJson(body),
    );
  }

  @override
  Future<void> abandon(String attemptId) async {
    await _post('${_path(attemptId)}/abandonar');
  }

  @override
  Future<TriviaRushBoosterActivation> activateBooster({
    required String attemptId,
    required String questionId,
    required TriviaRushBooster booster,
  }) async => throw const ApiError(
    code: 'tug_local_booster_unavailable',
    message: 'El duelo local no utiliza potenciadores.',
  );
}
