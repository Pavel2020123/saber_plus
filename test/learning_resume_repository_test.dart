import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:saber_plus/core/database/app_database.dart';
import 'package:saber_plus/features/academic/domain/academic_models.dart';
import 'package:saber_plus/features/resume/data/drift_learning_resume_repository.dart';
import 'package:saber_plus/features/resume/domain/learning_resume_models.dart';

void main() {
  test('conserva una última lección independiente por estudiante', () async {
    final database = AppDatabase(NativeDatabase.memory());
    final repository = DriftLearningResumeRepository(database);
    addTearDown(database.close);

    await repository.save(
      LearningResume(
        userId: 'student-1',
        kind: LearningResumeKind.lesson,
        area: AcademicArea.mathematics,
        parentId: 'theme-1',
        itemId: 'subtopic-1',
        title: 'Regla de tres',
        parentTitle: 'Razones y proporciones',
        lastOpenedAt: DateTime.utc(2026, 8, 28, 10),
      ),
    );

    final first = await repository.watch('student-1').first;
    expect(first?.title, 'Regla de tres');
    expect(first?.route, '/student/study/matematicas/theme-1/subtopic-1');
    expect(await repository.watch('student-2').first, isNull);
  });

  test('reemplaza la ubicación anterior y permite limpiarla', () async {
    final database = AppDatabase(NativeDatabase.memory());
    final repository = DriftLearningResumeRepository(database);
    addTearDown(database.close);

    for (final item in const [('first', 'Primera'), ('second', 'Segunda')]) {
      await repository.save(
        LearningResume(
          userId: 'student-1',
          kind: LearningResumeKind.lesson,
          area: AcademicArea.english,
          parentId: 'theme-reading',
          itemId: item.$1,
          title: item.$2,
          parentTitle: 'Reading',
          lastOpenedAt: DateTime.utc(2026, 8, 28),
        ),
      );
    }

    expect((await repository.watch('student-1').first)?.title, 'Segunda');
    await repository.clear('student-1');
    expect(await repository.watch('student-1').first, isNull);
  });
}
