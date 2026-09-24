import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/api_client.dart';

import '../../../auth/domain/session.dart';
import '../../../auth/presentation/session_controller.dart';
import '../data/demo_knowledge_shield_repository.dart';
import '../data/remote_knowledge_shield_repository.dart';
import '../data/knowledge_shield_resume_store.dart';
import '../domain/knowledge_shield_models.dart';

final knowledgeShieldRepositoryProvider = Provider<KnowledgeShieldRepository?>((
  ref,
) {
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
    final repository = DemoKnowledgeShieldRepository();
    ref.onDispose(repository.dispose);
    return repository;
  }
  final dio = ref.watch(dioProvider);
  final repository = RemoteKnowledgeShieldRepository(
    dio,
    ref.watch(knowledgeShieldResumeStoreProvider),
    scope: '${dio.options.baseUrl}\u0000${account.$1}',
  );
  ref.onDispose(repository.dispose);
  return repository;
});
