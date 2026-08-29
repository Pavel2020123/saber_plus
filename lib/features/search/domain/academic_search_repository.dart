import 'academic_search_models.dart';

abstract interface class AcademicSearchRepository {
  Future<AcademicSearchIndex> loadIndex();
}
