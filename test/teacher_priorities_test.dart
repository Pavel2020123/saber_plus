import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:saber_plus/core/network/api_error.dart';
import 'package:saber_plus/features/academic/domain/academic_models.dart';
import 'package:saber_plus/features/auth/domain/session.dart';
import 'package:saber_plus/features/auth/presentation/session_controller.dart';
import 'package:saber_plus/features/institutions/data/demo_teacher_priority_repository.dart';
import 'package:saber_plus/features/institutions/data/teacher_priority_repository.dart';
import 'package:saber_plus/features/institutions/domain/teacher_priority.dart';
import 'package:saber_plus/features/institutions/presentation/teacher_priorities_page.dart';
import 'package:saber_plus/features/institutions/presentation/teacher_priority_providers.dart';
import 'package:saber_plus/features/practice/domain/practice_models.dart';

const group = 'demo-group-1';
const teacherQuery = (
  view: PriorityView.teacher,
  groupId: group,
  priorityId: null,
  area: null,
  page: 1,
);
const studentQuery = (
  view: PriorityView.student,
  groupId: null,
  priorityId: null,
  area: null,
  page: 1,
);

Map<String, dynamic> priorityFixture({
  String id = 'priority',
  String groupId = group,
  bool student = false,
}) {
  final now = DateTime.now().toUtc();
  return {
    'id': id,
    'grupoId': groupId,
    'area': 'MATEMATICAS',
    'tema': {'id': 'topic', 'nombre': 'Proporciones'},
    'subtema': null,
    'metaPreguntas': 5,
    'creadoEn': now.subtract(const Duration(days: 1)).toIso8601String(),
    'venceEn': now.add(const Duration(days: 7)).toIso8601String(),
    'retiradoEn': null,
    'estado': 'ACTIVA',
    if (student) ...{
      'grupoNombre': 'Once',
      'contenidoPublicadoSuficiente': true,
      'aplica': true,
      'preguntasPracticadas': 2,
      'estadoCumplimiento': 'PENDIENTE',
      'cumplida': false,
      'acreditaDominio': false,
    },
  };
}

Map<String, dynamic> bundleFixture({bool student = false}) => {
  'version': 1,
  'pagina': 1,
  'hayMas': false,
  'politica': {'version': 1, 'metaPreguntas': 5, 'acreditaDominio': false},
  'prioridades': [priorityFixture(student: student)],
};

