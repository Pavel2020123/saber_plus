import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:saber_plus/features/academic/domain/academic_models.dart';
import 'package:saber_plus/features/academic/data/diagnostic_draft_store.dart';
import 'package:saber_plus/features/academic/presentation/academic_home_controller.dart';
import 'package:saber_plus/features/academic/presentation/diagnostic_overview_page.dart';

DiagnosticQuestion fixture() => DiagnosticQuestion.fromJson({
  'id': 'booklet-question',
  'enunciado': 'Description',
  'respuestas': [
    {'id': 'a', 'texto': 'Alpha'},
    {'id': 'b', 'texto': 'Beta'},
  ],
  'subtema': {
    'nombre': 'Vocabulary',
    'tema': {'nombre': 'Words', 'area': 'INGLES'},
  },
  'cuadernillo': {
    'actividadId': 'activity',
    'version': 1,
    'contenido': {
      'format': 'vocabularyMatching',
      'title': 'QA matching',
      'instructions': 'Match the description.',
      'passage': '',
      'example': {'prompt': 'Example', 'answer': 'H. sample'},
      'choices': [
        {'id': 'a', 'label': 'A', 'text': 'Alpha'},
        {'id': 'b', 'label': 'B', 'text': 'Beta'},
      ],
      'items': [
        {
          'id': 'booklet-question',
          'number': 80,
          'prompt': 'Description',
          'choiceIds': ['a', 'b'],
        },
      ],
    },
  },
});

class _Controller extends AcademicHomeController {
  @override
  Future<AcademicHomeData> build() async => AcademicHomeData(
    diagnostic: DiagnosticSummary(
      status: DiagnosticStatus.inProgress,
      id: 'qa-diagnostic',
      totalQuestions: 1,
      questions: [fixture()],
    ),
    plan: const StudyPlanSummary(status: StudyPlanStatus.diagnosticPending),
  );
}

class _Store extends DiagnosticDraftStore {
  _Store() : super(const FlutterSecureStorage());
  DiagnosticDraft? saved;
  @override
  Future<DiagnosticDraft?> read(String id) async => saved;
  @override
  Future<void> save(DiagnosticDraft draft) async {
    saved = draft;
  }
}

void main() {
  test('parses booklet metadata without losing original option letters', () {
    final question = fixture();
    expect(question.booklet!.example!.answer, 'H. sample');
    expect(question.booklet!.items.single.id, question.id);
    expect(
      question.booklet!.choices.map((c) => c.id),
      question.options.map((c) => c.id),
    );
  });
  testWidgets(
    'diagnostic renders matching and stores its selection in the diagnostic draft',
    (tester) async {
      final store = _Store();
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            academicHomeControllerProvider.overrideWith(_Controller.new),
            diagnosticDraftStoreProvider.overrideWithValue(store),
          ],
          child: const MaterialApp(home: DiagnosticOverviewPage()),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('QA matching'), findsOneWidget);
      expect(find.text('Palabras'), findsOneWidget);
      await tester.ensureVisible(
        find.byKey(const Key('booklet-answer-booklet-question')),
      );
      await tester.tap(
        find.byKey(const Key('booklet-answer-booklet-question')),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('B. Beta').last);
      await tester.pumpAndSettle();
      expect(find.text('1 respondidas'), findsOneWidget);
      expect(store.saved!.selectedAnswers['booklet-question'], 'b');
      expect(find.text('Finalizar'), findsOneWidget);
    },
  );
}
