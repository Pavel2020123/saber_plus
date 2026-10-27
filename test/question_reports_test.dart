import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:saber_plus/features/auth/domain/session.dart';
import 'package:saber_plus/features/auth/presentation/session_controller.dart';
import 'package:saber_plus/features/question_reports/data/remote_question_report_repository.dart';
import 'package:saber_plus/features/question_reports/domain/question_report.dart';
import 'package:saber_plus/features/question_reports/presentation/question_report_controller.dart';
import 'package:saber_plus/features/question_reports/presentation/question_report_page.dart';

const operation = '11111111-1111-4111-8111-111111111111';
const student = UserSession(
  id: 'student',
  firstName: 'Ana',
  role: AppRole.student,
);
Map<String, dynamic> jsonReport({
  bool duplicate = false,
  String status = 'PENDIENTE',
}) => {
  'id': '22222222-2222-4222-8222-222222222222',
  'preguntaId': 'q1',
  'motivo': 'ENUNCIADO_CONFUSO',
  'detalle': 'Texto original',
  'estado': status,
  'revision': status == 'PENDIENTE' ? 0 : 1,
  'fechaCreacion': '2026-10-17T12:00:00Z',
  'fechaActualizacion': '2026-10-17T12:00:00Z',
  'duplicado': duplicate,
};
QuestionReport report({bool duplicate = false}) =>
    QuestionReport.fromJson(jsonReport(duplicate: duplicate), receipt: true);

class ReportFake implements QuestionReportRepository {
  final sends = <QuestionReportAttempt>[];
  final reads = <String>[];
  Object? fail;
  bool duplicate = false;
  Completer<QuestionReport>? delayed;
  int ownCalls = 0;
  @override
  Future<QuestionReport> send(QuestionReportAttempt attempt) async {
    sends.add(attempt);
    if (delayed != null) return delayed!.future;
    if (fail != null) throw fail!;
    return report(duplicate: duplicate);
  }

  @override
  Future<QuestionReport> receipt(String operationId) async {
    reads.add(operationId);
    if (fail != null) throw fail!;
    return report(duplicate: duplicate);
  }

  @override
  Future<QuestionReportPage> own(int page) async {
    ownCalls++;
    if (fail != null) throw fail!;
    return QuestionReportPage(
      [QuestionReport.fromJson(jsonReport(status: 'RESUELTO'))],
      page,
      false,
    );
  }
}

class TestSession extends SessionController {
  TestSession(this.user);
  final UserSession user;
  @override
  SessionState build() => SessionState.authenticated(user);
  void change(UserSession? value) => state = value == null
      ? const SessionState.unauthenticated()
      : SessionState.authenticated(value);
}

