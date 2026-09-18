import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:saber_plus/core/network/api_error.dart';
import 'package:saber_plus/features/institutions/data/institution_approval_repository.dart';
import 'package:saber_plus/features/institutions/presentation/institution_approval_page.dart';

const application = <String, dynamic>{
  'revision': 0,
  'nombre': 'Colegio de ensayo',
  'ciudad': 'Bogotá',
  'correoInstitucional': 'colegio@example.com',
  'contacto': 'Representante institucional',
  'evidencia': 'Soy la persona autorizada para representar al colegio.',
  'declaracion': true,
};
void main() {
  test(
    'demo mantiene solicitud pendiente y rechaza reenvío sin dar privilegios',
    () async {
      final repo = DemoInstitutionApprovalRepository();
      expect((await repo.load()).canEdit, true);
      await repo.submit(application);
      final context = await repo.load();
      expect(context.request!.state, 'PENDIENTE');
      expect(context.canEdit, false);
      expect(context.request!.data['institucionId'], null);
      await expectLater(repo.submit(application), throwsA(isA<ApiError>()));
    },
  );
  test(
    'el remoto usa exclusivamente el registro protegido y conserva revisión',
    () async {
      final requests = <RequestOptions>[];
      final dio = Dio();
      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            requests.add(options);
            handler.resolve(
              Response(
                requestOptions: options,
                statusCode: 200,
                data: options.path.endsWith('/me')
                    ? {
                        'solicitud': null,
                        'puedeEditar': true,
                        'transicionHasta': null,
                      }
                    : options.path.endsWith('coincidencias')
                    ? {
                        'coincidencias': [
                          {'nombre': 'Colegio Central', 'ciudad': 'Bogotá'},
                        ],
                      }
                    : {},
              ),
            );
          },
        ),
      );
      final repo = RemoteInstitutionApprovalRepository(dio);
      await repo.load();
      await repo.matches('Central');
      await repo.submit(application);
      expect(requests.map((r) => r.path), [
        '/instituciones/registro/me',
        '/instituciones/registro/coincidencias',
        '/instituciones/registro',
      ]);
      expect(requests.last.data, application);
    },
  );
  test('un envío incierto pide consultar estado y nunca cae en demo', () async {
    final dio = Dio();
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) => handler.reject(
          DioException(
            requestOptions: options,
            type: DioExceptionType.connectionTimeout,
          ),
        ),
      ),
    );
    await expectLater(
      RemoteInstitutionApprovalRepository(dio).submit(application),
      throwsA(
        isA<ApiError>().having((e) => e.code, 'code', 'institution_uncertain'),
      ),
    );
  });
  test('estado desconocido no se interpreta como aprobado', () {
    expect(
      () => InstitutionApplication.fromJson({
        ...application,
        'id': 'x',
        'revision': 1,
        'mensaje': '',
        'estado': 'DESCONOCIDO',
      }),
      throwsFormatException,
    );
  });
  testWidgets(
    'formulario envía solicitud y muestra espera, sin botones de aprobación',
    (tester) async {
      tester.view.physicalSize = const Size(440, 1000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final repo = DemoInstitutionApprovalRepository();
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            institutionApprovalRepositoryProvider.overrideWithValue(repo),
          ],
          child: const MaterialApp(home: InstitutionApprovalPage()),
        ),
      );
      await tester.pumpAndSettle();
      for (final name in [
        'nombre',
        'ciudad',
        'correoInstitucional',
        'contacto',
        'evidencia',
      ]) {
        final field = find.byKey(Key('application-$name'));
        await tester.scrollUntilVisible(
          field,
          250,
          scrollable: find.byType(Scrollable).first,
        );
        await tester.enterText(field, application[name] as String);
        await tester.pumpAndSettle();
      }
      tester.testTextInput.hide();
      tester.binding.focusManager.primaryFocus?.unfocus();
      await tester.pumpAndSettle();
      final submit = find.byKey(const Key('submit-institution-application'));
      await tester.scrollUntilVisible(
        submit,
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();
      await tester.drag(find.byType(ListView), const Offset(0, -180));
      await tester.pumpAndSettle();
      await tester.tap(submit);
      await tester.pumpAndSettle();
      expect((await repo.load()).request, null);
      expect(
        find.text(
          'Confirma que tienes autorización para representar a la institución.',
        ),
        findsOneWidget,
      );
      final check = find.byType(CheckboxListTile);
      await tester.ensureVisible(check);
      await tester.pumpAndSettle();
      await tester.tap(check);
      await tester.ensureVisible(submit);
      await tester.pumpAndSettle();
      await tester.tap(submit);
      await tester.pumpAndSettle();
      expect(find.text('Pendiente de revisión'), findsOneWidget);
      expect(
        find.byKey(const Key('submit-institution-application')),
        findsNothing,
      );
      expect(find.text('Aprobar'), findsNothing);
      expect(tester.takeException(), null);
    },
  );
}
