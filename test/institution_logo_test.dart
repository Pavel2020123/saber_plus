import 'dart:convert';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:saber_plus/features/institutions/data/institution_logo_repository.dart';
import 'package:saber_plus/features/institutions/domain/institution_profile.dart';
import 'package:saber_plus/features/institutions/presentation/institution_logo.dart';
import 'package:saber_plus/features/institutions/presentation/institution_logo_page.dart';

const id = 'a6ec3648-24ee-47d0-91f8-e59b2b68b9ab';
final png = base64Decode(
  'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNk+A8AAQUBAScY42YAAAAASUVORK5CYII=',
);
InstitutionProfile profile({
  bool edit = true,
  int revision = 0,
  String? logo,
}) => InstitutionProfile(
  id: id,
  name: 'Colegio',
  description: 'Texto',
  revision: revision,
  canEdit: edit,
  logoUrl: logo,
);

class Profiles implements InstitutionProfileRepository {
  InstitutionProfile current = profile();
  @override
  Future<InstitutionProfile> load() async => current;
  @override
  Future<InstitutionProfile> save(
    InstitutionProfile current,
    String description,
  ) => throw UnimplementedError();
}

class Logos implements InstitutionLogoRepository {
  Logos(this.profiles);
  final Profiles profiles;
  bool fail = false;
  int calls = 0;
  @override
  Future<InstitutionProfile> save(
    InstitutionProfile current,
    Uint8List? bytes,
  ) async {
    calls++;
    if (fail) throw Exception('409');
    return profiles.current = profile(
      revision: current.revision + 1,
      logo: bytes == null
          ? null
          : '/instituciones/directorio/$id/logo/${current.revision + 1}',
    );
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'logo publicado conserva cuadro de 80 por 80 dentro del perfil ancho',
    (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            institutionLogoBytesProvider.overrideWith((ref, path) async => png),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: ListView(
                children: [
                  InstitutionLogo(
                    path: '/instituciones/directorio/$id/logo/1',
                    size: 80,
                  ),
                ],
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.getSize(find.byType(Image)), const Size(80, 80));
    },
  );

  test(
    'la miniatura PNG conserva bytes originales y decodifica la selección',
    () async {
      final original = Uint8List.fromList(png);
      final preview = await createInstitutionLogoPreview(original);
      expect(preview.take(8), [137, 80, 78, 71, 13, 10, 26, 10]);
      expect(original, png);
    },
  );

