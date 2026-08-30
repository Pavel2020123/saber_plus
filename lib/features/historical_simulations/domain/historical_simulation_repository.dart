import '../../practice/domain/practice_models.dart';
import 'historical_simulation_models.dart';

abstract interface class HistoricalSimulationRepository {
  Future<HistoricalSimulationCatalog> loadCatalog();

  Future<PracticeSession> startEdition({
    required String editionId,
    required OfficialSimulationBlock block,
  });

  Future<PracticeResult> gradeEdition({
    required String editionId,
    required OfficialSimulationBlock block,
    required String attemptId,
    required List<PracticeAnswer> answers,
  });
}
