import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../config/environment.dart';
import '../security/device_installation_store.dart';
import '../security/session_security.dart';
import 'access_token_store.dart';
import 'api_origin.dart';
import 'auth_interceptor.dart';
import 'session_dio.dart';

Dio _createDio(
  AppConfig config,
  DeviceInstallationStore deviceStore, {
  AccessTokenStore? tokenStore,
}) {
  var requestSequence = 0;
  final options = BaseOptions(
    baseUrl: config.apiBaseUrl,
    connectTimeout: const Duration(seconds: 15),
    receiveTimeout: const Duration(seconds: 20),
    sendTimeout: const Duration(seconds: 20),
    headers: const {'Accept': 'application/json'},
  );
  final dio = tokenStore == null
      ? Dio(options)
      : SessionDio(options, tokenStore);

  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) async {
        if (!isAllowedApiOrigin(Uri.parse(config.apiBaseUrl), options.uri)) {
          handler.reject(
            DioException(
              requestOptions: options,
              type: DioExceptionType.cancel,
              message: 'Este cliente solo permite solicitudes a la API.',
            ),
          );
          return;
        }
        // El cliente público también envía contraseñas y datos de registro.
        options.followRedirects = false;
        requestSequence += 1;
        options.headers['X-Request-Id'] =
            'mobile-${DateTime.now().microsecondsSinceEpoch}-$requestSequence';
        try {
          options.headers['X-Device-Id'] = await deviceStore.getOrCreate();
          options.headers['X-SaberPlus-Client'] = 'mobile';
          handler.next(options);
        } on Object catch (error) {
          handler.reject(
            DioException(
              requestOptions: options,
              error: error,
              message:
                  'No se pudo acceder al identificador seguro del dispositivo.',
            ),
          );
        }
      },
    ),
  );
  return dio;
}

final publicDioProvider = Provider<Dio>((ref) {
  final dio = _createDio(
    ref.watch(appConfigProvider),
    ref.watch(deviceInstallationStoreProvider),
  );
  ref.onDispose(() => dio.close(force: true));
  return dio;
});

final dioProvider = Provider<Dio>((ref) {
  final config = ref.watch(appConfigProvider);
  final tokenStore = ref.watch(accessTokenStoreProvider);
  final dio = _createDio(
    config,
    ref.watch(deviceInstallationStoreProvider),
    tokenStore: tokenStore,
  );
  dio.interceptors.add(
    AuthInterceptor(tokenStore, apiBaseUrl: config.apiBaseUrl),
  );
  dio.interceptors.add(
    SessionSecurityInterceptor(
      ref.read(sessionSecurityProvider.notifier).report,
    ),
  );
  ref.onDispose(() => dio.close(force: true));
  return dio;
});
