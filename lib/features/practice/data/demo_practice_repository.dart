import '../../academic/domain/academic_models.dart';
import '../domain/practice_history_models.dart';
import '../domain/practice_models.dart';
import '../domain/practice_repository.dart';

class DemoPracticeRepository implements PracticeRepository {
  @override
  Future<PracticeSession> startSubtopicPractice({
    required AcademicArea area,
    required String subtopicId,
  }) async {
    return PracticeSession(
      attemptId: 'demo-${area.name}-${DateTime.now().microsecondsSinceEpoch}',
      area: area,
      subtopicId: subtopicId,
      questions: [
        _demoQuestion(
          area: area,
          subtopicId: subtopicId,
          id: 'demo-question-${area.name}-1',
          variant: 1,
        ),
        _demoQuestion(
          area: area,
          subtopicId: subtopicId,
          id: 'demo-question-${area.name}-2',
          variant: 2,
        ),
      ],
    );
  }

  @override
  Future<PracticeResult> gradePractice({
    required String attemptId,
    required AcademicArea area,
    required List<PracticeAnswer> answers,
  }) async {
    final content = _contentFor(area);
    final review = answers
        .map((answer) {
          final variant = answer.questionId.endsWith('-2') ? 2 : 1;
          final correctId = variant == 1 ? 'answer-a' : 'answer-e';
          final question = _demoQuestion(
            area: area,
            subtopicId: 'demo-${area.name}',
            id: answer.questionId,
            variant: variant,
          );
          return PracticeReviewQuestion(
            id: answer.questionId,
            statement: question.statement,
            isCorrect: answer.answerId == correctId,
            selectedAnswerId: answer.answerId,
            correctAnswerId: correctId,
            explanation: variant == 1
                ? content.explanation
                : 'Comprobar significa volver a usar los datos originales con el resultado obtenido.',
            options: question.options
                .map(
                  (option) => PracticeReviewOption(
                    id: option.id,
                    text: option.text,
                    isCorrect: option.id == correctId,
                  ),
                )
                .toList(growable: false),
          );
        })
        .toList(growable: false);
    final correct = review.where((question) => question.isCorrect).length;
    final percentage = answers.isEmpty ? 0.0 : correct * 100 / answers.length;
    return PracticeResult(
      summary: PracticeResultSummary(
        totalQuestions: answers.length,
        correctAnswers: correct,
        incorrectAnswers: answers.length - correct,
        percentage: percentage,
        earnedXp:
            correct * 10 +
            (percentage >= 80
                ? 50
                : percentage >= 60
                ? 25
                : 0),
      ),
      review: review,
    );
  }

  @override
  Future<PracticeSession> startRandomPractice(
    RandomPracticeConfig config,
  ) async {
    final questions = <PracticeQuestion>[];
    for (var index = 0; index < config.questionCount; index++) {
      final area = config.areas[index % config.areas.length];
      final round = index ~/ config.areas.length;
      final variant = round.isEven ? 1 : 2;
      questions.add(
        _demoQuestion(
          area: area,
          subtopicId: 'demo-random-${area.name}',
          id: 'demo-question-${area.name}-random-${index + 1}-$variant',
          variant: variant,
        ),
      );
    }
    return PracticeSession(
      attemptId: 'demo-random-${DateTime.now().microsecondsSinceEpoch}',
      area: config.areas.first,
      subtopicId: '',
      isRandom: true,
      selectedAreas: List.unmodifiable(config.areas),
      questions: List.unmodifiable(questions),
    );
  }

  @override
  Future<PracticeResult> gradeRandomPractice({
    required String attemptId,
    required List<PracticeAnswer> answers,
  }) async {
    final review = <PracticeReviewQuestion>[];
    for (final area in AcademicArea.values) {
      final areaAnswers = answers
          .where((answer) => answer.questionId.contains(area.name))
          .toList(growable: false);
      if (areaAnswers.isEmpty) continue;
      final areaResult = await gradePractice(
        attemptId: attemptId,
        area: area,
        answers: areaAnswers,
      );
      review.addAll(areaResult.review);
    }
    final correct = review.where((question) => question.isCorrect).length;
    final percentage = answers.isEmpty ? 0.0 : correct * 100 / answers.length;
    return PracticeResult(
      summary: PracticeResultSummary(
        totalQuestions: answers.length,
        correctAnswers: correct,
        incorrectAnswers: answers.length - correct,
        percentage: percentage,
        earnedXp:
            correct * 10 +
            (percentage >= 80
                ? 50
                : percentage >= 60
                ? 25
                : 0),
      ),
      review: review,
    );
  }

