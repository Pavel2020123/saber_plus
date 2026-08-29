import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/presentation/session_controller.dart';
import '../data/drift_favorite_repository.dart';
import '../domain/favorite_models.dart';

final favoritesProvider = StreamProvider<List<AcademicFavorite>>((ref) {
  final userId = ref.watch(
    sessionControllerProvider.select((session) => session.user?.id),
  );
  if (userId == null) return Stream.value(const []);
  return ref.watch(favoriteRepositoryProvider).watchAll(userId);
});

final favoriteStatusProvider = StreamProvider.autoDispose
    .family<bool, FavoriteIdentity>((ref, identity) {
      final userId = ref.watch(
        sessionControllerProvider.select((session) => session.user?.id),
      );
      if (userId == null) return Stream.value(false);
      return ref
          .watch(favoriteRepositoryProvider)
          .watchContains(userId, identity);
    });
