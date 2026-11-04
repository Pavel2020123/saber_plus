/// Online backend decision; never an offline permission or device-clock rule.
class PersonalReturnEligibility {
  const PersonalReturnEligibility._({
    required this.allowed,
    required this.managed,
    required this.assignmentId,
    required this.assignmentVersion,
  });

  final bool allowed;
  final bool managed;
  final String? assignmentId;
  final String? assignmentVersion;

  factory PersonalReturnEligibility.fromJson(Map<String, dynamic> json) {
    final allowed = json['puedeVolver'];
    final managed = json['gestionada'];
    final id = json['asignacionId'];
    final version = json['versionAsignacion'];
    final validVersion =
        version is String &&
        RegExp(r'T.*(?:Z|[+-]\d{2}:\d{2})$').hasMatch(version) &&
        DateTime.tryParse(version) != null;
    if (allowed is! bool ||
        managed is! bool ||
        (id != null && (id is! String || id.isEmpty)) ||
        (version != null && !validVersion) ||
        (allowed && (managed || id == null || !validVersion))) {
      throw const FormatException('Invalid personal return decision');
    }
    return PersonalReturnEligibility._(
      allowed: allowed,
      managed: managed,
      assignmentId: id as String?,
      assignmentVersion: version as String?,
    );
  }
}
