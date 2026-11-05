import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:saber_plus/features/institutions/domain/private_institution_evidence.dart';
import 'package:saber_plus/features/institutions/presentation/private_evidence_board.dart';
import 'package:saber_plus/features/institutions/presentation/private_evidence_controller.dart';
import 'private_evidence_controller_test.dart' show Repository, file;

void main() {
  testWidgets('PDF download and export wait for explicit consent', (
    tester,
  ) async {
    final repository = Repository();
    repository.files = [file('3bfc090f-9aa3-45ad-9f20-23dad1b41475')];
    final controller = PrivateEvidenceController(
      repository,
      isCurrent: () => true,
    );
    int exports = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: PrivateEvidenceBoard(
          controller: controller,
          pick: () async => null,
          export: (_, _) async {
            exports++;
            return true;
          },
        ),
      ),
    );
    await tester.pumpAndSettle();
    final button = find.text('Exportar copia');
    await tester.scrollUntilVisible(button, 150);
    await tester.tap(button);
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.textContaining('antivirus'), findsOneWidget);
    expect(repository.downloads, 0);
    expect(exports, 0);
    await tester.tap(find.text('Cancelar'));
    await tester.pumpAndSettle();
    expect(repository.downloads, 0);
    await tester.tap(button);
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(find.text('Elegir destino'));
    await tester.pumpAndSettle();
    expect(repository.downloads, 1);
    expect(exports, 1);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    controller.dispose();
  });

  testWidgets('withdrawing a file waits for confirmation', (tester) async {
    final repository = Repository();
    repository.receipt = file('3bfc090f-9aa3-45ad-9f20-23dad1b41475');
    repository.files = [repository.receipt!];
    final controller = PrivateEvidenceController(
      repository,
      isCurrent: () => true,
    );
    await tester.pumpWidget(
      MaterialApp(
        home: PrivateEvidenceBoard(
          controller: controller,
          pick: () async => null,
          export: (_, _) async => true,
        ),
      ),
    );
    await tester.pumpAndSettle();
    final button = find.text('Retirar adjunto');
    await tester.scrollUntilVisible(button, 150);
    await tester.tap(button);
    await tester.pump(const Duration(milliseconds: 300));
    expect(repository.removals, 0);
    await tester.tap(find.text('Cancelar'));
    await tester.pumpAndSettle();
    expect(repository.removals, 0);
    await tester.tap(button);
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(find.widgetWithText(FilledButton, 'Retirar'));
    await tester.pumpAndSettle();
    expect(repository.removals, 1);
    expect(controller.message, contains('limpieza física'));
    await tester.pumpWidget(const SizedBox());
    controller.dispose();
  });
  for (final size in [const Size(375, 812), const Size(844, 390)]) {
    for (final dark in [false, true]) {
      testWidgets(
        'selection and explicit upload at $size dark=$dark text 200%',
        (tester) async {
          tester.view.physicalSize = size;
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);
          final repository = Repository();
          final controller = PrivateEvidenceController(
            repository,
            isCurrent: () => true,
          );
          await tester.pumpWidget(
            MaterialApp(
              theme: ThemeData(
                brightness: dark ? Brightness.dark : Brightness.light,
              ),
              builder: (context, child) => MediaQuery(
                data: MediaQuery.of(context).copyWith(
                  textScaler: const TextScaler.linear(2),
                  disableAnimations: true,
                ),
                child: child!,
              ),
              home: PrivateEvidenceBoard(
                controller: controller,
                pick: () async => InstitutionEvidenceDraft(Uint8List(5)),
                export: (_, _) async => true,
              ),
            ),
          );
          await tester.pumpAndSettle();
          final select = find.text('Seleccionar archivo');
          await tester.scrollUntilVisible(select, 150);
          await tester.tap(select);
          await tester.pumpAndSettle();
          expect(repository.operations, isEmpty);
          final upload = find.text('Subir adjunto privado');
          await tester.scrollUntilVisible(upload, 150);
          await tester.tap(upload);
          await tester.pumpAndSettle();
          expect(repository.operations, hasLength(1));
          expect(controller.pending, isFalse);
          expect(tester.takeException(), isNull);
          await tester.pumpWidget(const SizedBox());
          controller.dispose();
        },
      );
    }
  }
}
