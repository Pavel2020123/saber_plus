import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/api_client.dart';

import '../../../auth/domain/session.dart';
import '../../../auth/presentation/session_controller.dart';
import '../data/demo_summit_repository.dart';
import '../data/remote_summit_repository.dart';
import '../data/summit_resume_store.dart';
import '../domain/summit_models.dart';

final summitRepositoryProvider = Provider<SummitRepository?>((ref) {
  final account = ref.watch(
    sessionControllerProvider.select(
      (state) => (state.user?.id, state.user?.isDemo, state.user?.role),
    ),
  );
  // No silent fallback from real accounts to demo scores or question grading.
  if (account.$1 == null || account.$3 != AppRole.student) {
    return null;
  }
  if (account.$2 == true) return DemoSummitRepository();
  final dio = ref.watch(dioProvider);
  final repository = RemoteSummitRepository(
    dio,
    ref.watch(summitResumeStoreProvider),
    scope: '${dio.options.baseUrl}\u0000${account.$1}',
  );
  ref.onDispose(repository.dispose);
  return repository;
});
