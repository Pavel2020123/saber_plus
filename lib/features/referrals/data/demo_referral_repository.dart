import '../domain/referral_models.dart';
import '../domain/referral_repository.dart';

class DemoReferralRepository implements ReferralRepository {
  @override
  Future<ReferralSummary> loadSummary() async => ReferralSummary.fromJson({
    'codigo': 'SABER2026',
    'totalInvitaciones': 2,
    'invitaciones': [
      {
        'id': 'demo-referral-1',
        'fechaRegistro': DateTime.now()
            .subtract(const Duration(days: 2))
            .toUtc()
            .toIso8601String(),
      },
      {
        'id': 'demo-referral-2',
        'fechaRegistro': DateTime.now()
            .subtract(const Duration(days: 8))
            .toUtc()
            .toIso8601String(),
      },
    ],
    'beneficio': {
      'estado': 'POR_DEFINIR',
      'descripcion':
          'Podrás invitar a otros estudiantes. El beneficio se publicará cuando esté configurado el comercio móvil.',
    },
  });
}
