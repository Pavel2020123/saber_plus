class PublicInstitution {
  const PublicInstitution({required this.id, required this.name});
  final String id;
  final String name;

  factory PublicInstitution.fromJson(Map<String, dynamic> json) {
    final id = json['id'];
    final name = json['nombre'];
    if (id is! String || id.isEmpty || name is! String || name.trim().isEmpty) {
      throw const FormatException('Identidad institucional inválida.');
    }
    return PublicInstitution(id: id, name: name);
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
  });
  Future<PublicInstitution> detail(String id);
}
