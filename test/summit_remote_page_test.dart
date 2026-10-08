import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:saber_plus/features/academic/domain/academic_models.dart';
import 'package:saber_plus/features/games/summit/data/remote_summit_repository.dart';
import 'package:saber_plus/features/games/summit/presentation/summit_page.dart';
import 'package:saber_plus/features/games/summit/presentation/summit_providers.dart';
import 'package:saber_plus/features/study/domain/study_models.dart';
import 'package:saber_plus/features/study/presentation/study_providers.dart';
import 'package:saber_plus/features/ranking/domain/competitive_ranking_models.dart';
import 'package:saber_plus/features/ranking/presentation/competitive_ranking_page.dart';
import 'package:saber_plus/features/ranking/presentation/competitive_ranking_providers.dart';
import 'competitive_ranking_providers_test.dart' show TestCompetitiveRepository;
import 'helpers/competitive_ranking_fixture.dart';

import 'remote_summit_repository_test.dart' as fixture;

Map<String, dynamic> state({
  int count = 0,
  String status = 'ACTIVO',
  bool images = false,
}) {
  final result = fixture.state(count: count, status: status);
  if (!images && result['pregunta'] is Map) {
    (result['pregunta'] as Map).remove('imagenUrl');
    ((result['pregunta'] as Map)['caso'] as Map).remove('imagenUrl');
  }
  return result;
}

Widget app(RemoteSummitRepository repo, {double textScale = 1}) =>
    ProviderScope(
      overrides: [
        summitRepositoryProvider.overrideWithValue(repo),
        studyCatalogProvider(AcademicArea.mathematics).overrideWith(
          (ref) async => StudyCatalog.demo(AcademicArea.mathematics),
        ),
      ],
      child: MaterialApp(
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: TextScaler.linear(textScale)),
          child: child!,
        ),
        home: const SummitPage(),
      ),
    );

