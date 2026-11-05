// Opt-in Flutter VM/HTTP contract test, NOT native picker/UI or Android QA.
// Configuration comes only from the owned runner's temporary private JSON.
import 'dart:convert';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:saber_plus/core/network/api_error.dart';
import 'package:saber_plus/features/institutions/domain/private_institution_evidence.dart';
import 'package:saber_plus/features/institutions/domain/student_institution_request.dart';
import 'package:saber_plus/features/institutions/data/private_institution_evidence_repository.dart';
import 'package:saber_plus/features/profile/domain/private_profile_photo.dart';
import 'package:saber_plus/features/profile/data/remote_private_profile_photo_repository.dart';

const enabled = bool.fromEnvironment('C5_PRIVATE_FILES_HTTP_ENABLED');
const marker = String.fromEnvironment('C5_PRIVATE_FILES_TEST_OWNER');
const api = String.fromEnvironment('C5_PRIVATE_FILES_TEST_API');
const teacher = String.fromEnvironment('C5_PRIVATE_FILES_TEACHER_EMAIL');
const student = String.fromEnvironment('C5_PRIVATE_FILES_STUDENT_EMAIL');
const password = String.fromEnvironment('C5_PRIVATE_FILES_PASSWORD');
const request = String.fromEnvironment('C5_PRIVATE_FILES_REQUEST_ID');

