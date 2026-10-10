import 'package:dio/dio.dart';
import '../../../core/network/api_error.dart';
import '../domain/institution_directory.dart';

class RemoteInstitutionDirectoryRepository
    implements InstitutionDirectoryRepository {
  RemoteInstitutionDirectoryRepository(this._dio);
  final Dio _dio;

  @override
  Future<InstitutionDirectoryPageData> search({
    required String query,
    required int page,
  }) async {
    if (page < 1 || page > 10000 || query.length > 120) {
      throw ArgumentError('Consulta fuera de los límites del directorio.');
    }
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '/instituciones/directorio',
        queryParameters: {'q': query.trim(), 'pagina': page},
      );
      final data = response.data;
      if (data == null ||
          data['instituciones'] is! List ||
          data['pagina'] != page ||
          data['hayMas'] is! bool) {
        throw const FormatException('Respuesta de directorio inválida.');
      }
      final rows = data['instituciones'] as List;
      if (rows.length > 20) {
        throw const FormatException('Página demasiado grande.');
      }
      return InstitutionDirectoryPageData(
        items: List.unmodifiable(
          rows.map((row) {
            if (row is! Map<String, dynamic>) {
              throw const FormatException('Institución inválida.');
            }
            return PublicInstitution.fromJson(row);
          }),
        ),
        page: page,
        hasMore: data['hayMas'] as bool,
      );
    } on DioException catch (error) {
      throw ApiError.fromDioException(error);
    }
  }

  @override
  Future<PublicInstitution> detail(String id) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '/instituciones/directorio/${Uri.encodeComponent(id)}',
      );
      final item = PublicInstitution.fromJson(response.data ?? {});
      if (item.id != id) throw const FormatException('Institución inesperada.');
      return item;
    } on DioException catch (error) {
      throw ApiError.fromDioException(error);
    }
  }
}

// Datos de ejemplo deliberados, nunca sustituyen un error de la API real.
class DemoInstitutionDirectoryRepository
    implements InstitutionDirectoryRepository {
  static const _items = [
    PublicInstitution(id: 'demo-central', name: 'Colegio Central (ejemplo)'),
    PublicInstitution(id: 'demo-norte', name: 'Instituto del Norte (ejemplo)'),
  ];
  @override
  Future<InstitutionDirectoryPageData> search({
    required String query,
    required int page,
  }) async => InstitutionDirectoryPageData(
    items: page == 1
        ? _items
              .where(
                (item) => item.name.toLowerCase().contains(
                  query.trim().toLowerCase(),
                ),
              )
              .toList()
        : [],
    page: page,
    hasMore: false,
  );
  @override
  Future<PublicInstitution> detail(String id) async =>
      _items.firstWhere((item) => item.id == id);
}
