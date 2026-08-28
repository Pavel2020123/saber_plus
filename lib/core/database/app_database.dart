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

@DriftDatabase(tables: [OfflineDownloads, PendingOperations])
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.executor);

  AppDatabase.defaults() : super(driftDatabase(name: 'saber_plus'));

  @override
  int get schemaVersion => 2;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (migrator) => migrator.createAll(),
    onUpgrade: (migrator, from, to) async {
      if (from < 2) await migrator.createTable(pendingOperations);
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
}

final appDatabaseProvider = Provider<AppDatabase>((ref) {
  final database = AppDatabase.defaults();
  ref.onDispose(database.close);
  return database;
});
