enum InstitutionalLicenseState {
  noLicense,
  scheduled,
  active,
  expired,
  suspended,
}

/// Presentation snapshot from the backend, not an offline grant or local clock policy.
class InstitutionalAccess {
  const InstitutionalAccess({
    required this.institutionId,
    required this.state,
    required this.managedAccount,
    required this.hasAssignment,
    required this.practiceAllowed,
    required this.historyAllowed,
    required this.validatedAt,
    this.startsAt,
    this.endsAt,
  });

  final String institutionId;
  final InstitutionalLicenseState state;
  final bool managedAccount;
  final bool hasAssignment;
  final bool practiceAllowed;
  final bool historyAllowed;
  final DateTime validatedAt;
  final DateTime? startsAt;
  final DateTime? endsAt;

  bool get canStartPractice =>
      state == InstitutionalLicenseState.active &&
      hasAssignment &&
      practiceAllowed;

  String get statusLabel {
    if (state == InstitutionalLicenseState.active && !hasAssignment) {
      return 'Sin cupo asignado';
    }
    return switch (state) {
      InstitutionalLicenseState.noLicense => 'Sin licencia institucional',
      InstitutionalLicenseState.scheduled => 'Licencia programada',
      InstitutionalLicenseState.active => 'Licencia activa',
      InstitutionalLicenseState.expired => 'Licencia vencida',
      InstitutionalLicenseState.suspended => 'Licencia suspendida',
    };
  }

  factory InstitutionalAccess.fromJson(Map<String, dynamic> json) {
    const states = {
      'SIN_LICENCIA': InstitutionalLicenseState.noLicense,
      'PROGRAMADA': InstitutionalLicenseState.scheduled,
      'ACTIVA': InstitutionalLicenseState.active,
      'VENCIDA': InstitutionalLicenseState.expired,
      'SUSPENDIDA': InstitutionalLicenseState.suspended,
    };
    final state = states[json['estadoLicencia']];
    final id = json['institucionId'];
    final origin = json['origenCuenta'];
    final assigned = json['asignacionActiva'];
    final practice = json['permitePractica'];
    final history = json['permiteHistorial'];
    if (json['version'] != 1 ||
        state == null ||
        id is! String ||
        id.isEmpty ||
        (origin != 'GESTIONADA' && origin != 'PERSONAL_VINCULADA') ||
        assigned is! bool ||
        practice is! bool ||
        history is! bool ||
        (practice &&
            (state != InstitutionalLicenseState.active || !assigned))) {
      throw const FormatException('Invalid institutional access snapshot');
    }
    return InstitutionalAccess(
      institutionId: id,
      state: state,
      managedAccount: origin == 'GESTIONADA',
      hasAssignment: assigned,
      practiceAllowed: practice,
      historyAllowed: history,
      validatedAt: _date(json['validadoEn']),
      startsAt: json['inicio'] == null ? null : _date(json['inicio']),
      endsAt: json['fin'] == null ? null : _date(json['fin']),
    );
  }

  Map<String, dynamic> toJson() => {
    'version': 1,
    'institucionId': institutionId,
    'estadoLicencia': const {
      InstitutionalLicenseState.noLicense: 'SIN_LICENCIA',
      InstitutionalLicenseState.scheduled: 'PROGRAMADA',
      InstitutionalLicenseState.active: 'ACTIVA',
      InstitutionalLicenseState.expired: 'VENCIDA',
      InstitutionalLicenseState.suspended: 'SUSPENDIDA',
    }[state],
    'origenCuenta': managedAccount ? 'GESTIONADA' : 'PERSONAL_VINCULADA',
    'asignacionActiva': hasAssignment,
    'permitePractica': practiceAllowed,
    'permiteHistorial': historyAllowed,
    'inicio': startsAt?.toUtc().toIso8601String(),
    'fin': endsAt?.toUtc().toIso8601String(),
    'validadoEn': validatedAt.toUtc().toIso8601String(),
  };

  static DateTime _date(Object? value) {
    if (value is! String || !RegExp(r'(Z|[+-]\d{2}:\d{2})$').hasMatch(value)) {
      throw const FormatException('Institutional date requires a timezone');
    }
    final date = DateTime.tryParse(value);
    if (date == null) throw const FormatException('Invalid institutional date');
    return date.toUtc();
  }
}
