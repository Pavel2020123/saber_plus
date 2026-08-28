import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../../auth/presentation/session_controller.dart';
import '../data/demo_gamification_repository.dart';
import '../data/remote_gamification_repository.dart';
import '../domain/gamification_models.dart';
import '../domain/gamification_repository.dart';

final gamificationRepositoryProvider = Provider<GamificationRepository>((ref) {
  final isDemo = ref.watch(
    sessionControllerProvider.select(
      (session) => session.user?.isDemo ?? false,
    ),
  );
  if (isDemo) return DemoGamificationRepository();
  return RemoteGamificationRepository(ref.watch(dioProvider));
});

final gamificationSummaryProvider =
    FutureProvider.autoDispose<GamificationSummary>(
      (ref) => ref.watch(gamificationRepositoryProvider).loadSummary(),
    );
