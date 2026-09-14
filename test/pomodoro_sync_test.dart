import 'dart:async';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:saber_plus/core/database/app_database.dart';
import 'package:saber_plus/core/network/auth_interceptor.dart';
import 'package:saber_plus/core/sync/safe_sync_models.dart';
import 'package:saber_plus/features/study_time/data/drift_study_time_repository.dart';
import 'package:saber_plus/features/study_time/data/pomodoro_sync_worker.dart';
import 'package:saber_plus/features/study_time/domain/study_evolution.dart';
import 'package:saber_plus/features/study_time/domain/study_time_models.dart';

const eventA = 'pomodoro:11111111-1111-4111-8111-111111111111';
const eventB = 'pomodoro:22222222-2222-4222-8222-222222222222';
final now = DateTime.utc(2026, 9, 14, 18);
StudyTimeRecord record({
  String id = eventA,
  String user = 'A',
  StudyTimeSource source = StudyTimeSource.pomodoro,
  DateTime? ended,
}) => StudyTimeRecord(
  userId: user,
  eventId: id,
  source: source,
  durationSeconds: 1500,
  recordedAt:
      ended ??
      now
          .subtract(const Duration(hours: 1))
          .add(const Duration(milliseconds: 123, microseconds: 456)),
);
Map<String, dynamic> acknowledgement(RequestOptions o) {
  final event = ((o.data as Map)['eventos'] as List).single as Map;
  return {
    'version': 1,
    'politica': studyTimePolicy,
    'confirmados': [
      {...event, 'reutilizado': false},
    ],
  };
}

