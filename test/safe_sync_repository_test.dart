import 'dart:async';

import 'package:dio/dio.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:saber_plus/core/database/app_database.dart';
import 'package:saber_plus/core/sync/drift_safe_sync_repository.dart';
import 'package:saber_plus/core/sync/safe_sync_models.dart';
import 'package:saber_plus/features/progress/domain/progress_models.dart';

enum _ServerMode {
  offline,
  online,
  rejectNotebook,
  holdWrites,
  holdRead,
  cancel,
}

class _HeldRequest {
  _HeldRequest(this.options, this.handler);

  final RequestOptions options;
  final RequestInterceptorHandler handler;

  void succeed({Map<String, dynamic> data = const {}}) => handler.resolve(
    Response(requestOptions: options, statusCode: 200, data: data),
  );

  void reject() => handler.reject(
    DioException.badResponse(
      statusCode: 404,
      requestOptions: options,
      response: Response(
        requestOptions: options,
        statusCode: 404,
        data: const {'message': 'La pregunta ya no está disponible.'},
      ),
    ),
  );
}

void main() {
  late AppDatabase database;
  late Dio dio;
  late DriftSafeSyncRepository repository;
  var mode = _ServerMode.offline;
  var remoteProgress = <String, int>{};
  final sentRequests = <RequestOptions>[];
  late Completer<_HeldRequest> heldRequest;
  SyncSessionSnapshot? session;

  setUp(() {
    mode = _ServerMode.offline;
    remoteProgress = {};
    sentRequests.clear();
    heldRequest = Completer<_HeldRequest>();
    session = const SyncSessionSnapshot(userId: 'student-1', revision: 1);
    database = AppDatabase(NativeDatabase.memory());
    dio = Dio(BaseOptions(baseUrl: 'http://localhost:3000'));
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          sentRequests.add(options);
          if ((mode == _ServerMode.holdWrites && options.method != 'GET') ||
              (mode == _ServerMode.holdRead && options.method == 'GET')) {
            heldRequest.complete(_HeldRequest(options, handler));
            return;
          }
          if (mode == _ServerMode.cancel) {
            handler.reject(
              DioException(
                requestOptions: options,
                type: DioExceptionType.cancel,
              ),
            );
            return;
          }
          if (mode == _ServerMode.offline) {
            handler.reject(
              DioException(
                requestOptions: options,
                type: DioExceptionType.connectionError,
                message: 'Sin conexión',
              ),
            );
            return;
          }
          if (mode == _ServerMode.rejectNotebook &&
              options.path.startsWith('/cuaderno-errores/')) {
            handler.reject(
              DioException.badResponse(
                statusCode: 404,
                requestOptions: options,
                response: Response<Map<String, dynamic>>(
                  requestOptions: options,
                  statusCode: 404,
                  data: {'message': 'La pregunta ya no está disponible.'},
                ),
              ),
            );
            return;
          }
          if (options.method == 'GET' &&
              options.path == '/simulacros/progreso') {
            handler.resolve(
              Response<Map<String, dynamic>>(
                requestOptions: options,
                statusCode: 200,
                data: {'porSubtema': remoteProgress},
              ),
            );
            return;
          }
          handler.resolve(
            Response<Map<String, dynamic>>(
              requestOptions: options,
              statusCode: 200,
              data: const {'mensaje': 'Actualizado'},
            ),
          );
        },
      ),
    );
    repository = DriftSafeSyncRepository(
      dio,
      database,
      currentSession: () => session,
    );
  });

  tearDown(() async {
    dio.close(force: true);
    await database.close();
  });

  Future<SafeWriteResult> saveNote(String note) => repository.saveNotebookEntry(
    userId: 'student-1',
    questionId: 'question-1',
    note: note,
    status: NotebookStatus.pending.backendValue,
  );

  for (final reject in [false, true]) {
    test(
      'una respuesta ${reject ? 'rechazada' : 'exitosa'} no pisa una edición posterior',
      () async {
        await saveNote('Primera edición');
        mode = _ServerMode.holdWrites;
        final syncing = repository.synchronize('student-1');
        final request = await heldRequest.future;
        final saving = saveNote('Edición nueva');
        await repository
            .watchOperations('student-1')
            .firstWhere(
              (rows) => rows.single.payload['nota'] == 'Edición nueva',
            );
        if (reject) {
          request.reject();
        } else {
          request.succeed();
        }
        final report = await syncing;
        expect(report.synced, 0);
        expect(report.pending, 1);
        expect(report.blocked, 0);
        expect((await saving).disposition, SafeWriteDisposition.queued);
        final pending =
            (await repository.watchOperations('student-1').first).single;
        expect(pending.payload['nota'], 'Edición nueva');
        expect(pending.attempts, 0);
        expect(pending.lastError, isNull);

        mode = _ServerMode.online;
        expect((await repository.synchronize('student-1')).synced, 1);
        expect(sentRequests.last.data['nota'], 'Edición nueva');
      },
    );
  }

  test(
    'ABA: descartar y volver a crear el mismo texto no confirma una fila nueva',
    () async {
      await saveNote('Mismo texto');
      final original = (await database.getPendingOperations(
        'student-1',
      )).single;
      mode = _ServerMode.holdWrites;
      final syncing = repository.synchronize('student-1');
      final request = await heldRequest.future;
      await repository.discard('student-1', original.id);
      final saving = saveNote('Mismo texto');
      await database
          .watchPendingOperations('student-1')
          .firstWhere(
            (rows) =>
                rows.isNotEmpty && rows.single.revision != original.revision,
          );
      request.succeed();
      expect((await syncing).synced, 0);
      expect((await saving).disposition, SafeWriteDisposition.queued);
      final next = (await database.getPendingOperations('student-1')).single;
      expect(next.payloadJson, original.payloadJson);
      expect(next.revision, isNot(original.revision));
    },
  );

  test(
    'conserva el porcentaje mayor editado durante el POST en vuelo',
    () async {
      await repository.saveStudyProgress(
        userId: 'student-1',
        subtopicId: 'subtopic-1',
        percentage: 50,
      );
      mode = _ServerMode.holdWrites;
      final syncing = repository.synchronize('student-1');
      final request = await heldRequest.future;
      expect(request.options.data['porcentaje'], 50);
      final saving = repository.saveStudyProgress(
        userId: 'student-1',
        subtopicId: 'subtopic-1',
        percentage: 100,
      );
      await repository
          .watchOperations('student-1')
          .firstWhere((rows) => rows.single.payload['porcentaje'] == 100);
      request.succeed();
      expect((await syncing).pending, 1);
      expect((await saving).disposition, SafeWriteDisposition.queued);
      mode = _ServerMode.online;
      await repository.synchronize('student-1');
      expect(sentRequests.last.data['porcentaje'], 100);
    },
  );

  test(
    'no envía una cola sin sesión ni con la cuenta de otro usuario',
    () async {
      await saveNote('Privado de A');
      sentRequests.clear();
      mode = _ServerMode.online;
      session = null;
      expect((await repository.synchronize('student-1')).pending, 1);
      session = const SyncSessionSnapshot(userId: 'student-2', revision: 2);
      expect((await repository.synchronize('student-1')).pending, 1);
      expect(sentRequests, isEmpty);
    },
  );

  test(
    'cambio de sesión entre GET y POST no envía progreso de A con sesión B',
    () async {
      await repository.saveStudyProgress(
        userId: 'student-1',
        subtopicId: 'subtopic-1',
        percentage: 75,
      );
      sentRequests.clear();
      mode = _ServerMode.holdRead;
      final syncing = repository.synchronize('student-1');
      final request = await heldRequest.future;
      session = const SyncSessionSnapshot(userId: 'student-2', revision: 2);
      request.succeed(data: {'porSubtema': <String, int>{}});
      final report = await syncing;
      expect(report.pending, 1);
      expect(report.blocked, 0);
      expect(sentRequests.map((request) => request.method), ['GET']);
    },
  );

  test(
    'la sesión que cambia en vuelo conserva todas las filas para su dueño',
    () async {
      await saveNote('A');
      await repository.saveNotebookEntry(
        userId: 'student-1',
        questionId: 'question-2',
        note: 'B',
        status: 'PENDIENTE',
      );
      sentRequests.clear();
      mode = _ServerMode.holdWrites;
      final syncing = repository.synchronize('student-1');
      final request = await heldRequest.future;
      session = const SyncSessionSnapshot(userId: 'student-1', revision: 2);
      request.succeed();
      final report = await syncing;
      expect(report.pending, 2);
      expect(report.synced, 0);
      expect(sentRequests, hasLength(1));
      expect(request.options.extra['saberplus.sessionRevision'], 1);
    },
  );

  test(
    'cancelar la solicitud no convierte una edición válida en bloqueada',
    () async {
      mode = _ServerMode.cancel;
      expect(
        (await saveNote('Pendiente')).disposition,
        SafeWriteDisposition.queued,
      );
      final row = (await repository.watchOperations('student-1').first).single;
      expect(row.status, SyncOperationStatus.pending);
      expect(row.attempts, 0);
    },
  );

  test('aplaza progreso sin conexión y conserva el porcentaje mayor', () async {
    final first = await repository.saveStudyProgress(
      userId: 'student-1',
      subtopicId: 'subtopic-1',
      percentage: 80,
    );
    final second = await repository.saveStudyProgress(
      userId: 'student-1',
      subtopicId: 'subtopic-1',
      percentage: 40,
    );

    expect(first.disposition, SafeWriteDisposition.queued);
    expect(second.disposition, SafeWriteDisposition.queued);
    final queued = await repository.watchOperations('student-1').first;
    expect(queued, hasLength(1));
    expect(queued.single.payload['porcentaje'], 80);

    mode = _ServerMode.online;
    remoteProgress = {'subtopic-1': 90};
    final report = await repository.synchronize('student-1');

    expect(report.synced, 1);
    expect(await repository.watchOperations('student-1').first, isEmpty);
    final update = sentRequests.lastWhere(
      (request) => request.method == 'POST',
    );
    expect(update.data, {'subtemaId': 'subtopic-1', 'porcentaje': 90});
  });

  test(
    'agrupa el cuaderno y envía únicamente la edición local más reciente',
    () async {
      await repository.saveNotebookEntry(
        userId: 'student-1',
        questionId: 'question-1',
        note: 'Primer apunte',
        status: NotebookStatus.pending.backendValue,
      );
      await repository.saveNotebookEntry(
        userId: 'student-1',
        questionId: 'question-1',
        note: 'Apunte definitivo',
        status: NotebookStatus.mastered.backendValue,
      );

      final queued = await repository.watchOperations('student-1').first;
      expect(queued, hasLength(1));
      expect(queued.single.payload, {
        'nota': 'Apunte definitivo',
        'estado': 'DOMINADO',
      });

      mode = _ServerMode.online;
      await repository.synchronize('student-1');

      final update = sentRequests.lastWhere(
        (request) => request.method == 'PATCH',
      );
      expect(update.data, {'nota': 'Apunte definitivo', 'estado': 'DOMINADO'});
      expect(await repository.watchOperations('student-1').first, isEmpty);
    },
  );

  test('marca rechazos permanentes y permite reintentarlos', () async {
    mode = _ServerMode.rejectNotebook;
    final result = await repository.saveNotebookEntry(
      userId: 'student-1',
      questionId: 'question-removed',
      note: 'Recordar el concepto',
      status: NotebookStatus.reviewing.backendValue,
    );

    expect(result.disposition, SafeWriteDisposition.blocked);
    var queued = await repository.watchOperations('student-1').first;
    expect(queued.single.status, SyncOperationStatus.blocked);
    expect(queued.single.lastError, 'La pregunta ya no está disponible.');

    mode = _ServerMode.online;
    final report = await repository.retry('student-1', queued.single.id);

    expect(report.synced, 1);
    queued = await repository.watchOperations('student-1').first;
    expect(queued, isEmpty);
  });

  test('mantiene colas independientes para cada usuario', () async {
    await repository.saveStudyProgress(
      userId: 'student-1',
      subtopicId: 'subtopic-1',
      percentage: 100,
    );
    await repository.saveStudyProgress(
      userId: 'student-2',
      subtopicId: 'subtopic-1',
      percentage: 50,
    );

    expect(await repository.watchOperations('student-1').first, hasLength(1));
    expect(await repository.watchOperations('student-2').first, hasLength(1));

    final first = (await repository.watchOperations('student-1').first).single;
    await repository.discard('student-2', first.id);

    expect(await repository.watchOperations('student-1').first, hasLength(1));
    await repository.discard('student-1', first.id);

    expect(await repository.watchOperations('student-1').first, isEmpty);
    expect(await repository.watchOperations('student-2').first, hasLength(1));
  });
}
