import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_client.dart';
import '../../../auth/presentation/session_controller.dart';
import '../../trivia_rush/data/demo_trivia_rush_repository.dart';
import '../../trivia_rush/domain/trivia_rush_repository.dart';
import '../data/remote_tug_local_repository.dart';

final tugLocalRepositoryProvider = Provider<TriviaRushRepository>((ref) {
  final demo = ref.watch(sessionControllerProvider).user?.isDemo ?? false;
  if (demo) return DemoTriviaRushRepository();
  return RemoteTugLocalRepository(ref.watch(dioProvider));
});
