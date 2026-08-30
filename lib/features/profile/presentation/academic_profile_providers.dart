import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../progress/domain/progress_models.dart';
import '../../progress/presentation/progress_providers.dart';

final academicProfileProgressProvider =
    FutureProvider.autoDispose<ProgressDashboard>(
      (ref) => ref.watch(progressRepositoryProvider).loadDashboard(),
    );
