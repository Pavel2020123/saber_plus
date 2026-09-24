import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/api_client.dart';

import '../../../auth/domain/session.dart';
import '../../../auth/presentation/session_controller.dart';
import '../data/demo_star_rescue_repository.dart';
import '../data/remote_star_rescue_repository.dart';
import '../data/star_rescue_resume_store.dart';
import '../domain/star_rescue_models.dart';

final starRescueRepositoryProvider = Provider<StarRescueRepository?>((ref) {
  final account = ref.watch(
    sessionControllerProvider.select(
      (state) => (state.user?.id, state.user?.isDemo, state.user?.role),
    ),
  );
  // No silent fallback from real accounts to demo scores or question grading.
  if (account.$1 == null || account.$3 != AppRole.student) {
    return null;
  }
  if (account.$2 == true) {
    final repository = DemoStarRescueRepository();
    ref.onDispose(repository.dispose);
    return repository;
  }
  final dio = ref.watch(dioProvider);
  final repository = RemoteStarRescueRepository(
    dio,
    ref.watch(starRescueResumeStoreProvider),
    scope: '${dio.options.baseUrl}\u0000${account.$1}',
  );
  ref.onDispose(repository.dispose);
  return repository;
});
