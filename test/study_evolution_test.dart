import 'dart:async';
import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:saber_plus/core/network/api_error.dart';
import 'package:saber_plus/features/auth/domain/session.dart';
import 'package:saber_plus/features/auth/presentation/session_controller.dart';
import 'package:saber_plus/features/institutions/data/teacher_student_evidence_repository.dart';
import 'package:saber_plus/features/institutions/presentation/teacher_student_evidence_page.dart';
import 'package:saber_plus/features/institutions/presentation/teacher_student_evidence_providers.dart';
import 'package:saber_plus/features/study_time/data/study_evolution_repository.dart';
import 'package:saber_plus/features/study_time/domain/study_evolution.dart';
import 'package:saber_plus/features/study_time/presentation/study_evolution_providers.dart';
import 'package:saber_plus/features/study_time/presentation/study_time_page.dart';

Map<String, dynamic> fixture([int days = 30]) => Map<String, dynamic>.from(
  jsonDecode(
        jsonEncode(
          demoStudyEvolutionJson(days, now: DateTime.utc(2026, 9, 14, 18)),
        ),
      )
      as Map,
);
Map<String, dynamic> teacherFixture([int days = 30]) => {
  'version': 1,
  'estudiante': {
    'id': 'student',
    'nombre': 'Ana',
    'grupos': [
      {'id': 'group', 'nombre': 'Once'},
    ],
  },
  'evolucion': fixture(days),
};

