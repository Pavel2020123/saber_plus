import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:saber_plus/core/database/app_database.dart';
import 'package:saber_plus/features/academic/domain/academic_models.dart';
import 'package:saber_plus/features/favorites/data/drift_favorite_repository.dart';
import 'package:saber_plus/features/favorites/domain/favorite_models.dart';

void main() {
  test(
    'guarda favoritos separados por estudiante y permite retirarlos',
    () async {
      final database = AppDatabase(NativeDatabase.memory());
      final repository = DriftFavoriteRepository(database);
      addTearDown(database.close);
      final favorite = AcademicFavorite(
        userId: 'student-1',
        kind: FavoriteKind.lesson,
        itemId: 'subtopic-1',
        area: AcademicArea.mathematics,
        parentId: 'theme-1',
        title: 'Regla de tres',
        parentTitle: 'Razones y proporciones',
        savedAt: DateTime.utc(2026, 8, 28),
      );

      expect(await repository.toggle(favorite), isTrue);
      expect(await repository.watchAll('student-1').first, hasLength(1));
      expect(await repository.watchAll('student-2').first, isEmpty);
      expect(
        await repository.watchContains('student-1', favorite.identity).first,
        isTrue,
      );

      expect(await repository.toggle(favorite), isFalse);
      expect(await repository.watchAll('student-1').first, isEmpty);
    },
  );

  test('conserva la ruta necesaria para volver a abrir la lección', () async {
    final database = AppDatabase(NativeDatabase.memory());
    final repository = DriftFavoriteRepository(database);
    addTearDown(database.close);
    final favorite = AcademicFavorite(
      userId: 'student-1',
      kind: FavoriteKind.lesson,
      itemId: 'subtopic-1',
      area: AcademicArea.english,
      parentId: 'theme-1',
      title: 'Main idea',
      parentTitle: 'Reading',
      savedAt: DateTime.utc(2026, 8, 28),
    );

    await repository.toggle(favorite);
    final saved = (await repository.watchAll('student-1').first).single;

    expect(saved.route, '/student/study/ingles/theme-1/subtopic-1');
    expect(saved.title, 'Main idea');
    expect(saved.parentTitle, 'Reading');
  });
}
