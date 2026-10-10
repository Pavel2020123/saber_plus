import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:saber_plus/features/auth/domain/session.dart';
import 'package:saber_plus/features/auth/presentation/session_controller.dart';
import 'package:saber_plus/features/academic/domain/academic_models.dart';
import 'package:saber_plus/features/games/star_rescue/presentation/star_rescue_page.dart';
import 'package:saber_plus/features/games/star_rescue/presentation/star_rescue_providers.dart';
import 'package:saber_plus/features/ranking/presentation/competitive_ranking_page.dart';
import 'package:saber_plus/features/ranking/presentation/competitive_ranking_providers.dart';
import 'package:saber_plus/features/study/domain/study_models.dart';
import 'package:saber_plus/features/study/presentation/study_providers.dart';

import 'competitive_ranking_providers_test.dart' show TestCompetitiveRepository;
import 'helpers/competitive_ranking_fixture.dart';
import 'remote_star_rescue_repository_test.dart' as fixture;
import 'star_rescue_remote_page_test.dart' as ui;

class _Student extends SessionController {
  @override
  SessionState build() => const SessionState.authenticated(
    UserSession(
      id: 'student',
      firstName: 'Ficticio',
      role: AppRole.student,
      isDemo: false,
    ),
  );
}

Map<String, dynamic> state({int count = 0, String status = 'ACTIVO'}) => {
  ...ui.state(count: count, status: status),
  'competitive': true,
};

Widget app(fixture.Harness h, {double textScale = 1}) => ProviderScope(
  overrides: [
    starRescueRepositoryProvider.overrideWithValue(h.repo()),
    sessionControllerProvider.overrideWith(_Student.new),
    competitiveRankingRepositoryProvider.overrideWithValue(
      TestCompetitiveRepository(
        (q) async => fixtureBoard(
          game: q.game,
          season: q.season,
          state: 'SIN_PARTICIPANTES',
        ),
      ),
    ),
    studyCatalogProvider(
      AcademicArea.mathematics,
    ).overrideWith((_) async => StudyCatalog.demo(AcademicArea.mathematics)),
  ],
  child: MaterialApp(
    builder: (context, child) => MediaQuery(
      data: MediaQuery.of(
        context,
      ).copyWith(textScaler: TextScaler.linear(textScale)),
      child: child!,
    ),
    home: const StarRescuePage(),
  ),
);

Finder get toggle => find.descendant(
  of: find.byKey(const Key('rescue-competitive-mode')),
  matching: find.byType(Switch),
);

void main() {
  testWidgets(
    'competitive selection fits small screen/large text and becomes fixed',
    (tester) async {
      tester.view.physicalSize = const Size(320, 780);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final h = fixture.Harness();
      h.handler = (o) => o.method == 'GET' ? null : state();
      await tester.pumpWidget(app(h, textScale: 2));
      await tester.pumpAndSettle();
      await ui.tap(tester, toggle);
      await ui.tap(tester, find.byKey(const Key('rescue-start')));
      expect(h.requests.last.data['competitive'], true);
      expect(find.byKey(const Key('rescue-competitive-mode')), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'OFF keeps explicit selection and permits deliberate normal practice',
    (tester) async {
      final h = fixture.Harness();
      h.handler = (o) {
        if (o.method == 'GET') return null;
        if (o.data['competitive'] == true) {
          throw DioException(
            requestOptions: o,
            response: Response(
              requestOptions: o,
              statusCode: 403,
              data: {'code': 'COMPETITIVE_SOLO_DISABLED', 'message': 'OFF'},
            ),
          );
        }
        return ui.state();
      };
      await tester.pumpWidget(app(h));
      await tester.pumpAndSettle();
      await ui.tap(tester, toggle);
      await ui.tap(tester, find.byKey(const Key('rescue-start')));
      await tester.scrollUntilVisible(
        find.textContaining('El servidor todavía no admite'),
        -150,
      );
      expect(
        find.textContaining('El servidor todavía no admite'),
        findsOneWidget,
      );
      expect(h.requests.where((o) => o.method == 'POST'), hasLength(1));
      await ui.tap(tester, toggle);
      await ui.tap(tester, find.byKey(const Key('rescue-start')));
      expect(h.requests.last.data.containsKey('competitive'), false);
    },
  );

  testWidgets('competitive terminal result opens the Rescate ranking', (
    tester,
  ) async {
    final h = fixture.Harness();
    h.handler = (_) => state(count: 6, status: 'VICTORIA');
    await tester.pumpWidget(app(h));
    await tester.pumpAndSettle();
    await ui.tap(tester, find.byKey(const Key('rescue-open-ranking')));
    expect(find.byType(CompetitiveRankingPage), findsOneWidget);
    expect(find.textContaining('Rescate de estrellas'), findsWidgets);
    expect(tester.takeException(), isNull);
    expect(h.requests.every((o) => o.method == 'GET'), true);
  });

  testWidgets('normal result does not offer competitive ranking', (
    tester,
  ) async {
    final h = fixture.Harness();
    h.handler = (_) => ui.state(count: 6, status: 'VICTORIA');
    await tester.pumpWidget(app(h));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.byKey(const Key('rescue-restart')),
      150,
    );
    expect(find.byKey(const Key('rescue-open-ranking')), findsNothing);
  });

  testWidgets(
    'abandonment explains competitive server rules before confirmation',
    (tester) async {
      final h = fixture.Harness();
      h.handler = (_) => state();
      await tester.pumpWidget(app(h));
      await tester.pumpAndSettle();
      await ui.tap(tester, find.byTooltip('Abandonar rescate'));
      expect(
        find.textContaining('reglas competitivas de abandono'),
        findsOneWidget,
      );
      await ui.tap(tester, find.text('Seguir jugando'));
      expect(h.requests.every((o) => o.method == 'GET'), true);
    },
  );
}
