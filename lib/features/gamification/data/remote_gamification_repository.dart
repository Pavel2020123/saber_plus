import 'dart:io';

import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';

import '../../../core/network/api_error.dart';
import '../domain/gamification_models.dart';
import '../domain/course_certificate.dart';
import '../domain/gamification_repository.dart';

typedef CertificateDirectoryProvider = Future<Directory> Function();

class RemoteGamificationRepository implements GamificationRepository {
  RemoteGamificationRepository(
    this._dio, {
    CertificateDirectoryProvider? certificateDirectory,
  }) : _certificateDirectory =
           certificateDirectory ?? getApplicationDocumentsDirectory;

  static const _maximumCertificateBytes = 20 * 1024 * 1024;

  final Dio _dio;
  final CertificateDirectoryProvider _certificateDirectory;

  @override
  Future<List<CourseCertificate>> loadCertificates() async {
    try {
      final response = await _dio.get<Object?>('/gamificacion/certificados');
      final body = response.data;
      return CourseCertificate.parseList(body is Map ? body['data'] : body);
    } on DioException catch (error) {
      throw ApiError.fromDioException(error);
    }
  }

  @override
  Future<GamificationSummary> loadSummary() async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '/gamificacion/resumen',
      );
      return GamificationSummary.fromJson(_body(response.data));
    } on DioException catch (error) {
      throw ApiError.fromDioException(error);
    }
  }

  @override
  Future<DownloadedCertificate?> findCertificate({
    required String userId,
    required CourseCertificate certificate,
  }) async {
    if (!certificate.available) return null;
    final directory = await _certificateDirectoryFor(userId, certificate.id);
    if (!await directory.exists()) return null;
    final files = await directory
        .list()
        .where(
          (entry) => entry is File && entry.path.toLowerCase().endsWith('.pdf'),
        )
        .cast<File>()
        .toList();
    if (files.isEmpty) return null;
    files.sort(
      (a, b) => b.statSync().modified.compareTo(a.statSync().modified),
    );
    final file = files.first;
    final bytes = await file
        .openRead(0, 4)
        .fold<List<int>>(<int>[], (buffer, chunk) => buffer..addAll(chunk));
    if (!_isPdf(bytes)) {
      await file.delete();
      return null;
    }
    final stat = await file.stat();
    return DownloadedCertificate(
      certificateId: certificate.id,
      fileName: file.uri.pathSegments.last,
      localPath: file.path,
      byteSize: stat.size,
      downloadedAt: stat.modified.toUtc(),
    );
  }

  @override
  Future<DownloadedCertificate> downloadCertificate({
    required String userId,
    required CourseCertificate certificate,
  }) async {
    if (!certificate.available) {
      throw const ApiError(
        code: 'certificate_locked',
        message:
            'Completa las lecciones publicadas antes de descargar el certificado.',
      );
    }
    try {
      final response = await _dio.get<List<int>>(
        '/gamificacion/certificados/${certificate.id}/pdf',
        options: Options(
          responseType: ResponseType.bytes,
          receiveTimeout: const Duration(seconds: 60),
        ),
      );
      final bytes = response.data ?? const <int>[];
      if (!_isPdf(bytes) || bytes.length > _maximumCertificateBytes) {
        throw const ApiError(
          code: 'invalid_certificate',
          message: 'El servidor no entregó un certificado PDF válido.',
        );
      }

      final fileName = _responseFileName(response.headers, certificate);
      final directory = await _certificateDirectoryFor(userId, certificate.id);
      final file = File('${directory.path}${Platform.pathSeparator}$fileName');
      await file.parent.create(recursive: true);
      final partial = File('${file.path}.part');
      await partial.writeAsBytes(bytes, flush: true);
      if (await file.exists()) await file.delete();
      await partial.rename(file.path);
      final stat = await file.stat();
      return DownloadedCertificate(
        certificateId: certificate.id,
        fileName: fileName,
        localPath: file.path,
        byteSize: stat.size,
        downloadedAt: stat.modified.toUtc(),
      );
    } on DioException catch (error) {
      throw ApiError.fromDioException(error);
    }
  }

  Future<Directory> _certificateDirectoryFor(
    String userId,
    String certificateId,
  ) async {
    final root = await _certificateDirectory();
    final separator = Platform.pathSeparator;
    return Directory(
      '${root.path}${separator}saberplus${separator}course-certificates$separator${_safeSegment(userId)}$separator${_safeSegment(certificateId)}',
    );
  }

  String _responseFileName(Headers headers, CourseCertificate certificate) {
    final disposition = headers.value('content-disposition') ?? '';
    final match = RegExp(
      r'filename\s*=\s*"?([^";]+)',
      caseSensitive: false,
    ).firstMatch(disposition);
    final candidate = match?.group(1)?.trim();
    if (candidate == null || candidate.isEmpty) {
      return _fallbackFileName(certificate);
    }
    final safe = candidate.replaceAll(RegExp(r'[^a-zA-Z0-9._-]'), '-');
    final base = safe.toLowerCase().endsWith('.pdf')
        ? safe.substring(0, safe.length - 4)
        : safe;
    final clean = base.replaceAll(RegExp(r'^\.+|\.+$'), '');
    final bounded = clean.substring(0, clean.length.clamp(0, 120));
    return '${bounded.isEmpty ? 'certificado' : bounded}.pdf';
  }

  String _fallbackFileName(CourseCertificate certificate) =>
      'certificado-${_safeSegment(certificate.title)}.pdf';

  String _safeSegment(String value) {
    final safe = value
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9_-]+'), '-')
        .replaceAll(RegExp(r'^-+|-+$'), '');
    return safe.isEmpty
        ? 'archivo'
        : safe.substring(0, safe.length.clamp(0, 80));
  }

  bool _isPdf(List<int> bytes) =>
      bytes.length >= 4 &&
      bytes[0] == 0x25 &&
      bytes[1] == 0x50 &&
      bytes[2] == 0x44 &&
      bytes[3] == 0x46;

  Map<String, dynamic> _body(Map<String, dynamic>? body) {
    if (body == null) return const {};
    final data = body['data'];
    return data is Map<String, dynamic> ? data : body;
  }
}
