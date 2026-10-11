import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:saber_plus/features/institutions/data/institution_territory_repository.dart';
import 'package:saber_plus/features/institutions/presentation/institution_territory_field.dart';

class DelayedTerritory extends DemoInstitutionTerritoryRepository {
  final pending = Completer<TerritoryCatalogPage>();
  @override
  Future<TerritoryCatalogPage> municipalities(
    String department, {
    CancelToken? cancelToken,
  }) => department == '91'
      ? pending.future
      : super.municipalities(department, cancelToken: cancelToken);
}

void main() {
  test(
    'catalog preserves leading zero and rejects duplicate/mismatched codes',
    () {
      final row = {
        'codigo': '05001',
        'nombre': 'Medellín',
        'departamentoCodigo': '05',
        'tipo': 'MUNICIPIO',
      };
      Map<String, Object> page(List<Object> rows) => {
        'version': 'v1',
        'departamentoCodigo': '05',
        'municipios': rows,
      };
      expect(
        TerritoryCatalogPage.parse(
          page([row]),
          department: '05',
        ).options.single.code,
        '05001',
      );
      expect(
        () => TerritoryCatalogPage.parse(page([row, row]), department: '05'),
        throwsFormatException,
      );
      expect(
        () => TerritoryCatalogPage.parse(
          page([
            {...row, 'codigo': 5001},
          ]),
          department: '05',
        ),
        throwsFormatException,
      );
      expect(
        () => TerritoryCatalogPage.parse(page([row]), department: '11'),
        throwsFormatException,
      );
    },
  );
  test('remote uses protected catalog paths without demo fallback', () async {
    final dio = Dio();
    final paths = <String>[];
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (request, handler) {
          paths.add(request.path);
          handler.resolve(
            Response(
              requestOptions: request,
              data: {
                'version': 'v1',
                'departamentos': [
                  {'codigo': '05', 'nombre': 'Antioquia'},
                ],
              },
            ),
          );
        },
      ),
    );
    final repo = RemoteInstitutionTerritoryRepository(dio);
    expect((await repo.departments()).options.single.code, '05');
    expect(paths.single, '/instituciones/territorio/departamentos');
    expect(() => repo.municipalities('5'), throwsFormatException);
    await expectLater(repo.municipalities('05'), throwsFormatException);
    expect(paths.last, '/instituciones/territorio/departamentos/05/municipios');
  });
  testWidgets(
    'restores selection, clears municipality and ignores late response',
    (tester) async {
      final repo = DelayedTerritory();
      InstitutionTerritorySelection? selected;
      final form = GlobalKey<FormState>();
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Form(
              key: form,
              child: InstitutionTerritoryField(
                repository: repo,
                initialDepartment: '11',
                initialMunicipality: '11001',
                onChanged: (value) => selected = value,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(selected?.municipality.code, '11001');
      expect(form.currentState!.validate(), true);
      void choose(String code) => tester
          .widget<DropdownButtonFormField<String>>(
            find.byType(DropdownButtonFormField<String>).first,
          )
          .onChanged!(code);
      choose('91');
      await tester.pump();
      expect(selected, null);
      expect(form.currentState!.validate(), false);
      choose('20');
      await tester.pumpAndSettle();
      tester
          .widget<DropdownButtonFormField<String>>(
            find.byType(DropdownButtonFormField<String>).last,
          )
          .onChanged!('20001');
      await tester.pumpAndSettle();
      repo.pending.complete(
        await DemoInstitutionTerritoryRepository().municipalities('91'),
      );
      await tester.pumpAndSettle();
      expect(selected?.municipality.code, '20001');
      expect(form.currentState!.validate(), true);
      expect(tester.takeException(), null);
    },
  );
}
