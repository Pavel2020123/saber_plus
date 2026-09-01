import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../../auth/presentation/session_controller.dart';
import '../data/demo_referral_repository.dart';
import '../data/remote_referral_repository.dart';
import '../domain/referral_models.dart';
import '../domain/referral_repository.dart';

final referralRepositoryProvider = Provider<ReferralRepository>((ref) {
  final isDemo = ref.watch(
    sessionControllerProvider.select(
      (session) => session.user?.isDemo ?? false,
    ),
  );
  if (isDemo) return DemoReferralRepository();
  return RemoteReferralRepository(ref.watch(dioProvider));
});

final referralSummaryProvider = FutureProvider.autoDispose<ReferralSummary>(
  (ref) => ref.watch(referralRepositoryProvider).loadSummary(),
);
