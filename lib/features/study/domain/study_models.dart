import '../../academic/domain/academic_models.dart';

class StudyCatalog {
  const StudyCatalog({required this.area, required this.themes});

  final AcademicArea area;
  final List<StudyTheme> themes;

  int get totalSubtopics =>
      themes.fold<int>(0, (total, theme) => total + theme.subtopics.length);

  StudySubtopic? findSubtopic(String themeId, String subtopicId) {
    for (final theme in themes) {
      if (theme.id != themeId) continue;
      for (final subtopic in theme.subtopics) {
        if (subtopic.id == subtopicId) return subtopic;
      }
    }
    return null;
  }

  StudyTheme? findTheme(String themeId) {
    for (final theme in themes) {
      if (theme.id == themeId) return theme;
    }
    return null;
  }

  factory StudyCatalog.fromJson(Map<String, dynamic> json) => StudyCatalog(
    area: AcademicArea.fromBackend(json['area'] as String),
    themes:
        (json['temas'] as List<dynamic>?)
            ?.map(
              (item) =>
                  StudyTheme.fromJson(Map<String, dynamic>.from(item as Map)),
            )
            .toList(growable: false) ??
        const [],
  );

  factory StudyCatalog.demo(AcademicArea area) {
    final data = switch (area) {
      AcademicArea.criticalReading => ('Comprensión textual', 'Idea principal'),
      AcademicArea.mathematics => ('Razones y proporciones', 'Regla de tres'),
      AcademicArea.naturalSciences => ('Entorno vivo', 'Ecosistemas'),
      AcademicArea.socialSciences => (
        'Pensamiento social',
        'Constitución y ciudadanía',
      ),
      AcademicArea.english => ('Reading', 'Main idea'),
    };
    return StudyCatalog(
      area: area,
      themes: [
        StudyTheme(
          id: 'demo-${area.name}-theme',
          name: data.$1,
          subtopics: [
            StudySubtopic(
              id: 'demo-${area.name}-subtopic',
              name: data.$2,
              totalQuestions: 5,
              content:
                  '# ${data.$2}\n\nEsta es una lección demostrativa de **${area.label}**.\n\n- Revisa el concepto principal.\n- Observa el ejemplo.\n- Marca la lección cuando termines.',
            ),
          ],
        ),
      ],
    );
  }
}

class StudyTheme {
  const StudyTheme({
    required this.id,
    required this.name,
    required this.subtopics,
  });

  final String id;
  final String name;
  final List<StudySubtopic> subtopics;

  factory StudyTheme.fromJson(Map<String, dynamic> json) => StudyTheme(
    id: json['id'] as String,
    name: json['nombre'] as String,
    subtopics:
        (json['subtemas'] as List<dynamic>?)
            ?.map(
              (item) => StudySubtopic.fromJson(
                Map<String, dynamic>.from(item as Map),
              ),
            )
            .toList(growable: false) ??
        const [],
  );
}

class StudySubtopic {
  const StudySubtopic({
    required this.id,
    required this.name,
    required this.totalQuestions,
    this.content,
    this.videoUrl,
    this.imageUrl,
    this.clozeActivity,
  });

  final String id;
  final String name;
  final int totalQuestions;
  final String? content;
  final String? videoUrl;
  final String? imageUrl;
  final ClozeActivity? clozeActivity;

  bool get hasLearningResource =>
      (content?.trim().isNotEmpty ?? false) ||
      (videoUrl?.trim().isNotEmpty ?? false) ||
      (imageUrl?.trim().isNotEmpty ?? false) ||
      clozeActivity != null;

  factory StudySubtopic.fromJson(Map<String, dynamic> json) {
    final interactive = json['datosInteractivo'];
    return StudySubtopic(
      id: json['id'] as String,
      name: json['nombre'] as String,
      totalQuestions: json['totalPreguntas'] as int? ?? 0,
      content: _optionalText(json['contenido']),
      videoUrl: _optionalText(json['videoUrl']),
      imageUrl: _optionalText(json['imagenUrl']),
      clozeActivity: json['tipoInteractivo'] == 'CLOZE' && interactive is Map
          ? ClozeActivity.tryFromJson(Map<String, dynamic>.from(interactive))
          : null,
    );
  }
}

class ClozeActivity {
  const ClozeActivity({required this.textWithBlanks, required this.blanks});

  final String textWithBlanks;
  final List<ClozeBlank> blanks;

  static ClozeActivity? tryFromJson(Map<String, dynamic> json) {
    final text = json['textoConEspacios'];
    final rawBlanks = json['espacios'];
    if (text is! String || rawBlanks is! List) return null;
    final blanks = rawBlanks
        .whereType<Map>()
        .map((item) => ClozeBlank.tryFromJson(Map<String, dynamic>.from(item)))
        .whereType<ClozeBlank>()
        .toList(growable: false);
    if (blanks.isEmpty) return null;
    return ClozeActivity(textWithBlanks: text, blanks: blanks);
  }
}

class ClozeBlank {
  const ClozeBlank({required this.options, required this.correctIndex});

  final List<String> options;
  final int correctIndex;

  static ClozeBlank? tryFromJson(Map<String, dynamic> json) {
    final rawOptions = json['opciones'];
    final correctIndex = json['correctaIndex'];
    if (rawOptions is! List || correctIndex is! int) return null;
    final options = rawOptions.whereType<String>().toList(growable: false);
    if (options.isEmpty || correctIndex < 0 || correctIndex >= options.length) {
      return null;
    }
    return ClozeBlank(options: options, correctIndex: correctIndex);
  }
}

class StudyProgress {
  const StudyProgress({
    required this.totalSubtopics,
    required this.viewedSubtopics,
    required this.completedSubtopics,
    required this.overallPercentage,
    required this.bySubtopic,
  });

  final int totalSubtopics;
  final int viewedSubtopics;
  final int completedSubtopics;
  final int overallPercentage;
  final Map<String, int> bySubtopic;

  int percentageFor(String subtopicId) => bySubtopic[subtopicId] ?? 0;

  factory StudyProgress.fromJson(Map<String, dynamic> json) {
    final rawProgress = json['porSubtema'];
    return StudyProgress(
      totalSubtopics: json['totalSubtemas'] as int? ?? 0,
      viewedSubtopics: json['temasVistos'] as int? ?? 0,
      completedSubtopics: json['temasCompletados'] as int? ?? 0,
      overallPercentage: json['porcentajeGeneral'] as int? ?? 0,
      bySubtopic: rawProgress is Map
          ? rawProgress.map(
              (key, value) => MapEntry(
                key.toString(),
                value is num ? value.toInt().clamp(0, 100) : 0,
              ),
            )
          : const {},
    );
  }

  static const empty = StudyProgress(
    totalSubtopics: 0,
    viewedSubtopics: 0,
    completedSubtopics: 0,
    overallPercentage: 0,
    bySubtopic: {},
  );
}

class DownloadedThemePdf {
  const DownloadedThemePdf({required this.path, required this.fileName});

  final String path;
  final String fileName;
}

String? _optionalText(Object? value) {
  if (value is! String || value.trim().isEmpty) return null;
  return value.trim();
}
