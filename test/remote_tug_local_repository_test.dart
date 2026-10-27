import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:saber_plus/core/network/api_error.dart';
import 'package:saber_plus/features/academic/domain/academic_models.dart';
import 'package:saber_plus/features/games/trivia_rush/domain/trivia_rush_models.dart';
import 'package:saber_plus/features/games/tug_of_war/data/remote_tug_local_repository.dart';

void main() {
  test(
    'solo usa el contrato local y conserva opciones con y sin imagen',
    () async {
      final requests = <RequestOptions>[];
      final repository = RemoteTugLocalRepository(
        _dio((options) {
          requests.add(options);
          return _state();
        }),
      );
      final session = await repository.start(
        const TriviaRushConfig(
          areas: [AcademicArea.mathematics],
          duration: TriviaRushDuration.quick,
        ),
      );
      expect(requests.single.path, '/tira-local/intentos');
      expect(requests.single.data, {
        'areas': ['MATEMATICAS'],
      });
      expect(session.questions.single.options.first.imageUrl, _image);
      expect(session.questions.single.options.last.imageUrl, isNull);
      expect(session.serverState!.baseDurationSeconds, 600);
      final round = await repository.beginRound('attempt', 'question');
      expect(round.version, 1);
      expect(round.remainingAt(DateTime.now()), inInclusiveRange(9900, 10000));
      await repository.setPaused(
        attemptId: 'attempt',
        questionId: 'question',
        version: 1,
        paused: true,
      );
      expect(requests.last.path, '/tira-local/intentos/attempt/pausa');
      expect(requests.last.data, {
        'preguntaId': 'question',
        'version': 1,
        'pausada': true,
      });
      expect(requests.every((r) => r.path.startsWith('/tira-local/')), isTrue);
    },
  );

  test(
    'ACK perdido reenvía la misma respuesta y clave sin aceptar otra selección',
    () async {
      final requests = <RequestOptions>[];
      final repository = RemoteTugLocalRepository(
        _dio((options) {
          requests.add(options);
          if (requests.length == 1) {
            throw DioException(
              requestOptions: options,
              type: DioExceptionType.receiveTimeout,
            );
          }
          return {
            ..._state(),
            'evaluacion': {
              'preguntaId': 'question',
              'esCorrecta': true,
              'respuestaCorrectaId': 'blue',
              'explicacion': 'Azul',
            },
          };
        }),
      );
      Future<TriviaRushAnswerEvaluation> answer(String id) => repository.answer(
        attemptId: 'attempt',
        questionId: 'question',
        answerId: id,
        responseTimeSeconds: 999,
      );
      await expectLater(answer('blue'), throwsA(isA<ApiError>()));
      await expectLater(
        answer('text'),
        throwsA(
          isA<ApiError>().having((e) => e.code, 'code', 'tug_answer_pending'),
        ),
      );
      final confirmed = await answer('blue');
      expect(confirmed.isCorrect, isTrue);
      expect(requests.length, 2);
      expect(requests.first.data, requests.last.data);
      expect((requests.last.data as Map).keys, {
        'preguntaId',
        'respuestaId',
        'idempotencyKey',
      });
      expect((requests.last.data as Map)['idempotencyKey'], matches(_uuid));
    },
  );

  test(
    'timeout y repetición terminal usan una clave estable sin respuesta ni recompensa',
    () async {
      final requests = <RequestOptions>[];
      final repository = RemoteTugLocalRepository(
        _dio((options) {
          requests.add(options);
          if (requests.length == 1) {
            throw DioException(
              requestOptions: options,
              type: DioExceptionType.connectionError,
            );
          }
          return {
            ..._state(terminal: true),
            'sinRespuesta': {'id': 'receipt', 'preguntaId': 'question'},
          };
        }),
      );
      await expectLater(
        repository.expireRound('attempt', 'question'),
        throwsA(isA<ApiError>()),
      );
      final terminal = await repository.expireRound('attempt', 'question');
      expect(terminal.serverState!.isTerminal, isTrue);
      expect(terminal.questions, isEmpty);
      expect(requests.first.data, requests.last.data);
      expect((requests.last.data as Map).keys, {
        'preguntaId',
        'idempotencyKey',
      });
      expect((requests.last.data as Map)['idempotencyKey'], matches(_uuid));
      expect(requests.every((r) => r.path.endsWith('/sin-respuesta')), isTrue);
    },
  );

  test(
    'mantiene errores de autorización, rechaza otro flujo y no pide potenciadores',
    () async {
      var requests = 0;
      final repository = RemoteTugLocalRepository(
        _dio((options) {
          requests++;
          throw DioException(
            requestOptions: options,
            type: DioExceptionType.badResponse,
            response: Response(
              requestOptions: options,
              statusCode: 403,
              data: {'code': '403', 'message': 'No autorizado.'},
            ),
          );
        }),
      );
      await expectLater(
        repository.beginRound('foreign', 'question'),
        throwsA(isA<ApiError>().having((e) => e.code, 'code', '403')),
      );
      await expectLater(
        repository.activateBooster(
          attemptId: 'attempt',
          questionId: 'question',
          booster: TriviaRushBooster.skip,
        ),
        throwsA(isA<ApiError>()),
      );
      expect(requests, 1);
      final wrongFlow = RemoteTugLocalRepository(
        _dio((_) {
          final body = _state();
          (body['intento'] as Map)['modalidad'] = 'TRIVIA_RUSH';
          return body;
        }),
      );
      await expectLater(
        wrongFlow.beginRound('attempt', 'question'),
        throwsFormatException,
      );
      final missingReceipt = RemoteTugLocalRepository(
        _dio((_) => _state(terminal: true)),
      );
      await expectLater(
        missingReceipt.expireRound('attempt', 'question'),
        throwsA(
          isA<ApiError>().having((e) => e.code, 'code', 'tug_local_expired'),
        ),
      );
    },
  );
}