  @override
  Future<PracticeSession> startAreaSimulation(AcademicArea area) async {
    final source = await startSubtopicPractice(
      area: area,
      subtopicId: 'demo-simulation-${area.name}',
    );
    return PracticeSession(
      attemptId: 'demo-simulation-${DateTime.now().microsecondsSinceEpoch}',
      area: area,
      subtopicId: '',
      isSimulation: true,
      questions: source.questions,
    );
  }

  @override
  Future<PracticeResult> gradeAreaSimulation({
    required String attemptId,
    required AcademicArea area,
    required List<PracticeAnswer> answers,
  }) => gradePractice(attemptId: attemptId, area: area, answers: answers);

  @override
  Future<SimulationHistory> loadSimulationHistory() async => SimulationHistory(
    total: 5,
    results: [
      SimulationHistoryResult(
        id: 'demo-result-1',
        area: AcademicArea.mathematics,
        totalQuestions: 25,
        correctAnswers: 18,
        percentage: 72,
        earnedXp: 205,
        completedAt: DateTime.now().subtract(const Duration(days: 1)),
      ),
      SimulationHistoryResult(
        id: 'demo-result-2',
        area: AcademicArea.criticalReading,
        totalQuestions: 25,
        correctAnswers: 21,
        percentage: 84,
        earnedXp: 260,
        completedAt: DateTime.now().subtract(const Duration(days: 4)),
      ),
      SimulationHistoryResult(
        id: 'demo-result-3',
        area: AcademicArea.naturalSciences,
        totalQuestions: 25,
        correctAnswers: 15,
        percentage: 60,
        earnedXp: 175,
        completedAt: DateTime.now().subtract(const Duration(days: 8)),
      ),
      SimulationHistoryResult(
        id: 'demo-result-4',
        area: AcademicArea.mathematics,
        totalQuestions: 25,
        correctAnswers: 14,
        percentage: 56,
        earnedXp: 140,
        completedAt: DateTime.now().subtract(const Duration(days: 12)),
      ),
      SimulationHistoryResult(
        id: 'demo-result-5',
        area: AcademicArea.criticalReading,
        totalQuestions: 25,
        correctAnswers: 17,
        percentage: 68,
        earnedXp: 170,
        completedAt: DateTime.now().subtract(const Duration(days: 18)),
      ),
    ],
  );

  @override
  Future<AnswerHistory> loadAnswerHistory(AnswerHistoryFilter filter) async {
    final items = <AnswerHistoryItem>[
      AnswerHistoryItem(
        id: 'demo-history-1',
        sessionId: 'demo-session-1',
        questionId: 'demo-question-mathematics-1',
        statement: 'Si 3 cuadernos cuestan 12.000 pesos, ¿cuánto cuestan 5?',
        explanation: 'Cada cuaderno cuesta 4.000 pesos; cinco cuestan 20.000.',
        difficulty: 'MEDIO',
        area: AcademicArea.mathematics,
        origin: PracticeOrigin.simulation,
        isCorrect: false,
        responseTimeSeconds: 42,
        answeredAt: DateTime.now().subtract(const Duration(hours: 2)),
        selectedAnswer: const HistoryAnswer(
          id: 'answer-b',
          text: '15.000 pesos',
        ),
        correctAnswer: const HistoryAnswer(
          id: 'answer-a',
          text: '20.000 pesos',
        ),
        theme: 'Razones y proporciones',
        subtopic: 'Regla de tres',
      ),
      AnswerHistoryItem(
        id: 'demo-history-2',
        sessionId: 'demo-session-2',
        questionId: 'demo-question-criticalReading-1',
        statement: '¿Cuál es la idea principal del texto?',
        explanation: 'Resume el propósito general del texto.',
        difficulty: 'MEDIO',
        area: AcademicArea.criticalReading,
        origin: PracticeOrigin.random,
        isCorrect: true,
        responseTimeSeconds: 28,
        answeredAt: DateTime.now().subtract(const Duration(days: 2)),
        selectedAnswer: const HistoryAnswer(
          id: 'answer-a',
          text: 'La opción que resume el texto',
        ),
        correctAnswer: const HistoryAnswer(
          id: 'answer-a',
          text: 'La opción que resume el texto',
        ),
        theme: 'Comprensión textual',
        subtopic: 'Idea principal',
      ),
    ];
    final filtered = items
        .where((item) {
          if (filter.area != null && item.area != filter.area) return false;
          return switch (filter.outcome) {
            AnswerOutcomeFilter.all => true,
            AnswerOutcomeFilter.correct => item.isCorrect,
            AnswerOutcomeFilter.incorrect => !item.isCorrect,
          };
        })
        .toList(growable: false);
    final correct = filtered.where((item) => item.isCorrect).length;
    return AnswerHistory(
      summary: AnswerHistorySummary(
        total: filtered.length,
        correct: correct,
        incorrect: filtered.length - correct,
        successPercentage: filtered.isEmpty
            ? 0
            : correct * 100 / filtered.length,
      ),
      answers: filtered,
    );
  }
}

