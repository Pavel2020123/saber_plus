import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:saber_plus/core/feedback/game_audio_feedback.dart';
import 'package:saber_plus/features/academic/domain/academic_models.dart';
import 'package:saber_plus/features/games/ghost_duel/presentation/ghost_character.dart';
import 'package:saber_plus/features/games/ghost_duel/presentation/ghost_race_panel.dart';
import 'package:saber_plus/features/games/trivia_rush/domain/trivia_rush_models.dart';
import 'package:saber_plus/features/games/trivia_rush/domain/trivia_rush_repository.dart';
import 'package:saber_plus/features/games/trivia_rush/presentation/trivia_rush_hud.dart';
import 'package:saber_plus/features/games/trivia_rush/presentation/trivia_rush_page.dart';
import 'package:saber_plus/features/games/trivia_rush/presentation/trivia_rush_providers.dart';
import 'package:saber_plus/features/practice/domain/practice_models.dart';

void main() {
  testWidgets(
    'the ghost moves, pauses in background and respects reduced motion',
    (tester) async {
      Widget app({bool reduced = false, bool tickers = true}) => MaterialApp(
        home: MediaQuery(
          data: MediaQueryData(disableAnimations: reduced),
          child: TickerMode(
            enabled: tickers,
            child: const Center(child: GhostCharacter()),
          ),
        ),
      );
      double phase() => tester
          .widgetList<CustomPaint>(find.byType(CustomPaint))
          .map((widget) => widget.painter)
          .whereType<GhostCharacterPainter>()
          .single
          .phase;
      await tester.pumpWidget(app());
      await tester.pump(const Duration(milliseconds: 260));
      final moving = phase();
      expect(moving, greaterThan(0));
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      await tester.pump(const Duration(seconds: 1));
      expect(phase(), moving);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 260));
      expect(phase(), isNot(moving));
      await tester.pumpWidget(app(tickers: false));
      final hidden = phase();
      await tester.pump(const Duration(seconds: 1));
      expect(phase(), hidden);
      await tester.pumpWidget(app(reduced: true));
      expect(phase(), .25);
      await tester.pump(const Duration(seconds: 1));
      expect(phase(), .25);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );

  testWidgets('a covering route pauses decorative ghost motion', (
    tester,
  ) async {
    final navigatorKey = GlobalKey<NavigatorState>();
    await tester.pumpWidget(
      MaterialApp(
        navigatorKey: navigatorKey,
        home: const Scaffold(body: GhostCharacter()),
      ),
    );
    await tester.pump(const Duration(milliseconds: 200));
    double phase() => tester
        .widgetList<CustomPaint>(find.byType(CustomPaint, skipOffstage: false))
        .map((widget) => widget.painter)
        .whereType<GhostCharacterPainter>()
        .single
        .phase;
    navigatorKey.currentState!.push(
      MaterialPageRoute<void>(
        builder: (_) => const Scaffold(body: Text('Otro contenido')),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    final covered = phase();
    await tester.pump(const Duration(seconds: 2));
    expect(phase(), covered);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('lanes share a points scale even above the previous record', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: GhostRacePanel(
          currentScore: 1600,
          ghostScore: 1500,
          recordScore: 1000,
        ),
      ),
    );
    final player = tester.widget<AnimatedAlign>(
      find.byKey(const Key('ghost-player-marker')),
    );
    final ghost = tester.widget<AnimatedAlign>(
      find.byKey(const Key('ghost-record-marker')),
    );
    final playerX = player.alignment.resolve(TextDirection.ltr).x;
    final ghostX = ghost.alignment.resolve(TextDirection.ltr).x;
    expect(playerX, greaterThan(ghostX));
    expect(playerX, lessThan(1));
    expect(find.text('Tu récord anterior · 1000 pts'), findsOneWidget);
    expect(
      tester.widget<GhostCharacter>(find.byType(GhostCharacter)).mood,
      GhostMood.surprised,
    );
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets(
    'first round creates a ghost rather than inventing a rival score',
    (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: GhostRacePanel(
            currentScore: 100,
            ghostScore: null,
            recordScore: null,
          ),
        ),
      );
      expect(
        find.text('Primera partida: estás creando tu fantasma'),
        findsOneWidget,
      );
      expect(find.byKey(const Key('ghost-record-marker')), findsNothing);
      expect(
        tester.widget<GhostCharacter>(find.byType(GhostCharacter)).forming,
        isTrue,
      );
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );

  testWidgets(
    'confirmed answers enable the next question without an animation delay',
    (tester) async {
      final repository = _TwoQuestionsRepository();
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            triviaRushRepositoryProvider.overrideWithValue(repository),
            gameAudioFeedbackProvider.overrideWithValue(_SilentAudio()),
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
      expect(find.byTooltip('Abandonar partida'), findsOneWidget);
      await tester.tap(find.byKey(const Key('trivia-answer-a1')));
      await tester.pump();
      expect(find.text('Pregunta 2'), findsOneWidget);
      expect(find.text('¡Correcto! +100 puntos'), findsOneWidget);
      expect(
        tester
            .widget<OutlinedButton>(
              find.descendant(
                of: find.byKey(const Key('trivia-answer-a2')),
                matching: find.byType(OutlinedButton),
              ),
            )
            .onPressed,
        isNotNull,
      );
      await tester.tap(find.byKey(const Key('trivia-answer-a2')));
      await tester.pump();
      expect(repository.answers, 2);
      expect(find.byKey(const Key('trivia-result-view')), findsOneWidget);
    },
  );

  testWidgets(
    'confirmed shield activation is visible on the combo and does not block answers',
    (tester) async {
      tester.view.physicalSize = const Size(800, 1100);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            triviaRushRepositoryProvider.overrideWithValue(
              _TwoQuestionsRepository(),
            ),
            gameAudioFeedbackProvider.overrideWithValue(_SilentAudio()),
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
      await tester.tap(find.byKey(const Key('trivia-booster-comboShield')));
      await tester.pump();
      expect(find.text('PROTEGIDO'), findsOneWidget);
      expect(
        find.text('Escudo activo: tu próximo error no rompe el combo.'),
        findsOneWidget,
      );
      await tester.tap(find.byKey(const Key('trivia-answer-a1')));
      await tester.pump();
      expect(find.text('Pregunta 2'), findsOneWidget);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );

  for (final dark in [false, true]) {
    testWidgets('ghost and HUD fit a small phone with enlarged text ($dark)', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(320, 780);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(
            useMaterial3: true,
            brightness: dark ? Brightness.dark : Brightness.light,
          ),
          home: MediaQuery(
            data: const MediaQueryData(
              textScaler: TextScaler.linear(1.6),
              disableAnimations: true,
            ),
            child: Scaffold(
              body: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      const GhostCharacter(
                        size: 126,
                        mood: GhostMood.celebrating,
                      ),
                      TriviaRushHud(
                        seconds: 7,
                        score: const TriviaRushScore(points: 2400, combo: 10),
                        shieldActive: true,
                        assisted: true,
                        feedback: '¡Correcto! +400 puntos',
                      ),
                      const SizedBox(height: 14),
                      const GhostRacePanel(
                        currentScore: 2400,
                        ghostScore: 2000,
                        recordScore: 3000,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    });
  }

  testWidgets('capture detailed ghost and trivia UI for visual review', (
    tester,
  ) async {
    if (!const bool.fromEnvironment('CAPTURE_GAME_VISUALS')) return;
    tester.view.physicalSize = const Size(420, 940);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final boundary = GlobalKey();
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(
          useMaterial3: true,
          scaffoldBackgroundColor: Colors.white,
          colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xff65508c)),
        ),
        home: RepaintBoundary(
          key: boundary,
          child: Scaffold(
            appBar: AppBar(title: const Text('Duelo fantasma')),
            body: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  const GhostCharacter(size: 120, mood: GhostMood.celebrating),
                  const SizedBox(height: 12),
                  const TriviaRushHud(
                    seconds: 42,
                    score: TriviaRushScore(points: 1200, combo: 6),
                    shieldActive: false,
                    assisted: false,
                    feedback: '¡Correcto! +300 puntos',
                  ),
                  const SizedBox(height: 14),
                  const GhostRacePanel(
                    currentScore: 1200,
                    ghostScore: 800,
                    recordScore: 2100,
                  ),
                  const SizedBox(height: 20),
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text('Matemáticas · Proporcionalidad'),
                  ),
                  const Card(
                    child: Padding(
                      padding: EdgeInsets.all(18),
                      child: Text(
                        'Si 3 cuadernos cuestan 12.000 pesos, ¿cuánto cuestan 5?',
                        style: TextStyle(fontSize: 20),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  OutlinedButton(
                    onPressed: () {},
                    child: const Align(
                      alignment: Alignment.centerLeft,
                      child: Text('20.000 pesos'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 400));
    expect(tester.takeException(), isNull);
    final render =
        boundary.currentContext!.findRenderObject()! as RenderRepaintBoundary;
    await tester.runAsync(() async {
      final image = await render.toImage(pixelRatio: 2);
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      final output = File('build/test-artifacts/ghost-trivia-preview.png');
      await output.parent.create(recursive: true);
      await output.writeAsBytes(bytes!.buffer.asUint8List());
      image.dispose();
    });
    await tester.pumpWidget(const SizedBox.shrink());
  });
}

class _SilentAudio implements GameAudioFeedback {
  @override
  Future<void> play(GameSound sound) async {}
}

class _TwoQuestionsRepository implements TriviaRushRepository {
  int answers = 0;
  @override
  Future<TriviaRushSession> start(TriviaRushConfig config) async =>
      TriviaRushSession(
        attemptId: 'round',
        questions: [
          for (var i = 1; i <= 2; i++)
            PracticeQuestion(
              id: 'q$i',
              statement: 'Pregunta $i',
              difficulty: 'BASICA',
              options: [
                PracticeOption(id: 'a$i', text: 'Correcta'),
                PracticeOption(id: 'b$i', text: 'Otra'),
              ],
              subtopicId: 'sum',
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
  }) async {
    answers++;
    return TriviaRushAnswerEvaluation(
      questionId: questionId,
      isCorrect: true,
      correctAnswerId: answerId,
      explanation: 'Correcto',
    );
  }

  @override
  Future<TriviaRushBoosterActivation> activateBooster({
    required String attemptId,
    required String questionId,
    required TriviaRushBooster booster,
  }) async => const TriviaRushBoosterActivation();
}
