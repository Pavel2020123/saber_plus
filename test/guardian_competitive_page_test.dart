import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:saber_plus/core/feedback/game_audio_feedback.dart';
import 'package:saber_plus/features/academic/domain/academic_models.dart';
import 'package:saber_plus/features/auth/domain/session.dart';
import 'package:saber_plus/features/auth/presentation/session_controller.dart';
import 'package:saber_plus/features/games/guardian/data/guardian_repository.dart';
import 'package:saber_plus/features/games/guardian/data/guardian_resume_store.dart';
import 'package:saber_plus/features/games/guardian/domain/guardian_models.dart';
import 'package:saber_plus/features/games/guardian/presentation/guardian_page.dart';
import 'package:saber_plus/features/ranking/domain/competitive_ranking_models.dart';
import 'package:saber_plus/features/ranking/presentation/competitive_ranking_page.dart';
import 'package:saber_plus/features/ranking/presentation/competitive_ranking_providers.dart';
import 'package:saber_plus/features/study/domain/study_models.dart';
import 'package:saber_plus/features/study/presentation/study_providers.dart';
import 'competitive_ranking_providers_test.dart' show TestCompetitiveRepository;
import 'helpers/competitive_ranking_fixture.dart';
import 'helpers/guardian_fixture.dart';

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

class _SilentAudio implements GameAudioFeedback {
  @override
  Future<void> play(GameSound sound) async {}
}

