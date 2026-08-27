import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/api_error.dart';
import '../../auth/domain/auth_models.dart';
import '../../auth/domain/auth_repository.dart';
import '../../auth/domain/session.dart';

class RemoteAuthRepository implements AuthRepository {
  RemoteAuthRepository(this._publicDio, this._authenticatedDio);

  final Dio _publicDio;
  final Dio _authenticatedDio;

  @override
  Future<LoginResult> login({
    required String email,
    required String password,
  }) async {
    final data = await _post(
      _publicDio,
      '/auth/login',
      body: {'email': email, 'password': password},
    );
    return LoginResult.fromJson(data);
  }

  @override
  Future<RegistrationResult> register(RegistrationRequest request) async {
    final data = await _post(
      _publicDio,
      '/auth/registro',
      body: request.toJson(),
    );
    return RegistrationResult.fromJson(data);
  }

  @override
  Future<void> verifyEmail(String token) =>
      _post(_publicDio, '/auth/verificar-correo', body: {'token': token});

  @override
  Future<void> resendVerification(String email) =>
      _post(_publicDio, '/auth/reenviar-verificacion', body: {'email': email});

  @override
  Future<void> requestPasswordReset(String email) =>
      _post(_publicDio, '/auth/solicitar-recuperacion', body: {'email': email});

  @override
  Future<void> resetPassword({
    required String token,
    required String password,
  }) => _post(
    _publicDio,
    '/auth/restablecer-contrasena',
    body: {'token': token, 'password': password},
  );

  @override
  Future<void> changeInitialPassword(String password) => _patch(
    _authenticatedDio,
    '/auth/cambiar-contrasena-inicial',
    body: {'password': password},
  );

  @override
  Future<UserSession> profile() async {
    try {
      final response = await _authenticatedDio.get<Map<String, dynamic>>(
        '/auth/perfil',
      );
      return UserSession.fromJson(_unwrap(response.data));
    } on DioException catch (error) {
      throw ApiError.fromDioException(error);
    }
  }

  @override
  Future<LoginResult> restore(String refreshToken) async {
    final data = await _post(
      _publicDio,
      '/auth/refresh',
      body: {'refreshToken': refreshToken},
    );
    return LoginResult.fromJson(data);
  }

  @override
  Future<void> logout(String? refreshToken) =>
      _post(_publicDio, '/auth/logout', body: {'refreshToken': ?refreshToken});

  Future<Map<String, dynamic>> _post(
    Dio dio,
    String path, {
    required Map<String, dynamic> body,
  }) async {
    try {
      final response = await dio.post<Map<String, dynamic>>(path, data: body);
      return _unwrap(response.data);
    } on DioException catch (error) {
      throw ApiError.fromDioException(error);
    }
  }

  Future<Map<String, dynamic>> _patch(
    Dio dio,
    String path, {
    required Map<String, dynamic> body,
  }) async {
    try {
      final response = await dio.patch<Map<String, dynamic>>(path, data: body);
      return _unwrap(response.data);
    } on DioException catch (error) {
      throw ApiError.fromDioException(error);
    }
  }

  Map<String, dynamic> _unwrap(Map<String, dynamic>? body) {
    if (body == null) return const {};
    final data = body['data'];
    return data is Map<String, dynamic> ? data : body;
  }
}

final authRepositoryProvider = Provider<AuthRepository>(
  (ref) => RemoteAuthRepository(
    ref.watch(publicDioProvider),
    ref.watch(dioProvider),
  ),
);
