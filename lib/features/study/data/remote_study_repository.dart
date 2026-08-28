import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/api_error.dart';
import '../../academic/domain/academic_models.dart';
import '../domain/study_models.dart';
import '../domain/study_repository.dart';

typedef DownloadDirectoryProvider = Future<Directory> Function();

class RemoteStudyRepository implements StudyRepository {
  RemoteStudyRepository(
    this._dio, {
    DownloadDirectoryProvider? downloadDirectory,
  }) : _downloadDirectory = downloadDirectory ?? _systemTemporaryDirectory;

  final Dio _dio;
  final DownloadDirectoryProvider _downloadDirectory;

  @override
  Future<StudyCatalog> loadCatalog(AcademicArea area) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '/simulacros/temas',
        queryParameters: {'area': area.backendValue},
      );
      return StudyCatalog.fromJson(_body(response.data));
    } on DioException catch (error) {
      throw ApiError.fromDioException(error);
    }
  }

  @override
  Future<StudyProgress> loadProgress() async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '/simulacros/progreso',
      );
      return StudyProgress.fromJson(_body(response.data));
    } on DioException catch (error) {
      throw ApiError.fromDioException(error);
    }
  }

  @override
  Future<void> updateSubtopicProgress(String subtopicId, int percentage) async {
    try {
      await _dio.post<Map<String, dynamic>>(
        '/simulacros/progreso',
        data: {'subtemaId': subtopicId, 'porcentaje': percentage.clamp(0, 100)},
      );
    } on DioException catch (error) {
      throw ApiError.fromDioException(error);
    }
  }

  @override
  Future<DownloadedThemePdf> downloadThemePdf(StudyTheme theme) async {
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

      final root = await _downloadDirectory();
      final directory = Directory(
        '${root.path}${Platform.pathSeparator}saberplus${Platform.pathSeparator}temas',
      );
      await directory.create(recursive: true);
      final fileName = 'tema-${_safeFileName(theme.name)}.pdf';
      final file = File('${directory.path}${Platform.pathSeparator}$fileName');
      await file.writeAsBytes(bytes, flush: true);
      return DownloadedThemePdf(path: file.path, fileName: fileName);
    } on DioException catch (error) {
      throw ApiError.fromDioException(error);
    } on FileSystemException {
      throw const ApiError(
        code: 'local_storage_error',
        message: 'No pudimos guardar el PDF en este dispositivo.',
      );
    }
  }

  Map<String, dynamic> _body(Map<String, dynamic>? body) {
    if (body == null) return const {};
    final data = body['data'];
    return data is Map<String, dynamic> ? data : body;
  }
}

Future<Directory> _systemTemporaryDirectory() async => Directory.systemTemp;

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
  return safe.isEmpty ? 'icfes' : safe.substring(0, safe.length.clamp(0, 70));
}

final studyRepositoryProvider = Provider<StudyRepository>(
  (ref) => RemoteStudyRepository(ref.watch(dioProvider)),
);
