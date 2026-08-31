import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:saber_plus/core/network/api_error.dart';
import 'package:saber_plus/features/academic/domain/academic_models.dart';
import 'package:saber_plus/features/games/trivia_rush/data/remote_trivia_rush_repository.dart';
import 'package:saber_plus/features/games/trivia_rush/domain/trivia_rush_models.dart';

void main() {
  test('crea la ronda y acepta únicamente el estado autoritativo', () async {
    late RequestOptions captured;
    final repository = RemoteTriviaRushRepository(
      _dio((options) {
        captured = options;
        return _activeResponse;
      }),
    );

    final session = await repository.start(
      const TriviaRushConfig(
        areas: [AcademicArea.mathematics, AcademicArea.criticalReading],
        duration: TriviaRushDuration.standard,
      ),
    );

    expect(captured.path, '/trivia-rush/intentos');
    expect(captured.data, {
      'areas': ['MATEMATICAS', 'LECTURA_CRITICA'],
      'duracionSegundos': 90,
    });
    expect(session.isAuthoritative, isTrue);
    expect(session.questions.single.statement, '¿Cuánto es dos más dos?');
    expect(
      session.questions.single.toJson().toString(),
      isNot(contains('esCorrecta')),
    );
    expect(session.serverState?.score.points, 200);
    expect(
      session.serverState?.secondsRemainingAt(DateTime.now()),
      inInclusiveRange(89, 90),
    );
  });

  test('responde con UUID sin enviar tiempo, puntaje ni combo', () async {
    late RequestOptions captured;
    final repository = RemoteTriviaRushRepository(
      _dio((options) {
        captured = options;
        return {
          ..._activeResponse,
          'evaluacion': {
            'preguntaId': 'question-1',
            'esCorrecta': false,
            'esFinal': false,
            'puedeReintentar': true,
            'puntosOtorgados': 0,
            'comboResultante': 2,
            'tiempoRespuestaMs': 3450,
            'respuestaCorrectaId': null,
            'explicacion': null,
          },
        };
      }),
    );

    final evaluation = await repository.answer(
      attemptId: '00000000-0000-4000-8000-000000000001',
      questionId: 'question-1',
      answerId: 'answer-b',
      responseTimeSeconds: 9999,
    );
    final data = Map<String, dynamic>.from(captured.data as Map);

    expect(captured.path, contains('/respuestas'));
    expect(data.keys, {'preguntaId', 'respuestaId', 'idempotencyKey'});
    expect(
      data['idempotencyKey'],
      matches(
        RegExp(
          r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$',
        ),
      ),
    );
    expect(evaluation.canRetry, isTrue);
    expect(evaluation.correctAnswerId, isNull);
    expect(evaluation.serverState?.score.combo, 2);
  });

  test('no fabrica una concesión de potenciador desde el teléfono', () async {
    var requests = 0;
    final repository = RemoteTriviaRushRepository(
      _dio((_) {
        requests++;
        return _activeResponse;
      }),
    );

    await expectLater(
      repository.activateBooster(
        attemptId: 'attempt-1',
        questionId: 'question-1',
        booster: TriviaRushBooster.extraTime,
      ),
      throwsA(
        isA<ApiError>().having(
          (error) => error.code,
          'code',
          'rewarded_ads_pending',
        ),
      ),
    );
    expect(requests, 0);
  });

  test('consume la concesión cargada y mapea el potenciador', () async {
    late RequestOptions captured;
    final repository = RemoteTriviaRushRepository(
      _dio((options) {
        captured = options;
        return {
          ..._activeResponse,
          'activacion': {
            'potenciador': 'CINCUENTA_CINCUENTA',
            'preguntaId': 'question-1',
            'opcionesEliminadas': ['answer-b', 'answer-c'],
          },
        };
      }),
      rewardGrantLoader: (_) async => '00000000-0000-4000-8000-000000000010',
    );

    final activation = await repository.activateBooster(
      attemptId: '00000000-0000-4000-8000-000000000001',
      questionId: 'question-1',
      booster: TriviaRushBooster.fiftyFifty,
    );
    final data = Map<String, dynamic>.from(captured.data as Map);

    expect(data['potenciador'], 'CINCUENTA_CINCUENTA');
    expect(data['concesionId'], '00000000-0000-4000-8000-000000000010');
    expect(activation.eliminatedAnswerIds, {'answer-b', 'answer-c'});
  });

  test('interpreta el diagnóstico confirmado al finalizar', () async {
    final repository = RemoteTriviaRushRepository(
      _dio((_) => _finishedResponse),
    );

    final session = await repository.finish(
      '00000000-0000-4000-8000-000000000001',
    );

    expect(session.serverState?.status, TriviaRushAttemptStatus.expired);
    expect(session.serverState?.currentQuestion, isNull);
    expect(session.serverState?.weaknesses.single.subtopic, 'Regla de tres');
    expect(session.serverState?.weaknesses.single.errors, 2);
  });
}

Dio _dio(Map<String, dynamic> Function(RequestOptions options) response) {
  final dio = Dio(BaseOptions(baseUrl: 'http://localhost:3000'));
  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) => handler.resolve(
        Response<Map<String, dynamic>>(
          requestOptions: options,
          statusCode: 200,
          data: response(options),
        ),
      ),
    ),
  );
  return dio;
}

final _activeResponse = <String, dynamic>{
  'servidorAhora': '2026-08-31T10:00:00.000Z',
  'intento': {
    'id': '00000000-0000-4000-8000-000000000001',
    'estado': 'ACTIVO',
    'versionReglas': 1,
    'areas': ['MATEMATICAS', 'LECTURA_CRITICA'],
    'duracionBaseSegundos': 90,
    'tiempoExtraSegundos': 0,
    'iniciadoEn': '2026-08-31T10:00:00.000Z',
    'venceEn': '2026-08-31T10:01:30.000Z',
    'finalizadoEn': null,
    'asistido': false,
    'marcador': {
      'puntaje': 200,
      'comboActual': 2,
      'mejorCombo': 2,
      'respuestasCorrectas': 2,
      'respuestasIncorrectas': 0,
      'preguntasSaltadas': 0,
    },
    'progreso': {'indiceActual': 2, 'respondidas': 2, 'totalPreguntas': 30},
    'potenciadoresActivos': {
      'escudoCombo': false,
      'segundaOportunidad': true,
      'opcionesEliminadas': <String>[],
    },
    'pregunta': {
      'id': 'question-1',
      'enunciado': '¿Cuánto es dos más dos?',
      'imagenUrl': null,
      'contexto': null,
      'dificultad': 'BASICO',
      'area': 'MATEMATICAS',
      'tema': 'Aritmética',
      'subtema': 'Suma',
      'subtemaId': 'subtopic-1',
      'opciones': [
        {'id': 'answer-a', 'texto': '4'},
        {'id': 'answer-b', 'texto': '5'},
        {'id': 'answer-c', 'texto': '6'},
        {'id': 'answer-d', 'texto': '7'},
      ],
    },
    'resultado': null,
  },
};

final _finishedResponse = <String, dynamic>{
  'servidorAhora': '2026-08-31T10:01:30.000Z',
  'intento': {
    ...Map<String, dynamic>.from(_activeResponse['intento'] as Map),
    'estado': 'EXPIRADO',
    'finalizadoEn': '2026-08-31T10:01:30.000Z',
    'pregunta': null,
    'resultado': {
      'diagnostico': [
        {
          'area': 'MATEMATICAS',
          'tema': 'Proporciones',
          'subtema': 'Regla de tres',
          'subtemaId': 'rule-three',
          'errores': 2,
        },
      ],
    },
  },
};
