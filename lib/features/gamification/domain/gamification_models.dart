class StudyStreak {
  const StudyStreak({
    required this.current,
    required this.best,
    required this.activeToday,
    this.lastActivity,
  });

  final int current;
  final int best;
  final bool activeToday;
  final DateTime? lastActivity;

  factory StudyStreak.fromJson(Map<String, dynamic> json) => StudyStreak(
    current: _nonNegativeInt(json['actual']),
    best: _nonNegativeInt(json['mejor']),
    activeToday: json['activoHoy'] as bool? ?? false,
    lastActivity: _date(json['ultimaActividad']),
  );

  static const empty = StudyStreak(current: 0, best: 0, activeToday: false);
}

class DailyActivity {
  const DailyActivity({required this.date, required this.count});

  final DateTime date;
  final int count;

  factory DailyActivity.fromJson(Map<String, dynamic> json) {
    final date = _date(json['fecha']);
    if (date == null) {
      throw const FormatException('La actividad no contiene una fecha válida.');
    }
    return DailyActivity(date: date, count: _nonNegativeInt(json['cantidad']));
  }

  String get dateKey => _dateKey(date);
}

enum AchievementCategory {
  practice('PRACTICA', 'Práctica'),
  precision('PRECISION', 'Precisión'),
  simulations('SIMULACROS', 'Simulacros'),
  study('ESTUDIO', 'Estudio'),
  streak('RACHA', 'Racha'),
  battles('BATALLAS', 'Batallas'),
  other('', 'Otros');

  const AchievementCategory(this.backendValue, this.label);

  final String backendValue;
  final String label;

  static AchievementCategory fromBackend(Object? value) => values.firstWhere(
    (category) => category.backendValue == value,
    orElse: () => AchievementCategory.other,
  );
}

class Achievement {
  const Achievement({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.unlocked,
    required this.progress,
    required this.goal,
    required this.percentage,
  });

  final String id;
  final String title;
  final String description;
  final AchievementCategory category;
  final bool unlocked;
  final int progress;
  final int goal;
  final int percentage;

  int get remaining => (goal - progress).clamp(0, goal);

  factory Achievement.fromJson(Map<String, dynamic> json) {
    final goal = _nonNegativeInt(json['meta']);
    final progress = _nonNegativeInt(json['progreso']).clamp(0, goal);
    return Achievement(
      id: json['id'] as String? ?? '',
      title: json['titulo'] as String? ?? 'Logro',
      description: json['descripcion'] as String? ?? '',
      category: AchievementCategory.fromBackend(json['categoria']),
      unlocked: json['desbloqueado'] as bool? ?? false,
      progress: progress,
      goal: goal,
      percentage: _nonNegativeInt(json['porcentaje']).clamp(0, 100),
    );
  }
}

class AchievementTotals {
  const AchievementTotals({
    required this.unlocked,
    required this.total,
    required this.answeredQuestions,
  });

  final int unlocked;
  final int total;
  final int answeredQuestions;

  factory AchievementTotals.fromJson(Map<String, dynamic> json) =>
      AchievementTotals(
        unlocked: _nonNegativeInt(json['desbloqueados']),
        total: _nonNegativeInt(json['total']),
        answeredQuestions: _nonNegativeInt(json['preguntasRespondidas']),
      );

  double get completion => total == 0 ? 0 : (unlocked / total).clamp(0, 1);

  static const empty = AchievementTotals(
    unlocked: 0,
    total: 0,
    answeredQuestions: 0,
  );
}

class GamificationSummary {
  const GamificationSummary({
    required this.streak,
    required this.activity,
    required this.totals,
    required this.achievements,
  });

  final StudyStreak streak;
  final List<DailyActivity> activity;
  final AchievementTotals totals;
  final List<Achievement> achievements;

  factory GamificationSummary.fromJson(Map<String, dynamic> json) =>
      GamificationSummary(
        streak: StudyStreak.fromJson(_map(json['racha'])),
        activity: _list(json['actividad'])
            .map((item) => DailyActivity.fromJson(_map(item)))
            .toList(growable: false),
        totals: AchievementTotals.fromJson(_map(json['resumen'])),
        achievements: _list(json['logros'])
            .map((item) => Achievement.fromJson(_map(item)))
            .toList(growable: false),
      );

  int activityOn(DateTime date) {
    final key = _dateKey(date);
    return activity
        .where((item) => item.dateKey == key)
        .fold(0, (total, item) => total + item.count);
  }

  static const empty = GamificationSummary(
    streak: StudyStreak.empty,
    activity: [],
    totals: AchievementTotals.empty,
    achievements: [],
  );
}

Map<String, dynamic> _map(Object? value) =>
    Map<String, dynamic>.from(value as Map? ?? const {});

List<Object?> _list(Object? value) =>
    List<Object?>.from(value as List? ?? const []);

int _nonNegativeInt(Object? value) {
  final number = value is num ? value.toInt() : int.tryParse('$value') ?? 0;
  return number < 0 ? 0 : number;
}

DateTime? _date(Object? value) {
  if (value is! String || value.isEmpty) return null;
  return DateTime.tryParse(value);
}

String _dateKey(DateTime date) =>
    '${date.year.toString().padLeft(4, '0')}-'
    '${date.month.toString().padLeft(2, '0')}-'
    '${date.day.toString().padLeft(2, '0')}';
