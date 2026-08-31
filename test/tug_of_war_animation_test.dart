import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:saber_plus/features/games/tug_of_war/domain/tug_of_war_models.dart';
import 'package:saber_plus/features/games/tug_of_war/presentation/animation/tug_animation_cue.dart';
import 'package:saber_plus/features/games/tug_of_war/presentation/animation/tug_arena.dart';
import 'package:saber_plus/features/games/tug_of_war/presentation/animation/tug_arena_painters.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'movimiento reducido completa una señal una vez y emite sus sonidos',
    (tester) async {
      final completed = <int>[];
      final sounds = <TugArenaSoundCue>[];

      await tester.pumpWidget(
        _arenaApp(
          disableAnimations: true,
          onSequenceCompleted: completed.add,
          onSoundCue: sounds.add,
        ),
      );

      const cue = TugAnimationCue(
        id: 1,
        fromPosition: 0,
        toPosition: 2,
        outcome: TugRoundOutcome.strongPlayer,
        bothCorrect: false,
      );
      await tester.pumpWidget(
        _arenaApp(
          disableAnimations: true,
          animationCue: cue,
          ropePosition: 2,
          onSequenceCompleted: completed.add,
          onSoundCue: sounds.add,
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(seconds: 2));

      expect(completed, [cue.id]);
      expect(sounds, [TugArenaSoundCue.ropeStrain, TugArenaSoundCue.pull]);
    },
  );

  testWidgets('una señal pausada solo completa después de reanudar', (
    tester,
  ) async {
    final completed = <int>[];

    await tester.pumpWidget(
      _arenaApp(disableAnimations: true, onSequenceCompleted: completed.add),
    );
    await tester.pump();

    await tester.pumpWidget(
      _arenaApp(paused: true, onSequenceCompleted: completed.add),
    );
    const cue = TugAnimationCue(
      id: 20,
      fromPosition: 0,
      toPosition: -2,
      outcome: TugRoundOutcome.strongCpu,
      bothCorrect: false,
    );
    await tester.pumpWidget(
      _arenaApp(
        paused: true,
        animationCue: cue,
        ropePosition: -2,
        onSequenceCompleted: completed.add,
      ),
    );
    await tester.pump(const Duration(seconds: 2));

    expect(completed, isEmpty);

    await tester.pumpWidget(
      _arenaApp(
        animationCue: cue,
        ropePosition: -2,
        onSequenceCompleted: completed.add,
      ),
    );
    await tester.pump(const Duration(milliseconds: 981));
    await tester.pump();

    expect(completed, [cue.id]);
  });

  testWidgets('dos identificadores consecutivos ejecutan dos secuencias', (
    tester,
  ) async {
    final completed = <int>[];

    await tester.pumpWidget(
      _arenaApp(disableAnimations: true, onSequenceCompleted: completed.add),
    );

    const firstCue = TugAnimationCue(
      id: 31,
      fromPosition: 0,
      toPosition: 1,
      outcome: TugRoundOutcome.quickPlayer,
      bothCorrect: true,
    );
    await tester.pumpWidget(
      _arenaApp(
        disableAnimations: true,
        animationCue: firstCue,
        ropePosition: 1,
        onSequenceCompleted: completed.add,
      ),
    );
    await tester.pump();

    const secondCue = TugAnimationCue(
      id: 32,
      fromPosition: 1,
      toPosition: 0,
      outcome: TugRoundOutcome.quickCpu,
      bothCorrect: true,
    );
    await tester.pumpWidget(
      _arenaApp(
        disableAnimations: true,
        animationCue: secondCue,
        onSequenceCompleted: completed.add,
      ),
    );
    await tester.pump();

    expect(completed, [firstCue.id, secondCue.id]);
  });

  testWidgets('el ciclo de vida pausa y reanuda un tirón en progreso', (
    tester,
  ) async {
    final completed = <int>[];
    await tester.pumpWidget(_arenaApp(onSequenceCompleted: completed.add));
    await tester.pump(const Duration(milliseconds: 851));

    const cue = TugAnimationCue(
      id: 35,
      fromPosition: 0,
      toPosition: 2,
      outcome: TugRoundOutcome.strongPlayer,
      bothCorrect: false,
    );
    await tester.pumpWidget(
      _arenaApp(
        animationCue: cue,
        ropePosition: 2,
        onSequenceCompleted: completed.add,
      ),
    );
    await tester.pump(const Duration(milliseconds: 250));

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    await tester.pump(const Duration(seconds: 2));
    expect(completed, isEmpty);

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 750));
    await tester.pump();

    expect(completed, [cue.id]);
  });

  testWidgets('el nudo recorre una posición intermedia antes de llegar a +2', (
    tester,
  ) async {
    final completed = <int>[];
    await tester.pumpWidget(_arenaApp(onSequenceCompleted: completed.add));
    await tester.pump(const Duration(milliseconds: 851));

    const cue = TugAnimationCue(
      id: 36,
      fromPosition: 0,
      toPosition: 2,
      outcome: TugRoundOutcome.strongPlayer,
      bothCorrect: false,
    );
    await tester.pumpWidget(
      _arenaApp(
        animationCue: cue,
        ropePosition: 2,
        onSequenceCompleted: completed.add,
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    final intermediate =
        tester
                .widget<CustomPaint>(find.byKey(const Key('tug-rope-painter')))
                .painter!
            as TugRopePainter;
    expect(intermediate.ropePosition, greaterThan(0));
    expect(intermediate.ropePosition, lessThan(2));
    expect(completed, isEmpty);

    await tester.pump(const Duration(milliseconds: 500));
    final settled =
        tester
                .widget<CustomPaint>(find.byKey(const Key('tug-rope-painter')))
                .painter!
            as TugRopePainter;
    expect(settled.ropePosition, closeTo(2, 0.01));
    expect(completed, [cue.id]);
  });

  testWidgets('la celebración final termina después del tirón decisivo', (
    tester,
  ) async {
    final completed = <int>[];
    await tester.pumpWidget(_arenaApp(onSequenceCompleted: completed.add));
    await tester.pump(const Duration(milliseconds: 851));

    const cue = TugAnimationCue(
      id: 37,
      fromPosition: 2,
      toPosition: 4,
      outcome: TugRoundOutcome.strongPlayer,
      bothCorrect: false,
      winner: TugWinner.player,
    );
    await tester.pumpWidget(
      _arenaApp(
        animationCue: cue,
        ropePosition: 4,
        onSequenceCompleted: completed.add,
      ),
    );
    await tester.pump();
    await tester.pump(cue.actionDuration);
    expect(completed, isEmpty);

    await tester.pump(const Duration(milliseconds: 899));
    expect(completed, isEmpty);
    await tester.pump(const Duration(milliseconds: 2));
    expect(completed, [cue.id]);
  });

  testWidgets('la arena se adapta a anchos pequeños y orientación horizontal', (
    tester,
  ) async {
    for (final size in [const Size(320, 568), const Size(640, 360)]) {
      await tester.pumpWidget(_arenaApp(size: size, disableAnimations: true));
      await tester.pump();
      expect(tester.takeException(), isNull, reason: '$size');
    }
  });

  test('un tirón fuerte limitado de 3 a 4 conserva fuerza y duración', () {
    const cue = TugAnimationCue(
      id: 40,
      fromPosition: 3,
      toPosition: TugMatchProgress.winningPosition,
      outcome: TugRoundOutcome.strongPlayer,
      bothCorrect: false,
      winner: TugWinner.player,
    );

    expect(cue.ropeDelta, 1);
    expect(cue.isStrongPull, isTrue);
    expect(cue.actionDuration, const Duration(milliseconds: 980));
    expect(cue.duration, const Duration(milliseconds: 1880));
  });

  test('los tres recursos visuales de la arena están empaquetados', () async {
    const assets = [
      'assets/images/games/tug_of_war/arena_background.png',
      'assets/images/games/tug_of_war/player_fighter.png',
      'assets/images/games/tug_of_war/cpu_fighter.png',
    ];

    for (final asset in assets) {
      final data = await rootBundle.load(asset);
      expect(data.lengthInBytes, greaterThan(0), reason: asset);
    }
  });
}

Widget _arenaApp({
  TugAnimationCue? animationCue,
  int ropePosition = 0,
  bool paused = false,
  bool disableAnimations = false,
  Size size = const Size(390, 844),
  ValueChanged<int>? onReady,
  ValueChanged<int>? onSequenceCompleted,
  ValueChanged<TugArenaSoundCue>? onSoundCue,
}) => MaterialApp(
  home: MediaQuery(
    data: MediaQueryData(size: size, disableAnimations: disableAnimations),
    child: Scaffold(
      body: Align(
        alignment: Alignment.topCenter,
        child: SizedBox(
          width: size.width,
          child: TugArena(
            key: const Key('tested-tug-arena'),
            roundId: 0,
            ropePosition: ropePosition,
            playerAnswered: false,
            cpuAnswered: false,
            animationCue: animationCue,
            paused: paused,
            onReady: onReady ?? (_) {},
            onSequenceCompleted: onSequenceCompleted ?? (_) {},
            onSoundCue: onSoundCue ?? (_) {},
          ),
        ),
      ),
    ),
  ),
);
