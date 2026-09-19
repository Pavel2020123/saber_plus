import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../auth/domain/session.dart';
import '../../../auth/presentation/session_controller.dart';
import '../data/demo_star_rescue_repository.dart';
import '../domain/star_rescue_models.dart';

final starRescueRepositoryProvider = Provider<StarRescueRepository?>((ref) {
  final identity = ref.watch(
    sessionControllerProvider.select(
      (state) => (state.user?.id, state.user?.role, state.user?.isDemo),
    ),
  );
  if (identity.$1 == null ||
      identity.$2 != AppRole.student ||
      identity.$3 != true) {
    return null;
  }
  final repository = DemoStarRescueRepository();
  ref.onDispose(repository.dispose);
  return repository;
});
