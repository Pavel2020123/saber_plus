import 'package:dio/dio.dart';
import '../../../core/network/api_error.dart';
import '../../academic/domain/academic_models.dart';
import '../domain/learning_evidence.dart';

class LearningEvidenceRepository {
  const LearningEvidenceRepository(this.dio);
  final Dio dio;

  Future<LearningEvidence> load({CancelToken? cancelToken}) async {
    try {
      final response = await dio.get<Map<String, dynamic>>(
        '/diagnostico-evidencia',
        cancelToken: cancelToken,
      );
      return LearningEvidence.fromJson(response.data ?? const {});
    } on DioException catch (error) {
      if (error.response?.statusCode == 404) {
        throw const ApiError(
          code: 'evidence_not_deployed',
          message:
              'El análisis por temas todavía no está disponible en este servidor.',
        );
      }
      throw ApiError.fromDioException(error);
    } on FormatException {
      throw const ApiError(
        code: 'invalid_evidence',
        message:
            'No pudimos validar el informe. Intenta actualizarlo más tarde.',
      );
    }
  }
}

LearningEvidence demoLearningEvidence() {
  const policy = EvidencePolicy(
    windowDays: 90,
    subtopicMinimum: 5,
    themeMinimum: 10,
    sessionsMinimum: 2,
    daysMinimum: 2,
  );
  // Isolated preview, never merged with server history or persisted as progress.
  return LearningEvidence(
    policy: policy,
    partial: false,
    excluded: 0,
    repeated: 4,
    since: DateTime.utc(2026, 6, 8),
    until: DateTime.utc(2026, 9, 6),
    isDemo: true,
    topics: const [
      EvidenceItem(
        id: 'demo-proportions',
        name: 'Proporcionalidad',
        area: AcademicArea.mathematics,
        questions: 10,
        correct: 7,
        sessions: 3,
        days: 3,
        percentage: 70,
        level: EvidenceLevel.developing,
        subtopics: [
          EvidenceItem(
            id: 'demo-rule-three',
            name: 'Regla de tres directa',
            area: AcademicArea.mathematics,
            questions: 5,
            correct: 2,
            sessions: 2,
            days: 2,
            percentage: 40,
            level: EvidenceLevel.needsReview,
          ),
          EvidenceItem(
            id: 'demo-ratios',
            name: 'Razones y proporciones',
            area: AcademicArea.mathematics,
            questions: 5,
            correct: 5,
            sessions: 2,
            days: 2,
            percentage: 100,
            level: EvidenceLevel.strength,
          ),
        ],
      ),
      EvidenceItem(
        id: 'demo-grammar',
        name: 'Gramática',
        area: AcademicArea.english,
        questions: 1,
        correct: 0,
        sessions: 1,
        days: 1,
        percentage: 0,
        level: EvidenceLevel.insufficient,
        subtopics: [
          EvidenceItem(
            id: 'demo-to-be',
            name: 'Verbo to be',
            area: AcademicArea.english,
            questions: 1,
            correct: 0,
            sessions: 1,
            days: 1,
            percentage: 0,
            level: EvidenceLevel.insufficient,
          ),
        ],
      ),
    ],
  );
}
