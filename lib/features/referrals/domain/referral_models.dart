class ReferralInvitation {
  const ReferralInvitation({required this.id, required this.registeredAt});

  final String id;
  final DateTime registeredAt;

  factory ReferralInvitation.fromJson(Map<String, dynamic> json) =>
      ReferralInvitation(
        id: json['id'] as String,
        registeredAt: DateTime.parse(json['fechaRegistro'] as String).toLocal(),
      );
}

class ReferralBenefit {
  const ReferralBenefit({required this.status, required this.description});

  final String status;
  final String description;

  bool get isPendingDefinition => status == 'POR_DEFINIR';

  factory ReferralBenefit.fromJson(Map<String, dynamic> json) =>
      ReferralBenefit(
        status: json['estado'] as String? ?? 'POR_DEFINIR',
        description:
            json['descripcion'] as String? ??
            'El beneficio del programa se publicará próximamente.',
      );
}

class ReferralSummary {
  const ReferralSummary({
    required this.code,
    required this.totalInvitations,
    required this.invitations,
    required this.benefit,
  });

  final String code;
  final int totalInvitations;
  final List<ReferralInvitation> invitations;
  final ReferralBenefit benefit;

  String get shareText =>
      'Estudia conmigo en SaberPlus. Usa mi código $code al crear tu cuenta.';

  factory ReferralSummary.fromJson(Map<String, dynamic> json) {
    final rawInvitations = json['invitaciones'];
    return ReferralSummary(
      code: json['codigo'] as String,
      totalInvitations: json['totalInvitaciones'] as int? ?? 0,
      invitations: rawInvitations is List
          ? rawInvitations
                .whereType<Map>()
                .map(
                  (item) => ReferralInvitation.fromJson(
                    Map<String, dynamic>.from(item),
                  ),
                )
                .toList(growable: false)
          : const [],
      benefit: ReferralBenefit.fromJson(
        json['beneficio'] is Map
            ? Map<String, dynamic>.from(json['beneficio'] as Map)
            : const {},
      ),
    );
  }
}
