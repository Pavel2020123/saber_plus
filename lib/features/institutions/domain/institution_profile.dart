class InstitutionProfile {
  const InstitutionProfile({
    required this.id,
    required this.name,
    required this.description,
    required this.revision,
    required this.canEdit,
  });
  final String id, name;
  final String? description;
  final int revision;
  final bool canEdit;

  factory InstitutionProfile.fromJson(Map<String, dynamic> json) {
    final id = json['id'],
        name = json['nombre'],
        description = json['descripcion'];
    final revision = json['revision'], canEdit = json['puedeEditar'];
    if (id is! String ||
        id.isEmpty ||
        name is! String ||
        name.trim().isEmpty ||
        (description != null && description is! String) ||
        revision is! int ||
        revision < 0 ||
        canEdit is! bool) {
      throw const FormatException('Perfil institucional inválido.');
    }
    return InstitutionProfile(
      id: id,
      name: name,
      description: description as String?,
      revision: revision,
      canEdit: canEdit,
    );
  }
}

abstract interface class InstitutionProfileRepository {
  Future<InstitutionProfile> load();
  Future<InstitutionProfile> save(
    InstitutionProfile current,
    String description,
  );
}
