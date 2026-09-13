import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:saber_plus/features/institutions/data/demo_teacher_detailed_analytics_repository.dart';
import 'package:saber_plus/features/institutions/presentation/teacher_detailed_analytics_page.dart';
import 'package:saber_plus/features/institutions/presentation/teacher_detailed_analytics_providers.dart';
import 'package:saber_plus/core/network/api_error.dart';
import 'package:saber_plus/features/auth/domain/session.dart';
import 'package:saber_plus/features/auth/presentation/session_controller.dart';
import 'package:saber_plus/features/institutions/data/teacher_student_evidence_repository.dart';
import 'package:saber_plus/features/institutions/domain/teacher_student_evidence.dart';
import 'package:saber_plus/features/institutions/presentation/teacher_student_evidence_page.dart';
import 'package:saber_plus/features/institutions/presentation/teacher_student_evidence_providers.dart';
import 'package:saber_plus/features/learning_evidence/domain/learning_evidence.dart';
import 'learning_evidence_test.dart' show reportFixture;

Map<String, dynamic> _fixture() => {
  'version': 1,
  'estudiante': {
    'id': 'student',
    'nombre': 'Ana',
    'grupos': [
      {'id': 'group', 'nombre': 'Once'},
    ],
  },
  'evidencia': reportFixture(),
};

TeacherStudentEvidence _data() =>
    TeacherStudentEvidence.fromJson(_fixture(), 'student');

