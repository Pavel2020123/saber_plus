import '../../academic/domain/academic_models.dart';

class ReferenceLibrary {
  const ReferenceLibrary({
    required this.version,
    required this.formulas,
    required this.glossary,
    required this.strategy,
  });

  final int version;
  final List<FormulaArea> formulas;
  final List<GlossaryTerm> glossary;
  final ExamStrategy strategy;

  int get formulaCount => formulas.fold(
    0,
    (total, area) =>
        total +
        area.sections.fold(0, (sum, section) => sum + section.items.length),
  );

  factory ReferenceLibrary.fromJson(Map<String, dynamic> json) {
    final version = json['version'] as int? ?? 0;
    if (version != 1) {
      throw FormatException('Versión de biblioteca no compatible: $version');
    }
    return ReferenceLibrary(
      version: version,
      formulas: (json['formulas'] as List<dynamic>? ?? const [])
          .map(
            (item) =>
                FormulaArea.fromJson(Map<String, dynamic>.from(item as Map)),
          )
          .toList(growable: false),
      glossary: (json['glossary'] as List<dynamic>? ?? const [])
          .map(
            (item) =>
                GlossaryTerm.fromJson(Map<String, dynamic>.from(item as Map)),
          )
          .toList(growable: false),
      strategy: ExamStrategy.fromJson(
        Map<String, dynamic>.from(json['strategy'] as Map? ?? const {}),
      ),
    );
  }
}

class FormulaArea {
  const FormulaArea({
    required this.area,
    required this.name,
    required this.tagline,
    required this.description,
    required this.sections,
  });

  final AcademicArea area;
  final String name;
  final String tagline;
  final String description;
  final List<FormulaSection> sections;

  factory FormulaArea.fromJson(Map<String, dynamic> json) => FormulaArea(
    area: AcademicArea.fromBackend(json['key'] as String),
    name: json['nombre'] as String? ?? '',
    tagline: json['etiqueta'] as String? ?? '',
    description: json['descripcion'] as String? ?? '',
    sections: (json['secciones'] as List<dynamic>? ?? const [])
        .map(
          (item) =>
              FormulaSection.fromJson(Map<String, dynamic>.from(item as Map)),
        )
        .toList(growable: false),
  );
}

class FormulaSection {
  const FormulaSection({
    required this.id,
    required this.title,
    required this.items,
  });

  final String id;
  final String title;
  final List<FormulaReference> items;

  factory FormulaSection.fromJson(Map<String, dynamic> json) => FormulaSection(
    id: json['id'] as String? ?? '',
    title: json['titulo'] as String? ?? '',
    items: (json['items'] as List<dynamic>? ?? const [])
        .map(
          (item) =>
              FormulaReference.fromJson(Map<String, dynamic>.from(item as Map)),
        )
        .toList(growable: false),
  );
}

class FormulaReference {
  const FormulaReference({
    required this.name,
    required this.expression,
    required this.use,
    this.variables,
    this.warning,
  });

  final String name;
  final String expression;
  final String use;
  final String? variables;
  final String? warning;

  factory FormulaReference.fromJson(Map<String, dynamic> json) =>
      FormulaReference(
        name: json['nombre'] as String? ?? '',
        expression: json['formula'] as String? ?? '',
        use: json['uso'] as String? ?? '',
        variables: _optionalText(json['variables']),
        warning: _optionalText(json['alerta']),
      );

  bool matches(String query) {
    final normalized = query.trim().toLowerCase();
    if (normalized.isEmpty) return true;
    return '$name $expression $use ${variables ?? ''} ${warning ?? ''}'
        .toLowerCase()
        .contains(normalized);
  }
}

class GlossaryTerm {
  const GlossaryTerm({
    required this.term,
    required this.definition,
    required this.example,
    required this.area,
    required this.related,
  });

  final String term;
  final String definition;
  final String example;
  final AcademicArea area;
  final List<String> related;

  factory GlossaryTerm.fromJson(Map<String, dynamic> json) => GlossaryTerm(
    term: json['termino'] as String? ?? '',
    definition: json['definicion'] as String? ?? '',
    example: json['ejemplo'] as String? ?? '',
    area: AcademicArea.fromBackend(json['area'] as String),
    related: (json['relacionados'] as List<dynamic>? ?? const [])
        .whereType<String>()
        .toList(growable: false),
  );

  bool matches(String query) {
    final normalized = query.trim().toLowerCase();
    if (normalized.isEmpty) return true;
    return '$term $definition $example ${related.join(' ')}'
        .toLowerCase()
        .contains(normalized);
  }
}

