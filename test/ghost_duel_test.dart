import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:saber_plus/features/academic/domain/academic_models.dart';
import 'package:saber_plus/features/games/ghost_duel/data/shared_preferences_ghost_duel_repository.dart';
import 'package:saber_plus/features/games/ghost_duel/domain/ghost_duel_models.dart';
import 'package:saber_plus/features/games/ghost_duel/domain/ghost_duel_repository.dart';
import 'package:saber_plus/features/games/ghost_duel/presentation/ghost_duel_providers.dart';
import 'package:saber_plus/features/games/trivia_rush/domain/trivia_rush_models.dart';
import 'package:saber_plus/features/games/trivia_rush/domain/trivia_rush_repository.dart';
import 'package:saber_plus/features/games/trivia_rush/presentation/trivia_rush_page.dart';
import 'package:saber_plus/features/games/trivia_rush/presentation/trivia_rush_providers.dart';
import 'package:saber_plus/features/practice/domain/practice_models.dart';

void main() {
  test('construye una ruta de duelo y ordena las áreas de su clave', () {
    const config = GhostDuelConfig(
      areas: [AcademicArea.mathematics, AcademicArea.english],
      duration: TriviaRushDuration.extended,
    );
    final restored = GhostDuelConfig.tryFromUri(
      Uri.parse(config.routeLocation),
    );
    final key = GhostDuelKey(
      areas: const [AcademicArea.mathematics, AcademicArea.english],
      seconds: 120,
    );

    expect(restored?.areas, config.areas);
    expect(restored?.duration, TriviaRushDuration.extended);
    expect(key.areas, [AcademicArea.english, AcademicArea.mathematics]);
    expect(key.storageKey, 'INGLES-MATEMATICAS.120');
  });

  test('reproduce el puntaje del fantasma en cada instante', () {
    final run = _run(
      score: 500,
      checkpoints: const [
        GhostCheckpoint(elapsedSeconds: 5, score: 100),
        GhostCheckpoint(elapsedSeconds: 12, score: 300),
        GhostCheckpoint(elapsedSeconds: 20, score: 500),
      ],
    );

    expect(run.scoreAt(0), 0);
    expect(run.scoreAt(12), 300);
    expect(run.scoreAt(60), 500);
  });

  test('guarda solo el mejor récord limpio y separa estudiantes', () async {
    final storage = <String, String>{};
    final repository = SharedPreferencesGhostDuelRepository.withStorage(
      reader: (key) async => storage[key],
      writer: (key, value) async => storage[key] = value,
    );
    final first = _run(score: 500);
    final weaker = _run(score: 400);
    final stronger = _run(score: 700);

    expect(
      (await repository.saveIfBetter(first)).outcome,
      GhostDuelOutcome.firstRecord,
    );
    expect(
      (await repository.saveIfBetter(weaker)).outcome,
      GhostDuelOutcome.keptRecord,
    );
    expect(
      (await repository.saveIfBetter(stronger)).outcome,
      GhostDuelOutcome.newRecord,
    );
    expect(
      (await repository.loadBest(
        userId: 'student-1',
        key: stronger.key,
      ))?.score,
      700,
    );
    expect(
      await repository.loadBest(userId: 'student-2', key: stronger.key),
      isNull,
    );
    expect(
      () => repository.saveIfBetter(_run(score: 900, assisted: true)),
      throwsArgumentError,
    );
  });

  testWidgets('crea el primer fantasma al completar una ronda limpia', (
    tester,
  ) async {
    final ghosts = _MemoryGhostRepository();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          ghostDuelUserIdProvider.overrideWithValue('student-1'),
          ghostDuelRepositoryProvider.overrideWithValue(ghosts),
          triviaRushRepositoryProvider.overrideWithValue(
            const _OneQuestionTriviaRepository(),
          ),
        ],
        child: const MaterialApp(
          home: TriviaRushPage(
            ghostMode: true,
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

    expect(find.byKey(const Key('ghost-race-status')), findsOneWidget);
    expect(find.text('Potenciadores'), findsNothing);
    await tester.tap(find.byKey(const Key('trivia-answer-answer-a')));
    await tester.pump(const Duration(milliseconds: 600));
    await tester.pump();

    expect(find.byKey(const Key('trivia-result-view')), findsOneWidget);
    expect(find.text('Primer fantasma creado'), findsOneWidget);
    expect(ghosts.best?.score, 100);
    expect(ghosts.best?.assisted, isFalse);
  });
}

GhostRun _run({
  required int score,
  bool assisted = false,
  List<GhostCheckpoint> checkpoints = const [
    GhostCheckpoint(elapsedSeconds: 10, score: 500),
  ],
}) => GhostRun(
  userId: 'student-1',
  key: GhostDuelKey(areas: const [AcademicArea.mathematics], seconds: 60),
  score: score,
  bestCombo: score ~/ 100,
  correctAnswers: score ~/ 100,
  completedAt: DateTime(2026, 8, 30, 12),
  checkpoints: checkpoints,
  assisted: assisted,
);

class _MemoryGhostRepository implements GhostDuelRepository {
  GhostRun? best;

  @override
  Future<GhostRun?> loadBest({
    required String userId,
    required GhostDuelKey key,
  }) async => best;

  @override
  Future<GhostSaveResult> saveIfBetter(GhostRun run) async {
    final previous = best;
    if (previous == null || run.isBetterThan(previous)) best = run;
    return GhostSaveResult(
      outcome: previous == null
          ? GhostDuelOutcome.firstRecord
          : best == run
          ? GhostDuelOutcome.newRecord
          : GhostDuelOutcome.keptRecord,
      bestRun: best!,
    );
  }
}

class _OneQuestionTriviaRepository implements TriviaRushRepository {
  const _OneQuestionTriviaRepository();

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