void main() {
  test(
    'creación remota normaliza milisegundos y valida la confirmación del servidor',
    () async {
      final precise = DateTime.now().toUtc().add(
        const Duration(days: 7, microseconds: 123),
      );
      final request = PriorityCreation(
        groupId: group,
        topicId: 'topic',
        dueAt: precise,
      );
      expect(request.dueAt.microsecond, 0);
      final sent = <Map<String, dynamic>>[];
      final dio = Dio()
        ..interceptors.add(
          InterceptorsWrapper(
            onRequest: (o, h) {
              sent.add(Map<String, dynamic>.from(o.data as Map));
              h.resolve(
                Response(
                  requestOptions: o,
                  data: {
                    'version': 1,
                    'reutilizada': false,
                    'prioridad': {
                      ...priorityFixture(id: request.id),
                      'venceEn': request.dueAt.toIso8601String(),
                    },
                  },
                ),
              );
            },
          ),
        );
      await RemoteTeacherPriorityRepository(dio).create(request);
      expect(sent.single, request.toJson());
    },
  );
  test('UUID v4 válido y solicitud conserva ID/cuerpo al reintentar', () {
    final request = PriorityCreation(
      groupId: group,
      topicId: 'topic',
      dueAt: DateTime.now().toUtc().add(const Duration(days: 7)),
    );
    expect(
      request.id,
      matches(
        RegExp(
          r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$',
        ),
      ),
    );
    expect(request.toJson(), request.toJson());
    expect(newPriorityRequestId(), isNot(request.id));
  });
  test('contrato rechaza progreso incoherente y no inventa dominio', () {
    final valid = priorityFixture(student: true);
    expect(TeacherPriority.fromJson(valid).progress!.label, 'Práctica · 2/5');
    for (final change in [
      {'preguntasPracticadas': 6},
      {'cumplida': true},
      {'acreditaDominio': true},
      {'aplica': false},
    ]) {
      expect(
        () => TeacherPriority.fromJson({...valid, ...change}),
        throwsFormatException,
      );
    }
  });
  test(
    'contrato rechaza otra institución/grupo, página o política inesperados',
    () {
      expect(
        () => PriorityBundle.fromJson({
          ...bundleFixture(),
          'prioridades': [priorityFixture(groupId: 'other')],
        }, teacherQuery),
        throwsFormatException,
      );
      expect(
        () => PriorityBundle.fromJson({
          ...bundleFixture(),
          'pagina': 2,
        }, teacherQuery),
        throwsFormatException,
      );
      expect(
        () => PriorityBundle.fromJson({
          ...bundleFixture(),
          'politica': {},
        }, teacherQuery),
        throwsFormatException,
      );
      expect(
        () => PriorityBundle.fromJson(bundleFixture(), studentQuery),
        throwsFormatException,
      );
    },
  );
  test('rechaza fecha sin zona, plazo invertido y retiro contradictorio', () {
    final p = priorityFixture();
    expect(
      () => TeacherPriority.fromJson({...p, 'venceEn': '2026-09-15'}),
      throwsFormatException,
    );
    expect(
      () => TeacherPriority.fromJson({...p, 'venceEn': p['creadoEn']}),
      throwsFormatException,
    );
    expect(
      () => TeacherPriority.fromJson({...p, 'estado': 'RETIRADA'}),
      throwsFormatException,
    );
  });
  test(
    'repositorio remoto usa rutas protegidas y valida respuestas; no usa demo ante 403',
    () async {
      final dio = Dio();
      final requests = <RequestOptions>[];
      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (o, h) {
            requests.add(o);
            if (requests.length == 1) {
              h.resolve(Response(requestOptions: o, data: bundleFixture()));
            } else {
              h.reject(
                DioException(
                  requestOptions: o,
                  response: Response(requestOptions: o, statusCode: 403),
                  type: DioExceptionType.badResponse,
                ),
              );
            }
          },
        ),
      );
      final repo = RemoteTeacherPriorityRepository(dio);
      expect((await repo.load(teacherQuery)).priorities.length, 1);
      expect(
        requests.first.path,
        '/instituciones/me/grupos/$group/prioridades',
      );
      expect(requests.first.queryParameters, {'pagina': 1});
      await expectLater(repo.load(teacherQuery), throwsA(isA<ApiError>()));
    },
  );
  test(
    'práctica remota rechaza una prioridad/área diferente antes de mostrar preguntas',
    () async {
      final dio = Dio()
        ..interceptors.add(
          InterceptorsWrapper(
            onRequest: (o, h) => h.resolve(
              Response(
                requestOptions: o,
                data: {
                  'version': 1,
                  'prioridadId': 'other',
                  'area': 'MATEMATICAS',
                },
              ),
            ),
          ),
        );
      await expectLater(
        RemoteTeacherPriorityRepository(
          dio,
        ).startPractice('priority', AcademicArea.mathematics),
        throwsA(isA<ApiError>()),
      );
    },
  );
  test('el alumno no consulta páginas del profesor', () async {
    final repo = _TrackingRepository();
    final container = ProviderContainer(
      overrides: [
        sessionControllerProvider.overrideWith(_StudentSession.new),
        teacherPriorityRepositoryProvider.overrideWithValue(repo),
      ],
    );
    addTearDown(container.dispose);
    await expectLater(
      container.read(teacherPriorityProvider(teacherQuery).future),
      throwsA(isA<ApiError>()),
    );
    expect(repo.loadCalls, 0);
  });
  test(
    'cambiar sesión cancela la consulta anterior y no reutiliza sus datos',
    () async {
      final repo = _PendingRepository();
      final container = ProviderContainer(
        overrides: [
          sessionControllerProvider.overrideWith(_TeacherSession.new),
          teacherPriorityRepositoryProvider.overrideWithValue(repo),
        ],
      );
      addTearDown(container.dispose);
      final subscription = container.listen(
        teacherPriorityProvider(teacherQuery),
        (_, _) {},
      );
      addTearDown(subscription.close);
      await Future<void>.delayed(Duration.zero);
      final first = repo.tokens.first;
      (container.read(sessionControllerProvider.notifier) as _TeacherSession)
          .changeUser();
      await Future<void>.delayed(Duration.zero);
      expect(first.isCancelled, true);
      expect(repo.tokens.length, 2);
      for (final completer in repo.completers) {
        completer.complete(const PriorityBundle());
      }
      await container.read(teacherPriorityProvider(teacherQuery).future);
    },
  );
  test(
    'demo permite crear, retirar idempotente y completar práctica sin guardar en remoto',
    () async {
      final repo = DemoTeacherPriorityRepository();
      final request = PriorityCreation(
        groupId: group,
        topicId: 'demo-topic',
        dueAt: DateTime.now().toUtc().add(const Duration(days: 7)),
      );
      await repo.create(request);
      await repo.create(request);
      expect((await repo.load(teacherQuery)).priorities.length, 2);
      await repo.withdraw(group, request.id);
      await repo.withdraw(group, request.id);
      final practice = await repo.startPractice(
        'demo-priority',
        AcademicArea.mathematics,
      );
      await repo.gradePractice(
        'demo-priority',
        practice.session,
        practice.session.questions
            .map(
              (q) => PracticeAnswer(
                questionId: q.id,
                answerId: q.options.first.id,
                responseTimeSeconds: 5,
              ),
            )
            .toList(),
      );
      final own = await repo.load(studentQuery);
      expect(
        own.priorities
            .singleWhere((p) => p.id == 'demo-priority')
            .progress!
            .complete,
        true,
      );
      await expectLater(
        repo.startPractice('demo-priority', AcademicArea.mathematics),
        throwsStateError,
      );
    },
  );

  testWidgets(
    'el listado docente abre seguimiento y pide confirmación para retirar',
    (tester) async {
      final repo = DemoTeacherPriorityRepository();
      final router = GoRouter(
        routes: [
          GoRoute(
            path: '/',
            builder: (_, _) => const TeacherPrioritiesPage(groupId: group),
          ),
          GoRoute(
            path: '/teacher/groups/:groupId/priorities/:priorityId/report',
            builder: (_, s) =>
                Text('Informe ${s.pathParameters['priorityId']}'),
          ),
        ],
      );
      addTearDown(router.dispose);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sessionControllerProvider.overrideWith(_TeacherSession.new),
            teacherPriorityRepositoryProvider.overrideWithValue(repo),
            priorityManagementEnabledProvider.overrideWithValue(true),
          ],
          child: MaterialApp.router(routerConfig: router),
        ),
      );
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(find.text('Retirar prioridad'), 200);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Retirar prioridad'));
      await tester.pumpAndSettle();
      expect(find.text('¿Retirar esta prioridad?'), findsOneWidget);
      await tester.tap(find.text('Cancelar'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Ver cumplimiento'));
      await tester.pumpAndSettle();
      expect(find.text('Informe demo-priority'), findsOneWidget);
    },
  );
  testWidgets(
    'creación con red incierta reintenta exactamente el mismo UUID y cuerpo',
    (tester) async {
      final repo = _UncertainRepository();
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sessionControllerProvider.overrideWith(_TeacherSession.new),
            teacherPriorityRepositoryProvider.overrideWithValue(repo),
          ],
          child: const MaterialApp(
            home: CreateTeacherPriorityPage(groupId: group),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('priority-catalog-demo-subtopic')));
      await tester.pumpAndSettle();
      final button = find.byKey(const Key('confirm-create-priority'));
      await tester.scrollUntilVisible(button, 200);
      await tester.pumpAndSettle();
      await tester.tap(button);
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(button, 150);
      await tester.pumpAndSettle();
      await tester.tap(button);
      await tester.pumpAndSettle();
      expect(repo.sent.length, 2);
      expect(repo.sent[0].id, repo.sent[1].id);
      expect(repo.sent[0].toJson(), repo.sent[1].toJson());
    },
  );
  testWidgets('alumno ve práctica y progreso sin botones de gestión', (
    tester,
  ) async {
    await _pump(tester, const TeacherPrioritiesPage(), student: true);
    expect(find.text('Asignar tema o subtema'), findsNothing);
    await tester.scrollUntilVisible(
      find.byKey(const Key('practice-priority-demo-priority')),
      200,
    );
    await tester.pumpAndSettle();
    expect(find.text('Práctica · 0/5'), findsOneWidget);
    expect(
      tester
          .widget<FilledButton>(
            find.byKey(const Key('practice-priority-demo-priority')),
          )
          .onPressed,
      isNotNull,
    );
  });
  testWidgets('pantallas estrechas con texto al 200% no desbordan', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 780);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await _pump(tester, const TeacherPrioritiesPage(), student: true, scale: 2);
    for (var i = 0; i < 8; i++) {
      await tester.drag(find.byType(ListView).first, const Offset(0, -230));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    }
  });
  testWidgets('error y reintento no se confunden con ausencia de prioridades', (
    tester,
  ) async {
    final repo = _TrackingRepository()..fail = true;
    await _pump(
      tester,
      const TeacherPrioritiesPage(groupId: group),
      repo: repo,
    );
    expect(find.text('Sin conexión de prueba'), findsOneWidget);
    expect(find.text('No hay prioridades en esta página.'), findsNothing);
    repo.fail = false;
    await tester.tap(find.text('Reintentar'));
    await tester.pumpAndSettle();
    expect(find.text('Regla de tres'), findsOneWidget);
  });
}

