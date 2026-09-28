import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:saber_plus/core/database/app_database.dart';
import 'package:saber_plus/core/sync/safe_sync_models.dart';
import 'package:saber_plus/features/flashcards/data/deferred_review_repository.dart';
import 'package:saber_plus/features/flashcards/domain/deferred_review.dart';

final instant = DateTime.utc(2026, 9, 27, 10);
Map<String, Object> snapshot({int revision = 1}) => {
  'tarjetaId': 'card',
  'contenidoVersion': 'library-v1',
  'paso': 0,
  'revision': revision,
  'revisadoEn': instant.toIso8601String(),
  'venceEn': instant.add(const Duration(days: 1)).toIso8601String(),
};
void main() {
  late AppDatabase db;
  late Dio dio;
  late DeferredReviewRepository repo;
  SyncSessionSnapshot? session;
  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    dio = Dio();
    session = const SyncSessionSnapshot(userId: 'A', revision: 1);
    repo = DeferredReviewRepository(
      db,
      dio,
      currentSession: () => session,
      allowedCardIds: {'card'},
      now: () => instant,
    );
  });
  tearDown(() async {
    repo.dispose();
    dio.close();
    await db.close();
  });
  Future<void> enqueue() => repo.enqueue(
    userId: 'A',
    cardId: 'card',
    outcome: RecallOutcome.remembered,
  );
  test(
    'queue and provisional agenda commit together, no second in-flight review',
    () async {
      await enqueue();
      final row = (await repo.watch('A').first).single;
      expect(row.confirmedJson, isNull);
      expect(row.provisionalJson, isNotNull);
      expect(row.status, 'pending');
      await expectLater(enqueue(), throwsStateError);
      await expectLater(
        repo.enqueue(
          userId: 'B',
          cardId: 'card',
          outcome: RecallOutcome.remembered,
        ),
        throwsStateError,
      );
    },
  );
  test(
    'lost response retries identical ID/body and consumes validated receipt',
    () async {
      final bodies = <String>[];
      var fail = true;
      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (o, h) {
            if (o.method == 'GET') {
              h.resolve(
                Response(
                  requestOptions: o,
                  data: {
                    'version': 1,
                    'contenidoVersion': 'library-v1',
                    'agenda': [snapshot()],
                  },
                ),
              );
              return;
            }
            bodies.add(jsonEncode(o.data));
            if (fail) {
              h.reject(
                DioException(
                  requestOptions: o,
                  type: DioExceptionType.connectionError,
                ),
              );
              return;
            }
            h.resolve(
              Response(
                requestOptions: o,
                data: {
                  'version': 1,
                  'eventoId': o.data['eventoId'],
                  'estado': 'scheduled',
                  'agenda': snapshot(),
                },
              ),
            );
          },
        ),
      );
      await enqueue();
      await repo.synchronize('A');
      expect((await repo.watch('A').first).single.status, 'pending');
      fail = false;
      await repo.synchronize('A');
      expect(bodies[0], bodies[1]);
      final row = (await repo.watch('A').first).single;
      expect(row.pendingJson, isNull);
      expect(row.status, 'synced');
      await enqueue();
      expect(
        (await repo.watch('A').first).single.pendingJson,
        isNull,
      ); // early practice stays local
    },
  );
  test(
    'conflict stays blocked; refresh never silently reissues an answer',
    () async {
      var posts = 0;
      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (o, h) {
            if (o.method == 'GET') {
              h.resolve(
                Response(
                  requestOptions: o,
                  data: {
                    'version': 1,
                    'contenidoVersion': 'library-v1',
                    'agenda': [snapshot(revision: 2)],
                  },
                ),
              );
              return;
            }
            posts++;
            h.reject(
              DioException(
                requestOptions: o,
                response: Response(requestOptions: o, statusCode: 409),
              ),
            );
          },
        ),
      );
      await enqueue();
      await repo.synchronize('A');
      await repo.synchronize('A');
      final row = (await repo.watch('A').first).single;
      expect(row.status, 'conflict');
      expect(row.pendingJson, isNotNull);
      expect(posts, 1);
      expect(jsonDecode(row.confirmedJson!)['revision'], 2);
      await repo.discardBlocked('A', 'card');
      expect((await repo.watch('A').first).single.pendingJson, isNull);
      expect(posts, 1);
    },
  );
  test('late response cannot confirm another session', () async {
    final started = Completer<void>();
    RequestInterceptorHandler? handler;
    RequestOptions? options;
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (o, h) {
          options = o;
          handler = h;
          started.complete();
        },
      ),
    );
    await enqueue();
    final work = repo.synchronize('A');
    await started.future;
    session = const SyncSessionSnapshot(userId: 'B', revision: 2);
    handler!.resolve(
      Response(
        requestOptions: options!,
        data: {
          'version': 1,
          'eventoId': options!.data['eventoId'],
          'estado': 'scheduled',
          'agenda': snapshot(),
        },
      ),
    );
    await work;
    session = const SyncSessionSnapshot(userId: 'A', revision: 3);
    expect((await repo.watch('A').first).single.status, 'pending');
  });
  test('reinstall restores only server-confirmed records', () async {
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (o, h) => h.resolve(
          Response(
            requestOptions: o,
            data: {
              'version': 1,
              'contenidoVersion': 'library-v1',
              'agenda': [snapshot()],
            },
          ),
        ),
      ),
    );
    await repo.refresh('A');
    final row = (await repo.watch('A').first).single;
    expect(row.status, 'synced');
    expect(row.pendingJson, isNull);
  });
  test('malformed acknowledgment is not deleted or replaced', () async {
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (o, h) => h.resolve(
          Response(
            requestOptions: o,
            data: {'version': 1, 'eventoId': 'wrong'},
          ),
        ),
      ),
    );
    await enqueue();
    final original = (await repo.watch('A').first).single.pendingJson;
    await repo.synchronize('A');
    expect((await repo.watch('A').first).single.pendingJson, original);
  });
  test(
    'v9 migration and process reopen preserve outbox without importing old counters',
    () async {
      final dir = await Directory.systemTemp.createTemp(
        'saberplus-review-test-',
      );
      final file = File('${dir.path}/agenda.sqlite');
      AppDatabase? disk;
      try {
        disk = AppDatabase(NativeDatabase(file));
        await disk.customSelect('SELECT 1').get();
        await disk.customStatement('DROP TABLE deferred_review_entries');
        await disk.customStatement('PRAGMA user_version = 9');
        await disk.close();
        disk = AppDatabase(NativeDatabase(file));
        var local = DeferredReviewRepository(
          disk,
          dio,
          currentSession: () => session,
          allowedCardIds: {'card'},
          now: () => instant,
        );
        expect(await local.watch('A').first, isEmpty);
        await local.enqueue(
          userId: 'A',
          cardId: 'card',
          outcome: RecallOutcome.remembered,
        );
        final pending = (await local.watch('A').first).single.pendingJson;
        await disk.close();
        disk = AppDatabase(NativeDatabase(file));
        local = DeferredReviewRepository(
          disk,
          dio,
          currentSession: () => session,
          allowedCardIds: {'card'},
        );
        expect((await local.watch('A').first).single.pendingJson, pending);
      } finally {
        await disk?.close();
        await dir.delete(recursive: true);
      }
    },
  );
}
