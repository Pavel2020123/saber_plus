import 'package:dio/dio.dart';

import 'access_token_store.dart';
import 'api_origin.dart';

class AuthInterceptor extends Interceptor {
  AuthInterceptor(this._accessTokenStore, {String? apiBaseUrl})
    : _apiOrigin = apiBaseUrl == null ? null : Uri.parse(apiBaseUrl);

  static const sessionRevisionKey = 'saberplus.sessionRevision';
  final AccessTokenStore _accessTokenStore;
  final Uri? _apiOrigin;

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    final origin = _apiOrigin ?? Uri.tryParse(options.baseUrl);
    final target = options.uri;
    if (!isAllowedApiOrigin(origin, target)) {
      handler.reject(
        DioException(
          requestOptions: options,
          type: DioExceptionType.cancel,
          message: 'El cliente autenticado solo permite solicitudes a la API.',
        ),
      );
      return;
    }
    options.extra.putIfAbsent(
      sessionRevisionKey,
      () => _accessTokenStore.revision,
    );
    if (_isStale(options)) {
      handler.reject(_cancelled(options));
      return;
    }
    // Una redirección nunca debe transportar credenciales a otro destino.
    options.followRedirects = false;
    options.headers.removeWhere(
      (key, _) => key.toLowerCase() == 'authorization',
    );
    final accessToken = _accessTokenStore.accessToken;
    if (accessToken != null && accessToken.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $accessToken';
    }
    handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    if (_isStale(response.requestOptions)) {
      handler.reject(_cancelled(response.requestOptions));
      return;
    }
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    // Una respuesta de A no puede invalidar la nueva sesión de B.
    handler.next(
      _isStale(err.requestOptions) ? _cancelled(err.requestOptions) : err,
    );
  }

  bool _isStale(RequestOptions options) =>
      options.extra[sessionRevisionKey] != _accessTokenStore.revision;

  DioException _cancelled(RequestOptions options) => DioException(
    requestOptions: options,
    type: DioExceptionType.cancel,
    message: 'La sesión cambió durante la solicitud.',
  );
}
