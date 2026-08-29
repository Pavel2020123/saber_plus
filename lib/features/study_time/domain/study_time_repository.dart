import 'study_time_models.dart';

abstract interface class StudyTimeRepository {
  Stream<List<StudyTimeRecord>> watchAll(String userId);

  Future<void> record(StudyTimeRecord entry);
}
