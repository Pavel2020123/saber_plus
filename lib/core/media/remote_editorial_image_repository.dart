import 'dart:async';
import 'dart:typed_data';

import 'package:dio/dio.dart';

import '../network/access_token_store.dart';
import 'editorial_image_reference.dart';

/// Reads only private API resources, with bounded bytes and no disk cache.
class RemoteEditorialImageRepository {
  RemoteEditorialImageRepository(this._dio, this._tokens);

  final Dio _dio;
  final AccessTokenStore _tokens;
  static const maxBytes = 2 * 1024 * 1024;

  Future<Uint8List> load(
    EditorialImageReference reference, {
    required CancelToken cancelToken,
  }) async {
    final revision = _tokens.revision;
    if (_tokens.accessToken?.isNotEmpty != true) {
      throw StateError('Inicia sesión para consultar esta imagen.');
    }
    final deadline = Timer(
      const Duration(seconds: 30),
      () => cancelToken.cancel('La imagen tardó demasiado.'),
    );
    try {
      final response = await _dio.get<ResponseBody>(
        reference.path,
        cancelToken: cancelToken,
        options: Options(
          responseType: ResponseType.stream,
          followRedirects: false,
          headers: {'Accept': 'image/webp'},
        ),
      );
      final body = response.data;
      final type = response.headers.value(Headers.contentTypeHeader);
      final length = response.headers.value(Headers.contentLengthHeader);
      final declaredLength = length == null ? null : int.tryParse(length);
      // Close the response even when the status or headers are rejected.
      if (response.statusCode != 200 ||
          body == null ||
          type?.split(';').first.trim().toLowerCase() != 'image/webp' ||
          (length != null &&
              (declaredLength == null ||
                  declaredLength <= 0 ||
                  declaredLength > maxBytes))) {
        await body?.stream.listen(null).cancel();
        throw const FormatException('Respuesta de imagen inválida.');
      }
      final bytes = BytesBuilder(copy: false);
      await for (final chunk in body.stream) {
        if (cancelToken.isCancelled || revision != _tokens.revision) {
          throw StateError('La sesión cambió durante la descarga.');
        }
        if (bytes.length + chunk.length > maxBytes) {
          throw const FormatException('La imagen supera el límite permitido.');
        }
        bytes.add(chunk);
      }
      final result = bytes.takeBytes();
      if (revision != _tokens.revision || cancelToken.isCancelled) {
        throw StateError('La sesión cambió durante la descarga.');
      }
      if (result.length < 12 ||
          String.fromCharCodes(result.take(4)) != 'RIFF' ||
          String.fromCharCodes(result.skip(8).take(4)) != 'WEBP' ||
          (declaredLength != null && declaredLength != result.length)) {
        throw const FormatException('Contenido de imagen inválido.');
      }
      return result;
    } finally {
      deadline.cancel();
      // Dio's bounded output stream does not itself cancel the HTTP source.
      // Each load owns a fresh token; close the underlying source on every exit.
      cancelToken.cancel('Descarga finalizada.');
    }
  }
}
