import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:saber_plus/core/network/api_error.dart';
import 'package:saber_plus/core/network/api_client.dart';
import 'package:saber_plus/features/auth/domain/session.dart';
import 'package:saber_plus/features/auth/presentation/session_controller.dart';
import 'package:saber_plus/features/institutions/data/student_institution_request_repository.dart';
import 'package:saber_plus/features/institutions/domain/institution_directory.dart';
import 'package:saber_plus/features/institutions/domain/student_institution_request.dart';
import 'package:saber_plus/features/institutions/domain/teacher_institution_models.dart';
import 'package:saber_plus/features/institutions/presentation/student_institution_requests_page.dart';
import 'package:saber_plus/features/institutions/presentation/student_institution_request_providers.dart';
import 'package:saber_plus/features/institutions/presentation/teacher_institution_providers.dart';

const requestId = '11111111-1111-4111-8111-111111111111';
const institutionId = '22222222-2222-4222-8222-222222222222';
const target = PublicInstitution(id: institutionId, name: 'Colegio Central');
Map<String, dynamic> jsonRow({
  String id = requestId,
  String state = 'PENDIENTE',
  int revision = 0,
  bool owner = false,
}) => {
  'id': id,
  'institucion': {'id': institutionId, 'nombre': 'Colegio Central'},
  'estado': state,
  'revision': revision,
  'mensaje': 'Hola',
  'fechaCreacion': '2026-10-15T12:00:00Z',
  'fechaActualizacion': '2026-10-15T12:00:00Z',
  if (owner) 'estudianteNombre': 'Estudiante de ensayo',
};
StudentInstitutionRequest row({
  String id = requestId,
  String state = 'PENDIENTE',
  int revision = 0,
  bool owner = false,
}) => StudentInstitutionRequest.fromJson(
  jsonRow(id: id, state: state, revision: revision, owner: owner),
);

class RequestFake implements StudentInstitutionRequestRepository {
  List<StudentInstitutionRequest> rows = [];
  final sends = <({String id, String institution, String message})>[];
  final pages = <int>[];
  final filters = <StudentRequestStatus>[];
  bool failRead = false,
      failWrite = false,
      saveBeforeFailure = false,
      hasMore = false;
  int cancels = 0, reviews = 0;
  Completer<StudentInstitutionRequestPage>? delayed;
  @override
  Future<StudentInstitutionRequestPage> own(int page) async {
    pages.add(page);
    if (failRead) throw Exception('offline');
    if (delayed != null) return delayed!.future;
    return StudentInstitutionRequestPage(
      items: rows,
      page: page,
      hasMore: hasMore,
    );
  }

  @override
  Future<StudentInstitutionRequestPage> inbox(
    int page,
    StudentRequestStatus status,
  ) {
    filters.add(status);
    return own(page);
  }

  @override
  Future<StudentInstitutionRequest> create({
    required String operationId,
    required String institutionId,
    required String message,
  }) async {
    sends.add((id: operationId, institution: institutionId, message: message));
    final saved = row(id: operationId);
    if (!failWrite || saveBeforeFailure) rows = [saved];
    if (failWrite) throw Exception('timeout');
    return saved;
  }

  @override
  Future<StudentInstitutionRequest> cancel(
    StudentInstitutionRequest request,
  ) async {
    cancels++;
    if (failWrite) throw Exception('timeout');
    final saved = row(state: 'CANCELADA', revision: 1);
    rows = [saved];
    return saved;
  }

  @override
  Future<StudentInstitutionRequest> review(
    StudentInstitutionRequest request, {
    required bool approve,
  }) async {
    reviews++;
    if (failWrite) {
      throw const ApiError(code: '400', message: 'No hay cupos disponibles.');
    }
    final saved = row(
      state: approve ? 'APROBADA' : 'RECHAZADA',
      revision: 1,
      owner: true,
    );
    rows = [];
    return saved;
  }
}

class TestRequestSession extends SessionController {
  TestRequestSession(this.initial);
  final UserSession initial;
  @override
  SessionState build() => SessionState.authenticated(initial);
  void change(UserSession user) => state = SessionState.authenticated(user);
}

