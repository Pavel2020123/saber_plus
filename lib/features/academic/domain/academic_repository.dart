import 'academic_models.dart';

abstract interface class AcademicRepository {
  Future<AcademicHomeData> loadHome();

  Future<DiagnosticSummary> startDiagnostic();
}
