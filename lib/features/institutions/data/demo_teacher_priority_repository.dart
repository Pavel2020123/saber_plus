import 'package:dio/dio.dart';
import '../../academic/domain/academic_models.dart';
import '../../practice/data/demo_practice_repository.dart';
import '../../practice/domain/practice_models.dart';
import '../domain/teacher_priority.dart';
import 'teacher_priority_repository.dart';

class DemoTeacherPriorityRepository implements TeacherPriorityRepository {
  DemoTeacherPriorityRepository() {
    final now = DateTime.now().toUtc();
    _items['demo-priority'] = TeacherPriority(
      id: 'demo-priority',
      groupId: 'demo-group-1',
      area: AcademicArea.mathematics,
      topicId: 'demo-topic',
      topicName: 'Proporcionalidad',
      subtopicId: 'demo-subtopic',
      subtopicName: 'Regla de tres',
      createdAt: now,
      dueAt: now.add(const Duration(days: 7)),
      groupName: 'Once A',
    );
  }
  final _items = <String, TeacherPriority>{};
  final _requests = <String, Map<String, dynamic>>{};
  final _counts = <String, Set<String>>{};
  final _attempts = <String, String>{};
  final _practice = DemoPracticeRepository();
  static const entries = [
    PriorityCatalogEntry(
      id: 'demo-subtopic',
      name: 'Regla de tres',
      topicId: 'demo-topic',
      topicName: 'Proporcionalidad',
      area: AcademicArea.mathematics,
      count: 5,
    ),
  ];
  TeacherPriority _get(String id) =>
      _items[id] ?? (throw StateError('Prioridad de demo no disponible.'));
  PriorityProgress _progress(String id) =>
      PriorityProgress(count: _counts[id]?.length ?? 0, applies: true);
  @override
  Future<PriorityBundle> load(
    PriorityQuery query, {
    CancelToken? cancelToken,
  }) async {
    if (query.page != 1) return PriorityBundle(page: query.page);
    if (query.view == PriorityView.catalog) {
      return PriorityBundle(
        catalog: entries
            .where((e) => query.area == null || e.area == query.area)
            .toList(),
      );
    }
    if (query.view == PriorityView.report) {
      final p = _get(query.priorityId!);
      if (p.groupId != query.groupId) {
        throw StateError('Grupo de demo no disponible.');
      }
      return PriorityBundle(
        priority: p,
        students: [
          PriorityStudent(
            'demo-student',
            'Estudiante de ejemplo',
            _progress(p.id),
          ),
        ],
      );
    }
    return PriorityBundle(
      priorities: _items.values
          .where((p) => query.groupId == null || p.groupId == query.groupId)
          .map(
            (p) => TeacherPriority(
              id: p.id,
              groupId: p.groupId,
              area: p.area,
              topicId: p.topicId,
              topicName: p.topicName,
              subtopicId: p.subtopicId,
              subtopicName: p.subtopicName,
              createdAt: p.createdAt,
              dueAt: p.dueAt,
              withdrawnAt: p.withdrawnAt,
              groupName: 'Once A',
              progress: query.view == PriorityView.student
                  ? _progress(p.id)
                  : null,
            ),
          )
          .toList()
          .reversed
          .toList(),
    );
  }

  @override
  Future<void> create(
    PriorityCreation request, {
    CancelToken? cancelToken,
  }) async {
    if (_requests.containsKey(request.id)) {
      if (_requests[request.id].toString() != request.toJson().toString()) {
        throw StateError('Solicitud distinta con el mismo ID.');
      }
      return;
    }
    if (_items.values.any(
      (p) =>
          p.groupId == request.groupId &&
          p.active &&
          p.topicId == request.topicId &&
          p.subtopicId == request.subtopicId,
    )) {
      throw StateError('Ya existe una prioridad activa para esta selección.');
    }
    final entry = entries.firstWhere(
      (e) =>
          e.topicId == request.topicId &&
          (request.subtopicId == null || e.id == request.subtopicId),
    );
    final now = DateTime.now().toUtc();
    if (!request.dueAt.isAfter(now) ||
        request.dueAt.difference(now) > const Duration(days: 30)) {
      throw StateError('Elige un plazo futuro de hasta treinta días.');
    }
    if (_items.values
            .where((p) => p.groupId == request.groupId && p.active)
            .length >=
        10) {
      throw StateError('Ya hay diez prioridades activas.');
    }
    _items[request.id] = TeacherPriority(
      id: request.id,
      groupId: request.groupId,
      area: entry.area,
      topicId: entry.topicId,
      topicName: entry.topicName,
      subtopicId: request.subtopicId,
      subtopicName: request.subtopicId == null ? null : entry.name,
      createdAt: now,
      dueAt: request.dueAt,
    );
    _requests[request.id] = request.toJson();
  }

  @override
  Future<void> withdraw(
    String groupId,
    String priorityId, {
    CancelToken? cancelToken,
  }) async {
    final p = _get(priorityId);
    if (p.groupId != groupId) throw StateError('Grupo incorrecto.');
    _items[p.id] = TeacherPriority(
      id: p.id,
      groupId: p.groupId,
      area: p.area,
      topicId: p.topicId,
      topicName: p.topicName,
      subtopicId: p.subtopicId,
      subtopicName: p.subtopicName,
      createdAt: p.createdAt,
      dueAt: p.dueAt,
      withdrawnAt: p.withdrawnAt ?? DateTime.now().toUtc(),
    );
  }

  @override
  Future<PriorityPractice> startPractice(
    String priorityId,
    AcademicArea area, {
    CancelToken? cancelToken,
  }) async {
    final p = _get(priorityId);
    if (!p.active || p.area != area || _progress(p.id).complete) {
      throw StateError('Esta prioridad ya no necesita práctica.');
    }
    final source = await _practice.startRandomPractice(
      RandomPracticeConfig(areas: [area], questionCount: 5),
    );
    _attempts[source.attemptId] = priorityId;
    return (
      session: PracticeSession(
        attemptId: source.attemptId,
        area: area,
        subtopicId: 'priority:$priorityId',
        questions: source.questions
            .where((q) => !(_counts[priorityId]?.contains(q.id) ?? false))
            .toList(),
      ),
      expiresAt: DateTime.now().add(const Duration(minutes: 115)),
    );
  }

  @override
  Future<PracticeResult> gradePractice(
    String priorityId,
    PracticeSession session,
    List<PracticeAnswer> answers,
  ) async {
    if (_attempts.remove(session.attemptId) != priorityId) {
      throw StateError('Intento no disponible.');
    }
    final result = await _practice.gradePractice(
      attemptId: session.attemptId,
      area: session.area,
      answers: answers,
    );
    if (_get(priorityId).active) {
      (_counts[priorityId] ??= {}).addAll(answers.map((a) => a.questionId));
    }
    return result;
  }
}
