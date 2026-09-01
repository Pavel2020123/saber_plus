import 'referral_models.dart';

abstract interface class ReferralRepository {
  Future<ReferralSummary> loadSummary();
}
