import 'package:dio/dio.dart';
import '../../../core/network/api_error.dart';
import '../../institutions/data/teacher_student_evidence_repository.dart';
import '../domain/study_evolution.dart';

abstract interface class StudyEvolutionRepository {
  Future<StudyEvolution> load(
    int days, {
    String? studentId,
    CancelToken? cancelToken,
  });
}

class RemoteStudyEvolutionRepository implements StudyEvolutionRepository {
  const RemoteStudyEvolutionRepository(this.dio);
  final Dio dio;
  @override
  Future<StudyEvolution> load(
    int days, {
    String? studentId,
    CancelToken? cancelToken,
  }) async {
    try {
      final response = await dio.get<Map<String, dynamic>>(
        studentId == null
            ? '/tiempo-estudio/me'
            : '/instituciones/me/estudiantes/${Uri.encodeComponent(studentId)}/evolucion',
        queryParameters: {'dias': days},
        cancelToken: cancelToken,
      );
      return StudyEvolution.fromJson(
        studyMap(response.data),
        days,
        studentId: studentId,
      );
    } on DioException catch (error) {
      if (error.response?.statusCode == 404) {
        throw const ApiError(
          code: 'study_time_unavailable',
          message:
              'El informe no está disponible. Revisa tu acceso y que el backend tenga desplegada la etapa P4-A.',
        );
      }
      throw ApiError.fromDioException(error);
    } on FormatException {
      throw const ApiError(
        code: 'invalid_study_time',
        message:
            'No pudimos validar el informe de tiempo. Actualiza para intentarlo nuevamente.',
      );
    } on TypeError {
      throw const ApiError(
        code: 'invalid_study_time',
        message: 'El servidor devolvió un informe incompatible.',
      );
    }
  }
}

class DemoStudyEvolutionRepository implements StudyEvolutionRepository {
  @override
  Future<StudyEvolution> load(
    int days, {
    String? studentId,
    CancelToken? cancelToken,
  }) async {
    final student = studentId == null
        ? null
        : await DemoTeacherStudentEvidenceRepository().load(
            studentId,
            cancelToken: cancelToken,
          );
    final json = demoStudyEvolutionJson(days);
    return StudyEvolution.fromJson(
      student == null
          ? json
          : {
              'version': 1,
              'estudiante': {
                'id': studentId,
                'nombre': student.name,
                'grupos': <Object>[],
              },
              'evolucion': json,
            },
      days,
      studentId: studentId,
      demo: true,
    );
  }
}

// Datos de ejemplo explícitos: no se mezclan con contadores ni cuentas reales.
Map<String, dynamic> demoStudyEvolutionJson(int days, {DateTime? now}) {
  final until = (now ?? DateTime.now()).toUtc();
  final since = DateTime.parse(
    '${colombianStudyDay(until)}T00:00:00-05:00',
  ).subtract(Duration(days: days - 1));
  final total = {for (final key in studyMetricKeys) key: 0};
  final rows = <Map<String, dynamic>>[];
  for (var i = 0; i < days; i++) {
    final active = i >= days - 4 && i.isEven;
    final metrics = {for (final key in studyMetricKeys) key: 0};
    if (active) {
      metrics.addAll({
        'segundosEvaluaciones': 2400,
        'segundosPomodoroDeclarados': 1500,
        'respuestas': 8,
        'aciertos': 6,
        'errores': 2,
        'sesionesEvaluacion': 1,
        'bloquesPomodoro': 1,
      });
    }
    for (final key in studyMetricKeys) {
      total[key] = total[key]! + metrics[key]!;
    }
    rows.add({
      'fecha': colombianStudyDay(since.add(Duration(days: i))),
      ...metrics,
      'estado': active ? 'CON_REGISTROS' : 'SIN_REGISTROS',
      'porcentajeAciertos': active ? 75.0 : null,
    });
  }
  return {
    'version': 1,
    'politica': studyTimePolicy,
    'desde': since.toUtc().toIso8601String(),
    'hasta': until.toIso8601String(),
    'dias': days,
    'parcial': false,
    'registrosEvaluacionLeidos': total['respuestas'],
    'totales': total,
    'evolucion': rows,
  };
}
