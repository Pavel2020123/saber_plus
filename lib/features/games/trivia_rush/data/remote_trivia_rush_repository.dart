import 'dart:math';

import 'package:dio/dio.dart';

import '../../../../core/network/api_error.dart';
import '../domain/trivia_rush_models.dart';
import '../domain/trivia_rush_repository.dart';

typedef TriviaRewardGrantLoader =
    Future<String> Function(TriviaRushBooster booster);

class RemoteTriviaRushRepository
    implements TriviaRushRepository, AuthoritativeTriviaRushRepository {
  RemoteTriviaRushRepository(this._dio, {this.rewardGrantLoader});

  final Dio _dio;
  final TriviaRewardGrantLoader? rewardGrantLoader;

  @override
  Future<TriviaRushSession> start(TriviaRushConfig config) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/trivia-rush/intentos',
        data: {
          'areas': config.areas.map((area) => area.backendValue).toList(),
          'duracionSegundos': config.duration.seconds,
        },
      );
      return _session(_body(response.data));
    } on DioException catch (error) {
      throw ApiError.fromDioException(error);
    }
  }

  @override
  Future<TriviaRushSession> synchronize(String attemptId) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '/trivia-rush/intentos/${Uri.encodeComponent(attemptId)}',
      );
      return _session(_body(response.data));
    } on DioException catch (error) {
      throw ApiError.fromDioException(error);
    }
  }

  @override
  Future<TriviaRushAnswerEvaluation> answer({
    required String attemptId,
    required String questionId,
    required String answerId,
    required int responseTimeSeconds,
  }) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/trivia-rush/intentos/${Uri.encodeComponent(attemptId)}/respuestas',
        data: {
          'preguntaId': questionId,
          'respuestaId': answerId,
          'idempotencyKey': createTriviaIdempotencyKey(),
        },
      );
      final body = _body(response.data);
      final evaluation = _map(body['evaluacion']);
      return TriviaRushAnswerEvaluation(
        questionId: evaluation['preguntaId'] as String,
        isCorrect: evaluation['esCorrecta'] == true,
        correctAnswerId: evaluation['respuestaCorrectaId'] as String?,
        explanation: evaluation['explicacion'] as String?,
        isFinal: evaluation['esFinal'] == true,
        canRetry: evaluation['puedeReintentar'] == true,
        serverState: TriviaRushServerState.fromJson(body),
      );
    } on DioException catch (error) {
      throw ApiError.fromDioException(error);
    }
  }

  @override
  Future<TriviaRushBoosterActivation> activateBooster({
    required String attemptId,
    required String questionId,
    required TriviaRushBooster booster,
  }) async {
    final loader = rewardGrantLoader;
    if (loader == null) {
      throw const ApiError(
        code: 'rewarded_ads_pending',
        message:
            'Los potenciadores con anuncios se habilitarán cuando terminemos la configuración de AdMob.',
      );
    }
    final grantId = await loader(booster);
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/trivia-rush/intentos/${Uri.encodeComponent(attemptId)}/potenciadores',
        data: {
          'preguntaId': questionId,
          'potenciador': booster.backendValue,
          'concesionId': grantId,
          'idempotencyKey': createTriviaIdempotencyKey(),
        },
      );
      final body = _body(response.data);
      final activation = _map(body['activacion']);
      return TriviaRushBoosterActivation(
        eliminatedAnswerIds:
            (activation['opcionesEliminadas'] as List<dynamic>? ?? const [])
                .whereType<String>()
                .toSet(),
        serverState: TriviaRushServerState.fromJson(body),
      );
    } on DioException catch (error) {
      throw ApiError.fromDioException(error);
    }
  }

  @override
  Future<TriviaRushSession> finish(String attemptId) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/trivia-rush/intentos/${Uri.encodeComponent(attemptId)}/finalizar',
      );
      return _session(_body(response.data));
    } on DioException catch (error) {
      throw ApiError.fromDioException(error);
    }
  }

  @override
  Future<void> abandon(String attemptId) async {
    try {
      await _dio.post<Map<String, dynamic>>(
        '/trivia-rush/intentos/${Uri.encodeComponent(attemptId)}/abandonar',
      );
    } on DioException catch (error) {
      throw ApiError.fromDioException(error);
    }
  }

  TriviaRushSession _session(Map<String, dynamic> body) {
    final state = TriviaRushServerState.fromJson(body);
    final question = state.currentQuestion;
    return TriviaRushSession(
      attemptId: state.attemptId,
      questions: question == null ? const [] : [question],
      serverState: state,
    );
  }
}

extension TriviaRushBoosterBackend on TriviaRushBooster {
  String get backendValue => switch (this) {
    TriviaRushBooster.extraTime => 'TIEMPO_EXTRA',
    TriviaRushBooster.fiftyFifty => 'CINCUENTA_CINCUENTA',
    TriviaRushBooster.comboShield => 'ESCUDO_COMBO',
    TriviaRushBooster.skip => 'SALTAR',
    TriviaRushBooster.secondChance => 'SEGUNDA_OPORTUNIDAD',
  };
}

String createTriviaIdempotencyKey([Random? source]) {
  final random = source ?? Random.secure();
  final bytes = List<int>.generate(16, (_) => random.nextInt(256));
  bytes[6] = (bytes[6] & 0x0f) | 0x40;
  bytes[8] = (bytes[8] & 0x3f) | 0x80;
  final hex = bytes
      .map((byte) => byte.toRadixString(16).padLeft(2, '0'))
      .join();
  return '${hex.substring(0, 8)}-${hex.substring(8, 12)}-'
      '${hex.substring(12, 16)}-${hex.substring(16, 20)}-'
      '${hex.substring(20)}';
}

Map<String, dynamic> _body(Map<String, dynamic>? value) {
  if (value == null) return const {};
  final data = value['data'];
  return data is Map ? Map<String, dynamic>.from(data) : value;
}

Map<String, dynamic> _map(Object? value) =>
    value is Map ? Map<String, dynamic>.from(value) : const {};
