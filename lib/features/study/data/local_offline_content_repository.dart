import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';

import '../../../core/database/app_database.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_error.dart';
import '../../academic/domain/academic_models.dart';
import '../domain/offline_content_models.dart';
import '../domain/offline_content_repository.dart';
import '../domain/study_models.dart';

typedef OfflineDirectoryProvider = Future<Directory> Function();

class LocalOfflineContentRepository implements OfflineContentRepository {
  LocalOfflineContentRepository(
    this._dio,
    this._database, {
    OfflineDirectoryProvider? rootDirectory,
  }) : _rootDirectory = rootDirectory ?? getApplicationDocumentsDirectory;

  final Dio _dio;
  final AppDatabase _database;
  final OfflineDirectoryProvider _rootDirectory;

  @override
  Stream<List<OfflineThemeDownload>> watchDownloads(String userId) => _database
      .watchOfflineDownloads(userId)
      .map((rows) => rows.map(_fromRow).toList(growable: false));

  @override
  Future<OfflineThemeDownload?> findDownload(
    String userId,
    String themeId,
  ) async {
    final row = await _database.findOfflineDownload(userId, themeId);
    if (row == null) return null;
    final download = _fromRow(row);
    if (await File(download.localPath).exists()) return download;
    await _database.removeOfflineDownload(userId, themeId);
    return null;
  }

  @override
  Future<OfflineThemeDownload> downloadTheme({
    required String userId,
    required AcademicArea area,
    required StudyTheme theme,
  }) async {
    File? partialFile;
    try {
      final response = await _dio.get<List<int>>(
        '/simulacros/temas/${Uri.encodeComponent(theme.id)}/pdf',
        options: Options(responseType: ResponseType.bytes),
      );
      final bytes = response.data;
      if (bytes == null || bytes.isEmpty) {
        throw const ApiError(
          code: 'empty_pdf',
          message: 'El servidor entregó un PDF vacío.',
        );
      }

      final directory = await _userDirectory(userId);
      final fileName =
          'tema-${_safeFileName(theme.name)}-${_safeFileName(theme.id)}.pdf';
      final file = File('${directory.path}${Platform.pathSeparator}$fileName');
      partialFile = File('${file.path}.part');
      await partialFile.writeAsBytes(bytes, flush: true);
      if (await file.exists()) await file.delete();
      await partialFile.rename(file.path);
      partialFile = null;

      final downloadedAt = DateTime.now().toUtc();
      await _database.saveOfflineDownload(
        OfflineDownloadsCompanion.insert(
          userId: userId,
          themeId: theme.id,
          area: area.slug,
          themeName: theme.name,
          fileName: fileName,
          localPath: file.path,
          byteSize: bytes.length,
          downloadedAt: downloadedAt,
        ),
      );
      return OfflineThemeDownload(
        userId: userId,
        themeId: theme.id,
        areaSlug: area.slug,
        themeName: theme.name,
        fileName: fileName,
        localPath: file.path,
        byteSize: bytes.length,
        downloadedAt: downloadedAt,
      );
    } on DioException catch (error) {
      throw ApiError.fromDioException(error);
    } on ApiError {
      rethrow;
    } on FileSystemException {
      throw const ApiError(
        code: 'local_storage_error',
        message: 'No pudimos guardar el PDF en este dispositivo.',
      );
    } finally {
      if (partialFile != null && await partialFile.exists()) {
        await partialFile.delete();
      }
    }
  }

  @override
  Future<void> deleteDownload(OfflineThemeDownload download) async {
    try {
      final file = File(download.localPath);
      if (await file.exists()) await file.delete();
      await _database.removeOfflineDownload(download.userId, download.themeId);
    } on FileSystemException {
      throw const ApiError(
        code: 'local_storage_error',
        message: 'No pudimos eliminar el archivo del dispositivo.',
      );
    }
  }

  @override
  Future<void> deleteAll(String userId) async {
    final rows = await _database.watchOfflineDownloads(userId).first;
    try {
      for (final row in rows) {
        final file = File(row.localPath);
        if (await file.exists()) await file.delete();
      }
      await _database.removeAllOfflineDownloads(userId);
    } on FileSystemException {
      throw const ApiError(
        code: 'local_storage_error',
        message: 'No pudimos liberar todo el espacio solicitado.',
      );
    }
  }

  Future<Directory> _userDirectory(String userId) async {
    final root = await _rootDirectory();
    final directory = Directory(
      '${root.path}${Platform.pathSeparator}saber_plus${Platform.pathSeparator}offline${Platform.pathSeparator}${_safeFileName(userId)}',
    );
    await directory.create(recursive: true);
    return directory;
  }

  OfflineThemeDownload _fromRow(OfflineDownload row) => OfflineThemeDownload(
    userId: row.userId,
    themeId: row.themeId,
    areaSlug: row.area,
    themeName: row.themeName,
    fileName: row.fileName,
    localPath: row.localPath,
    byteSize: row.byteSize,
    downloadedAt: row.downloadedAt,
  );
}

String _safeFileName(String value) {
  const replacements = {
    'á': 'a',
    'é': 'e',
    'í': 'i',
    'ó': 'o',
    'ú': 'u',
    'ñ': 'n',
  };
  var normalized = value.toLowerCase();
  replacements.forEach((key, replacement) {
    normalized = normalized.replaceAll(key, replacement);
  });
  final safe = normalized
      .replaceAll(RegExp('[^a-z0-9]+'), '-')
      .replaceAll(RegExp(r'^-+|-+$'), '');
  return safe.isEmpty
      ? 'contenido'
      : safe.substring(0, safe.length.clamp(0, 60));
}

final offlineContentRepositoryProvider = Provider<OfflineContentRepository>(
  (ref) => LocalOfflineContentRepository(
    ref.watch(dioProvider),
    ref.watch(appDatabaseProvider),
  ),
);
