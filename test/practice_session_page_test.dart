import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:saber_plus/features/academic/domain/academic_models.dart';
import 'package:saber_plus/features/auth/domain/session.dart';
import 'package:saber_plus/features/auth/presentation/session_controller.dart';
import 'package:saber_plus/features/practice/data/practice_draft_store.dart';
import 'package:saber_plus/features/practice/domain/practice_history_models.dart';
import 'package:saber_plus/features/practice/domain/practice_models.dart';
import 'package:saber_plus/features/practice/domain/practice_repository.dart';
import 'package:saber_plus/features/practice/presentation/practice_providers.dart';
import 'package:saber_plus/features/practice/presentation/practice_session_page.dart';
import 'package:saber_plus/features/progress/domain/progress_models.dart';
import 'package:saber_plus/features/progress/domain/progress_repository.dart';
import 'package:saber_plus/features/progress/presentation/progress_providers.dart';
import 'package:saber_plus/features/study/data/remote_study_repository.dart';
import 'package:saber_plus/features/study/domain/study_models.dart';
import 'package:saber_plus/features/study/domain/study_repository.dart';

const _practiceSession = PracticeSession(
  attemptId: 'attempt-1',
  area: AcademicArea.mathematics,
  subtopicId: 'subtopic-1',
  questions: [
    PracticeQuestion(
      id: 'question-1',
      statement: '¿Cuánto cuesta?',
      difficulty: 'MEDIA',
      options: [
        PracticeOption(id: 'answer-a', text: '10'),
        PracticeOption(id: 'answer-b', text: '20'),
      ],
      subtopicName: 'Regla de tres',
      themeName: 'Proporciones',
      area: AcademicArea.mathematics,
    ),
  ],
);

const _adaptiveSession = PracticeSession(
  attemptId: 'adaptive-attempt-1',
  area: AcademicArea.mathematics,
  subtopicId: '',
  isAdaptive: true,
  selectedAreas: [AcademicArea.mathematics],
  questions: [
    PracticeQuestion(
      id: 'question-1',
      statement: '¿Cuánto cuesta?',
      difficulty: 'MEDIO',
      options: [
        PracticeOption(id: 'answer-a', text: '10'),
        PracticeOption(id: 'answer-b', text: '20'),
      ],
      subtopicName: 'Regla de tres',
      themeName: 'Proporciones',
      area: AcademicArea.mathematics,
    ),
  ],
);

