import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/presentation/session_controller.dart';
import '../data/local_offline_content_repository.dart';
import '../domain/offline_content_models.dart';

final offlineDownloadsProvider = StreamProvider<List<OfflineThemeDownload>>((
  ref,
) {
  final user = ref.watch(sessionControllerProvider).user;
  if (user == null || user.isDemo) return Stream.value(const []);
  return ref.watch(offlineContentRepositoryProvider).watchDownloads(user.id);
});

final offlineStorageSummaryProvider = Provider<OfflineStorageSummary>((ref) {
  final downloads = ref.watch(offlineDownloadsProvider).valueOrNull ?? const [];
  return OfflineStorageSummary.fromDownloads(downloads);
});
