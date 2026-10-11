import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:saber_plus/features/institutions/data/institution_directory_repository.dart';
import 'package:saber_plus/features/institutions/domain/institution_directory.dart';
import 'package:saber_plus/features/institutions/presentation/institution_directory_page.dart';
import 'package:saber_plus/features/institutions/presentation/institution_directory_providers.dart';
import 'package:saber_plus/features/institutions/presentation/institution_territory_field.dart';
import 'package:saber_plus/features/institutions/data/institution_territory_repository.dart';

class FakeDirectory implements InstitutionDirectoryRepository {
  final calls = <DirectoryQuery>[];
  Future<InstitutionDirectoryPageData> Function(String, int)? load;
  Future<InstitutionDirectoryPageData> Function(DirectoryQuery)? filteredLoad;
  bool fail = false;
  int details = 0;
  @override
  Future<InstitutionDirectoryPageData> search({
    required String query,
    required int page,
    String? department,
    String? municipality,
  }) async {
    calls.add((
      query: query,
      page: page,
      department: department,
      municipality: municipality,
    ));
    if (fail) throw Exception('offline');
    if (filteredLoad != null) return filteredLoad!(calls.last);
    if (load != null) return load!(query, page);
    return InstitutionDirectoryPageData(
      items: [PublicInstitution(id: 'id-$page', name: 'Colegio $page')],
      page: page,
      hasMore: page == 1,
    );
  }

  @override
  Future<PublicInstitution> detail(String id) async {
    details++;
    return PublicInstitution(id: id, name: 'Nombre actualizado');
  }
}

Future<void> mount(WidgetTester tester, InstitutionDirectoryRepository repo) =>
    tester.pumpWidget(
      ProviderScope(
        overrides: [
          institutionDirectoryRepositoryProvider.overrideWithValue(repo),
          institutionTerritoryRepositoryProvider.overrideWithValue(
            DemoInstitutionTerritoryRepository(),
          ),
        ],
        child: const MaterialApp(home: InstitutionDirectoryPage()),
      ),
    );