void main() {
  for (final days in [7, 30, 90]) {
    test(
      'contrato $days días conserva fuentes separadas, totales y fechas colombianas',
      () {
        final data = StudyEvolution.fromJson(fixture(days), days);
        expect(data.evolution, hasLength(days));
        expect(data.total.evaluationSeconds, 4800);
        expect(data.total.pomodoroSeconds, 3000);
        expect(data.evolution.last.date, '2026-09-14');
        expect(
          data.evolution
              .where((d) => d.state == 'SIN_REGISTROS')
              .every((d) => d.percentage == null),
          isTrue,
        );
      },
    );
  }
  test(
    'rechaza política que sume fuentes, cambie la zona o afirme dominio/XP',
    () {
      for (final changes in [
        {'fuentesNoSumables': false},
        {'zonaHoraria': 'UTC'},
        {'acreditaDominio': true},
        {'otorgaXp': true},
        {'version': 2},
      ]) {
        final json = fixture();
        (json['politica'] as Map).addAll(changes);
        expect(() => StudyEvolution.fromJson(json, 30), throwsFormatException);
      }
    },
  );
  test(
    'rechaza días duplicados, porcentajes inventados y totales diferentes al desglose',
    () {
      final alteredDay = fixture();
      ((alteredDay['evolucion'] as List)[0] as Map)['fecha'] = '2026-09-14';
      final alteredPercentage = fixture();
      ((alteredPercentage['evolucion'] as List)[0]
              as Map)['porcentajeAciertos'] =
          0;
      final alteredTotal = fixture();
      (alteredTotal['totales'] as Map)['segundosEvaluaciones'] = 4801;
      for (final json in [alteredDay, alteredPercentage, alteredTotal]) {
        expect(() => StudyEvolution.fromJson(json, 30), throwsFormatException);
      }
    },
  );
  test(
    'rechaza negativos, decimales en contadores, fechas sin zona y períodos equivocados',
    () {
      for (final value in [-1, 1.2, '2', null]) {
        final json = fixture();
        (json['totales'] as Map)['aciertos'] = value;
        expect(() => StudyEvolution.fromJson(json, 30), throwsFormatException);
      }
      expect(
        () => StudyEvolution.fromJson({
          ...fixture(),
          'desde': '2026-08-16T00:00:00',
        }, 30),
        throwsFormatException,
      );
      expect(
        () => StudyEvolution.fromJson(fixture(7), 30),
        throwsFormatException,
      );
    },
  );
  test(
    'muestra parcial no convierte días vacíos en ausencia de estudio o porcentajes',
    () {
      final json = partialFixture();
      final data = StudyEvolution.fromJson(json, 30);
      expect(data.partial, isTrue);
      expect(
        data.evolution.every(
          (d) => d.state == 'MUESTRA_PARCIAL' && d.percentage == null,
        ),
        isTrue,
      );
      ((json['evolucion'] as List)[0] as Map)['estado'] = 'SIN_REGISTROS';
      expect(() => StudyEvolution.fromJson(json, 30), throwsFormatException);
    },
  );
  test('ficha docente valida ID y no acepta el resumen de otro estudiante', () {
    expect(
      StudyEvolution.fromJson(
        teacherFixture(),
        30,
        studentId: 'student',
      ).studentName,
      'Ana',
    );
    expect(
      () => StudyEvolution.fromJson(teacherFixture(), 30, studentId: 'other'),
      throwsFormatException,
    );
  });
  test(
    'repositorio remoto usa rutas protegidas y nunca sustituye un 403 con demo',
    () async {
      final requests = <RequestOptions>[];
      final dio = Dio()
        ..interceptors.add(
          InterceptorsWrapper(
            onRequest: (o, h) {
              requests.add(o);
              if (o.path == '/tiempo-estudio/me') {
                h.resolve(Response(requestOptions: o, data: fixture(7)));
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
      final repo = RemoteStudyEvolutionRepository(dio);
      expect((await repo.load(7)).isDemo, isFalse);
      await expectLater(
        repo.load(30, studentId: 'student'),
        throwsA(isA<ApiError>()),
      );
      expect(
        requests.last.path,
        '/instituciones/me/estudiantes/student/evolucion',
      );
      expect(requests.last.queryParameters, {'dias': 30});
    },
  );
  test(
    'alumno no consulta evolución docente y cambio de cuenta cancela lectura pendiente',
    () async {
      final repo = _PendingRepository();
      final container = ProviderContainer(
        overrides: [
          sessionControllerProvider.overrideWith(_StudentSession.new),
          studyEvolutionRepositoryProvider.overrideWithValue(repo),
        ],
      );
      addTearDown(container.dispose);
      await expectLater(
        container.read(
          studyEvolutionProvider((days: 30, studentId: 'other')).future,
        ),
        throwsA(isA<ApiError>()),
      );
      expect(repo.tokens, isEmpty);
      final subscription = container.listen(
        studyEvolutionProvider((days: 30, studentId: null)),
        (_, _) {},
      );
      addTearDown(subscription.close);
      await Future<void>.delayed(Duration.zero);
      expect(repo.tokens, hasLength(1));
      (container.read(sessionControllerProvider.notifier) as _StudentSession)
          .changeUser('B');
      await Future<void>.delayed(Duration.zero);
      expect(repo.tokens.first!.isCancelled, isTrue);
      for (final pending in repo.pending) {
        pending.complete(StudyEvolution.fromJson(fixture(), 30));
      }
    },
  );
  testWidgets('demo muestra fuentes separadas y permite cambiar la ventana', (
    tester,
  ) async {
    await pump(tester, _DemoStudentSession.new, DemoStudyEvolutionRepository());
    await tester.scrollUntilVisible(
      find.byKey(const Key('study-evaluation-total')),
      200,
    );
    expect(
      tester.widget<Text>(find.byKey(const Key('study-evaluation-total'))).data,
      '1 h 20 min',
    );
    expect(find.byKey(const Key('study-time-total')), findsNothing);
    await tester.scrollUntilVisible(
      find.byKey(const Key('study-pomodoro-total')),
      200,
    );
    expect(
      tester.widget<Text>(find.byKey(const Key('study-pomodoro-total'))).data,
      '50 min',
    );
    await tester.scrollUntilVisible(
      find.byKey(const Key('study-days-7')),
      -200,
    );
    await tester.tap(find.byKey(const Key('study-days-7')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('sync-pomodoros')), findsNothing);
    expect(
      tester.widget<ChoiceChip>(find.byKey(const Key('study-days-7'))).selected,
      isTrue,
    );
  });
  testWidgets('error docente no reutiliza el nombre o métricas anteriores', (
    tester,
  ) async {
    final repo = _Repository();
    await pump(tester, _TeacherSession.new, repo, studentId: 'student');
    expect(find.text('Ana'), findsOneWidget);
    repo.fail = true;
    await tester.tap(find.byTooltip('Actualizar informe'));
    await tester.pumpAndSettle();
    expect(find.text('Ana'), findsNothing);
    expect(find.byKey(const Key('study-evaluation-total')), findsNothing);
    expect(find.text('Acceso retirado'), findsOneWidget);
    repo.fail = false;
    await tester.scrollUntilVisible(find.text('Reintentar informe'), 180);
    await tester.tap(find.text('Reintentar informe'));
    await tester.pumpAndSettle();
    expect(find.text('Ana'), findsOneWidget);
  });
  testWidgets('320 px y texto 200% permite consultar detalle sin desbordar', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 780);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await pump(
      tester,
      _TeacherSession.new,
      _Repository(),
      studentId: 'student',
      scale: 2,
    );
    final day = find.byKey(const Key('study-day-2026-09-14'));
    await tester.scrollUntilVisible(day, 240);
    await Scrollable.ensureVisible(tester.element(day), alignment: 0.5);
    await tester.pumpAndSettle();
    await tester.tap(
      find.descendant(of: day, matching: find.text('14/09/2026')),
    );
    await tester.pumpAndSettle();
    for (var i = 0; i < 6; i++) {
      await tester.drag(
        find.byKey(const Key('study-time-list')),
        const Offset(0, -160),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    }
  });
  testWidgets('ficha P2 enlaza a la evolución del mismo alumno', (
    tester,
  ) async {
    final data = await DemoTeacherStudentEvidenceRepository().load(
      'demo-student-1',
    );
    final router = GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (_, _) =>
              const TeacherStudentEvidencePage(studentId: 'demo-student-1'),
        ),
        GoRoute(
          path: '/teacher/students/:id/evolution',
          builder: (_, state) =>
              Scaffold(body: Text('Evolución ${state.pathParameters['id']}')),
        ),
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          teacherStudentEvidenceProvider(
            'demo-student-1',
          ).overrideWith((ref) async => data),
        ],
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.byKey(const Key('open-student-evolution')),
      200,
    );
    await Scrollable.ensureVisible(
      tester.element(find.byKey(const Key('open-student-evolution'))),
      alignment: 0.5,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('open-student-evolution')));
    await tester.pumpAndSettle();
    expect(find.text('Evolución demo-student-1'), findsOneWidget);
  });
}

