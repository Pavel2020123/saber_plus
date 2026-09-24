import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:saber_plus/core/network/api_error.dart';
import 'package:saber_plus/features/academic/domain/academic_models.dart';
import 'package:saber_plus/features/practice/domain/practice_models.dart';
import 'package:saber_plus/features/games/star_rescue/data/remote_star_rescue_repository.dart';
import 'package:saber_plus/features/games/star_rescue/data/star_rescue_resume_store.dart';
import 'package:saber_plus/features/games/star_rescue/domain/star_rescue_models.dart';

const key = '11111111-1111-4111-8111-111111111111';
Map<String, dynamic> state({int count = 0, String status = 'ACTIVO'}) => {
  'id': 'attempt',
  'area': 'MATEMATICAS',
  'reglas': {
    'version': 1,
    'target': 6,
    'questions': 10,
    'starsPerConstellation': 3,
  },
  'estado': status,
  'venceEn': '2026-09-20T12:00:00Z',
  'estrellas': count,
  'constelaciones': count ~/ 3,
  'respondidas': count,
  'aciertos': count,
  'errores': 0,
  'ultimaRespuesta': count == 0
      ? null
      : {
          'preguntaId': 'q${count - 1}',
          'respuestaId': 'yes',
          'esCorrecta': true,
          'estrellasGanadas': 1,
        },
  'pregunta': status != 'ACTIVO'
      ? null
      : {
          'id': 'q$count',
          'enunciado': 'Resuelve con la figura',
          'dificultad': 'BASICO',
          'imagenUrl': '/uploads/figure.png',
          'respuestas': [
            {'id': 'yes', 'texto': 'Uno'},
            {'id': 'no', 'texto': 'Dos'},
          ],
          'subtema': {
            'id': 'sub',
            'nombre': 'Proporciones',
            'tema': {'id': 'theme', 'nombre': 'Razones', 'area': 'MATEMATICAS'},
          },
          'caso': {
            'id': 'case',
            'titulo': 'Contexto',
            'contexto': 'Lee el gráfico',
            'imagenUrl': '/uploads/case.png',
          },
        },
};

class Harness {
  final values = <String, String>{};
  final requests = <RequestOptions>[];
  late final store = StarRescueResumeStore(
    readValue: (k) async => values[k],
    writeValue: (k, v) async {
      if (failStorage) throw StateError('storage failed');
      values[k] = v;
    },
  );
  bool failStorage = false;
  Object? Function(RequestOptions)? handler;
  late final dio = Dio(BaseOptions(baseUrl: 'https://api.invalid'))
    ..interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, callback) {
          requests.add(options);
          try {
            final data = handler?.call(options);
            callback.resolve(Response(requestOptions: options, data: data));
          } on DioException catch (e) {
            callback.reject(e);
          }
        },
      ),
    );
  RemoteStarRescueRepository repo([String scope = 'api:student']) =>
      RemoteStarRescueRepository(dio, store, scope: scope);
  Future<RemoteStarRescueRepository> started() async {
    final r = repo();
    await r.restore();
    handler = (_) => state();
    await r.start(AcademicArea.mathematics);
    return r;
  }

  DioException lost(RequestOptions o) =>
      DioException(requestOptions: o, type: DioExceptionType.receiveTimeout);
}

Future<StarRescueAttempt> answer(
  RemoteStarRescueRepository r, {
  String answerId = 'yes',
  String requestKey = key,
}) => r.answer(
  attemptId: 'attempt',
  questionId: 'q0',
  answerId: answerId,
  requestKey: requestKey,
);

