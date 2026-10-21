// Opt-in host Flutter VM test against the disposable Docker session, not Android.
import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:saber_plus/core/media/editorial_image_reference.dart';
import 'package:saber_plus/core/media/remote_editorial_image_repository.dart';
import 'package:saber_plus/core/network/access_token_store.dart';
import 'package:saber_plus/core/network/auth_interceptor.dart';

void main() {
  // Deliberately no widget binding: it replaces real HTTP with synthetic 400s.
  final directory = Platform.environment['SABERPLUS_LOCAL_SESSION'];
  late Dio dio;
  late Map<String, dynamic> fixture;
  late RemoteEditorialImageRepository repository;

  setUpAll(() async {
    if (directory == null) return;
    final resolved = await Directory(directory).resolveSymbolicLinks();
    final root = await Directory.systemTemp.resolveSymbolicLinks();
    expect(Directory(resolved).parent.path, root);
    expect(
      resolved.split(Platform.pathSeparator).last,
      startsWith('saberplus-i2-local-'),
    );
    Future<Map<String, dynamic>> read(String name) async =>
        Map<String, dynamic>.from(
          jsonDecode(
                await File(
                  '$resolved${Platform.pathSeparator}$name',
                ).readAsString(),
              )
              as Map,
        );
    final marker = await read('owner.json');
    expect(marker['purpose'], 'saberplus-competitive-disposable-v1');
    final db = Uri.parse(marker['url'] as String);
    expect(db.host, '127.0.0.1');
    expect(db.scheme, 'postgresql');
    expect(db.path, '/postgres');
    final config = await read('flutter-private.json');
    fixture = await read('editorial-images-fixture.json');
    expect(fixture['nonce'], marker['nonce']);
    expect(fixture['api'], 'http://127.0.0.1:43187');
    expect(config['API_BASE_URL'], fixture['api']);
    dio = Dio(
      BaseOptions(
        baseUrl: fixture['api'] as String,
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 15),
      ),
    );
    final login = await dio.post<Map<String, dynamic>>(
      '/auth/login',
      data: {
        'correo': 'absent@example.invalid',
        'contrasena': config['AUTH_E2E_PASSWORD'],
      },
    );
    final tokens = AccessTokenStore()
      ..set(login.data!['accessToken'] as String);
    dio.interceptors.add(AuthInterceptor(tokens));
    repository = RemoteEditorialImageRepository(dio, tokens);
  });
  tearDownAll(() {
    if (directory != null) dio.close(force: true);
  });

  test(
    'referencia publicada llega en la práctica y entrega WEBP real',
    () async {
      final practice = await dio.get<Map<String, dynamic>>(
        '/simulacros/preguntas/${fixture['subthemeId']}',
      );
      final questions = practice.data!['preguntas'] as List;
      expect((questions.single as Map)['imagenUrl'], fixture['imagePath']);
      final bytes = await repository.load(
        EditorialImageReference.parse(fixture['imagePath'] as String),
        cancelToken: CancelToken(),
      );
      final codec = await ui.instantiateImageCodec(bytes);
      try {
        final frame = await codec.getNextFrame();
        expect(frame.image.width, 120);
        expect(frame.image.height, 60);
        frame.image.dispose();
      } finally {
        codec.dispose();
      }
    },
    skip: directory == null
        ? 'Requiere sesión Docker local propia y fixture C5-C1.'
        : false,
  );

  test(
    'archivo subido sin publicar no se entrega al estudiante',
    () async {
      await expectLater(
        repository.load(
          EditorialImageReference.parse(fixture['unpublishedPath'] as String),
          cancelToken: CancelToken(),
        ),
        throwsA(
          isA<DioException>().having(
            (e) => e.response?.statusCode,
            'status',
            404,
          ),
        ),
      );
    },
    skip: directory == null
        ? 'Requiere sesión Docker local propia y fixture C5-C1.'
        : false,
  );

  test(
    'lectura anónima rechazada incluso con referencia conocida',
    () async {
      final anonymous = Dio(BaseOptions(baseUrl: fixture['api'] as String));
      try {
        await expectLater(
          anonymous.get<void>(fixture['imagePath'] as String),
          throwsA(
            isA<DioException>().having(
              (e) => e.response?.statusCode,
              'status',
              401,
            ),
          ),
        );
      } finally {
        anonymous.close(force: true);
      }
    },
    skip: directory == null
        ? 'Requiere sesión Docker local propia y fixture C5-C1.'
        : false,
  );
}