void main() {
  testWidgets('responde, califica y revela la explicación al finalizar', (
    tester,
  ) async {
    final repository = _FakePracticeRepository();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          practiceRepositoryProvider.overrideWithValue(repository),
          studyRepositoryProvider.overrideWithValue(_FakeStudyRepository()),
        ],
        child: const MaterialApp(
          home: PracticeSessionPage(
            area: AcademicArea.mathematics,
            subtopicId: 'subtopic-1',
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Pregunta 1 de 1'), findsOneWidget);
    expect(find.text('¿Cuánto cuesta?'), findsOneWidget);
    expect(find.text('Respuesta correcta'), findsNothing);

    await tester.tap(find.byKey(const Key('practice-answer-answer-b')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('submit-practice-button')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('confirm-submit-practice-button')));
    await tester.pumpAndSettle();

    expect(repository.gradeCalls, 1);
    expect(find.byKey(const Key('practice-result-view')), findsOneWidget);
    expect(find.text('0%'), findsOneWidget);
    expect(find.text('Por reforzar'), findsOneWidget);
    expect(find.text('Cómo se resuelve'), findsOneWidget);
    expect(find.text('Divide y luego multiplica.'), findsOneWidget);
    expect(find.text('Tu respuesta'), findsOneWidget);
    expect(find.text('Correcta'), findsOneWidget);
  });

  testWidgets('reanuda respuestas y tiempos sin crear otro intento', (
    tester,
  ) async {
    final repository = _FakePracticeRepository();
    final now = DateTime.now();
    final drafts = _MemoryPracticeDraftStore(
      initial: PracticeDraft(
        session: _practiceSession,
        selectedAnswers: const {'question-1': 'answer-b'},
        responseTimesSeconds: const {'question-1': 21},
        currentIndex: 0,
        startedAt: now.subtract(const Duration(minutes: 2)),
        expiresAt: now.add(const Duration(minutes: 100)),
      ),
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sessionControllerProvider.overrideWith(
            _AuthenticatedSessionController.new,
          ),
          practiceRepositoryProvider.overrideWithValue(repository),
          practiceDraftStoreProvider.overrideWithValue(drafts),
        ],
        child: const MaterialApp(
          home: PracticeSessionPage(
            area: AcademicArea.mathematics,
            subtopicId: 'subtopic-1',
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(repository.startCalls, 0);
    expect(find.text('Intento reanudado.'), findsOneWidget);
    final submit = tester.widget<FilledButton>(
      find.byKey(const Key('submit-practice-button')),
    );
    expect(submit.onPressed, isNotNull);
  });

  testWidgets('completa y califica una sesión de repaso adaptativo', (
    tester,
  ) async {
    final repository = _FakeProgressRepository();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          progressRepositoryProvider.overrideWithValue(repository),
          practiceDraftStoreProvider.overrideWithValue(
            _MemoryPracticeDraftStore(),
          ),
        ],
        child: const MaterialApp(
          home: PracticeSessionPage.adaptive(questionCount: 15),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Repaso inteligente'), findsOneWidget);
    expect(find.text('Pregunta 1 de 1'), findsOneWidget);
    await tester.tap(find.byKey(const Key('practice-answer-answer-a')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('submit-practice-button')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('confirm-submit-practice-button')));
    await tester.pumpAndSettle();

    expect(repository.startCalls, 1);
    expect(repository.gradeCalls, 1);
    expect(find.text('Resultado del repaso'), findsOneWidget);
    expect(find.text('100%'), findsOneWidget);
  });
}

class _FakePracticeRepository implements PracticeRepository {
  var gradeCalls = 0;
  var startCalls = 0;

  @override
  Future<PracticeSession> startSubtopicPractice({
    required AcademicArea area,
    required String subtopicId,
  }) async {
    startCalls++;
    return _practiceSession;
  }

  @override
  Future<PracticeResult> gradePractice({
    required String attemptId,
    required AcademicArea area,
    required List<PracticeAnswer> answers,
  }) async {
    gradeCalls++;
    expect(answers.single.answerId, 'answer-b');
    return const PracticeResult(
      summary: PracticeResultSummary(
        totalQuestions: 1,
        correctAnswers: 0,
        incorrectAnswers: 1,
        percentage: 0,
        earnedXp: 0,
      ),
      review: [
        PracticeReviewQuestion(
          id: 'question-1',
          statement: '¿Cuánto cuesta?',
          isCorrect: false,
          selectedAnswerId: 'answer-b',
          correctAnswerId: 'answer-a',
          explanation: 'Divide y luego multiplica.',
          options: [
            PracticeReviewOption(id: 'answer-a', text: '10', isCorrect: true),
            PracticeReviewOption(id: 'answer-b', text: '20', isCorrect: false),
          ],
        ),
      ],
    );
  }

  @override
  Future<PracticeResult> gradeRandomPractice({
    required String attemptId,
    required List<PracticeAnswer> answers,
  }) => throw UnimplementedError();

  @override
  Future<PracticeSession> startRandomPractice(RandomPracticeConfig config) =>
      throw UnimplementedError();

  @override
  Future<PracticeSession> startAreaSimulation(AcademicArea area) =>
      throw UnimplementedError();

  @override
  Future<PracticeResult> gradeAreaSimulation({
    required String attemptId,
    required AcademicArea area,
    required List<PracticeAnswer> answers,
  }) => throw UnimplementedError();

  @override
  Future<SimulationHistory> loadSimulationHistory() =>
      throw UnimplementedError();

  @override
  Future<AnswerHistory> loadAnswerHistory(AnswerHistoryFilter filter) =>
      throw UnimplementedError();
}

class _FakeStudyRepository implements StudyRepository {
  @override
  Future<DownloadedThemePdf> downloadThemePdf(StudyTheme theme) =>
      throw UnimplementedError();

  @override
  Future<StudyCatalog> loadCatalog(AcademicArea area) =>
      throw UnimplementedError();

  @override
  Future<StudyProgress> loadProgress() async => StudyProgress.empty;

  @override
  Future<void> updateSubtopicProgress(
    String subtopicId,
    int percentage,
  ) async {}
}

class _FakeProgressRepository implements ProgressRepository {
  var startCalls = 0;
  var gradeCalls = 0;

  @override
  Future<AdaptiveSessionStart> startAdaptiveSession(int questionCount) async {
    startCalls++;
    expect(questionCount, 15);
    return const AdaptiveSessionStart(
      session: _adaptiveSession,
      plan: AdaptiveSessionPlan(
        targetLevel: PracticeDifficulty.medium,
        priorityAreas: [AcademicArea.mathematics],
        questionMix: AdaptiveDifficultyMix(basic: 0, medium: 1, advanced: 0),
      ),
    );
  }

  @override
  Future<AdaptiveGradeResult> gradeAdaptiveSession({
    required String attemptId,
    required List<PracticeAnswer> answers,
  }) async {
    gradeCalls++;
    expect(attemptId, 'adaptive-attempt-1');
    expect(answers.single.answerId, 'answer-a');
    return const AdaptiveGradeResult(
      result: PracticeResult(
        summary: PracticeResultSummary(
          totalQuestions: 1,
          correctAnswers: 1,
          incorrectAnswers: 0,
          percentage: 100,
          earnedXp: 60,
        ),
        review: [
          PracticeReviewQuestion(
            id: 'question-1',
            statement: '¿Cuánto cuesta?',
            isCorrect: true,
            selectedAnswerId: 'answer-a',
            correctAnswerId: 'answer-a',
            explanation: 'Divide y multiplica.',
            options: [
              PracticeReviewOption(id: 'answer-a', text: '10', isCorrect: true),
              PracticeReviewOption(
                id: 'answer-b',
                text: '20',
                isCorrect: false,
              ),
            ],
          ),
        ],
      ),
      nextProfile: AdaptiveProfile(
        analyzedAttempts: 1,
        recentAccuracy: 100,
        targetLevel: PracticeDifficulty.medium,
        areaPerformance: [],
        priorityAreas: [AcademicArea.mathematics],
        recommendedMix: AdaptiveDifficultyMix(
          basic: 25,
          medium: 60,
          advanced: 15,
        ),
      ),
    );
  }

  @override
  Future<AdaptiveProfile> loadAdaptiveProfile() => throw UnimplementedError();

  @override
  Future<ProgressDashboard> loadDashboard() => throw UnimplementedError();

  @override
  Future<ErrorNotebook> loadNotebook(NotebookFilter filter) =>
      throw UnimplementedError();

  @override
  Future<void> updateNotebookEntry({
    required String questionId,
    required String note,
    required NotebookStatus status,
  }) => throw UnimplementedError();
}

class _MemoryPracticeDraftStore extends PracticeDraftStore {
  _MemoryPracticeDraftStore({PracticeDraft? initial})
    : _draft = initial,
      super(const FlutterSecureStorage());

  PracticeDraft? _draft;

  @override
  Future<PracticeDraft?> read(String userId, String draftId) async => _draft;

  @override
  Future<void> save(String userId, String draftId, PracticeDraft draft) async =>
      _draft = draft;

  @override
  Future<void> clear(String userId, String draftId) async => _draft = null;
}

class _AuthenticatedSessionController extends SessionController {
  @override
  SessionState build() => const SessionState.authenticated(
    UserSession(id: 'user-1', firstName: 'Ana', role: AppRole.student),
  );
}
