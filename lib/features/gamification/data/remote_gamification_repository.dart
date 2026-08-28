import 'dart:io';

import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';

import '../../../core/network/api_error.dart';
import '../domain/gamification_models.dart';
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
  Future<AchievementCertificate?> findCertificate({
    required String userId,
    required Achievement achievement,
  }) async {
    final file = await _certificateFile(userId, achievement.id);
    if (!await file.exists()) return null;
    final bytes = await file
        .openRead(0, 4)
        .fold<List<int>>(<int>[], (buffer, chunk) => buffer..addAll(chunk));
    if (!_isPdf(bytes)) {
      await file.delete();
      return null;
    }
    final stat = await file.stat();
    return AchievementCertificate(
      achievementId: achievement.id,
      fileName: _fallbackFileName(achievement),
      localPath: file.path,
      byteSize: stat.size,
      downloadedAt: stat.modified.toUtc(),
    );
  }

  @override
  Future<AchievementCertificate> downloadCertificate({
    required String userId,
    required Achievement achievement,
  }) async {
    if (!achievement.unlocked) {
      throw const ApiError(
        code: 'achievement_locked',
        message: 'Completa este logro antes de descargar su certificado.',
      );
    }
    try {
      final response = await _dio.get<List<int>>(
        '/gamificacion/logros/${Uri.encodeComponent(achievement.id)}/certificado',
        options: Options(responseType: ResponseType.bytes),
      );
      final bytes = response.data ?? const <int>[];
      if (!_isPdf(bytes) || bytes.length > _maximumCertificateBytes) {
        throw const ApiError(
          code: 'invalid_certificate',
          message: 'El servidor no entregó un certificado PDF válido.',
        );
      }

      final file = await _certificateFile(userId, achievement.id);
      await file.parent.create(recursive: true);
      final partial = File('${file.path}.part');
      await partial.writeAsBytes(bytes, flush: true);
      if (await file.exists()) await file.delete();
      await partial.rename(file.path);
      final stat = await file.stat();
      return AchievementCertificate(
        achievementId: achievement.id,
        fileName: _responseFileName(response.headers, achievement),
        localPath: file.path,
        byteSize: stat.size,
        downloadedAt: stat.modified.toUtc(),
      );
    } on DioException catch (error) {
      throw ApiError.fromDioException(error);
    }
  }

  Future<File> _certificateFile(String userId, String achievementId) async {
    final root = await _certificateDirectory();
    final separator = Platform.pathSeparator;
    final directory = Directory(
      '${root.path}${separator}saberplus${separator}certificates$separator${_safeSegment(userId)}',
    );
    return File(
      '${directory.path}$separator${_safeSegment(achievementId)}.pdf',
    );
  }

  String _responseFileName(Headers headers, Achievement achievement) {
    final disposition = headers.value('content-disposition') ?? '';
    final match = RegExp(
      r'filename\s*=\s*"?([^";]+)',
      caseSensitive: false,
    ).firstMatch(disposition);
    final candidate = match?.group(1)?.trim();
    if (candidate == null || candidate.isEmpty) {
      return _fallbackFileName(achievement);
    }
    final safe = candidate.replaceAll(RegExp(r'[^a-zA-Z0-9._-]'), '-');
    return safe.toLowerCase().endsWith('.pdf') ? safe : '$safe.pdf';
  }

  String _fallbackFileName(Achievement achievement) =>
      'certificado-${_safeSegment(achievement.title)}.pdf';

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
