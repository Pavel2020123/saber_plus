import '../../academic/domain/academic_models.dart';
import '../../study/domain/study_models.dart';

enum AcademicSearchType { lesson, questionPractice }

class AcademicSearchResult {
  const AcademicSearchResult({
    required this.type,
    required this.area,
    required this.themeId,
    required this.themeName,
    required this.subtopicId,
    required this.subtopicName,
    required this.questionCount,
    required this.searchableText,
    this.excerpt,
  });

  final AcademicSearchType type;
  final AcademicArea area;
  final String themeId;
  final String themeName;
  final String subtopicId;
  final String subtopicName;
  final int questionCount;
  final String searchableText;
  final String? excerpt;

  String get identity => '${type.name}-${area.slug}-$subtopicId';

  String get route => switch (type) {
    AcademicSearchType.lesson =>
      '/student/study/${area.slug}/${Uri.encodeComponent(themeId)}/${Uri.encodeComponent(subtopicId)}',
    AcademicSearchType.questionPractice =>
      '/student/practice/subtopic/${area.slug}/${Uri.encodeComponent(subtopicId)}',
  };
}

class AcademicSearchIndex {
  AcademicSearchIndex._(this._results);

  final List<AcademicSearchResult> _results;

  factory AcademicSearchIndex.fromCatalogs(Iterable<StudyCatalog> catalogs) {
    final results = <AcademicSearchResult>[];
    for (final catalog in catalogs) {
      for (final theme in catalog.themes) {
        for (final subtopic in theme.subtopics) {
          final content = subtopic.content?.trim();
          final searchableText = _normalize(
            '${catalog.area.label} ${theme.name} ${subtopic.name} '
            '${content ?? ''} ${subtopic.clozeActivity?.textWithBlanks ?? ''}',
          );
          if (subtopic.hasLearningResource) {
            results.add(
              AcademicSearchResult(
                type: AcademicSearchType.lesson,
                area: catalog.area,
                themeId: theme.id,
                themeName: theme.name,
                subtopicId: subtopic.id,
                subtopicName: subtopic.name,
                questionCount: subtopic.totalQuestions,
                searchableText: searchableText,
                excerpt: _excerpt(content),
              ),
            );
          }
          if (subtopic.totalQuestions > 0) {
            results.add(
              AcademicSearchResult(
                type: AcademicSearchType.questionPractice,
                area: catalog.area,
                themeId: theme.id,
                themeName: theme.name,
                subtopicId: subtopic.id,
                subtopicName: subtopic.name,
                questionCount: subtopic.totalQuestions,
                searchableText: searchableText,
              ),
            );
          }
        }
      }
    }
    return AcademicSearchIndex._(List.unmodifiable(results));
  }

  List<AcademicSearchResult> search(
    String query, {
    AcademicSearchType? type,
    int limit = 50,
  }) {
    final normalizedQuery = _normalize(query);
    if (normalizedQuery.length < 2 || limit <= 0) return const [];
    final tokens = normalizedQuery
        .split(' ')
        .where((token) => token.isNotEmpty);
    final matches = <({AcademicSearchResult result, int score})>[];
    for (final result in _results) {
      if (type != null && result.type != type) continue;
      if (!tokens.every(result.searchableText.contains)) continue;
      matches.add((result: result, score: _score(result, normalizedQuery)));
    }
    matches.sort((left, right) {
      final score = right.score.compareTo(left.score);
      if (score != 0) return score;
      final title = left.result.subtopicName.compareTo(
        right.result.subtopicName,
      );
      if (title != 0) return title;
      return left.result.type.index.compareTo(right.result.type.index);
    });
    return matches.take(limit).map((match) => match.result).toList();
  }

  static int _score(AcademicSearchResult result, String query) {
    final title = _normalize(result.subtopicName);
    final theme = _normalize(result.themeName);
    final area = _normalize(result.area.label);
    var score = 0;
    if (title == query) score += 100;
    if (title.startsWith(query)) score += 60;
    if (title.contains(query)) score += 30;
    if (theme.contains(query)) score += 20;
    if (area.contains(query)) score += 10;
    if (result.type == AcademicSearchType.lesson) score += 1;
    return score;
  }
}

String _normalize(String value) {
  const accents = {
    'á': 'a',
    'é': 'e',
    'í': 'i',
    'ó': 'o',
    'ú': 'u',
    'ü': 'u',
    'ñ': 'n',
  };
  var normalized = value.toLowerCase();
  accents.forEach((accent, plain) {
    normalized = normalized.replaceAll(accent, plain);
  });
  return normalized
      .replaceAll(RegExp(r'[#*_>`~\[\]()]'), ' ')
      .replaceAll(RegExp(r'[^a-z0-9]+'), ' ')
      .trim();
}

String? _excerpt(String? content) {
  if (content == null || content.isEmpty) return null;
  final plain = content
      .replaceAll(RegExp(r'[#*_>`~\[\]()]'), ' ')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();
  if (plain.isEmpty) return null;
  return plain.length <= 120 ? plain : '${plain.substring(0, 117)}...';
}
