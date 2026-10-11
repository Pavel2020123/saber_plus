import 'package:dio/dio.dart';
import '../../../core/network/api_error.dart';

class TerritoryOption {
  const TerritoryOption(this.code, this.name, {this.department, this.type});
  final String code, name;
  final String? department, type;
}

class TerritoryCatalogPage {
  const TerritoryCatalogPage(this.version, this.options);
  final String version;
  final List<TerritoryOption> options;

  factory TerritoryCatalogPage.parse(Object? value, {String? department}) {
    if (value is! Map ||
        value['version'] is! String ||
        (value['version'] as String).isEmpty ||
        (department != null && value['departamentoCodigo'] != department)) {
      throw const FormatException('Catálogo territorial inválido');
    }
    final rows = value[department == null ? 'departamentos' : 'municipios'];
    if (rows is! List || rows.isEmpty || rows.length > 1300) {
      throw const FormatException('Catálogo territorial incompleto');
    }
    final codes = <String>{};
    final options = rows.map((row) {
      if (row is! Map ||
          row['codigo'] is! String ||
          !RegExp(
            department == null ? r'^\d{2}$' : r'^\d{5}$',
          ).hasMatch(row['codigo'] as String) ||
          !codes.add(row['codigo'] as String) ||
          row['nombre'] is! String ||
          (row['nombre'] as String).trim().isEmpty ||
          (department != null &&
              (row['departamentoCodigo'] != department ||
                  !(row['codigo'] as String).startsWith(department) ||
                  row['tipo'] is! String))) {
        throw const FormatException('Unidad territorial inválida');
      }
      return TerritoryOption(
        row['codigo'] as String,
        row['nombre'] as String,
        department: department,
        type: row['tipo'] as String?,
      );
    }).toList()..sort((a, b) => a.name.compareTo(b.name));
    return TerritoryCatalogPage(
      value['version'] as String,
      List.unmodifiable(options),
    );
  }
}

class InstitutionTerritorySelection {
  const InstitutionTerritorySelection(
    this.department,
    this.municipality,
    this.version,
  );
  final TerritoryOption department, municipality;
  final String version;
}

abstract interface class InstitutionTerritoryRepository {
  Future<TerritoryCatalogPage> departments({CancelToken? cancelToken});
  Future<TerritoryCatalogPage> municipalities(
    String department, {
    CancelToken? cancelToken,
  });
}

class RemoteInstitutionTerritoryRepository
    implements InstitutionTerritoryRepository {
  RemoteInstitutionTerritoryRepository(this.dio);
  final Dio dio;
  Future<TerritoryCatalogPage> _get(
    String path,
    String? department,
    CancelToken? cancelToken,
  ) async {
    try {
      final response = await dio.get<Object?>(path, cancelToken: cancelToken);
      return TerritoryCatalogPage.parse(response.data, department: department);
    } on DioException catch (e) {
      throw ApiError.fromDioException(e);
    }
  }

  @override
  Future<TerritoryCatalogPage> departments({CancelToken? cancelToken}) =>
      _get('/instituciones/territorio/departamentos', null, cancelToken);
  @override
  Future<TerritoryCatalogPage> municipalities(
    String department, {
    CancelToken? cancelToken,
  }) {
    if (!RegExp(r'^\d{2}$').hasMatch(department)) {
      throw const FormatException('Departamento inválido');
    }
    return _get(
      '/instituciones/territorio/departamentos/$department/municipios',
      department,
      cancelToken,
    );
  }
}

// Small, explicit demonstration fixture; never used as a network fallback.
class DemoInstitutionTerritoryRepository
    implements InstitutionTerritoryRepository {
  @override
  Future<TerritoryCatalogPage> departments({CancelToken? cancelToken}) async =>
      const TerritoryCatalogPage('demo', [
        TerritoryOption('91', 'Amazonas'),
        TerritoryOption('11', 'Bogotá D.C.'),
        TerritoryOption('20', 'Cesar'),
      ]);
  @override
  Future<TerritoryCatalogPage> municipalities(
    String department, {
    CancelToken? cancelToken,
  }) async {
    final name = {
      '91': 'Leticia',
      '11': 'Bogotá D.C.',
      '20': 'Valledupar',
    }[department];
    if (name == null) {
      throw const FormatException('Departamento de demo inválido');
    }
    return TerritoryCatalogPage('demo', [
      TerritoryOption(
        '${department}001',
        name,
        department: department,
        type: 'MUNICIPIO',
      ),
    ]);
  }
}
