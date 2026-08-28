import '../../academic/domain/academic_models.dart';
import '../domain/practice_models.dart';
import '../domain/practice_repository.dart';

class DemoPracticeRepository implements PracticeRepository {
  @override
  Future<PracticeSession> startSubtopicPractice({
    required AcademicArea area,
    required String subtopicId,
  }) async {
    final content = _contentFor(area);
    return PracticeSession(
      attemptId: 'demo-${area.name}-${DateTime.now().microsecondsSinceEpoch}',
      area: area,
      subtopicId: subtopicId,
      questions: [
        PracticeQuestion(
          id: 'demo-question-${area.name}-1',
          statement: content.statement,
          difficulty: 'MEDIA',
          options: [
            for (var index = 0; index < content.options.length; index++)
              PracticeOption(
                id: 'answer-${String.fromCharCode(97 + index)}',
                text: content.options[index],
              ),
          ],
          subtopicName: content.subtopic,
          themeName: content.theme,
          area: area,
        ),
        PracticeQuestion(
          id: 'demo-question-${area.name}-2',
          statement:
              '¿Cuál es la mejor estrategia para comprobar la respuesta?',
          difficulty: 'MEDIA',
          options: const [
            PracticeOption(
              id: 'answer-e',
              text: 'Revisar los datos y sustituir el resultado',
            ),
            PracticeOption(id: 'answer-f', text: 'Elegir la opción más larga'),
            PracticeOption(id: 'answer-g', text: 'Ignorar las unidades'),
            PracticeOption(id: 'answer-h', text: 'Responder sin verificar'),
          ],
          subtopicName: content.subtopic,
          themeName: content.theme,
          area: area,
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
    final correctByQuestion = {
      'demo-question-${area.name}-1': 'answer-a',
      'demo-question-${area.name}-2': 'answer-e',
    };
    final statements = {
      'demo-question-${area.name}-1': content.statement,
      'demo-question-${area.name}-2':
          '¿Cuál es la mejor estrategia para comprobar la respuesta?',
    };
    final allOptions = <String, List<PracticeReviewOption>>{
      'demo-question-${area.name}-1': [
        for (var index = 0; index < content.options.length; index++)
          PracticeReviewOption(
            id: 'answer-${String.fromCharCode(97 + index)}',
            text: content.options[index],
            isCorrect: index == 0,
          ),
      ],
      'demo-question-${area.name}-2': const [
        PracticeReviewOption(
          id: 'answer-e',
          text: 'Revisar los datos y sustituir el resultado',
          isCorrect: true,
        ),
        PracticeReviewOption(
          id: 'answer-f',
          text: 'Elegir la opción más larga',
          isCorrect: false,
        ),
        PracticeReviewOption(
          id: 'answer-g',
          text: 'Ignorar las unidades',
          isCorrect: false,
        ),
        PracticeReviewOption(
          id: 'answer-h',
          text: 'Responder sin verificar',
          isCorrect: false,
        ),
      ],
    };
    final review = answers
        .map((answer) {
          final correctId = correctByQuestion[answer.questionId]!;
          return PracticeReviewQuestion(
            id: answer.questionId,
            statement: statements[answer.questionId]!,
            isCorrect: answer.answerId == correctId,
            selectedAnswerId: answer.answerId,
            correctAnswerId: correctId,
            explanation: answer.questionId.endsWith('-1')
                ? content.explanation
                : 'Comprobar significa volver a usar los datos originales con el resultado obtenido.',
            options: allOptions[answer.questionId]!,
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
    for (final area in config.areas) {
      final session = await startSubtopicPractice(
        area: area,
        subtopicId: 'demo-random-${area.name}',
      );
      questions.addAll(session.questions);
    }
    return PracticeSession(
      attemptId: 'demo-random-${DateTime.now().microsecondsSinceEpoch}',
      area: config.areas.first,
      subtopicId: '',
      isRandom: true,
      selectedAreas: List.unmodifiable(config.areas),
      questions: questions.take(config.questionCount).toList(growable: false),
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
