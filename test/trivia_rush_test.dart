import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:saber_plus/features/academic/domain/academic_models.dart';
import 'package:saber_plus/features/games/trivia_rush/data/demo_trivia_rush_repository.dart';
import 'package:saber_plus/features/games/trivia_rush/domain/trivia_rush_models.dart';
import 'package:saber_plus/features/games/trivia_rush/domain/trivia_rush_repository.dart';
import 'package:saber_plus/features/games/trivia_rush/presentation/trivia_rush_page.dart';
import 'package:saber_plus/features/games/trivia_rush/presentation/trivia_rush_providers.dart';
import 'package:saber_plus/features/practice/domain/practice_models.dart';

void main() {
  test('construye y recupera una configuración de Trivia Rush', () {
    const config = TriviaRushConfig(
      areas: [AcademicArea.mathematics, AcademicArea.english],
      duration: TriviaRushDuration.extended,
    );

    final restored = TriviaRushConfig.tryFromUri(
      Uri.parse(config.routeLocation),
    );

    expect(restored?.areas, [AcademicArea.mathematics, AcademicArea.english]);
    expect(restored?.duration, TriviaRushDuration.extended);
    expect(
      TriviaRushConfig.tryFromUri(
        Uri.parse('/student/practice/trivia-rush/play?segundos=20'),
      ),
      isNull,
    );
  });

  test('aplica los multiplicadores de combo sin otorgar ventaja académica', () {
    var score = const TriviaRushScore();
    for (var index = 0; index < 10; index++) {
      score = score.registerCorrect();
    }

    expect(score.points, 2400);
    expect(score.combo, 10);
    expect(score.bestCombo, 10);
    expect(score.multiplier, 4);

    final protected = score.registerIncorrect(protectCombo: true);
    expect(protected.combo, 10);
    expect(protected.incorrectAnswers, 1);

    final broken = protected.registerIncorrect();
    expect(broken.combo, 0);
    expect(broken.points, score.points);
  });

  test('agrupa errores por tema y conserva la ruta protegida de repaso', () {
    const question = PracticeQuestion(
      id: 'question-1',
      statement: 'Pregunta',
      difficulty: 'MEDIA',
      options: [PracticeOption(id: 'a', text: 'A')],
      subtopicId: 'rule-three',
      subtopicName: 'Regla de tres',
      themeName: 'Proporciones',
      area: AcademicArea.mathematics,
    );
    const evaluation = TriviaRushAnswerEvaluation(
      questionId: 'question-1',
      isCorrect: false,
      correctAnswerId: 'a',
      explanation: 'Explicación',
    );

    final weaknesses = triviaRushWeaknesses(const [
      TriviaRushReviewEntry(
        question: question,
        selectedAnswerId: 'b',
        evaluation: evaluation,
      ),
      TriviaRushReviewEntry(
        question: question,
        selectedAnswerId: 'c',
        evaluation: evaluation,
      ),
    ]);

    expect(weaknesses.single.errors, 2);
    expect(
      weaknesses.single.studyRoute,
      '/student/practice/subtopic/matematicas/rule-three',
    );
  });

  test(
    'la demostración valida respuestas sin exponer la clave en sesión',
    () async {
      final repository = DemoTriviaRushRepository();
      final session = await repository.start(
        const TriviaRushConfig(
          areas: [AcademicArea.mathematics],
          duration: TriviaRushDuration.quick,
        ),
      );
      final question = session.questions.first;

      expect(question.toJson().toString(), isNot(contains('esCorrecta')));
      expect(session.questions.first.difficulty, 'BASICA');
      expect(session.questions[10].difficulty, 'MEDIA');
      expect(session.questions[20].difficulty, 'AVANZADA');
      final evaluation = await repository.answer(
        attemptId: session.attemptId,
        questionId: question.id,
        answerId: question.options.first.id,
        responseTimeSeconds: 3,
      );
      final booster = await repository.activateBooster(
        attemptId: session.attemptId,
        questionId: question.id,
        booster: TriviaRushBooster.fiftyFifty,
      );

      expect(evaluation.isCorrect, isTrue);
      expect(booster.eliminatedAnswerIds, hasLength(2));
      expect(
        booster.eliminatedAnswerIds,
        isNot(contains(evaluation.correctAnswerId)),
      );
    },
  );

  testWidgets('termina una ronda y muestra el diagnóstico académico', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          triviaRushRepositoryProvider.overrideWithValue(
            const _FakeTriviaRushRepository(),
          ),
        ],
        child: const MaterialApp(
          home: TriviaRushPage(
            config: TriviaRushConfig(
              areas: [AcademicArea.mathematics],
              duration: TriviaRushDuration.quick,
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump();

    await tester.tap(find.byKey(const Key('trivia-answer-answer-a')));
    await tester.pump(const Duration(milliseconds: 600));
    await tester.pump();

    expect(find.byKey(const Key('trivia-result-view')), findsOneWidget);
    expect(find.text('100 puntos'), findsOneWidget);
    expect(
      find.text('No detectamos errores en las respuestas enviadas.'),
      findsOneWidget,
    );
  });
}

class _FakeTriviaRushRepository implements TriviaRushRepository {
  const _FakeTriviaRushRepository();

  @override
  Future<TriviaRushSession> start(TriviaRushConfig config) async =>
      const TriviaRushSession(
        attemptId: 'attempt-1',
        questions: [
          PracticeQuestion(
            id: 'question-1',
            statement: '¿Cuánto es dos más dos?',
            difficulty: 'BASICA',
            options: [
              PracticeOption(id: 'answer-a', text: '4'),
              PracticeOption(id: 'answer-b', text: '5'),
            ],
            subtopicId: 'sums',
            subtopicName: 'Suma',
            themeName: 'Aritmética',
            area: AcademicArea.mathematics,
          ),
        ],
      );

  @override
  Future<TriviaRushAnswerEvaluation> answer({
    required String attemptId,
    required String questionId,
    required String answerId,
    required int responseTimeSeconds,
  }) async => TriviaRushAnswerEvaluation(
    questionId: questionId,
    isCorrect: answerId == 'answer-a',
    correctAnswerId: 'answer-a',
    explanation: 'Dos más dos es cuatro.',
  );

  @override
  Future<TriviaRushBoosterActivation> activateBooster({
    required String attemptId,
    required String questionId,
    required TriviaRushBooster booster,
  }) async => const TriviaRushBoosterActivation();
}
