import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

part 'app_database.g.dart';

class OfflineDownloads extends Table {
  TextColumn get userId => text()();

  TextColumn get themeId => text()();

  TextColumn get area => text()();

  TextColumn get themeName => text()();

  TextColumn get fileName => text()();

  TextColumn get localPath => text()();

  IntColumn get byteSize => integer()();

  DateTimeColumn get downloadedAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {userId, themeId};
}

class PendingOperations extends Table {
  TextColumn get id => text()();

  TextColumn get userId => text()();

  TextColumn get kind => text()();

  TextColumn get entityId => text()();

  TextColumn get payloadJson => text()();

  TextColumn get status => text().withDefault(const Constant('pending'))();

  IntColumn get attempts => integer().withDefault(const Constant(0))();

  TextColumn get lastError => text().nullable()();

  DateTimeColumn get createdAt => dateTime()();

  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

class FavoriteEntries extends Table {
  TextColumn get userId => text()();

  TextColumn get kind => text()();

  TextColumn get itemId => text()();

  TextColumn get area => text()();

  TextColumn get parentId => text()();

  TextColumn get title => text()();

  TextColumn get parentTitle => text()();

  DateTimeColumn get savedAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {userId, kind, itemId};
}

class LearningResumeEntries extends Table {
  TextColumn get userId => text()();

  TextColumn get kind => text()();

  TextColumn get area => text()();

  TextColumn get parentId => text()();

  TextColumn get itemId => text()();

  TextColumn get title => text()();

  TextColumn get parentTitle => text()();

  DateTimeColumn get lastOpenedAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {userId};
}

class FlashcardProgressEntries extends Table {
  TextColumn get userId => text()();

  TextColumn get cardId => text()();

  BoolColumn get mastered => boolean().withDefault(const Constant(false))();

  IntColumn get reviewCount => integer().withDefault(const Constant(0))();

  IntColumn get correctCount => integer().withDefault(const Constant(0))();

  DateTimeColumn get lastReviewedAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {userId, cardId};
}

class DifficultQuestionEntries extends Table {
  TextColumn get userId => text()();

  TextColumn get questionId => text()();

  TextColumn get area => text()();

  TextColumn get subtopicId => text().nullable()();

  TextColumn get subtopicName => text()();

  TextColumn get themeName => text()();

  TextColumn get difficulty => text()();

  DateTimeColumn get markedAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {userId, questionId};
}

@DriftDatabase(
  tables: [
    OfflineDownloads,
    PendingOperations,
    FavoriteEntries,
    LearningResumeEntries,
    FlashcardProgressEntries,
    DifficultQuestionEntries,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.executor);

  AppDatabase.defaults() : super(driftDatabase(name: 'saber_plus'));

  @override
  int get schemaVersion => 6;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (migrator) => migrator.createAll(),
    onUpgrade: (migrator, from, to) async {
      if (from < 2) await migrator.createTable(pendingOperations);
      if (from < 3) await migrator.createTable(favoriteEntries);
      if (from < 4) await migrator.createTable(learningResumeEntries);
      if (from < 5) await migrator.createTable(flashcardProgressEntries);
      if (from < 6) await migrator.createTable(difficultQuestionEntries);
    },
  );

  Stream<List<OfflineDownload>> watchOfflineDownloads(String userId) =>
      (select(offlineDownloads)
            ..where((row) => row.userId.equals(userId))
            ..orderBy([(row) => OrderingTerm.desc(row.downloadedAt)]))
          .watch();

  Future<OfflineDownload?> findOfflineDownload(String userId, String themeId) =>
      (select(offlineDownloads)..where(
            (row) => row.userId.equals(userId) & row.themeId.equals(themeId),
          ))
          .getSingleOrNull();

  Future<void> saveOfflineDownload(OfflineDownloadsCompanion download) =>
      into(offlineDownloads).insertOnConflictUpdate(download);

  Future<void> removeOfflineDownload(String userId, String themeId) =>
      (delete(offlineDownloads)..where(
            (row) => row.userId.equals(userId) & row.themeId.equals(themeId),
          ))
          .go();

  Future<void> removeAllOfflineDownloads(String userId) => (delete(
    offlineDownloads,
  )..where((row) => row.userId.equals(userId))).go();

  Stream<List<PendingOperation>> watchPendingOperations(String userId) =>
      (select(pendingOperations)
            ..where((row) => row.userId.equals(userId))
            ..orderBy([(row) => OrderingTerm.desc(row.updatedAt)]))
          .watch();

