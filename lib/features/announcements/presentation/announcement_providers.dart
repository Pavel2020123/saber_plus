import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../../auth/presentation/session_controller.dart';
import '../data/demo_announcement_repository.dart';
import '../data/remote_announcement_repository.dart';
import '../domain/announcement_models.dart';
import '../domain/announcement_repository.dart';

final announcementRepositoryProvider = Provider<AnnouncementRepository>((ref) {
  final isDemo = ref.watch(
    sessionControllerProvider.select(
      (session) => session.user?.isDemo ?? false,
    ),
  );
  if (isDemo) return DemoAnnouncementRepository();
  return RemoteAnnouncementRepository(ref.watch(dioProvider));
});

class AnnouncementController
    extends AutoDisposeAsyncNotifier<AnnouncementBoard> {
  @override
  Future<AnnouncementBoard> build() =>
      ref.watch(announcementRepositoryProvider).load();

  Future<void> reload() async {
    state = const AsyncLoading<AnnouncementBoard>().copyWithPrevious(state);
    state = await AsyncValue.guard(
      () => ref.read(announcementRepositoryProvider).load(),
    );
  }

  Future<void> markRead(String id) async {
    final current = state.valueOrNull;
    if (current == null ||
        current.items.every((item) => item.id != id || item.isRead)) {
      return;
    }
    final readAt = await ref.read(announcementRepositoryProvider).markRead(id);
    state = AsyncData(current.markRead(id, readAt));
  }

  Future<void> markAllRead() async {
    final current = state.valueOrNull;
    if (current == null || current.pendingCount == 0) return;
    await ref.read(announcementRepositoryProvider).markAllRead();
    state = AsyncData(current.markAllRead(DateTime.now()));
  }
}

final announcementControllerProvider =
    AutoDisposeAsyncNotifierProvider<AnnouncementController, AnnouncementBoard>(
      AnnouncementController.new,
    );
