import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:saber_plus/core/network/api_error.dart';
import 'package:saber_plus/features/academic/domain/academic_models.dart';
import 'package:saber_plus/features/auth/domain/session.dart';
import 'package:saber_plus/features/auth/presentation/session_controller.dart';
import 'package:saber_plus/features/games/summit/data/demo_summit_repository.dart';
import 'package:saber_plus/features/games/summit/domain/summit_models.dart';
import 'package:saber_plus/features/games/summit/presentation/summit_page.dart';
import 'package:saber_plus/features/games/summit/presentation/summit_providers.dart';

Future<SummitAttempt> send(
  DemoSummitRepository repository, {
  bool correct = true,
  String? key,
}) {
  final attempt = repository.current!;
  final question = attempt.question!;
  return repository.answer(
    attemptId: attempt.id,
    questionId: question.id,
    answerId: correct ? question.options.first.id : question.options.last.id,
    requestKey: key ?? question.id,
  );
}

void main() {
  test('correct climbs, wrong descends one, floor zero and peak preserved', () {
    var p = const SummitProgress.initial().answer(false);
    expect(p.step, 0);
    p = p.answer(true).answer(true).answer(false);
    expect(p.step, 1);
    expect(p.peak, 2);
    expect(p.answered, 4);
    expect(p.correct, 2);
    expect(p.mistakes, 2);
  });

  test('five correct end immediately and prohibit later answers', () {
    var p = const SummitProgress.initial();
    for (var i = 0; i < 5; i++) {
      p = p.answer(true);
    }
    expect(p.won, isTrue);
    expect(p.finished, isTrue);
    expect(() => p.answer(true), throwsStateError);
  });

  test('twelve questions end even without reaching the summit', () {
    var p = const SummitProgress.initial();
    for (var i = 0; i < 12; i++) {
      p = p.answer(i.isEven);
    }
    expect(p.won, isFalse);
    expect(p.finished, isTrue);
    expect(p.step, 0);
    expect(() => p.answer(false), throwsStateError);
  });

  test('demo can win with no next question or invented XP', () async {
    final repo = DemoSummitRepository();
    await repo.start(AcademicArea.mathematics);
    for (var i = 0; i < 5; i++) {
      await send(repo);
    }
    expect(repo.current!.progress.won, isTrue);
    expect(repo.current!.question, isNull);
    expect(repo.current!.progress.answered, 5);
  });

  test('demo twelve wrong answers stay at base and finish', () async {
    final repo = DemoSummitRepository();
    await repo.start(AcademicArea.english);
    for (var i = 0; i < 12; i++) {
      await send(repo, correct: false);
    }
    expect(repo.current!.progress.finished, isTrue);
    expect(repo.current!.progress.won, isFalse);
    expect(repo.current!.progress.step, 0);
    expect(repo.current!.question, isNull);
    expect(repo.current!.lastMovement, 0);
  });

  test(
    'retries are idempotent and conflicting keys/options/attempts fail',
    () async {
      final repo = DemoSummitRepository();
      final start = await repo.start(AcademicArea.mathematics);
      final question = start.question!;
      Future<SummitAttempt> request({
        String? option,
        String? attempt,
        String key = 'request',
      }) => repo.answer(
        attemptId: attempt ?? start.id,
        questionId: question.id,
        answerId: option ?? question.options.first.id,
        requestKey: key,
      );
      await expectLater(request(option: 'fake'), throwsA(isA<ApiError>()));
      await expectLater(request(attempt: 'fake'), throwsA(isA<ApiError>()));
      await expectLater(request(key: ''), throwsA(isA<ApiError>()));
      await request();
      expect((await request()).progress.answered, 1);
      await expectLater(
        request(option: question.options.last.id),
        throwsA(isA<ApiError>()),
      );
      await expectLater(
        request(key: 'new-key-old-question'),
        throwsA(isA<ApiError>()),
      );
      expect(repo.current!.progress.answered, 1);
    },
  );

  test('concurrent requests cannot count a question twice', () async {
    final repo = DemoSummitRepository();
    await repo.start(AcademicArea.mathematics);
    final first = send(repo, key: 'first');
    await expectLater(send(repo, key: 'second'), throwsA(isA<ApiError>()));
    await first;
    expect(repo.current!.progress.answered, 1);
  });

  test(
    'start resumes an active game and does not silently change area',
    () async {
      final repo = DemoSummitRepository();
      final initial = await repo.start(AcademicArea.mathematics);
      await send(repo);
      expect((await repo.start(AcademicArea.mathematics)).id, initial.id);
      expect(repo.current!.progress.step, 1);
      await expectLater(
        repo.start(AcademicArea.english),
        throwsA(isA<ApiError>()),
      );
      for (var i = 1; i < 5; i++) {
        await send(repo);
      }
      final fresh = await repo.start(AcademicArea.english);
      expect(fresh.progress.answered, 0);
      expect(fresh.area, AcademicArea.english);
    },
  );

  test(
    'provider blocks real users, isolates demo accounts, keeps XP-only updates',
    () async {
      final container = ProviderContainer(
        overrides: [sessionControllerProvider.overrideWith(_Session.new)],
      );
      addTearDown(container.dispose);
      final session =
          container.read(sessionControllerProvider.notifier) as _Session;
      final repo = container.read(summitRepositoryProvider)!;
      await repo.start(AcademicArea.mathematics);
      session.change(id: 'demo', xp: 100);
      expect(container.read(summitRepositoryProvider), same(repo));
      session.change(id: 'another');
      expect(container.read(summitRepositoryProvider), isNot(same(repo)));
      expect(container.read(summitRepositoryProvider)!.current, isNull);
      session.change(id: 'real', demo: false);
      expect(container.read(summitRepositoryProvider), isNull);
      session.change(id: 'teacher', role: AppRole.teacher);
      expect(container.read(summitRepositoryProvider), isNull);
      session.clear();
      expect(container.read(summitRepositoryProvider), isNull);
    },
  );

  Future<void> tap(WidgetTester tester, String key) async {
    final finder = find.byKey(Key(key));
    await tester.scrollUntilVisible(
      finder,
      180,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    await tester.ensureVisible(finder);
    await tester.pumpAndSettle();
    await tester.tap(finder);
    await tester.pumpAndSettle();
  }

  testWidgets('UI moves up then down without explanation or double grading', (
    tester,
  ) async {
    final repo = DemoSummitRepository();
    await tester.pumpWidget(_app(repo));
    await tap(tester, 'summit-start');
    await tap(
      tester,
      'summit-option-${repo.current!.question!.options.first.id}',
    );
    await tap(tester, 'summit-answer');
    expect(repo.current!.progress.step, 1);
    expect(find.text('¡Acierto! Subes un escalón.'), findsOneWidget);
    expect(find.byKey(const Key('summit-answer')), findsNothing);
    await tap(tester, 'summit-next');
    await tap(
      tester,
      'summit-option-${repo.current!.question!.options.last.id}',
    );
    await tap(tester, 'summit-answer');
    expect(repo.current!.progress.step, 0);
    expect(
      find.text('Respuesta incorrecta. Bajas un escalón.'),
      findsOneWidget,
    );
    expect(find.textContaining('La respuesta correcta'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('lost acknowledgment retries same request without another step', (
    tester,
  ) async {
    final repo = _LostAcknowledgment();
    await tester.pumpWidget(_app(repo));
    await tap(tester, 'summit-start');
    await tap(
      tester,
      'summit-option-${repo.current!.question!.options.first.id}',
    );
    await tap(tester, 'summit-answer');
    expect(repo.current!.progress.step, 1);
    await tap(tester, 'summit-answer');
    expect(repo.keys, hasLength(2));
    expect(repo.keys.first, repo.keys.last);
    expect(repo.current!.progress.answered, 1);
    expect(find.text('¡Acierto! Subes un escalón.'), findsOneWidget);
  });

  testWidgets('real account sees availability notice rather than demo game', (
    tester,
  ) async {
    await tester.pumpWidget(_app(null));
    expect(find.textContaining('cuentas reales'), findsOneWidget);
    expect(find.byKey(const Key('summit-start')), findsNothing);
  });

  testWidgets(
    'small dark screen with large text can start and finish a round',
    (tester) async {
      tester.view.physicalSize = const Size(320, 780);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final repo = DemoSummitRepository();
      await repo.start(AcademicArea.mathematics);
      for (var i = 0; i < 5; i++) {
        await send(repo);
      }
      await tester.pumpWidget(_app(repo, small: true));
      await tester.scrollUntilVisible(
        find.byKey(const Key('summit-result')),
        160,
      );
      expect(find.text('¡Llegaste a la cima!'), findsOneWidget);
      await tap(tester, 'summit-restart');
      await tap(tester, 'summit-start');
      expect(repo.current!.progress.answered, 0);
      expect(tester.takeException(), isNull);
    },
  );
}

Widget _app(SummitRepository? repository, {bool small = false}) =>
    ProviderScope(
      overrides: [summitRepositoryProvider.overrideWithValue(repository)],
      child: MaterialApp(
        theme: ThemeData(
          brightness: small ? Brightness.dark : Brightness.light,
        ),
        home: MediaQuery(
          data: MediaQueryData(textScaler: TextScaler.linear(small ? 1.8 : 1)),
          child: const SummitPage(),
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
  void change({
    required String id,
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

class _LostAcknowledgment extends DemoSummitRepository {
  final keys = <String>[];
  @override
  Future<SummitAttempt> answer({
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
