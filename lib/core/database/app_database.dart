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

@DriftDatabase(tables: [OfflineDownloads])
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.executor);

  AppDatabase.defaults() : super(driftDatabase(name: 'saber_plus'));

  @override
  int get schemaVersion => 1;

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
}

final appDatabaseProvider = Provider<AppDatabase>((ref) {
  final database = AppDatabase.defaults();
  ref.onDispose(database.close);
  return database;
});
