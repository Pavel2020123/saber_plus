import 'dart:typed_data';

bool isPrivatePhotoId(Object? value) =>
    value is String &&
    RegExp(
      r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$',
      caseSensitive: false,
    ).hasMatch(value);

class PrivateProfilePhoto {
  const PrivateProfilePhoto({required this.revision, this.fileId});
  final int revision;
  final String? fileId;

  factory PrivateProfilePhoto.fromJson(Map<String, dynamic> json) {
    final revision = json['revision'];
    final id = json['archivoId'];
    if (revision is! int ||
        revision < 0 ||
        revision > 2147483647 ||
        !json.containsKey('archivoId') ||
        !json.containsKey('contenido') ||
        (id != null && !isPrivatePhotoId(id)) ||
        json['contenido'] !=
            (id == null ? null : '/cuenta/archivos/foto/$id')) {
      throw const FormatException('No se pudo validar tu foto privada.');
    }
    return PrivateProfilePhoto(revision: revision, fileId: id as String?);
  }
}

enum PrivatePhotoOperationState { prepared, active, retired }

class PrivatePhotoReceipt {
  const PrivatePhotoReceipt({
    required this.id,
    required this.operationId,
    required this.state,
    required this.photo,
    required this.cleanupPending,
  });
  final String id, operationId;
  final PrivatePhotoOperationState state;
  final PrivateProfilePhoto photo;
  final bool cleanupPending;

  factory PrivatePhotoReceipt.fromJson(Map<String, dynamic> json) {
    final state = switch (json['estado']) {
      'PREPARADO' => PrivatePhotoOperationState.prepared,
      'ACTIVO' => PrivatePhotoOperationState.active,
      'RETIRADO' => PrivatePhotoOperationState.retired,
      _ => throw const FormatException('Estado de foto no reconocido.'),
    };
    final rawPhoto = json['foto'];
    if (!isPrivatePhotoId(json['id']) ||
        !isPrivatePhotoId(json['operacionId']) ||
        rawPhoto is! Map<String, dynamic> ||
        json['limpiezaPendiente'] is! bool) {
      throw const FormatException(
        'No se pudo confirmar la operación de tu foto.',
      );
    }
    final photo = PrivateProfilePhoto.fromJson(rawPhoto);
    if ((state == PrivatePhotoOperationState.active &&
            photo.fileId != json['id']) ||
        (state != PrivatePhotoOperationState.retired &&
            json['limpiezaPendiente'] == true)) {
      throw const FormatException('La confirmación de foto es inconsistente.');
    }
    return PrivatePhotoReceipt(
      id: json['id'] as String,
      operationId: json['operacionId'] as String,
      state: state,
      photo: photo,
      cleanupPending: json['limpiezaPendiente'] as bool,
    );
  }
}

class PrivatePhotoRemoval {
  const PrivatePhotoRemoval(this.photo, this.cleanupPending);
  final PrivateProfilePhoto photo;
  final bool cleanupPending;
}

abstract interface class PrivateProfilePhotoRepository {
  Future<PrivateProfilePhoto> load();
  Future<Uint8List> content(PrivateProfilePhoto photo);
  Future<PrivatePhotoReceipt> upload(
    String operationId,
    int revision,
    Uint8List bytes,
  );
  Future<PrivatePhotoReceipt> operation(String operationId);
  Future<PrivatePhotoReceipt> cancel(String operationId);
  Future<PrivatePhotoRemoval> remove(int revision);
}
