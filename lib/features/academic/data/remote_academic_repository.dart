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

  @override
  Future<DiagnosticSummary> finishDiagnostic(
    List<DiagnosticAnswer> answers,
  ) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/diagnostico-inicial/finalizar',
        data: {'respuestas': answers.map((answer) => answer.toJson()).toList()},
      );
      return DiagnosticSummary.fromJson(_body(response.data));
    } on DioException catch (error) {
      throw ApiError.fromDioException(error);
    }
  }

  @override
  Future<List<WeakTopic>> loadWeakTopics() async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '/cuaderno-errores',
      );
      final errors = _body(response.data)['errores'];
      if (errors is! List) return const [];

      final grouped = <String, WeakTopic>{};
      for (final item in errors) {
        if (item is! Map) continue;
        final json = Map<String, dynamic>.from(item);
        final areaValue = json['area'];
        final theme = json['tema'];
        final subtopic = json['subtema'];
        if (areaValue is! String || theme is! String || subtopic is! String) {
          continue;
        }
        final area = AcademicArea.fromBackend(areaValue);
        final key = '$areaValue\u0000$theme\u0000$subtopic';
        final previous = grouped[key];
        grouped[key] = WeakTopic(
          area: area,
          theme: theme,
          subtopic: subtopic,
          failedQuestions: (previous?.failedQuestions ?? 0) + 1,
        );
      }

      final topics = grouped.values.toList()
        ..sort((a, b) {
          final byFailures = b.failedQuestions.compareTo(a.failedQuestions);
          if (byFailures != 0) return byFailures;
          final byArea = a.area.label.compareTo(b.area.label);
          if (byArea != 0) return byArea;
          return a.subtopic.compareTo(b.subtopic);
        });
      return topics;
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
