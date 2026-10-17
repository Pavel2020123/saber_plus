import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:saber_plus/core/network/api_error.dart';
import 'package:saber_plus/features/auth/domain/session.dart';
import 'package:saber_plus/features/auth/presentation/session_controller.dart';
import 'package:saber_plus/features/institutions/data/student_institution_code_repository.dart';
import 'package:saber_plus/features/institutions/domain/institution_directory.dart';
import 'package:saber_plus/features/institutions/domain/student_institution_code.dart';
import 'package:saber_plus/features/institutions/presentation/institution_student_code_entry.dart';
import 'package:saber_plus/features/institutions/presentation/institution_student_code_owner.dart';
import 'package:saber_plus/features/institutions/presentation/student_institution_code_page.dart';
import 'package:saber_plus/features/institutions/presentation/student_institution_code_providers.dart';
import 'package:saber_plus/features/institutions/presentation/teacher_institution_providers.dart';
import 'student_institution_requests_test.dart' as fixtures;

const institution = PublicInstitution(
  id: fixtures.institutionId,
  name: 'Colegio Central',
);
final code = 'SPI-${'A' * 32}';
final nextCode = 'SPI-${'B' * 32}';
const operationId = fixtures.requestId;
final preview = InstitutionCodePreview(
  institution: institution,
  revision: 1,
  alreadyLinked: false,
);
Map<String, dynamic> ownedJson({
  Object? value,
  Object? revision = 1,
  Object? operation = operationId,
}) => {
  'institucion': {'id': institution.id, 'nombre': institution.name},
  'codigo': value ?? code,
  'revision': revision,
  'operacionId': operation,
};
Map<String, dynamic> previewJson() => {
  'institucion': {'id': institution.id, 'nombre': institution.name},
  'revision': 1,
  'yaVinculado': false,
};

class CodeFake implements StudentInstitutionCodeRepository {
  InstitutionStudentCode owned = const InstitutionStudentCode(
    institution: institution,
    revision: 0,
  );
  final rotations = <({String id, int revision})>[];
  final joins = <InstitutionCodeJoinAttempt>[];
  final queries = <String>[];
  final copied = <String>[];
  bool failRead = false,
      failRotate = false,
      saveRotationBeforeFailure = false,
      failJoin = false,
      saveJoinBeforeFailure = false,
      failMembership = false,
      failPreview = false;
  String? membership;
  VoidCallback? onRequestVisit;
  int reads = 0, refreshes = 0, requestVisits = 0;
  Completer<InstitutionCodePreview>? delayedPreview;
  Completer<InstitutionCodeRotation>? delayedRotation;
  Completer<InstitutionStudentCode>? delayedOwn;
  Completer<InstitutionCodeJoinResult>? delayedJoin;
  @override
  Future<InstitutionStudentCode> own() async {
    reads++;
    if (failRead) throw Exception('offline');
    if (delayedOwn != null) return delayedOwn!.future;
    return owned;
  }

  @override
  Future<InstitutionCodeRotation> rotate({
    required String operationId,
    required int revision,
  }) async {
    rotations.add((id: operationId, revision: revision));
    final result = InstitutionCodeRotation(
      code: nextCode,
      revision: revision + 1,
      operationId: operationId,
    );
    if (!failRotate || saveRotationBeforeFailure) owned = owned.rotated(result);
    if (delayedRotation != null) return delayedRotation!.future;
    if (failRotate) throw Exception('timeout');
    return result;
  }

  @override
  Future<InstitutionCodePreview> preview(String code) async {
    queries.add(code);
    if (failPreview) {
      throw const ApiError(code: '404', message: 'Código no disponible.');
    }
    if (delayedPreview != null) return delayedPreview!.future;
    return InstitutionCodePreview(
      institution: institution,
      revision: 1,
      alreadyLinked: membership == institution.id,
    );
  }

  @override
  Future<InstitutionCodeJoinResult> join(
    InstitutionCodeJoinAttempt attempt,
  ) async {
    joins.add(attempt);
    if (!failJoin || saveJoinBeforeFailure) membership = institution.id;
    if (delayedJoin != null) return delayedJoin!.future;
    if (failJoin) {
      throw const ApiError(code: '409', message: 'Consulta el estado actual.');
    }
    return const InstitutionCodeJoinResult(
      institution: institution,
      alreadyLinked: false,
    );
  }

  Future<String?> consult() async {
    if (failMembership) throw Exception('offline');
    return membership;
  }

  Future<void> refreshed() async {
    refreshes++;
  }

  Future<void> requests() async {
    requestVisits++;
    onRequestVisit?.call();
  }

  Future<void> copy(String value) async {
    copied.add(value);
  }
}

