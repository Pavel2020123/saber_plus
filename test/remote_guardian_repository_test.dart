import 'dart:async';
import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:saber_plus/core/network/api_error.dart';
import 'package:saber_plus/features/academic/domain/academic_models.dart';
import 'package:saber_plus/features/practice/domain/practice_models.dart';
import 'package:saber_plus/features/games/guardian/domain/guardian_models.dart';
import 'package:saber_plus/features/games/guardian/data/demo_guardian_repository.dart';
import 'package:saber_plus/features/games/guardian/data/guardian_repository.dart';
import 'package:saber_plus/features/games/guardian/data/guardian_resume_store.dart';
import 'helpers/guardian_fixture.dart';

const config = GuardianConfig(
  area: AcademicArea.mathematics,
  difficulty: PracticeDifficulty.medium,
);
Future<GuardianAttempt> answer(
  RemoteGuardianRepository repo, {
  String answerId = 'a1',
  String key = guardianRequestKey,
}) => repo.answer(
  id: 'attempt',
  questionId: 'q1',
  answerId: answerId,
  idempotencyKey: key,
);
DioException networkError(RequestOptions options) => DioException(
  requestOptions: options,
  type: DioExceptionType.receiveTimeout,
);
void main() {
  test(
    'mode must be a boolean; missing legacy field is normal, not competitive',
    () {
      expect(
        GuardianAttempt.fromJson(guardianState(legacy: true)).isCompetitive,
        isFalse,
      );
      expect(
        GuardianAttempt.fromJson(
          guardianState(competitive: true),
        ).isCompetitive,
        isTrue,
      );
      for (final value in [null, 'true', 1]) {
        expect(
          () => GuardianAttempt.fromJson({
            ...guardianState(),
            'competitive': value,
          }),
          throwsFormatException,
        );
      }
    },
  );
  test('demo refuses competition without creating any attempt', () async {
    final repo = DemoGuardianRepository();
    await expectLater(
      repo.start(config, competitive: true),
      throwsA(isA<ApiError>()),
    );
    expect(await repo.active(), isNull);
  });
  test(
    'explicit admission payload, normal payload stays compatible and never sends XP',
    () async {
      for (final competitive in [false, true]) {
        final h = GuardianHarness();
        h.handler = (o) => o.path.endsWith('/activo')
            ? null
            : guardianState(competitive: competitive);
        final repo = h.repo();
        await repo.active();
        expect(
          (await repo.start(config, competitive: competitive)).isCompetitive,
          competitive,
        );
        expect(h.requests.last.data, {
          'area': 'MATEMATICAS',
          'dificultad': 'MEDIO',
          if (competitive) 'competitive': true,
        });
      }
    },
  );
  test('OFF admission error has no normal fallback or second POST', () async {
    final h = GuardianHarness();
    h.handler = (o) {
      if (o.method == 'GET') return null;
      throw DioException(
        requestOptions: o,
        response: Response(
          requestOptions: o,
          statusCode: 403,
          data: {'code': 'COMPETITIVE_SOLO_DISABLED', 'message': 'Disabled'},
        ),
      );
    };
    final repo = h.repo();
    await repo.active();
    await expectLater(
      repo.start(config, competitive: true),
      throwsA(
        isA<ApiError>().having(
          (e) => e.code,
          'code',
          'COMPETITIVE_SOLO_DISABLED',
        ),
      ),
    );
    expect(h.requests.where((r) => r.method == 'POST').length, 1);
    expect(await h.store.read('api\u0000student'), isNull);
  });
  test('refuses mismatched admission before storing server result', () async {
    final h = GuardianHarness();
    h.handler = (o) => o.method == 'GET' ? null : guardianState();
    final repo = h.repo();
    await repo.active();
    await expectLater(
      repo.start(config, competitive: true),
      throwsFormatException,
    );
    expect(await h.store.read('api\u0000student'), isNull);
  });
  test('failed restore never permits a new attempt or demo fallback', () async {
    final h = GuardianHarness()..handler = (o) => throw networkError(o);
    final repo = h.repo();
    await expectLater(repo.active(), throwsA(isA<ApiError>()));
    await expectLater(
      repo.start(config, competitive: true),
      throwsA(isA<ApiError>()),
    );
    expect(h.requests.every((r) => r.method == 'GET'), isTrue);
  });
  test(
    'lost creation acknowledgement recovers competitive attempt without another POST',
    () async {
      final h = GuardianHarness();
      var created = false;
      h.handler = (o) {
        if (o.method == 'GET') {
          return created ? guardianState(competitive: true) : null;
        }
        created = true;
        throw networkError(o);
      };
      final repo = h.repo();
      await repo.active();
      await expectLater(
        repo.start(config, competitive: true),
        throwsA(isA<ApiError>()),
      );
      expect((await repo.active())!.isCompetitive, isTrue);
      expect(h.requests.where((r) => r.method == 'POST').length, 1);
    },
  );
  test(
    'answer is durable before POST and keeps same choice/key after process recreation',
    () async {
      final h = GuardianHarness();
      var acknowledged = false;
      h.handler = (o) {
        if (o.method == 'GET') return guardianState(competitive: true);
        if (!acknowledged) throw networkError(o);
        return guardianState(competitive: true, count: 1);
      };
      var repo = h.repo();
      await repo.active();
      await expectLater(answer(repo), throwsA(isA<ApiError>()));
      final saved = await h.store.read('api\u0000student');
      expect(saved!.pending!.idempotencyKey, guardianRequestKey);
      expect(h.values.values.join(), isNot(contains('enunciado')));
      repo.dispose();
      repo = h.repo();
      await repo.active();
      expect(repo.pending!.answerId, 'a1');
      await expectLater(answer(repo, answerId: 'b1'), throwsA(isA<ApiError>()));
      acknowledged = true;
      expect((await answer(repo)).correct, 1);
      final sends = h.requests
          .where((r) => r.path.endsWith('/respuestas'))
          .toList();
      expect(sends.length, 2);
      expect(sends[0].data, sends[1].data);
      expect(repo.pending, isNull);
    },
  );
  test(
    'after server saves but loses acknowledgement, GET confirms without resending',
    () async {
      final h = GuardianHarness();
      var stored = false;
      h.handler = (o) {
        if (o.method == 'GET') {
          return guardianState(competitive: true, count: stored ? 1 : 0);
        }
        stored = true;
        throw networkError(o);
      };
      final first = h.repo();
      await first.active();
      await expectLater(answer(first), throwsA(isA<ApiError>()));
      first.dispose();
      final restored = h.repo();
      expect((await restored.active())!.correct, 1);
      expect(restored.pending, isNull);
      expect(h.requests.where((r) => r.method == 'POST').length, 1);
    },
  );
  test('storage failure stops submission before any POST', () async {
    final h = GuardianHarness()
      ..handler = (_) => guardianState(competitive: true);
    final repo = h.repo();
    await repo.active();
    h.failWrites = true;
    await expectLater(answer(repo), throwsStateError);
    expect(h.requests.every((r) => r.method == 'GET'), isTrue);
  });
  test('mode mutation on answer retains durable pending submission', () async {
    final h = GuardianHarness();
    h.handler = (o) => guardianState(
      competitive: o.method == 'GET',
      count: o.method == 'POST' ? 1 : 0,
    );
    final repo = h.repo();
    await repo.active();
    await expectLater(answer(repo), throwsFormatException);
    expect(repo.pending, isNotNull);
    expect((await h.store.read('api\u0000student'))!.pending, isNotNull);
    expect((await repo.active())!.isCompetitive, isTrue);
  });
  test('wrong attempt id is rejected without clearing pending', () async {
    final h = GuardianHarness();
    h.handler = (o) => guardianState(
      competitive: true,
      count: o.method == 'POST' ? 1 : 0,
      id: o.method == 'POST' ? 'someone-else' : 'attempt',
    );
    final repo = h.repo();
    await repo.active();
    await expectLater(answer(repo), throwsFormatException);
    expect(repo.pending, isNotNull);
  });
  test(
    'unconfirmed response cannot advance gameplay or clear pending',
    () async {
      final h = GuardianHarness()
        ..handler = (_) => guardianState(competitive: true);
      final repo = h.repo();
      await repo.active();
      await expectLater(answer(repo), throwsFormatException);
      expect(repo.pending, isNotNull);
    },
  );
  test(
    'repeated terminal reads restore result and never send XP or additional POST',
    () async {
      final h = GuardianHarness();
      await h.store.save('api\u0000student', const GuardianResume('attempt'));
      h.handler = (o) => o.path.endsWith('/activo')
          ? null
          : guardianState(competitive: true, count: 6, status: 'VICTORIA');
      final repo = h.repo();
      expect((await repo.active())!.status, GuardianStatus.victory);
      for (var i = 0; i < 3; i++) {
        expect((await repo.get('attempt')).correct, 6);
      }
      expect(h.requests.every((r) => r.method == 'GET'), isTrue);
    },
  );
  test(
    'resume keys separate users and API endpoints; malformed record fails closed',
    () async {
      final h = GuardianHarness();
      await h.store.save('one\u0000student', const GuardianResume('attempt'));
      expect(await h.store.read('one\u0000other'), isNull);
      expect(await h.store.read('two\u0000student'), isNull);
      h.values[h.store.key('bad')] = jsonEncode({'attemptId': ''});
      await expectLater(h.store.read('bad'), throwsFormatException);
    },
  );
  test('invalid pending record or UUID cannot be silently dropped', () async {
    final h = GuardianHarness();
    h.values[h.store.key('api\u0000student')] = jsonEncode({
      'attemptId': 'attempt',
      'pending': {
        'attemptId': 'other',
        'questionId': 'q1',
        'answerId': 'a1',
        'idempotencyKey': guardianRequestKey,
      },
    });
    await expectLater(h.repo().active(), throwsFormatException);
    expect(h.requests, isEmpty);
    h.handler = (_) => guardianState();
    final repo = h.repo(scope: 'valid');
    await repo.active();
    await expectLater(answer(repo, key: 'invalid'), throwsFormatException);
    expect(h.requests.every((r) => r.method == 'GET'), isTrue);
  });
  test('mode remains immutable after repository recreation', () async {
    final h = GuardianHarness()
      ..handler = (_) => guardianState(competitive: true);
    final first = h.repo();
    await first.active();
    first.dispose();
    h.handler = (_) => guardianState();
    await expectLater(h.repo().active(), throwsFormatException);
    expect((await h.store.read('api\u0000student'))!.isCompetitive, isTrue);
  });
  test(
    'concurrent start and late response after logout cannot alter the new session',
    () async {
      final h = GuardianHarness();
      final completion = Completer<Object?>();
      h.handler = (o) => o.method == 'GET' ? null : completion.future;
      final repo = h.repo();
      await repo.active();
      final starting = repo.start(config, competitive: true);
      await expectLater(
        repo.start(config, competitive: true),
        throwsA(isA<ApiError>()),
      );
      repo.dispose();
      final assertion = expectLater(starting, throwsA(isA<ApiError>()));
      completion.complete(guardianState(competitive: true));
      await assertion;
      expect(await h.store.read('api\u0000student'), isNull);
    },
  );
  test(
    'stale local id 404 is cleared but authorization/network errors are not ignored',
    () async {
      for (final status in [404, 403]) {
        final h = GuardianHarness();
        await h.store.save('api\u0000student', const GuardianResume('attempt'));
        h.handler = (o) {
          if (o.path.endsWith('/activo')) return null;
          throw DioException(
            requestOptions: o,
            response: Response(
              requestOptions: o,
              statusCode: status,
              data: {'statusCode': status, 'message': 'Denied'},
            ),
          );
        };
        if (status == 404) {
          expect(await h.repo().active(), isNull);
          expect(await h.store.read('api\u0000student'), isNull);
        } else {
          await expectLater(h.repo().active(), throwsA(isA<ApiError>()));
          expect(await h.store.read('api\u0000student'), isNotNull);
        }
      }
    },
  );
}
