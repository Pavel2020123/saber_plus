import 'package:flutter_test/flutter_test.dart';
import 'package:saber_plus/features/gamification/domain/gamification_models.dart';

void main() {
  test('interpreta racha, actividad y progreso de logros', () {
    final summary = GamificationSummary.fromJson({
      'racha': {
        'actual': 3,
        'mejor': 7,
        'activoHoy': true,
        'ultimaActividad': '2026-08-28',
      },
      'actividad': [
        {'fecha': '2026-08-28', 'cantidad': 4},
      ],
      'resumen': {'desbloqueados': 2, 'total': 16, 'preguntasRespondidas': 25},
      'logros': [
        {
          'id': 'MENTE_ACTIVA',
          'titulo': 'Mente activa',
          'descripcion': 'Responde 25 preguntas.',
          'categoria': 'PRACTICA',
          'desbloqueado': true,
          'progreso': 25,
          'meta': 25,
          'porcentaje': 100,
        },
      ],
    });

    expect(summary.streak.current, 3);
    expect(summary.streak.best, 7);
    expect(summary.streak.activeToday, isTrue);
    expect(summary.activityOn(DateTime(2026, 8, 28)), 4);
    expect(summary.totals.completion, 0.125);
    expect(summary.achievements.single.category, AchievementCategory.practice);
    expect(summary.achievements.single.remaining, 0);
  });

  test('limita valores inválidos para mantener segura la interfaz', () {
    final achievement = Achievement.fromJson({
      'id': 'DESCONOCIDO',
      'categoria': 'NUEVA_CATEGORIA',
      'progreso': 20,
      'meta': 10,
      'porcentaje': 140,
    });

    expect(achievement.category, AchievementCategory.other);
    expect(achievement.progress, 10);
    expect(achievement.percentage, 100);
    expect(achievement.remaining, 0);
  });

  test('rechaza una actividad sin fecha válida', () {
    expect(
      () => DailyActivity.fromJson({'fecha': 'incorrecta', 'cantidad': 1}),
      throwsFormatException,
    );
  });
}
