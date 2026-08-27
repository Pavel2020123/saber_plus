import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/api_error.dart';
import '../domain/academic_models.dart';
import '../domain/academic_repository.dart';

class RemoteAcademicRepository implements AcademicRepository {
  RemoteAcademicRepository(this._dio);

  final Dio _dio;

  @override
  Future<AcademicHomeData> loadHome() async {
    try {
      final responses = await Future.wait([
        _dio.get<Map<String, dynamic>>('/calendario-icfes/activo'),
        _dio.get<Map<String, dynamic>>('/diagnostico-inicial'),
        _dio.get<Map<String, dynamic>>('/plan-estudio/semanal'),
      ]);
      final calendarBody = _body(responses[0].data);
      final diagnosticBody = _body(responses[1].data);
      final planBody = _body(responses[2].data);
      final calendar = calendarBody['calendario'];

      return AcademicHomeData(
        activeExam: calendar is Map
            ? ActiveExam.fromJson(Map<String, dynamic>.from(calendar))
            : null,
        diagnostic: DiagnosticSummary.fromJson(diagnosticBody),
        plan: StudyPlanSummary.fromJson(planBody),
      );
    } on DioException catch (error) {
      throw ApiError.fromDioException(error);
    }
  }

  @override
  Future<DiagnosticSummary> startDiagnostic() async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/diagnostico-inicial/iniciar',
      );
      return DiagnosticSummary.fromJson(_body(response.data));
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

final academicRepositoryProvider = Provider<AcademicRepository>(
  (ref) => RemoteAcademicRepository(ref.watch(dioProvider)),
);
