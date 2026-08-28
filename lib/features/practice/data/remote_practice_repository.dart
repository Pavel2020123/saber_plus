import 'package:dio/dio.dart';

import '../../../core/network/api_error.dart';
import '../../academic/domain/academic_models.dart';
import '../domain/practice_models.dart';
import '../domain/practice_repository.dart';

class RemotePracticeRepository implements PracticeRepository {
  RemotePracticeRepository(this._dio);

  final Dio _dio;

  @override
  Future<PracticeSession> startSubtopicPractice({
    required AcademicArea area,
    required String subtopicId,
  }) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '/simulacros/preguntas/${Uri.encodeComponent(subtopicId)}',
      );
      final session = PracticeSession.fromJson(
        _body(response.data),
        area: area,
        subtopicId: subtopicId,
      );
      if (session.questions.isEmpty) {
        throw const ApiError(
          code: 'empty_practice',
          message: 'Este subtema todavía no tiene preguntas disponibles.',
        );
      }
      if (session.questions.any((question) => question.area != area)) {
        throw const ApiError(
          code: 'practice_area_mismatch',
          message: 'Las preguntas recibidas no corresponden al área elegida.',
        );
      }
      return session;
    } on DioException catch (error) {
      throw ApiError.fromDioException(error);
    }
  }

  @override
  Future<PracticeResult> gradePractice({
    required String attemptId,
    required AcademicArea area,
    required List<PracticeAnswer> answers,
  }) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/simulacros/calificar',
        data: {
          'intentoId': attemptId,
          'area': area.backendValue,
          'origen': 'PRACTICA',
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
