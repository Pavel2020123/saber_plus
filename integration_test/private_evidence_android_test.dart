// Opt-in owned loopback fixture; actual Android selectors, screen and API.
import 'dart:io';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:saber_plus/app/theme.dart';
import 'package:saber_plus/core/network/api_error.dart';
import 'package:saber_plus/features/institutions/data/private_document_access.dart';
import 'package:saber_plus/features/institutions/data/private_institution_evidence_repository.dart';
import 'package:saber_plus/features/institutions/domain/private_institution_evidence.dart';
import 'package:saber_plus/features/institutions/presentation/private_evidence_board.dart';
import 'package:saber_plus/features/institutions/presentation/private_evidence_controller.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets(
    'Android real selectors, private evidence UI and owned API roundtrip',
    (tester) async {
      const api = String.fromEnvironment('C5_PRIVATE_FILES_TEST_API');
      const password = String.fromEnvironment('C5_PRIVATE_FILES_PASSWORD');
      const request = String.fromEnvironment('C5_PRIVATE_FILES_REQUEST_ID');
      expect(Platform.isAndroid, isTrue);
      expect(
        const bool.fromEnvironment('C5_PRIVATE_FILES_HTTP_ENABLED'),
        isTrue,
      );
      expect(
        const String.fromEnvironment('C5_PRIVATE_FILES_TEST_OWNER'),
        'saberplus-c5-private-files-http-v1',
      );
      expect(api, 'http://127.0.0.1:43188');
      expect(
        const String.fromEnvironment('C5_PRIVATE_FILES_TEACHER_EMAIL'),
        'teacher@example.invalid',
      );
      expect(RegExp(r'^[a-f0-9]{36}$').hasMatch(password), isTrue);
      expect(isInstitutionEvidenceId(request), isTrue);
      expect(privateInstitutionEvidenceEnabled, isTrue);
      final dio = Dio(
        BaseOptions(
          baseUrl: api,
          connectTimeout: const Duration(seconds: 15),
          receiveTimeout: const Duration(seconds: 60),
          followRedirects: false,
          headers: {
            'Accept': 'application/json',
            'X-SaberPlus-Client': 'mobile',
            'X-Device-Id': 'c5-android-evidence-fixture',
          },
        ),
      );
      addTearDown(() => dio.close(force: true));
      final login = await dio.post<Map<String, dynamic>>(
        '/auth/login',
        data: {'correo': 'teacher@example.invalid', 'contrasena': password},
      );
      expect(login.data?['accessToken'], isA<String>());
      dio.options.headers['Authorization'] =
          'Bearer ${login.data!['accessToken']}';
      bool current = true;
      final repository = RemotePrivateInstitutionEvidenceRepository(
        dio,
        request,
        isCurrent: () => current,
      );
      final controller = PrivateEvidenceController(
        repository,
        isCurrent: () => current,
      );
      final access = PrivateDocumentAccess(isCurrent: () => current);
      addTearDown(() {
        current = false;
        access.dispose();
        controller.dispose();
        repository.dispose();
      });
      final initial = await repository.load();
      expect(initial.files, isEmpty);
      expect(initial.canUpload, isTrue);
      final bytes = Uint8List.fromList(
        '%PDF-1.7\nC5 Android synthetic document\n%%EOF'.codeUnits,
      );
      final seed = InstitutionEvidenceFile(
        requestId: request,
        id: 'e902e956-dbb5-4c91-ae4f-425ee6bc7db8',
        operationId: '3bfc090f-9aa3-45ad-9f20-23dad1b41475',
        revision: 1,
        state: InstitutionEvidenceState.active,
        mime: 'application/pdf',
        bytes: bytes.length,
        available: true,
        cleanupPending: false,
      );
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Center(
              child: Text('SaberPlus · documento sintético de prueba'),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      debugPrint('C5_ROUNDTRIP_SAVE_SEED');
      expect(await access.exportFile(seed, bytes, confirmed: true), isTrue);
      debugPrint('C5_ROUNDTRIP_SEED_SAVED');
      await tester.pumpWidget(
        MaterialApp(
          theme: SaberPlusTheme.light,
          home: PrivateEvidenceBoard(
            controller: controller,
            pick: () {
              debugPrint('C5_ROUNDTRIP_PICK_SEED');
              return access.pick();
            },
            export: (file, content) {
              debugPrint('C5_ROUNDTRIP_EXPORT_DOWNLOADED');
              expect(content, orderedEquals(bytes));
              return access.exportFile(file, content, confirmed: true);
            },
          ),
        ),
      );
      Future<void> until(bool Function() condition) async {
        final watch = Stopwatch()..start();
        while (!condition()) {
          if (watch.elapsed > const Duration(minutes: 2)) {
            fail('C5 Android stage timed out');
          }
          await tester.pump(const Duration(milliseconds: 200));
        }
        await tester.pump(const Duration(milliseconds: 300));
      }

      Future<void> tap(String text) async {
        final finder = find.text(text);
        await tester.scrollUntilVisible(finder, 150);
        await tester.tap(finder);
        await tester.pump(const Duration(milliseconds: 300));
      }

      await until(() => controller.listing != null && !controller.busy);
      await tap('Seleccionar archivo');
      await until(() => controller.draft != null);
      expect(controller.draft!.bytes, orderedEquals(bytes));
      await tap('Subir adjunto privado');
      await until(
        () => !controller.busy && controller.listing!.files.length == 1,
      );
      final saved = controller.listing!.files.single;
      expect(await repository.content(saved), orderedEquals(bytes));
      debugPrint('C5_ROUNDTRIP_API_SAVED');
      await tap('Exportar copia');
      await tester.tap(find.text('Elegir destino'));
      await tester.pump(const Duration(milliseconds: 300));
      await until(
        () => find
            .text('Copia exportada. Consérvala en un lugar seguro.')
            .evaluate()
            .isNotEmpty,
      );
      await tap('Retirar adjunto');
      await tester.tap(find.widgetWithText(FilledButton, 'Retirar'));
      await until(() => !controller.busy && controller.listing!.files.isEmpty);
      expect(
        (await repository.operation(saved.operationId)).state,
        InstitutionEvidenceState.retired,
      );
      await expectLater(repository.content(saved), throwsA(isA<ApiError>()));
      expect(tester.takeException(), isNull);
      debugPrint('C5_ROUNDTRIP_COMPLETE');
    },
    timeout: const Timeout(Duration(minutes: 10)),
  );
}
