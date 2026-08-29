import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/app_database.dart';
import '../../academic/domain/academic_models.dart';
import '../domain/favorite_models.dart';
import '../domain/favorite_repository.dart';

class DriftFavoriteRepository implements FavoriteRepository {
  DriftFavoriteRepository(this._database);

  final AppDatabase _database;

  @override
  Stream<List<AcademicFavorite>> watchAll(String userId) => _database
      .watchFavoriteEntries(userId)
      .map((rows) => rows.map(_fromRow).toList(growable: false));

  @override
  Stream<bool> watchContains(String userId, FavoriteIdentity identity) =>
      _database.watchFavoriteEntry(
        userId,
        identity.kind.storageValue,
        identity.itemId,
      );

  @override
  Future<bool> toggle(AcademicFavorite favorite) async {
    final existing = await _database.findFavoriteEntry(
      favorite.userId,
      favorite.kind.storageValue,
      favorite.itemId,
    );
    if (existing != null) {
      await remove(favorite.userId, favorite.identity);
      return false;
    }
    await _database.saveFavoriteEntry(
      FavoriteEntriesCompanion.insert(
        userId: favorite.userId,
        kind: favorite.kind.storageValue,
        itemId: favorite.itemId,
        area: favorite.area.backendValue,
        parentId: favorite.parentId,
        title: favorite.title,
        parentTitle: favorite.parentTitle,
        savedAt: favorite.savedAt,
      ),
    );
    return true;
  }

  @override
  Future<void> remove(String userId, FavoriteIdentity identity) => _database
      .removeFavoriteEntry(userId, identity.kind.storageValue, identity.itemId);

  AcademicFavorite _fromRow(FavoriteEntry row) => AcademicFavorite(
    userId: row.userId,
    kind: FavoriteKind.fromStorage(row.kind),
    itemId: row.itemId,
    area: AcademicArea.fromBackend(row.area),
    parentId: row.parentId,
    title: row.title,
    parentTitle: row.parentTitle,
    savedAt: row.savedAt,
  );
}

final favoriteRepositoryProvider = Provider<FavoriteRepository>(
  (ref) => DriftFavoriteRepository(ref.watch(appDatabaseProvider)),
);
