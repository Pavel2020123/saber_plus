import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/presentation/session_controller.dart';
import '../data/demo_trivia_rush_repository.dart';
import '../data/remote_trivia_rush_repository.dart';
import '../domain/trivia_rush_repository.dart';
import '../../../../core/network/api_client.dart';

final triviaRushRepositoryProvider = Provider<TriviaRushRepository>((ref) {
  final isDemo = ref.watch(sessionControllerProvider).user?.isDemo ?? false;
  if (isDemo) return DemoTriviaRushRepository();
  return RemoteTriviaRushRepository(ref.watch(dioProvider));
});