Future<void> _pump(
  WidgetTester tester,
  Widget page, {
  bool student = false,
  double scale = 1,
  TeacherPriorityRepository? repo,
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        sessionControllerProvider.overrideWith(
          student ? _StudentSession.new : _TeacherSession.new,
        ),
        teacherPriorityRepositoryProvider.overrideWithValue(
          repo ?? DemoTeacherPriorityRepository(),
        ),
        priorityManagementEnabledProvider.overrideWithValue(true),
      ],
      child: MaterialApp(
        builder: (c, child) => MediaQuery(
          data: MediaQuery.of(c).copyWith(textScaler: TextScaler.linear(scale)),
          child: child!,
        ),
        home: page,
      ),
    ),
  );
  await tester.pumpAndSettle();
}

class _TeacherSession extends SessionController {
  @override
  SessionState build() => const SessionState.authenticated(
    UserSession(
      id: 'teacher',
      firstName: 'Profe',
      role: AppRole.teacher,
      isDemo: true,
    ),
  );
  void changeUser() => state = const SessionState.authenticated(
    UserSession(
      id: 'other',
      firstName: 'Otro',
      role: AppRole.teacher,
      isDemo: true,
    ),
  );
}

class _StudentSession extends SessionController {
  @override
  SessionState build() => const SessionState.authenticated(
    UserSession(
      id: 'student',
      firstName: 'Ana',
      role: AppRole.student,
      isDemo: true,
    ),
  );
}

class _TrackingRepository extends DemoTeacherPriorityRepository {
  int loadCalls = 0;
  bool fail = false;
  @override
  Future<PriorityBundle> load(PriorityQuery query, {CancelToken? cancelToken}) {
    loadCalls++;
    if (fail) {
      throw const ApiError(
        code: 'network_unavailable',
        message: 'Sin conexión de prueba',
      );
    }
    return super.load(query, cancelToken: cancelToken);
  }
}

class _UncertainRepository extends DemoTeacherPriorityRepository {
  final sent = <PriorityCreation>[];
  @override
  Future<void> create(
    PriorityCreation request, {
    CancelToken? cancelToken,
  }) async {
    sent.add(request);
    throw const ApiError(
      code: 'network_timeout',
      message: 'Tiempo agotado de prueba',
    );
  }
}

class _PendingRepository extends DemoTeacherPriorityRepository {
  final tokens = <CancelToken>[];
  final completers = <Completer<PriorityBundle>>[];
  @override
  Future<PriorityBundle> load(PriorityQuery query, {CancelToken? cancelToken}) {
    tokens.add(cancelToken!);
    final completer = Completer<PriorityBundle>();
    completers.add(completer);
    return completer.future;
  }
}
