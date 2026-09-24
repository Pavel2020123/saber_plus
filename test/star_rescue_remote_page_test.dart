import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:saber_plus/features/academic/domain/academic_models.dart';
import 'package:saber_plus/features/games/star_rescue/data/remote_star_rescue_repository.dart';
import 'package:saber_plus/features/games/star_rescue/presentation/star_rescue_page.dart';
import 'package:saber_plus/features/games/star_rescue/presentation/star_rescue_providers.dart';
import 'package:saber_plus/features/study/domain/study_models.dart';
import 'package:saber_plus/features/study/presentation/study_providers.dart';

import 'remote_star_rescue_repository_test.dart' as fixture;

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

Widget app(RemoteStarRescueRepository repo) => ProviderScope(
  overrides: [
    starRescueRepositoryProvider.overrideWithValue(repo),
    studyCatalogProvider(
      AcademicArea.mathematics,
    ).overrideWith((ref) async => StudyCatalog.demo(AcademicArea.mathematics)),
  ],
  child: const MaterialApp(home: StarRescuePage()),
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
  testWidgets('real setup fits a small screen with enlarged text', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 780);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final h = fixture.Harness();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          starRescueRepositoryProvider.overrideWithValue(h.repo()),
          studyCatalogProvider(AcademicArea.mathematics).overrideWith(
            (ref) async => StudyCatalog.demo(AcademicArea.mathematics),
          ),
        ],
        child: MaterialApp(
          theme: ThemeData.dark(),
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(
              context,
            ).copyWith(textScaler: const TextScaler.linear(1.5)),
            child: child!,
          ),
          home: const StarRescuePage(),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.byKey(const Key('rescue-start')), 150);
    expect(find.text('Comenzar rescate'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
  testWidgets('startup error blocks start and recovers without demo fallback', (
    tester,
  ) async {
    final h = fixture.Harness();
    final r = h.repo();
    h.handler = (o) => throw h.lost(o);
    await tester.pumpWidget(app(r));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('rescue-start')), findsNothing);
    expect(find.textContaining('DEMOSTRACIÓN'), findsNothing);
    h.handler = (_) => null;
    await tap(tester, find.byKey(const Key('rescue-sync')));
    await tester.scrollUntilVisible(find.byKey(const Key('rescue-start')), 150);
    expect(find.byKey(const Key('rescue-start')), findsOneWidget);
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
        find.byKey(const Key('rescue-answer')),
        150,
      );
      expect(find.text('Reintentar envío'), findsOneWidget);
      final other = tester.widget<OutlinedButton>(
        find.byKey(const Key('rescue-option-no')),
      );
      expect(other.onPressed, null);
      h.handler = (_) => state(count: 1);
      await tap(tester, find.byKey(const Key('rescue-answer')));
      expect(find.text('¡Liberaste una estrella!'), findsOneWidget);
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
    await tap(tester, find.byKey(const Key('rescue-option-yes')));
    h.handler = (_) => state(status: 'EXPIRADO');
    await tap(tester, find.byKey(const Key('rescue-answer')));
    expect(find.text('El rescate venció'), findsOneWidget);
    expect(find.byKey(const Key('rescue-feedback')), findsNothing);
    expect(find.text('¡Reconstruiste las dos constelaciones!'), findsNothing);
  });

  testWidgets('abandon requires confirmation and cancel does not mutate', (
    tester,
  ) async {
    final h = fixture.Harness();
    h.handler = (_) => state();
    final r = h.repo();
    await tester.pumpWidget(app(r));
    await tester.pumpAndSettle();
    await tap(tester, find.byTooltip('Abandonar rescate'));
    await tap(tester, find.text('Seguir jugando'));
    expect(h.requests.any((o) => o.method == 'POST'), false);
    await tap(tester, find.byTooltip('Abandonar rescate'));
    h.handler = (_) => state(status: 'ABANDONADO');
    await tap(tester, find.text('Abandonar'));
    expect(find.text('Rescate abandonado'), findsOneWidget);
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
