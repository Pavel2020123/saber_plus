import '../../academic/domain/academic_models.dart';
import 'offline_content_models.dart';
import 'study_models.dart';

abstract interface class OfflineContentRepository {
  Stream<List<OfflineThemeDownload>> watchDownloads(String userId);

  Future<OfflineThemeDownload?> findDownload(String userId, String themeId);

  Future<OfflineThemeDownload> downloadTheme({
    required String userId,
    required AcademicArea area,
    required StudyTheme theme,
  });

  Future<void> deleteDownload(OfflineThemeDownload download);

  Future<void> deleteAll(String userId);
}