PracticeQuestion _demoQuestion({
  required AcademicArea area,
  required String subtopicId,
  required String id,
  required int variant,
}) {
  final content = _contentFor(area);
  final isConceptQuestion = variant == 1;
  return PracticeQuestion(
    id: id,
    statement: isConceptQuestion
        ? content.statement
        : '¿Cuál es la mejor estrategia para comprobar la respuesta?',
    difficulty: 'MEDIA',
    options: isConceptQuestion
        ? [
            for (var index = 0; index < content.options.length; index++)
              PracticeOption(
                id: 'answer-${String.fromCharCode(97 + index)}',
                text: content.options[index],
              ),
          ]
        : const [
            PracticeOption(
              id: 'answer-e',
              text: 'Revisar los datos y sustituir el resultado',
            ),
            PracticeOption(id: 'answer-f', text: 'Elegir la opción más larga'),
            PracticeOption(id: 'answer-g', text: 'Ignorar las unidades'),
            PracticeOption(id: 'answer-h', text: 'Responder sin verificar'),
          ],
    subtopicId: subtopicId,
    subtopicName: content.subtopic,
    themeName: content.theme,
    area: area,
  );
}

typedef _DemoContent = ({
  String theme,
  String subtopic,
  String statement,
  List<String> options,
  String explanation,
});

_DemoContent _contentFor(AcademicArea area) => switch (area) {
  AcademicArea.mathematics => (
    theme: 'Razones y proporciones',
    subtopic: 'Regla de tres',
    statement:
        'Si 3 cuadernos cuestan 12.000 pesos, ¿cuánto cuestan 5 cuadernos?',
    options: const [
      '20.000 pesos',
      '15.000 pesos',
      '24.000 pesos',
      '18.000 pesos',
    ],
    explanation:
        'Cada cuaderno cuesta 4.000 pesos; cinco cuestan 20.000 pesos.',
  ),
  AcademicArea.criticalReading => (
    theme: 'Comprensión textual',
    subtopic: 'Idea principal',
    statement:
        'Un texto explica cómo ahorrar agua en casa. ¿Cuál es su idea principal?',
    options: const [
      'Presentar acciones para reducir el consumo de agua',
      'Describir todos los ríos del país',
      'Comparar el precio de varias viviendas',
      'Narrar un viaje familiar',
    ],
    explanation:
        'La idea principal reúne el propósito general y la información central del texto.',
  ),
  AcademicArea.naturalSciences => (
    theme: 'Entorno vivo',
    subtopic: 'Ecosistemas',
    statement: '¿Qué función cumplen las plantas en una cadena alimentaria?',
    options: const [
      'Producen materia orgánica usando la energía solar',
      'Consumen únicamente otros animales',
      'Eliminan toda la energía del ecosistema',
      'Descomponen exclusivamente materiales plásticos',
    ],
    explanation:
        'Las plantas son productores: transforman energía solar en materia orgánica.',
  ),
  AcademicArea.socialSciences => (
    theme: 'Pensamiento social',
    subtopic: 'Ciudadanía',
    statement: '¿Cuál acción fortalece la participación democrática?',
    options: const [
      'Informarse y participar responsablemente en decisiones colectivas',
      'Impedir que otras personas expresen sus ideas',
      'Ignorar las normas de convivencia',
      'Compartir información sin verificarla',
    ],
    explanation:
        'La participación democrática requiere información, diálogo y responsabilidad.',
  ),
  AcademicArea.english => (
    theme: 'Reading',
    subtopic: 'Main idea',
    statement:
        'A paragraph describes ways to study effectively. What is its main idea?',
    options: const [
      'Strategies for effective studying',
      'The history of a city',
      'Instructions for cooking',
      'A description of the weather',
    ],
    explanation:
        'The main idea summarizes the central topic developed throughout the paragraph.',
  ),
};
