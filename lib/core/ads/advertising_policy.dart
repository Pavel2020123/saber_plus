enum AdvertisingAudience { student, teacher }

enum AdvertisingPlacement {
  studentNavigationBanner,
  teacherDashboardBanner,
  teacherGroupsBanner,
  teacherAnalyticsBanner,
  naturalBreakInterstitial,
  voluntaryReward,
}

class AdvertisingPolicy {
  const AdvertisingPolicy({required this.audience, required this.adsEnabled});

  final AdvertisingAudience audience;
  final bool adsEnabled;

  int get maximumInterstitialsPerWindow =>
      audience == AdvertisingAudience.teacher ? 3 : 2;

  Duration get interstitialWindow => const Duration(minutes: 30);

  int get minimumCompletedActions => 2;

  bool allowsBanner({
    required AdvertisingPlacement placement,
    bool concentrationScreen = false,
  }) {
    if (!adsEnabled || concentrationScreen) return false;
    return switch (placement) {
      AdvertisingPlacement.studentNavigationBanner =>
        audience == AdvertisingAudience.student,
      AdvertisingPlacement.teacherDashboardBanner ||
      AdvertisingPlacement.teacherGroupsBanner ||
      AdvertisingPlacement.teacherAnalyticsBanner =>
        audience == AdvertisingAudience.teacher,
      _ => false,
    };
  }

  bool allowsInterstitial(AdvertisingPlacement placement) =>
      adsEnabled && placement == AdvertisingPlacement.naturalBreakInterstitial;

  bool allowsVoluntaryReward(AdvertisingPlacement placement) =>
      adsEnabled && placement == AdvertisingPlacement.voluntaryReward;
}

class LocalInterstitialGate {
  LocalInterstitialGate(this.policy);

  final AdvertisingPolicy policy;
  final List<DateTime> _impressions = [];
  var _completedActions = 0;

  void registerCompletedAction() => _completedActions += 1;

  bool canRequest(DateTime now) {
    if (!policy.allowsInterstitial(
      AdvertisingPlacement.naturalBreakInterstitial,
    )) {
      return false;
    }
    _removeExpired(now);
    return _completedActions >= policy.minimumCompletedActions &&
        _impressions.length < policy.maximumInterstitialsPerWindow;
  }

  void registerImpression(DateTime now) {
    _removeExpired(now);
    _impressions.add(now);
    _completedActions = 0;
  }

  int impressionsInWindow(DateTime now) {
    _removeExpired(now);
    return _impressions.length;
  }

  void _removeExpired(DateTime now) {
    final limit = now.subtract(policy.interstitialWindow);
    _impressions.removeWhere((value) => value.isBefore(limit));
  }
}

abstract interface class MobileAdvertisingGateway {
  bool get isConfigured;

  Future<bool> showInterstitial(AdvertisingPlacement placement);
}

class DisabledMobileAdvertisingGateway implements MobileAdvertisingGateway {
  const DisabledMobileAdvertisingGateway();

  @override
  bool get isConfigured => false;

  @override
  Future<bool> showInterstitial(AdvertisingPlacement placement) async => false;
}
