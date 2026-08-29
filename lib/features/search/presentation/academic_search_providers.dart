import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/catalog_academic_search_repository.dart';
import '../domain/academic_search_models.dart';

final academicSearchIndexProvider =
    FutureProvider.autoDispose<AcademicSearchIndex>(
      (ref) => ref.watch(academicSearchRepositoryProvider).loadIndex(),
    );
