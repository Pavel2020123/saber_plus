import 'package:flutter_test/flutter_test.dart';
import 'package:saber_plus/features/academic/domain/academic_models.dart';
import 'package:saber_plus/features/exam_countdown/domain/exam_countdown_models.dart';

void main() {
  final exam = ActiveExam(
    id: 'calendar-2026-a',
    year: 2026,
    calendar: 'A',
    examDate: DateTime(2026, 9, 6),
  );

  test('calcula los días usando fechas de calendario completas', () {
    final countdown = ExamCountdown.calculate(
      exam: exam,
      now: DateTime(2026, 8, 29, 23, 59),
    );

    expect(countdown.daysRemaining, 8);
    expect(countdown.status, ExamCountdownStatus.upcoming);
    expect(countdown.headline, 'Faltan 8 días');
    expect(countdown.compactLabel, 'ICFES en 8 días');
    expect(countdown.detail, contains('6 de septiembre'));
  });

  test('distingue mañana, el día del examen y una fecha vencida', () {
    final tomorrow = ExamCountdown.calculate(
      exam: exam,
      now: DateTime(2026, 9, 5),
    );
    final today = ExamCountdown.calculate(
      exam: exam,
      now: DateTime(2026, 9, 6),
    );
    final elapsed = ExamCountdown.calculate(
      exam: exam,
      now: DateTime(2026, 9, 7),
    );

    expect(tomorrow.headline, 'Falta 1 día');
    expect(tomorrow.compactLabel, 'ICFES mañana');
    expect(today.status, ExamCountdownStatus.today);
    expect(today.headline, 'El examen es hoy');
    expect(elapsed.status, ExamCountdownStatus.elapsed);
    expect(elapsed.compactLabel, 'Actualizar fecha ICFES');
  });
}
