import 'package:dio/dio.dart';

import '../../../core/network/api_error.dart';
import '../../academic/domain/academic_models.dart';
import '../../practice/domain/practice_models.dart';
import '../domain/historical_simulation_models.dart';
import '../domain/historical_simulation_repository.dart';

class RemoteHistoricalSimulationRepository
    implements HistoricalSimulationRepository {
  RemoteHistoricalSimulationRepository(this._dio);

  final Dio _dio;

  @override
  Future<HistoricalSimulationCatalog> loadCatalog() async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '/simulacros/historicos',
      );
      return HistoricalSimulationCatalog.fromJson(_body(response.data));
    } on DioException catch (error) {
      throw ApiError.fromDioException(error);
    }
  }

  @override
  Future<PracticeSession> startEdition({
    required String editionId,
    required OfficialSimulationBlock block,
  }) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '/simulacros/historicos/${Uri.encodeComponent(editionId)}/iniciar',
        queryParameters: {'jornada': block.slug.toUpperCase()},
      );
      final session = PracticeSession.fromHistoricalJson(
        _body(response.data),
        editionId: editionId,
        block: block,
      );
      final areas = session.questions.map((question) => question.area).toSet();
      if (session.questions.length != OfficialSimulationBlock.questionCount ||
          !areas.containsAll(AcademicArea.values)) {
        throw const ApiError(
          code: 'historical_session_incomplete',
          message:
              'La edición no entregó las 75 preguntas esperadas en las cinco áreas.',
        );
      }
      return session;
    } on DioException catch (error) {
      throw ApiError.fromDioException(error);
    }
  }

  @override
  Future<PracticeResult> gradeEdition({
    required String editionId,
    required OfficialSimulationBlock block,
    required String attemptId,
    required List<PracticeAnswer> answers,
  }) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/simulacros/historicos/${Uri.encodeComponent(editionId)}/calificar',
        data: {
          'intentoId': attemptId,
          'jornada': block.slug.toUpperCase(),
          'respuestas': answers.map((answer) => answer.toJson()).toList(),
        },
      );
      return PracticeResult.fromJson(_body(response.data));
    } on DioException catch (error) {
      throw ApiError.fromDioException(error);
    }
  }

  Map<String, dynamic> _body(Map<String, dynamic>? body) {
    if (body == null) return const {};
    final data = body['data'];
    return data is Map<String, dynamic> ? data : body;
  }
}
