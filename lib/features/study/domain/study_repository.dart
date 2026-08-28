import '../../academic/domain/academic_models.dart';
import 'study_models.dart';

abstract interface class StudyRepository {
  Future<StudyCatalog> loadCatalog(AcademicArea area);

  Future<StudyProgress> loadProgress();

  Future<void> updateSubtopicProgress(String subtopicId, int percentage);

  Future<DownloadedThemePdf> downloadThemePdf(StudyTheme theme);
}
