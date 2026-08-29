import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/app_database.dart';
import '../../academic/domain/academic_models.dart';
import '../domain/learning_resume_models.dart';
import '../domain/learning_resume_repository.dart';

class DriftLearningResumeRepository implements LearningResumeRepository {
  const DriftLearningResumeRepository(this._database);

  final AppDatabase _database;

  @override
  Stream<LearningResume?> watch(String userId) => _database
      .watchLearningResume(userId)
      .map(
        (row) => row == null
            ? null
            : LearningResume(
                userId: row.userId,
                kind: LearningResumeKind.fromStorage(row.kind),
                area: AcademicArea.fromBackend(row.area),
                parentId: row.parentId,
                itemId: row.itemId,
                title: row.title,
                parentTitle: row.parentTitle,
                lastOpenedAt: row.lastOpenedAt,
              ),
      );

  @override
  Future<void> save(LearningResume entry) => _database.saveLearningResume(
    LearningResumeEntriesCompanion.insert(
      userId: entry.userId,
      kind: entry.kind.storageValue,
      area: entry.area.backendValue,
      parentId: entry.parentId,
      itemId: entry.itemId,
      title: entry.title,
      parentTitle: entry.parentTitle,
      lastOpenedAt: entry.lastOpenedAt,
    ),
  );

  @override
  Future<void> clear(String userId) => _database.clearLearningResume(userId);
}

final learningResumeRepositoryProvider = Provider<LearningResumeRepository>(
  (ref) => DriftLearningResumeRepository(ref.watch(appDatabaseProvider)),
);
