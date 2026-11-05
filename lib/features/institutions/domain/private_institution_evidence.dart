import 'dart:typed_data';

const institutionEvidenceLimit = 5 * 1024 * 1024;
bool isInstitutionEvidenceId(Object? value) =>
    value is String &&
    RegExp(
      r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$',
      caseSensitive: false,
    ).hasMatch(value);

String institutionEvidencePath(String request, [String? file]) {
  if (!isInstitutionEvidenceId(request) ||
      (file != null && !isInstitutionEvidenceId(file))) {
    throw ArgumentError('Solicitud o adjunto no válido.');
  }
  return '/cuenta/archivos/evidencias/$request${file == null ? '' : '/$file'}';
}

enum InstitutionEvidenceState { prepared, active, retired }

class InstitutionEvidenceFile {
  const InstitutionEvidenceFile({
    required this.requestId,
    required this.id,
    required this.operationId,
    required this.revision,
    required this.state,
    required this.mime,
    required this.bytes,
    required this.available,
    required this.cleanupPending,
    this.expiresAt,
  });
  final String requestId, id, operationId, mime;
  final int revision, bytes;
  final InstitutionEvidenceState state;
  final bool available, cleanupPending;
  final DateTime? expiresAt;

  factory InstitutionEvidenceFile.fromJson(
    Map<String, dynamic> json,
    String requestId,
  ) {
    institutionEvidencePath(requestId);
    final id = json['id'],
        operation = json['operacionId'],
        revision = json['revision'];
    final size = json['bytes'],
        mime = json['mime'],
        available = json['disponible'];
    final cleanup = json['limpiezaPendiente'], expiration = json['venceEn'];
    final state = switch (json['estado']) {
      'PREPARADO' => InstitutionEvidenceState.prepared,
      'ACTIVO' => InstitutionEvidenceState.active,
      'RETIRADO' => InstitutionEvidenceState.retired,
      _ => throw const FormatException('Estado de adjunto no reconocido.'),
    };
    if (!isInstitutionEvidenceId(id) ||
        !isInstitutionEvidenceId(operation) ||
        revision is! int ||
        revision < 1 ||
        revision > 2147483647 ||
        size is! int ||
        size < 1 ||
        size > institutionEvidenceLimit ||
        !['image/webp', 'application/pdf'].contains(mime) ||
        available is! bool ||
        cleanup is! bool ||
        (cleanup && state != InstitutionEvidenceState.retired) ||
        (available &&
            (state != InstitutionEvidenceState.active ||
                json['contenido'] !=
                    institutionEvidencePath(requestId, id as String))) ||
        (!available && json['contenido'] != null) ||
        !json.containsKey('contenido') ||
        !json.containsKey('venceEn')) {
      throw const FormatException('No se pudo validar el adjunto privado.');
    }
    DateTime? expiresAt;
    if (expiration != null) {
      if (expiration is! String ||
          !RegExp(
            r'^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}\.\d{3}Z$',
          ).hasMatch(expiration)) {
        throw const FormatException('Plazo de adjunto no válido.');
      }
      expiresAt = DateTime.tryParse(expiration);
      if (expiresAt == null || expiresAt.toIso8601String() != expiration) {
        throw const FormatException('Plazo de adjunto no válido.');
      }
    }
    // Device time is for displaying the deadline, never for granting permission.
    return InstitutionEvidenceFile(
      requestId: requestId,
      id: id as String,
      operationId: operation as String,
      revision: revision,
      state: state,
      mime: mime as String,
      bytes: size,
      available: available,
      cleanupPending: cleanup,
      expiresAt: expiresAt,
    );
  }
}

class InstitutionEvidenceList {
  InstitutionEvidenceList({
    required this.revision,
    required this.canUpload,
    required List<InstitutionEvidenceFile> files,
  }) : files = List.unmodifiable(files);
  final int revision;
  final bool canUpload;
  final List<InstitutionEvidenceFile> files;
  factory InstitutionEvidenceList.fromJson(
    Map<String, dynamic> json,
    String requestId,
  ) {
    institutionEvidencePath(requestId);
    final revision = json['revision'],
        upload = json['puedeAdjuntar'],
        rows = json['adjuntos'];
    if (revision is! int ||
        revision < 1 ||
        revision > 2147483647 ||
        upload is! bool ||
        rows is! List ||
        rows.length > 3) {
      throw const FormatException('Lista de adjuntos no válida.');
    }
    final files = rows.map((row) {
      if (row is! Map<String, dynamic>) {
        throw const FormatException('Adjunto incompleto.');
      }
      final file = InstitutionEvidenceFile.fromJson(row, requestId);
      if (!file.available || file.revision != revision) {
        throw const FormatException('La lista cambió. Actualiza los adjuntos.');
      }
      return file;
    }).toList();
    if (files.map((f) => f.id).toSet().length != files.length ||
        files.map((f) => f.operationId).toSet().length != files.length) {
      throw const FormatException('Adjuntos repetidos en la respuesta.');
    }
    return InstitutionEvidenceList(
      revision: revision,
      canUpload: upload,
      files: files,
    );
  }
}

/// Stable in-memory selection for idempotent retry; never stores a path or filename.
class InstitutionEvidenceDraft {
  factory InstitutionEvidenceDraft(Uint8List input) {
    if (input.isEmpty || input.length > institutionEvidenceLimit) {
      throw ArgumentError('Selecciona una imagen o PDF de hasta 5 MiB.');
    }
    return InstitutionEvidenceDraft._(
      Uint8List.fromList(input).asUnmodifiableView(),
    );
  }
  InstitutionEvidenceDraft._(this.bytes);
  final Uint8List bytes;
}

abstract interface class PrivateInstitutionEvidenceRepository {
  Future<InstitutionEvidenceList> load();
  Future<InstitutionEvidenceFile> operation(String operationId);
  Future<InstitutionEvidenceFile> upload(
    String operationId,
    int revision,
    InstitutionEvidenceDraft draft,
  );
  Future<InstitutionEvidenceFile> remove(String fileId, int revision);
  Future<Uint8List> content(InstitutionEvidenceFile file);
}
