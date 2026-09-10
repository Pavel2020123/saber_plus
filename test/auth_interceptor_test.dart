import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:saber_plus/core/config/environment.dart';
import 'package:saber_plus/core/network/access_token_store.dart';
import 'package:saber_plus/core/network/api_client.dart';
import 'package:saber_plus/core/network/auth_interceptor.dart';
import 'package:saber_plus/core/security/device_installation_store.dart';
import 'package:saber_plus/core/security/session_security.dart';

void main() {
  late Dio dio;
  late AccessTokenStore store;
  final requests = <RequestOptions>[];

  setUp(() {
    store = AccessTokenStore()..set('token-a');
    requests.clear();
    dio = Dio(BaseOptions(baseUrl: 'https://api.example.com'));
    dio.interceptors.add(
      AuthInterceptor(store, apiBaseUrl: dio.options.baseUrl),
    );
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          requests.add(options);
          handler.resolve(
            Response(requestOptions: options, statusCode: 200, data: const {}),
            true,
          );
        },
      ),
    );
  });
  tearDown(() => dio.close(force: true));

  test(
    'limita el token al origen configurado y desactiva redirecciones',
    () async {
      await dio.get<Object?>('/auth/perfil');
      expect(requests.single.headers['Authorization'], 'Bearer token-a');
      expect(requests.single.followRedirects, isFalse);
      for (final url in [
        'https://external.example.com/auth/perfil',
        'http://api.example.com/auth/perfil',
        'https://api.example.com:8443/auth/perfil',
        'https://user@api.example.com/auth/perfil',
      ]) {
        await expectLater(dio.get<Object?>(url), throwsA(isA<DioException>()));
      }
      expect(requests, hasLength(1));
    },
  );

  test('no conserva una cabecera Authorization después de logout', () async {
    store.clear();
    await dio.get<Object?>(
      '/auth/perfil',
      options: Options(headers: {'authorization': 'Bearer old'}),
    );
    expect(
      requests.single.headers.keys.any(
        (key) => key.toLowerCase() == 'authorization',
      ),
      isFalse,
    );
  });

  test(
    'descarta una respuesta exitosa perteneciente a una sesión anterior',
    () async {
      final arrival = Completer<RequestInterceptorHandler>();
      dio.interceptors.removeLast();
      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            requests.add(options);
            arrival.complete(handler);
          },
        ),
      );
      final future = dio.get<Object?>('/auth/perfil');
      final expectation = expectLater(
        future,
        throwsA(
          isA<DioException>().having(
            (e) => e.type,
            'cancelled',
            DioExceptionType.cancel,
          ),
        ),
      );
      final handler = await arrival.future;
      store.clear();
      store.set('token-b');
      handler.resolve(
        Response(
          requestOptions: requests.single,
          statusCode: 200,
          data: const {},
        ),
        true,
      );
      await expectation;
    },
  );

  test('un conflicto viejo no cierra la sesión nueva', () async {
    final events = <SessionSecurityEvent>[];
    final arrival = Completer<RequestInterceptorHandler>();
    dio.interceptors.removeLast();
    dio.interceptors.add(SessionSecurityInterceptor(events.add));
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          requests.add(options);
          arrival.complete(handler);
        },
      ),
    );
    final future = dio.get<Object?>('/auth/perfil');
    final expectation = expectLater(future, throwsA(isA<DioException>()));
    final handler = await arrival.future;
    store.set('token-b');
    handler.reject(
      DioException.badResponse(
        statusCode: 401,
        requestOptions: requests.single,
        response: Response(
          requestOptions: requests.single,
          statusCode: 401,
          data: {'code': 'SESSION_REPLACED'},
        ),
      ),
      true,
    );
    await expectation;
    expect(events, isEmpty);
  });

  test(
    'la inicialización lenta del dispositivo no cambia el dueño del request',
    () async {
      final deviceRead = Completer<String?>();
      final deviceReadStarted = Completer<void>();
      final container = ProviderContainer(
        overrides: [
          appConfigProvider.overrideWithValue(
            const AppConfig(
              environment: AppEnvironment.dev,
              apiBaseUrl: 'https://api.example.com',
              demoMode: false,
            ),
          ),
          accessTokenStoreProvider.overrideWithValue(store),
          deviceInstallationStoreProvider.overrideWithValue(
            DeviceInstallationStore(() {
              deviceReadStarted.complete();
              return deviceRead.future;
            }, (_) async {}),
          ),
        ],
      );
      addTearDown(container.dispose);
      final client = container.read(dioProvider);
      var dispatched = false;
      client.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            dispatched = true;
            handler.resolve(
              Response(
                requestOptions: options,
                statusCode: 200,
                data: const {},
              ),
            );
          },
        ),
      );
      final future = client.get<Object?>('/auth/perfil');
      final expectation = expectLater(future, throwsA(isA<DioException>()));
      await deviceReadStarted.future;
      store.set('token-b');
      deviceRead.complete('saved-device-identity-12345678');
      await expectation;
      expect(dispatched, isFalse);
    },
  );

  test('fija la sesión antes de que arranque el primer interceptor', () async {
    final container = ProviderContainer(
      overrides: [
        appConfigProvider.overrideWithValue(
          const AppConfig(
            environment: AppEnvironment.dev,
            apiBaseUrl: 'https://api.example.com',
            demoMode: false,
          ),
        ),
        accessTokenStoreProvider.overrideWithValue(store),
        deviceInstallationStoreProvider.overrideWithValue(
          DeviceInstallationStore(
            () async => 'saved-device-identity-12345678',
            (_) async {},
          ),
        ),
      ],
    );
    addTearDown(container.dispose);
    final client = container.read(dioProvider);
    var dispatched = false;
    client.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          dispatched = true;
          handler.resolve(
            Response(requestOptions: options, statusCode: 200, data: const {}),
          );
        },
      ),
    );
    final request = client.post<Object?>(
      '/cuaderno-errores/question-1',
      data: {'nota': 'Nota de A'},
    );
    store.set('token-b');
    await expectLater(
      request,
      throwsA(
        isA<DioException>().having(
          (e) => e.type,
          'cancelled',
          DioExceptionType.cancel,
        ),
      ),
    );
    expect(dispatched, isFalse);
  });

  test(
    'un fallo del almacén de dispositivo finaliza la petición sin colgarla',
    () async {
      final container = ProviderContainer(
        overrides: [
          deviceInstallationStoreProvider.overrideWithValue(
            DeviceInstallationStore(
              () async => throw StateError('storage failed'),
              (_) async {},
            ),
          ),
        ],
      );
      addTearDown(container.dispose);
      await expectLater(
        container
            .read(publicDioProvider)
            .get<Object?>('/health')
            .timeout(const Duration(seconds: 1)),
        throwsA(isA<DioException>()),
      );
    },
  );

  test(
    'el cliente público tampoco envía credenciales fuera de su API',
    () async {
      final container = ProviderContainer(
        overrides: [
          appConfigProvider.overrideWithValue(
            const AppConfig(
              environment: AppEnvironment.dev,
              apiBaseUrl: 'https://api.example.com',
              demoMode: false,
            ),
          ),
          deviceInstallationStoreProvider.overrideWithValue(
            DeviceInstallationStore(
              () async => 'saved-device-identity-12345678',
              (_) async {},
            ),
          ),
        ],
      );
      addTearDown(container.dispose);
      final client = container.read(publicDioProvider);
      final dispatched = <RequestOptions>[];
      client.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            dispatched.add(options);
            handler.resolve(
              Response(
                requestOptions: options,
                statusCode: 200,
                data: const {},
              ),
            );
          },
        ),
      );
      await expectLater(
        client.post<Object?>(
          'https://other.example.com/auth/login',
          data: {'contrasena': 'not-a-real-password'},
        ),
        throwsA(isA<DioException>()),
      );
      expect(dispatched, isEmpty);
      await client.post<Object?>(
        '/auth/login',
        data: {'contrasena': 'not-a-real-password'},
      );
      expect(dispatched.single.followRedirects, isFalse);
    },
  );

  test(
    'fetch conserva la revisión explícita de una operación en cola',
    () async {
      final container = ProviderContainer(
        overrides: [
          appConfigProvider.overrideWithValue(
            const AppConfig(
              environment: AppEnvironment.dev,
              apiBaseUrl: 'https://api.example.com',
              demoMode: false,
            ),
          ),
          accessTokenStoreProvider.overrideWithValue(store),
          deviceInstallationStoreProvider.overrideWithValue(
            DeviceInstallationStore(
              () async => 'saved-device-identity-12345678',
              (_) async {},
            ),
          ),
        ],
      );
      addTearDown(container.dispose);
      final client = container.read(dioProvider);
      final oldRevision = store.revision;
      store.set('token-b');
      var dispatched = false;
      client.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            dispatched = true;
            handler.resolve(
              Response(
                requestOptions: options,
                statusCode: 200,
                data: const {},
              ),
            );
          },
        ),
      );
      await expectLater(
        client.post<Object?>(
          '/simulacros/progreso',
          options: Options(
            extra: {AuthInterceptor.sessionRevisionKey: oldRevision},
          ),
        ),
        throwsA(isA<DioException>()),
      );
      expect(dispatched, isFalse);
    },
  );
}
