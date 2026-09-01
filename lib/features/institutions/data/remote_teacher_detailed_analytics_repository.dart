import 'dart:io';

import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';

import '../../../core/network/api_error.dart';
import '../domain/teacher_detailed_analytics_models.dart';
import '../domain/teacher_detailed_analytics_repository.dart';

typedef InstitutionReportsDirectoryProvider = Future<Directory> Function();

class RemoteTeacherDetailedAnalyticsRepository
    implements TeacherDetailedAnalyticsRepository {
  RemoteTeacherDetailedAnalyticsRepository(
    this._dio, {
    InstitutionReportsDirectoryProvider? documentsDirectory,
  }) : _documentsDirectory =
           documentsDirectory ?? getApplicationDocumentsDirectory;

  final Dio _dio;
  final InstitutionReportsDirectoryProvider _documentsDirectory;

  @override
  Future<TeacherDetailedDashboard> load() async {
    try {
      final responses = await Future.wait([
        _dio.get<Map<String, dynamic>>('/instituciones/me/analiticas'),
        _dio.get<Map<String, dynamic>>('/instituciones/me/alertas-riesgo'),
      ]);
      return TeacherDetailedDashboard(
        analytics: TeacherDetailedAnalytics.fromJson(_body(responses[0].data)),
        risks: TeacherRiskReport.fromJson(_body(responses[1].data)),
      );
    } on DioException catch (error) {
      throw ApiError.fromDioException(error);
    }
  }

  @override
  Future<DownloadedInstitutionReport> downloadReport(
    InstitutionReportFormat format,
  ) async {
    File? partial;
    try {
      final response = await _dio.get<List<int>>(
        '/instituciones/me/exportaciones/analitica.${format.extension}',
        options: Options(responseType: ResponseType.bytes),
      );
      final bytes = response.data;
      if (bytes == null || bytes.isEmpty) {
        throw const ApiError(
          code: 'empty_institution_report',
          message: 'El reporte llegó vacío. Intenta nuevamente.',
        );
      }
      final root = await _documentsDirectory();
      final directory = Directory(
        '${root.path}${Platform.pathSeparator}saberplus_reports',
      );
      await directory.create(recursive: true);
      final day = DateTime.now().toIso8601String().substring(0, 10);
      final fileName = 'saberplus-analitica-$day.${format.extension}';
      final file = File('${directory.path}${Platform.pathSeparator}$fileName');
      partial = File('${file.path}.part');
      await partial.writeAsBytes(bytes, flush: true);
      if (await file.exists()) await file.delete();
      await partial.rename(file.path);
      partial = null;
      return DownloadedInstitutionReport(
        path: file.path,
        fileName: fileName,
        format: format,
      );
    } on DioException catch (error) {
      throw ApiError.fromDioException(error);
    } on ApiError {
      rethrow;
    } on FileSystemException {
      throw const ApiError(
        code: 'institution_report_storage_error',
        message: 'No pudimos guardar el reporte en este dispositivo.',
      );
    } finally {
      if (partial != null && await partial.exists()) {
        await partial.delete();
      }
    }
  }
}

Map<String, dynamic> _body(Map<String, dynamic>? value) {
  if (value == null) return const {};
  final data = value['data'];
  return data is Map ? Map<String, dynamic>.from(data) : value;
}
