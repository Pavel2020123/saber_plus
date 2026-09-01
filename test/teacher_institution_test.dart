import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:saber_plus/features/dashboard/presentation/teacher_dashboard_page.dart';
import 'package:saber_plus/features/institutions/data/demo_teacher_institution_repository.dart';
import 'package:saber_plus/features/institutions/data/remote_teacher_institution_repository.dart';
import 'package:saber_plus/features/institutions/domain/teacher_institution_models.dart';
import 'package:saber_plus/features/institutions/presentation/institution_administration_page.dart';
import 'package:saber_plus/features/institutions/presentation/teacher_institution_providers.dart';

void main() {
  test('interpreta el vínculo y el rol institucional sin listar personas', () {
    final context = TeacherInstitutionContext.fromJson({
      'estado': 'VINCULADO',
      'institucion': {
        'id': 'institution-1',
        'nombre': 'Colegio Central',
        'codigoUnico': 'INST-ABC123',
        'planActual': 'GRATIS',
        'totalEstudiantes': 12,
        'totalGrupos': 1,
        'totalProfesores': 2,
        'limiteEstudiantes': 40,
      },
      'membresia': {'rol': 'PROPIETARIO'},
      'solicitud': null,
    });

    expect(context.status, TeacherInstitutionStatus.linked);
    expect(context.memberRole, InstitutionMemberRole.owner);
    expect(context.institution?.name, 'Colegio Central');
    expect(context.institution?.totalStudents, 12);
  });

  test('la demostración crea, solicita y cancela vínculos', () async {
    final repository = DemoTeacherInstitutionRepository();

    expect(
      (await repository.loadContext()).status,
      TeacherInstitutionStatus.noInstitution,
    );
    final pending = await repository.requestJoin(
      institutionCode: 'inst-demo01',
      message: 'Soy docente.',
    );
    expect(pending.status, TeacherInstitutionStatus.pendingRequest);
    expect(pending.joinRequest?.institutionCode, 'INST-DEMO01');
    expect(
      (await repository.cancelJoinRequest()).status,
      TeacherInstitutionStatus.noInstitution,
    );
    final linked = await repository.createInstitution(name: 'Colegio Demo');
    expect(linked.status, TeacherInstitutionStatus.linked);
    expect(linked.memberRole, InstitutionMemberRole.owner);
  });

  test('el repositorio remoto usa las rutas y DTO móviles', () async {
    final requests = <RequestOptions>[];
    final repository = RemoteTeacherInstitutionRepository(
      _dio((options) {
        requests.add(options);
        return {
          'estado': 'SIN_INSTITUCION',
          'institucion': null,
          'membresia': null,
          'solicitud': null,
        };
      }),
    );

    await repository.requestJoin(
      institutionCode: 'INST-ABC123',
      message: 'Soy docente.',
    );

    expect(requests, hasLength(2));
    expect(requests.first.path, '/instituciones/solicitudes');
    expect(requests.first.method, 'POST');
    expect(requests.first.data, {
      'codigoInstitucion': 'INST-ABC123',
      'mensaje': 'Soy docente.',
    });
    expect(requests.last.path, '/instituciones/profesor/contexto');
  });

  test('interpreta miembros, permisos y auditoría institucional', () {
    final administration = InstitutionAdministration.fromJson(_adminJson());

    expect(administration.myRole, InstitutionMemberRole.owner);
    expect(administration.permissions.transferOwnership, isTrue);
    expect(administration.members.single.email, 'owner@saberplus.com');
    expect(administration.requests.single.name, 'Laura Martínez');
    expect(administration.audit.single.action, 'INSTITUCION_CREADA');
  });

  test(
    'la administración demostrativa aprueba y transfiere propiedad',
    () async {
      final repository = DemoTeacherInstitutionRepository();
      await repository.createInstitution(name: 'Colegio Demo');

      final initial = await repository.loadAdministration();
      expect(initial.members, hasLength(1));
      expect(initial.requests, hasLength(1));

      final approved = await repository.reviewRequest(
        requestId: initial.requests.single.id,
        approve: true,
      );
      expect(approved.members, hasLength(2));
      final teacher = approved.members.firstWhere(
        (member) => member.role == InstitutionMemberRole.teacher,
      );

      final transferred = await repository.transferOwnership(
        membershipId: teacher.membershipId,
        confirmationCode: 'inst-demo01',
      );
      expect(transferred.myRole, InstitutionMemberRole.administrator);
      expect(
        transferred.members
            .firstWhere((member) => member.membershipId == teacher.membershipId)
            .role,
        InstitutionMemberRole.owner,
      );
    },
  );

  test('el repositorio remoto protege los DTO administrativos', () async {
    final requests = <RequestOptions>[];
    final repository = RemoteTeacherInstitutionRepository(
      _dio((options) {
        requests.add(options);
        return options.path == '/instituciones/me/administracion'
            ? _adminJson()
            : <String, dynamic>{};
      }),
    );

    await repository.inviteMember(
      email: 'teacher@saberplus.com',
      role: InstitutionMemberRole.administrator,
    );

    expect(requests.first.path, '/instituciones/me/invitaciones');
    expect(requests.first.method, 'POST');
    expect(requests.first.data, {
      'correo': 'teacher@saberplus.com',
      'rol': 'ADMINISTRADOR',
    });
    expect(requests.last.path, '/instituciones/me/administracion');
  });

  testWidgets('el profesor crea su institución personal desde la interfaz', (
    tester,
  ) async {
    final repository = DemoTeacherInstitutionRepository();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          teacherInstitutionRepositoryProvider.overrideWithValue(repository),
        ],
        child: const MaterialApp(home: TeacherDashboardPage()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Configura tu espacio institucional'), findsOneWidget);
    final createButton = find.descendant(
      of: find.byKey(const Key('teacher-create-institution')),
      matching: find.byType(FilledButton),
    );
    await tester.ensureVisible(createButton);
    await tester.tap(createButton);
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('institution-name-field')),
      'Colegio Central',
    );
    await tester.tap(find.byKey(const Key('confirm-create-institution')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('teacher-institution-name')), findsOneWidget);
    expect(find.text('Colegio Central'), findsOneWidget);
    expect(find.text('Propietario'), findsOneWidget);
    expect(find.text('INST-DEMO01'), findsOneWidget);
  });

  testWidgets('el propietario crea una invitación desde la administración', (
    tester,
  ) async {
    final repository = DemoTeacherInstitutionRepository();
    await repository.createInstitution(name: 'Colegio Central');
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          teacherInstitutionRepositoryProvider.overrideWithValue(repository),
        ],
        child: const MaterialApp(home: InstitutionAdministrationPage()),
      ),
    );
    await tester.pumpAndSettle();

    final invite = find.byKey(const Key('invite-institution-member'));
    await tester.ensureVisible(invite);
    await tester.tap(invite);
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('institution-invitation-email')),
      'nuevo@saberplus.com',
    );
    await tester.tap(
      find.byKey(const Key('confirm-invite-institution-member')),
    );
    await tester.pumpAndSettle();

    expect(find.text('nuevo@saberplus.com'), findsOneWidget);
    expect(find.text('Invitación creada por siete días.'), findsOneWidget);
  });
}

