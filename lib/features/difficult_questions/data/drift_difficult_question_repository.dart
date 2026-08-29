import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/app_database.dart';
import '../../academic/domain/academic_models.dart';
import '../domain/difficult_question_models.dart';
import '../domain/difficult_question_repository.dart';

class DriftDifficultQuestionRepository implements DifficultQuestionRepository {
  DriftDifficultQuestionRepository(this._database);

  final AppDatabase _database;

  @override
  Stream<List<DifficultQuestionMark>> watchAll(String userId) => _database
      .watchDifficultQuestions(userId)
      .map((rows) => rows.map(_fromRow).toList(growable: false));

  @override
  Stream<bool> watchContains(String userId, String questionId) =>
      _database.watchDifficultQuestion(userId, questionId);

  @override
  Future<bool> toggle(DifficultQuestionMark mark) async {
    final existing = await _database.findDifficultQuestion(
      mark.userId,
      mark.questionId,
    );
    if (existing != null) {
      await remove(mark.userId, mark.questionId);
      return false;
    }
    await _database.saveDifficultQuestion(
      DifficultQuestionEntriesCompanion.insert(
        userId: mark.userId,
        questionId: mark.questionId,
        area: mark.area.backendValue,
        subtopicId: Value(mark.subtopicId),
        subtopicName: mark.subtopicName,
        themeName: mark.themeName,
        difficulty: mark.difficulty,
        markedAt: mark.markedAt,
      ),
    );
    return true;
  }

  @override
  Future<void> remove(String userId, String questionId) =>
      _database.removeDifficultQuestion(userId, questionId);

  DifficultQuestionMark _fromRow(DifficultQuestionEntry row) =>
      DifficultQuestionMark(
        userId: row.userId,
        questionId: row.questionId,
        area: AcademicArea.fromBackend(row.area),
        subtopicId: row.subtopicId,
        subtopicName: row.subtopicName,
        themeName: row.themeName,
        difficulty: row.difficulty,
        markedAt: row.markedAt,
      );
}

final difficultQuestionRepositoryProvider =
    Provider<DifficultQuestionRepository>(
      (ref) => DriftDifficultQuestionRepository(ref.watch(appDatabaseProvider)),
    );
