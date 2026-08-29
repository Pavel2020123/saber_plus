import 'package:flutter_test/flutter_test.dart';
import 'package:saber_plus/features/academic/domain/academic_models.dart';
import 'package:saber_plus/features/search/domain/academic_search_models.dart';
import 'package:saber_plus/features/study/domain/study_models.dart';

void main() {
  final index = AcademicSearchIndex.fromCatalogs([
    const StudyCatalog(
      area: AcademicArea.mathematics,
      themes: [
        StudyTheme(
          id: 'theme-proportions',
          name: 'Razones y proporciones',
          subtopics: [
            StudySubtopic(
              id: 'subtopic-rule-three',
              name: 'Regla de tres',
              totalQuestions: 5,
              content:
                  '# Proporcionalidad\n\nAplica el porcentaje compuesto en problemas.',
            ),
          ],
        ),
      ],
    ),
  ]);

  test('encuentra lecciones y prácticas sin distinguir tildes', () {
    final byTitle = index.search('regla de tres');
    expect(byTitle, hasLength(2));
    expect(byTitle.first.type, AcademicSearchType.lesson);

    final byArea = index.search('matematicas');
    expect(byArea, hasLength(2));

    final byContent = index.search('porcentaje compuesto');
    expect(byContent, hasLength(2));
  });

  test('filtra el banco y genera una ruta de práctica protegida', () {
    final results = index.search(
      'proporciones',
      type: AcademicSearchType.questionPractice,
    );

    expect(results, hasLength(1));
    expect(results.single.questionCount, 5);
    expect(
      results.single.route,
      '/student/practice/subtopic/matematicas/subtopic-rule-three',
    );
    expect(index.search('r'), isEmpty);
  });
}
