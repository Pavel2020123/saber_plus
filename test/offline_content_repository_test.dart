import 'dart:io';

import 'package:dio/dio.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:saber_plus/core/database/app_database.dart';
import 'package:saber_plus/features/academic/domain/academic_models.dart';
import 'package:saber_plus/features/study/data/local_offline_content_repository.dart';
import 'package:saber_plus/features/study/domain/offline_content_models.dart';
import 'package:saber_plus/features/study/domain/study_models.dart';

void main() {
  late Directory temporaryDirectory;
  late AppDatabase database;
  late Dio dio;
  late LocalOfflineContentRepository repository;
  late RequestOptions capturedRequest;

  const theme = StudyTheme(
    id: 'theme-1',
    name: 'Álgebra básica',
    subtopics: [],
  );

  setUp(() async {
    temporaryDirectory = await Directory.systemTemp.createTemp(
      'saberplus-offline-test-',
    );
    database = AppDatabase(NativeDatabase.memory());
    dio = Dio(BaseOptions(baseUrl: 'http://localhost:3000'));
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          capturedRequest = options;
          handler.resolve(
            Response<List<int>>(
              requestOptions: options,
              statusCode: 200,
              data: const [37, 80, 68, 70, 45, 49],
            ),
          );
        },
      ),
    );
    repository = LocalOfflineContentRepository(
      dio,
      database,
      rootDirectory: () async => temporaryDirectory,
    );
  });

  tearDown(() async {
    await database.close();
    if (await temporaryDirectory.exists()) {
      await temporaryDirectory.delete(recursive: true);
    }
  });

  test('descarga el PDF y registra sus metadatos en SQLite', () async {
    final download = await repository.downloadTheme(
      userId: 'student-1',
      area: AcademicArea.mathematics,
      theme: theme,
    );

    expect(capturedRequest.path, '/simulacros/temas/theme-1/pdf');
    expect(download.areaSlug, 'matematicas');
    expect(download.byteSize, 6);
    expect(download.fileName, 'tema-algebra-basica-theme-1.pdf');
    expect(await File(download.localPath).readAsBytes(), [
      37,
      80,
      68,
      70,
      45,
      49,
    ]);

    final stored = await repository.watchDownloads('student-1').first;
    expect(stored, hasLength(1));
    expect(stored.single.themeName, 'Álgebra básica');
  });

  test(
    'separa las descargas por estudiante y limpia solo la cuenta activa',
    () async {
      final first = await repository.downloadTheme(
        userId: 'student-1',
        area: AcademicArea.mathematics,
        theme: theme,
      );
      final second = await repository.downloadTheme(
        userId: 'student-2',
        area: AcademicArea.mathematics,
        theme: theme,
      );

      expect(first.localPath, isNot(second.localPath));
      expect(await repository.watchDownloads('student-1').first, hasLength(1));
      expect(await repository.watchDownloads('student-2').first, hasLength(1));

      await repository.deleteAll('student-1');

      expect(await File(first.localPath).exists(), isFalse);
      expect(await File(second.localPath).exists(), isTrue);
      expect(await repository.watchDownloads('student-1').first, isEmpty);
      expect(await repository.watchDownloads('student-2').first, hasLength(1));
    },
  );

  test('elimina registros huérfanos cuando falta el archivo local', () async {
    final download = await repository.downloadTheme(
      userId: 'student-1',
      area: AcademicArea.mathematics,
      theme: theme,
    );
    await File(download.localPath).delete();

    expect(await repository.findDownload('student-1', theme.id), isNull);
    expect(await repository.watchDownloads('student-1').first, isEmpty);
  });

  test('formatea el espacio usado con unidades legibles', () {
    expect(formatStorageSize(900), '900 B');
    expect(formatStorageSize(1536), '1.5 KB');
    expect(formatStorageSize(2 * 1024 * 1024), '2.0 MB');
  });
}
