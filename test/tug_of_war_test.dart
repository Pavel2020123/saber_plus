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

  testWidgets('resuelve una ronda local y mueve la cuerda sin animarla', (
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

    expect(find.byKey(const Key('tug-arena-mockup')), findsOneWidget);
    expect(find.byKey(const Key('tug-prototype-banner')), findsOneWidget);
    await tester.tap(find.byKey(const Key('tug-answer-answer-a')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 120));

    expect(find.byKey(const Key('tug-round-feedback')), findsOneWidget);
    expect(find.text('¡Tirón fuerte para ti!'), findsOneWidget);
    expect(find.text('+2'), findsOneWidget);
    expect(audio.played, [GameSound.matchFound, GameSound.tugPull]);

    await tester.pumpWidget(const SizedBox());
  });
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
