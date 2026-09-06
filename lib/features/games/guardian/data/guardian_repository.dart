import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_error.dart';
import '../../../auth/presentation/session_controller.dart';
import '../domain/guardian_models.dart';
import 'demo_guardian_repository.dart';

final guardianRepositoryProvider = Provider<GuardianRepository>((ref) {
  final user = ref.watch(sessionControllerProvider).user;
  if (user?.isDemo ?? false) return DemoGuardianRepository();
  return RemoteGuardianRepository(ref.watch(dioProvider));
});

class RemoteGuardianRepository implements GuardianRepository {
  RemoteGuardianRepository(this.dio);
  final Dio dio;
  Future<GuardianAttempt?> _request(
    String path, {
    Map<String, dynamic>? data,
  }) async {
    try {
      final response = data == null
          ? await dio.get<Object?>(path)
          : await dio.post<Object?>(path, data: data);
      final body = response.data;
      if (body == null || body == '') return null;
      if (body is! Map) {
        throw const FormatException('Respuesta de desafío inválida.');
      }
      return GuardianAttempt.fromJson(Map<String, dynamic>.from(body));
    } on DioException catch (e) {
      throw ApiError.fromDioException(e);
    }
  }

  GuardianAttempt _required(GuardianAttempt? attempt) =>
      attempt ??
      (throw const FormatException('El servidor no devolvió el desafío.'));
  String _path(String id) => '/guardian/intentos/${Uri.encodeComponent(id)}';
  @override
  Future<GuardianAttempt?> active() => _request('/guardian/intentos/activo');
  @override
  Future<GuardianAttempt> start(GuardianConfig config) async =>
      _required(await _request('/guardian/intentos', data: config.toJson()));
  @override
  Future<GuardianAttempt> get(String id) async =>
      _required(await _request(_path(id)));
  @override
  Future<GuardianAttempt> answer({
    required String id,
    required String questionId,
    required String answerId,
    required String idempotencyKey,
  }) async => _required(
    await _request(
      '${_path(id)}/respuestas',
      data: {
        'preguntaId': questionId,
        'respuestaId': answerId,
        'idempotencyKey': idempotencyKey,
      },
    ),
  );
  @override
  Future<GuardianAttempt> abandon(String id) async =>
      _required(await _request('${_path(id)}/abandonar', data: {}));
}