Map<String, dynamic> _adminJson() => {
  'institucion': {
    'id': 'institution-1',
    'nombre': 'Colegio Central',
    'codigoUnico': 'INST-ABC123',
  },
  'miRol': 'PROPIETARIO',
  'permisos': {
    'revisarSolicitudes': true,
    'invitarProfesores': true,
    'gestionarAdministradores': true,
    'retirarProfesores': true,
    'transferirPropiedad': true,
    'verAuditoria': true,
  },
  'miembros': [
    {
      'id': 'membership-1',
      'rol': 'PROPIETARIO',
      'fechaCreacion': '2026-09-01T10:00:00.000Z',
      'usuario': {
        'id': 'owner-1',
        'nombre': 'Profesor propietario',
        'correo': 'owner@saberplus.com',
      },
    },
  ],
  'solicitudes': [
    {
      'id': 'request-1',
      'mensaje': 'Soy docente.',
      'fechaCreacion': '2026-09-01T11:00:00.000Z',
      'solicitante': {
        'id': 'teacher-2',
        'nombre': 'Laura Martínez',
        'correo': 'laura@saberplus.com',
      },
    },
  ],
  'invitaciones': <Map<String, dynamic>>[],
  'auditoria': [
    {
      'id': 'audit-1',
      'accion': 'INSTITUCION_CREADA',
      'fechaCreacion': '2026-09-01T10:00:00.000Z',
      'actor': {'nombre': 'Profesor propietario'},
      'afectado': {
        'nombre': 'Profesor propietario',
        'correo': 'owner@saberplus.com',
      },
    },
  ],
};

Dio _dio(Map<String, dynamic> Function(RequestOptions options) response) {
  final dio = Dio(BaseOptions(baseUrl: 'http://localhost:3000'));
  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) => handler.resolve(
        Response<Map<String, dynamic>>(
          requestOptions: options,
          statusCode: 200,
          data: response(options),
        ),
      ),
    ),
  );
  return dio;
}
