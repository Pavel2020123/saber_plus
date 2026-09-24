import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:saber_plus/core/network/api_error.dart';
import 'package:saber_plus/features/academic/domain/academic_models.dart';
import 'package:saber_plus/features/auth/domain/session.dart';
import 'package:saber_plus/features/auth/presentation/session_controller.dart';
import 'package:saber_plus/features/games/knowledge_shield/data/demo_knowledge_shield_repository.dart';
import 'package:saber_plus/features/games/knowledge_shield/domain/knowledge_shield_models.dart';
import 'package:saber_plus/features/games/knowledge_shield/presentation/knowledge_shield_page.dart';
import 'package:saber_plus/features/games/knowledge_shield/presentation/knowledge_shield_providers.dart';

Future<KnowledgeShieldAttempt> send(
  DemoKnowledgeShieldRepository repo, {
  bool correct = true,
}) {
  final attempt = repo.current!;
  final q = attempt.question!;
  return repo.answer(
    attemptId: attempt.id,
    questionId: q.id,
    answerId: (correct ? q.options.first : q.options.last).id,
    requestKey: 'request-${attempt.progress.answered}',
  );
}

void main() {
  test(
    'three rounds award pages after attacks; correct answers cap at three',
    () {
      var p = const KnowledgeShieldProgress.initial();
      for (var i = 1; i <= 12; i++) {
        p = p.answer(true);
        expect(p.shield, i % 4 == 0 ? 2 : 3);
        expect(p.pages, i ~/ 4);
        expect(p.finished, i == 12);
      }
      expect(p.won, true);
      expect(p.round, 3);
      expect(() => p.answer(true), throwsStateError);
    },
  );
  test('three errors defeat immediately without negative health or pages', () {
    var p = const KnowledgeShieldProgress.initial();
    for (var i = 0; i < 3; i++) {
      p = p.answer(false);
    }
    expect(p.shield, 0);
    expect(p.answered, 3);
    expect(p.pages, 0);
    expect(p.won, false);
    expect(() => p.answer(true), throwsStateError);
  });
  test('end-of-round attack can defeat; failed round grants no page', () {
    var p = const KnowledgeShieldProgress.initial();
    for (final correct in [true, true, false, false]) {
      p = p.answer(correct);
    }
    expect(p.answered, 4);
    expect(p.shield, 0);
    expect(p.finished, true);
    expect(p.pages, 0);
  });
  test('last round defeat takes precedence over answering all questions', () {
    var p = const KnowledgeShieldProgress.initial();
    for (var i = 0; i < 10; i++) {
      p = p.answer(true);
    }
    p = p.answer(false).answer(false);
    expect(p.answered, 12);
    expect(p.pages, 2);
    expect(p.won, false);
  });
  test('repair recovers damage; shield is not reset at round transitions', () {
    var p = const KnowledgeShieldProgress.initial().answer(false).answer(true);
    expect(p.shield, 3);
    p = p.answer(true).answer(true);
    expect(p.shield, 2);
    expect(p.round, 2);
    expect(p.answer(false).shield, 1);
  });
  test('all five demo areas have twelve questions and can finish', () async {
    for (final area in AcademicArea.values) {
      final repo = DemoKnowledgeShieldRepository();
      await repo.start(area);
      final ids = <String>{};
      for (var i = 0; i < 12; i++) {
        expect(repo.current!.question!.area, area);
        ids.add(repo.current!.question!.id);
        await send(repo);
      }
      expect(ids.length, 12);
      expect(repo.current!.progress.won, true);
      expect(repo.current!.question, null);
    }
  });
  test('early defeat closes question; new attempt resets progress', () async {
    final repo = DemoKnowledgeShieldRepository();
    await repo.start(AcademicArea.mathematics);
    for (var i = 0; i < 3; i++) {
      await send(repo, correct: false);
    }
    expect(repo.current!.finished, true);
    expect(repo.current!.question, null);
    expect((await repo.start(AcademicArea.english)).progress.shield, 3);
  });
  test(
    'duplicate delivery counts once; changed payload and stale question rejected',
    () async {
      final repo = DemoKnowledgeShieldRepository();
      final start = await repo.start(AcademicArea.mathematics);
      final q = start.question!;
      Future<KnowledgeShieldAttempt> answer({
        String key = 'key',
        String? id,
        String? option,
      }) => repo.answer(
        attemptId: id ?? start.id,
        questionId: q.id,
        answerId: option ?? q.options.first.id,
        requestKey: key,
      );
      await expectLater(answer(key: ''), throwsA(isA<ApiError>()));
      await expectLater(answer(id: 'other'), throwsA(isA<ApiError>()));
      await expectLater(answer(option: 'unknown'), throwsA(isA<ApiError>()));
      await answer();
      await answer();
      expect(repo.current!.progress.answered, 1);
      await expectLater(
        answer(option: q.options.last.id),
        throwsA(isA<ApiError>()),
      );
      await expectLater(answer(key: 'new'), throwsA(isA<ApiError>()));
    },
  );
  test('concurrent calls rejected; resume cannot change area', () async {
    final repo = DemoKnowledgeShieldRepository();
    final starting = repo.start(AcademicArea.mathematics);
    await expectLater(
      repo.start(AcademicArea.english),
      throwsA(isA<ApiError>()),
    );
    final first = await starting;
    final answering = send(repo);
    await expectLater(repo.abandon(first.id), throwsA(isA<ApiError>()));
    await answering;
    expect((await repo.start(AcademicArea.mathematics)).progress.answered, 1);
    await expectLater(
      repo.start(AcademicArea.english),
      throwsA(isA<ApiError>()),
    );
  });
  test('abandon is idempotent and preserves pages', () async {
    final repo = DemoKnowledgeShieldRepository();
    await repo.start(AcademicArea.english);
    for (var i = 0; i < 4; i++) {
      await send(repo);
    }
    final abandoned = await repo.abandon(repo.current!.id);
    expect(abandoned.abandoned, true);
    expect(abandoned.progress.pages, 1);
    expect(abandoned.question, null);
    expect(await repo.abandon(abandoned.id), same(abandoned));
  });
  test('disposed account rejects pending result', () async {
    final repo = DemoKnowledgeShieldRepository();
    final starting = repo.start(AcademicArea.english);
    repo.dispose();
    await expectLater(starting, throwsA(isA<ApiError>()));
    expect(repo.current, null);
  });
  test(
    'provider selects remote for real students, blocks teachers and isolates users',
    () async {
      final container = ProviderContainer(
        overrides: [sessionControllerProvider.overrideWith(_Session.new)],
      );
      addTearDown(container.dispose);
      final session =
          container.read(sessionControllerProvider.notifier) as _Session;
      final repo = container.read(knowledgeShieldRepositoryProvider)!;
      session.change('demo', xp: 10);
      expect(container.read(knowledgeShieldRepositoryProvider), same(repo));
      session.change('other');
      expect(
        container.read(knowledgeShieldRepositoryProvider),
        isNot(same(repo)),
      );
      session.change('real', demo: false);
      expect(container.read(knowledgeShieldRepositoryProvider)!.isDemo, false);
      session.change('teacher', role: AppRole.teacher);
      expect(container.read(knowledgeShieldRepositoryProvider), null);
      session.clear();
      expect(container.read(knowledgeShieldRepositoryProvider), null);
    },
  );
  testWidgets('demo repairs, takes damage and requires next question', (
    tester,
  ) async {
    final repo = DemoKnowledgeShieldRepository();
    await tester.pumpWidget(app(repo));
    await tap(tester, 'shield-start');
    await tap(
      tester,
      'shield-option-${repo.current!.question!.options.last.id}',
    );
    await tap(tester, 'shield-answer');
    expect(repo.current!.progress.shield, 2);
    expect(find.byKey(const Key('shield-feedback')), findsOneWidget);
    await tap(tester, 'shield-next');
    await tap(
      tester,
      'shield-option-${repo.current!.question!.options.first.id}',
    );
    await tap(tester, 'shield-answer');
    expect(repo.current!.progress.shield, 3);
    expect(tester.takeException(), null);
  });
  testWidgets(
    'lost acknowledgment retries same payload without duplicate damage',
    (tester) async {
      final repo = _LostAck();
      await tester.pumpWidget(app(repo));
      await tap(tester, 'shield-start');
      await tap(
        tester,
        'shield-option-${repo.current!.question!.options.last.id}',
      );
      await tap(tester, 'shield-answer');
      expect(repo.current!.progress.shield, 2);
      await tap(tester, 'shield-answer');
      expect(repo.keys, hasLength(2));
      expect(repo.keys.first, repo.keys.last);
      expect(repo.current!.progress.answered, 1);
      expect(repo.current!.progress.shield, 2);
      expect(tester.takeException(), null);
    },
  );
  testWidgets(
    'round summary leads to next round and early defeat shows result',
    (tester) async {
      final repo = DemoKnowledgeShieldRepository();
      await repo.start(AcademicArea.english);
      for (var i = 0; i < 4; i++) {
        await send(repo);
      }
      await tester.pumpWidget(app(repo));
      await tap(tester, 'shield-next');
      expect(find.text('Ronda 2/3 · Pregunta 1/4'), findsOneWidget);
      for (var i = 0; i < 2; i++) {
        await tap(
          tester,
          'shield-option-${repo.current!.question!.options.last.id}',
        );
        await tap(tester, 'shield-answer');
        if (i == 0) await tap(tester, 'shield-next');
      }
      expect(find.text('El escudo se agotó'), findsOneWidget);
      expect(repo.current!.progress.pages, 1);
      expect(tester.takeException(), null);
    },
  );
  testWidgets('real account never falls back to demo', (tester) async {
    await tester.pumpWidget(app(null));
    expect(find.textContaining('cuentas reales'), findsOneWidget);
    expect(find.byKey(const Key('shield-start')), findsNothing);
  });
  testWidgets('small dark screen with large text supports result and restart', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 780);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final repo = DemoKnowledgeShieldRepository();
    await repo.start(AcademicArea.english);
    for (var i = 0; i < 12; i++) {
      await send(repo);
    }
    await tester.pumpWidget(app(repo, large: true));
    await tap(tester, 'shield-restart');
    await tap(tester, 'shield-start');
    expect(repo.current!.progress.pages, 0);
    expect(tester.takeException(), null);
  });
  testWidgets('reopen resumes round; abandon needs confirmation', (
    tester,
  ) async {
    final repo = DemoKnowledgeShieldRepository();
    await repo.start(AcademicArea.english);
    for (var i = 0; i < 4; i++) {
      await send(repo);
    }
    await tester.pumpWidget(app(repo));
    expect(find.textContaining('Páginas recuperadas: 1/3'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
    await tester.pumpWidget(app(repo));
    await tester.tap(find.byTooltip('Abandonar defensa'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Seguir jugando'));
    await tester.pumpAndSettle();
    expect(repo.current!.finished, false);
    await tester.tap(find.byTooltip('Abandonar defensa'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Abandonar'));
    await tester.pumpAndSettle();
    expect(repo.current!.abandoned, true);
    expect(repo.current!.progress.pages, 1);
  });
}

Widget app(KnowledgeShieldRepository? repo, {bool large = false}) =>
    ProviderScope(
      overrides: [knowledgeShieldRepositoryProvider.overrideWithValue(repo)],
      child: MaterialApp(
        theme: ThemeData(
          brightness: large ? Brightness.dark : Brightness.light,
        ),
        home: MediaQuery(
          data: MediaQueryData(textScaler: TextScaler.linear(large ? 1.8 : 1)),
          child: const KnowledgeShieldPage(),
        ),
      ),
    );
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
        firstName: 'Demo',
        role: role,
        isDemo: demo,
        xpTotal: xp,
      ),
    );
  }

  void clear() => state = const SessionState.unauthenticated();
}

class _LostAck extends DemoKnowledgeShieldRepository {
  final keys = <String>[];
  @override
  Future<KnowledgeShieldAttempt> answer({
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
      throw const ApiError(code: 'test', message: 'No se confirmó.');
    }
    return result;
  }
}
