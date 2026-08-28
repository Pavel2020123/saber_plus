import 'package:flutter_test/flutter_test.dart';
import 'package:saber_plus/features/academic/domain/academic_models.dart';
import 'package:saber_plus/features/library/data/asset_reference_library_repository.dart';
import 'package:saber_plus/features/library/domain/reference_library_models.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('carga el catálogo académico incluido en la aplicación', () async {
    final library = await AssetReferenceLibraryRepository().load();

    expect(library.version, 1);
    expect(library.formulas, hasLength(5));
    expect(library.formulaCount, 80);
    expect(library.glossary, hasLength(50));
    expect(library.strategy.phases, hasLength(4));
    expect(library.strategy.areaTactics, hasLength(5));
    expect(library.strategy.checklist, hasLength(8));
    expect(
      library.formulas
          .firstWhere((area) => area.area == AcademicArea.mathematics)
          .name,
      'Matemáticas',
    );
  });

  test('mantiene una sola copia del catálogo después de cargarlo', () async {
    var loads = 0;
    final repository = AssetReferenceLibraryRepository(
      loader: () async {
        loads++;
        return '''
          {
            "version": 1,
            "formulas": [],
            "glossary": [],
            "strategy": {
              "phases": [],
              "areaTactics": [],
              "distractors": [],
              "checklist": []
            }
          }
        ''';
      },
    );

    final first = await repository.load();
    final second = await repository.load();

    expect(identical(first, second), isTrue);
    expect(loads, 1);
  });

  test('calcula tiempo útil, segundos y puntos de control', () {
    final plan = ExamTimePlan.calculate(
      questionCount: 100,
      availableMinutes: 240,
      reviewMinutes: 20,
    );

    expect(plan.workMinutes, 220);
    expect(plan.secondsPerQuestion, 132);
    expect(plan.checkpoints.first.question, 25);
    expect(plan.checkpoints.first.minute, 55);
    expect(plan.checkpoints.last.question, 75);
    expect(plan.checkpoints.last.minute, 165);
  });

  test('busca fórmulas y términos en todo su contenido', () async {
    final library = await AssetReferenceLibraryRepository().load();
    final formulas = library.formulas
        .expand((area) => area.sections)
        .expand((section) => section.items);

    expect(formulas.where((item) => item.matches('pitágoras')), hasLength(1));
    expect(
      library.glossary.where((term) => term.matches('temperatura corporal')),
      hasLength(1),
    );
  });
}
