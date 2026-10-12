import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:saber_plus/features/institutions/domain/institution_directory.dart';
import 'package:saber_plus/features/institutions/presentation/institution_directory_page.dart';
import 'package:saber_plus/features/institutions/presentation/institution_directory_providers.dart';

void main() {
  test('la descripción es opcional para servidores anteriores', () {
    expect(
      PublicInstitution.fromJson({'id': 'i', 'nombre': 'Colegio'}).description,
      isNull,
    );
  });
  test('no utiliza mensajes privados antiguos como presentación', () {
    expect(
      PublicInstitution.fromJson({
        'id': 'i',
        'nombre': 'Colegio',
        'mensajeBienvenida': 'Código privado',
      }).description,
      isNull,
    );
  });
  test('lee la descripción incluso sin ubicación', () {
    expect(
      PublicInstitution.fromJson({
        'id': 'i',
        'nombre': 'Colegio',
        'descripcion': 'Presentación',
      }).description,
      'Presentación',
    );
  });
  for (final invalid in [42, true, <String, String>{}, 'x' * 501]) {
    test('rechaza descripción fuera de contrato ${invalid.runtimeType}', () {
      expect(
        () => PublicInstitution.fromJson({
          'id': 'i',
          'nombre': 'Colegio',
          'descripcion': invalid,
        }),
        throwsFormatException,
      );
    });
  }
  testWidgets('ficha muestra texto público literal sin ejecutar marcado', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          institutionDirectoryDetailProvider('i').overrideWith(
            (ref) async => const PublicInstitution(
              id: 'i',
              name: 'Colegio',
              description: '<b>Educación</b>',
            ),
          ),
        ],
        child: const MaterialApp(home: InstitutionDirectoryDetailPage(id: 'i')),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Sobre la institución'), findsOneWidget);
    expect(find.text('<b>Educación</b>'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
  testWidgets('ficha vacía no inventa una presentación', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          institutionDirectoryDetailProvider('i').overrideWith(
            (ref) async => const PublicInstitution(id: 'i', name: 'Colegio'),
          ),
        ],
        child: const MaterialApp(home: InstitutionDirectoryDetailPage(id: 'i')),
      ),
    );
    await tester.pumpAndSettle();
    expect(
      find.text(
        'Esta institución todavía no ha añadido una presentación pública.',
      ),
      findsOneWidget,
    );
  });
}
