import '../../academic/domain/academic_models.dart';
import 'practice_history_models.dart';
import 'practice_models.dart';

abstract interface class PracticeRepository {
  Future<PracticeSession> startSubtopicPractice({
    required AcademicArea area,
    required String subtopicId,
  });

  Future<PracticeResult> gradePractice({
    required String attemptId,
    required AcademicArea area,
    required List<PracticeAnswer> answers,
  });

  Future<PracticeSession> startRandomPractice(RandomPracticeConfig config);

  Future<PracticeResult> gradeRandomPractice({
    required String attemptId,
    required List<PracticeAnswer> answers,
  });

  Future<PracticeSession> startAreaSimulation(AcademicArea area);

  Future<PracticeResult> gradeAreaSimulation({
    required String attemptId,
    required AcademicArea area,
    required List<PracticeAnswer> answers,
  });

  Future<SimulationHistory> loadSimulationHistory();

  Future<AnswerHistory> loadAnswerHistory(AnswerHistoryFilter filter);
}
