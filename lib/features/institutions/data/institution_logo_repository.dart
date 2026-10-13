import 'dart:typed_data';
import 'package:dio/dio.dart';
import '../domain/institution_profile.dart';

abstract interface class InstitutionLogoRepository {
  Future<InstitutionProfile> save(InstitutionProfile current, Uint8List? bytes);
}

class RemoteInstitutionLogoRepository implements InstitutionLogoRepository {
  RemoteInstitutionLogoRepository(this._dio);
  final Dio _dio;

  @override
  Future<InstitutionProfile> save(
    InstitutionProfile current,
    Uint8List? bytes,
  ) async {
    if (!current.canEdit ||
        (bytes != null && (bytes.isEmpty || bytes.length > 3 * 1024 * 1024))) {
      throw ArgumentError('Selecciona una imagen de hasta 3 MB.');
    }
    const path = '/instituciones/me/logo';
    final Response<Map<String, dynamic>> response;
    if (bytes == null) {
      response = await _dio.delete<Map<String, dynamic>>(
        path,
        data: {'revision': current.revision},
      );
    } else {
      response = await _dio.post<Map<String, dynamic>>(
        path,
        data: FormData.fromMap({
          'revision': current.revision.toString(),
          'logo': MultipartFile.fromBytes(bytes, filename: 'logo.img'),
        }),
      );
    }
    final data = response.data;
    final expected = bytes == null
        ? null
        : '/instituciones/directorio/${current.id}/logo/${current.revision + 1}';
    if (data == null ||
        data['revision'] != current.revision + 1 ||
        data['logoUrl'] != expected) {
      throw const FormatException('No se pudo confirmar el cambio de logo.');
    }
    return InstitutionProfile(
      id: current.id,
      name: current.name,
      description: current.description,
      revision: current.revision + 1,
      canEdit: true,
      logoUrl: institutionLogoPath(data['logoUrl']),
    );
  }
}