void main() {
  testWidgets(
    'respuesta tardía de otro departamento no sustituye el filtro actual',
    (tester) async {
      tester.view.physicalSize = const Size(500, 1200);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final late = Completer<InstitutionDirectoryPageData>();
      final repo = FakeDirectory()
        ..filteredLoad = (q) => q.department == '91'
            ? late.future
            : Future.value(
                InstitutionDirectoryPageData(
                  items: [
                    PublicInstitution(
                      id: 'new',
                      name: q.department == '20'
                          ? 'Resultado Cesar'
                          : 'Nacional',
                    ),
                  ],
                  page: 1,
                  hasMore: false,
                ),
              );
      await mount(tester, repo);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Filtrar por ubicación'));
      await tester.pumpAndSettle();
      tester
          .widget<DropdownButtonFormField<String>>(
            find.byKey(const ValueKey('directory-department-all')),
          )
          .onChanged!('91');
      await tester.pump();
      await tester.pump();
      tester
          .widget<DropdownButtonFormField<String>>(
            find.byKey(const ValueKey('directory-department-91')),
          )
          .onChanged!('20');
      await tester.pumpAndSettle();
      late.complete(
        const InstitutionDirectoryPageData(
          items: [PublicInstitution(id: 'old', name: 'Resultado obsoleto')],
          page: 1,
          hasMore: false,
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Resultado Cesar'), findsOneWidget);
      expect(find.text('Resultado obsoleto'), findsNothing);
    },
  );
  test(
    'remoto envía filtros y rechaza resultados fuera de la región',
    () async {
      final dio = Dio();
      RequestOptions? captured;
      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            captured = options;
            handler.resolve(
              Response(
                requestOptions: options,
                data: {
                  'instituciones': [
                    {'id': 'x', 'nombre': 'Colegio', 'ubicacion': null},
                  ],
                  'pagina': 1,
                  'hayMas': false,
                },
              ),
            );
          },
        ),
      );
      final repo = RemoteInstitutionDirectoryRepository(dio);
      await expectLater(
        repo.search(
          query: '',
          page: 1,
          department: '05',
          municipality: '05001',
        ),
        throwsFormatException,
      );
      expect(captured!.queryParameters, {
        'q': '',
        'pagina': 1,
        'departamentoCodigo': '05',
        'municipioCodigo': '05001',
      });
      await expectLater(
        repo.search(query: '', page: 1, municipality: '05001'),
        throwsArgumentError,
      );
    },
  );
  test(
    'demo sin ubicación solo aparece sin filtro, no se inventa región',
    () async {
      final repo = DemoInstitutionDirectoryRepository();
      expect((await repo.search(query: '', page: 1)).items.length, 2);
      expect(
        (await repo.search(
          query: '',
          page: 1,
          department: '91',
        )).items.single.municipalityCode,
        '91001',
      );
      expect(
        (await repo.search(query: '', page: 1, department: '20')).items,
        isEmpty,
      );
    },
  );
  testWidgets('cambiar departamento limpia municipio y reinicia paginación', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(500, 1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final repo = FakeDirectory();
    await mount(tester, repo);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Siguiente'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Filtrar por ubicación'));
    await tester.pumpAndSettle();
    void select(String key, String value) => tester
        .widget<DropdownButtonFormField<String>>(find.byKey(ValueKey(key)))
        .onChanged!(value);
    select('directory-department-all', '91');
    await tester.pumpAndSettle();
    expect(repo.calls.last.page, 1);
    expect(repo.calls.last.department, '91');
    select('directory-municipality-all', '91001');
    await tester.pumpAndSettle();
    expect(repo.calls.last.municipality, '91001');
    expect(find.text('Amazonas · Leticia'), findsOneWidget);
    expect(find.textContaining('Filtro territorial:'), findsNothing);
    select('directory-department-91', '20');
    await tester.pumpAndSettle();
    expect(repo.calls.last.department, '20');
    expect(repo.calls.last.municipality, null);
    await tester.tap(find.text('Todas las ubicaciones'));
    await tester.pumpAndSettle();
    expect(repo.calls.last.department, null);
    expect(repo.calls.last.page, 1);
    expect(tester.takeException(), null);
  });
  test('remoto usa GET paginado y detalle sin enviar códigos', () async {
    final dio = Dio();
    final calls = <RequestOptions>[];
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          calls.add(options);
          handler.resolve(
            Response(
              requestOptions: options,
              data: options.path.endsWith('/abc')
                  ? {'id': 'abc', 'nombre': 'Colegio'}
                  : {
                      'instituciones': [
                        {'id': 'abc', 'nombre': 'Colegio'},
                      ],
                      'pagina': 2,
                      'hayMas': false,
                    },
            ),
          );
        },
      ),
    );
    final repo = RemoteInstitutionDirectoryRepository(dio);
    final page = await repo.search(query: ' Norte ', page: 2);
    expect(page.items.single.name, 'Colegio');
    expect(calls.single.queryParameters, {'q': 'Norte', 'pagina': 2});
    expect((await repo.detail('abc')).id, 'abc');
    expect(calls.map((c) => c.method), everyElement('GET'));
    expect(calls.last.path, '/instituciones/directorio/abc');
  });
  test('no acepta una respuesta vacía o de otra página como éxito', () async {
    final dio = Dio();
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) => handler.resolve(
          Response(
            requestOptions: options,
            data: {'instituciones': [], 'pagina': 9, 'hayMas': false},
          ),
        ),
      ),
    );
    await expectLater(
      RemoteInstitutionDirectoryRepository(dio).search(query: '', page: 1),
      throwsFormatException,
    );
  });
  test('error remoto nunca devuelve instituciones demo', () async {
    final dio = Dio();
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) => handler.reject(
          DioException(
            requestOptions: options,
            type: DioExceptionType.connectionError,
          ),
        ),
      ),
    );
    await expectLater(
      RemoteInstitutionDirectoryRepository(dio).search(query: '', page: 1),
      throwsException,
    );
  });
  testWidgets('lista, pagina y reinicia a primera página al buscar', (
    tester,
  ) async {
    final repo = FakeDirectory();
    await mount(tester, repo);
    await tester.pumpAndSettle();
    expect(find.text('Colegio 1'), findsOneWidget);
    await tester.tap(find.text('Siguiente'));
    await tester.pumpAndSettle();
    expect(find.text('Colegio 2'), findsOneWidget);
    await tester.enterText(find.byType(TextField), 'Norte');
    await tester.tap(find.text('Buscar'));
    await tester.pumpAndSettle();
    expect(repo.calls.last, (
      query: 'Norte',
      page: 1,
      department: null,
      municipality: null,
    ));
  });
  testWidgets('error permite reintentar sin fabricar resultados', (
    tester,
  ) async {
    final repo = FakeDirectory()..fail = true;
    await mount(tester, repo);
    await tester.pumpAndSettle();
    expect(find.text('Reintentar'), findsOneWidget);
    expect(find.text('Colegio 1'), findsNothing);
    repo.fail = false;
    await tester.tap(find.text('Reintentar'));
    await tester.pumpAndSettle();
    expect(find.text('Colegio 1'), findsOneWidget);
  });
  testWidgets('detalle vuelve a consultar y no ofrece afiliación ficticia', (
    tester,
  ) async {
    final repo = FakeDirectory();
    await mount(tester, repo);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Colegio 1'));
    await tester.pumpAndSettle();
    expect(repo.details, 1);
    expect(find.text('Nombre actualizado'), findsOneWidget);
    expect(find.text('Solicitar ingreso'), findsNothing);
  });
  testWidgets('respuesta tardía no reemplaza una búsqueda nueva', (
    tester,
  ) async {
    final old = Completer<InstitutionDirectoryPageData>();
    final repo = FakeDirectory()
      ..load = (q, page) => q.isEmpty
          ? old.future
          : Future.value(
              InstitutionDirectoryPageData(
                items: const [PublicInstitution(id: 'new', name: 'Nuevo')],
                page: 1,
                hasMore: false,
              ),
            );
    await mount(tester, repo);
    await tester.pump();
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    await tester.enterText(find.byType(TextField), 'Nuevo');
    await tester.tap(find.text('Buscar'));
    await tester.pumpAndSettle();
    old.complete(
      const InstitutionDirectoryPageData(
        items: [PublicInstitution(id: 'old', name: 'Viejo')],
        page: 1,
        hasMore: false,
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Nuevo'), findsWidgets);
    expect(find.text('Viejo'), findsNothing);
  });
  testWidgets('demo identificada y búsqueda vacía explícita', (tester) async {
    await mount(tester, DemoInstitutionDirectoryRepository());
    await tester.pumpAndSettle();
    expect(find.textContaining('Demostración:'), findsOneWidget);
    await tester.enterText(find.byType(TextField), 'inexistente');
    await tester.tap(find.text('Buscar'));
    await tester.pumpAndSettle();
    expect(
      find.text('No encontramos instituciones para esta búsqueda.'),
      findsOneWidget,
    );
  });
}