Future<void> mount(
  WidgetTester tester,
  CodeFake repo, {
  bool owner = false,
  String? linked,
  double width = 500,
  double height = 1500,
  double scale = 1,
}) async {
  tester.view.physicalSize = Size(width, height);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    MaterialApp(
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(
          context,
        ).copyWith(textScaler: TextScaler.linear(scale)),
        child: child!,
      ),
      home: owner
          ? InstitutionStudentCodeOwner(repository: repo, copy: repo.copy)
          : InstitutionStudentCodeEntry(
              repository: repo,
              linkedInstitutionId: linked,
              consultMembership: repo.consult,
              onJoined: repo.refreshed,
              onRequests: repo.requests,
            ),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> tapKey(WidgetTester tester, String key) async {
  final finder = find.byKey(Key(key));
  if (finder.evaluate().isEmpty) {
    await tester.scrollUntilVisible(
      finder,
      150,
      scrollable: find.byType(Scrollable).first,
    );
  }
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

Future<void> lookup(WidgetTester tester) async {
  await tester.enterText(
    find.byKey(const Key('student-institution-code-input')),
    code.toLowerCase(),
  );
  await tapKey(tester, 'preview-student-institution-code');
}

Future<void> enter(WidgetTester tester) async {
  await tapKey(tester, 'join-student-institution-code');
  await tester.tap(find.text('Confirmar ingreso'));
  await tester.pumpAndSettle();
}

Future<void> rotate(WidgetTester tester) async {
  await tapKey(tester, 'rotate-student-code');
  await tester.tap(find.text('Confirmar'));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('salir protege código escrito y descarta solo al confirmar', (
    tester,
  ) async {
    final repo = CodeFake();
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () => Navigator.of(context).push<void>(
                MaterialPageRoute(
                  builder: (_) => InstitutionStudentCodeEntry(
                    repository: repo,
                    consultMembership: repo.consult,
                    onJoined: repo.refreshed,
                    onRequests: repo.requests,
                  ),
                ),
              ),
              child: const Text('Abrir'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Abrir'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('student-institution-code-input')),
      code,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Back'));
    await tester.pumpAndSettle();
    expect(find.text('¿Salir sin continuar?'), findsOneWidget);
    await tester.tap(find.text('Volver'));
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<TextField>(
            find.byKey(const Key('student-institution-code-input')),
          )
          .controller!
          .text,
      code,
    );
    await tester.tap(find.byTooltip('Back'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Salir'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Abrir'));
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<TextField>(
            find.byKey(const Key('student-institution-code-input')),
          )
          .controller!
          .text,
      '',
    );
    expect(repo.joins, isEmpty);
  });

  testWidgets(
    'doble acción de ingreso y red pendiente envían una sola operación',
    (tester) async {
      final repo = CodeFake()
        ..delayedJoin = Completer<InstitutionCodeJoinResult>();
      await mount(tester, repo);
      await lookup(tester);
      final action = tester
          .widget<FilledButton>(
            find.byKey(const Key('join-student-institution-code')),
          )
          .onPressed!;
      action();
      action();
      await tester.pumpAndSettle();
      expect(find.text('Confirmar ingreso'), findsOneWidget);
      await tester.tap(find.text('Confirmar ingreso'));
      await tester.pump();
      action();
      await tester.pump();
      expect(repo.joins, hasLength(1));
      repo.delayedJoin!.complete(
        const InstitutionCodeJoinResult(
          institution: institution,
          alreadyLinked: false,
        ),
      );
      await tester.pumpAndSettle();
      expect(repo.joins, hasLength(1));
    },
  );

  testWidgets('doble acción de renovación genera un único POST', (
    tester,
  ) async {
    final repo = CodeFake()
      ..delayedRotation = Completer<InstitutionCodeRotation>();
    await mount(tester, repo, owner: true);
    final action = tester
        .widget<FilledButton>(find.byKey(const Key('rotate-student-code')))
        .onPressed!;
    action();
    action();
    await tester.pumpAndSettle();
    await tester.tap(find.text('Confirmar'));
    await tester.pump();
    action();
    await tester.pump();
    expect(repo.rotations, hasLength(1));
    repo.delayedRotation!.complete(
      InstitutionCodeRotation(
        code: nextCode,
        revision: 1,
        operationId: repo.rotations.single.id,
      ),
    );
    await tester.pumpAndSettle();
    expect(repo.rotations, hasLength(1));
  });

  testWidgets('fallo del portapapeles no afirma que se copió', (tester) async {
    final repo = CodeFake()
      ..owned = InstitutionStudentCode(
        institution: institution,
        revision: 1,
        code: code,
        operationId: operationId,
      );
    await tester.pumpWidget(
      MaterialApp(
        home: InstitutionStudentCodeOwner(
          repository: repo,
          copy: (_) async => throw Exception('unavailable'),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tapKey(tester, 'copy-student-code');
    expect(
      find.text('No pudimos copiar el código. Inténtalo de nuevo.'),
      findsOneWidget,
    );
    expect(find.textContaining('Código copiado.'), findsNothing);
  });

  testWidgets('cambio de cuenta cierra confirmación sin enviar', (
    tester,
  ) async {
    final repo = CodeFake();
    final session = fixtures.TestRequestSession(fixtures.student);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sessionControllerProvider.overrideWith(() => session),
          studentInstitutionCodeRepositoryProvider.overrideWithValue(repo),
        ],
        child: const MaterialApp(home: StudentInstitutionCodePage()),
      ),
    );
    await tester.pumpAndSettle();
    await lookup(tester);
    await tapKey(tester, 'join-student-institution-code');
    expect(find.text('Confirmar ingreso'), findsOneWidget);
    session.change(
      const UserSession(id: 'other', firstName: 'Otra', role: AppRole.student),
    );
    await tester.pumpAndSettle();
    expect(find.text('Confirmar ingreso'), findsNothing);
    expect(repo.joins, isEmpty);
    expect(
      tester
          .widget<TextField>(
            find.byKey(const Key('student-institution-code-input')),
          )
          .controller!
          .text,
      '',
    );
    expect(tester.takeException(), null);
  });

  testWidgets('ingreso tardío no confirma ni refresca en otra cuenta', (
    tester,
  ) async {
    final repo = CodeFake()
      ..delayedJoin = Completer<InstitutionCodeJoinResult>();
    final session = fixtures.TestRequestSession(fixtures.student);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sessionControllerProvider.overrideWith(() => session),
          studentInstitutionCodeRepositoryProvider.overrideWithValue(repo),
        ],
        child: const MaterialApp(home: StudentInstitutionCodePage()),
      ),
    );
    await tester.pumpAndSettle();
    await lookup(tester);
    await tapKey(tester, 'join-student-institution-code');
    await tester.tap(find.text('Confirmar ingreso'));
    await tester.pump();
    session.change(
      const UserSession(id: 'other', firstName: 'Otra', role: AppRole.student),
    );
    await tester.pump();
    repo.delayedJoin!.complete(
      const InstitutionCodeJoinResult(
        institution: institution,
        alreadyLinked: false,
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Institución vinculada'), findsNothing);
    expect(find.textContaining('Ingreso confirmado.'), findsNothing);
    expect(tester.takeException(), null);
  });

  group('C4 modelos y contrato remoto', () {
    test('estado propio requiere campos nulos explícitos, no ausentes', () {
      final missingCode = ownedJson()..remove('codigo');
      final missingOperation = ownedJson()..remove('operacionId');
      expect(
        () => InstitutionStudentCode.fromJson(missingCode),
        throwsFormatException,
      );
      expect(
        () => InstitutionStudentCode.fromJson(missingOperation),
        throwsFormatException,
      );
    });
    test('código normalizado, separado de docente/grupo', () {
      expect(normalizeInstitutionStudentCode(' ${code.toLowerCase()} '), code);
      for (final value in [
        'INST-123',
        'GRP-123',
        true,
        null,
        code.toLowerCase(),
        code.substring(0, 35),
      ]) {
        expect(isInstitutionStudentCode(value), false);
      }
    });
    test('propio permite null solo con revisión0 y sin operación', () {
      expect(
        InstitutionStudentCode.fromJson({
          ...ownedJson(),
          'codigo': null,
          'revision': 0,
          'operacionId': null,
        }).code,
        null,
      );
      for (final change in [
        {'codigo': null},
        {'revision': 0},
        {'revision': '1'},
        {'operacionId': 'bad'},
      ]) {
        expect(
          () => InstitutionStudentCode.fromJson({...ownedJson(), ...change}),
          throwsFormatException,
        );
      }
    });
    test('identidad inválida y booleanos no se aceptan silenciosamente', () {
      expect(
        () => InstitutionCodePreview.fromJson({
          ...previewJson(),
          'yaVinculado': 1,
        }),
        throwsFormatException,
      );
      expect(
        () => InstitutionCodePreview.fromJson({
          ...previewJson(),
          'institucion': {'id': 'bad', 'nombre': 'A'},
        }),
        throwsFormatException,
      );
      expect(
        () => InstitutionCodeJoinResult.fromJson({
          ...previewJson(),
          'estado': 'PENDIENTE',
        }),
        throwsFormatException,
      );
    });
    test(
      'normaliza solo envío y mantiene UUID/snapshot en el mismo reintento',
      () async {
        final requests = <RequestOptions>[];
        final dio = Dio()
          ..interceptors.add(
            InterceptorsWrapper(
              onRequest: (request, handler) {
                requests.add(request);
                handler.resolve(
                  Response(
                    requestOptions: request,
                    data: request.path.endsWith('/consultar')
                        ? previewJson()
                        : {...previewJson(), 'estado': 'VINCULADO'},
                  ),
                );
              },
            ),
          );
        addTearDown(dio.close);
        final repo = RemoteStudentInstitutionCodeRepository(dio);
        final snapshot = await repo.preview(' ${code.toLowerCase()} ');
        final attempt = InstitutionCodeJoinAttempt(
          operationId: operationId,
          code: code,
          preview: snapshot,
        );
        await repo.join(attempt);
        await repo.join(attempt);
        expect(
          requests.every(
            (r) =>
                r.method == 'POST' &&
                r.queryParameters.isEmpty &&
                !r.path.contains(code),
          ),
          true,
        );
        expect(requests.first.data, {'codigo': code});
        expect(requests[1].data, requests[2].data);
        expect(requests[1].data, {
          'id': operationId,
          'codigo': code,
          'institucionId': institution.id,
          'revision': 1,
        });
      },
    );
    test('rotación solo acepta respuesta de su UUID y revisión', () async {
      var valid = false;
      final dio = Dio()
        ..interceptors.add(
          InterceptorsWrapper(
            onRequest: (request, handler) {
              handler.resolve(
                Response(
                  requestOptions: request,
                  data: {
                    'codigo': nextCode,
                    'revision': valid ? 2 : 1,
                    'operacionId': operationId,
                  },
                ),
              );
            },
          ),
        );
      addTearDown(dio.close);
      final repo = RemoteStudentInstitutionCodeRepository(dio);
      await expectLater(
        repo.rotate(operationId: operationId, revision: 1),
        throwsFormatException,
      );
      valid = true;
      expect(
        (await repo.rotate(operationId: operationId, revision: 1)).revision,
        2,
      );
    });
    test('ingreso a otra institución en respuesta no es éxito', () async {
      final dio = Dio()
        ..interceptors.add(
          InterceptorsWrapper(
            onRequest: (request, handler) {
              handler.resolve(
                Response(
                  requestOptions: request,
                  data: {
                    ...previewJson(),
                    'estado': 'VINCULADO',
                    'institucion': {'id': operationId, 'nombre': 'Otra'},
                  },
                ),
              );
            },
          ),
        );
      addTearDown(dio.close);
      await expectLater(
        RemoteStudentInstitutionCodeRepository(dio).join(
          InstitutionCodeJoinAttempt(
            operationId: operationId,
            code: code,
            preview: preview,
          ),
        ),
        throwsFormatException,
      );
    });
    test('datos inválidos no hacen solicitudes', () async {
      final dio = Dio();
      addTearDown(dio.close);
      final repo = RemoteStudentInstitutionCodeRepository(dio);
      await expectLater(repo.preview('GRP-123'), throwsArgumentError);
      await expectLater(
        repo.rotate(operationId: 'bad', revision: 1),
        throwsArgumentError,
      );
      await expectLater(
        repo.rotate(operationId: operationId, revision: 2147483647),
        throwsArgumentError,
      );
      await expectLater(
        repo.join(
          InstitutionCodeJoinAttempt(
            operationId: operationId,
            code: 'wrong',
            preview: preview,
          ),
        ),
        throwsArgumentError,
      );
    });
    test('errores Dio no se transforman en demo/éxito', () async {
      final dio = Dio()
        ..interceptors.add(
          InterceptorsWrapper(
            onRequest: (request, handler) {
              handler.reject(
                DioException(
                  requestOptions: request,
                  type: DioExceptionType.connectionError,
                ),
              );
            },
          ),
        );
      addTearDown(dio.close);
      await expectLater(
        RemoteStudentInstitutionCodeRepository(dio).own(),
        throwsA(isA<ApiError>()),
      );
    });
  });

  testWidgets('propietario consulta sin generar ni copiar', (tester) async {
    final repo = CodeFake();
    await mount(tester, repo, owner: true);
    expect(repo.reads, 1);
    expect(repo.rotations, isEmpty);
    expect(repo.copied, isEmpty);
    expect(find.text('Generar código'), findsOneWidget);
  });
  testWidgets('cancelar confirmación no genera código', (tester) async {
    final repo = CodeFake();
    await mount(tester, repo, owner: true);
    await tapKey(tester, 'rotate-student-code');
    await tester.tap(find.text('Volver'));
    await tester.pumpAndSettle();
    expect(repo.rotations, isEmpty);
  });
  testWidgets('generación confirmada y copia por gesto', (tester) async {
    final repo = CodeFake();
    await mount(tester, repo, owner: true);
    await rotate(tester);
    expect(repo.rotations, hasLength(1));
    expect(find.text(nextCode), findsOneWidget);
    expect(repo.copied, isEmpty);
    await tapKey(tester, 'copy-student-code');
    expect(repo.copied, [nextCode]);
    expect(find.textContaining('Código copiado.'), findsOneWidget);
  });
  testWidgets('rotación sin respuesta requiere consulta y conserva operación', (
    tester,
  ) async {
    final repo = CodeFake()..failRotate = true;
    await mount(tester, repo, owner: true);
    await rotate(tester);
    expect(
      find.textContaining('No se pudo confirmar la renovación.'),
      findsOneWidget,
    );
    expect(
      tester
          .widget<FilledButton>(find.byKey(const Key('rotate-student-code')))
          .onPressed,
      null,
    );
    await tapKey(tester, 'consult-owner-student-code');
    repo.failRotate = false;
    await tapKey(tester, 'rotate-student-code');
    expect(repo.rotations, hasLength(2));
    expect(repo.rotations.first, repo.rotations.last);
  });
  testWidgets('rotación guardada se reconcilia consultando sin repetir POST', (
    tester,
  ) async {
    final repo = CodeFake()
      ..failRotate = true
      ..saveRotationBeforeFailure = true;
    await mount(tester, repo, owner: true);
    await rotate(tester);
    expect(find.byKey(const Key('private-student-code')), findsNothing);
    await tapKey(tester, 'consult-owner-student-code');
    expect(
      find.textContaining('Renovación confirmada al consultar'),
      findsOneWidget,
    );
    expect(repo.rotations, hasLength(1));
    expect(find.text(nextCode), findsOneWidget);
  });
  testWidgets('otra renovación no se sobrescribe al consultar', (tester) async {
    final repo = CodeFake()..failRotate = true;
    await mount(tester, repo, owner: true);
    await rotate(tester);
    repo.owned = InstitutionStudentCode(
      institution: institution,
      revision: 2,
      code: nextCode,
      operationId: operationId,
    );
    await tapKey(tester, 'consult-owner-student-code');
    expect(find.textContaining('otra operación'), findsOneWidget);
    expect(find.text('Reintentar misma renovación'), findsNothing);
    expect(repo.rotations, hasLength(1));
  });
  testWidgets('consulta fallida oculta código y bloquea copiar/renovar', (
    tester,
  ) async {
    final repo = CodeFake()
      ..owned = InstitutionStudentCode(
        institution: institution,
        revision: 1,
        code: code,
        operationId: operationId,
      );
    await mount(tester, repo, owner: true);
    repo.failRead = true;
    await tapKey(tester, 'consult-owner-student-code');
    expect(find.text(code), findsNothing);
    expect(find.byKey(const Key('copy-student-code')), findsNothing);
    expect(find.byKey(const Key('rotate-student-code')), findsNothing);
  });
  testWidgets('alumno consulta normalizado y aún no ingresa', (tester) async {
    final repo = CodeFake();
    await mount(tester, repo);
    await lookup(tester);
    expect(repo.queries, [code]);
    expect(repo.joins, isEmpty);
    expect(find.text(institution.name), findsOneWidget);
  });
  testWidgets('cambiar código invalida vista previa', (tester) async {
    final repo = CodeFake();
    await mount(tester, repo);
    await lookup(tester);
    await tester.enterText(
      find.byKey(const Key('student-institution-code-input')),
      nextCode,
    );
    await tester.pumpAndSettle();
    expect(
      find.byKey(const Key('join-student-institution-code')),
      findsNothing,
    );
  });
  testWidgets('código de grupo se rechaza sin llamar API', (tester) async {
    final repo = CodeFake();
    await mount(tester, repo);
    await tester.enterText(
      find.byKey(const Key('student-institution-code-input')),
      'GRP-123',
    );
    await tapKey(tester, 'preview-student-institution-code');
    expect(repo.queries, isEmpty);
    expect(find.textContaining('No uses el código de grupo'), findsOneWidget);
  });
  testWidgets('consulta fallida no permite confirmar nombre anterior', (
    tester,
  ) async {
    final repo = CodeFake();
    await mount(tester, repo);
    await lookup(tester);
    repo.failPreview = true;
    await tapKey(tester, 'preview-student-institution-code');
    expect(
      find.byKey(const Key('join-student-institution-code')),
      findsNothing,
    );
    expect(find.textContaining('Código no disponible.'), findsOneWidget);
  });
  testWidgets('volver en confirmación conserva texto y no envía', (
    tester,
  ) async {
    final repo = CodeFake();
    await mount(tester, repo);
    await lookup(tester);
    await tapKey(tester, 'join-student-institution-code');
    await tester.tap(find.text('Volver'));
    await tester.pumpAndSettle();
    expect(repo.joins, isEmpty);
    expect(
      tester
          .widget<TextField>(
            find.byKey(const Key('student-institution-code-input')),
          )
          .controller!
          .text,
      code.toLowerCase(),
    );
  });
  testWidgets('ingreso confirmado actualiza vínculo y retira formulario', (
    tester,
  ) async {
    final repo = CodeFake();
    await mount(tester, repo);
    await lookup(tester);
    await enter(tester);
    expect(repo.joins, hasLength(1));
    expect(repo.refreshes, 1);
    expect(find.text('Institución vinculada'), findsOneWidget);
    expect(
      find.byKey(const Key('student-institution-code-input')),
      findsNothing,
    );
    expect(
      find.textContaining('No se te asignó un grupo automáticamente'),
      findsOneWidget,
    );
  });
  testWidgets('ingreso incierto bloquea reenvío hasta consulta exitosa', (
    tester,
  ) async {
    final repo = CodeFake()..failJoin = true;
    await mount(tester, repo);
    await lookup(tester);
    await enter(tester);
    expect(
      tester
          .widget<FilledButton>(
            find.byKey(const Key('join-student-institution-code')),
          )
          .onPressed,
      null,
    );
    repo.failMembership = true;
    await tapKey(tester, 'consult-student-code-membership');
    expect(
      tester
          .widget<FilledButton>(
            find.byKey(const Key('join-student-institution-code')),
          )
          .onPressed,
      null,
    );
    expect(repo.joins, hasLength(1));
  });
  testWidgets('reintento del ingreso mantiene UUID código e institución', (
    tester,
  ) async {
    final repo = CodeFake()..failJoin = true;
    await mount(tester, repo);
    await lookup(tester);
    await enter(tester);
    await tapKey(tester, 'consult-student-code-membership');
    repo.failJoin = false;
    await tapKey(tester, 'join-student-institution-code');
    expect(repo.joins, hasLength(2));
    expect(identical(repo.joins.first, repo.joins.last), true);
    expect(repo.joins.first.code, code);
    expect(find.text('Institución vinculada'), findsOneWidget);
  });
  testWidgets('ingreso ya guardado se reconcilia sin repetir envío', (
    tester,
  ) async {
    final repo = CodeFake()
      ..failJoin = true
      ..saveJoinBeforeFailure = true;
    await mount(tester, repo);
    await lookup(tester);
    await enter(tester);
    await tapKey(tester, 'consult-student-code-membership');
    expect(repo.joins, hasLength(1));
    expect(find.text('Institución vinculada'), findsOneWidget);
  });
  testWidgets(
    'vínculo distinto al consultar bloquea traslado y limpia código',
    (tester) async {
      final repo = CodeFake()..failJoin = true;
      await mount(tester, repo);
      await lookup(tester);
      await enter(tester);
      repo.membership = operationId;
      await tapKey(tester, 'consult-student-code-membership');
      expect(
        find.byKey(const Key('student-institution-code-input')),
        findsNothing,
      );
      expect(
        find.byKey(const Key('join-student-institution-code')),
        findsNothing,
      );
      expect(repo.joins, hasLength(1));
    },
  );
  testWidgets('alumno ya vinculado no puede escribir otro código', (
    tester,
  ) async {
    final repo = CodeFake();
    await mount(tester, repo, linked: institution.id);
    expect(find.text('Institución vinculada'), findsOneWidget);
    expect(find.byType(TextField), findsNothing);
    expect(repo.queries, isEmpty);
  });
  testWidgets('vista previa ya vinculado ofrece actualizar, no otro ingreso', (
    tester,
  ) async {
    final repo = CodeFake()..membership = institution.id;
    await mount(tester, repo);
    await lookup(tester);
    expect(find.text('Actualizar mi vínculo'), findsOneWidget);
    expect(
      find.byKey(const Key('join-student-institution-code')),
      findsNothing,
    );
    await tester.tap(find.text('Actualizar mi vínculo'));
    await tester.pumpAndSettle();
    expect(find.text('Institución vinculada'), findsOneWidget);
    expect(repo.joins, isEmpty);
  });
  testWidgets('solicitudes se gestionan de forma explícita', (tester) async {
    final repo = CodeFake();
    await mount(tester, repo);
    await tester.tap(find.text('Consultar mis solicitudes de ingreso'));
    await tester.pumpAndSettle();
    expect(repo.requestVisits, 1);
    expect(repo.joins, isEmpty);
  });
  testWidgets('volver de solicitudes refresca la institución sin ingresar', (
    tester,
  ) async {
    final repo = CodeFake();
    await mount(tester, repo);
    await lookup(tester);
    repo.failPreview = true;
    await tapKey(tester, 'preview-student-institution-code');
    repo.onRequestVisit = () => repo.failPreview = false;
    await tester.tap(find.text('Consultar mis solicitudes de ingreso'));
    await tester.pumpAndSettle();
    expect(repo.queries, hasLength(3));
    expect(find.text(institution.name), findsOneWidget);
    expect(
      find.textContaining('No pudimos consultar ese código'),
      findsNothing,
    );
    expect(
      find.text(
        'Si tienes una solicitud pendiente, cancélala explícitamente antes de ingresar por código.',
      ),
      findsNothing,
    );
    expect(repo.joins, isEmpty);
  });
  testWidgets('cancelar solicitud permite reintentar el mismo ingreso', (
    tester,
  ) async {
    final repo = CodeFake()..failJoin = true;
    await mount(tester, repo);
    await lookup(tester);
    await enter(tester);
    expect(
      tester
          .widget<TextButton>(
            find.widgetWithText(
              TextButton,
              'Consultar mis solicitudes de ingreso',
            ),
          )
          .onPressed,
      isNotNull,
    );
    repo.onRequestVisit = () => repo.failJoin = false;
    await tester.tap(find.text('Consultar mis solicitudes de ingreso'));
    await tester.pumpAndSettle();
    expect(find.text(institution.name), findsOneWidget);
    expect(repo.joins, hasLength(1));
    expect(find.text('Reintentar mismo ingreso'), findsOneWidget);
    await tapKey(tester, 'join-student-institution-code');
    expect(repo.joins, hasLength(2));
    expect(identical(repo.joins.first, repo.joins.last), true);
    expect(find.text('Institución vinculada'), findsOneWidget);
  });
  testWidgets('volver de solicitudes sin red conserva intento bloqueado', (
    tester,
  ) async {
    final repo = CodeFake()..failJoin = true;
    await mount(tester, repo);
    await lookup(tester);
    await enter(tester);
    repo.onRequestVisit = () => repo.failMembership = true;
    await tester.tap(find.text('Consultar mis solicitudes de ingreso'));
    await tester.pumpAndSettle();
    expect(
      find.textContaining('No pudimos consultar tu vínculo'),
      findsOneWidget,
    );
    final button = tester.widget<FilledButton>(
      find.byKey(const Key('join-student-institution-code')),
    );
    expect(button.onPressed, isNull);
    expect(repo.joins, hasLength(1));
  });
  testWidgets(
    'solicitudes accesibles tras ingreso incierto reconcilian sin POST',
    (tester) async {
      final repo = CodeFake()
        ..failJoin = true
        ..saveJoinBeforeFailure = true;
      await mount(tester, repo);
      await lookup(tester);
      await enter(tester);
      await tester.tap(find.text('Consultar mis solicitudes de ingreso'));
      await tester.pumpAndSettle();
      expect(repo.requestVisits, 1);
      expect(find.text('Institución vinculada'), findsOneWidget);
      expect(repo.joins, hasLength(1));
    },
  );
  testWidgets('aprobación en solicitudes reconcilia sin otro ingreso', (
    tester,
  ) async {
    final repo = CodeFake();
    await mount(tester, repo);
    await lookup(tester);
    repo.onRequestVisit = () => repo.membership = institution.id;
    await tester.tap(find.text('Consultar mis solicitudes de ingreso'));
    await tester.pumpAndSettle();
    expect(find.text('Institución vinculada'), findsOneWidget);
    expect(find.byType(TextField), findsNothing);
    expect(repo.queries, hasLength(1));
    expect(repo.joins, isEmpty);
  });
  testWidgets('texto2x y teléfono estrecho sin overflow en ambas pantallas', (
    tester,
  ) async {
    final repo = CodeFake();
    await mount(tester, repo, width: 320, height: 640, scale: 2);
    await lookup(tester);
    await tapKey(tester, 'join-student-institution-code');
    expect(tester.takeException(), null);
    await tester.tap(find.text('Volver'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), null);
    await mount(tester, repo, owner: true, width: 320, height: 640, scale: 2);
    await rotate(tester);
    expect(tester.takeException(), null);
  });

  for (final user in [
    const UserSession(
      id: 'demo',
      firstName: 'Demo',
      role: AppRole.student,
      isDemo: true,
    ),
    const UserSession(id: 'admin', firstName: 'Admin', role: AppRole.admin),
  ]) {
    testWidgets('demo/rol no admitido no llama repositorio ${user.id}', (
      tester,
    ) async {
      final repo = CodeFake();
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sessionControllerProvider.overrideWith(
              () => fixtures.TestRequestSession(user),
            ),
            studentInstitutionCodeRepositoryProvider.overrideWithValue(repo),
          ],
          child: const MaterialApp(home: StudentInstitutionCodePage()),
        ),
      );
      await tester.pumpAndSettle();
      expect(repo.reads, 0);
      expect(repo.queries, isEmpty);
      expect(find.byType(TextField), findsNothing);
    });
  }
  testWidgets('docente lector no carga código privado', (tester) async {
    final repo = CodeFake();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sessionControllerProvider.overrideWith(
            () => fixtures.TestRequestSession(fixtures.teacher),
          ),
          teacherInstitutionControllerProvider.overrideWith(
            () => fixtures.RequestTeacherContext('ADMINISTRADOR'),
          ),
          studentInstitutionCodeRepositoryProvider.overrideWithValue(repo),
        ],
        child: const MaterialApp(home: StudentInstitutionCodePage(owner: true)),
      ),
    );
    await tester.pumpAndSettle();
    expect(repo.reads, 0);
    expect(find.textContaining('Solo el propietario'), findsOneWidget);
  });
  testWidgets('respuesta de consulta tardía no cruza cuentas', (tester) async {
    final repo = CodeFake()
      ..delayedPreview = Completer<InstitutionCodePreview>();
    final session = fixtures.TestRequestSession(fixtures.student);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sessionControllerProvider.overrideWith(() => session),
          studentInstitutionCodeRepositoryProvider.overrideWithValue(repo),
        ],
        child: const MaterialApp(home: StudentInstitutionCodePage()),
      ),
    );
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('student-institution-code-input')),
      code,
    );
    await tester.tap(find.byKey(const Key('preview-student-institution-code')));
    await tester.pump();
    session.change(
      const UserSession(id: 'other', firstName: 'Otra', role: AppRole.student),
    );
    await tester.pump();
    repo.delayedPreview!.complete(preview);
    await tester.pumpAndSettle();
    expect(find.text(institution.name), findsNothing);
    expect(
      tester
          .widget<TextField>(
            find.byKey(const Key('student-institution-code-input')),
          )
          .controller!
          .text,
      '',
    );
    expect(tester.takeException(), null);
  });
  testWidgets(
    'vínculo actualizado en la misma cuenta cierra confirmación antigua',
    (tester) async {
      final repo = CodeFake();
      final session = fixtures.TestRequestSession(fixtures.student);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sessionControllerProvider.overrideWith(() => session),
            studentInstitutionCodeRepositoryProvider.overrideWithValue(repo),
          ],
          child: const MaterialApp(home: StudentInstitutionCodePage()),
        ),
      );
      await tester.pumpAndSettle();
      await lookup(tester);
      await tapKey(tester, 'join-student-institution-code');
      session.change(
        UserSession(
          id: fixtures.student.id,
          firstName: 'Ana',
          role: AppRole.student,
          institutionId: operationId,
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Confirmar ingreso'), findsNothing);
      expect(
        find.byKey(const Key('student-institution-code-input')),
        findsNothing,
      );
      expect(find.text('Institución vinculada'), findsOneWidget);
      expect(repo.joins, isEmpty);
      expect(tester.takeException(), null);
    },
  );
  testWidgets('respuesta privada tardía no se muestra tras salir de cuenta', (
    tester,
  ) async {
    final repo = CodeFake()..delayedOwn = Completer<InstitutionStudentCode>();
    final session = fixtures.TestRequestSession(fixtures.teacher);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sessionControllerProvider.overrideWith(() => session),
          teacherInstitutionControllerProvider.overrideWith(
            () => fixtures.RequestTeacherContext('PROPIETARIO'),
          ),
          studentInstitutionCodeRepositoryProvider.overrideWithValue(repo),
        ],
        child: const MaterialApp(home: StudentInstitutionCodePage(owner: true)),
      ),
    );
    await tester.pump();
    await tester.pump();
    session.change(fixtures.student);
    await tester.pump();
    repo.delayedOwn!.complete(
      InstitutionStudentCode(
        institution: institution,
        revision: 1,
        code: code,
        operationId: operationId,
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text(code), findsNothing);
    expect(tester.takeException(), null);
  });
}