void main() {
  late AppDatabase db;
  late DriftStudyTimeRepository records;
  late Dio dio;
  late PomodoroSyncWorker worker;
  SyncSessionSnapshot? session;
  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    records = DriftStudyTimeRepository(db);
    dio = Dio();
    session = const SyncSessionSnapshot(userId: 'A', revision: 7);
    worker = PomodoroSyncWorker(
      db,
      dio,
      currentSession: () => session,
      now: () => now,
    );
  });
  tearDown(() async {
    worker.dispose();
    dio.close(force: true);
    await db.close();
  });

  test(
    'inserción local y cola atómicas, ID inmutable y milisegundos conservados',
    () async {
      await records.record(record());
      await records.record(record(ended: now));
      final queued = (await db.pendingPomodoros('A')).single;
      expect(queued.endedAtUtc, '2026-09-14T17:00:00.123Z');
      expect((await records.watchAll('A').first).length, 1);
      expect(await db.pendingPomodoros('B'), isEmpty);
      await records.record(
        record(id: 'practice:attempt', source: StudyTimeSource.practice),
      );
      await records.record(
        record(id: 'diagnostic:attempt', source: StudyTimeSource.diagnostic),
      );
      expect(await db.pendingPomodoros('A'), hasLength(1));
    },
  );
  test(
    'no importa un registro local previo aunque se vuelva a notificar',
    () async {
      await db.saveStudyTimeEntry(
        StudyTimeEntriesCompanion.insert(
          userId: 'A',
          eventId: eventA,
          source: 'POMODORO',
          durationSeconds: 1500,
          recordedAt: now,
        ),
      );
      await records.record(record());
      expect(await db.pendingPomodoros('A'), isEmpty);
    },
  );
  test(
    'confirma solo la respuesta exacta y conserva el historial tras reconocerla',
    () async {
      await records.record(record());
      var calls = 0;
      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (o, h) {
            calls++;
            expect(o.path, '/tiempo-estudio/me/pomodoros');
            expect(o.extra[AuthInterceptor.sessionRevisionKey], 7);
            expect(o.data.toString(), isNot(contains('userId')));
            h.resolve(Response(requestOptions: o, data: acknowledgement(o)));
          },
        ),
      );
      expect(await worker.synchronize(), 1);
      expect((await db.findPomodoro('A', eventA))!.status, 'confirmed');
      await records.record(record());
      expect(await worker.synchronize(), 0);
      expect(calls, 1);
      expect(await records.watchAll('A').first, hasLength(1));
    },
  );
  test(
    'timeout deja pendiente; el reintento conserva exactamente fecha, ID y cuerpo',
    () async {
      await records.record(record());
      final bodies = <Object?>[];
      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (o, h) {
            bodies.add(o.data);
            if (bodies.length == 1) {
              h.reject(
                DioException(
                  requestOptions: o,
                  type: DioExceptionType.receiveTimeout,
                ),
              );
            } else {
              h.resolve(Response(requestOptions: o, data: acknowledgement(o)));
            }
          },
        ),
      );
      expect(await worker.synchronize(), 0);
      expect((await db.findPomodoro('A', eventA))!.errorCode, 'network');
      expect(await worker.synchronize(), 1);
      expect(bodies[0], bodies[1]);
    },
  );
  test(
    'confirmación incompleta, de otro ID o con fecha cambiada no retira el pendiente',
    () async {
      await records.record(record());
      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (o, h) {
            final ack = acknowledgement(o);
            ((ack['confirmados'] as List).single as Map)['eventoId'] = eventB;
            h.resolve(Response(requestOptions: o, data: ack));
          },
        ),
      );
      expect(await worker.synchronize(), 0);
      expect((await db.findPomodoro('A', eventA))!.status, 'blocked');
      expect((await db.findPomodoro('A', eventA))!.errorCode, 'unconfirmed');
    },
  );
  test(
    'conflicto individual no impide sincronizar otro bloque válido',
    () async {
      await records.record(record());
      await records.record(
        record(id: eventB, ended: now.subtract(const Duration(minutes: 20))),
      );
      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (o, h) {
            final id =
                (((o.data as Map)['eventos'] as List).single
                    as Map)['eventoId'];
            if (id == eventA) {
              h.reject(
                DioException(
                  requestOptions: o,
                  response: Response(requestOptions: o, statusCode: 409),
                  type: DioExceptionType.badResponse,
                ),
              );
            } else {
              h.resolve(Response(requestOptions: o, data: acknowledgement(o)));
            }
          },
        ),
      );
      expect(await worker.synchronize(), 1);
      expect((await db.findPomodoro('A', eventA))!.errorCode, 'conflict');
      expect((await db.findPomodoro('A', eventB))!.status, 'confirmed');
      await worker.keepLocalOnly(eventA);
      expect((await db.findPomodoro('A', eventA))!.status, 'discarded');
      expect(await records.watchAll('A').first, hasLength(2));
    },
  );
  test(
    'reintento de conflicto usa el mismo bloque, sin reescribirlo',
    () async {
      await records.record(record());
      var calls = 0;
      final bodies = <Object?>[];
      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (o, h) {
            bodies.add(o.data);
            if (calls++ == 0) {
              h.reject(
                DioException(
                  requestOptions: o,
                  response: Response(requestOptions: o, statusCode: 409),
                ),
              );
            } else {
              h.resolve(Response(requestOptions: o, data: acknowledgement(o)));
            }
          },
        ),
      );
      await worker.synchronize();
      await worker.retry(eventA);
      expect(bodies[0], bodies[1]);
      expect((await db.findPomodoro('A', eventA))!.status, 'confirmed');
    },
  );
  test(
    'fechas futuras y antiguas nunca enviadas quedan distinguibles sin red',
    () async {
      await records.record(record(ended: now.add(const Duration(days: 1))));
      await records.record(
        record(id: eventB, ended: now.subtract(const Duration(days: 91))),
      );
      var calls = 0;
      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (o, h) {
            calls++;
            h.reject(DioException(requestOptions: o));
          },
        ),
      );
      await worker.synchronize();
      expect((await db.findPomodoro('A', eventA))!.errorCode, 'clock_future');
      expect((await db.findPomodoro('A', eventB))!.errorCode, 'expired');
      expect(calls, 0);
    },
  );
  test(
    'reintento incierto antiguo llega a la API para reconocerlo, no se pierde por edad',
    () async {
      await records.record(
        record(ended: now.subtract(const Duration(days: 91))),
      );
      final row = (await db.findPomodoro('A', eventA))!;
      await db.updatePomodoroIfUnchanged(
        row,
        const PomodoroSyncEntriesCompanion(attempts: Value(1)),
      );
      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (o, h) =>
              h.resolve(Response(requestOptions: o, data: acknowledgement(o))),
        ),
      );
      expect(await worker.synchronize(), 1);
    },
  );
  for (final status in [401, 403, 404, 410, 429, 500]) {
    test('HTTP $status conserva el bloque pendiente sin descartarlo', () async {
      await records.record(record());
      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (o, h) => h.reject(
            DioException(
              requestOptions: o,
              response: Response(requestOptions: o, statusCode: status),
            ),
          ),
        ),
      );
      await worker.synchronize();
      expect((await db.findPomodoro('A', eventA))!.status, 'pending');
    });
  }
  test(
    'cambio de cuenta o revisión durante red no confirma datos de otra sesión',
    () async {
      await records.record(record());
      final entered = Completer<void>();
      final release = Completer<void>();
      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (o, h) async {
            entered.complete();
            await release.future;
            h.resolve(Response(requestOptions: o, data: acknowledgement(o)));
          },
        ),
      );
      final run = worker.synchronize();
      await entered.future;
      session = const SyncSessionSnapshot(userId: 'B', revision: 8);
      release.complete();
      expect(await run, 0);
      expect((await db.findPomodoro('A', eventA))!.status, 'pending');
      expect(await db.findPomodoro('B', eventA), isNull);
      expect(await worker.synchronize(), 0);
    },
  );
  test(
    'sin sesión no envía y dos sincronizaciones simultáneas comparten trabajo',
    () async {
      await records.record(record());
      session = null;
      expect(await worker.synchronize(), 0);
      session = const SyncSessionSnapshot(userId: 'A', revision: 7);
      var calls = 0;
      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (o, h) {
            calls++;
            h.resolve(Response(requestOptions: o, data: acknowledgement(o)));
          },
        ),
      );
      await Future.wait([worker.synchronize(), worker.synchronize()]);
      expect(calls, 1);
    },
  );
  test(
    'migración v8 a v9 conserva historial, no importa antiguos y persiste recibos',
    () async {
      final directory = await Directory.systemTemp.createTemp(
        'saberplus-p4b-test-',
      );
      final file = File('${directory.path}/study.sqlite');
      AppDatabase? disk;
      try {
        disk = AppDatabase(NativeDatabase(file));
        await DriftStudyTimeRepository(disk).record(record());
        await disk.customStatement('DROP TABLE pomodoro_sync_entries');
        await disk.customStatement('PRAGMA user_version = 8');
        await disk.close();
        disk = AppDatabase(NativeDatabase(file));
        expect(
          await DriftStudyTimeRepository(disk).watchAll('A').first,
          hasLength(1),
        );
        expect(await disk.pendingPomodoros('A'), isEmpty);
        await DriftStudyTimeRepository(disk).record(record(id: eventB));
        await disk.close();
        disk = AppDatabase(NativeDatabase(file));
        expect((await disk.pendingPomodoros('A')).single.eventId, eventB);
      } finally {
        await disk?.close();
        // Solo el directorio temporal creado en esta prueba.
        await directory.delete(recursive: true);
      }
    },
  );
}
