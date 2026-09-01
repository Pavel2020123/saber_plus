import 'teacher_detailed_analytics_models.dart';

enum InstitutionReportFormat {
  csv('csv'),
  pdf('pdf');

  const InstitutionReportFormat(this.extension);

  final String extension;
}

class DownloadedInstitutionReport {
  const DownloadedInstitutionReport({
    required this.path,
    required this.fileName,
    required this.format,
  });

  final String path;
  final String fileName;
  final InstitutionReportFormat format;
}

abstract interface class TeacherDetailedAnalyticsRepository {
  Future<TeacherDetailedDashboard> load();

  Future<DownloadedInstitutionReport> downloadReport(
    InstitutionReportFormat format,
  );
}
