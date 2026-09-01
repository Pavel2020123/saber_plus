import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:saber_plus/features/institutions/data/demo_institution_group_repository.dart';
import 'package:saber_plus/features/institutions/data/demo_teacher_institution_repository.dart';
import 'package:saber_plus/features/institutions/data/remote_institution_group_repository.dart';
import 'package:saber_plus/features/institutions/domain/institution_group_models.dart';
import 'package:saber_plus/features/institutions/presentation/institution_group_providers.dart';
import 'package:saber_plus/features/institutions/presentation/institution_groups_page.dart';
import 'package:saber_plus/features/institutions/presentation/student_group_join_page.dart';
import 'package:saber_plus/features/institutions/presentation/teacher_institution_providers.dart';

void main() {
  test('interpreta grupos sin recibir el código temporal completo', () {
    final group = InstitutionGroup.fromJson(_teacherGroupJson());

    expect(group.name, 'Once A');
    expect(group.grade, InstitutionGrade.eleventh);
    expect(group.studentCount, 18);
    expect(group.teachers.single.name, 'Profe Andrea');
    expect(group.codes.single.suffix, '7KQ9');
    expect(group.codes.single.availableUses, 37);
  });

  test('interpreta la vista previa y exige aceptación explícita', () {
    final preview = StudentGroupPreview.fromJson(_previewJson());

    expect(preview.status, StudentGroupPreviewStatus.available);
    expect(preview.canJoin, isTrue);
    expect(preview.requiresAcceptance, isTrue);
    expect(preview.institutionName, 'Colegio Central');
    expect(preview.groupName, 'Once A');
  });

  test(
    'el repositorio remoto envía vista previa y aceptación separadas',
    () async {
      final requests = <RequestOptions>[];
      final repository = RemoteInstitutionGroupRepository(
        _dio((options) {
          requests.add(options);
          return switch (options.path) {
            '/instituciones/grupos/vista-previa' => _previewJson(),
            '/instituciones/grupos/estudiante' => {
              'institucionId': 'institution-1',
              'grupos': [_studentGroupJson()],
            },
            _ => <String, dynamic>{'mensaje': 'ok'},
          };
        }),
      );

      await repository.previewCode('GRP-ABCD2345');
      final joined = await repository.acceptCode('GRP-ABCD2345');

      expect(requests[0].path, '/instituciones/grupos/vista-previa');
      expect(requests[0].data, {'codigo': 'GRP-ABCD2345'});
      expect(requests[1].path, '/instituciones/grupos/aceptar');
      expect(requests[1].data, {'codigo': 'GRP-ABCD2345', 'acepto': true});
      expect(requests[2].path, '/instituciones/grupos/estudiante');
      expect(joined.groups.single.explicitlyAccepted, isTrue);
    },
  );

  test(
    'la demostración crea códigos y conserva solo su sufijo al listar',
    () async {
      final repository = DemoInstitutionGroupRepository();

      final created = await repository.createTemporaryCode(
        groupId: 'demo-group-1',
        durationMinutes: 60,
        maximumUses: 40,
      );
      final listed = (await repository.loadTeacherGroups()).single.codes.single;

      expect(created.code, matches(RegExp(r'^GRP-[A-Z2-9]{8}$')));
      expect(listed.suffix, created.code.substring(created.code.length - 4));
      expect(listed.maximumUses, 40);
      expect(listed, isNot(isA<CreatedTemporaryGroupCode>()));
    },
  );

  testWidgets('el estudiante no puede unirse antes de aceptar', (tester) async {
    final repository = DemoInstitutionGroupRepository();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          institutionGroupRepositoryProvider.overrideWithValue(repository),
        ],
        child: const MaterialApp(home: StudentGroupJoinPage()),
      ),
    );
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const Key('student-group-code')),
      'GRP-DEMO2222',
    );
    await tester.tap(find.byKey(const Key('preview-student-group-code')));
    await tester.pumpAndSettle();

    final joinButton = find.byKey(const Key('confirm-student-group-link'));
    expect(joinButton, findsOneWidget);
    expect(tester.widget<FilledButton>(joinButton).onPressed, isNull);

    final acceptance = find.byKey(const Key('accept-student-group-link'));
    await tester.drag(
      find.byKey(const Key('student-institution-groups-list')),
      const Offset(0, -420),
    );
    await tester.pumpAndSettle();
    await tester.tap(
      find.descendant(of: acceptance, matching: find.byType(Checkbox)),
    );
    await tester.pump();
    expect(tester.widget<FilledButton>(joinButton).onPressed, isNotNull);

    await tester.ensureVisible(joinButton);
    await tester.tap(joinButton);
    await tester.pumpAndSettle();
    expect(find.text('Once A'), findsOneWidget);
    expect(find.text('Te vinculaste al grupo correctamente.'), findsOneWidget);
  });

  testWidgets('el propietario genera un código que se muestra una sola vez', (
    tester,
  ) async {
    final groups = DemoInstitutionGroupRepository();
    final institution = DemoTeacherInstitutionRepository();
    await institution.createInstitution(name: 'Colegio Central');
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          institutionGroupRepositoryProvider.overrideWithValue(groups),
          teacherInstitutionRepositoryProvider.overrideWithValue(institution),
        ],
        child: const MaterialApp(home: InstitutionGroupsPage()),
      ),
    );
    await tester.pumpAndSettle();

    final create = find.byKey(const Key('create-group-code-demo-group-1'));
    await tester.ensureVisible(create);
    await tester.tap(create);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('confirm-create-group-code')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('created-group-code-value')), findsOneWidget);
    expect(find.textContaining('no volverá a mostrar'), findsOneWidget);
    expect(find.byKey(const Key('copy-created-group-code')), findsOneWidget);
  });
}

