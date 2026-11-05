import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import '../../../core/network/api_error.dart';
import '../domain/private_institution_evidence.dart';
import '../domain/student_institution_request.dart';

const privateInstitutionEvidenceEnabled = bool.fromEnvironment(
  'PRIVATE_INSTITUTION_EVIDENCE_ENABLED',
);

/// Per-owner native bridge. No local path, URI, filename or broad grant crosses it.
class PrivateDocumentAccess {
  PrivateDocumentAccess({
    required this.isCurrent,
    this.enabled = privateInstitutionEvidenceEnabled,
    this.channel = const MethodChannel('saberplus/private_documents_v1'),
    TargetPlatform? platform,
    String Function()? operationId,
  }) : platform = platform ?? defaultTargetPlatform,
       newOperationId = operationId ?? newStudentRequestId;
  final bool Function() isCurrent;
  final bool enabled;
  final MethodChannel channel;
  final TargetPlatform platform;
  final String Function() newOperationId;
  String? _operation;
  bool _closed = false;

  void _check() {
    if (!enabled || kIsWeb || platform != TargetPlatform.android) {
      throw const ApiError(
        code: 'private_documents_unavailable',
        message:
            'Los documentos privados requieren Android y una instalación de pruebas habilitada.',
      );
    }
    if (_closed || !isCurrent()) {
      throw const ApiError(
        code: 'session_changed',
        message:
            'La sesión cambió. Si elegiste un destino para exportar, revisa cualquier copia en ese destino.',
      );
    }
  }

  Future<Object?> _invoke(String method, Map<String, Object> data) async {
    _check();
    if (_operation != null) {
      throw const ApiError(
        code: 'private_document_busy',
        message: 'Termina o cancela la selección anterior.',
      );
    }
    final operation = newOperationId();
    if (!isInstitutionEvidenceId(operation)) {
      throw ArgumentError('Operación de documento no válida.');
    }
    _operation = operation;
    try {
      final value = await channel.invokeMethod<Object?>(method, {
        'operationId': operation,
        ...data,
      });
      _check();
      return value;
    } on PlatformException catch (error) {
      _check();
      throw ApiError(
        code: error.code,
        message: switch (error.code) {
          'DOCUMENT_TOO_LARGE' => 'Selecciona un archivo de hasta 5 MiB.',
          'DOCUMENT_BUSY' =>
            'Todavía hay una operación de documentos en curso. Espera o vuelve a abrir la pantalla.',
          'DOCUMENT_CANCELLED' =>
            'La selección fue cancelada. No se subió ningún archivo.',
          'DOCUMENT_EXPORT_UNCONFIRMED' =>
            'No pudimos confirmar la exportación. Revisa el destino que elegiste; puede existir una copia completa o parcial.',
          _ =>
            'No pudimos completar la operación de documentos. Revisa el archivo o vuelve a abrir la pantalla.',
        },
      );
    } on MissingPluginException {
      throw const ApiError(
        code: 'private_documents_unavailable',
        message:
            'Esta instalación todavía no incluye el selector de documentos privados.',
      );
    } finally {
      if (_operation == operation) _operation = null;
    }
  }

  /// Call only from the user's selection action, never as part of loading a page.
  Future<InstitutionEvidenceDraft?> pick() async {
    return _pick('pick');
  }

  /// Image-only Android selection for private photos; no plugin disk cache.
  Future<Uint8List?> pickImage() async => (await _pick('pickImage'))?.bytes;

  Future<InstitutionEvidenceDraft?> _pick(String method) async {
    final result = await _invoke(method, {});
    if (result == null) return null;
    if (result is! Uint8List) {
      throw const FormatException('El selector no entregó un archivo válido.');
    }
    return InstitutionEvidenceDraft(result);
  }

  /// Caller must obtain explicit consent for an untrusted, non-revocable copy.
  Future<bool> exportFile(
    InstitutionEvidenceFile file,
    Uint8List bytes, {
    required bool confirmed,
  }) async {
    if (!confirmed) return false;
    _check();
    institutionEvidencePath(file.requestId, file.id);
    if (!file.available ||
        file.state != InstitutionEvidenceState.active ||
        !['application/pdf', 'image/webp'].contains(file.mime) ||
        bytes.isEmpty ||
        bytes.length > institutionEvidenceLimit ||
        bytes.length != file.bytes) {
      throw ArgumentError('El adjunto no está disponible para exportar.');
    }
    final result = await _invoke('export', {
      'bytes': Uint8List.fromList(bytes),
      'mime': file.mime,
    });
    if (result is! bool) {
      throw const FormatException(
        'No pudimos confirmar la exportación. Revisa el destino elegido.',
      );
    }
    return result;
  }

  Future<void> cancel() async {
    final operation = _operation;
    if (operation == null) return;
    try {
      await channel.invokeMethod<Object?>('cancel', {'operationId': operation});
    } on Object {
      /* Cancellation acknowledgement is not a saved/exported file receipt. */
    }
  }

  void dispose() {
    _closed = true;
    unawaited(cancel());
  }
}
