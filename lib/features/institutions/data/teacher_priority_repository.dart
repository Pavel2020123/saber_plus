import 'package:dio/dio.dart';
import '../../../core/network/api_error.dart';
import '../../academic/domain/academic_models.dart';
import '../../practice/data/remote_practice_repository.dart';
import '../../practice/domain/practice_models.dart';
import '../domain/teacher_priority.dart';

typedef PriorityPractice = ({PracticeSession session, DateTime expiresAt});

abstract interface class TeacherPriorityRepository {
  Future<PriorityBundle> load(PriorityQuery query, {CancelToken? cancelToken});
  Future<void> create(PriorityCreation request, {CancelToken? cancelToken});
  Future<void> withdraw(
    String groupId,
    String priorityId, {
    CancelToken? cancelToken,
  });
  Future<PriorityPractice> startPractice(
    String priorityId,
    AcademicArea area, {
    CancelToken? cancelToken,
  });
  Future<PracticeResult> gradePractice(
    String priorityId,
    PracticeSession session,
    List<PracticeAnswer> answers,
  );
}

class RemoteTeacherPriorityRepository implements TeacherPriorityRepository {
  const RemoteTeacherPriorityRepository(this.dio);
  final Dio dio;
  String _group(String id) =>
      '/instituciones/me/grupos/${Uri.encodeComponent(id)}/prioridades';
  Future<T> _safe<T>(Future<T> Function() operation) async {
    try {
      return await operation();
    } on DioException catch (error) {
      throw ApiError.fromDioException(error);
    } on FormatException {
      throw const ApiError(
        code: 'invalid_priority',
        message:
            'No pudimos validar las prioridades recibidas. Actualiza e inténtalo de nuevo.',
      );
    } on TypeError {
      throw const ApiError(
        code: 'invalid_priority',
        message: 'El servidor devolvió datos de prioridades incompatibles.',
      );
    }
  }

  @override
  Future<PriorityBundle> load(
    PriorityQuery query, {
    CancelToken? cancelToken,
  }) => _safe(() async {
    final path = switch (query.view) {
      PriorityView.student => '/prioridades-docentes/me',
      PriorityView.teacher => _group(query.groupId!),
      PriorityView.catalog => '${_group(query.groupId!)}/catalogo',
      PriorityView.report =>
        '${_group(query.groupId!)}/${Uri.encodeComponent(query.priorityId!)}/cumplimiento',
    };
    final response = await dio.get<Map<String, dynamic>>(
      path,
      queryParameters: {
        'pagina': query.page,
        if (query.area != null) 'area': query.area!.backendValue,
      },
      cancelToken: cancelToken,
    );
    return PriorityBundle.fromJson(priorityMap(response.data), query);
  });
  @override
  Future<void> create(PriorityCreation request, {CancelToken? cancelToken}) =>
      _safe(() async {
        final response = await dio.post<Map<String, dynamic>>(
          _group(request.groupId),
          data: request.toJson(),
          cancelToken: cancelToken,
        );
        final body = priorityMap(response.data);
        final priority = TeacherPriority.fromJson(
          priorityMap(body['prioridad']),
        );
        if (body['version'] != 1 ||
            body['reutilizada'] is! bool ||
            priority.id != request.id ||
            priority.groupId != request.groupId ||
            priority.topicId != request.topicId ||
            priority.subtopicId != request.subtopicId ||
            priority.dueAt != request.dueAt.toUtc()) {
          throw const FormatException('Creación inesperada');
        }
      });
  @override
  Future<void> withdraw(
    String groupId,
    String priorityId, {
    CancelToken? cancelToken,
  }) => _safe(() async {
    final response = await dio.post<Map<String, dynamic>>(
      '${_group(groupId)}/${Uri.encodeComponent(priorityId)}/retirar',
      cancelToken: cancelToken,
    );
    final body = priorityMap(response.data);
    final priority = TeacherPriority.fromJson(priorityMap(body['prioridad']));
    if (body['version'] != 1 ||
        priority.id != priorityId ||
        priority.groupId != groupId ||
        priority.withdrawnAt == null) {
      throw const FormatException('Retiro inesperado');
    }
  });
  @override
  Future<PriorityPractice> startPractice(
    String priorityId,
    AcademicArea area, {
    CancelToken? cancelToken,
  }) => _safe(() async {
    final response = await dio.post<Map<String, dynamic>>(
      '/prioridades-docentes/${Uri.encodeComponent(priorityId)}/practica',
      cancelToken: cancelToken,
    );
    final body = priorityMap(response.data);
    if (body['version'] != 1 ||
        body['prioridadId'] != priorityId ||
        body['area'] != area.backendValue) {
      throw const FormatException('Práctica inesperada');
    }
    final session = PracticeSession.fromJson(body, area: area, subtopicId: '');
    final expiresAt = priorityDate(body['expira']);
    if (session.attemptId.isEmpty ||
        session.questions.isEmpty ||
        session.questions.length > 5 ||
        !expiresAt.isAfter(DateTime.now()) ||
        session.questions.map((q) => q.id).toSet().length !=
            session.questions.length ||
        session.questions.any(
          (q) => q.area != area || q.options.isEmpty || q.subtopicId == null,
        )) {
      throw const FormatException('Preguntas inválidas');
    }
    return (session: session, expiresAt: expiresAt);
  });
  @override
  Future<PracticeResult> gradePractice(
    String priorityId,
    PracticeSession session,
    List<PracticeAnswer> answers,
  ) => RemotePracticeRepository(dio).gradePractice(
    attemptId: session.attemptId,
    area: session.area,
    answers: answers,
  );
}