void main() {
  test('una sesión de estudiante no consulta fichas docentes', () async {
    var calls = 0;
    final container = ProviderContainer(
      overrides: [
        sessionControllerProvider.overrideWith(_StudentSession.new),
        teacherStudentEvidenceRepositoryProvider.overrideWithValue(
          _Repository((_, _) async {
            calls++;
            return _data();
          }),
        ),
      ],
    );
    addTearDown(container.dispose);
    await expectLater(
      container.read(teacherStudentEvidenceProvider('student').future),
      throwsA(isA<ApiError>()),
    );
    expect(calls, 0);
  });
  testWidgets(
    'desde la lista del profesor abre la ficha del estudiante elegido',
    (tester) async {
      final router = GoRouter(
        routes: [
          GoRoute(
            path: '/',
            builder: (_, _) => const TeacherDetailedAnalyticsPage(),
          ),
          GoRoute(
            path: '/teacher/students/:studentId/evidence',
            builder: (_, state) => Scaffold(
              body: Text('Ficha ${state.pathParameters['studentId']}'),
            ),
          ),
        ],
      );
      addTearDown(router.dispose);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            teacherDetailedAnalyticsRepositoryProvider.overrideWithValue(
              DemoTeacherDetailedAnalyticsRepository(),
            ),
          ],
          child: MaterialApp.router(routerConfig: router),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(Tab, 'Estudiantes'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Andrea Gómez'));
      await tester.pumpAndSettle();
      final button = find.byKey(
        const Key('open-student-evidence-demo-student-1'),
      );
      await tester.ensureVisible(button);
      await tester.tap(button);
      await tester.pumpAndSettle();
      expect(find.text('Ficha demo-student-1'), findsOneWidget);
    },
  );

  testWidgets('el filtro permite elegir un área y volver a todas', (
    tester,
  ) async {
    await _pump(tester, (ref) async => _data());
    final filter = find.byKey(
      const ValueKey('student-evidence-filter-student'),
    );
    await tester.ensureVisible(filter);
    await tester.tap(filter);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Inglés').last);
    await tester.pumpAndSettle();
    expect(
      find.byKey(const PageStorageKey('evidence-area-mathematics')),
      findsNothing,
    );
    expect(
      find.byKey(const PageStorageKey('evidence-area-english')),
      findsOneWidget,
    );
    await tester.tap(filter);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Todas las áreas').last);
    await tester.pumpAndSettle();
    expect(
      find.byKey(const PageStorageKey('evidence-area-mathematics')),
      findsOneWidget,
    );
  });
  test(
    'rechaza una ficha de otro estudiante y mantiene reglas de evidencia',
    () {
      expect(
        () => TeacherStudentEvidence.fromJson(_fixture(), 'other'),
        throwsFormatException,
      );
      expect(_data().evidence.topics.single.level, EvidenceLevel.insufficient);
      expect(
        _data().evidence.topics.single.subtopics.single.level,
        EvidenceLevel.needsReview,
      );
    },
  );

  test('lee fechas de evidencia y rechaza fechas fuera de ventana', () {
    final json = reportFixture();
    final topic = (json['temas'] as List).single as Map<String, dynamic>;
    topic['ultimaEvidencia'] = '2026-09-05T15:00:00Z';
    expect(
      LearningEvidence.fromJson(json).topics.single.lastEvidence,
      DateTime.utc(2026, 9, 5, 15),
    );
    topic['ultimaEvidencia'] = '2027-01-01T00:00:00Z';
    expect(() => LearningEvidence.fromJson(json), throwsFormatException);
  });

  test(
    'consulta la ruta individual con cancelación sin enviar actor por parámetros',
    () async {
      final dio = Dio();
      addTearDown(dio.close);
      final cancel = CancelToken();
      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            expect(
              options.path,
              '/instituciones/me/estudiantes/student/evidencia',
            );
            expect(options.queryParameters, isEmpty);
            expect(options.cancelToken, cancel);
            handler.resolve(
              Response(
                requestOptions: options,
                data: _fixture(),
                statusCode: 200,
              ),
            );
          },
        ),
      );
      final data = await RemoteTeacherStudentEvidenceRepository(
        dio,
      ).load('student', cancelToken: cancel);
      expect(data.name, 'Ana');
      expect(data.evidence.isDemo, isFalse);
    },
  );

  for (final status in [401, 403, 404, 500]) {
    test(
      'error HTTP $status no se reemplaza por demo ni datos vacíos',
      () async {
        final dio = Dio();
        addTearDown(dio.close);
        dio.interceptors.add(
          InterceptorsWrapper(
            onRequest: (options, handler) {
              handler.reject(
                DioException(
                  requestOptions: options,
                  type: DioExceptionType.badResponse,
                  response: Response(
                    requestOptions: options,
                    statusCode: status,
                  ),
                ),
              );
            },
          ),
        );
        await expectLater(
          RemoteTeacherStudentEvidenceRepository(dio).load('student'),
          throwsA(isA<ApiError>()),
        );
      },
    );
  }

  test(
    'cambio de sesión cancela la petición y descarta el resultado anterior',
    () async {
      final session = _Session();
      final requests = <Completer<TeacherStudentEvidence>>[];
      final cancels = <CancelToken?>[];
      final repository = _Repository((_, cancel) {
        cancels.add(cancel);
        final completer = Completer<TeacherStudentEvidence>();
        requests.add(completer);
        return completer.future;
      });
      final container = ProviderContainer(
        overrides: [
          sessionControllerProvider.overrideWith(() => session),
          teacherStudentEvidenceRepositoryProvider.overrideWithValue(
            repository,
          ),
        ],
      );
      addTearDown(container.dispose);
      final provider = teacherStudentEvidenceProvider('student');
      final subscription = container.listen(provider, (_, _) {});
      addTearDown(subscription.close);
      await Future<void>.delayed(Duration.zero);
      session.changeUser('teacher-two');
      await Future<void>.delayed(Duration.zero);
      expect(cancels.first!.isCancelled, isTrue);
      expect(requests.length, 2);
      requests.first.complete(_data());
      await Future<void>.delayed(Duration.zero);
      expect(container.read(provider).hasValue, isFalse);
      requests.last.completeError(
        const ApiError(code: 'forbidden', message: 'Sin acceso'),
      );
      await Future<void>.delayed(Duration.zero);
      expect(container.read(provider).hasError, isTrue);
    },
  );

  testWidgets(
    'abre área, tema y subtema con métricas y sin exponer preguntas',
    (tester) async {
      await _pump(tester, (ref) async => _data());
      expect(find.text('Ana'), findsOneWidget);
      final area = find.byKey(
        const PageStorageKey('evidence-area-mathematics'),
      );
      await tester.scrollUntilVisible(area, 200);
      await tester.tap(
        find.descendant(of: area, matching: find.text('Matemáticas')),
      );
      await tester.pumpAndSettle();
      final topic = find.text('Proporcionalidad');
      await tester.scrollUntilVisible(topic, 150);
      await tester.tap(topic);
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(find.text('Regla de tres'), 100);
      expect(find.text('Conviene reforzar'), findsOneWidget);
      expect(
        find.text('2 aciertos · 3 errores · 5 preguntas distintas'),
        findsNWidgets(2),
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('sin respuestas no inventa falencias y muestra las cinco áreas', (
    tester,
  ) async {
    final json = _fixture();
    (json['evidencia'] as Map)['temas'] = <Object>[];
    await _pump(
      tester,
      (ref) async => TeacherStudentEvidence.fromJson(json, 'student'),
    );
    expect(find.textContaining('Esto no significa'), findsOneWidget);
    expect(find.text('Conviene reforzar'), findsNothing);
    await tester.scrollUntilVisible(
      find.byKey(const PageStorageKey('evidence-area-english')),
      180,
    );
    expect(
      find.byKey(const PageStorageKey('evidence-area-english')),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('reintenta un fallo y no conserva datos al revocar el acceso', (
    tester,
  ) async {
    var calls = 0;
    await _pump(tester, (ref) async {
      calls++;
      if (calls == 2) return _data();
      throw const ApiError(code: 'forbidden', message: 'Acceso no disponible');
    });
    expect(find.text('Acceso no disponible'), findsOneWidget);
    await tester.tap(find.text('Reintentar'));
    await tester.pumpAndSettle();
    expect(find.text('Ana'), findsOneWidget);
    await tester.tap(find.byTooltip('Actualizar ficha'));
    await tester.pumpAndSettle();
    expect(find.text('Ana'), findsNothing);
    expect(find.text('Acceso no disponible'), findsOneWidget);
  });

  testWidgets('320 px y texto al 200% no desbordan la ficha', (tester) async {
    tester.view.physicalSize = const Size(320, 760);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await _pump(tester, (ref) async => _data(), scale: 2);
    final area = find.byKey(const PageStorageKey('evidence-area-mathematics'));
    final areaTitle = find.descendant(
      of: area,
      matching: find.text('Matemáticas'),
    );
    await tester.scrollUntilVisible(areaTitle, 200);
    await tester.ensureVisible(areaTitle);
    await tester.pumpAndSettle();
    await tester.tap(areaTitle);
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.text('Proporcionalidad'), 150);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Proporcionalidad'));
    await tester.pumpAndSettle();
    final list = find.byKey(const ValueKey('student-evidence-student'));
    for (var i = 0; i < 14; i++) {
      await tester.drag(list, const Offset(0, -240));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    }
  });
}

Future<void> _pump(
  WidgetTester tester,
  Future<TeacherStudentEvidence> Function(Ref) loader, {
  double scale = 1,
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        teacherStudentEvidenceProvider('student').overrideWith(loader),
      ],
      child: MaterialApp(
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: TextScaler.linear(scale)),
          child: child!,
        ),
        home: const TeacherStudentEvidencePage(studentId: 'student'),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

class _Session extends SessionController {
  @override
  SessionState build() => const SessionState.authenticated(
    UserSession(id: 'teacher', firstName: 'Profe', role: AppRole.teacher),
  );
  void changeUser(String id) => state = SessionState.authenticated(
    UserSession(id: id, firstName: 'Otro', role: AppRole.teacher),
  );
}

class _StudentSession extends SessionController {
  @override
  SessionState build() => const SessionState.authenticated(
    UserSession(id: 'student', firstName: 'Ana', role: AppRole.student),
  );
}

class _Repository implements TeacherStudentEvidenceRepository {
  _Repository(this.loader);
  final Future<TeacherStudentEvidence> Function(String, CancelToken?) loader;
  @override
  Future<TeacherStudentEvidence> load(
    String studentId, {
    CancelToken? cancelToken,
  }) => loader(studentId, cancelToken);
}
