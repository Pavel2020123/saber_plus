import 'favorite_models.dart';

abstract interface class FavoriteRepository {
  Stream<List<AcademicFavorite>> watchAll(String userId);

  Stream<bool> watchContains(String userId, FavoriteIdentity identity);

  Future<bool> toggle(AcademicFavorite favorite);

  Future<void> remove(String userId, FavoriteIdentity identity);
}
