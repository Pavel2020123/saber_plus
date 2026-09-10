import 'package:dio/dio.dart';
import 'package:dio/io.dart';

import 'access_token_store.dart';
import 'auth_interceptor.dart';

/// Cliente Android/iOS que fija la sesión al iniciar la solicitud, antes de
/// que Dio programe la ejecución asíncrona de los interceptores.
class SessionDio extends DioForNative {
  SessionDio(super.options, this._tokens);

  final AccessTokenStore _tokens;

  @override
  Future<Response<T>> fetch<T>(RequestOptions requestOptions) {
    requestOptions.extra.putIfAbsent(
      AuthInterceptor.sessionRevisionKey,
      () => _tokens.revision,
    );
    return super.fetch<T>(requestOptions);
  }
}