Widget app(
  GuardianRepository repo, {
  double textScale = 1,
  TestCompetitiveRepository? rankings,
}) => ProviderScope(
  overrides: [
    guardianRepositoryProvider.overrideWithValue(repo),
    sessionControllerProvider.overrideWith(_Student.new),
    gameAudioFeedbackProvider.overrideWithValue(_SilentAudio()),
    studyCatalogProvider(
      AcademicArea.mathematics,
    ).overrideWith((_) async => StudyCatalog.demo(AcademicArea.mathematics)),
    if (rankings != null)
      competitiveRankingRepositoryProvider.overrideWithValue(rankings),
  ],
  child: MaterialApp(
    builder: (context, child) => MediaQuery(
      data: MediaQuery.of(context).copyWith(
        disableAnimations: true,
        textScaler: TextScaler.linear(textScale),
      ),
      child: child!,
    ),
    home: const GuardianPage(),
  ),
);
Future<void> tap(WidgetTester tester, Finder finder) async {
  if (finder.evaluate().isEmpty) {
    await tester.scrollUntilVisible(
      finder,
      180,
      scrollable: find.byType(Scrollable).first,
    );
  }
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

void screen(WidgetTester tester, Size size) {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

void main() {
  testWidgets(
    'small screen/large text competitive selection is usable, then server mode is fixed',
    (tester) async {
      screen(tester, const Size(320, 568));
      final h = GuardianHarness();
      h.handler = (o) =>
          o.method == 'GET' ? null : guardianState(competitive: true);
      await tester.pumpWidget(app(h.repo(), textScale: 2));
      await tester.pumpAndSettle();
      await tap(
        tester,
        find.descendant(
          of: find.byKey(const Key('guardian-competitive-mode')),
          matching: find.byType(Switch),
        ),
      );
      await tap(tester, find.byKey(const Key('guardian-start')));
      expect(h.requests.last.data['competitive'], isTrue);
      expect(find.byKey(const Key('guardian-competitive-mode')), findsNothing);
      await tester.scrollUntilVisible(
        find.textContaining('Partida competitiva ·'),
        -200,
      );
      expect(find.textContaining('Partida competitiva ·'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );
  testWidgets(
    'OFF rejection explains explicit normal choice and never retries automatically',
    (tester) async {
      screen(tester, const Size(430, 1100));
      final h = GuardianHarness();
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
        return guardianState();
      };
      await tester.pumpWidget(app(h.repo()));
      await tester.pumpAndSettle();
      final toggle = find.descendant(
        of: find.byKey(const Key('guardian-competitive-mode')),
        matching: find.byType(Switch),
      );
      await tap(tester, toggle);
      await tap(tester, find.byKey(const Key('guardian-start')));
      await tester.scrollUntilVisible(
        find.textContaining('El servidor todavía no admite'),
        -200,
      );
      expect(
        find.textContaining('El servidor todavía no admite'),
        findsOneWidget,
      );
      expect(h.requests.where((r) => r.method == 'POST').length, 1);
      await tap(tester, toggle);
      await tap(tester, find.byKey(const Key('guardian-start')));
      expect(h.requests.last.data.containsKey('competitive'), isFalse);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );
  testWidgets(
    'restored pending answer keeps selection and key, then shows existing feedback',
    (tester) async {
      screen(tester, const Size(430, 1100));
      final h = GuardianHarness();
      await h.store.save(
        'api\u0000student',
        const GuardianResume(
          'attempt',
          GuardianPendingAnswer(
            attemptId: 'attempt',
            questionId: 'q1',
            answerId: 'a1',
            idempotencyKey: guardianRequestKey,
          ),
          true,
        ),
      );
      h.handler = (o) =>
          guardianState(competitive: true, count: o.method == 'POST' ? 1 : 0);
      await tester.pumpWidget(app(h.repo()));
      await tester.pumpAndSettle();
      await tap(tester, find.byKey(const Key('guardian-answer')));
      expect(h.requests.last.data, {
        'preguntaId': 'q1',
        'respuestaId': 'a1',
        'idempotencyKey': guardianRequestKey,
      });
      expect(
        find.text('¡Acierto! El guardián pierde energía.'),
        findsOneWidget,
      );
      expect(find.byKey(const Key('guardian-next')), findsOneWidget);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );
  testWidgets('competitive abandonment warns, cancel never sends a mutation', (
    tester,
  ) async {
    final h = GuardianHarness()
      ..handler = (_) => guardianState(competitive: true);
    await tester.pumpWidget(app(h.repo()));
    await tester.pumpAndSettle();
    await tap(tester, find.byTooltip('Abandonar desafío'));
    expect(
      find.textContaining('reglas competitivas de abandono'),
      findsOneWidget,
    );
    await tap(tester, find.text('Seguir jugando'));
    expect(h.requests.every((r) => r.method == 'GET'), isTrue);
    await tester.pumpWidget(const SizedBox.shrink());
  });
  testWidgets(
    'competitive terminal result opens Guardian ranking without inventing XP',
    (tester) async {
      screen(tester, const Size(430, 1100));
      final h = GuardianHarness()
        ..handler = (_) =>
            guardianState(competitive: true, count: 6, status: 'VICTORIA');
      final rankings = TestCompetitiveRepository(
        (q) async => fixtureBoard(
          game: q.game,
          season: q.season,
          state: 'SIN_PARTICIPANTES',
        ),
      );
      await tester.pumpWidget(app(h.repo(), rankings: rankings));
      await tester.pumpAndSettle();
      await tap(tester, find.byKey(const Key('guardian-open-ranking')));
      expect(find.byType(CompetitiveRankingPage), findsOneWidget);
      expect(rankings.queries.last.game, CompetitiveGame.guardian);
      expect(h.requests.every((r) => r.method == 'GET'), isTrue);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );
  testWidgets(
    'failed initial restore disables start instead of allowing fallback',
    (tester) async {
      final h = GuardianHarness()
        ..handler = (o) => throw DioException(
          requestOptions: o,
          type: DioExceptionType.connectionError,
        );
      await tester.pumpWidget(app(h.repo()));
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.byKey(const Key('guardian-start')),
        180,
      );
      expect(
        tester
            .widget<FilledButton>(find.byKey(const Key('guardian-start')))
            .onPressed,
        isNull,
      );
      expect(h.requests.every((r) => r.method == 'GET'), isTrue);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );
}
