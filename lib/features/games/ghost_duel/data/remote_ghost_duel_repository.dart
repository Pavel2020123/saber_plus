import 'package:dio/dio.dart';

import '../../../../core/network/api_error.dart';
import '../../../academic/domain/academic_models.dart';
import '../domain/ghost_duel_models.dart';
import '../domain/ghost_duel_repository.dart';

class RemoteGhostDuelRepository implements GhostDuelRepository {
  RemoteGhostDuelRepository(this._dio);

  final Dio _dio;
  final Map<String, GhostRun?> _previousByKey = {};

  @override
  Future<GhostRun?> loadBest({
    required String userId,
    required GhostDuelKey key,
  }) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '/trivia-rush/fantasma',
        queryParameters: {
          'areas': key.areas.map((area) => area.backendValue).join(','),
          'duracionSegundos': key.seconds,
        },
      );
      final body = _body(response.data);
      final rawGhost = body['fantasma'];
      if (rawGhost == null) {
        _previousByKey[key.storageKey] = null;
        return null;
      }
      if (rawGhost is! Map) {
        throw const ApiError(
          code: 'invalid_ghost_response',
          message: 'El servidor devolvió un récord fantasma no compatible.',
        );
      }
      final ghost = Map<String, dynamic>.from(rawGhost);
      final completedAt = DateTime.tryParse(
        ghost['completadoEn'] as String? ?? '',
      );
      final attemptId = ghost['intentoId'] as String?;
      if (completedAt == null || attemptId == null || attemptId.isEmpty) {
        throw const ApiError(
          code: 'invalid_ghost_response',
          message: 'El récord fantasma recibido está incompleto.',
        );
      }
      final parsedKey = GhostDuelKey(
        areas: (ghost['areas'] as List<dynamic>? ?? const [])
            .whereType<String>()
            .map(AcademicArea.fromBackend),
        seconds: (ghost['duracionSegundos'] as num?)?.toInt() ?? 0,
      );
      if (parsedKey.storageKey != key.storageKey) {
        throw const ApiError(
          code: 'invalid_ghost_response',
          message: 'El servidor devolvió un fantasma de otra configuración.',
        );
      }
      final run = GhostRun(
        userId: userId,
        key: parsedKey,
        score: (ghost['puntaje'] as num?)?.toInt() ?? 0,
        bestCombo: (ghost['mejorCombo'] as num?)?.toInt() ?? 0,
        correctAnswers: (ghost['respuestasCorrectas'] as num?)?.toInt() ?? 0,
        completedAt: completedAt.toLocal(),
        checkpoints: (ghost['checkpoints'] as List<dynamic>? ?? const [])
            .whereType<Map>()
            .map(
              (checkpoint) => GhostCheckpoint(
                elapsedSeconds:
                    (checkpoint['segundosTranscurridos'] as num?)?.toInt() ?? 0,
                score: (checkpoint['puntaje'] as num?)?.toInt() ?? 0,
              ),
            ),
        sourceAttemptId: attemptId,
      );
      _previousByKey[key.storageKey] = run;
      return run;
    } on DioException catch (error) {
      throw ApiError.fromDioException(error);
    }
  }

  @override
  Future<GhostSaveResult> saveIfBetter(GhostRun run) async {
    final attemptId = run.sourceAttemptId;
    if (attemptId == null || attemptId.isEmpty) {
      throw const ApiError(
        code: 'ghost_attempt_required',
        message: 'No se pudo confirmar el intento que generó el fantasma.',
      );
    }
    final previous = _previousByKey[run.key.storageKey];
    final best = await loadBest(userId: run.userId, key: run.key);
    if (best == null) {
      throw const ApiError(
        code: 'ghost_not_confirmed',
        message: 'El servidor todavía no confirmó el récord fantasma.',
      );
    }
    if (best.sourceAttemptId != attemptId) {
      return GhostSaveResult(
        outcome: GhostDuelOutcome.keptRecord,
        bestRun: best,
      );
    }
    return GhostSaveResult(
      outcome: previous == null
          ? GhostDuelOutcome.firstRecord
          : previous.sourceAttemptId == attemptId
          ? GhostDuelOutcome.keptRecord
          : GhostDuelOutcome.newRecord,
      bestRun: best,
    );
  }
}

Map<String, dynamic> _body(Map<String, dynamic>? value) {
  if (value == null) return const {};
  final data = value['data'];
  return data is Map ? Map<String, dynamic>.from(data) : value;
}
