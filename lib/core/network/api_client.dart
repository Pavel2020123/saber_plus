import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../config/environment.dart';
import '../storage/secure_session_store.dart';
import 'access_token_store.dart';
import 'auth_interceptor.dart';

Dio _createDio(AppConfig config) {
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
      onRequest: (options, handler) {
        requestSequence += 1;
        options.headers['X-Request-Id'] =
            'mobile-${DateTime.now().microsecondsSinceEpoch}-$requestSequence';
        handler.next(options);
      },
    ),
  );
  return dio;
}

final publicDioProvider = Provider<Dio>((ref) {
  return _createDio(ref.watch(appConfigProvider));
});

final dioProvider = Provider<Dio>((ref) {
  final config = ref.watch(appConfigProvider);
  final dio = _createDio(config);
  dio.interceptors.add(
    AuthInterceptor(
      dio,
      ref.watch(publicDioProvider),
      ref.watch(accessTokenStoreProvider),
      ref.watch(secureSessionStoreProvider),
    ),
  );
  return dio;
});
