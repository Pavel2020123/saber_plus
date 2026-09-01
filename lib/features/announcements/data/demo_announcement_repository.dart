import '../domain/announcement_models.dart';
import '../domain/announcement_repository.dart';

class DemoAnnouncementRepository implements AnnouncementRepository {
  DemoAnnouncementRepository()
    : _board = AnnouncementBoard.fromJson({
        'pendientes': 2,
        'anuncios': [
          {
            'id': 'demo-institucion',
            'titulo': 'Simulacro institucional este viernes',
            'contenido':
                'Tu institución programó un simulacro. Revisa el horario con tu profesor antes de comenzar.',
            'tipo': 'IMPORTANTE',
            'origen': 'INSTITUCION',
            'fechaInicio': DateTime.now()
                .subtract(const Duration(hours: 4))
                .toUtc()
                .toIso8601String(),
            'fechaFin': null,
            'destacado': true,
            'leido': false,
            'fechaLectura': null,
          },
          {
            'id': 'demo-saberplus',
            'titulo': 'Nuevos repasos disponibles',
            'contenido':
                'Ya puedes practicar con tu cuaderno de errores y continuar desde el último tema estudiado.',
            'tipo': 'INFORMACION',
            'origen': 'SABERPLUS',
            'fechaInicio': DateTime.now()
                .subtract(const Duration(days: 1))
                .toUtc()
                .toIso8601String(),
            'fechaFin': null,
            'destacado': false,
            'leido': false,
            'fechaLectura': null,
          },
        ],
      });

  AnnouncementBoard _board;

  @override
  Future<AnnouncementBoard> load() async => _board;

  @override
  Future<DateTime> markRead(String id) async {
    final now = DateTime.now();
    _board = _board.markRead(id, now);
    return now;
  }

  @override
  Future<void> markAllRead() async {
    _board = _board.markAllRead(DateTime.now());
  }
}