class ExamStrategy {
  const ExamStrategy({
    required this.phases,
    required this.areaTactics,
    required this.distractors,
    required this.checklist,
  });

  final List<StrategyPhase> phases;
  final List<AreaTactic> areaTactics;
  final List<ExamDistractor> distractors;
  final List<String> checklist;

  factory ExamStrategy.fromJson(Map<String, dynamic> json) => ExamStrategy(
    phases: (json['phases'] as List<dynamic>? ?? const [])
        .map(
          (item) =>
              StrategyPhase.fromJson(Map<String, dynamic>.from(item as Map)),
        )
        .toList(growable: false),
    areaTactics: (json['areaTactics'] as List<dynamic>? ?? const [])
        .map(
          (item) => AreaTactic.fromJson(Map<String, dynamic>.from(item as Map)),
        )
        .toList(growable: false),
    distractors: (json['distractors'] as List<dynamic>? ?? const [])
        .map(
          (item) =>
              ExamDistractor.fromJson(Map<String, dynamic>.from(item as Map)),
        )
        .toList(growable: false),
    checklist: (json['checklist'] as List<dynamic>? ?? const [])
        .whereType<String>()
        .toList(growable: false),
  );
}

class StrategyPhase {
  const StrategyPhase({
    required this.number,
    required this.title,
    required this.moment,
    required this.objective,
    required this.actions,
  });

  final int number;
  final String title;
  final String moment;
  final String objective;
  final List<String> actions;

  factory StrategyPhase.fromJson(Map<String, dynamic> json) => StrategyPhase(
    number: json['numero'] as int? ?? 0,
    title: json['titulo'] as String? ?? '',
    moment: json['momento'] as String? ?? '',
    objective: json['objetivo'] as String? ?? '',
    actions: (json['acciones'] as List<dynamic>? ?? const [])
        .whereType<String>()
        .toList(growable: false),
  );
}

class AreaTactic {
  const AreaTactic({
    required this.area,
    required this.name,
    required this.focus,
    required this.steps,
    required this.controlQuestion,
  });

  final AcademicArea area;
  final String name;
  final String focus;
  final List<String> steps;
  final String controlQuestion;

  factory AreaTactic.fromJson(Map<String, dynamic> json) => AreaTactic(
    area: AcademicArea.fromBackend(json['key'] as String),
    name: json['nombre'] as String? ?? '',
    focus: json['enfoque'] as String? ?? '',
    steps: (json['pasos'] as List<dynamic>? ?? const [])
        .whereType<String>()
        .toList(growable: false),
    controlQuestion: json['preguntaControl'] as String? ?? '',
  );
}

class ExamDistractor {
  const ExamDistractor({
    required this.title,
    required this.signal,
    required this.response,
  });

  final String title;
  final String signal;
  final String response;

  factory ExamDistractor.fromJson(Map<String, dynamic> json) => ExamDistractor(
    title: json['titulo'] as String? ?? '',
    signal: json['senal'] as String? ?? '',
    response: json['respuesta'] as String? ?? '',
  );
}

class ExamTimePlan {
  const ExamTimePlan({
    required this.questionCount,
    required this.availableMinutes,
    required this.reviewMinutes,
    required this.workMinutes,
    required this.secondsPerQuestion,
    required this.checkpoints,
  });

  final int questionCount;
  final int availableMinutes;
  final int reviewMinutes;
  final int workMinutes;
  final int secondsPerQuestion;
  final List<TimeCheckpoint> checkpoints;

  factory ExamTimePlan.calculate({
    required int questionCount,
    required int availableMinutes,
    required int reviewMinutes,
  }) {
    final questions = questionCount.clamp(1, 500);
    final minutes = availableMinutes.clamp(10, 600);
    final review = reviewMinutes.clamp(0, minutes - 1);
    final work = (minutes - review).clamp(1, 600);
    return ExamTimePlan(
      questionCount: questions,
      availableMinutes: minutes,
      reviewMinutes: review,
      workMinutes: work,
      secondsPerQuestion: (work * 60 / questions).round(),
      checkpoints: [
        for (final percentage in const [25, 50, 75])
          TimeCheckpoint(
            percentage: percentage,
            question: (questions * percentage / 100).ceil(),
            minute: (work * percentage / 100).round(),
          ),
      ],
    );
  }
}

class TimeCheckpoint {
  const TimeCheckpoint({
    required this.percentage,
    required this.question,
    required this.minute,
  });

  final int percentage;
  final int question;
  final int minute;
}

String? _optionalText(Object? value) {
  if (value is! String || value.trim().isEmpty) return null;
  return value.trim();
}