final _uuid = RegExp(
  r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$',
);
const _image = '/recursos/editoriales/11111111-1111-4111-8111-111111111111';

Dio _dio(Map<String, dynamic> Function(RequestOptions) reply) {
  final dio = Dio(BaseOptions(baseUrl: 'http://127.0.0.1:1'));
  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) {
        try {
          handler.resolve(
            Response(
              requestOptions: options,
              statusCode: 201,
              data: reply(options),
            ),
          );
        } on DioException catch (error) {
          handler.reject(error);
        }
      },
    ),
  );
  return dio;
}

Map<String, dynamic> _state({bool terminal = false}) => {
  'servidorAhora': '2026-10-23T10:00:00Z',
  'intento': {
    'id': 'attempt',
    'modalidad': 'TUG_LOCAL',
    'estado': terminal ? 'FINALIZADO' : 'ACTIVO',
    'versionReglas': 1,
    'areas': ['MATEMATICAS'],
    'duracionBaseSegundos': 600,
    'tiempoExtraSegundos': 0,
    'iniciadoEn': '2026-10-23T10:00:00Z',
    'venceEn': '2026-10-23T10:10:00Z',
    'asistido': false,
    'rondaLocal': {'version': 1, 'pausada': false, 'tiempoRestanteMs': 10000},
    'progreso': {'indiceActual': terminal ? 1 : 0, 'totalPreguntas': 1},
    'pregunta': terminal
        ? null
        : {
            'id': 'question',
            'enunciado': 'Figura',
            'dificultad': 'BASICO',
            'area': 'MATEMATICAS',
            'tema': 'Figuras',
            'subtema': 'Opciones',
            'subtemaId': 'figures',
            'opciones': [
              {'id': 'blue', 'texto': 'Azul', 'imagenUrl': _image},
              {'id': 'text', 'texto': 'Texto antiguo'},
            ],
          },
  },
};