Map<String, dynamic> partialFixture() {
  final json = fixture();
  json['parcial'] = true;
  json['registrosEvaluacionLeidos'] = 10000;
  for (final raw in json['evolucion'] as List) {
    (raw as Map)['estado'] = 'MUESTRA_PARCIAL';
    raw['porcentajeAciertos'] = null;
  }
  return json;
}

Future<void> pump(
  WidgetTester tester,
  SessionController Function() controller,
  StudyEvolutionRepository repo, {
  String? studentId,
  double scale = 1,
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        sessionControllerProvider.overrideWith(controller),
        studyEvolutionRepositoryProvider.overrideWithValue(repo),
      ],
      child: MaterialApp(
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: TextScaler.linear(scale)),
          child: child!,
        ),
        home: StudyTimePage(studentId: studentId),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

class _StudentSession extends SessionController {
  @override
  SessionState build() => const SessionState.authenticated(
    UserSession(id: 'A', firstName: 'Ana', role: AppRole.student),
  );
  void changeUser(String id) => state = SessionState.authenticated(
    UserSession(id: id, firstName: 'Otra', role: AppRole.student),
  );
}

class _DemoStudentSession extends SessionController {
  @override
  SessionState build() => const SessionState.authenticated(
    UserSession(
      id: 'demo-student',
      firstName: 'Ana',
      role: AppRole.student,
      isDemo: true,
    ),
  );
}

class _TeacherSession extends SessionController {
  @override
  SessionState build() => const SessionState.authenticated(
    UserSession(id: 'teacher', firstName: 'Profe', role: AppRole.teacher),
  );
}

class _Repository implements StudyEvolutionRepository {
  bool fail = false;
  @override
  Future<StudyEvolution> load(
    int days, {
    String? studentId,
    CancelToken? cancelToken,
  }) async {
    if (fail) {
      throw const ApiError(code: 'forbidden', message: 'Acceso retirado');
    }
    return StudyEvolution.fromJson(
      studentId == null ? fixture(days) : teacherFixture(days),
      days,
      studentId: studentId,
    );
  }
}

class _PendingRepository implements StudyEvolutionRepository {
  final tokens = <CancelToken?>[];
  final pending = <Completer<StudyEvolution>>[];
  @override
  Future<StudyEvolution> load(
    int days, {
    String? studentId,
    CancelToken? cancelToken,
  }) {
    tokens.add(cancelToken);
    final completer = Completer<StudyEvolution>();
    pending.add(completer);
    return completer.future;
  }
}