Future<void> tap(WidgetTester tester, Finder finder) async {
  if (finder.evaluate().isEmpty) {
    await tester.scrollUntilVisible(
      finder,
      150,
      scrollable: find.byType(Scrollable).first,
    );
  }
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

void main() {
  testWidgets(
    'competitive setup remains usable on small screen with large text',
    (tester) async {
      tester.view.physicalSize = const Size(320, 568);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final h = fixture.Harness();
      h.handler = (_) => null;
      await tester.pumpWidget(app(h.repo(), textScale: 2));
      await tester.pumpAndSettle();
      // The whole tile may be taller than the viewport at 2x text. Scroll to
      // and tap the actual switch rather than its off-screen semantic center.
      await tap(
        tester,
        find.descendant(
          of: find.byKey(const Key('summit-competitive-mode')),
          matching: find.byType(Switch),
        ),
      );
      expect(tester.takeException(), null);
      expect(
        tester
            .widget<SwitchListTile>(
              find.byKey(const Key('summit-competitive-mode')),
            )
            .value,
        true,
      );
      h.handler = (_) => {...state(), 'competitive': true};
      await tap(tester, find.byKey(const Key('summit-start')));
      expect(h.requests.last.data, {
        'area': 'MATEMATICAS',
        'competitive': true,
      });
      expect(tester.takeException(), null);
    },
  );
  testWidgets('competitive switch requests admission but server owns mode', (
    tester,
  ) async {
    final h = fixture.Harness();
    h.handler = (_) => null;
    await tester.pumpWidget(app(h.repo()));
    await tester.pumpAndSettle();
    await tap(tester, find.byKey(const Key('summit-competitive-mode')));
    h.handler = (_) => {...state(), 'competitive': true};
    await tap(tester, find.byKey(const Key('summit-start')));
    expect(h.requests.last.data, {'area': 'MATEMATICAS', 'competitive': true});
    expect(
      find.text('PARTIDA COMPETITIVA · XP confirmada solo por el servidor'),
      findsOneWidget,
    );
    expect(find.byKey(const Key('summit-competitive-mode')), findsNothing);
  });
  testWidgets(
    'disabled competition explains rejection without fallback; normal is explicit',
    (tester) async {
      final h = fixture.Harness();
      h.handler = (_) => null;
      await tester.pumpWidget(app(h.repo()));
      await tester.pumpAndSettle();
      await tap(tester, find.byKey(const Key('summit-competitive-mode')));
      h.handler = (o) => throw DioException(
        requestOptions: o,
        response: Response(
          requestOptions: o,
          statusCode: 403,
          data: {'code': 'COMPETITIVE_SOLO_DISABLED', 'message': 'Not enabled'},
        ),
      );
      await tap(tester, find.byKey(const Key('summit-start')));
      expect(
        find.textContaining('todavía no admite partidas competitivas'),
        findsOneWidget,
      );
      expect(h.requests.where((o) => o.method == 'POST'), hasLength(1));
      await tap(tester, find.byKey(const Key('summit-competitive-mode')));
      h.handler = (_) => state();
      await tap(tester, find.byKey(const Key('summit-start')));
      expect(h.requests.last.data, {'area': 'MATEMATICAS'});
      expect(
        find.text('PARTIDA EN LÍNEA · Sin XP ni cambios en tu diagnóstico'),
        findsOneWidget,
      );
    },
  );
  testWidgets('restored competitive abandonment warns about server rules', (
    tester,
  ) async {
    final h = fixture.Harness();
    h.handler = (_) => {...state(), 'competitive': true};
    await tester.pumpWidget(app(h.repo()));
    await tester.pumpAndSettle();
    await tap(tester, find.byTooltip('Abandonar ascenso'));
    expect(
      find.textContaining('reglas competitivas de abandono'),
      findsOneWidget,
    );
    await tap(tester, find.text('Continuar jugando'));
    expect(h.requests.any((o) => o.method == 'POST'), false);
  });
  testWidgets(
    'competitive terminal opens Summit ranking, never displays invented XP',
    (tester) async {
      final h = fixture.Harness();
      h.handler = (_) => {
        ...state(count: 5, status: 'VICTORIA'),
        'competitive': true,
      };
      final ranking = TestCompetitiveRepository(
        (q) async => fixtureBoard(game: q.game, season: q.season),
      );
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            summitRepositoryProvider.overrideWithValue(h.repo()),
            competitiveRankingRepositoryProvider.overrideWithValue(ranking),
          ],
          child: const MaterialApp(home: SummitPage()),
        ),
      );
      await tester.pumpAndSettle();
      await tap(tester, find.byKey(const Key('summit-open-ranking')));
      expect(find.byType(CompetitiveRankingPage), findsOneWidget);
      expect(ranking.queries.single.game, CompetitiveGame.summit);
      expect(h.requests.every((o) => o.method == 'GET'), true);
    },
  );
  testWidgets('startup error blocks start and recovers without demo fallback', (
    tester,
  ) async {
    final h = fixture.Harness();
    final r = h.repo();
    h.handler = (o) => throw h.lost(o);
    await tester.pumpWidget(app(r));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('summit-start')), findsNothing);
    expect(find.textContaining('DEMOSTRACIÓN'), findsNothing);
    h.handler = (_) => null;
    await tap(tester, find.byKey(const Key('summit-sync')));
    await tester.scrollUntilVisible(find.byKey(const Key('summit-start')), 150);
    expect(find.byKey(const Key('summit-start')), findsOneWidget);
    expect(find.text('Tema'), findsOneWidget);
    expect(h.requests.every((o) => o.method == 'GET'), true);
  });

  testWidgets(
    'restores pending selection and retries identical submission after reopening',
    (tester) async {
      final h = fixture.Harness();
      final original = (await tester.runAsync(h.started))!;
      h.handler = (o) => throw h.lost(o);
      await tester.runAsync(
        () => expectLater(fixture.answer(original), throwsA(anything)),
      );
      original.dispose();
      h.handler = (_) => state();
      final r = h.repo();
      await tester.pumpWidget(app(r));
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.byKey(const Key('summit-answer')),
        150,
      );
      expect(find.text('Reintentar envío'), findsOneWidget);
      final other = tester.widget<OutlinedButton>(
        find.byKey(const Key('summit-option-no')),
      );
      expect(other.onPressed, null);
      h.handler = (_) => state(count: 1);
      await tap(tester, find.byKey(const Key('summit-answer')));
      expect(find.text('¡Acierto! Subes un escalón.'), findsOneWidget);
      final answers = h.requests
          .where((o) => o.path.endsWith('/respuestas'))
          .toList();
      expect(answers, hasLength(2));
      expect(answers[0].data, answers[1].data);
      expect(r.current!.progress.answered, 1);
    },
  );

  testWidgets('expiry displays expiry, not wrong answer or fake victory', (
    tester,
  ) async {
    final h = fixture.Harness();
    h.handler = (_) => state();
    final r = h.repo();
    await tester.pumpWidget(app(r));
    await tester.pumpAndSettle();
    await tap(tester, find.byKey(const Key('summit-option-yes')));
    h.handler = (_) => state(status: 'EXPIRADO');
    await tap(tester, find.byKey(const Key('summit-answer')));
    expect(find.text('La partida venció'), findsOneWidget);
    expect(find.byKey(const Key('summit-feedback')), findsNothing);
    expect(find.text('¡Llegaste a la cima!'), findsNothing);
  });

  testWidgets('abandon requires confirmation and cancel does not mutate', (
    tester,
  ) async {
    final h = fixture.Harness();
    h.handler = (_) => state();
    final r = h.repo();
    await tester.pumpWidget(app(r));
    await tester.pumpAndSettle();
    await tap(tester, find.byTooltip('Abandonar ascenso'));
    await tap(tester, find.text('Continuar jugando'));
    expect(h.requests.any((o) => o.method == 'POST'), false);
    await tap(tester, find.byTooltip('Abandonar ascenso'));
    h.handler = (_) => state(status: 'ABANDONADO');
    await tap(tester, find.text('Abandonar'));
    expect(find.text('Ascenso abandonado'), findsOneWidget);
  });

  testWidgets(
    'real question renders case and both images with recoverable errors',
    (tester) async {
      final h = fixture.Harness();
      h.handler = (_) => state(images: true);
      await tester.pumpWidget(app(h.repo()));
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(find.text('Lee el gráfico'), 150);
      await tester.pumpAndSettle();
      expect(find.text('Lee el gráfico'), findsOneWidget);
      expect(find.byType(Image), findsNWidgets(2));
      final images = tester.widgetList<Image>(find.byType(Image)).toList();
      expect(
        images.map((i) => i.semanticLabel),
        containsAll(['Imagen del caso', 'Imagen de la pregunta']),
      );
      expect(images.every((i) => i.errorBuilder != null), true);
      expect(tester.takeException(), null);
    },
  );
}
