import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../auth/domain/session.dart';
import '../../../auth/presentation/session_controller.dart';
import '../data/demo_knowledge_shield_repository.dart';
import '../domain/knowledge_shield_models.dart';

final knowledgeShieldRepositoryProvider = Provider<KnowledgeShieldRepository?>((
  ref,
) {
  final account = ref.watch(
    sessionControllerProvider.select(
      (state) => (state.user?.id, state.user?.isDemo, state.user?.role),
    ),
  );
  if (account.$1 == null ||
      account.$2 != true ||
      account.$3 != AppRole.student) {
    return null;
  }
  final repository = DemoKnowledgeShieldRepository();
  ref.onDispose(repository.dispose);
  return repository;
});
