import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../domain/national_score_comparison.dart';

typedef NationalStatisticsLinkOpener = Future<bool> Function(Uri uri);

final nationalScoreReferencesProvider = Provider<List<NationalScoreReference>>(
  (ref) => nationalScoreReferences,
);

final nationalStatisticsLinkOpenerProvider =
    Provider<NationalStatisticsLinkOpener>(
      (ref) =>
          (uri) => launchUrl(uri, mode: LaunchMode.externalApplication),
    );