  Future<List<PendingOperation>> getPendingOperations(String userId) =>
      (select(pendingOperations)
            ..where((row) => row.userId.equals(userId))
            ..orderBy([(row) => OrderingTerm.asc(row.createdAt)]))
          .get();

  Future<PendingOperation?> findPendingOperation(String id) => (select(
    pendingOperations,
  )..where((row) => row.id.equals(id))).getSingleOrNull();

  Future<void> savePendingOperation(PendingOperationsCompanion operation) =>
      into(pendingOperations).insertOnConflictUpdate(operation);

  Future<void> removePendingOperation(String id) =>
      (delete(pendingOperations)..where((row) => row.id.equals(id))).go();

  Stream<List<FavoriteEntry>> watchFavoriteEntries(String userId) =>
      (select(favoriteEntries)
            ..where((row) => row.userId.equals(userId))
            ..orderBy([(row) => OrderingTerm.desc(row.savedAt)]))
          .watch();

  Stream<bool> watchFavoriteEntry(String userId, String kind, String itemId) =>
      (select(favoriteEntries)..where(
            (row) =>
                row.userId.equals(userId) &
                row.kind.equals(kind) &
                row.itemId.equals(itemId),
          ))
          .watchSingleOrNull()
          .map((row) => row != null);

  Future<FavoriteEntry?> findFavoriteEntry(
    String userId,
    String kind,
    String itemId,
  ) =>
      (select(favoriteEntries)..where(
            (row) =>
                row.userId.equals(userId) &
                row.kind.equals(kind) &
                row.itemId.equals(itemId),
          ))
          .getSingleOrNull();

  Future<void> saveFavoriteEntry(FavoriteEntriesCompanion favorite) =>
      into(favoriteEntries).insertOnConflictUpdate(favorite);

  Future<void> removeFavoriteEntry(String userId, String kind, String itemId) =>
      (delete(favoriteEntries)..where(
            (row) =>
                row.userId.equals(userId) &
                row.kind.equals(kind) &
                row.itemId.equals(itemId),
          ))
          .go();

  Stream<LearningResumeEntry?> watchLearningResume(String userId) => (select(
    learningResumeEntries,
  )..where((row) => row.userId.equals(userId))).watchSingleOrNull();

  Future<void> saveLearningResume(LearningResumeEntriesCompanion entry) =>
      into(learningResumeEntries).insertOnConflictUpdate(entry);

  Future<void> clearLearningResume(String userId) => (delete(
    learningResumeEntries,
  )..where((row) => row.userId.equals(userId))).go();

  Stream<List<FlashcardProgressEntry>> watchFlashcardProgress(String userId) =>
      (select(flashcardProgressEntries)
            ..where((row) => row.userId.equals(userId))
            ..orderBy([(row) => OrderingTerm.desc(row.lastReviewedAt)]))
          .watch();

  Future<FlashcardProgressEntry?> findFlashcardProgress(
    String userId,
    String cardId,
  ) =>
      (select(flashcardProgressEntries)..where(
            (row) => row.userId.equals(userId) & row.cardId.equals(cardId),
          ))
          .getSingleOrNull();

  Future<void> saveFlashcardProgress(
    FlashcardProgressEntriesCompanion progress,
  ) => into(flashcardProgressEntries).insertOnConflictUpdate(progress);

  Stream<List<DifficultQuestionEntry>> watchDifficultQuestions(String userId) =>
      (select(difficultQuestionEntries)
            ..where((row) => row.userId.equals(userId))
            ..orderBy([(row) => OrderingTerm.desc(row.markedAt)]))
          .watch();

  Stream<bool> watchDifficultQuestion(String userId, String questionId) =>
      (select(difficultQuestionEntries)..where(
            (row) =>
                row.userId.equals(userId) & row.questionId.equals(questionId),
          ))
          .watchSingleOrNull()
          .map((row) => row != null);

  Future<DifficultQuestionEntry?> findDifficultQuestion(
    String userId,
    String questionId,
  ) =>
      (select(difficultQuestionEntries)..where(
            (row) =>
                row.userId.equals(userId) & row.questionId.equals(questionId),
          ))
          .getSingleOrNull();

  Future<void> saveDifficultQuestion(DifficultQuestionEntriesCompanion entry) =>
      into(difficultQuestionEntries).insertOnConflictUpdate(entry);

  Future<void> removeDifficultQuestion(String userId, String questionId) =>
      (delete(difficultQuestionEntries)..where(
            (row) =>
                row.userId.equals(userId) & row.questionId.equals(questionId),
          ))
          .go();
}

final appDatabaseProvider = Provider<AppDatabase>((ref) {
  final database = AppDatabase.defaults();
  ref.onDispose(database.close);
  return database;
});
