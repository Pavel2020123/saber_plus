import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:saber_plus/core/feedback/game_audio_feedback.dart';
import 'package:saber_plus/features/academic/domain/academic_models.dart';
import 'package:saber_plus/features/games/trivia_rush/domain/trivia_rush_models.dart';
import 'package:saber_plus/features/games/trivia_rush/domain/trivia_rush_repository.dart';
import 'package:saber_plus/features/games/trivia_rush/presentation/trivia_rush_providers.dart';
import 'package:saber_plus/features/games/tug_of_war/domain/tug_of_war_models.dart';
import 'package:saber_plus/features/games/tug_of_war/presentation/tug_of_war_page.dart';
import 'package:saber_plus/features/games/tug_of_war/presentation/tug_of_war_providers.dart';
import 'package:saber_plus/features/practice/domain/practice_models.dart';

void main() {
  test('construye y recupera la configuración de Tira y afloja', () {
    const config = TugOfWarConfig(
      areas: [AcademicArea.mathematics, AcademicArea.english],
      cpuDifficulty: TugCpuDifficulty.challenge,
    );

    final restored = TugOfWarConfig.tryFromUri(Uri.parse(config.routeLocation));

    expect(restored?.areas, [AcademicArea.mathematics, AcademicArea.english]);
    expect(restored?.cpuDifficulty, TugCpuDifficulty.challenge);
    expect(
      TugOfWarConfig.tryFromUri(
        Uri.parse('/student/practice/tug-of-war/play?rival=otro'),
      ),
      isNull,
    );
  });

  test('da un tirón fuerte cuando solo un participante acierta', () {
    final player = TugRoundResolution.resolve(
      playerCorrect: true,
      playerResponseMilliseconds: 1800,
      cpuCorrect: false,
      cpuResponseMilliseconds: 2500,
    );
    final cpu = TugRoundResolution.resolve(
      playerCorrect: null,
      playerResponseMilliseconds: null,
      cpuCorrect: true,
      cpuResponseMilliseconds: 3200,
    );

    expect(player.outcome, TugRoundOutcome.strongPlayer);
    expect(player.ropeDelta, 2);
    expect(cpu.outcome, TugRoundOutcome.strongCpu);
    expect(cpu.ropeDelta, -2);
  });

  test('usa la velocidad solo cuando los dos aciertan', () {
    final quickPlayer = TugRoundResolution.resolve(
      playerCorrect: true,
      playerResponseMilliseconds: 1500,
      cpuCorrect: true,
      cpuResponseMilliseconds: 2600,
    );
    final nearTie = TugRoundResolution.resolve(
      playerCorrect: true,
      playerResponseMilliseconds: 1500,
      cpuCorrect: true,
      cpuResponseMilliseconds: 1650,
    );
    final bothWrong = TugRoundResolution.resolve(
      playerCorrect: false,
      playerResponseMilliseconds: 1200,
      cpuCorrect: false,
      cpuResponseMilliseconds: 1000,
    );

    expect(quickPlayer.ropeDelta, 1);
    expect(nearTie.outcome, TugRoundOutcome.neutral);
    expect(bothWrong.ropeDelta, 0);
  });

  test('limita la cuerda y detecta al ganador en la cuarta marca', () {
    const resolution = TugRoundResolution(
      outcome: TugRoundOutcome.strongPlayer,
      ropeDelta: 2,
      title: 'Jugador',
      explanation: 'Acierto.',
    );
    var progress = const TugMatchProgress();
    progress = progress.apply(
      resolution: resolution,
      playerCorrect: true,
      cpuCorrect: false,
    );
    progress = progress.apply(
      resolution: resolution,
      playerCorrect: true,
      cpuCorrect: false,
    );

    expect(progress.ropePosition, TugMatchProgress.winningPosition);
    expect(progress.winner, TugWinner.player);
    expect(progress.roundsPlayed, 2);
    expect(progress.playerCorrectAnswers, 2);
  });

  test('el plan CPU siempre respeta los límites de su dificultad', () {
    final random = Random(42);
    final turns = [
      for (var index = 0; index < 100; index++)
        TugCpuTurn.random(TugCpuDifficulty.balanced, random),
    ];

    for (final turn in turns.where((turn) => turn.isCorrect != null)) {
      expect(
        turn.responseMilliseconds,
        inInclusiveRange(
          TugCpuDifficulty.balanced.minimumResponseMilliseconds,
          TugCpuDifficulty.balanced.maximumResponseMilliseconds,
        ),
      );
    }
  });

  testWidgets('anima el tirón antes de habilitar el resultado de la ronda', (
    tester,
  ) async {
    final audio = _RecordingGameAudioFeedback();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          triviaRushRepositoryProvider.overrideWithValue(
            const _FakeTugQuestionRepository(),
          ),
          tugCpuPlannerProvider.overrideWithValue(
            (_) =>
                const TugCpuTurn(isCorrect: false, responseMilliseconds: 100),
          ),
          gameAudioFeedbackProvider.overrideWithValue(audio),
        ],
        child: const MaterialApp(
          home: TugOfWarPage(
            config: TugOfWarConfig(
              areas: [AcademicArea.mathematics],
              cpuDifficulty: TugCpuDifficulty.training,
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump();

    expect(find.byKey(const Key('tug-arena')), findsOneWidget);
    expect(find.byKey(const Key('tug-local-match-banner')), findsOneWidget);
    expect(find.byKey(const Key('tug-arena-preparing')), findsOneWidget);

    await _pumpUntil(
      tester,
      () => find.byKey(const Key('tug-arena-preparing')).evaluate().isEmpty,
    );
    final answer = find.byKey(const Key('tug-answer-answer-a'));
    await tester.scrollUntilVisible(
      answer,
      120,
      scrollable: find.byType(Scrollable).first,
    );
    expect(tester.widget<OutlinedButton>(answer).onPressed, isNotNull);
    await tester.tap(answer);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 120));

    expect(find.byKey(const Key('tug-round-resolving')), findsOneWidget);
    expect(find.byKey(const Key('tug-round-feedback')), findsNothing);
    expect(find.byKey(const Key('continue-tug-round')), findsNothing);

    await tester.pump(const Duration(milliseconds: 1100));

    expect(find.byKey(const Key('tug-round-resolving')), findsNothing);
    expect(find.byKey(const Key('tug-round-feedback')), findsOneWidget);
    expect(find.text('¡Tirón fuerte para ti!'), findsOneWidget);
    expect(find.text('+2'), findsOneWidget);
    expect(audio.played, [
      GameSound.matchFound,
      GameSound.tugRopeStrain,
      GameSound.tugPull,
    ]);

    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('el diálogo de salida pausa el reloj y la respuesta de la CPU', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          triviaRushRepositoryProvider.overrideWithValue(
            const _FakeTugQuestionRepository(),
          ),
          tugCpuPlannerProvider.overrideWithValue(
            (_) =>
                const TugCpuTurn(isCorrect: false, responseMilliseconds: 4000),
          ),
          gameAudioFeedbackProvider.overrideWithValue(
            _RecordingGameAudioFeedback(),
          ),
        ],
        child: const MaterialApp(
          home: MediaQuery(
            data: MediaQueryData(disableAnimations: true),
            child: TugOfWarPage(
              config: TugOfWarConfig(
                areas: [AcademicArea.mathematics],
                cpuDifficulty: TugCpuDifficulty.training,
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump();
    await _pumpUntil(
      tester,
      () => find.byKey(const Key('tug-arena-preparing')).evaluate().isEmpty,
    );

    await tester.tap(find.byIcon(Icons.close_rounded));
    await tester.pump();
    expect(find.text('¿Salir de la partida?'), findsOneWidget);
    expect(find.text('10 s'), findsOneWidget);

    await tester.pump(const Duration(seconds: 5));
    expect(find.text('10 s'), findsOneWidget);

    await tester.tap(find.widgetWithText(TextButton, 'Continuar'));
    await tester.pump();
    final answer = find.byKey(const Key('tug-answer-answer-a'));
    await tester.scrollUntilVisible(
      answer,
      120,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(answer);
    await tester.pump();

    expect(find.textContaining('El rival sigue pensando'), findsOneWidget);
    await tester.pump(const Duration(seconds: 3));
    expect(find.textContaining('El rival sigue pensando'), findsOneWidget);
    expect(find.byKey(const Key('tug-round-feedback')), findsNothing);

    await tester.pump(const Duration(milliseconds: 1200));
    await tester.pump();
    expect(find.byKey(const Key('tug-round-feedback')), findsOneWidget);

    await tester.pumpWidget(const SizedBox());
  });
}

Future<void> _pumpUntil(
  WidgetTester tester,
  bool Function() condition, {
  int maximumPumps = 30,
}) async {
  for (var index = 0; index < maximumPumps; index++) {
    if (condition()) return;
    await tester.pump(const Duration(milliseconds: 100));
  }
  fail('La condición esperada no ocurrió durante la animación.');
}

class _RecordingGameAudioFeedback implements GameAudioFeedback {
  final List<GameSound> played = [];

  @override
  Future<void> play(GameSound sound) async => played.add(sound);
}

class _FakeTugQuestionRepository implements TriviaRushRepository {
  const _FakeTugQuestionRepository();

  @override
  Future<TriviaRushSession> start(TriviaRushConfig config) async =>
      const TriviaRushSession(
        attemptId: 'tug-attempt',
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
