import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../academic/domain/academic_models.dart';
import '../../auth/presentation/session_controller.dart';
import '../../study/data/remote_study_repository.dart';
import '../../study/domain/study_models.dart';
import '../../study/domain/study_repository.dart';
import '../domain/academic_search_models.dart';
import '../domain/academic_search_repository.dart';

class CatalogAcademicSearchRepository implements AcademicSearchRepository {
  const CatalogAcademicSearchRepository(
    this._studyRepository, {
    required this.demo,
  });

  final StudyRepository _studyRepository;
  final bool demo;

  @override
  Future<AcademicSearchIndex> loadIndex() async {
    final catalogs = demo
        ? AcademicArea.values.map(StudyCatalog.demo).toList(growable: false)
        : await Future.wait(
            AcademicArea.values.map(_studyRepository.loadCatalog),
          );
    return AcademicSearchIndex.fromCatalogs(catalogs);
  }
}

final academicSearchRepositoryProvider = Provider<AcademicSearchRepository>((
  ref,
) {
  final demo = ref.watch(sessionControllerProvider).user?.isDemo ?? false;
  return CatalogAcademicSearchRepository(
    ref.watch(studyRepositoryProvider),
    demo: demo,
  );
});
