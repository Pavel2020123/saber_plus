import 'package:flutter/material.dart' hide DiagnosticLevel;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:saber_plus/features/academic/data/diagnostic_draft_store.dart';
import 'package:saber_plus/features/academic/domain/academic_models.dart';
import 'package:saber_plus/features/academic/presentation/academic_home_controller.dart';
import 'package:saber_plus/features/academic/presentation/diagnostic_overview_page.dart';

const _question = DiagnosticQuestion(
  id: 'question-1',
  statement: '¿Cuál es el valor de x?',
  difficulty: 'MEDIA',
  options: [
    DiagnosticOption(id: 'answer-a', text: '10'),
    DiagnosticOption(id: 'answer-b', text: '20'),
  ],
  subtopicName: 'Regla de tres',
  themeName: 'Razones y proporciones',
  area: AcademicArea.mathematics,
);

void main() {
  testWidgets('inicia y muestra la primera pregunta del diagnóstico', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          academicHomeControllerProvider.overrideWith(
            _NotStartedAcademicController.new,
          ),
          diagnosticDraftStoreProvider.overrideWithValue(_MemoryDraftStore()),
        ],
        child: const MaterialApp(home: DiagnosticOverviewPage()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Descubre tu punto de partida'), findsOneWidget);
    await tester.tap(find.byKey(const Key('start-diagnostic-button')));
    await tester.pumpAndSettle();

    expect(find.text('Pregunta 1 de 1'), findsOneWidget);
    expect(find.text('Regla de tres'), findsOneWidget);
    expect(find.text('¿Cuál es el valor de x?'), findsOneWidget);
  });

  testWidgets('restaura la respuesta guardada en el borrador', (tester) async {
    final store = _MemoryDraftStore(
      initial: const DiagnosticDraft(
        diagnosticId: 'diagnostic-1',
        selectedAnswers: {'question-1': 'answer-b'},
        responseTimesSeconds: {'question-1': 12},
      ),
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          academicHomeControllerProvider.overrideWith(
            _InProgressAcademicController.new,
          ),
          diagnosticDraftStoreProvider.overrideWithValue(store),
        ],
        child: const MaterialApp(home: DiagnosticOverviewPage()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('1 respondidas'), findsOneWidget);
    final option = tester.widget<Semantics>(
      find
          .descendant(
            of: find.byKey(const Key('diagnostic-option-answer-b')),
            matching: find.byType(Semantics),
          )
          .first,
    );
    expect(option.properties.selected, isTrue);
  });

  testWidgets('finaliza y muestra la falencia exacta por subtema', (
    tester,
  ) async {
    final store = _MemoryDraftStore();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          academicHomeControllerProvider.overrideWith(
            _InProgressAcademicController.new,
          ),
          diagnosticDraftStoreProvider.overrideWithValue(store),
        ],
        child: const MaterialApp(home: DiagnosticOverviewPage()),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('diagnostic-option-answer-a')));
    await tester.tap(find.byKey(const Key('finish-diagnostic-button')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('confirm-finish-diagnostic-button')));
    await tester.pumpAndSettle();

    expect(find.text('Tu línea base'), findsOneWidget);
    expect(find.text('Temas para reforzar'), findsOneWidget);
    expect(find.text('Regla de tres'), findsOneWidget);
    expect(find.textContaining('Razones y proporciones'), findsOneWidget);
    expect(store.wasCleared, isTrue);
  });
}

class _MemoryDraftStore extends DiagnosticDraftStore {
  _MemoryDraftStore({DiagnosticDraft? initial})
    : _draft = initial,
      super(const FlutterSecureStorage());

  DiagnosticDraft? _draft;
  bool wasCleared = false;

  @override
  Future<DiagnosticDraft?> read(String diagnosticId) async => _draft;

  @override
  Future<void> save(DiagnosticDraft draft) async => _draft = draft;

  @override
  Future<void> clear(String diagnosticId) async {
    wasCleared = true;
    _draft = null;
  }
}

class _NotStartedAcademicController extends AcademicHomeController {
  static const initial = AcademicHomeData(
    diagnostic: DiagnosticSummary(status: DiagnosticStatus.notStarted),
    plan: StudyPlanSummary(status: StudyPlanStatus.diagnosticPending),
  );

  @override
  Future<AcademicHomeData> build() async => initial;

  @override
  Future<bool> startDiagnostic() async {
    state = const AsyncData(_InProgressAcademicController.initial);
    return true;
  }
}

class _InProgressAcademicController extends AcademicHomeController {
  static const initial = AcademicHomeData(
    diagnostic: DiagnosticSummary(
      status: DiagnosticStatus.inProgress,
      id: 'diagnostic-1',
      totalQuestions: 1,
      questions: [_question],
    ),
    plan: StudyPlanSummary(status: StudyPlanStatus.diagnosticPending),
  );

  @override
  Future<AcademicHomeData> build() async => initial;

  @override
  Future<DiagnosticSummary> finishDiagnostic(
    List<DiagnosticAnswer> answers,
  ) async {
    expect(answers, hasLength(1));
    expect(answers.single.questionId, 'question-1');
    expect(answers.single.answerId, 'answer-a');
    return const DiagnosticSummary(
      status: DiagnosticStatus.completed,
      id: 'diagnostic-1',
      totalQuestions: 1,
      correctAnswers: 0,
      percentage: 0,
      level: DiagnosticLevel.needsReinforcement,
      priorityArea: AcademicArea.mathematics,
      resultsByArea: [
        AreaDiagnosticResult(
          area: AcademicArea.mathematics,
          totalQuestions: 1,
          correctAnswers: 0,
          percentage: 0,
          level: DiagnosticLevel.needsReinforcement,
        ),
      ],
      weakTopics: [
        WeakTopic(
          area: AcademicArea.mathematics,
          theme: 'Razones y proporciones',
          subtopic: 'Regla de tres',
          failedQuestions: 1,
        ),
      ],
    );
  }
}
