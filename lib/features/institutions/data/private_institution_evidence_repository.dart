import 'dart:typed_data';
import 'package:dio/dio.dart';
import '../../../core/network/api_error.dart';
import '../domain/private_institution_evidence.dart';

class RemotePrivateInstitutionEvidenceRepository
    implements PrivateInstitutionEvidenceRepository {
  RemotePrivateInstitutionEvidenceRepository(
    this._dio,
    this.requestId, {
    required this.isCurrent,
  }) {
    institutionEvidencePath(requestId);
  }
  final Dio _dio;
  final String requestId;
  final bool Function() isCurrent;
  final _cancel = CancelToken();
  String get _path => institutionEvidencePath(requestId);
  void dispose() => _cancel.cancel('Private evidence page disposed');

  void _check() {
    if (_cancel.isCancelled || !isCurrent()) {
      throw const ApiError(
        code: 'session_changed',
        message: 'La sesión cambió. Vuelve a abrir los documentos privados.',
      );
    }
  }

  Map<String, dynamic> _object(Object? data) {
    if (data is! Map<String, dynamic>) {
      throw const FormatException('Respuesta privada incompleta.');
    }
    return data;
  }

  Future<T> _run<T>(Future<T> Function() work) async {
    _check();
    try {
      final result = await work();
      _check();
      return result;
    } on DioException catch (error) {
      _check();
      throw ApiError.fromDioException(error);
    }
  }

  void _revision(int revision) {
    if (revision < 1 || revision > 2147483646) {
      throw ArgumentError('Actualiza la solicitud antes de enviar.');
    }
  }

  InstitutionEvidenceFile _file(Object? data, {String? operation, String? id}) {
    final file = InstitutionEvidenceFile.fromJson(_object(data), requestId);
    if ((operation != null && file.operationId != operation) ||
        (id != null && file.id != id)) {
      throw const FormatException(
        'El recibo no corresponde al envío seleccionado.',
      );
    }
    return file;
  }

  @override
  Future<InstitutionEvidenceList> load() => _run(() async {
    final response = await _dio.get<Object?>(_path, cancelToken: _cancel);
    return InstitutionEvidenceList.fromJson(_object(response.data), requestId);
  });
  @override
  Future<InstitutionEvidenceFile> operation(String operationId) {
    if (!isInstitutionEvidenceId(operationId)) {
      throw ArgumentError('Envío no válido.');
    }
    return _run(() async {
      final response = await _dio.get<Object?>(
        '$_path/operaciones/$operationId',
        cancelToken: _cancel,
      );
      return _file(response.data, operation: operationId);
    });
  }

  @override
  Future<InstitutionEvidenceFile> upload(
    String operationId,
    int revision,
    InstitutionEvidenceDraft draft,
  ) {
    _revision(revision);
    if (!isInstitutionEvidenceId(operationId) ||
        draft.bytes.isEmpty ||
        draft.bytes.length > institutionEvidenceLimit) {
      throw ArgumentError('Selecciona un adjunto de hasta 5 MiB.');
    }
    return _run(() async {
      final response = await _dio.post<Object?>(
        _path,
        cancelToken: _cancel,
        options: Options(receiveTimeout: const Duration(seconds: 60)),
        data: FormData.fromMap({
          'operacionId': operationId,
          'revision': revision.toString(),
          'archivo': MultipartFile.fromBytes(
            draft.bytes,
            filename: 'documento',
          ),
        }),
      );
      return _file(response.data, operation: operationId);
    });
  }

  @override
  Future<InstitutionEvidenceFile> remove(String fileId, int revision) {
    _revision(revision);
    final path = institutionEvidencePath(requestId, fileId);
    return _run(() async {
      final response = await _dio.delete<Object?>(
        path,
        cancelToken: _cancel,
        data: {'revision': revision},
      );
      final file = _file(response.data, id: fileId);
      if (file.state != InstitutionEvidenceState.retired) {
        throw const FormatException('No se pudo confirmar la retirada.');
      }
      return file;
    });
  }

  @override
  Future<Uint8List> content(InstitutionEvidenceFile file) {
    if (!file.available ||
        file.requestId != requestId ||
        file.state != InstitutionEvidenceState.active ||
        file.bytes < 1 ||
        file.bytes > institutionEvidenceLimit ||
        !['application/pdf', 'image/webp'].contains(file.mime)) {
      throw ArgumentError('Adjunto no disponible.');
    }
    final path = institutionEvidencePath(requestId, file.id);
    return _run(() async {
      final response = await _dio.get<ResponseBody>(
        path,
        cancelToken: _cancel,
        options: Options(
          responseType: ResponseType.stream,
          headers: {'Accept': 'application/pdf,image/webp'},
        ),
      );
      final body = response.data;
      final declared = response.headers.value('content-length');
      if (body == null ||
          response.headers.value('content-type')?.split(';').first.trim() !=
              file.mime ||
          (declared != null &&
              (!RegExp(r'^\d+$').hasMatch(declared) ||
                  int.tryParse(declared) != file.bytes))) {
        if (body != null) await body.stream.listen(null).cancel();
        throw const FormatException(
          'El adjunto no coincide con su información privada.',
        );
      }
      final output = BytesBuilder(copy: false);
      await for (final chunk in body.stream) {
        _check();
        if (output.length + chunk.length > file.bytes ||
            output.length + chunk.length > institutionEvidenceLimit) {
          throw const FormatException('El adjunto supera el tamaño permitido.');
        }
        output.add(chunk);
      }
      if (output.length != file.bytes) {
        throw const FormatException('La descarga quedó incompleta.');
      }
      return output.takeBytes();
    });
  }
}
