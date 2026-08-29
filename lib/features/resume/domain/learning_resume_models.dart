import '../../academic/domain/academic_models.dart';

enum LearningResumeKind {
  lesson('STUDY_SUBTOPIC');

  const LearningResumeKind(this.storageValue);

  final String storageValue;

  factory LearningResumeKind.fromStorage(String value) =>
      LearningResumeKind.values.firstWhere(
        (kind) => kind.storageValue == value,
        orElse: () => throw FormatException(
          'Tipo de reanudación académica no reconocido: $value',
        ),
      );
}

class LearningResume {
  const LearningResume({
    required this.userId,
    required this.kind,
    required this.area,
    required this.parentId,
    required this.itemId,
    required this.title,
    required this.parentTitle,
    required this.lastOpenedAt,
  });

  final String userId;
  final LearningResumeKind kind;
  final AcademicArea area;
  final String parentId;
  final String itemId;
  final String title;
  final String parentTitle;
  final DateTime lastOpenedAt;

  String get route => switch (kind) {
    LearningResumeKind.lesson =>
      '/student/study/${area.slug}/${Uri.encodeComponent(parentId)}/${Uri.encodeComponent(itemId)}',
  };
}