void main() {
  test(
    'partial rescue and tenth-question victory follow the server counters',
    () {
      final partial = {
        ...state(count: 5, status: 'AGOTADO'),
        'respondidas': 10,
        'errores': 5,
      };
      final result = StarRescueAttempt.fromJson(partial);
      expect(result.progress.stars, 5);
      expect(result.progress.constellations, 1);
      expect(result.finished, true);
      expect(result.progress.won, false);
      final won = StarRescueAttempt.fromJson({
        ...state(count: 6, status: 'VICTORIA'),
        'respondidas': 10,
        'errores': 4,
      });
      expect(won.progress.won, true);
      for (final bad in [
        {...partial, 'constelaciones': 2},
        {...partial, 'estado': 'ACTIVO'},
        {...state(count: 6, status: 'EXPIRADO')},
        {...state(), 'area': 'UNKNOWN'},
        {
          ...state(count: 1),
          'ultimaRespuesta': {
            'preguntaId': 'q0',
            'respuestaId': 'yes',
            'esCorrecta': true,
            'estrellasGanadas': 0,
          },
        },
      ]) {
        expect(() => StarRescueAttempt.fromJson(bad), throwsFormatException);
      }
    },
  );
  test('unchanged progress does not confirm a pending answer', () async {
    final h = Harness();
    final r = await h.started();
    h.handler = (_) {
      final unchanged = state();
      (unchanged['pregunta'] as Map)['id'] = 'different-question';
      return unchanged;
    };
    await expectLater(answer(r), throwsFormatException);
    expect(r.pending, isNotNull);
    expect(r.current!.progress.stars, 0);
  });
  test(
    'missing API preserves the saved pending answer and never loads a demo',
    () async {
      final h = Harness();
      final r = await h.started();
      h.handler = (o) => throw h.lost(o);
      await expectLater(answer(r), throwsA(isA<ApiError>()));
      r.dispose();
      h.handler = (o) => throw DioException(
        requestOptions: o,
        response: Response(requestOptions: o, statusCode: 404),
        type: DioExceptionType.badResponse,
      );
      final next = h.repo();
      await expectLater(next.restore(), throwsA(isA<ApiError>()));
      expect((await h.store.read('api:student'))!.pending!.requestKey, key);
      expect(next.isDemo, false);
    },
  );
  test(
    'newer active attempt takes precedence over a saved terminal attempt',
    () async {
      final h = Harness();
      await h.store.save('api:student', const StarRescueResume('old-attempt'));
      h.handler = (_) => {...state(), 'id': 'new-attempt'};
      expect((await h.repo().restore())!.id, 'new-attempt');
      expect(h.requests, hasLength(1));
      expect(h.requests.single.path, '/rescate-estrellas/intentos/activo');
    },
  );
  test(
    'concurrent submissions are serialized; response for other attempt is rejected',
    () async {
      final h = Harness();
      final r = await h.started();
      h.handler = (_) => {...state(count: 1), 'id': 'other-attempt'};
      final first = answer(r);
      await expectLater(answer(r), throwsA(isA<ApiError>()));
      await expectLater(first, throwsFormatException);
      expect(
        h.requests.where((o) => o.path.endsWith('/respuestas')),
        hasLength(1),
      );
      expect(r.current!.progress.stars, 0);
      expect(r.pending!.requestKey, key);
    },
  );
  test('strict contract preserves context/images and terminal states', () {
    final result = StarRescueAttempt.fromJson(state());
    expect(result.question!.imageUrl, '/uploads/figure.png');
    expect(result.question!.caseContent!.context, 'Lee el gráfico');
    for (final status in ['ABANDONADO', 'EXPIRADO']) {
      expect(StarRescueAttempt.fromJson(state(status: status)).finished, true);
    }
    expect(
      StarRescueAttempt.fromJson(
        state(count: 6, status: 'VICTORIA'),
      ).progress.won,
      true,
    );
    for (final bad in [
      {
        ...state(),
        'reglas': {
          'version': 2,
          'target': 6,
          'questions': 10,
          'starsPerConstellation': 3,
        },
      },
      {...state(), 'estado': 'UNKNOWN'},
      {...state(), 'pregunta': null},
      {...state(), 'estrellas': 7},
      {...state(), 'errores': 5},
    ]) {
      expect(() => StarRescueAttempt.fromJson(bad), throwsFormatException);
    }
  });
  test(
    'restore precedes start; sends filters only, no owner or client score',
    () async {
      final h = Harness();
      final r = h.repo();
      await expectLater(
        r.start(AcademicArea.mathematics),
        throwsA(isA<ApiError>()),
      );
      expect(h.requests, isEmpty);
      await r.restore();
      h.handler = (_) => state();
      await r.start(
        AcademicArea.mathematics,
        themeId: 'theme',
        subtopicId: 'sub',
        difficulty: PracticeDifficulty.easy,
      );
      expect(h.requests.last.data, {
        'area': 'MATEMATICAS',
        'temaId': 'theme',
        'subtemaId': 'sub',
        'dificultad': 'BASICO',
      });
    },
  );
  test('persists before POST, server progress is authoritative', () async {
    final h = Harness();
    final r = await h.started();
    h.handler = (o) {
      expect(h.values.values.single, contains(key));
      expect(o.data, {
        'preguntaId': 'q0',
        'respuestaId': 'yes',
        'idempotencyKey': key,
      });
      return state(count: 1);
    };
    final result = await answer(r);
    expect(result.progress.stars, 1);
    expect(r.pending, null);
    expect(h.values.values.single, isNot(contains(key)));
  });
  test(
    'lost acknowledgment survives reopening and synchronizes without regrading',
    () async {
      final h = Harness();
      final r = await h.started();
      h.handler = (o) => throw h.lost(o);
      await expectLater(answer(r), throwsA(isA<ApiError>()));
      expect(r.current!.progress.stars, 0);
      r.dispose();
      h.handler = (_) => state(count: 1);
      final restored = h.repo();
      expect((await restored.restore())!.progress.stars, 1);
      expect(restored.pending, null);
      expect(
        h.requests.where((o) => o.path.endsWith('/respuestas')),
        hasLength(1),
      );
    },
  );
  test(
    'unreceived submission survives reopening and retries identical UUID/option',
    () async {
      final h = Harness();
      final r = await h.started();
      h.handler = (o) => throw h.lost(o);
      await expectLater(answer(r), throwsA(isA<ApiError>()));
      r.dispose();
      final restored = h.repo();
      h.handler = (_) => state();
      await restored.restore();
      expect(restored.pending!.requestKey, key);
      await expectLater(
        answer(restored, answerId: 'no'),
        throwsA(isA<ApiError>()),
      );
      h.handler = (_) => state(count: 1);
      await answer(restored);
      final sent = h.requests
          .where((o) => o.path.endsWith('/respuestas'))
          .toList();
      expect(sent, hasLength(2));
      expect(sent[0].data, sent[1].data);
    },
  );
  test('storage failure prevents answer POST', () async {
    final h = Harness();
    final r = await h.started();
    h.failStorage = true;
    await expectLater(answer(r), throwsStateError);
    expect(h.requests.where((o) => o.path.endsWith('/respuestas')), isEmpty);
    expect(r.current!.progress.stars, 0);
  });
  test(
    'failure clearing ack still retains pending and can recover terminal victory',
    () async {
      final h = Harness();
      final r = await h.started();
      h.handler = (_) {
        h.failStorage = true;
        return state(count: 6, status: 'VICTORIA');
      };
      await expectLater(answer(r), throwsStateError);
      expect(r.pending, isNotNull);
      h.failStorage = false;
      h.handler = (_) => state(count: 6, status: 'VICTORIA');
      expect((await h.repo().restore())!.finished, true);
    },
  );
  test(
    'expired answer never invents incorrect feedback; abandonment persists',
    () async {
      final h = Harness();
      final r = await h.started();
      h.handler = (_) => state(status: 'EXPIRADO');
      final result = await answer(r);
      expect(result.status, 'EXPIRADO');
      expect(result.lastCorrect, null);
      expect(result.progress.stars, 0);
      expect(r.pending, null);
      h.handler = (_) => state();
      await r.start(AcademicArea.mathematics);
      h.handler = (_) => state(status: 'ABANDONADO');
      expect((await r.abandon('attempt')).status, 'ABANDONADO');
      expect(
        h.requests.last.path,
        '/rescate-estrellas/intentos/attempt/abandonar',
      );
    },
  );
  test('account and API scope isolate encrypted resume record', () async {
    final h = Harness();
    final r = await h.started();
    h.handler = (o) => throw h.lost(o);
    await expectLater(answer(r), throwsA(isA<ApiError>()));
    h.handler = (_) => null;
    for (final scope in ['api:another-student', 'other-api:student']) {
      final other = h.repo(scope);
      expect(await other.restore(), null);
      expect(other.pending, null);
    }
    expect((await h.store.read('api:student'))!.pending!.requestKey, key);
  });
  test(
    'dispose during storage read prevents requests under a different account',
    () async {
      final h = Harness();
      final gate = Completer<String?>();
      final store = StarRescueResumeStore(
        readValue: (_) => gate.future,
        writeValue: (_, _) async {},
      );
      final r = RemoteStarRescueRepository(h.dio, store, scope: 'user');
      final restoring = r.restore();
      r.dispose();
      gate.complete(null);
      await expectLater(restoring, throwsA(isA<ApiError>()));
      expect(h.requests, isEmpty);
    },
  );
  test(
    'malformed response and network failure do not fall back to demo',
    () async {
      final h = Harness();
      final r = h.repo();
      h.handler = (_) => '<html>Not deployed</html>';
      await expectLater(r.restore(), throwsFormatException);
      h.handler = (o) => throw h.lost(o);
      await expectLater(r.restore(), throwsA(isA<ApiError>()));
      expect(r.current, null);
      expect(r.isDemo, false);
    },
  );
  test('corrupt saved state is not silently deleted or resent', () async {
    final h = Harness();
    h.values[h.store.key('api:student')] = jsonEncode({
      'attemptId': 'other',
      'pending': {
        'attemptId': 'attempt',
        'questionId': 'q0',
        'answerId': 'yes',
        'requestKey': key,
      },
    });
    await expectLater(h.repo().restore(), throwsFormatException);
    expect(h.requests, isEmpty);
    expect(h.values, hasLength(1));
  });
}
