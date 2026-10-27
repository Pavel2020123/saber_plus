import 'dart:math';
import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:saber_plus/core/feedback/game_audio_feedback.dart';
import 'package:saber_plus/core/network/api_error.dart';
import 'package:saber_plus/core/widgets/academic_option_content.dart';
import 'package:saber_plus/core/widgets/academic_image.dart';
import 'package:saber_plus/features/academic/domain/academic_models.dart';
import 'package:saber_plus/features/games/trivia_rush/domain/trivia_rush_models.dart';
import 'package:saber_plus/features/games/trivia_rush/domain/trivia_rush_repository.dart';
import 'package:saber_plus/features/games/tug_of_war/presentation/tug_local_providers.dart';
import 'package:saber_plus/features/games/tug_of_war/domain/tug_of_war_models.dart';
import 'package:saber_plus/features/games/tug_of_war/domain/tug_local_repository.dart';
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
          tugLocalRepositoryProvider.overrideWithValue(
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
                tugLocalRepositoryProvider.overrideWithValue(
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
              tugLocalRepositoryProvider.overrideWithValue(repository),
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

  testWidgets('vencer una ronda remota no agota el banco sin responder', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(800, 1400));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final repository = _TimeoutTugQuestionRepository();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          tugLocalRepositoryProvider.overrideWithValue(repository),
          tugCpuPlannerProvider.overrideWithValue(
            (_) =>
                const TugCpuTurn(isCorrect: null, responseMilliseconds: 10000),
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
    // The local deadline uses DateTime.now, not the widget scheduler's clock.
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(seconds: 10)),
    );
    await tester.pump(const Duration(seconds: 10));
    await _pumpUntil(
      tester,
      () => find.byKey(const Key('continue-tug-round')).evaluate().isNotEmpty,
    );
    expect(repository.answers, isEmpty);
    expect(repository.timeouts, ['first']);
    final next = find.byKey(const Key('continue-tug-round'));
    await tester.ensureVisible(next);
    await tester.pump();
    await tester.tap(next);
    await tester.pump();
    expect(repository.answers, isEmpty);
    expect(
      find.byKey(const Key('tug-result-view')),
      findsNothing,
      reason: 'El servidor conserva dos preguntas y ninguna respuesta.',
    );
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets(
    'timeout remoto espera confirmación y reintenta sin elegir una respuesta',
    (tester) async {
      final repository = _TimeoutTugQuestionRepository(
        remainingMilliseconds: 0,
        loseTimeoutAck: true,
      );
      await _mountLocalRemote(tester, repository);
      await _pumpUntil(
        tester,
        () => find.byKey(const Key('tug-retry-round')).evaluate().isNotEmpty,
      );
      expect(repository.answers, isEmpty);
      expect(repository.timeouts, ['first']);
      expect(find.byKey(const Key('continue-tug-round')), findsNothing);
      expect(find.byKey(const Key('tug-result-view')), findsNothing);
      final answer = find.byKey(const Key('tug-answer-first-blue'));
      await tester.ensureVisible(answer);
      expect(tester.widget<OutlinedButton>(answer).onPressed, isNull);
      final retry = find.byKey(const Key('tug-retry-round'));
      await tester.ensureVisible(retry);
      await tester.tap(retry);
      await tester.pump();
      await _pumpUntil(
        tester,
        () => find.byKey(const Key('continue-tug-round')).evaluate().isNotEmpty,
      );
      expect(repository.timeouts, ['first', 'first']);
      expect(repository.answers, isEmpty);
      final next = find.byKey(const Key('continue-tug-round'));
      await tester.ensureVisible(next);
      await tester.tap(next);
      await tester.pump();
      expect(find.text('Figura second'), findsOneWidget);
      expect(find.byKey(const Key('tug-result-view')), findsNothing);
      await tester.pumpWidget(const SizedBox());
    },
  );

  testWidgets(
    'timeout de última pregunta muestra resultado solo tras el feedback',
    (tester) async {
      final repository = _TimeoutTugQuestionRepository(
        remainingMilliseconds: 0,
        lastQuestion: true,
      );
      await _mountLocalRemote(tester, repository);
      await _pumpUntil(
        tester,
        () => find.byKey(const Key('continue-tug-round')).evaluate().isNotEmpty,
      );
      expect(find.byKey(const Key('tug-result-view')), findsNothing);
      final next = find.byKey(const Key('continue-tug-round'));
      await tester.ensureVisible(next);
      await tester.tap(next);
      await tester.pump();
      expect(find.byKey(const Key('tug-result-view')), findsOneWidget);
      expect(repository.timeouts, ['first']);
      expect(repository.answers, isEmpty);
      expect(repository.abandonCalls, 0);
      await tester.pumpWidget(const SizedBox());
    },
  );

  for (final lostAck in [false, true]) {
    testWidgets(
      'respuesta ${lostAck ? 'con ACK perdido' : 'en vuelo'} conserva su envío al vencer',
      (tester) async {
        final repository = _TimeoutTugQuestionRepository(
          remainingMilliseconds: 300,
          loseAnswerAck: lostAck,
        );
        if (!lostAck) {
          repository.pendingAnswer = Completer<TriviaRushAnswerEvaluation>();
        }
        await _mountLocalRemote(tester, repository);
        final answer = find.byKey(const Key('tug-answer-first-blue'));
        await tester.ensureVisible(answer);
        await tester.tap(answer);
        await tester.pump();
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 350)),
        );
        await tester.pump(const Duration(milliseconds: 400));
        expect(repository.timeouts, isEmpty);
        expect(find.byKey(const Key('continue-tug-round')), findsNothing);
        if (lostAck) {
          final retry = find.byKey(const Key('tug-retry-round'));
          await tester.ensureVisible(retry);
          await tester.tap(retry);
        } else {
          repository.pendingAnswer!.complete(
            TriviaRushAnswerEvaluation(
              questionId: 'first',
              isCorrect: true,
              correctAnswerId: 'first-blue',
              explanation: 'Figura azul',
              serverState: repository.state(
                repository.question(
                  'second',
                  _PagedTugQuestionRepository.secondImage,
                ),
                1,
              ),
            ),
          );
        }
        await tester.pump();
        await _pumpUntil(
          tester,
          () =>
              find.byKey(const Key('continue-tug-round')).evaluate().isNotEmpty,
        );
        expect(repository.answers, lostAck ? ['first', 'first'] : ['first']);
        expect(repository.timeouts, isEmpty);
        final next = find.byKey(const Key('continue-tug-round'));
        await tester.ensureVisible(next);
        await tester.tap(next);
        await tester.pump();
        expect(find.text('Figura second'), findsOneWidget);
        await tester.pumpWidget(const SizedBox());
      },
    );
  }

  testWidgets(
    'pausa local remota conserva el reloj y confirma pausa y reanudación',
    (tester) async {
      final repository = _TimeoutTugQuestionRepository();
      await _mountLocalRemote(tester, repository);
      await tester.tap(find.byIcon(Icons.close_rounded));
      await tester.pump();
      expect(repository.pauseChanges, [true]);
      await tester.pump(const Duration(seconds: 5));
      expect(repository.timeouts, isEmpty);
      expect(find.text('10 s'), findsOneWidget);
      await tester.tap(find.widgetWithText(TextButton, 'Continuar'));
      await tester.pump();
      expect(repository.pauseChanges, [true, false]);
      expect(repository.version, 3);
      final answer = find.byKey(const Key('tug-answer-first-blue'));
      await tester.ensureVisible(answer);
      expect(tester.widget<OutlinedButton>(answer).onPressed, isNotNull);
      expect(repository.answers, isEmpty);
      await tester.pumpWidget(const SizedBox());
    },
  );

  testWidgets(
    'reanudar tras perder ACK de pausa concilia la misma versión antes de continuar',
    (tester) async {
      final repository = _TimeoutTugQuestionRepository(losePauseAck: true);
      await _mountLocalRemote(tester, repository);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      await tester.pump();
      expect(repository.pauseChanges, [true]);
      expect(find.byKey(const Key('tug-retry-round')), findsOneWidget);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pump();
      await tester.pump();
      expect(repository.pauseChanges, [true, true, false]);
      expect(repository.pauseVersions, [1, 1, 2]);
      expect(repository.version, 3);
      expect(find.byKey(const Key('tug-retry-round')), findsNothing);
      expect(repository.timeouts, isEmpty);
      await tester.pumpWidget(const SizedBox());
    },
  );

  testWidgets(
    'respuesta confirmada en segundo plano permite terminar la ronda CPU al volver',
    (tester) async {
      final repository = _TimeoutTugQuestionRepository();
      repository.pendingAnswer = Completer<TriviaRushAnswerEvaluation>();
      await _mountLocalRemote(
        tester,
        repository,
        cpuTurn: const TugCpuTurn(isCorrect: false, responseMilliseconds: 100),
      );
      final answer = find.byKey(const Key('tug-answer-first-blue'));
      await tester.ensureVisible(answer);
      await tester.tap(answer);
      await tester.pump();
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      await tester.pump();
      repository.pendingAnswer!.complete(
        TriviaRushAnswerEvaluation(
          questionId: 'first',
          isCorrect: true,
          correctAnswerId: 'first-blue',
          explanation: 'Azul',
          serverState: repository.state(
            repository.question(
              'second',
              _PagedTugQuestionRepository.secondImage,
            ),
            1,
          ),
        ),
      );
      await tester.pump();
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 120));
      await _pumpUntil(
        tester,
        () => find.byKey(const Key('continue-tug-round')).evaluate().isNotEmpty,
      );
      expect(
        repository.pauseChanges,
        isEmpty,
        reason: 'El servidor ya avanzó: no pausar la pregunta anterior.',
      );
      expect(repository.timeouts, isEmpty);
      expect(repository.answers, ['first']);
      await tester.pumpWidget(const SizedBox());
    },
  );

  testWidgets('el diálogo de salida pausa el reloj y la respuesta de la CPU', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          tugLocalRepositoryProvider.overrideWithValue(
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

Future<void> _mountLocalRemote(
  WidgetTester tester,
  _TimeoutTugQuestionRepository repository, {
  TugCpuTurn cpuTurn = const TugCpuTurn(
    isCorrect: null,
    responseMilliseconds: 10000,
  ),
}) async {
  await tester.binding.setSurfaceSize(const Size(800, 1400));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        tugLocalRepositoryProvider.overrideWithValue(repository),
        tugCpuPlannerProvider.overrideWithValue((_) => cpuTurn),
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

class _TimeoutTugQuestionRepository extends _PagedTugQuestionRepository
    implements TugLocalRepository {
  _TimeoutTugQuestionRepository({
    this.remainingMilliseconds = 10000,
    this.lastQuestion = false,
    this.loseTimeoutAck = false,
    this.loseAnswerAck = false,
    this.losePauseAck = false,
  }) : super(true);

  final int remainingMilliseconds;
  final bool lastQuestion;
  bool loseTimeoutAck;
  bool loseAnswerAck;
  bool losePauseAck;
  final timeouts = <String>[];
  final started = <String>[];
  final pauseChanges = <bool>[];
  final pauseVersions = <int>[];
  int abandonCalls = 0;
  Completer<TriviaRushAnswerEvaluation>? pendingAnswer;
  TriviaRushAnswerEvaluation? savedAnswer;
  int version = 1;
  bool paused = false;

  TriviaRushSession sessionFor(PracticeQuestion? current, int index) =>
      TriviaRushSession(
        attemptId: 'paged-tug',
        questions: [?current],
        serverState: state(current, index),
      );

  @override
  Future<TugLocalRound> beginRound(String attemptId, String questionId) async {
    started.add(questionId);
    return TugLocalRound(
      session: sessionFor(
        question(questionId, _PagedTugQuestionRepository.firstImage),
        questionId == 'first' ? 0 : 1,
      ),
      version: version,
      paused: paused,
      remainingMilliseconds: questionId == 'first'
          ? remainingMilliseconds
          : 10000,
    );
  }

  @override
  Future<TugLocalRound> setPaused({
    required String attemptId,
    required String questionId,
    required int version,
    required bool paused,
  }) async {
    pauseChanges.add(paused);
    pauseVersions.add(version);
    if (version == this.version && this.paused != paused) {
      this.version++;
      this.paused = paused;
    }
    if (losePauseAck) {
      losePauseAck = false;
      throw const ApiError(
        code: 'network_timeout',
        message: 'Confirmación pendiente.',
      );
    }
    return TugLocalRound(
      session: sessionFor(
        question(questionId, _PagedTugQuestionRepository.firstImage),
        0,
      ),
      version: this.version,
      paused: this.paused,
      remainingMilliseconds: remainingMilliseconds,
    );
  }

  @override
  Future<TriviaRushSession> expireRound(
    String attemptId,
    String questionId,
  ) async {
    timeouts.add(questionId);
    if (loseTimeoutAck) {
      loseTimeoutAck = false;
      throw const ApiError(
        code: 'network_unavailable',
        message: 'Sin conexión.',
      );
    }
    return sessionFor(
      lastQuestion
          ? null
          : question('second', _PagedTugQuestionRepository.secondImage),
      lastQuestion ? 2 : 1,
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
    if (pendingAnswer != null) return pendingAnswer!.future;
    savedAnswer ??= TriviaRushAnswerEvaluation(
      questionId: questionId,
      isCorrect: true,
      correctAnswerId: answerId,
      explanation: 'Figura azul',
      serverState: state(
        question('second', _PagedTugQuestionRepository.secondImage),
        1,
      ),
    );
    if (loseAnswerAck) {
      loseAnswerAck = false;
      throw const ApiError(
        code: 'network_timeout',
        message: 'Confirmación pendiente.',
      );
    }
    return savedAnswer!;
  }

  @override
  Future<void> abandon(String attemptId) async {
    abandonCalls++;
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
