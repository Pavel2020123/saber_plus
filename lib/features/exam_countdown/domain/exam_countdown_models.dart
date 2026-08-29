import '../../academic/domain/academic_models.dart';

enum ExamCountdownStatus { upcoming, today, elapsed }

class ExamCountdown {
  const ExamCountdown({
    required this.exam,
    required this.daysRemaining,
    required this.status,
  });

  final ActiveExam exam;
  final int daysRemaining;
  final ExamCountdownStatus status;

  factory ExamCountdown.calculate({
    required ActiveExam exam,
    required DateTime now,
  }) {
    final days = exam.daysRemaining(now);
    return ExamCountdown(
      exam: exam,
      daysRemaining: days,
      status: days > 0
          ? ExamCountdownStatus.upcoming
          : days == 0
          ? ExamCountdownStatus.today
          : ExamCountdownStatus.elapsed,
    );
  }

  String get headline => switch (status) {
    ExamCountdownStatus.upcoming when daysRemaining == 1 => 'Falta 1 día',
    ExamCountdownStatus.upcoming => 'Faltan $daysRemaining días',
    ExamCountdownStatus.today => 'El examen es hoy',
    ExamCountdownStatus.elapsed => 'Fecha pendiente de actualización',
  };

  String get compactLabel => switch (status) {
    ExamCountdownStatus.upcoming when daysRemaining == 1 => 'ICFES mañana',
    ExamCountdownStatus.upcoming => 'ICFES en $daysRemaining días',
    ExamCountdownStatus.today => 'ICFES hoy',
    ExamCountdownStatus.elapsed => 'Actualizar fecha ICFES',
  };

  String get detail =>
      'ICFES ${exam.year} · Calendario ${exam.calendar} · ${formatExamDate(exam.examDate)}';
}

String formatExamDate(DateTime date) {
  const months = [
    'enero',
    'febrero',
    'marzo',
    'abril',
    'mayo',
    'junio',
    'julio',
    'agosto',
    'septiembre',
    'octubre',
    'noviembre',
    'diciembre',
  ];
  return '${date.day} de ${months[date.month - 1]}';
}