void main() {
  late Dio teacherDio, studentDio;
  final clients = <Dio>[];
  setUpAll(() async {
    if (!enabled) return;
    final uri = Uri.tryParse(api);
    if (marker != 'saberplus-c5-private-files-http-v1' ||
        uri == null ||
        uri.scheme != 'http' ||
        uri.host != '127.0.0.1' ||
        uri.port < 1024 ||
        uri.userInfo.isNotEmpty ||
        uri.path.isNotEmpty ||
        uri.hasQuery ||
        uri.hasFragment ||
        teacher != 'teacher@example.invalid' ||
        student != 'student@example.invalid' ||
        !RegExp(r'^[a-f0-9]{36}$').hasMatch(password) ||
        !isInstitutionEvidenceId(request)) {
      throw StateError(
        'Requires a fresh owned C5 disposable loopback fixture.',
      );
    }
    Future<Dio> login(String email, String role) async {
      final dio = Dio(
        BaseOptions(
          baseUrl: api,
          connectTimeout: const Duration(seconds: 15),
          receiveTimeout: const Duration(seconds: 60),
          followRedirects: false,
          headers: {
            'Accept': 'application/json',
            'X-SaberPlus-Client': 'mobile',
            'X-Device-Id': 'c5-private-http-${newStudentRequestId()}',
          },
        ),
      );
      clients.add(dio);
      try {
        final result = await dio.post<Object?>(
          '/auth/login',
          data: {'correo': email, 'contrasena': password},
        );
        final body = result.data;
        if (body is! Map<String, dynamic> || body['accessToken'] is! String) {
          throw StateError('Synthetic login failed');
        }
        dio.options.headers['Authorization'] = 'Bearer ${body['accessToken']}';
        final profile = (await dio.get<Map<String, dynamic>>(
          '/auth/perfil',
        )).data;
        if (profile?['rol'] != role ||
            profile?['correo'] != email ||
            profile?['debeCambiarContrasena'] != false) {
          throw StateError('Synthetic account scope not confirmed');
        }
        return dio;
      } catch (_) {
        dio.close(force: true);
        // Never print login payload, token, fixture password or raw response.
        throw StateError(
          'Could not confirm the owned synthetic session; details suppressed.',
        );
      }
    }

    teacherDio = await login(teacher, 'PROFESOR');
    studentDio = await login(student, 'ESTUDIANTE');
  });
  tearDownAll(() {
    for (final client in clients) {
      client.close(force: true);
    }
  });

  test(
    'owned real API: lost evidence acknowledgements reconcile without duplicate uploads',
    () async {
      final repo = RemotePrivateInstitutionEvidenceRepository(
        teacherDio,
        request,
        isCurrent: () => true,
      );
      final stranger = RemotePrivateInstitutionEvidenceRepository(
        studentDio,
        request,
        isCurrent: () => true,
      );
      addTearDown(repo.dispose);
      addTearDown(stranger.dispose);
      final initial = await repo.load();
      expect(initial.canUpload, isTrue);
      expect(initial.files, isEmpty);
      var loseUpload = true, loseDelete = true;
      final interceptor = InterceptorsWrapper(
        onResponse: (response, handler) {
          final options = response.requestOptions;
          if ((options.method == 'POST' &&
                  options.path == institutionEvidencePath(request) &&
                  loseUpload) ||
              (options.method == 'DELETE' &&
                  options.path.startsWith(institutionEvidencePath(request)) &&
                  loseDelete)) {
            if (options.method == 'POST') {
              loseUpload = false;
            } else {
              loseDelete = false;
            }
            handler.reject(
              DioException(
                requestOptions: options,
                type: DioExceptionType.connectionError,
                message:
                    'Synthetic acknowledgement suppressed after real server commit.',
              ),
            );
          } else {
            handler.next(response);
          }
        },
      );
      teacherDio.interceptors.add(interceptor);
      addTearDown(() => teacherDio.interceptors.remove(interceptor));
      final operation = newStudentRequestId();
      final pdf = Uint8List.fromList(
        ascii.encode('%PDF-1.7\nC5 VM synthetic document\n%%EOF'),
      );
      final draft = InstitutionEvidenceDraft(pdf);
      await expectLater(
        repo.upload(operation, initial.revision, draft),
        throwsA(isA<ApiError>()),
      );
      final saved = await repo.operation(operation);
      expect(saved.state, InstitutionEvidenceState.active);
      expect(saved.available, isTrue);
      expect((await repo.load()).files.length, 1);
      final replay = await repo.upload(operation, initial.revision, draft);
      expect(replay.id, saved.id);
      expect(replay.revision, saved.revision);
      expect(await repo.content(saved), pdf);
      await expectLater(stranger.load(), throwsA(isA<ApiError>()));
      await expectLater(stranger.content(saved), throwsA(isA<ApiError>()));
      await expectLater(
        repo.remove(saved.id, saved.revision),
        throwsA(isA<ApiError>()),
      );
      expect(
        (await repo.operation(operation)).state,
        InstitutionEvidenceState.retired,
      );
      expect((await repo.load()).files, isEmpty);
      await expectLater(repo.content(saved), throwsA(isA<ApiError>()));
      expect(
        (await repo.upload(operation, initial.revision, draft)).state,
        InstitutionEvidenceState.retired,
      );
    },
    skip: !enabled,
  );

  test(
    'owned real API: profile photo roundtrip stays private and is removable',
    () async {
      final owner = RemotePrivateProfilePhotoRepository(studentDio);
      final stranger = RemotePrivateProfilePhotoRepository(teacherDio);
      addTearDown(owner.dispose);
      addTearDown(stranger.dispose);
      final initial = await owner.load();
      expect(initial.fileId, isNull);
      // Generated locally with Sharp: 24x12 solid teal, no personal metadata/image.
      final png = base64Decode(
        'iVBORw0KGgoAAAANSUhEUgAAABgAAAAMCAIAAAD3UuoiAAAACXBIWXMAAAPoAAAD6AG1e1JrAAAAHElEQVQokWNgaGigDmIYNahhNIwaRtNRA65AAABQQCAQ9cz7uAAAAABJRU5ErkJggg==',
      );
      final operation = newStudentRequestId();
      final saved = await owner.upload(operation, initial.revision, png);
      expect(saved.state, PrivatePhotoOperationState.active);
      final bytes = await owner.content(saved.photo);
      expect(ascii.decode(bytes.sublist(0, 4)), 'RIFF');
      expect(ascii.decode(bytes.sublist(8, 12)), 'WEBP');
      expect(
        (await owner.upload(operation, initial.revision, png)).id,
        saved.id,
      );
      await expectLater(
        stranger.content(saved.photo),
        throwsA(isA<ApiError>()),
      );
      final profile = (await studentDio.get<Map<String, dynamic>>(
        '/auth/perfil',
      )).data;
      expect(profile?['fotoPerfil'], isNull);
      final removed = await owner.remove(saved.photo.revision);
      expect(removed.photo.fileId, isNull);
      expect(removed.cleanupPending, isFalse);
      await expectLater(owner.content(saved.photo), throwsA(isA<ApiError>()));
    },
    skip: !enabled,
  );
}
