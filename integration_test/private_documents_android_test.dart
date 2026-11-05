// Real Android OS intents, no mocked MethodChannel or personal account/files.
// Host cancels each observed DocumentsUI chooser; no broad storage permission.
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:saber_plus/features/institutions/data/private_document_access.dart';
import 'package:saber_plus/features/institutions/domain/private_institution_evidence.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets('Android private document picker and export cancellation', (
    tester,
  ) async {
    expect(Platform.isAndroid, isTrue);
    expect(const bool.fromEnvironment('C5_PRIVATE_DOCUMENTS_ANDROID'), isTrue);
    expect(privateInstitutionEvidenceEnabled, isTrue);
    final access = PrivateDocumentAccess(isCurrent: () => true);
    addTearDown(access.dispose);
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SafeArea(
            child: Center(
              child: Text('SaberPlus · prueba de documentos sintéticos'),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    debugPrint('C5_NATIVE_STAGE_PICK_CANCEL');
    final selection = await access.pick();
    expect(selection, isNull);
    debugPrint('C5_NATIVE_PICK_CANCEL_CONFIRMED');
    final bytes = Uint8List.fromList(
      '%PDF-1.7\nSynthetic cancellation fixture\n%%EOF'.codeUnits,
    );
    final file = InstitutionEvidenceFile(
      requestId: 'd9ac5e51-de18-46ce-b596-b62a97d1ac91',
      id: 'e902e956-dbb5-4c91-ae4f-425ee6bc7db8',
      operationId: '3bfc090f-9aa3-45ad-9f20-23dad1b41475',
      revision: 1,
      state: InstitutionEvidenceState.active,
      mime: 'application/pdf',
      bytes: bytes.length,
      available: true,
      cleanupPending: false,
    );
    debugPrint('C5_NATIVE_STAGE_EXPORT_CANCEL');
    expect(await access.exportFile(file, bytes, confirmed: true), isFalse);
    debugPrint('C5_NATIVE_EXPORT_CANCEL_CONFIRMED');
    // A second picker also proves the previous native gate has been released.
    debugPrint('C5_NATIVE_STAGE_PICK_AGAIN_CANCEL');
    expect(await access.pick(), isNull);
    debugPrint('C5_NATIVE_CANCEL_FLOW_COMPLETE');
  }, timeout: const Timeout(Duration(minutes: 5)));
}
