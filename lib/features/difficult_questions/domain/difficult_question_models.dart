import '../../academic/domain/academic_models.dart';

class DifficultQuestionMark {
  const DifficultQuestionMark({
    required this.userId,
    required this.questionId,
    required this.area,
    required this.subtopicName,
    required this.themeName,
    required this.difficulty,
    required this.markedAt,
    this.subtopicId,
  });

  final String userId;
  final String questionId;
  final AcademicArea area;
  final String? subtopicId;
  final String subtopicName;
  final String themeName;
  final String difficulty;
  final DateTime markedAt;

  String get title => subtopicName.trim().isEmpty
      ? 'Pregunta de ${area.label}'
      : 'Pregunta de $subtopicName';

  String? get practiceRoute {
    final id = subtopicId?.trim();
    if (id == null || id.isEmpty) return null;
    return '/student/practice/subtopic/${area.slug}/$id';
  }
}
