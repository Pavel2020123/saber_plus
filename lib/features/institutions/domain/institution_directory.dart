class PublicInstitution {
  const PublicInstitution({
    required this.id,
    required this.name,
    this.departmentCode,
    this.municipalityCode,
    this.locationLabel,
    this.description,
  });
  final String id;
  final String name;
  final String? description;
  final String? departmentCode, municipalityCode, locationLabel;

  factory PublicInstitution.fromJson(Map<String, dynamic> json) {
    final id = json['id'];
    final name = json['nombre'];
    if (id is! String || id.isEmpty || name is! String || name.trim().isEmpty) {
      throw const FormatException('Identidad institucional inválida.');
    }
    final description = json['descripcion'];
    if (description != null &&
        (description is! String || description.length > 500)) {
      throw const FormatException('Presentación institucional inválida.');
    }
    final location = json['ubicacion'];
    if (location == null) {
      return PublicInstitution(
        id: id,
        name: name,
        description: description as String?,
      );
    }
    if (location is! Map ||
        location['departamentoCodigo'] is! String ||
        location['municipioCodigo'] is! String ||
        !RegExp(
          r'^\d{2}$',
        ).hasMatch(location['departamentoCodigo'] as String) ||
        !RegExp(r'^\d{5}$').hasMatch(location['municipioCodigo'] as String) ||
        !(location['municipioCodigo'] as String).startsWith(
          location['departamentoCodigo'] as String,
        ) ||
        location['departamentoNombre'] is! String ||
        location['municipioNombre'] is! String ||
        (location['departamentoNombre'] as String).trim().isEmpty ||
        (location['municipioNombre'] as String).trim().isEmpty) {
      throw const FormatException('Ubicación pública inválida.');
    }
    return PublicInstitution(
      id: id,
      name: name,
      description: description as String?,
      departmentCode: location['departamentoCodigo'] as String,
      municipalityCode: location['municipioCodigo'] as String,
      locationLabel:
          '${location['municipioNombre']} · ${location['departamentoNombre']}',
    );
  }
}

class InstitutionDirectoryPageData {
  const InstitutionDirectoryPageData({
    required this.items,
    required this.page,
    required this.hasMore,
  });
  final List<PublicInstitution> items;
  final int page;
  final bool hasMore;
}

abstract interface class InstitutionDirectoryRepository {
  Future<InstitutionDirectoryPageData> search({
    required String query,
    required int page,
    String? department,
    String? municipality,
  });
  Future<PublicInstitution> detail(String id);
}
