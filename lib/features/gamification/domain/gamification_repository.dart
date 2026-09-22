import 'gamification_models.dart';
import 'course_certificate.dart';

abstract interface class GamificationRepository {
  Future<GamificationSummary> loadSummary();

  Future<List<CourseCertificate>> loadCertificates();

  Future<DownloadedCertificate?> findCertificate({
    required String userId,
    required CourseCertificate certificate,
  });

  Future<DownloadedCertificate> downloadCertificate({
    required String userId,
    required CourseCertificate certificate,
  });
}
