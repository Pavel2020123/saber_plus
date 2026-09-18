import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/domain/session.dart';
import '../../../auth/presentation/session_controller.dart';
import '../data/demo_summit_repository.dart';
import '../domain/summit_models.dart';

final summitRepositoryProvider = Provider<SummitRepository?>((ref) {
  final account = ref.watch(
    sessionControllerProvider.select(
      (state) => (state.user?.id, state.user?.isDemo, state.user?.role),
    ),
  );
  // No silent fallback from real accounts to demo scores or question grading.
  if (account.$1 == null ||
      account.$2 != true ||
      account.$3 != AppRole.student) {
    return null;
  }
  return DemoSummitRepository();
});
