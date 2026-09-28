import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/database/app_database.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/access_token_store.dart';
import '../../../core/sync/safe_sync_models.dart';
import '../../auth/presentation/session_controller.dart';
import 'flashcard_providers.dart';
import '../data/deferred_review_repository.dart';

// Retained by the existing foreground sync lifecycle; never sends demo events.
final deferredReviewRepositoryProvider =
    FutureProvider.autoDispose<DeferredReviewRepository>((ref) async {
      var disposed = false;
      ref.onDispose(() => disposed = true);
      ref.watch(sessionControllerProvider.select((s) => s.user));
      final db = ref.watch(appDatabaseProvider);
      final dio = ref.watch(dioProvider);
      final cards = await ref.watch(flashcardCatalogProvider.future);
      if (disposed) throw StateError('Provider disposed');
      final repo = DeferredReviewRepository(
        db,
        dio,
        allowedCardIds: cards.map((c) => c.id).toSet(),
        currentSession: () {
          if (disposed) return null;
          final user = ref.read(sessionControllerProvider).user;
          final tokens = ref.read(accessTokenStoreProvider);
          if (user == null || user.isDemo || tokens.accessToken == null) {
            return null;
          }
          return SyncSessionSnapshot(
            userId: user.id,
            revision: tokens.revision,
          );
        },
      );
      ref.onDispose(repo.dispose);
      return repo;
    });

final deferredReviewRowsProvider =
    StreamProvider.autoDispose<List<DeferredReviewEntry>>((ref) {
      final user = ref.watch(sessionControllerProvider).user;
      if (user == null || user.isDemo) return Stream.value(const []);
      final db = ref.watch(appDatabaseProvider);
      return (db.select(
        db.deferredReviewEntries,
      )..where((r) => r.userId.equals(user.id))).watch();
    });
