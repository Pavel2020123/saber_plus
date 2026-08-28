import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:saber_plus/core/database/app_database.dart';
import 'package:sqlite3/sqlite3.dart' as sqlite;

void main() {
  test(
    'migra desde descargas v1 sin perder los archivos registrados',
    () async {
      final directory = await Directory.systemTemp.createTemp(
        'saberplus-migration-test-',
      );
      final file = File(
        '${directory.path}${Platform.pathSeparator}legacy.sqlite',
      );
      final legacy = sqlite.sqlite3.open(file.path);
      legacy.execute('''
      CREATE TABLE offline_downloads (
        user_id TEXT NOT NULL,
        theme_id TEXT NOT NULL,
        area TEXT NOT NULL,
        theme_name TEXT NOT NULL,
        file_name TEXT NOT NULL,
        local_path TEXT NOT NULL,
        byte_size INTEGER NOT NULL,
        downloaded_at INTEGER NOT NULL,
        PRIMARY KEY (user_id, theme_id)
      );
    ''');
      legacy.execute(
        '''
      INSERT INTO offline_downloads VALUES (?, ?, ?, ?, ?, ?, ?, ?)
      ''',
        [
          'student-1',
          'theme-1',
          'matematicas',
          'Álgebra',
          'algebra.pdf',
          'private/algebra.pdf',
          2048,
          DateTime.utc(2026, 8, 28).millisecondsSinceEpoch ~/ 1000,
        ],
      );
      legacy.execute('PRAGMA user_version = 1;');
      legacy.dispose();

      final database = AppDatabase(NativeDatabase(file));
      addTearDown(() async {
        await database.close();
        await directory.delete(recursive: true);
      });

      final downloads = await database.watchOfflineDownloads('student-1').first;
      final outbox = await database.getPendingOperations('student-1');

      expect(downloads, hasLength(1));
      expect(downloads.single.themeName, 'Álgebra');
      expect(outbox, isEmpty);
    },
  );
}
