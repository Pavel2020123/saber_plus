import 'package:dio/dio.dart';
import '../../../core/network/api_error.dart';
import '../../learning_evidence/data/learning_evidence_repository.dart';
import '../domain/teacher_student_evidence.dart';
import 'demo_teacher_detailed_analytics_repository.dart';

abstract interface class TeacherStudentEvidenceRepository {
  Future<TeacherStudentEvidence> load(
    String studentId, {
    CancelToken? cancelToken,
  });
}

class RemoteTeacherStudentEvidenceRepository
    implements TeacherStudentEvidenceRepository {
  const RemoteTeacherStudentEvidenceRepository(this.dio);
  final Dio dio;

  @override
  Future<TeacherStudentEvidence> load(
    String studentId, {
    CancelToken? cancelToken,
  }) async {
    try {
      final response = await dio.get<Map<String, dynamic>>(
        '/instituciones/me/estudiantes/${Uri.encodeComponent(studentId)}/evidencia',
        cancelToken: cancelToken,
      );
      return TeacherStudentEvidence.fromJson(
        response.data ?? const {},
        studentId,
      );
    } on DioException catch (error) {
      if (error.response?.statusCode == 404) {
        throw const ApiError(
          code: 'student_evidence_unavailable',
          message:
              'La ficha no está disponible. Revisa tu acceso al estudiante y que el servidor tenga esta función.',
        );
      }
      throw ApiError.fromDioException(error);
    } on FormatException {
      throw const ApiError(
        code: 'invalid_student_evidence',
        message:
            'No pudimos validar la ficha. No se mostrarán conclusiones con estos datos.',
      );
    }
  }
}

class DemoTeacherStudentEvidenceRepository
    implements TeacherStudentEvidenceRepository {
  @override
  Future<TeacherStudentEvidence> load(
    String studentId, {
    CancelToken? cancelToken,
  }) async {
    final dashboard = await DemoTeacherDetailedAnalyticsRepository().load();
    final matches = dashboard.analytics.students.where(
      (student) => student.id == studentId,
    );
    if (matches.isEmpty) {
      throw const ApiError(
        code: 'demo_student_missing',
        message: 'Estudiante de demostración no disponible.',
      );
    }
    final student = matches.first;
    return TeacherStudentEvidence(
      studentId: student.id,
      name: student.name,
      groups: student.groups,
      evidence: demoLearningEvidence(),
    );
  }
}
