import 'package:dio/dio.dart';
import '../../../core/network/api_error.dart';
import '../domain/institution_profile.dart';

class RemoteInstitutionProfileRepository
    implements InstitutionProfileRepository {
  RemoteInstitutionProfileRepository(this._dio);
  final Dio _dio;
  static const _path = '/instituciones/me/perfil';
  @override
  Future<InstitutionProfile> load() async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(_path);
      if (response.data == null) throw const FormatException('Perfil vacío.');
      return InstitutionProfile.fromJson(response.data!);
    } on DioException catch (error) {
      throw ApiError.fromDioException(error);
    }
  }

  @override
  Future<InstitutionProfile> save(
    InstitutionProfile current,
    String description,
  ) async {
    final text = description.trim();
    if (!current.canEdit || text.runes.length > 500) {
      throw ArgumentError('No se puede guardar esta presentación.');
    }
    try {
      final response = await _dio.patch<Map<String, dynamic>>(
        _path,
        data: {'revision': current.revision, 'descripcion': text},
      );
      final data = response.data;
      final expected = text.isEmpty ? null : text;
      if (data == null ||
          data['revision'] != current.revision + 1 ||
          data['descripcion'] != expected) {
        throw const FormatException('No se pudo confirmar el guardado.');
      }
      return InstitutionProfile(
        id: current.id,
        name: current.name,
        description: expected,
        revision: current.revision + 1,
        canEdit: true,
        logoUrl: current.logoUrl,
      );
    } on DioException catch (error) {
      throw ApiError.fromDioException(error);
    }
  }
}

// Demostración explícita en memoria, nunca respaldo de un error de red.
class DemoInstitutionProfileRepository implements InstitutionProfileRepository {
  InstitutionProfile _profile = const InstitutionProfile(
    id: 'demo-central',
    name: 'Institución de demostración',
    description: null,
    revision: 0,
    canEdit: true,
  );
  @override
  Future<InstitutionProfile> load() async => _profile;
  @override
  Future<InstitutionProfile> save(
    InstitutionProfile current,
    String description,
  ) async {
    if (current.revision != _profile.revision ||
        !current.canEdit ||
        description.trim().runes.length > 500) {
      throw const ApiError(
        code: '409',
        message: 'Recarga el perfil antes de guardar.',
      );
    }
    return _profile = InstitutionProfile(
      id: _profile.id,
      name: _profile.name,
      description: description.trim().isEmpty ? null : description.trim(),
      revision: _profile.revision + 1,
      canEdit: true,
    );
  }
}
