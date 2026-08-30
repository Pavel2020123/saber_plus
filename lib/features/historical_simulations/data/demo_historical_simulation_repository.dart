import '../../../core/network/api_error.dart';
import '../../practice/domain/practice_models.dart';
import '../domain/historical_simulation_models.dart';
import '../domain/historical_simulation_repository.dart';

class DemoHistoricalSimulationRepository
    implements HistoricalSimulationRepository {
  @override
  Future<HistoricalSimulationCatalog>
  loadCatalog() async => HistoricalSimulationCatalog(
    updatedAt: DateTime(2026, 8, 30),
    editions: const [
      HistoricalSimulationEdition(
        id: 'demo-2025',
        year: 2025,
        title: 'Edición 2025',
        description:
            'Espacio reservado para una prueba propia o autorizada correspondiente a 2025.',
        provider: 'Pendiente de fuente autorizada',
        questionCount: 0,
        availability: HistoricalSimulationAvailability.comingSoon,
      ),
      HistoricalSimulationEdition(
        id: 'demo-2024',
        year: 2024,
        title: 'Edición 2024',
        description:
            'No se mostrará contenido hasta registrar la licencia o autorización de reutilización.',
        provider: 'Sin contenido cargado',
        questionCount: 0,
        availability: HistoricalSimulationAvailability.restricted,
      ),
    ],
  );

  @override
  Future<PracticeSession> startEdition({
    required String editionId,
    required OfficialSimulationBlock block,
  }) => throw const ApiError(
    code: 'historical_content_unavailable',
    message:
        'Esta edición todavía no cuenta con contenido autorizado para iniciar.',
  );

  @override
  Future<PracticeResult> gradeEdition({
    required String editionId,
    required OfficialSimulationBlock block,
    required String attemptId,
    required List<PracticeAnswer> answers,
  }) => throw const ApiError(
    code: 'historical_content_unavailable',
    message: 'No existe un intento histórico autorizado para calificar.',
  );
}
