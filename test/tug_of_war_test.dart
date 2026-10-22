import 'dart:math';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:saber_plus/core/feedback/game_audio_feedback.dart';
import 'package:saber_plus/core/widgets/academic_option_content.dart';
import 'package:saber_plus/core/widgets/academic_image.dart';
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

    expect(find.byTooltip('Abandonar partida'), findsOneWidget);
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

  for (final width in [320.0, 412.0]) {
    for (final scale in [1.0, 2.0]) {
      testWidgets(
        'botones ilustrados contienen texto y píxeles a ${width}px texto $scale',
        (tester) async {
          await tester.binding.setSurfaceSize(Size(width, 2000));
          addTearDown(() => tester.binding.setSurfaceSize(null));
          final images = (await tester.runAsync(() async {
            final result = <ui.Image>[];
            for (final size in [const Size(160, 80), const Size(80, 160)]) {
              final recorder = ui.PictureRecorder();
              Canvas(
                recorder,
              ).drawRect(Offset.zero & size, Paint()..color = Colors.blue);
              final picture = recorder.endRecording();
              result.add(
                await picture.toImage(size.width.toInt(), size.height.toInt()),
              );
              picture.dispose();
            }
            return result;
          }))!;
          addTearDown(() {
            for (final image in images) {
              image.dispose();
            }
          });
          await tester.pumpWidget(
            ProviderScope(
              overrides: [
                triviaRushRepositoryProvider.overrideWithValue(
                  const _IllustratedTugQuestionRepository(),
                ),
                editorialImageProvider(
                  _PagedTugQuestionRepository.firstImage,
                ).overrideWith((ref) async => images[0]),
                editorialImageProvider(
                  _PagedTugQuestionRepository.secondImage,
                ).overrideWith((ref) async => images[1]),
                tugCpuPlannerProvider.overrideWithValue(
                  (_) => const TugCpuTurn(
                    isCorrect: false,
                    responseMilliseconds: 7000,
                  ),
                ),
                gameAudioFeedbackProvider.overrideWithValue(
                  _RecordingGameAudioFeedback(),
                ),
              ],
              child: MaterialApp(
                builder: (context, child) => MediaQuery(
                  data: MediaQuery.of(
                    context,
                  ).copyWith(textScaler: TextScaler.linear(scale)),
                  child: child!,
                ),
                home: const TugOfWarPage(
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
          await _pumpUntil(
            tester,
            () =>
                find
                    .descendant(
                      of: find.byType(AcademicOptionContent),
                      matching: find.byType(RawImage),
                    )
                    .evaluate()
                    .length ==
                2,
          );
          for (final id in ['blue', 'orange']) {
            final button = find.byKey(Key('tug-answer-$id'));
            final material = find
                .descendant(of: button, matching: find.byType(Material))
                .first;
            final border = tester.widget<Material>(material).shape!;
            final bounds = tester.getRect(material);
            final outline = border.getOuterPath(Offset.zero & bounds.size);
            final content = find.descendant(
              of: button,
              matching: find.byType(AcademicOptionContent),
            );
            for (final part in [
              find.descendant(of: content, matching: find.byType(Text)),
              find.descendant(of: content, matching: find.byType(RawImage)),
            ]) {
              final rect = tester
                  .getRect(part)
                  .shift(-bounds.topLeft)
                  .deflate(1);
              for (final point in [
                rect.topLeft,
                rect.topRight,
                rect.bottomLeft,
                rect.bottomRight,
              ]) {
                expect(
                  outline.contains(point),
                  isTrue,
                  reason:
                      '$id: contenido $rect fuera del borde $border a $width/$scale',
                );
              }
            }
          }
          expect(tester.takeException(), isNull);
          await tester.pumpWidget(const SizedBox());
        },
      );
    }
  }

  for (final authoritative in [false, true]) {
    testWidgets(
      'avanza imágenes entre rondas con banco ${authoritative ? 'remoto' : 'antiguo'}',
      (tester) async {
        await tester.binding.setSurfaceSize(const Size(800, 1400));
        addTearDown(() => tester.binding.setSurfaceSize(null));
        final repository = _PagedTugQuestionRepository(authoritative);
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              triviaRushRepositoryProvider.overrideWithValue(repository),
              tugCpuPlannerProvider.overrideWithValue(
                (_) => const TugCpuTurn(
                  isCorrect: false,
                  responseMilliseconds: 100,
                ),
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
        final first = find.byKey(const Key('tug-answer-first-blue'));
        await tester.scrollUntilVisible(
          first,
          120,
          scrollable: find.byType(Scrollable).first,
        );
        await tester.ensureVisible(first);
        await tester.pump();
        expect(
          tester
              .widget<AcademicOptionContent>(
                find.descendant(
                  of: first,
                  matching: find.byType(AcademicOptionContent),
                ),
              )
              .imageUrl,
          _PagedTugQuestionRepository.firstImage,
        );
        await tester.tap(first);
        await tester.pump();
        await _pumpUntil(
          tester,
          () =>
              find.byKey(const Key('continue-tug-round')).evaluate().isNotEmpty,
        );
        final next = find.byKey(const Key('continue-tug-round'));
        await tester.ensureVisible(next);
        await tester.pump();
        await tester.tap(next);
        await tester.pump();
        await _pumpUntil(
          tester,
          () => find.byKey(const Key('tug-arena-preparing')).evaluate().isEmpty,
        );
        final second = find.byKey(const Key('tug-answer-second-blue'));
        await tester.scrollUntilVisible(
          second,
          120,
          scrollable: find.byType(Scrollable).first,
        );
        await tester.ensureVisible(second);
        await tester.pump();
        expect(find.byKey(const Key('tug-answer-first-blue')), findsNothing);
        expect(
          tester
              .widget<AcademicOptionContent>(
                find.descendant(
                  of: second,
                  matching: find.byType(AcademicOptionContent),
                ),
              )
              .imageUrl,
          _PagedTugQuestionRepository.secondImage,
        );
        expect(repository.answers, ['first']);
        await tester.tap(second);
        await tester.pump();
        expect(repository.answers, ['first', 'second']);
        await tester.pumpWidget(const SizedBox());
      },
    );
  }

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

class _PagedTugQuestionRepository extends _FakeTugQuestionRepository {
  _PagedTugQuestionRepository(this.authoritative);
  final bool authoritative;
  final answers = <String>[];
  static const firstImage =
      '/recursos/editoriales/11111111-1111-4111-8111-111111111111';
  static const secondImage =
      '/recursos/editoriales/22222222-2222-4222-8222-222222222222';
  PracticeQuestion question(String id, String image) => PracticeQuestion(
    id: id,
    statement: 'Figura $id',
    difficulty: 'BASICO',
    options: [
      PracticeOption(id: '$id-blue', text: 'Azul $id', imageUrl: image),
      PracticeOption(id: '$id-text', text: 'Solo texto $id'),
    ],
    subtopicId: 'figures',
    subtopicName: 'Figuras',
    themeName: 'Opciones',
    area: AcademicArea.mathematics,
  );
  TriviaRushServerState state(PracticeQuestion? question, int index) =>
      TriviaRushServerState(
        attemptId: 'paged-tug',
        status: question == null
            ? TriviaRushAttemptStatus.finished
            : TriviaRushAttemptStatus.active,
        ruleVersion: 1,
        areas: [AcademicArea.mathematics],
        baseDurationSeconds: 60,
        extraTimeSeconds: 0,
        serverNow: DateTime(2026),
        receivedAt: DateTime(2026),
        startedAt: DateTime(2026),
        expiresAt: DateTime(2026, 1, 1, 0, 1),
        score: const TriviaRushScore(),
        currentIndex: index,
        totalQuestions: 2,
        assisted: false,
        comboShieldActive: false,
        secondChanceActive: false,
        eliminatedAnswerIds: {},
        weaknesses: [],
        currentQuestion: question,
      );
  @override
  Future<TriviaRushSession> start(TriviaRushConfig config) async {
    final first = question('first', firstImage);
    return TriviaRushSession(
      attemptId: 'paged-tug',
      questions: [first, if (!authoritative) question('second', secondImage)],
      serverState: authoritative ? state(first, 0) : null,
    );
  }

  @override
  Future<TriviaRushAnswerEvaluation> answer({
    required String attemptId,
    required String questionId,
    required String answerId,
    required int responseTimeSeconds,
  }) async {
    answers.add(questionId);
    return TriviaRushAnswerEvaluation(
      questionId: questionId,
      isCorrect: true,
      correctAnswerId: answerId,
      explanation: 'Figura azul',
      serverState: authoritative
          ? state(
              questionId == 'first' ? question('second', secondImage) : null,
              answers.length,
            )
          : null,
    );
  }
}

class _IllustratedTugQuestionRepository extends _FakeTugQuestionRepository {
  const _IllustratedTugQuestionRepository();
  @override
  Future<TriviaRushSession> start(TriviaRushConfig config) async =>
      const TriviaRushSession(
        attemptId: 'layout-tug',
        questions: [
          PracticeQuestion(
            id: 'figures',
            statement: '¿Qué figura tiene el ancho doble de su altura?',
            difficulty: 'BASICO',
            options: [
              PracticeOption(
                id: 'blue',
                text: 'Rectángulo azul horizontal',
                imageUrl: _PagedTugQuestionRepository.firstImage,
              ),
              PracticeOption(
                id: 'orange',
                text: 'Rectángulo naranja vertical',
                imageUrl: _PagedTugQuestionRepository.secondImage,
              ),
            ],
            subtopicName: 'Opciones con imágenes',
            themeName: 'Geometría',
            area: AcademicArea.mathematics,
          ),
        ],
      );
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
