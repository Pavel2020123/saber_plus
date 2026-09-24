import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:saber_plus/core/network/api_error.dart';
import 'package:saber_plus/features/academic/domain/academic_models.dart';
import 'package:saber_plus/features/auth/domain/session.dart';
import 'package:saber_plus/features/auth/presentation/session_controller.dart';
import 'package:saber_plus/features/games/star_rescue/data/demo_star_rescue_repository.dart';
import 'package:saber_plus/features/games/star_rescue/domain/star_rescue_models.dart';
import 'package:saber_plus/features/games/star_rescue/presentation/star_rescue_page.dart';
import 'package:saber_plus/features/games/star_rescue/presentation/star_rescue_providers.dart';

Future<StarRescueAttempt> send(
  DemoStarRescueRepository repo, {
  bool correct = true,
}) {
  final attempt = repo.current!;
  final q = attempt.question!;
  return repo.answer(
    attemptId: attempt.id,
    questionId: q.id,
    answerId: correct ? q.options.first.id : q.options.last.id,
    requestKey: q.id,
  );
}

void main() {
  test('one star per correct answer, three per group and victory at six', () {
    var p = const StarRescueProgress.initial();
    expect(p.stars, 0);
    expect(p.constellations, 0);
    for (var i = 1; i <= 6; i++) {
      p = p.answer(true);
      expect(p.stars, i);
      expect(p.constellations, i ~/ 3);
      expect(p.won, i == 6);
    }
    expect(p.finished, true);
    expect(() => p.answer(true), throwsStateError);
  });
  test('mistakes consume questions, never remove rescued stars', () {
    var p = const StarRescueProgress.initial().answer(true).answer(false);
    expect(p.stars, 1);
    expect(p.mistakes, 1);
    for (var i = 2; i < 10; i++) {
      p = p.answer(false);
    }
    expect(p.stars, 1);
    expect(p.mistakes, 9);
    expect(p.finished, true);
    expect(p.won, false);
    expect(() => p.answer(false), throwsStateError);
  });
  test('victory on tenth question takes precedence over exhaustion', () {
    var p = const StarRescueProgress.initial();
    for (var i = 0; i < 10; i++) {
      p = p.answer(i >= 4);
    }
    expect(p.won, true);
    expect(p.answered, 10);
    expect(p.constellations, 2);
  });
  test(
    'demo closes immediately at six and does not expose a next question',
    () async {
      final repo = DemoStarRescueRepository();
      await repo.start(AcademicArea.english);
      for (var i = 0; i < 6; i++) {
        await send(repo);
      }
      expect(repo.current!.progress.won, true);
      expect(repo.current!.question, null);
      expect(repo.current!.progress.answered, 6);
    },
  );
  test('ten wrong answers end at zero without fake completion', () async {
    final repo = DemoStarRescueRepository();
    await repo.start(AcademicArea.mathematics);
    for (var i = 0; i < 10; i++) {
      await send(repo, correct: false);
    }
    expect(repo.current!.finished, true);
    expect(repo.current!.progress.won, false);
    expect(repo.current!.progress.constellations, 0);
    expect(repo.current!.question, null);
  });
  test(
    'duplicate keys return same progress; altered payload and stale questions fail',
    () async {
      final repo = DemoStarRescueRepository();
      final start = await repo.start(AcademicArea.mathematics);
      final q = start.question!;
      Future<StarRescueAttempt> request({
        String? option,
        String? id,
        String key = 'key',
      }) => repo.answer(
        attemptId: id ?? start.id,
        questionId: q.id,
        answerId: option ?? q.options.first.id,
        requestKey: key,
      );
      await expectLater(request(key: ''), throwsA(isA<ApiError>()));
      await expectLater(request(option: 'foreign'), throwsA(isA<ApiError>()));
      await expectLater(request(id: 'other'), throwsA(isA<ApiError>()));
      await request();
      expect((await request()).progress.stars, 1);
      await expectLater(
        request(option: q.options.last.id),
        throwsA(isA<ApiError>()),
      );
      await expectLater(request(key: 'second-key'), throwsA(isA<ApiError>()));
      expect(repo.current!.progress.answered, 1);
    },
  );
  test(
    'concurrent start, answer and abandon do not race or double count',
    () async {
      final repo = DemoStarRescueRepository();
      final starting = repo.start(AcademicArea.mathematics);
      await expectLater(
        repo.start(AcademicArea.mathematics),
        throwsA(isA<ApiError>()),
      );
      await starting;
      final answering = send(repo);
      final duplicate = expectLater(send(repo), throwsA(isA<ApiError>()));
      final abandoning = expectLater(
        repo.abandon(repo.current!.id),
        throwsA(isA<ApiError>()),
      );
      await Future.wait([answering, duplicate, abandoning]);
      expect(repo.current!.progress.stars, 1);
      expect(repo.current!.abandoned, false);
    },
  );
  test(
    'start resumes same area; cannot replace active attempt with another area',
    () async {
      final repo = DemoStarRescueRepository();
      final start = await repo.start(AcademicArea.mathematics);
      await send(repo);
      expect((await repo.start(AcademicArea.mathematics)).id, start.id);
      expect(repo.current!.progress.stars, 1);
      await expectLater(
        repo.start(AcademicArea.english),
        throwsA(isA<ApiError>()),
      );
    },
  );
  test(
    'abandon preserves stars, is idempotent and allows a fresh rescue',
    () async {
      final repo = DemoStarRescueRepository();
      await repo.start(AcademicArea.mathematics);
      await send(repo);
      final active = repo.current!;
      final q = active.question!;
      final closed = await repo.abandon(active.id);
      expect(closed.abandoned, true);
      expect(closed.progress.stars, 1);
      expect(await repo.abandon(active.id), same(closed));
      await expectLater(
        repo.answer(
          attemptId: active.id,
          questionId: q.id,
          answerId: q.options.first.id,
          requestKey: 'new',
        ),
        throwsA(isA<ApiError>()),
      );
      expect((await repo.start(AcademicArea.english)).progress.stars, 0);
    },
  );
  test('account disposal while awaiting demo work discards result', () async {
    final repo = DemoStarRescueRepository();
    final starting = repo.start(AcademicArea.mathematics);
    repo.dispose();
    await expectLater(starting, throwsA(isA<ApiError>()));
    expect(repo.current, null);
    await expectLater(
      repo.start(AcademicArea.english),
      throwsA(isA<ApiError>()),
    );
  });
  test(
    'provider isolates account/role and uses remote for real users; XP does not reset',
    () async {
      final container = ProviderContainer(
        overrides: [sessionControllerProvider.overrideWith(_Session.new)],
      );
      addTearDown(container.dispose);
      final session =
          container.read(sessionControllerProvider.notifier) as _Session;
      final repo = container.read(starRescueRepositoryProvider)!;
      await repo.start(AcademicArea.mathematics);
      session.change('demo', xp: 50);
      expect(container.read(starRescueRepositoryProvider), same(repo));
      session.change('other');
      expect(container.read(starRescueRepositoryProvider), isNot(same(repo)));
      expect(container.read(starRescueRepositoryProvider)!.current, null);
      session.change('real', demo: false);
      expect(container.read(starRescueRepositoryProvider)!.isDemo, false);
      session.change('teacher', role: AppRole.teacher);
      expect(container.read(starRescueRepositoryProvider), null);
      session.clear();
      expect(container.read(starRescueRepositoryProvider), null);
    },
  );

  testWidgets('UI releases a star then preserves it after an error', (
    tester,
  ) async {
    final repo = DemoStarRescueRepository();
    await tester.pumpWidget(app(repo));
    await tap(tester, 'rescue-start');
    await tap(
      tester,
      'rescue-option-${repo.current!.question!.options.first.id}',
    );
    await tap(tester, 'rescue-answer');
    expect(find.text('¡Liberaste una estrella!'), findsOneWidget);
    expect(repo.current!.progress.stars, 1);
    await tap(tester, 'rescue-next');
    await tap(
      tester,
      'rescue-option-${repo.current!.question!.options.last.id}',
    );
    await tap(tester, 'rescue-answer');
    expect(find.textContaining('Conservas tus estrellas'), findsOneWidget);
    expect(repo.current!.progress.stars, 1);
    expect(repo.current!.progress.answered, 2);
    expect(tester.takeException(), null);
  });
  testWidgets(
    'lost acknowledgment retries same choice and request without two stars',
    (tester) async {
      final repo = _LostAck();
      await tester.pumpWidget(app(repo));
      await tap(tester, 'rescue-start');
      await tap(
        tester,
        'rescue-option-${repo.current!.question!.options.first.id}',
      );
      await tap(tester, 'rescue-answer');
      await tap(tester, 'rescue-answer');
      expect(repo.keys, hasLength(2));
      expect(repo.keys.first, repo.keys.last);
      expect(repo.current!.progress.stars, 1);
      expect(find.text('¡Liberaste una estrella!'), findsOneWidget);
    },
  );
  testWidgets('unavailable repository does not offer demo for a real account', (
    tester,
  ) async {
    await tester.pumpWidget(app(null));
    expect(find.textContaining('cuentas reales'), findsOneWidget);
    expect(find.byKey(const Key('rescue-start')), findsNothing);
  });
  testWidgets(
    'small dark screen and large text show accessible final groups and restart',
    (tester) async {
      tester.view.physicalSize = const Size(320, 780);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final repo = DemoStarRescueRepository();
      await repo.start(AcademicArea.mathematics);
      for (var i = 0; i < 6; i++) {
        await send(repo);
      }
      await tester.pumpWidget(app(repo, small: true));
      await tester.scrollUntilVisible(
        find.byKey(const Key('rescue-result')),
        150,
      );
      expect(
        find.text('¡Reconstruiste las dos constelaciones!'),
        findsOneWidget,
      );
      await tap(tester, 'rescue-restart');
      await tap(tester, 'rescue-start');
      expect(repo.current!.progress.stars, 0);
      expect(tester.takeException(), null);
    },
  );
  testWidgets('leaving and reopening restores in-memory rescue and feedback', (
    tester,
  ) async {
    final repo = DemoStarRescueRepository();
    await repo.start(AcademicArea.mathematics);
    await send(repo);
    await tester.pumpWidget(app(repo));
    await tester.pumpAndSettle();
    expect(find.text('Estrellas liberadas: 1/6'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
    await tester.pumpWidget(app(repo));
    await tester.pumpAndSettle();
    expect(find.text('Estrellas liberadas: 1/6'), findsOneWidget);
    expect(find.byKey(const Key('rescue-start')), findsNothing);
  });
  testWidgets(
    'abandon requires confirmation and preserves confirmed progress',
    (tester) async {
      final repo = DemoStarRescueRepository();
      await repo.start(AcademicArea.mathematics);
      await send(repo);
      await tester.pumpWidget(app(repo));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Abandonar rescate'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Seguir jugando'));
      await tester.pumpAndSettle();
      expect(repo.current!.finished, false);
      await tester.tap(find.byTooltip('Abandonar rescate'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Abandonar'));
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.byKey(const Key('rescue-result')),
        150,
      );
      expect(find.text('Rescate abandonado'), findsOneWidget);
      expect(repo.current!.progress.stars, 1);
    },
  );
}

Future<void> tap(WidgetTester tester, String key) async {
  final finder = find.byKey(Key(key));
  await tester.scrollUntilVisible(
    finder,
    150,
    scrollable: find.byType(Scrollable).first,
  );
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

Widget app(StarRescueRepository? repo, {bool small = false}) => ProviderScope(
  overrides: [starRescueRepositoryProvider.overrideWithValue(repo)],
  child: MaterialApp(
    theme: ThemeData(brightness: small ? Brightness.dark : Brightness.light),
    home: MediaQuery(
      data: MediaQueryData(textScaler: TextScaler.linear(small ? 1.8 : 1)),
      child: const StarRescuePage(),
    ),
  ),
);

class _Session extends SessionController {
  @override
  SessionState build() => const SessionState.authenticated(
    UserSession(
      id: 'demo',
      firstName: 'Demo',
      role: AppRole.student,
      isDemo: true,
    ),
  );
  void change(
    String id, {
    bool demo = true,
    AppRole role = AppRole.student,
    int xp = 0,
  }) {
    state = SessionState.authenticated(
      UserSession(
        id: id,
        firstName: 'User',
        role: role,
        isDemo: demo,
        xpTotal: xp,
      ),
    );
  }

  void clear() => state = const SessionState.unauthenticated();
}

class _LostAck extends DemoStarRescueRepository {
  final keys = <String>[];
  @override
  Future<StarRescueAttempt> answer({
    required String attemptId,
    required String questionId,
    required String answerId,
    required String requestKey,
  }) async {
    keys.add(requestKey);
    final result = await super.answer(
      attemptId: attemptId,
      questionId: questionId,
      answerId: answerId,
      requestKey: requestKey,
    );
    if (keys.length == 1) {
      throw const ApiError(code: 'timeout', message: 'No se pudo confirmar.');
    }
    return result;
  }
}
