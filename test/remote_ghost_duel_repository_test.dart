import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:saber_plus/features/academic/domain/academic_models.dart';
import 'package:saber_plus/features/games/ghost_duel/data/remote_ghost_duel_repository.dart';
import 'package:saber_plus/features/games/ghost_duel/domain/ghost_duel_models.dart';

void main() {
  final key = GhostDuelKey(
    areas: const [AcademicArea.mathematics, AcademicArea.english],
    seconds: 60,
  );

  test(
    'consulta y reconstruye el fantasma confirmado por el servidor',
    () async {
      late RequestOptions captured;
      final repository = RemoteGhostDuelRepository(
        _dio((options, _) {
          captured = options;
          return _ghostResponse(attemptId: 'attempt-best', score: 700);
        }),
      );

      final ghost = await repository.loadBest(userId: 'student-1', key: key);

      expect(captured.method, 'GET');
      expect(captured.path, '/trivia-rush/fantasma');
      expect(captured.queryParameters, {
        'areas': 'INGLES,MATEMATICAS',
        'duracionSegundos': 60,
      });
      expect(ghost?.sourceAttemptId, 'attempt-best');
      expect(ghost?.score, 700);
      expect(ghost?.scoreAt(12), 300);
      expect(ghost?.scoreAt(60), 700);
    },
  );

  test(
    'reconoce el primer récord sin enviar puntajes desde el teléfono',
    () async {
      final requests = <RequestOptions>[];
      final repository = RemoteGhostDuelRepository(
        _dio((options, index) {
          requests.add(options);
          return index == 0
              ? <String, dynamic>{'fantasma': null}
              : _ghostResponse(attemptId: 'attempt-current', score: 500);
        }),
      );
      await repository.loadBest(userId: 'student-1', key: key);

      final result = await repository.saveIfBetter(
        _run(key: key, attemptId: 'attempt-current', score: 999999),
      );

      expect(result.outcome, GhostDuelOutcome.firstRecord);
      expect(result.bestRun.score, 500);
      expect(requests, hasLength(2));
      expect(requests.every((request) => request.method == 'GET'), isTrue);
      expect(requests.every((request) => request.data == null), isTrue);
    },
  );

  test(
    'distingue un nuevo récord de una ronda que no venció al fantasma',
    () async {
      final newRecordRepository = RemoteGhostDuelRepository(
        _dio(
          (_, index) => index == 0
              ? _ghostResponse(attemptId: 'attempt-old', score: 400)
              : _ghostResponse(attemptId: 'attempt-current', score: 600),
        ),
      );
      await newRecordRepository.loadBest(userId: 'student-1', key: key);
      final newRecord = await newRecordRepository.saveIfBetter(
        _run(key: key, attemptId: 'attempt-current', score: 600),
      );

      final keptRepository = RemoteGhostDuelRepository(
        _dio((_, _) => _ghostResponse(attemptId: 'attempt-old', score: 800)),
      );
      await keptRepository.loadBest(userId: 'student-1', key: key);
      final kept = await keptRepository.saveIfBetter(
        _run(key: key, attemptId: 'attempt-current', score: 600),
      );

      expect(newRecord.outcome, GhostDuelOutcome.newRecord);
      expect(kept.outcome, GhostDuelOutcome.keptRecord);
      expect(kept.bestRun.score, 800);
    },
  );
}

GhostRun _run({
  required GhostDuelKey key,
  required String attemptId,
  required int score,
}) => GhostRun(
  userId: 'student-1',
  key: key,
  score: score,
  bestCombo: 4,
  correctAnswers: 4,
  completedAt: DateTime(2026, 8, 31),
  checkpoints: [GhostCheckpoint(elapsedSeconds: 60, score: score)],
  sourceAttemptId: attemptId,
);

Map<String, dynamic> _ghostResponse({
  required String attemptId,
  required int score,
}) => {
  'fantasma': {
    'intentoId': attemptId,
    'versionReglas': 1,
    'areas': ['INGLES', 'MATEMATICAS'],
    'duracionSegundos': 60,
    'puntaje': score,
    'mejorCombo': 4,
    'respuestasCorrectas': 4,
    'completadoEn': '2026-08-31T12:00:00.000Z',
    'checkpoints': [
      {'segundosTranscurridos': 5, 'puntaje': 100},
      {'segundosTranscurridos': 12, 'puntaje': 300},
      {'segundosTranscurridos': 60, 'puntaje': score},
    ],
  },
};

Dio _dio(
  Map<String, dynamic> Function(RequestOptions options, int index) response,
) {
  var index = 0;
  final dio = Dio(BaseOptions(baseUrl: 'http://localhost:3000'));
  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) => handler.resolve(
        Response<Map<String, dynamic>>(
          requestOptions: options,
          statusCode: 200,
          data: response(options, index++),
        ),
      ),
    ),
  );
  return dio;
}
