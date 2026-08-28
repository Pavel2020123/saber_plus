import 'package:dio/dio.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:saber_plus/core/database/app_database.dart';
import 'package:saber_plus/core/sync/drift_safe_sync_repository.dart';
import 'package:saber_plus/core/sync/safe_sync_models.dart';
import 'package:saber_plus/features/progress/domain/progress_models.dart';

enum _ServerMode { offline, online, rejectNotebook }

void main() {
  late AppDatabase database;
  late Dio dio;
  late DriftSafeSyncRepository repository;
  var mode = _ServerMode.offline;
  var remoteProgress = <String, int>{};
  final sentRequests = <RequestOptions>[];

  setUp(() {
    mode = _ServerMode.offline;
    remoteProgress = {};
    sentRequests.clear();
    database = AppDatabase(NativeDatabase.memory());
    dio = Dio(BaseOptions(baseUrl: 'http://localhost:3000'));
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          sentRequests.add(options);
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
    repository = DriftSafeSyncRepository(dio, database);
  });

  tearDown(() => database.close());

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
