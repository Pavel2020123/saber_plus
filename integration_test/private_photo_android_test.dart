// Real Android image-only selector and private-photo screen/API, synthetic only.
import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:saber_plus/app/theme.dart';
import 'package:saber_plus/core/network/api_error.dart';
import 'package:saber_plus/features/institutions/data/private_document_access.dart';
import 'package:saber_plus/features/institutions/domain/private_institution_evidence.dart';
import 'package:saber_plus/features/institutions/domain/student_institution_request.dart';
import 'package:saber_plus/features/profile/data/remote_private_profile_photo_repository.dart';
import 'package:saber_plus/features/profile/presentation/private_profile_photo_board.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets(
    'Android photo image selection, own-only read and confirmed removal',
    (tester) async {
      const api = String.fromEnvironment('C5_PRIVATE_FILES_TEST_API');
      const password = String.fromEnvironment('C5_PRIVATE_FILES_PASSWORD');
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
      expect(RegExp(r'^[a-f0-9]{36}$').hasMatch(password), isTrue);
      final clients = <Dio>[];
      addTearDown(() {
        for (final dio in clients) {
          dio.close(force: true);
        }
      });
      Future<Dio> login(String email) async {
        final dio = Dio(
          BaseOptions(
            baseUrl: api,
            followRedirects: false,
            connectTimeout: const Duration(seconds: 15),
            receiveTimeout: const Duration(seconds: 60),
            headers: {
              'Accept': 'application/json',
              'X-SaberPlus-Client': 'mobile',
              'X-Device-Id': 'c5-photo-android-${newStudentRequestId()}',
            },
          ),
        );
        clients.add(dio);
        final response = await dio.post<Map<String, dynamic>>(
          '/auth/login',
          data: {'correo': email, 'contrasena': password},
        );
        expect(response.data?['accessToken'], isA<String>());
        dio.options.headers['Authorization'] =
            'Bearer ${response.data!['accessToken']}';
        return dio;
      }

      final student = await login('student@example.invalid');
      final teacher = await login('teacher@example.invalid');
      final owner = RemotePrivateProfilePhotoRepository(student);
      final stranger = RemotePrivateProfilePhotoRepository(teacher);
      addTearDown(owner.dispose);
      addTearDown(stranger.dispose);
      final before = await owner.load();
      expect(before.fileId, isNull);
      final png = base64Decode(
        'iVBORw0KGgoAAAANSUhEUgAAABgAAAAMCAIAAAD3UuoiAAAACXBIWXMAAAPoAAAD6AG1e1JrAAAAHElEQVQokWNgaGigDmIYNahhNIwaRtNRA65AAABQQCAQ9cz7uAAAAABJRU5ErkJggg==',
      );
      final seed = await owner.upload(
        newStudentRequestId(),
        before.revision,
        png,
      );
      final webp = await owner.content(seed.photo);
      final access = PrivateDocumentAccess(
        enabled: true,
        isCurrent: () => true,
      );
      addTearDown(access.dispose);
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Center(child: Text('SaberPlus · imagen sintética de prueba')),
          ),
        ),
      );
      await tester.pumpAndSettle();
      debugPrint('C5_PHOTO_SAVE_SYNTHETIC_WEBP');
      expect(
        await access.exportFile(
          InstitutionEvidenceFile(
            requestId: 'd9ac5e51-de18-46ce-b596-b62a97d1ac91',
            id: seed.id,
            operationId: seed.operationId,
            revision: 1,
            state: InstitutionEvidenceState.active,
            mime: 'image/webp',
            bytes: webp.length,
            available: true,
            cleanupPending: false,
          ),
          webp,
          confirmed: true,
        ),
        isTrue,
      );
      await owner.remove(seed.photo.revision);
      final profile = (await student.get<Map<String, dynamic>>(
        '/auth/perfil',
      )).data!;
      final userId = profile['id'] as String;
      expect(profile['fotoPerfil'], isNull);
      await tester.pumpWidget(
        MaterialApp(
          theme: SaberPlusTheme.light,
          home: PrivateProfilePhotoBoard(
            userId: userId,
            repository: owner,
            pick: () {
              debugPrint('C5_PHOTO_PICK_IMAGE_ONLY');
              return access.pickImage();
            },
          ),
        ),
      );
      Future<void> until(bool Function() condition) async {
        final watch = Stopwatch()..start();
        while (!condition()) {
          if (watch.elapsed > const Duration(minutes: 2)) {
            fail('C5 photo Android stage timed out');
          }
          await tester.pump(const Duration(milliseconds: 200));
        }
        await tester.pump(const Duration(milliseconds: 300));
      }

      Future<void> tapKey(String key) async {
        final finder = find.byKey(Key(key));
        await until(
          () =>
              finder.evaluate().isNotEmpty &&
              tester.widget<ButtonStyleButton>(finder).onPressed != null,
        );
        await tester.ensureVisible(finder);
        await tester.tap(finder);
        await tester.pump(const Duration(milliseconds: 300));
      }

      await tapKey('private-photo-pick');
      await tapKey('private-photo-save');
      await until(
        () =>
            find.byKey(const Key('private-photo-remove')).evaluate().isNotEmpty,
      );
      final saved = await owner.load();
      expect(saved.fileId, isNotNull);
      expect(saved.fileId, isNot(seed.id));
      final content = await owner.content(saved);
      expect(ascii.decode(content.sublist(0, 4)), 'RIFF');
      expect(ascii.decode(content.sublist(8, 12)), 'WEBP');
      await expectLater(stranger.content(saved), throwsA(isA<ApiError>()));
      expect(
        (await student.get<Map<String, dynamic>>(
          '/auth/perfil',
        )).data!['fotoPerfil'],
        isNull,
      );
      debugPrint('C5_PHOTO_OWN_ONLY_CONFIRMED');
      await tapKey('private-photo-remove');
      await tester.tap(find.widgetWithText(FilledButton, 'Quitar foto'));
      await until(
        () =>
            find.text('Tu foto privada quedó retirada.').evaluate().isNotEmpty,
      );
      expect((await owner.load()).fileId, isNull);
      await expectLater(owner.content(saved), throwsA(isA<ApiError>()));
      expect(tester.takeException(), isNull);
      debugPrint('C5_PHOTO_ANDROID_COMPLETE');
    },
    timeout: const Timeout(Duration(minutes: 10)),
  );
}
