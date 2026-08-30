import 'package:flutter_test/flutter_test.dart';
import 'package:saber_plus/features/academic/domain/academic_models.dart';
import 'package:saber_plus/features/practice/domain/practice_history_models.dart';
import 'package:saber_plus/features/profile/domain/academic_profile_models.dart';
import 'package:saber_plus/features/progress/domain/progress_models.dart';
import 'package:saber_plus/features/study/domain/study_models.dart';

void main() {
  test('detecta fortaleza y prioridad con respuestas confirmadas', () {
    final insights = AcademicAreaInsights.fromSources(progress: _progress());

    expect(insights.strongest?.area, AcademicArea.english);
    expect(insights.strongest?.percentage, 90);
    expect(insights.needsReinforcement?.area, AcademicArea.mathematics);
    expect(insights.needsReinforcement?.percentage, 50);
  });

  test('respeta las áreas explícitas del diagnóstico', () {
    final insights = AcademicAreaInsights.fromSources(
      progress: _progress(),
      diagnostic: const DiagnosticSummary(
        status: DiagnosticStatus.completed,
        strengthArea: AcademicArea.criticalReading,
        priorityArea: AcademicArea.naturalSciences,
        resultsByArea: [
          AreaDiagnosticResult(
            area: AcademicArea.naturalSciences,
            totalQuestions: 3,
            correctAnswers: 1,
            percentage: 33.3,
            level: DiagnosticLevel.needsReinforcement,
          ),
        ],
      ),
    );

    expect(insights.strongest?.area, AcademicArea.criticalReading);
    expect(insights.needsReinforcement?.area, AcademicArea.naturalSciences);
    expect(insights.needsReinforcement?.percentage, 33.3);
  });

  test('valida el objetivo dentro de la escala global', () {
    expect(PersonalExamGoal.isValidScore(350), isTrue);
    expect(PersonalExamGoal.isValidScore(100), isTrue);
    expect(PersonalExamGoal.isValidScore(500), isTrue);
    expect(PersonalExamGoal.isValidScore(99), isFalse);
    expect(PersonalExamGoal.isValidScore(501), isFalse);
  });
}

ProgressDashboard _progress() => const ProgressDashboard(
  study: StudyProgress.empty,
  answers: ProgressDashboard.emptyAnswers,
  byArea: {
    AcademicArea.mathematics: AnswerHistorySummary(
      total: 10,
      correct: 5,
      incorrect: 5,
      successPercentage: 50,
    ),
    AcademicArea.criticalReading: AnswerHistorySummary(
      total: 10,
      correct: 8,
      incorrect: 2,
      successPercentage: 80,
    ),
    AcademicArea.naturalSciences: AnswerHistorySummary(
      total: 10,
      correct: 6,
      incorrect: 4,
      successPercentage: 60,
    ),
    AcademicArea.english: AnswerHistorySummary(
      total: 10,
      correct: 9,
      incorrect: 1,
      successPercentage: 90,
    ),
  },
);