  test(
    'rechaza firmas falsas y JPEG truncado antes de aceptar la vista previa',
    () async {
      await expectLater(
        createInstitutionLogoPreview(Uint8List.fromList([1, 2, 3])),
        throwsFormatException,
      );
      await expectLater(
        createInstitutionLogoPreview(Uint8List.fromList([255, 216, 255, 0])),
        throwsA(isA<Exception>()),
      );
    },
  );
  test('envía multipart con revisión y exige acuse correspondiente', () async {
    final dio = Dio();
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (o, h) {
          expect(o.path, '/instituciones/me/logo');
          expect(o.method, 'POST');
          final data = o.data as FormData;
          expect(data.fields.single.key, 'revision');
          expect(data.fields.single.value, '0');
          expect(data.files.single.key, 'logo');
          expect(data.files.single.value.length, png.length);
          h.resolve(
            Response(
              requestOptions: o,
              data: {
                'revision': 1,
                'logoUrl': '/instituciones/directorio/$id/logo/1',
              },
            ),
          );
        },
      ),
    );
    final saved = await RemoteInstitutionLogoRepository(
      dio,
    ).save(profile(), png);
    expect(saved.description, 'Texto');
    expect(saved.revision, 1);
  });
  test(
    'DELETE lleva revisión, no sube imagen y confirma eliminación',
    () async {
      final dio = Dio();
      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (o, h) {
            expect(o.method, 'DELETE');
            expect(o.data, {'revision': 0});
            h.resolve(
              Response(
                requestOptions: o,
                data: {'revision': 1, 'logoUrl': null},
              ),
            );
          },
        ),
      );
      expect(
        (await RemoteInstitutionLogoRepository(
          dio,
        ).save(profile(), null)).logoUrl,
        isNull,
      );
    },
  );
  test('no acepta una URL externa como confirmación', () async {
    final dio = Dio();
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (o, h) => h.resolve(
          Response(
            requestOptions: o,
            data: {'revision': 1, 'logoUrl': 'https://example.org/x'},
          ),
        ),
      ),
    );
    await expectLater(
      RemoteInstitutionLogoRepository(dio).save(profile(), png),
      throwsFormatException,
    );
    expect(() => institutionLogoPath('//example.org/x'), throwsFormatException);
  });
  test('rechaza falta de permiso y tamaño antes de enviar', () async {
    final repo = RemoteInstitutionLogoRepository(Dio());
    await expectLater(
      repo.save(profile(edit: false), png),
      throwsArgumentError,
    );
    await expectLater(
      repo.save(profile(), Uint8List(3 * 1024 * 1024 + 1)),
      throwsArgumentError,
    );
  });

  Future<void> mount(
    WidgetTester tester,
    Profiles p,
    Logos l, {
    Future<Uint8List?> Function()? pick,
  }) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          institutionLogoBytesProvider.overrideWith((ref, path) async => png),
        ],
        child: MaterialApp(
          home: InstitutionLogoEditor(
            profiles: p,
            logos: l,
            pick: pick ?? () async => png,
            onSaved: (_) {},
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> tap(WidgetTester tester, String label) async {
    if (find.text(label).evaluate().isEmpty) {
      await tester.scrollUntilVisible(find.text(label), 200);
    }
    await tester.ensureVisible(find.text(label));
    // La decodificación nativa no avanza con el reloj simulado de pumpAndSettle.
    await tester.runAsync(() async {
      await tester.tap(find.text(label));
      await tester.pump();
      for (
        var i = 0;
        i < 100 && find.byType(LinearProgressIndicator).evaluate().isNotEmpty;
        i++
      ) {
        await Future<void>.delayed(const Duration(milliseconds: 10));
        await tester.pump();
      }
    });
    await tester.pumpAndSettle();
  }

  testWidgets(
    'cancelar selector no publica; elegir solo muestra vista previa',
    (tester) async {
      final p = Profiles();
      final l = Logos(p);
      await mount(tester, p, l, pick: () async => null);
      await tap(tester, 'Seleccionar imagen');
      expect(find.text('Guardar logo'), findsNothing);
      expect(l.calls, 0);
    },
  );
  testWidgets('vista previa y guardado explícito vuelven a logo publicado', (
    tester,
  ) async {
    final p = Profiles();
    final l = Logos(p);
    await mount(tester, p, l);
    await tap(tester, 'Seleccionar imagen');
    expect(l.calls, 0);
    expect(
      find.text('Vista previa · Recorte cuadrado centrado'),
      findsOneWidget,
    );
    await tap(tester, 'Guardar logo');
    expect(find.text('Logo institucional guardado.'), findsOneWidget);
    expect(find.text('Guardar logo'), findsNothing);
    expect(l.calls, 1);
  });
  testWidgets('imagen inválida no habilita guardar ni publica', (tester) async {
    final p = Profiles();
    final l = Logos(p);
    await mount(tester, p, l, pick: () async => Uint8List.fromList([1, 2, 3]));
    await tap(tester, 'Seleccionar imagen');
    expect(find.text('Guardar logo'), findsNothing);
    expect(find.textContaining('Formato no admitido'), findsOneWidget);
    expect(l.calls, 0);
  });
  testWidgets('imagen demasiado grande informa tamaño y no culpa permisos', (
    tester,
  ) async {
    final p = Profiles();
    final l = Logos(p);
    await mount(tester, p, l, pick: () async => Uint8List(3 * 1024 * 1024 + 1));
    await tap(tester, 'Seleccionar imagen');
    expect(find.text('Elige una imagen de hasta 3 MiB.'), findsOneWidget);
    expect(find.textContaining('permiso'), findsNothing);
    expect(find.text('Guardar logo'), findsNothing);
    expect(l.calls, 0);
  });
  testWidgets(
    'conflicto conserva selección y bloquea guardado hasta consultar',
    (tester) async {
      final p = Profiles();
      final l = Logos(p)..fail = true;
      await mount(tester, p, l);
      await tap(tester, 'Seleccionar imagen');
      await tap(tester, 'Guardar logo');
      expect(
        tester
            .widget<FilledButton>(
              find.widgetWithText(FilledButton, 'Guardar logo'),
            )
            .onPressed,
        isNull,
      );
      await tester.scrollUntilVisible(
        find.text('Vista previa · Recorte cuadrado centrado'),
        -150,
      );
      expect(
        find.text('Vista previa · Recorte cuadrado centrado'),
        findsOneWidget,
      );
      p.current = profile(revision: 3);
      await tap(tester, 'Consultar versión actual');
      l.fail = false;
      await tap(tester, 'Guardar logo');
      expect(p.current.revision, 4);
    },
  );
  testWidgets('lector no dispone de selección, eliminación ni guardado', (
    tester,
  ) async {
    final p = Profiles()..current = profile(edit: false);
    final l = Logos(p);
    await mount(tester, p, l);
    expect(find.text('Seleccionar imagen'), findsNothing);
    expect(find.text('Eliminar logo'), findsNothing);
    expect(find.text('Guardar logo'), findsNothing);
  });
  testWidgets('eliminar exige confirmación y cancela sin peticiones', (
    tester,
  ) async {
    final p = Profiles()
      ..current = profile(logo: '/instituciones/directorio/$id/logo/1');
    final l = Logos(p);
    await mount(tester, p, l);
    await tap(tester, 'Eliminar logo');
    await tap(tester, 'Cancelar');
    expect(l.calls, 0);
    await tap(tester, 'Eliminar logo');
    await tap(tester, 'Eliminar');
    expect(p.current.logoUrl, isNull);
    expect(find.text('Logo eliminado.'), findsOneWidget);
  });
  testWidgets(
    'selección pendiente exige confirmar salida y permite seguir editando',
    (tester) async {
      final p = Profiles();
      final l = Logos(p);
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Builder(
              builder: (context) => Scaffold(
                body: TextButton(
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => InstitutionLogoEditor(
                        profiles: p,
                        logos: l,
                        pick: () async => png,
                        onSaved: (_) {},
                      ),
                    ),
                  ),
                  child: const Text('Abrir'),
                ),
              ),
            ),
          ),
        ),
      );
      await tap(tester, 'Abrir');
      await tap(tester, 'Seleccionar imagen');
      await tester.pageBack();
      await tester.pumpAndSettle();
      await tap(tester, 'Seguir editando');
      expect(
        find.text('Vista previa · Recorte cuadrado centrado'),
        findsOneWidget,
      );
      await tester.pageBack();
      await tester.pumpAndSettle();
      await tap(tester, 'Salir');
      expect(find.text('Abrir'), findsOneWidget);
      expect(l.calls, 0);
    },
  );
  testWidgets('perder permiso al consultar elimina selección y botones', (
    tester,
  ) async {
    final p = Profiles();
    final l = Logos(p);
    await mount(tester, p, l);
    await tap(tester, 'Seleccionar imagen');
    p.current = profile(edit: false);
    await tap(tester, 'Consultar versión actual');
    expect(find.text('Guardar logo'), findsNothing);
    expect(find.text('Vista previa · Recorte cuadrado centrado'), findsNothing);
    expect(l.calls, 0);
  });
}
