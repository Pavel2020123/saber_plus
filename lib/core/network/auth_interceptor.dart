import 'package:dio/dio.dart';

import 'access_token_store.dart';

class AuthInterceptor extends Interceptor {
  AuthInterceptor(this._accessTokenStore);

  final AccessTokenStore _accessTokenStore;

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    final accessToken = _accessTokenStore.accessToken;
    if (accessToken != null && accessToken.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $accessToken';
    }
    handler.next(options);
  }
}
