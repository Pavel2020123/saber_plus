import '../../../academic/domain/academic_models.dart';
import '../../../practice/domain/practice_models.dart';

enum TriviaRushDuration {
  quick(60, '60 s', 'Una ronda rápida'),
  standard(90, '90 s', 'Equilibrio entre ritmo y precisión'),
  extended(120, '120 s', 'Más tiempo para construir combos');

  const TriviaRushDuration(this.seconds, this.label, this.description);

  final int seconds;
  final String label;
  final String description;

  static TriviaRushDuration? tryFromSeconds(int seconds) {
    for (final value in values) {
      if (value.seconds == seconds) return value;
    }
    return null;
  }
}

class TriviaRushConfig {
  const TriviaRushConfig({required this.areas, required this.duration});

  final List<AcademicArea> areas;
  final TriviaRushDuration duration;

  bool get isMixed => areas.length > 1;

  String get routeLocation => Uri(
    path: '/student/practice/trivia-rush/play',
    queryParameters: {
      'areas': areas.map((area) => area.backendValue).join(','),
      'segundos': duration.seconds.toString(),
    },
  ).toString();

  static TriviaRushConfig? tryFromUri(Uri uri) {
    final rawAreas = uri.queryParameters['areas'];
    final seconds = int.tryParse(uri.queryParameters['segundos'] ?? '');
    final duration = seconds == null
        ? null
        : TriviaRushDuration.tryFromSeconds(seconds);
    if (rawAreas == null || duration == null) return null;
    try {
      final areas = rawAreas
          .split(',')
          .where((value) => value.isNotEmpty)
          .map(AcademicArea.fromBackend)
          .toSet()
          .toList(growable: false);
      if (areas.isEmpty) return null;
      return TriviaRushConfig(areas: areas, duration: duration);
    } on Object {
      return null;
    }
  }
}

enum TriviaRushBooster {
  extraTime('Más 10 segundos', 'Añade diez segundos a esta ronda.'),
  fiftyFifty(
    'Descartar dos',
    'Oculta dos opciones incorrectas de la pregunta.',
  ),
  comboShield('Proteger combo', 'El próximo error no rompe tu combo.'),
  skip('Saltar pregunta', 'Avanza sin sumar ni restar puntos.'),
  secondChance(
    'Segunda oportunidad',
    'Permite corregir un primer error sin romper el combo.',
  );

  const TriviaRushBooster(this.label, this.description);

  final String label;
  final String description;
}

class TriviaRushSession {
  const TriviaRushSession({required this.attemptId, required this.questions});

  final String attemptId;
  final List<PracticeQuestion> questions;
}

class TriviaRushAnswerEvaluation {
  const TriviaRushAnswerEvaluation({
    required this.questionId,
    required this.isCorrect,
    required this.correctAnswerId,
    required this.explanation,
  });

  final String questionId;
  final bool isCorrect;
  final String correctAnswerId;
  final String? explanation;
}

class TriviaRushBoosterActivation {
  const TriviaRushBoosterActivation({this.eliminatedAnswerIds = const {}});

  final Set<String> eliminatedAnswerIds;
}

class TriviaRushScore {
  const TriviaRushScore({
    this.points = 0,
    this.combo = 0,
    this.bestCombo = 0,
    this.correctAnswers = 0,
    this.incorrectAnswers = 0,
    this.skippedQuestions = 0,
  });

  final int points;
  final int combo;
  final int bestCombo;
  final int correctAnswers;
  final int incorrectAnswers;
  final int skippedQuestions;

  int get multiplier => multiplierFor(combo);

  static int multiplierFor(int combo) => switch (combo) {
    >= 10 => 4,
    >= 6 => 3,
    >= 3 => 2,
    _ => 1,
  };

  TriviaRushScore registerCorrect() {
    final nextCombo = combo + 1;
    return TriviaRushScore(
      points: points + (100 * multiplierFor(nextCombo)),
      combo: nextCombo,
      bestCombo: nextCombo > bestCombo ? nextCombo : bestCombo,
      correctAnswers: correctAnswers + 1,
      incorrectAnswers: incorrectAnswers,
      skippedQuestions: skippedQuestions,
    );
  }

  TriviaRushScore registerIncorrect({bool protectCombo = false}) =>
      TriviaRushScore(
        points: points,
        combo: protectCombo ? combo : 0,
        bestCombo: bestCombo,
        correctAnswers: correctAnswers,
        incorrectAnswers: incorrectAnswers + 1,
        skippedQuestions: skippedQuestions,
      );

  TriviaRushScore registerSkip() => TriviaRushScore(
    points: points,
    combo: combo,
    bestCombo: bestCombo,
    correctAnswers: correctAnswers,
    incorrectAnswers: incorrectAnswers,
    skippedQuestions: skippedQuestions + 1,
  );
}

class TriviaRushReviewEntry {
  const TriviaRushReviewEntry({
    required this.question,
    required this.selectedAnswerId,
    required this.evaluation,
  });

  final PracticeQuestion question;
  final String selectedAnswerId;
  final TriviaRushAnswerEvaluation evaluation;
}

class TriviaRushWeakness {
  const TriviaRushWeakness({
    required this.area,
    required this.theme,
    required this.subtopic,
    required this.subtopicId,
    required this.errors,
  });

  final AcademicArea area;
  final String theme;
  final String subtopic;
  final String? subtopicId;
  final int errors;

  String? get studyRoute {
    final id = subtopicId?.trim() ?? '';
    if (id.isEmpty) return null;
    return '/student/practice/subtopic/${area.slug}/${Uri.encodeComponent(id)}';
  }
}

List<TriviaRushWeakness> triviaRushWeaknesses(
  Iterable<TriviaRushReviewEntry> review,
) {
  final grouped = <String, TriviaRushWeakness>{};
  for (final entry in review.where((entry) => !entry.evaluation.isCorrect)) {
    final question = entry.question;
    final routeId = question.subtopicId ?? '';
    final key = '${question.area.name}|${question.themeName}|$routeId';
    final current = grouped[key];
    grouped[key] = TriviaRushWeakness(
      area: question.area,
      theme: question.themeName,
      subtopic: question.subtopicName,
      subtopicId: question.subtopicId,
      errors: (current?.errors ?? 0) + 1,
    );
  }
  final result = grouped.values.toList(growable: false)
    ..sort((a, b) => b.errors.compareTo(a.errors));
  return result;
}
