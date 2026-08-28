import '../../academic/domain/academic_models.dart';
import '../../practice/data/demo_practice_repository.dart';
import '../../practice/domain/practice_history_models.dart';
import '../../practice/domain/practice_models.dart';
import '../../study/domain/study_models.dart';
import '../domain/progress_models.dart';
import '../domain/progress_repository.dart';

class DemoProgressRepository implements ProgressRepository {
  final _practice = DemoPracticeRepository();

  @override
  Future<ProgressDashboard> loadDashboard() async => ProgressDashboard(
    study: const StudyProgress(
      totalSubtopics: 5,
      viewedSubtopics: 3,
      completedSubtopics: 2,
      overallPercentage: 48,
      bySubtopic: {},
    ),
    answers: const AnswerHistorySummary(
      total: 24,
      correct: 15,
      incorrect: 9,
      successPercentage: 62.5,
    ),
    byArea: {
      for (final area in AcademicArea.values)
        area: AnswerHistorySummary(
          total: 4,
          correct: area == AcademicArea.mathematics ? 2 : 3,
          incorrect: area == AcademicArea.mathematics ? 2 : 1,
          successPercentage: area == AcademicArea.mathematics ? 50 : 75,
        ),
    },
  );

  @override
  Future<ErrorNotebook> loadNotebook(NotebookFilter filter) async =>
      ErrorNotebook.empty;

  @override
  Future<void> updateNotebookEntry({
    required String questionId,
    required String note,
    required NotebookStatus status,
  }) async {}

  @override
  Future<AdaptiveProfile> loadAdaptiveProfile() async => const AdaptiveProfile(
    analyzedAttempts: 24,
    recentAccuracy: 62.5,
    targetLevel: PracticeDifficulty.medium,
    areaPerformance: [
      AdaptiveAreaPerformance(
        area: AcademicArea.mathematics,
        attempts: 8,
        accuracy: 50,
        priority: 50,
      ),
      AdaptiveAreaPerformance(
        area: AcademicArea.naturalSciences,
        attempts: 4,
        accuracy: 55,
        priority: 45,
      ),
      AdaptiveAreaPerformance(
        area: AcademicArea.socialSciences,
        attempts: 4,
        accuracy: 60,
        priority: 40,
      ),
      AdaptiveAreaPerformance(
        area: AcademicArea.criticalReading,
        attempts: 4,
        accuracy: 75,
        priority: 25,
      ),
      AdaptiveAreaPerformance(
        area: AcademicArea.english,
        attempts: 4,
        accuracy: 75,
        priority: 25,
      ),
    ],
    priorityAreas: [
      AcademicArea.mathematics,
      AcademicArea.naturalSciences,
      AcademicArea.socialSciences,
    ],
    recommendedMix: AdaptiveDifficultyMix(basic: 25, medium: 60, advanced: 15),
  );

  @override
  Future<AdaptiveSessionStart> startAdaptiveSession(int questionCount) async {
    final source = await _practice.startRandomPractice(
      RandomPracticeConfig(
        areas: AcademicArea.values,
        questionCount: questionCount,
      ),
    );
    return AdaptiveSessionStart(
      session: PracticeSession(
        attemptId: 'demo-adaptive-${DateTime.now().microsecondsSinceEpoch}',
        area: source.area,
        subtopicId: '',
        questions: source.questions,
        isAdaptive: true,
        selectedAreas: source.areas,
      ),
      plan: const AdaptiveSessionPlan(
        targetLevel: PracticeDifficulty.medium,
        recentAccuracy: 62.5,
        priorityAreas: [
          AcademicArea.mathematics,
          AcademicArea.naturalSciences,
          AcademicArea.socialSciences,
        ],
        questionMix: AdaptiveDifficultyMix(basic: 2, medium: 6, advanced: 2),
      ),
    );
  }

  @override
  Future<AdaptiveGradeResult> gradeAdaptiveSession({
    required String attemptId,
    required List<PracticeAnswer> answers,
  }) async => AdaptiveGradeResult(
    result: await _practice.gradeRandomPractice(
      attemptId: attemptId,
      answers: answers,
    ),
    nextProfile: await loadAdaptiveProfile(),
  );
}
