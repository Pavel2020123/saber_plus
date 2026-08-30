import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../../auth/presentation/session_controller.dart';
import '../data/demo_practice_repository.dart';
import '../data/remote_practice_repository.dart';
import '../domain/practice_repository.dart';

final practiceNowProvider = Provider<DateTime Function()>(
  (ref) => DateTime.now,
);

final practiceRepositoryProvider = Provider<PracticeRepository>((ref) {
  final isDemo = ref.watch(sessionControllerProvider).user?.isDemo ?? false;
  if (isDemo) return DemoPracticeRepository();
  return RemotePracticeRepository(ref.watch(dioProvider));
});
