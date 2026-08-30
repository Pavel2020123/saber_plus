import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../academic/domain/academic_models.dart';
import '../domain/career_orientation.dart';
import 'academic_profile_providers.dart';

typedef OfficialOrientationLinkOpener = Future<bool> Function(Uri uri);

final officialOrientationLinkOpenerProvider =
    Provider<OfficialOrientationLinkOpener>(
      (ref) =>
          (uri) => launchUrl(uri, mode: LaunchMode.externalApplication),
    );

final careerOrientationProvider = FutureProvider.autoDispose<CareerOrientation>(
  (ref) async {
    final projection = await ref.watch(scoreProjectionProvider.future);
    final scores = <AcademicArea, double>{};
    if (projection != null) {
      for (final areaScore in projection.areaScores) {
        scores[areaScore.area] = areaScore.score;
      }
    } else {
      final progress = await ref.watch(academicProfileProgressProvider.future);
      for (final entry in progress.byArea.entries) {
        if (entry.value.total > 0) {
          scores[entry.key] = entry.value.successPercentage;
        }
      }
    }
    return scores.isEmpty
        ? CareerOrientation.empty
        : CareerOrientation.fromAreaScores(scores);
  },
);