Map<String, dynamic> _teacherGroupJson() => {
  'id': 'group-1',
  'nombre': 'Once A',
  'grado': 'ONCE',
  '_count': {'ClaseEstudiante': 18},
  'profesores': [
    {
      'miembro': {
        'id': 'membership-1',
        'rol': 'PROPIETARIO',
        'usuario': {
          'id': 'teacher-1',
          'nombre': 'Profe Andrea',
          'correo': 'andrea@saberplus.com',
        },
      },
    },
  ],
  'codigos': [
    {
      'id': 'code-1',
      'sufijo': '7KQ9',
      'usos': 3,
      'usosMaximos': 40,
      'fechaExpiracion': '2026-09-02T12:00:00.000Z',
      'fechaCreacion': '2026-09-01T12:00:00.000Z',
    },
  ],
};

Map<String, dynamic> _previewJson() => {
  'estado': 'DISPONIBLE',
  'requiereAceptacion': true,
  'puedeUnirse': true,
  'grupo': {'id': 'group-1', 'nombre': 'Once A', 'grado': 'ONCE'},
  'institucion': {'id': 'institution-1', 'nombre': 'Colegio Central'},
  'codigo': {
    'sufijo': '2345',
    'fechaExpiracion': '2026-09-02T12:00:00.000Z',
    'usosDisponibles': 39,
  },
};

Map<String, dynamic> _studentGroupJson() => {
  'id': 'group-1',
  'nombre': 'Once A',
  'grado': 'ONCE',
  'institucion': {'id': 'institution-1', 'nombre': 'Colegio Central'},
  'fechaIngreso': '2026-09-01T12:00:00.000Z',
  'aceptacionExplicita': true,
};

Dio _dio(Object? Function(RequestOptions options) response) {
  final dio = Dio(BaseOptions(baseUrl: 'http://localhost:3000'));
  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) => handler.resolve(
        Response<Object?>(
          requestOptions: options,
          statusCode: 200,
          data: response(options),
        ),
      ),
    ),
  );
  return dio;
}
