import 'package:dio/dio.dart';

import '../../../core/network/api_error.dart';
import '../../academic/domain/academic_models.dart';
import '../../practice/domain/practice_history_models.dart';
import '../../study/domain/study_models.dart';
import '../domain/progress_models.dart';
import '../domain/progress_repository.dart';

class RemoteProgressRepository implements ProgressRepository {
  RemoteProgressRepository(this._dio);

  final Dio _dio;

  @override
  Future<ProgressDashboard> loadDashboard() async {
    try {
      final responses = await Future.wait([
        _dio.get<Map<String, dynamic>>('/simulacros/progreso'),
        _answerSummary(),
        for (final area in AcademicArea.values) _answerSummary(area: area),
      ]);
      final studyResponse = responses.first as Response<Map<String, dynamic>>;
      final summaries = responses.skip(1).cast<AnswerHistorySummary>().toList();
      return ProgressDashboard(
        study: StudyProgress.fromJson(_body(studyResponse.data)),
        answers: summaries.first,
        byArea: {
          for (var index = 0; index < AcademicArea.values.length; index++)
            AcademicArea.values[index]: summaries[index + 1],
        },
      );
    } on DioException catch (error) {
      throw ApiError.fromDioException(error);
    }
  }

  Future<AnswerHistorySummary> _answerSummary({AcademicArea? area}) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/simulacros/historial-respuestas',
      queryParameters: {
        if (area != null) 'area': area.backendValue,
        'limite': 1,
      },
    );
    final body = _body(response.data);
    return AnswerHistorySummary.fromJson(
      Map<String, dynamic>.from(body['resumen'] as Map? ?? const {}),
    );
  }

  @override
  Future<ErrorNotebook> loadNotebook(NotebookFilter filter) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '/cuaderno-errores',
        queryParameters: {
          if (filter.area case final area?) 'area': area.backendValue,
          if (filter.status case final status?) 'estado': status.backendValue,
        },
      );
      return ErrorNotebook.fromJson(_body(response.data));
    } on DioException catch (error) {
      throw ApiError.fromDioException(error);
    }
  }

  @override
  Future<void> updateNotebookEntry({
    required String questionId,
    required String note,
    required NotebookStatus status,
  }) async {
    try {
      await _dio.patch<Map<String, dynamic>>(
        '/cuaderno-errores/${Uri.encodeComponent(questionId)}',
        data: {'nota': note.trim(), 'estado': status.backendValue},
      );
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