const student = UserSession(
  id: 'student',
  firstName: 'Ana',
  role: AppRole.student,
);
const teacher = UserSession(
  id: 'teacher',
  firstName: 'Luz',
  role: AppRole.teacher,
);

class RequestTeacherContext extends TeacherInstitutionController {
  RequestTeacherContext(this.role);
  final String role;
  @override
  Future<TeacherInstitutionContext> build() async =>
      TeacherInstitutionContext.fromJson({
        'estado': 'VINCULADO',
        'institucion': {
          'id': institutionId,
          'nombre': 'Colegio',
          'codigoUnico': 'private',
          'estadoVerificacion': 'APROBADA',
        },
        'membresia': {'rol': role},
      });
}

Future<void> mount(
  WidgetTester tester,
  RequestFake repo, {
  bool owner = false,
  PublicInstitution? institution = target,
  String? linked,
}) async {
  tester.view.physicalSize = const Size(500, 1400);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    MaterialApp(
      home: StudentInstitutionRequestsBoard(
        repository: repo,
        target: institution,
        ownerInbox: owner,
        linkedInstitutionId: linked,
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> compose(WidgetTester tester) async {
  await tester.tap(find.text('Escribir solicitud'));
  await tester.pumpAndSettle();
  await tester.enterText(
    find.byKey(const Key('student-request-message')),
    'Soy estudiante',
  );
  await tester.pumpAndSettle();
}

Future<void> send(WidgetTester tester) async {
  final button = find.widgetWithText(FilledButton, 'Solicitar ingreso');
  await tester.ensureVisible(button);
  await tester.tap(button);
  await tester.pumpAndSettle();
  await tester.tap(find.text('Enviar solicitud'));
  await tester.pumpAndSettle();
}

void main() {
  test('UUID de operación es v4 aleatorio y único', () {
    final ids = List.generate(100, (_) => newStudentRequestId());
    expect(ids.toSet(), hasLength(100));
    expect(ids.every(isStudentRequestUuid), true);
  });
  test('interpreta los cuatro estados y conserva revisión/fechas', () {
    for (final state in StudentRequestStatus.values) {
      final r = StudentInstitutionRequest.fromJson(jsonRow(state: state.value));
      expect(r.status, state);
      expect(r.revision, 0);
      expect(r.updatedAt.isUtc, true);
    }
  });
  test('no convierte respuestas incompletas o estado desconocido en éxito', () {
    for (final extra in [
      {'estado': 'OTRO'},
      {'revision': '0'},
      {'revision': -1},
      {'id': 'bad'},
      {'institucion': {}},
      {'fechaCreacion': null},
      {'mensaje': 1},
    ]) {
      expect(
        () => StudentInstitutionRequest.fromJson({...jsonRow(), ...extra}),
        throwsFormatException,
      );
    }
  });
  test(
    'remoto usa UUID estable, cuerpo explícito y rutas de cada actor',
    () async {
      final calls = <RequestOptions>[];
      final dio = Dio()
        ..interceptors.add(
          InterceptorsWrapper(
            onRequest: (o, h) {
              calls.add(o);
              h.resolve(
                Response(
                  requestOptions: o,
                  data: o.method == 'GET'
                      ? {
                          'solicitudes': [
                            jsonRow(owner: o.path.endsWith('pendientes')),
                          ],
                          'pagina': 2,
                          'hayMas': false,
                        }
                      : jsonRow(),
                ),
              );
            },
          ),
        );
      final repo = RemoteStudentInstitutionRequestRepository(dio);
      await repo.create(
        operationId: requestId,
        institutionId: institutionId,
        message: ' Hola ',
      );
      expect(calls.last.data, {
        'id': requestId,
        'institucionId': institutionId,
        'mensaje': 'Hola',
      });
      await repo.own(2);
      expect(
        calls.last.path,
        '${RemoteStudentInstitutionRequestRepository.path}/me',
      );
      await repo.inbox(2, StudentRequestStatus.pending);
      expect(calls.last.queryParameters, {'pagina': 2, 'estado': 'PENDIENTE'});
    },
  );
  test(
    'remoto cancela y decide con revisión sin mandar identidad del actor',
    () async {
      final calls = <RequestOptions>[];
      final dio = Dio()
        ..interceptors.add(
          InterceptorsWrapper(
            onRequest: (o, h) {
              calls.add(o);
              h.resolve(
                Response(
                  requestOptions: o,
                  data: jsonRow(
                    revision: 1,
                    state: o.method == 'DELETE'
                        ? 'CANCELADA'
                        : (o.data['decision'] == 'APROBAR'
                              ? 'APROBADA'
                              : 'RECHAZADA'),
                  ),
                ),
              );
            },
          ),
        );
      final repo = RemoteStudentInstitutionRequestRepository(dio);
      await repo.cancel(row());
      expect(calls.last.method, 'DELETE');
      expect(calls.last.data, {'revision': 0});
      await repo.review(row(), approve: true);
      expect(calls.last.method, 'PATCH');
      expect(calls.last.data, {'revision': 0, 'decision': 'APROBAR'});
      await repo.review(row(), approve: false);
      expect(calls.last.data, {'revision': 0, 'decision': 'RECHAZAR'});
    },
  );
  test(
    'rechaza página incorrecta, duplicados y bandeja de otro estado',
    () async {
      final dio = Dio();
      Map<String, dynamic> response = {};
      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (o, h) =>
              h.resolve(Response(requestOptions: o, data: response)),
        ),
      );
      final repo = RemoteStudentInstitutionRequestRepository(dio);
      response = {'solicitudes': [], 'pagina': 2, 'hayMas': false};
      await expectLater(repo.own(1), throwsFormatException);
      response = {
        'solicitudes': [jsonRow(), jsonRow()],
        'pagina': 1,
        'hayMas': false,
      };
      await expectLater(repo.own(1), throwsFormatException);
      response = {
        'solicitudes': [jsonRow(state: 'APROBADA', owner: true)],
        'pagina': 1,
        'hayMas': false,
      };
      await expectLater(
        repo.inbox(1, StudentRequestStatus.pending),
        throwsFormatException,
      );
    },
  );
  test(
    'remoto no confirma mutación con UUID distinto o sin incremento',
    () async {
      final dio = Dio();
      var response = jsonRow(id: institutionId);
      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (o, h) =>
              h.resolve(Response(requestOptions: o, data: response)),
        ),
      );
      final repo = RemoteStudentInstitutionRequestRepository(dio);
      await expectLater(
        repo.create(
          operationId: requestId,
          institutionId: institutionId,
          message: '',
        ),
        throwsFormatException,
      );
      response = jsonRow(state: 'CANCELADA');
      await expectLater(repo.cancel(row()), throwsFormatException);
    },
  );
  test('validación local impide enviar datos inválidos', () async {
    final repo = RemoteStudentInstitutionRequestRepository(Dio());
    await expectLater(repo.own(0), throwsArgumentError);
    await expectLater(
      repo.create(
        operationId: 'bad',
        institutionId: institutionId,
        message: '',
      ),
      throwsArgumentError,
    );
    await expectLater(
      repo.create(
        operationId: requestId,
        institutionId: institutionId,
        message: 'a' * 501,
      ),
      throwsArgumentError,
    );
    await expectLater(repo.cancel(row(state: 'APROBADA')), throwsArgumentError);
  });
  test(
    'Dio conserva el error de conflicto sin respaldo demostrativo',
    () async {
      final dio = Dio()
        ..interceptors.add(
          InterceptorsWrapper(
            onRequest: (o, h) => h.reject(
              DioException(
                requestOptions: o,
                response: Response(
                  requestOptions: o,
                  statusCode: 409,
                  data: {'statusCode': 409, 'message': 'Consulta el estado'},
                ),
              ),
            ),
          ),
        );
      await expectLater(
        RemoteStudentInstitutionRequestRepository(dio).own(1),
        throwsA(isA<ApiError>().having((e) => e.code, 'code', '409')),
      );
    },
  );

  testWidgets('error inicial permite reintentar sin datos inventados', (
    tester,
  ) async {
    final repo = RequestFake()..failRead = true;
    await mount(tester, repo);
    expect(find.textContaining('No pudimos consultar'), findsOneWidget);
    expect(find.text('Escribir solicitud'), findsNothing);
    repo.failRead = false;
    await tester.tap(find.text('Consultar estado actual'));
    await tester.pumpAndSettle();
    expect(find.text('Escribir solicitud'), findsOneWidget);
  });
  testWidgets('enviar cierra formulario y muestra pendiente sin duplicación', (
    tester,
  ) async {
    final repo = RequestFake();
    await mount(tester, repo);
    await compose(tester);
    await send(tester);
    expect(repo.sends, hasLength(1));
    expect(find.byType(TextField), findsNothing);
    expect(find.text('Escribir solicitud'), findsNothing);
    expect(find.textContaining('No necesitas enviar otra'), findsOneWidget);
  });
  testWidgets('volver en confirmación no envía y conserva texto', (
    tester,
  ) async {
    final repo = RequestFake();
    await mount(tester, repo);
    await compose(tester);
    await tester.tap(find.text('Solicitar ingreso'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Volver'));
    await tester.pumpAndSettle();
    expect(repo.sends, isEmpty);
    expect(
      tester.widget<TextField>(find.byType(TextField)).controller!.text,
      'Soy estudiante',
    );
  });
  testWidgets(
    'envío incierto exige consulta y reintenta mismo UUID y mensaje',
    (tester) async {
      final repo = RequestFake()..failWrite = true;
      await mount(tester, repo);
      await compose(tester);
      await send(tester);
      expect(find.textContaining('No se pudo confirmar'), findsOneWidget);
      expect(
        tester
            .widget<FilledButton>(
              find.widgetWithText(FilledButton, 'Reintentar mismo envío'),
            )
            .onPressed,
        isNull,
      );
      await tester.tap(find.text('Consultar estado actual'));
      await tester.pumpAndSettle();
      repo.failWrite = false;
      await tester.tap(find.text('Reintentar mismo envío'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Enviar solicitud'));
      await tester.pumpAndSettle();
      expect(repo.sends, hasLength(2));
      expect(repo.sends[0], repo.sends[1]);
    },
  );
  testWidgets('consulta reconcilia envío guardado sin volver a hacer POST', (
    tester,
  ) async {
    final repo = RequestFake()
      ..failWrite = true
      ..saveBeforeFailure = true;
    await mount(tester, repo);
    await compose(tester);
    await send(tester);
    await tester.tap(find.text('Consultar estado actual'));
    await tester.pumpAndSettle();
    expect(repo.sends, hasLength(1));
    expect(find.byType(TextField), findsNothing);
    expect(find.textContaining('Estado confirmado: Pendiente'), findsOneWidget);
  });
  testWidgets(
    'pendiente ajena al destino impide segunda solicitud y permite cancelar',
    (tester) async {
      final repo = RequestFake()..rows = [row()];
      await mount(tester, repo);
      expect(find.text('Escribir solicitud'), findsNothing);
      await tester.tap(find.text('Cancelar solicitud'));
      await tester.pumpAndSettle();
      expect(repo.cancels, 0);
      await tester.tap(find.text('Confirmar'));
      await tester.pumpAndSettle();
      expect(repo.cancels, 1);
      expect(find.text('Cancelada'), findsOneWidget);
      expect(find.byType(TextField), findsNothing);
    },
  );
  testWidgets('propietario confirma aceptación y recarga la bandeja', (
    tester,
  ) async {
    final repo = RequestFake()..rows = [row(owner: true)];
    await mount(tester, repo, owner: true, institution: null);
    await tester.tap(find.text('Aceptar'));
    await tester.pumpAndSettle();
    expect(repo.reviews, 0);
    expect(
      find.textContaining('sin asignación automática de grupo'),
      findsOneWidget,
    );
    await tester.tap(find.text('Confirmar'));
    await tester.pumpAndSettle();
    expect(repo.reviews, 1);
    expect(find.text('Aceptar'), findsNothing);
    expect(find.text('Estado confirmado: Aceptada.'), findsOneWidget);
  });
  testWidgets(
    'cupo agotado bloquea decisiones hasta consultar sin anunciar éxito',
    (tester) async {
      final repo = RequestFake()
        ..rows = [row(owner: true)]
        ..failWrite = true;
      await mount(tester, repo, owner: true, institution: null);
      await tester.tap(find.text('Aceptar'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Confirmar'));
      await tester.pumpAndSettle();
      expect(find.textContaining('No hay cupos disponibles'), findsOneWidget);
      expect(
        tester
            .widget<FilledButton>(find.widgetWithText(FilledButton, 'Aceptar'))
            .onPressed,
        isNull,
      );
      await tester.tap(find.text('Consultar estado actual'));
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<FilledButton>(find.widgetWithText(FilledButton, 'Aceptar'))
            .onPressed,
        isNotNull,
      );
    },
  );
  testWidgets(
    'paginación y filtro de propietario reinician página sin formularios',
    (tester) async {
      final repo = RequestFake()..hasMore = true;
      await mount(tester, repo, owner: true, institution: null);
      await tester.tap(find.text('Siguiente'));
      await tester.pumpAndSettle();
      expect(repo.pages.last, 2);
      tester
          .widget<DropdownButtonFormField<StudentRequestStatus>>(
            find.byType(DropdownButtonFormField<StudentRequestStatus>),
          )
          .onChanged!(StudentRequestStatus.rejected);
      await tester.pumpAndSettle();
      expect(repo.pages.last, 1);
      expect(repo.filters.last, StudentRequestStatus.rejected);
      expect(find.byType(TextField), findsNothing);
    },
  );
  testWidgets('cuenta vinculada solo consulta historial', (tester) async {
    final repo = RequestFake();
    await mount(tester, repo, linked: institutionId);
    expect(find.text('Escribir solicitud'), findsNothing);
    expect(find.textContaining('Ya perteneces'), findsOneWidget);
  });
  testWidgets('borrador exige confirmar salida y seguir editando lo conserva', (
    tester,
  ) async {
    final repo = RequestFake();
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => StudentInstitutionRequestsBoard(
                    repository: repo,
                    target: target,
                  ),
                ),
              ),
              child: const Text('Abrir solicitudes'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Abrir solicitudes'));
    await tester.pumpAndSettle();
    await compose(tester);
    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.text('¿Salir de solicitudes?'), findsOneWidget);
    await tester.tap(find.text('Volver'));
    await tester.pumpAndSettle();
    expect(
      tester.widget<TextField>(find.byType(TextField)).controller!.text,
      'Soy estudiante',
    );
    await tester.pageBack();
    await tester.pumpAndSettle();
    await tester.tap(find.text('Salir'));
    await tester.pumpAndSettle();
    expect(find.text('Abrir solicitudes'), findsOneWidget);
    expect(repo.sends, isEmpty);
  });
  testWidgets('límite 500 impide escribir de más y se permite mensaje vacío', (
    tester,
  ) async {
    final repo = RequestFake();
    await mount(tester, repo);
    await compose(tester);
    await tester.enterText(find.byType(TextField), 'a' * 501);
    await tester.pump();
    expect(
      tester.widget<TextField>(find.byType(TextField)).controller!.text.length,
      500,
    );
    await tester.enterText(find.byType(TextField), '');
    await tester.pumpAndSettle();
    await send(tester);
    expect(repo.sends.single.message, '');
  });
  testWidgets(
    'rechazo también se confirma y no modifica solicitudes docentes',
    (tester) async {
      final repo = RequestFake()..rows = [row(owner: true)];
      await mount(tester, repo, owner: true, institution: null);
      await tester.tap(find.text('Rechazar'));
      await tester.pumpAndSettle();
      expect(repo.reviews, 0);
      await tester.tap(find.text('Confirmar'));
      await tester.pumpAndSettle();
      expect(repo.reviews, 1);
      expect(find.text('Estado confirmado: Rechazada.'), findsOneWidget);
    },
  );
  testWidgets('solicitud aceptada muestra respuesta sin ofrecer cancelación', (
    tester,
  ) async {
    final repo = RequestFake()..rows = [row(state: 'APROBADA', revision: 1)];
    await mount(tester, repo, institution: null, linked: institutionId);
    expect(find.textContaining('Tu ingreso fue aceptado'), findsOneWidget);
    expect(find.text('Cancelar solicitud'), findsNothing);
    expect(find.text('Aceptar'), findsNothing);
  });
  testWidgets('bandeja tolera ancho reducido y texto grande', (tester) async {
    final repo = RequestFake()..rows = [row(owner: true)];
    tester.view.physicalSize = const Size(320, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MaterialApp(
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: const TextScaler.linear(2)),
          child: child!,
        ),
        home: StudentInstitutionRequestsBoard(
          repository: repo,
          ownerInbox: true,
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    await tester.ensureVisible(find.text('Aceptar'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
  testWidgets('demo y rol lector no cargan la bandeja de estudiantes', (
    tester,
  ) async {
    final repo = RequestFake();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sessionControllerProvider.overrideWith(
            () => TestRequestSession(
              const UserSession(
                id: 'demo',
                firstName: 'Demo',
                role: AppRole.student,
                isDemo: true,
              ),
            ),
          ),
          studentInstitutionRequestRepositoryProvider.overrideWithValue(repo),
        ],
        child: const MaterialApp(home: StudentInstitutionRequestsPage()),
      ),
    );
    await tester.pumpAndSettle();
    expect(repo.pages, isEmpty);
    expect(find.textContaining('demostración'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
    await tester.pumpAndSettle();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sessionControllerProvider.overrideWith(
            () => TestRequestSession(teacher),
          ),
          studentInstitutionRequestRepositoryProvider.overrideWithValue(repo),
          teacherInstitutionControllerProvider.overrideWith(
            () => RequestTeacherContext('ADMINISTRADOR'),
          ),
        ],
        child: const MaterialApp(
          home: StudentInstitutionRequestsPage(ownerInbox: true),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(repo.pages, isEmpty);
    expect(find.text('Aceptar'), findsNothing);
  });
  testWidgets('cambiar cuenta destruye borrador y descarta respuesta tardía', (
    tester,
  ) async {
    final repo = RequestFake()
      ..delayed = Completer<StudentInstitutionRequestPage>();
    final container = ProviderContainer(
      overrides: [
        sessionControllerProvider.overrideWith(
          () => TestRequestSession(student),
        ),
        studentInstitutionRequestRepositoryProvider.overrideWithValue(repo),
      ],
    );
    addTearDown(container.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: StudentInstitutionRequestsPage()),
      ),
    );
    await tester.pump();
    await tester.pump();
    final old = repo.delayed!;
    repo.delayed = null;
    (container.read(sessionControllerProvider.notifier) as TestRequestSession)
        .change(
          const UserSession(
            id: 'new',
            firstName: 'Otra',
            role: AppRole.student,
          ),
        );
    await tester.pumpAndSettle();
    old.complete(
      StudentInstitutionRequestPage(items: [row()], page: 1, hasMore: false),
    );
    await tester.pumpAndSettle();
    expect(find.text('Colegio Central'), findsNothing);
    expect(find.text('Cancelar solicitud'), findsNothing);
  });
  test('contexto institucional se invalida al cambiar identidad real', () {
    final container = ProviderContainer(
      overrides: [
        sessionControllerProvider.overrideWith(
          () => TestRequestSession(teacher),
        ),
        dioProvider.overrideWithValue(Dio()),
      ],
    );
    addTearDown(container.dispose);
    final first = container.read(teacherInstitutionRepositoryProvider);
    final requests = container.read(
      studentInstitutionRequestRepositoryProvider,
    );
    (container.read(sessionControllerProvider.notifier) as TestRequestSession)
        .change(teacher.copyWith(xpTotal: 10));
    expect(
      container.read(studentInstitutionRequestRepositoryProvider),
      same(requests),
      reason: 'Una actualización de XP no debe borrar el borrador de ingreso.',
    );
    (container.read(sessionControllerProvider.notifier) as TestRequestSession)
        .change(
          const UserSession(
            id: 'other',
            firstName: 'Otro',
            role: AppRole.teacher,
          ),
        );
    expect(
      container.read(teacherInstitutionRepositoryProvider),
      isNot(same(first)),
    );
    expect(
      container.read(studentInstitutionRequestRepositoryProvider),
      isNot(same(requests)),
    );
  });
}
