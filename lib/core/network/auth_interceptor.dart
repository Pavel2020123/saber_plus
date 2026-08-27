import 'dart:async';

import 'package:dio/dio.dart';

import '../storage/secure_session_store.dart';
import 'access_token_store.dart';

class AuthInterceptor extends QueuedInterceptor {
  AuthInterceptor(
    this._authenticatedDio,
    this._refreshDio,
    this._accessTokenStore,
    this._secureSessionStore,
  );

  final Dio _authenticatedDio;
  final Dio _refreshDio;
  final AccessTokenStore _accessTokenStore;
  final SecureSessionStore _secureSessionStore;
  Future<bool>? _refreshInProgress;

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    final accessToken = _accessTokenStore.accessToken;
    if (accessToken != null && accessToken.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $accessToken';
    }
    handler.next(options);
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    final request = err.requestOptions;
    final shouldRefresh =
        err.response?.statusCode == 401 &&
        request.extra['authRetried'] != true &&
        !request.path.endsWith('/auth/refresh');

    if (!shouldRefresh) {
      handler.next(err);
      return;
    }

    _refreshInProgress ??= _refreshTokens();
    final refreshed = await _refreshInProgress!;
    _refreshInProgress = null;

    if (!refreshed) {
      handler.next(err);
      return;
    }

    request.extra['authRetried'] = true;
    request.headers['Authorization'] =
        'Bearer ${_accessTokenStore.accessToken}';

    try {
      final response = await _authenticatedDio.fetch<dynamic>(request);
      handler.resolve(response);
    } on DioException catch (retryError) {
      handler.next(retryError);
    }
  }

  Future<bool> _refreshTokens() async {
    final refreshToken = await _secureSessionStore.readRefreshToken();
    if (refreshToken == null || refreshToken.isEmpty) return false;

    try {
      final response = await _refreshDio.post<Map<String, dynamic>>(
        '/auth/refresh',
        data: {'refreshToken': refreshToken},
      );
      final data = response.data;
      final accessToken = data?['accessToken'] as String?;
      final rotatedRefreshToken = data?['refreshToken'] as String?;
      if (accessToken == null || rotatedRefreshToken == null) return false;

      _accessTokenStore.set(accessToken);
      await _secureSessionStore.saveRefreshToken(rotatedRefreshToken);
      return true;
    } on DioException {
      _accessTokenStore.clear();
      await _secureSessionStore.clear();
      return false;
    }
  }
}
