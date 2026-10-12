import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:saber_plus/features/institutions/domain/institution_profile.dart';
import 'package:saber_plus/features/institutions/presentation/institution_profile_page.dart';

class ProfileFake implements InstitutionProfileRepository {
  InstitutionProfile profile = const InstitutionProfile(
    id: 'i',
    name: 'Colegio',
    description: 'Anterior',
    revision: 0,
    canEdit: true,
  );
  bool failSave = false, failLoad = false;
  int saves = 0;
  Completer<InstitutionProfile>? pending;
  @override
  Future<InstitutionProfile> load() async {
    if (failLoad) throw Exception('offline');
    return profile;
  }

  @override
  Future<InstitutionProfile> save(
    InstitutionProfile current,
    String text,
  ) async {
    saves++;
    if (pending != null) return pending!.future;
    if (failSave) throw Exception('409');
    return profile = InstitutionProfile(
      id: 'i',
      name: 'Colegio',
      description: text.trim().isEmpty ? null : text.trim(),
      revision: current.revision + 1,
      canEdit: true,
    );
  }
}

void main() {
  testWidgets('salir con borrador exige confirmación y permite cancelar', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => InstitutionProfileEditor(
                    repository: ProfileFake(),
                    onSaved: (_) {},
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
    await tester.tap(find.text('Editar presentación'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'Borrador');
    await tester.pump();
    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.text('¿Salir del editor?'), findsOneWidget);
    await tester.tap(find.text('Seguir editando'));
    await tester.pumpAndSettle();
    expect(
      tester.widget<TextField>(find.byType(TextField)).controller!.text,
      'Borrador',
    );
    await tester.pageBack();
    await tester.pumpAndSettle();
    await tester.tap(find.text('Salir'));
    await tester.pumpAndSettle();
    expect(find.text('Abrir'), findsOneWidget);
  });
  Future<void> mount(
    WidgetTester tester,
    ProfileFake repo, {
    ValueChanged<String>? saved,
    bool edit = true,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        home: InstitutionProfileEditor(
          repository: repo,
          onSaved: saved ?? (_) {},
        ),
      ),
    );
    await tester.pumpAndSettle();
    if (edit && repo.profile.canEdit) {
      await tester.ensureVisible(find.text('Editar presentación'));
      await tester.tap(find.text('Editar presentación'));
      await tester.pumpAndSettle();
    }
  }

  Future<void> tapText(WidgetTester tester, String text) async {
    await tester.pump();
    final finder = find.text(text);
    await tester.ensureVisible(finder);
    await tester.pumpAndSettle();
    await tester.tap(finder);
    await tester.pumpAndSettle();
  }

  testWidgets('al abrir perfil guardado solo se edita por acción explícita', (
    tester,
  ) async {
    await mount(tester, ProfileFake(), edit: false);
    expect(find.text('Anterior'), findsOneWidget);
    expect(find.byType(TextField), findsNothing);
    expect(find.text('Guardar presentación'), findsNothing);
    await tapText(tester, 'Editar presentación');
    expect(
      tester.widget<TextField>(find.byType(TextField)).controller!.text,
      'Anterior',
    );
  });

  testWidgets('guarda y notifica invalidación de ficha', (tester) async {
    final repo = ProfileFake();
    String? saved;
    await mount(tester, repo, saved: (id) => saved = id);
    await tester.enterText(find.byType(TextField), 'Nueva presentación');
    await tapText(tester, 'Guardar presentación');
    expect(repo.profile.description, 'Nueva presentación');
    expect(saved, 'i');
    expect(find.text('Presentación pública guardada.'), findsOneWidget);
    expect(find.byType(TextField), findsNothing);
    expect(find.text('Nueva presentación'), findsOneWidget);
    expect(find.text('Guardar presentación'), findsNothing);
    expect(tester.testTextInput.isVisible, isFalse);
    await tapText(tester, 'Editar presentación');
    expect(
      tester.widget<TextField>(find.byType(TextField)).controller!.text,
      'Nueva presentación',
    );
  });
  testWidgets('fallo conserva borrador y bloquea reenvío hasta consultar', (
    tester,
  ) async {
    final repo = ProfileFake()..failSave = true;
    await mount(tester, repo);
    await tester.enterText(find.byType(TextField), 'Mi borrador');
    await tapText(tester, 'Guardar presentación');
    expect(
      tester.widget<TextField>(find.byType(TextField)).controller!.text,
      'Mi borrador',
    );
    expect(
      tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
      isNull,
    );
    repo.failLoad = true;
    await tapText(tester, 'Consultar versión actual');
    expect(
      find.text('No pudimos cargar el perfil. Tu texto no se ha descartado.'),
      findsOneWidget,
    );
    expect(
      tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
      isNull,
    );
    repo.failLoad = false;
    repo.profile = const InstitutionProfile(
      id: 'i',
      name: 'Colegio',
      description: 'Cambio de otro editor',
      revision: 1,
      canEdit: true,
    );
    await tapText(tester, 'Consultar versión actual');
    expect(
      tester.widget<TextField>(find.byType(TextField)).controller!.text,
      'Mi borrador',
    );
    expect(find.text('Cambio de otro editor'), findsOneWidget);
    repo.failSave = false;
    await tapText(tester, 'Guardar presentación');
    expect(repo.profile.revision, 2);
    expect(repo.saves, 2);
  });
  testWidgets('docente no propietario solo lee', (tester) async {
    final repo = ProfileFake()
      ..profile = const InstitutionProfile(
        id: 'i',
        name: 'Colegio',
        description: 'Texto',
        revision: 1,
        canEdit: false,
      );
    await mount(tester, repo);
    expect(find.byType(TextField), findsNothing);
    expect(find.text('Texto'), findsOneWidget);
    expect(find.text('Editar presentación'), findsNothing);
    expect(find.text('Guardar presentación'), findsNothing);
  });
  testWidgets('permite vaciar descripción', (tester) async {
    final repo = ProfileFake();
    await mount(tester, repo);
    await tester.enterText(find.byType(TextField), '');
    await tapText(tester, 'Guardar presentación');
    expect(repo.profile.description, isNull);
    expect(
      find.text('Todavía no hay una presentación pública.'),
      findsOneWidget,
    );
    expect(find.byType(TextField), findsNothing);
  });
  testWidgets('respuesta posterior a desmontar no actualiza ficha', (
    tester,
  ) async {
    final repo = ProfileFake()..pending = Completer<InstitutionProfile>();
    var notified = false;
    await mount(tester, repo, saved: (_) => notified = true);
    await tester.enterText(find.byType(TextField), 'Nuevo');
    await tester.pump();
    await tester.ensureVisible(find.text('Guardar presentación'));
    await tester.tap(find.text('Guardar presentación'));
    await tester.pump();
    await tester.pumpWidget(const SizedBox());
    repo.pending!.complete(repo.profile);
    await tester.pump();
    expect(notified, isFalse);
    expect(tester.takeException(), isNull);
  });
  testWidgets('pantalla estrecha con texto grande no desborda', (tester) async {
    tester.view.physicalSize = const Size(320, 700);
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
        home: InstitutionProfileEditor(
          repository: ProfileFake(),
          onSaved: (_) {},
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}
