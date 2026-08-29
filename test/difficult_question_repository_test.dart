import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:saber_plus/core/database/app_database.dart';
import 'package:saber_plus/features/academic/domain/academic_models.dart';
import 'package:saber_plus/features/difficult_questions/data/drift_difficult_question_repository.dart';
import 'package:saber_plus/features/difficult_questions/domain/difficult_question_models.dart';

void main() {
  test('guarda marcas separadas por estudiante y permite retirarlas', () async {
    final database = AppDatabase(NativeDatabase.memory());
    final repository = DriftDifficultQuestionRepository(database);
    addTearDown(database.close);
    final mark = DifficultQuestionMark(
      userId: 'student-1',
      questionId: 'question-1',
      area: AcademicArea.mathematics,
      subtopicId: 'subtopic-1',
      subtopicName: 'Regla de tres',
      themeName: 'Proporciones',
      difficulty: 'MEDIA',
      markedAt: DateTime.utc(2026, 8, 29),
    );

    expect(await repository.toggle(mark), isTrue);
    expect(await repository.watchAll('student-1').first, hasLength(1));
    expect(await repository.watchAll('student-2').first, isEmpty);
    expect(
      await repository.watchContains('student-1', 'question-1').first,
      isTrue,
    );

    final saved = (await repository.watchAll('student-1').first).single;
    expect(
      saved.practiceRoute,
      '/student/practice/subtopic/matematicas/subtopic-1',
    );
    expect(await repository.toggle(mark), isFalse);
    expect(await repository.watchAll('student-1').first, isEmpty);
  });

  test('la tabla no almacena el contenido protegido de la pregunta', () async {
    final database = AppDatabase(NativeDatabase.memory());
    addTearDown(database.close);

    final columns = await database
        .customSelect('PRAGMA table_info(difficult_question_entries)')
        .get();
    final names = columns.map((row) => row.read<String>('name')).toSet();

    expect(names, containsAll({'user_id', 'question_id', 'subtopic_name'}));
    for (final protectedField in {
      'statement',
      'options',
      'selected_answer',
      'correct_answer',
      'explanation',
    }) {
      expect(names, isNot(contains(protectedField)));
    }
  });
}
