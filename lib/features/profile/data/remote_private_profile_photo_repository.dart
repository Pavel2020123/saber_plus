import 'dart:typed_data';
import 'package:dio/dio.dart';

import '../../../core/network/api_error.dart';
import '../domain/private_profile_photo.dart';

class RemotePrivateProfilePhotoRepository
    implements PrivateProfilePhotoRepository {
  RemotePrivateProfilePhotoRepository(this._dio);
  final Dio _dio;
  final _cancel = CancelToken();
  static const _root = '/cuenta/archivos';
  void dispose() => _cancel.cancel('Private photo page disposed');

  Map<String, dynamic> _object(Object? data) {
    if (data is! Map<String, dynamic>) {
      throw const FormatException('Respuesta de foto incompleta.');
    }
    return data;
  }

  void _revision(int revision) {
    if (revision < 0 || revision > 2147483646) {
      throw ArgumentError('Actualiza tu foto antes de guardarla.');
    }
  }

  @override
  Future<PrivateProfilePhoto> load() async {
    try {
      final response = await _dio.get<Object?>(
        '$_root/foto',
        cancelToken: _cancel,
      );
      return PrivateProfilePhoto.fromJson(_object(response.data));
    } on DioException catch (error) {
      throw ApiError.fromDioException(error);
    }
  }

  @override
  Future<Uint8List> content(PrivateProfilePhoto photo) async {
    final id = photo.fileId;
    if (!isPrivatePhotoId(id)) {
      throw ArgumentError('No hay una foto para consultar.');
    }
    try {
      final response = await _dio.get<ResponseBody>(
        '$_root/foto/$id',
        cancelToken: _cancel,
        options: Options(responseType: ResponseType.stream),
      );
      final body = response.data;
      final length = response.headers.value('content-length');
      if (body == null ||
          response.headers.value('content-type')?.split(';').first.trim() !=
              'image/webp' ||
          (length != null &&
              (int.tryParse(length) == null ||
                  int.parse(length) > 200 * 1024 ||
                  int.parse(length) <= 0))) {
        if (body != null) await body.stream.listen(null).cancel();
        throw const FormatException(
          'La foto no tiene un formato privado admitido.',
        );
      }
      final bytes = BytesBuilder(copy: false);
      await for (final chunk in body.stream) {
        if (bytes.length + chunk.length > 200 * 1024) {
          throw const FormatException('La foto supera el límite permitido.');
        }
        bytes.add(chunk);
      }
      if (bytes.isEmpty ||
          (length != null && bytes.length != int.parse(length))) {
        throw const FormatException('No se pudo leer tu foto completa.');
      }
      return bytes.takeBytes();
    } on DioException catch (error) {
      throw ApiError.fromDioException(error);
    }
  }

  PrivatePhotoReceipt _receipt(Object? data, String operationId) {
    final receipt = PrivatePhotoReceipt.fromJson(_object(data));
    if (receipt.operationId != operationId) {
      throw const FormatException(
        'La operación recibida no corresponde a tu selección.',
      );
    }
    return receipt;
  }

  @override
  Future<PrivatePhotoReceipt> upload(
    String operationId,
    int revision,
    Uint8List bytes,
  ) async {
    _revision(revision);
    if (!isPrivatePhotoId(operationId) ||
        bytes.isEmpty ||
        bytes.length > 5 * 1024 * 1024) {
      throw ArgumentError('Selecciona una imagen de hasta 5 MiB.');
    }
    try {
      final response = await _dio.post<Object?>(
        '$_root/foto',
        cancelToken: _cancel,
        options: Options(receiveTimeout: const Duration(seconds: 60)),
        data: FormData.fromMap({
          'operacionId': operationId,
          'revision': revision.toString(),
          'archivo': MultipartFile.fromBytes(bytes, filename: 'foto'),
        }),
      );
      return _receipt(response.data, operationId);
    } on DioException catch (error) {
      throw ApiError.fromDioException(error);
    }
  }

  @override
  Future<PrivatePhotoReceipt> operation(String operationId) async {
    if (!isPrivatePhotoId(operationId)) {
      throw ArgumentError('Operación no válida.');
    }
    try {
      final response = await _dio.get<Object?>(
        '$_root/operaciones/$operationId',
        cancelToken: _cancel,
      );
      return _receipt(response.data, operationId);
    } on DioException catch (error) {
      throw ApiError.fromDioException(error);
    }
  }

  @override
  Future<PrivatePhotoRemoval> remove(int revision) async {
    _revision(revision);
    try {
      final response = await _dio.delete<Object?>(
        '$_root/foto',
        data: {'revision': revision},
        cancelToken: _cancel,
      );
      final data = _object(response.data);
      if (data['foto'] is! Map<String, dynamic> ||
          data['limpiezaPendiente'] is! bool) {
        throw const FormatException(
          'No pudimos confirmar la retirada de tu foto.',
        );
      }
      final photo = PrivateProfilePhoto.fromJson(
        data['foto'] as Map<String, dynamic>,
      );
      if (photo.fileId != null) {
        throw const FormatException('La foto todavía no está retirada.');
      }
      return PrivatePhotoRemoval(photo, data['limpiezaPendiente'] as bool);
    } on DioException catch (error) {
      throw ApiError.fromDioException(error);
    }
  }

  @override
  Future<PrivatePhotoReceipt> cancel(String operationId) async {
    if (!isPrivatePhotoId(operationId)) {
      throw ArgumentError('Operación no válida.');
    }
    try {
      final response = await _dio.post<Object?>(
        '$_root/operaciones/$operationId/cancelar',
        cancelToken: _cancel,
      );
      final receipt = _receipt(response.data, operationId);
      if (receipt.state != PrivatePhotoOperationState.retired) {
        throw const FormatException('No pudimos confirmar la cancelación.');
      }
      return receipt;
    } on DioException catch (error) {
      throw ApiError.fromDioException(error);
    }
  }
}
