import 'package:flutter_test/flutter_test.dart';
import 'package:saber_plus/features/academic/domain/academic_models.dart';
import 'package:saber_plus/features/study/domain/study_models.dart';
import 'package:saber_plus/features/study/domain/syllabus_countdown_models.dart';

void main() {
  test('calcula pendientes y ritmo semanal usando el catálogo real', () {
    final countdown = SyllabusCountdown.calculate(
      catalogs: _catalogs,
      progress: const StudyProgress(
        totalSubtopics: 5,
        viewedSubtopics: 2,
        completedSubtopics: 1,
        overallPercentage: 30,
        bySubtopic: {
          'demo-mathematics-subtopic': 100,
          'demo-criticalReading-subtopic': 50,
        },
      ),
      exam: ActiveExam(
        id: 'exam',
        year: 2026,
        calendar: 'A',
        examDate: DateTime(2026, 9, 27),
      ),
      now: DateTime(2026, 8, 30),
    );

    expect(countdown.daysRemaining, 28);
    expect(countdown.totalSubtopics, 5);
    expect(countdown.completedSubtopics, 1);
    expect(countdown.inProgressSubtopics, 1);
    expect(countdown.remainingSubtopics, 4);
    expect(countdown.requiredPerWeek, 1);
    expect(countdown.status, SyllabusPaceStatus.manageable);
    expect(countdown.areas.last.area, AcademicArea.mathematics);
    expect(countdown.areas.last.remainingSubtopics, 0);
  });

  test('marca un ritmo intensivo cuando quedan pocos días', () {
    final countdown = SyllabusCountdown.calculate(
      catalogs: _catalogs,
      progress: StudyProgress.empty,
      exam: ActiveExam(
        id: 'exam',
        year: 2026,
        calendar: 'A',
        examDate: DateTime(2026, 8, 31),
      ),
      now: DateTime(2026, 8, 30),
    );

    expect(countdown.requiredPerWeek, 35);
    expect(countdown.status, SyllabusPaceStatus.intensive);
  });

  test('conserva el temario aunque no exista una fecha activa', () {
    final countdown = SyllabusCountdown.calculate(
      catalogs: _catalogs,
      progress: StudyProgress.empty,
      exam: null,
      now: DateTime(2026, 8, 30),
    );

    expect(countdown.daysRemaining, isNull);
    expect(countdown.remainingSubtopics, 5);
    expect(countdown.requiredPerWeek, 0);
    expect(countdown.status, SyllabusPaceStatus.dateMissing);
  });
}

final _catalogs = [
  for (final area in AcademicArea.values) StudyCatalog.demo(area),
];
