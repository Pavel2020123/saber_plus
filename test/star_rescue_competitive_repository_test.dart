import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:saber_plus/core/network/api_error.dart';
import 'package:saber_plus/features/academic/domain/academic_models.dart';
import 'package:saber_plus/features/games/star_rescue/data/demo_star_rescue_repository.dart';
import 'package:saber_plus/features/games/star_rescue/data/star_rescue_resume_store.dart';
import 'package:saber_plus/features/games/star_rescue/domain/star_rescue_models.dart';

import 'remote_star_rescue_repository_test.dart' as fixture;

Map<String, dynamic> competitiveState({
  int count = 0,
  String status = 'ACTIVO',
}) => {...fixture.state(count: count, status: status), 'competitive': true};

void main() {
  test('normal legacy is accepted; competitive marker must be boolean', () {
    expect(StarRescueAttempt.fromJson(fixture.state()).isCompetitive, false);
    expect(StarRescueAttempt.fromJson(competitiveState()).isCompetitive, true);
    for (final marker in ['true', 1, null]) {
      expect(
        () => StarRescueAttempt.fromJson({
          ...fixture.state(),
          'competitive': marker,
        }),
        throwsFormatException,
      );
    }
  });

  test('demo cannot opt into competition', () async {
    final repo = DemoStarRescueRepository();
    await expectLater(
      repo.start(AcademicArea.mathematics, competitive: true),
      throwsA(isA<ApiError>()),
    );
    expect(repo.current, null);
  });

  test(
    'competitive opt-in sends only filters and persists confirmed mode',
    () async {
      final h = fixture.Harness();
      final repo = h.repo();
      await repo.restore();
      h.handler = (_) => competitiveState();
      final attempt = await repo.start(
        AcademicArea.mathematics,
        competitive: true,
      );
      expect(attempt.isCompetitive, true);
      expect(h.requests.last.data, {
        'area': 'MATEMATICAS',
        'competitive': true,
      });
      expect((await h.store.read('api:student'))!.isCompetitive, true);
    },
  );

  test('OFF does not retry normally or create a saved attempt', () async {
    final h = fixture.Harness();
    final repo = h.repo();
    await repo.restore();
    h.handler = (o) => throw DioException(
      requestOptions: o,
      response: Response(
        requestOptions: o,
        statusCode: 403,
        data: {'code': 'COMPETITIVE_SOLO_DISABLED', 'message': 'OFF'},
      ),
    );
    await expectLater(
      repo.start(AcademicArea.mathematics, competitive: true),
      throwsA(
        isA<ApiError>().having(
          (e) => e.code,
          'code',
          'COMPETITIVE_SOLO_DISABLED',
        ),
      ),
    );
    expect(h.requests.where((o) => o.method == 'POST'), hasLength(1));
    expect(repo.current, null);
    expect(await h.store.read('api:student'), null);
  });

  for (final competitive in [false, true]) {
    test(
      'start rejects opposite server mode (requested $competitive)',
      () async {
        final h = fixture.Harness();
        final repo = h.repo();
        await repo.restore();
        h.handler = (_) => {...fixture.state(), 'competitive': !competitive};
        await expectLater(
          repo.start(AcademicArea.mathematics, competitive: competitive),
          throwsFormatException,
        );
        expect(repo.current, null);
        expect(await h.store.read('api:student'), null);
      },
    );
  }

  test('legacy response cannot acknowledge a competitive request', () async {
    final h = fixture.Harness();
    final repo = h.repo();
    await repo.restore();
    h.handler = (_) => fixture.state();
    await expectLater(
      repo.start(AcademicArea.mathematics, competitive: true),
      throwsFormatException,
    );
  });

  test(
    'resume rejects changed mode and preserves pending encrypted record',
    () async {
      final h = fixture.Harness();
      await h.store.save(
        'api:student',
        const StarRescueResume(
          'attempt',
          StarRescuePendingAnswer(
            attemptId: 'attempt',
            questionId: 'q0',
            answerId: 'yes',
            requestKey: fixture.key,
          ),
          true,
        ),
      );
      h.handler = (_) => fixture.state();
      await expectLater(h.repo().restore(), throwsFormatException);
      final saved = (await h.store.read('api:student'))!;
      expect(saved.isCompetitive, true);
      expect(saved.pending!.requestKey, fixture.key);
      expect(h.requests.every((o) => o.method == 'GET'), true);
    },
  );

  test(
    'unreceived competitive answer reopens and retries same payload',
    () async {
      final h = fixture.Harness();
      final repo = h.repo();
      h.handler = (_) => competitiveState();
      await repo.restore();
      h.handler = (o) => throw h.lost(o);
      await expectLater(fixture.answer(repo), throwsA(isA<ApiError>()));
      repo.dispose();
      h.handler = (_) => competitiveState();
      final restored = h.repo();
      expect((await restored.restore())!.isCompetitive, true);
      expect(restored.pending!.requestKey, fixture.key);
      h.handler = (_) => competitiveState(count: 1);
      await fixture.answer(restored);
      final sent = h.requests
          .where((o) => o.path.endsWith('/respuestas'))
          .toList();
      expect(sent, hasLength(2));
      expect(sent[0].data, sent[1].data);
      expect((await h.store.read('api:student'))!.isCompetitive, true);
      expect(restored.pending, null);
    },
  );

  test(
    'lost acknowledgment restores confirmed star without another POST',
    () async {
      final h = fixture.Harness();
      h.handler = (_) => competitiveState();
      final repo = h.repo();
      await repo.restore();
      h.handler = (o) => throw h.lost(o);
      await expectLater(fixture.answer(repo), throwsA(isA<ApiError>()));
      h.handler = (_) => competitiveState(count: 1);
      final restored = h.repo();
      expect((await restored.restore())!.progress.stars, 1);
      expect(restored.pending, null);
      expect(h.requests.where((o) => o.method == 'POST'), hasLength(1));
    },
  );

  test(
    'answer downgrade preserves selection, UUID and unconfirmed progress',
    () async {
      final h = fixture.Harness();
      h.handler = (_) => competitiveState();
      final repo = h.repo();
      await repo.restore();
      h.handler = (_) => fixture.state(count: 1);
      await expectLater(fixture.answer(repo), throwsFormatException);
      expect(repo.current!.isCompetitive, true);
      expect(repo.current!.progress.stars, 0);
      expect(repo.pending!.requestKey, fixture.key);
    },
  );

  test('conflicting accepted option does not clear pending answer', () async {
    final h = fixture.Harness();
    h.handler = (_) => competitiveState();
    final repo = h.repo();
    await repo.restore();
    h.handler = (_) {
      final body = competitiveState(count: 1);
      (body['ultimaRespuesta'] as Map)['respuestaId'] = 'no';
      return body;
    };
    await expectLater(fixture.answer(repo), throwsFormatException);
    expect(repo.pending!.answerId, 'yes');
    expect(repo.current!.progress.stars, 0);
  });

  for (final status in ['ABANDONADO', 'EXPIRADO', 'VICTORIA', 'AGOTADO']) {
    test('terminal $status recovers server mode without XP fields', () async {
      final h = fixture.Harness();
      await h.store.save(
        'api:student',
        const StarRescueResume('attempt', null, true),
      );
      h.handler = (o) {
        if (o.path.endsWith('/activo')) return null;
        if (status == 'AGOTADO') {
          return {
            ...competitiveState(count: 5, status: status),
            'respondidas': 10,
            'errores': 5,
          };
        }
        return competitiveState(
          count: status == 'VICTORIA' ? 6 : 0,
          status: status,
        );
      };
      final result = (await h.repo().restore())!;
      expect(result.finished, true);
      expect(result.isCompetitive, true);
      expect(h.requests.every((o) => o.method == 'GET'), true);
    });
  }

  test(
    'invalid saved mode fails before HTTP and leaves record untouched',
    () async {
      final h = fixture.Harness();
      h.values[h.store.key('api:student')] =
          '{"attemptId":"attempt","competitive":"true"}';
      await expectLater(h.repo().restore(), throwsFormatException);
      expect(h.requests, isEmpty);
      expect(h.values, hasLength(1));
    },
  );
}