void main() {
  testWidgets(
    'flecha y Atrás conservan motivo y borrador sin botón duplicado',
    (tester) async {
      final repo = ReportFake();
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sessionControllerProvider.overrideWith(() => TestSession(student)),
            questionReportRepositoryProvider.overrideWithValue(repo),
          ],
          child: const MaterialApp(
            home: Scaffold(body: QuestionReportButton(questionId: 'q1')),
          ),
        ),
      );
      await tester.tap(find.byKey(const Key('report-question-q1')));
      await tester.pumpAndSettle();
      expect(find.textContaining('Volver (conservar borrador'), findsNothing);
      expect(find.text('Volver a la revisión'), findsNothing);
      await tester.tap(find.byKey(const Key('report-reason')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Otro problema').last);
      await tester.pumpAndSettle();
      const detail = 'Borrador que se conserva con navegación normal';
      await tester.enterText(find.byType(TextFormField), detail);
      await tester.pageBack();
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('report-question-q1')));
      await tester.pumpAndSettle();
      expect(
        tester.widget<TextFormField>(find.byType(TextFormField)).initialValue,
        detail,
      );
      expect(find.text('Otro problema'), findsOneWidget);
      await tester.enterText(find.byType(TextFormField), '$detail actualizado');
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(find.byType(ReportQuestionPage), findsNothing);
      await tester.tap(find.byKey(const Key('report-question-q1')));
      await tester.pumpAndSettle();
      expect(
        tester.widget<TextFormField>(find.byType(TextFormField)).initialValue,
        '$detail actualizado',
      );
      expect(find.text('Otro problema'), findsOneWidget);
      expect(repo.sends, isEmpty);
      expect(repo.reads, isEmpty);
      expect(repo.ownCalls, 0);
    },
  );
  testWidgets('Más abre Mis reportes sin práctica y permite volver y reabrir', (
    tester,
  ) async {
    final repo = ReportFake();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sessionControllerProvider.overrideWith(() => TestSession(student)),
          questionReportRepositoryProvider.overrideWithValue(repo),
        ],
        child: const MaterialApp(
          home: Scaffold(body: MyQuestionReportsShortcut()),
        ),
      ),
    );
    expect(find.byKey(const Key('open-question-reports')), findsOneWidget);
    expect(repo.ownCalls, 0);
    await tester.tap(find.text('Mis reportes de preguntas'));
    await tester.pumpAndSettle();
    expect(find.byType(MyQuestionReportsPage), findsOneWidget);
    expect(find.textContaining('Resuelto'), findsOneWidget);
    expect(repo.ownCalls, 1);
    expect(repo.sends, isEmpty);
    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('open-question-reports')), findsOneWidget);
    await tester.tap(find.text('Mis reportes de preguntas'));
    await tester.pumpAndSettle();
    expect(repo.ownCalls, 2);
    expect(repo.sends, isEmpty);
  });
  testWidgets(
    'acceso permanente oculta demo, docentes, ADMIN y correos no verificados',
    (tester) async {
      final repo = ReportFake();
      for (final user in [
        const UserSession(
          id: 'demo',
          firstName: 'a',
          role: AppRole.student,
          isDemo: true,
        ),
        const UserSession(id: 'teacher', firstName: 'a', role: AppRole.teacher),
        const UserSession(id: 'admin', firstName: 'a', role: AppRole.admin),
        const UserSession(
          id: 'unverified',
          firstName: 'a',
          role: AppRole.student,
          emailVerified: false,
        ),
      ]) {
        await tester.pumpWidget(
          ProviderScope(
            key: ValueKey(user.id),
            overrides: [
              sessionControllerProvider.overrideWith(() => TestSession(user)),
              questionReportRepositoryProvider.overrideWithValue(repo),
            ],
            child: const MaterialApp(
              home: Scaffold(body: MyQuestionReportsShortcut()),
            ),
          ),
        );
        expect(find.byKey(const Key('open-question-reports')), findsNothing);
      }
      expect(repo.ownCalls, 0);
      expect(repo.sends, isEmpty);
    },
  );
  test(
    'un rechazo posterior a timeout NO libera un intento todavía incierto',
    () async {
      final repo = ReportFake()..fail = Exception('timeout');
      final c = QuestionReportController(
        repo,
        'q1',
        operationId: () => operation,
      );
      addTearDown(c.dispose);
      c.edit(detail: 'Texto original');
      await c.submit();
      repo.fail = const QuestionReportFailure('Límite', status: 429);
      await c.submit();
      expect(c.state.attempt!.operationId, operation);
      expect(c.state.locked, isTrue);
      c.anotherReason();
      expect(c.state.reason, QuestionReportReason.statement);
      repo.fail = null;
      await c.submit(consult: true);
      expect(c.state.receipt, isNotNull);
    },
  );
  test('otro motivo solo comienza después de un recibo confirmado', () async {
    final repo = ReportFake();
    final c = QuestionReportController(repo, 'q1');
    addTearDown(c.dispose);
    c.edit(detail: 'Texto original');
    await c.submit();
    c.anotherReason();
    expect(c.state.receipt, isNull);
    expect(c.state.attempt, isNull);
    expect(c.state.reason, QuestionReportReason.answer);
    expect(c.state.detail, isEmpty);
  });
  test(
    'errores HTTP conservan código sin filtrar detalles privados del servidor',
    () async {
      final dio = Dio();
      addTearDown(dio.close);
      var status = 403;
      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (o, h) => h.reject(
            DioException(
              requestOptions: o,
              response: Response(
                requestOptions: o,
                statusCode: status,
                data: {'message': 'SQL SECRET'},
              ),
            ),
          ),
        ),
      );
      for (status in [401, 403, 404, 409, 429, 503]) {
        await expectLater(
          RemoteQuestionReportRepository(dio).receipt(operation),
          throwsA(
            isA<QuestionReportFailure>()
                .having((e) => e.status, 'status', status)
                .having(
                  (e) => e.message.contains('SECRET'),
                  'privacy',
                  isFalse,
                ),
          ),
        );
      }
    },
  );
  testWidgets(
    'otro motivo reinicia el texto visible sin conservar el detalle anterior',
    (tester) async {
      tester.view.physicalSize = const Size(600, 1600);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final repo = ReportFake();
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sessionControllerProvider.overrideWith(() => TestSession(student)),
            questionReportRepositoryProvider.overrideWithValue(repo),
          ],
          child: const MaterialApp(
            home: ReportQuestionPage(questionId: 'q1', actorId: 'student'),
          ),
        ),
      );
      await tester.enterText(find.byType(TextFormField), 'Texto original');
      await tester.tap(find.text('Enviar reporte'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Reportar otro problema de esta pregunta'));
      await tester.pumpAndSettle();
      expect(
        tester.widget<TextFormField>(find.byType(TextFormField)).initialValue,
        isEmpty,
      );
      expect(
        tester.widget<TextFormField>(find.byType(TextFormField)).enabled,
        isTrue,
      );
    },
  );
  testWidgets(
    'Mis reportes muestra un error recuperable sin fingir lista vacía',
    (tester) async {
      final repo = ReportFake()..fail = Exception('offline');
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sessionControllerProvider.overrideWith(() => TestSession(student)),
            questionReportRepositoryProvider.overrideWithValue(repo),
          ],
          child: const MaterialApp(
            home: MyQuestionReportsPage(actorId: 'student'),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(
        find.textContaining('No pudimos consultar tus reportes'),
        findsOneWidget,
      );
      expect(find.text('No hay reportes en esta página.'), findsNothing);
      repo.fail = null;
      await tester.tap(find.text('Actualizar estado'));
      await tester.pumpAndSettle();
      expect(find.textContaining('Resuelto'), findsOneWidget);
    },
  );
  test('solo estudiantes reales verificados y sin cambio obligatorio', () {
    expect(canReportQuestions(student), isTrue);
    for (final user in [
      null,
      const UserSession(id: 'a', firstName: 'a', role: AppRole.admin),
      const UserSession(id: 't', firstName: 't', role: AppRole.teacher),
      const UserSession(
        id: 'd',
        firstName: 'd',
        role: AppRole.student,
        isDemo: true,
      ),
      const UserSession(
        id: 'u',
        firstName: 'u',
        role: AppRole.student,
        emailVerified: false,
      ),
      const UserSession(
        id: 'p',
        firstName: 'p',
        role: AppRole.student,
        mustChangePassword: true,
      ),
      const UserSession(
        id: 'v',
        firstName: 'v',
        role: AppRole.student,
        requiresEmailVerification: true,
      ),
    ]) {
      expect(canReportQuestions(user), isFalse);
    }
  });
  test('UUIDv4 aleatorio y detalle Unicode compatible con backend', () {
    final ids = List.generate(100, (_) => newReportOperation());
    expect(ids.toSet(), hasLength(100));
    expect(ids.every(reportUuid), isTrue);
    expect(reportDetailError('😀' * 500, QuestionReportReason.image), isNull);
    expect(
      reportDetailError('😀' * 501, QuestionReportReason.image),
      isNotNull,
    );
    expect(
      reportDetailError('   corto   ', QuestionReportReason.other),
      isNotNull,
    );
    expect(
      reportDetailError('\u0000', QuestionReportReason.statement),
      isNotNull,
    );
    expect(
      reportDetailError('\uD800', QuestionReportReason.statement),
      isNotNull,
    );
    expect(
      reportDetailError('\n\tTexto\r', QuestionReportReason.statement),
      isNull,
    );
  });
  test(
    'rechaza recibos incompletos, estados desconocidos y fechas invertidas',
    () {
      for (final change in <Map<String, dynamic>>[
        {'id': 'bad'},
        {'revision': -1},
        {'revision': '0'},
        {'estado': 'APROBADA'},
        {'motivo': 'OTROS'},
        {'detalle': 123},
        {'duplicado': null},
        {'preguntaId': 'q 1'},
        {'fechaActualizacion': '2026-10-16T12:00:00Z'},
      ]) {
        expect(
          () => QuestionReport.fromJson({
            ...jsonReport(),
            ...change,
          }, receipt: true),
          throwsFormatException,
        );
      }
    },
  );
  test(
    'timeout conserva UUID/payload y bloquea edición, doble envío y cambio de motivo',
    () async {
      final repo = ReportFake()..delayed = Completer<QuestionReport>();
      final controller = QuestionReportController(
        repo,
        'q1',
        operationId: () => operation,
      );
      addTearDown(controller.dispose);
      controller.edit(detail: 'Texto original');
      final send = controller.submit();
      await controller.submit();
      controller.edit(detail: 'No reemplazar');
      expect(repo.sends, hasLength(1));
      repo.delayed!.completeError(Exception('timeout'));
      await send;
      expect(controller.state.attempt?.operationId, operation);
      controller.edit(reason: QuestionReportReason.other, detail: 'Cambiado');
      expect(controller.state.detail, 'Texto original');
      repo.delayed = null;
      await controller.submit();
      expect(repo.sends, hasLength(2));
      expect(identical(repo.sends.first, repo.sends.last), isTrue);
      expect(controller.state.receipt, isNotNull);
    },
  );
  test(
    '404 al consultar no prueba fallo del envío: conserva el mismo intento',
    () async {
      final repo = ReportFake()..fail = Exception('timeout');
      final c = QuestionReportController(
        repo,
        'q1',
        operationId: () => operation,
      );
      addTearDown(c.dispose);
      c.edit(detail: 'Texto original');
      await c.submit();
      repo.fail = const QuestionReportFailure('no recibo', status: 404);
      await c.submit(consult: true);
      expect(c.state.locked, isTrue);
      expect(c.state.message, contains('Todavía no hay recibo'));
      repo.fail = null;
      await c.submit(consult: true);
      expect(repo.reads, [operation, operation]);
      expect(repo.sends, hasLength(1));
    },
  );
  for (final status in [400, 404, 429]) {
    test('rechazo definitivo $status conserva texto editable', () async {
      final repo = ReportFake()
        ..fail = QuestionReportFailure('rechazado', status: status);
      final c = QuestionReportController(repo, 'q1');
      addTearDown(c.dispose);
      c.edit(detail: 'Texto original');
      await c.submit();
      expect(c.state.locked, isFalse);
      expect(c.state.detail, 'Texto original');
    });
  }
  test('409 y 503 no crean un UUID nuevo ni liberan el intento', () async {
    for (final status in [409, 503]) {
      final repo = ReportFake()
        ..fail = QuestionReportFailure('incierto', status: status);
      final c = QuestionReportController(repo, 'q1');
      await c.submit();
      final id = c.state.attempt!.operationId;
      await c.submit();
      expect(c.state.attempt!.operationId, id);
      expect(c.state.locked, isTrue);
      c.dispose();
    }
  });
  test(
    'duplicado semántico confirma sin reemplazar detalle ni permitir segundo envío',
    () async {
      final repo = ReportFake()..duplicate = true;
      final c = QuestionReportController(repo, 'q1');
      addTearDown(c.dispose);
      c.edit(detail: 'Nuevo texto');
      await c.submit();
      await c.submit();
      expect(c.state.receipt!.detail, 'Texto original');
      expect(repo.sends, hasLength(1));
      expect(c.state.message, contains('ya estaba reportado'));
    },
  );
  test(
    'cambio de cuenta destruye borrador e ignora respuesta tardía',
    () async {
      final repo = ReportFake()..delayed = Completer<QuestionReport>();
      final container = ProviderContainer(
        overrides: [
          sessionControllerProvider.overrideWith(() => TestSession(student)),
          questionReportRepositoryProvider.overrideWithValue(repo),
        ],
      );
      addTearDown(container.dispose);
      final subscription = container.listen(
        questionReportControllerProvider('q1'),
        (_, _) {},
      );
      addTearDown(subscription.close);
      final old = container.read(
        questionReportControllerProvider('q1').notifier,
      );
      old.edit(detail: 'Texto original');
      final request = old.submit();
      (container.read(sessionControllerProvider.notifier) as TestSession)
          .change(
            const UserSession(
              id: 'other',
              firstName: 'B',
              role: AppRole.student,
            ),
          );
      await container.pump();
      expect(
        container.read(questionReportControllerProvider('q1')).detail,
        isEmpty,
      );
      repo.delayed!.complete(report());
      await request;
      expect(
        container.read(questionReportControllerProvider('q1')).receipt,
        isNull,
      );
      expect(repo.sends, hasLength(1));
    },
  );
  test(
    'remote usa rutas privadas, valida recibo y admite detalle original de duplicado',
    () async {
      final dio = Dio();
      addTearDown(dio.close);
      final captures = <RequestOptions>[];
      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (o, h) {
            captures.add(o);
            h.resolve(
              Response(
                requestOptions: o,
                statusCode: 200,
                data: o.path.endsWith('/mios')
                    ? {
                        'items': [jsonReport()],
                        'pagina': 1,
                        'limite': 20,
                        'hayMas': false,
                      }
                    : jsonReport(duplicate: true),
              ),
            );
          },
        ),
      );
      final repo = RemoteQuestionReportRepository(dio);
      await repo.send(
        QuestionReportAttempt(
          operationId: operation,
          questionId: 'q1',
          reason: QuestionReportReason.statement,
          detail: 'Nuevo',
        ),
      );
      await repo.receipt(operation);
      await repo.own(1);
      expect(captures.map((o) => o.path), [
        '/preguntas/reportes',
        '/preguntas/reportes/operaciones/$operation',
        '/preguntas/reportes/mios',
      ]);
      expect(captures.first.data, {
        'operacionId': operation,
        'preguntaId': 'q1',
        'motivo': 'ENUNCIADO_CONFUSO',
        'detalle': 'Nuevo',
      });
      expect(captures.last.queryParameters, {'pagina': 1, 'limite': 20});
    },
  );
  test(
    'remote no trata una respuesta inválida o de otra pregunta como éxito',
    () async {
      final dio = Dio();
      addTearDown(dio.close);
      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (o, h) => h.resolve(
            Response(
              requestOptions: o,
              statusCode: 200,
              data: {...jsonReport(), 'preguntaId': 'wrong'},
            ),
          ),
        ),
      );
      await expectLater(
        RemoteQuestionReportRepository(dio).send(
          QuestionReportAttempt(
            operationId: operation,
            questionId: 'q1',
            reason: QuestionReportReason.statement,
            detail: 'Texto original',
          ),
        ),
        throwsA(isA<QuestionReportFailure>()),
      );
    },
  );
  test(
    'remote rechaza paginación, duplicados de lista y contratos incoherentes',
    () async {
      final dio = Dio();
      addTearDown(dio.close);
      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (o, h) => h.resolve(
            Response(
              requestOptions: o,
              statusCode: 200,
              data: {
                'items': [jsonReport(), jsonReport()],
                'pagina': 1,
                'limite': 20,
                'hayMas': false,
              },
            ),
          ),
        ),
      );
      final repo = RemoteQuestionReportRepository(dio);
      expect(() => repo.own(0), throwsFormatException);
      await expectLater(repo.own(1), throwsA(isA<QuestionReportFailure>()));
    },
  );
  testWidgets(
    'formulario muestra reintento, consulta recibo y Mis reportes con estado actual',
    (tester) async {
      tester.view.physicalSize = const Size(600, 1600);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final repo = ReportFake()..fail = Exception('timeout');
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sessionControllerProvider.overrideWith(() => TestSession(student)),
            questionReportRepositoryProvider.overrideWithValue(repo),
          ],
          child: const MaterialApp(
            home: ReportQuestionPage(questionId: 'q1', actorId: 'student'),
          ),
        ),
      );
      await tester.enterText(find.byType(TextFormField), 'Texto original');
      await tester.tap(find.text('Enviar reporte'));
      await tester.pumpAndSettle();
      expect(find.text('Reintentar mismo envío'), findsOneWidget);
      expect(
        tester.widget<TextFormField>(find.byType(TextFormField)).enabled,
        isFalse,
      );
      repo.fail = null;
      await tester.tap(find.text('Consultar recibo'));
      await tester.pumpAndSettle();
      expect(find.textContaining('Reporte recibido.'), findsOneWidget);
      await tester.tap(find.text('Mis reportes'));
      await tester.pumpAndSettle();
      expect(find.textContaining('Resuelto'), findsOneWidget);
      expect(repo.ownCalls, 1);
      expect(repo.sends, hasLength(1));
    },
  );
  testWidgets('sesión ajena no muestra borrador ni consulta API privada', (
    tester,
  ) async {
    final repo = ReportFake();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sessionControllerProvider.overrideWith(() => TestSession(student)),
          questionReportRepositoryProvider.overrideWithValue(repo),
        ],
        child: const MaterialApp(
          home: ReportQuestionPage(questionId: 'q1', actorId: 'other'),
        ),
      ),
    );
    expect(find.textContaining('La sesión cambió'), findsOneWidget);
    expect(find.byType(TextFormField), findsNothing);
    expect(repo.sends, isEmpty);
  });
  testWidgets('demo y profesores no ven el botón de reportar', (tester) async {
    for (final user in [
      const UserSession(
        id: 's',
        firstName: 'a',
        role: AppRole.student,
        isDemo: true,
      ),
      const UserSession(id: 't', firstName: 'a', role: AppRole.teacher),
    ]) {
      await tester.pumpWidget(
        ProviderScope(
          key: ValueKey(user.id),
          overrides: [
            sessionControllerProvider.overrideWith(() => TestSession(user)),
          ],
          child: const MaterialApp(
            home: Scaffold(body: QuestionReportButton(questionId: 'q1')),
          ),
        ),
      );
      expect(find.text('Reportar un problema'), findsNothing);
    }
  });
}
