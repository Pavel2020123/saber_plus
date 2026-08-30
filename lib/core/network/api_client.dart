import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../config/environment.dart';
import '../security/device_installation_store.dart';
import '../security/session_security.dart';
import 'access_token_store.dart';
import 'auth_interceptor.dart';

Dio _createDio(AppConfig config, DeviceInstallationStore deviceStore) {
  var requestSequence = 0;
  final dio = Dio(
    BaseOptions(
      baseUrl: config.apiBaseUrl,
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 20),
      sendTimeout: const Duration(seconds: 20),
      headers: const {'Accept': 'application/json'},
    ),
  );

  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) async {
        requestSequence += 1;
        options.headers['X-Request-Id'] =
            'mobile-${DateTime.now().microsecondsSinceEpoch}-$requestSequence';
        options.headers['X-Device-Id'] = await deviceStore.getOrCreate();
        options.headers['X-SaberPlus-Client'] = 'mobile';
        handler.next(options);
      },
    ),
  );
  return dio;
}

final publicDioProvider = Provider<Dio>((ref) {
  return _createDio(
    ref.watch(appConfigProvider),
    ref.watch(deviceInstallationStoreProvider),
  );
});

final dioProvider = Provider<Dio>((ref) {
  final config = ref.watch(appConfigProvider);
  final dio = _createDio(config, ref.watch(deviceInstallationStoreProvider));
  dio.interceptors.add(AuthInterceptor(ref.watch(accessTokenStoreProvider)));
  dio.interceptors.add(
    SessionSecurityInterceptor(
      ref.read(sessionSecurityProvider.notifier).report,
    ),
  );
  return dio;
});
