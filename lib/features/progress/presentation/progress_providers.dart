import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../../auth/presentation/session_controller.dart';
import '../data/demo_progress_repository.dart';
import '../data/remote_progress_repository.dart';
import '../domain/progress_repository.dart';

final progressRepositoryProvider = Provider<ProgressRepository>((ref) {
  final isDemo = ref.watch(sessionControllerProvider).user?.isDemo ?? false;
  if (isDemo) return DemoProgressRepository();
  return RemoteProgressRepository(ref.watch(dioProvider));
});
