import 'dart:io';

import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:saber_plus/core/database/app_database.dart';
import 'package:sqlite3/sqlite3.dart' as sqlite;

void main() {
  for (var version = 2; version <= 7; version++) {
    test(
      'migra una cola existente v$version a v8 sin perder sus revisiones',
      () async {
        final directory = await Directory.systemTemp.createTemp(
          'saberplus-outbox-migration-test-',
        );
        final file = File(
          '${directory.path}${Platform.pathSeparator}legacy.sqlite',
        );
        AppDatabase? database;
        addTearDown(() async {
          await database?.close();
          await directory.delete(recursive: true);
        });

        // Construye un archivo aislado con el esquema anterior real: las tablas
        // previas no cambiaron en v8; únicamente se añadió pending_operations.revision.
        database = AppDatabase(NativeDatabase(file));
        await database.savePendingOperation(
          PendingOperationsCompanion.insert(
            id: 'student-1::notebook_entry::question-1',
            userId: 'student-1',
            kind: 'notebook_entry',
            entityId: 'question-1',
            payloadJson:
                '{"nota":"Revisar regla de tres","estado":"PENDIENTE"}',
            status: const Value('blocked'),
            attempts: const Value(2),
            lastError: const Value('Error previo'),
            createdAt: DateTime.utc(2026, 9, 1),
            updatedAt: DateTime.utc(2026, 9, 2),
          ),
        );
        await database.close();
        database = null;
        final legacy = sqlite.sqlite3.open(file.path);
        try {
          legacy.execute('ALTER TABLE pending_operations DROP COLUMN revision');
          const introducedIn = {
            'favorite_entries': 3,
            'learning_resume_entries': 4,
            'flashcard_progress_entries': 5,
            'difficult_question_entries': 6,
            'study_time_entries': 7,
          };
          for (final entry in introducedIn.entries) {
            if (entry.value > version) {
              legacy.execute('DROP TABLE ${entry.key}');
            }
          }
          legacy.execute('PRAGMA user_version = $version');
        } finally {
          legacy.dispose();
        }

        database = AppDatabase(NativeDatabase(file));
        final migrated = (await database.getPendingOperations(
          'student-1',
        )).single;
        expect(migrated.revision, '');
        expect(migrated.payloadJson, contains('Revisar regla de tres'));
        expect(migrated.status, 'blocked');
        expect(migrated.attempts, 2);
        expect(migrated.lastError, 'Error previo');
        expect(migrated.createdAt.toUtc(), DateTime.utc(2026, 9, 1));
        expect(migrated.updatedAt.toUtc(), DateTime.utc(2026, 9, 2));
        expect(await database.watchFavoriteEntries('student-1').first, isEmpty);
        expect(await database.watchLearningResume('student-1').first, isNull);
        expect(
          await database.watchFlashcardProgress('student-1').first,
          isEmpty,
        );
        expect(
          await database.watchDifficultQuestions('student-1').first,
          isEmpty,
        );
        expect(
          await database.watchStudyTimeEntries('student-1').first,
          isEmpty,
        );

        // La revisión por defecto puede confirmarse y luego editarse con CAS.
        expect(
          await database.updatePendingOperationIfUnchanged(
            migrated,
            const PendingOperationsCompanion(
              revision: Value('new-revision'),
              status: Value('pending'),
            ),
          ),
          1,
        );
        expect(await database.removePendingOperationIfUnchanged(migrated), 0);
        expect(
          (await database.getPendingOperations('student-1')).single.revision,
          'new-revision',
        );
        final pragma = await database
            .customSelect('PRAGMA user_version')
            .getSingle();
        expect(pragma.read<int>('user_version'), 8);
      },
    );
  }

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
      final favorites = await database.watchFavoriteEntries('student-1').first;
      final resume = await database.watchLearningResume('student-1').first;
      final flashcards = await database
          .watchFlashcardProgress('student-1')
          .first;
      final difficultQuestions = await database
          .watchDifficultQuestions('student-1')
          .first;
      final studyTime = await database.watchStudyTimeEntries('student-1').first;

      expect(downloads, hasLength(1));
      expect(downloads.single.themeName, 'Álgebra');
      expect(outbox, isEmpty);
      expect(favorites, isEmpty);
      expect(resume, isNull);
      expect(flashcards, isEmpty);
      expect(difficultQuestions, isEmpty);
      expect(studyTime, isEmpty);
    },
  );
}
